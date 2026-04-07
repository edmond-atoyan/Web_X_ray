import tempfile
from unittest.mock import patch

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from django.urls import reverse

from main.models import XRayImage
from main.views import PredictionUnavailable


class PredictViewTests(TestCase):
    def setUp(self):
        super().setUp()
        self.temp_dir = tempfile.TemporaryDirectory()
        self.override = override_settings(MEDIA_ROOT=self.temp_dir.name)
        self.override.enable()

    def tearDown(self):
        self.override.disable()
        self.temp_dir.cleanup()
        super().tearDown()

    def _upload(self):
        return SimpleUploadedFile(
            "xray.png",
            b"fake-image-bytes",
            content_type="image/png",
        )

    def test_predict_requires_image(self):
        response = self.client.post(reverse("predict"))

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json(), {"error": "No image uploaded."})

    def test_predict_returns_warning_when_runtime_is_unavailable(self):
        with patch("main.views._preprocess_image", return_value=("tensor", "flat")):
            with patch(
                "main.views._predict_with_confidence",
                side_effect=PredictionUnavailable("TensorFlow is not installed."),
            ):
                response = self.client.post(reverse("predict"), {"image": self._upload()})

        payload = response.json()
        self.assertEqual(response.status_code, 200)
        self.assertEqual(payload["message"], "Image saved successfully.")
        self.assertEqual(payload["warning"], "TensorFlow is not installed.")
        self.assertIn("image_id", payload)
        self.assertEqual(XRayImage.objects.count(), 1)

    def test_predict_returns_prediction_payload_when_inference_succeeds(self):
        with patch("main.views._preprocess_image", return_value=("tensor", "flat")):
            with patch(
                "main.views._predict_with_confidence",
                return_value=(1, 0.9732),
            ):
                response = self.client.post(reverse("predict"), {"image": self._upload()})

        payload = response.json()
        self.assertEqual(response.status_code, 200)
        self.assertEqual(payload["prediction"], "Tuberculosis Detected")
        self.assertEqual(payload["class"], 1)
        self.assertAlmostEqual(payload["confidence"], 0.9732)
        self.assertEqual(XRayImage.objects.count(), 1)
