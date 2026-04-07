from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.http import require_POST

from main.models import XRayImage

# Load model once when Django starts.
# MODEL_PATH = Path(__file__).resolve().parent / "model.pkl"
# with MODEL_PATH.open("rb") as file:
#     model = pickle.load(file)


def index(request):
    return render(request, "index.html")


# def _preprocess_image(image_file):
#     """
#     Convert uploaded X-ray to 150x150x1 and return both tensor and flat forms.
#     """
#     target_w, target_h = 150, 150
#     image = Image.open(image_file).convert("L").resize((target_w, target_h))
#     arr = np.array(image, dtype=np.float32) / 255.0
#     tensor = arr.reshape(1, target_h, target_w, 1)  # (1,150,150,1)
#     flat = arr.reshape(1, -1)  # (1,22500)
#     return tensor, flat


# def _predict_with_confidence(tensor_features, flat_features):
#     """
#     Return (label, confidence) for keras-like and sklearn-like models.
#     """
#     try:
#         raw_pred = model.predict(tensor_features)
#         pred_arr = np.asarray(raw_pred).reshape(-1)
#         if pred_arr.size:
#             score = float(pred_arr[0]) if pred_arr.size == 1 else float(np.max(pred_arr))
#             label = 1 if score >= 0.5 else 0
#             confidence = score if label == 1 else (1.0 - score)
#             return label, float(confidence)
#     except Exception:
#         pass

#     features = flat_features
#     if hasattr(model, "predict_proba"):
#         proba = model.predict_proba(features)[0]
#         idx = int(np.argmax(proba))
#         confidence = float(proba[idx])
#         label = int(model.classes_[idx]) if hasattr(model, "classes_") else idx
#         return label, confidence

#     prediction = model.predict(features)[0]

#     if hasattr(model, "decision_function"):
#         decision = model.decision_function(features)
#         if isinstance(decision, np.ndarray):
#             score = float(np.ravel(decision)[0])
#         else:
#             score = float(decision)
#         confidence = 1.0 / (1.0 + np.exp(-abs(score)))
#     else:
#         confidence = 0.5

#     return int(prediction), float(confidence)


@require_POST
def predict(request):
    try:
        image_file = request.FILES.get("image")
        if not image_file:
            return JsonResponse({"error": "No image uploaded."}, status=400)

        xray = XRayImage(image=image_file)
        xray.save()

        # TODO: uncomment ML prediction once model.pkl is available
        # tensor_features, flat_features = _preprocess_image(image_file)
        # label, confidence = _predict_with_confidence(tensor_features, flat_features)
        # prediction_text = "Tuberculosis Detected" if label == 1 else "Normal"

        return JsonResponse({
            "message": "Image saved successfully.",
            "image_id": xray.pk,
            "image_url": xray.image.url,
        })
    except Exception as exc:
        return JsonResponse(
            {"error": f"Upload failed: {str(exc)}"},
            status=500,
        )
