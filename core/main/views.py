import logging
import os
import pickle
from functools import lru_cache
from pathlib import Path

from django.http import JsonResponse
from django.shortcuts import render
from django.views.decorators.http import require_POST

from main.models import XRayImage

logger = logging.getLogger(__name__)

DEFAULT_MODEL_PATH = Path(__file__).resolve().parent / "model.pkl"
DEFAULT_CLASS_LABELS = ("Normal", "Tuberculosis Detected")
IMAGE_SIZE = (150, 150)


class PredictionUnavailable(RuntimeError):
    """Raised when an upload can be stored but inference cannot run."""


def index(request):
    return render(request, "index.html")


def _preprocess_image(image_file):
    """
    Convert the uploaded X-ray into tensor and flat feature shapes.
    """
    try:
        import numpy as np
        from PIL import Image
    except ModuleNotFoundError as exc:
        missing_dependency = exc.name or "prediction dependency"
        raise PredictionUnavailable(
            f"Prediction runtime is unavailable because '{missing_dependency}' is not installed."
        ) from exc

    image_file.seek(0)
    image = Image.open(image_file).convert("L").resize(IMAGE_SIZE)
    arr = np.array(image, dtype=np.float32) / 255.0
    width, height = IMAGE_SIZE
    tensor = arr.reshape(1, height, width, 1)
    flat = arr.reshape(1, -1)
    return tensor, flat

def _resolved_model_paths():
    configured_path = os.getenv("MODEL_PATH")
    candidates = []

    if configured_path:
        candidates.append(Path(configured_path).expanduser())
    candidates.append(DEFAULT_MODEL_PATH)

    unique_candidates = []
    seen = set()
    for candidate in candidates:
        candidate_str = str(candidate)
        if candidate_str not in seen:
            seen.add(candidate_str)
            unique_candidates.append(candidate)
    return tuple(unique_candidates)


@lru_cache(maxsize=1)
def _load_model():
    for model_path in _resolved_model_paths():
        if not model_path.exists():
            continue

        try:
            with model_path.open("rb") as file:
                return pickle.load(file)
        except ModuleNotFoundError as exc:
            missing_dependency = exc.name or "prediction dependency"
            raise PredictionUnavailable(
                f"Prediction runtime is unavailable because '{missing_dependency}' is not installed."
            ) from exc
        except Exception as exc:
            logger.exception("Failed to load model from %s", model_path)
            raise PredictionUnavailable(
                f"Failed to load the saved model from '{model_path}'."
            ) from exc

    checked_paths = ", ".join(str(path) for path in _resolved_model_paths())
    raise PredictionUnavailable(f"Model file not found. Checked: {checked_paths}")


def _is_keras_like_model(model):
    module_name = getattr(model.__class__, "__module__", "").lower()
    return "keras" in module_name or "tensorflow" in module_name


def _prediction_label(class_index):
    configured_labels = os.getenv(
        "MODEL_CLASS_LABELS",
        ",".join(DEFAULT_CLASS_LABELS),
    )
    labels = [label.strip() for label in configured_labels.split(",") if label.strip()]

    if 0 <= class_index < len(labels):
        return labels[class_index]
    return f"Class {class_index}"


def _predict_with_confidence(tensor_features, flat_features):
    """
    Return (class_index, confidence) for keras-like and sklearn-like models.
    """
    try:
        import numpy as np
    except ModuleNotFoundError as exc:
        missing_dependency = exc.name or "prediction dependency"
        raise PredictionUnavailable(
            f"Prediction runtime is unavailable because '{missing_dependency}' is not installed."
        ) from exc

    model = _load_model()

    if _is_keras_like_model(model):
        try:
            raw_prediction = model.predict(tensor_features, verbose=0)
        except TypeError:
            raw_prediction = model.predict(tensor_features)

        prediction_array = np.asarray(raw_prediction).reshape(-1)
        if not prediction_array.size:
            raise PredictionUnavailable("The model returned an empty prediction.")

        if prediction_array.size == 1:
            score = float(prediction_array[0])
            class_index = 1 if score >= 0.5 else 0
            confidence = score if class_index == 1 else (1.0 - score)
            return class_index, float(confidence)

        class_index = int(np.argmax(prediction_array))
        confidence = float(prediction_array[class_index])
        return class_index, confidence

    if hasattr(model, "predict_proba"):
        probabilities = np.asarray(model.predict_proba(flat_features)[0]).reshape(-1)
        class_index = int(np.argmax(probabilities))
        confidence = float(probabilities[class_index])
        if hasattr(model, "classes_"):
            class_index = int(model.classes_[class_index])
        return class_index, confidence

    prediction = int(np.asarray(model.predict(flat_features)).reshape(-1)[0])

    if hasattr(model, "decision_function"):
        decision = model.decision_function(flat_features)
        score = float(np.ravel(decision)[0])
        confidence = 1.0 / (1.0 + np.exp(-abs(score)))
    else:
        confidence = 0.5

    return prediction, float(confidence)


@require_POST
def predict(request):
    try:
        image_file = request.FILES.get("image")
        if not image_file:
            return JsonResponse({"error": "No image uploaded."}, status=400)

        xray = XRayImage(image=image_file)
        xray.save()

        response_payload = {
            "message": "Image saved successfully.",
            "image_id": xray.pk,
            "image_url": xray.image.url,
        }

        try:
            tensor_features, flat_features = _preprocess_image(image_file)
            class_index, confidence = _predict_with_confidence(
                tensor_features,
                flat_features,
            )
        except PredictionUnavailable as exc:
            logger.warning("Prediction unavailable for upload %s: %s", xray.pk, exc)
            response_payload["warning"] = str(exc)
            return JsonResponse(response_payload)

        response_payload.update(
            {
                "prediction": _prediction_label(class_index),
                "class": class_index,
                "confidence": confidence,
            }
        )
        return JsonResponse(response_payload)
    except Exception as exc:
        return JsonResponse(
            {"error": f"Upload failed: {str(exc)}"},
            status=500,
        )
