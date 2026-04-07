const state = {
  selectedFile: null,
};

const elements = {
  form: document.getElementById("uploadForm"),
  dropZone: document.getElementById("dropZone"),
  fileInput: document.getElementById("fileInput"),
  previewContainer: document.getElementById("previewContainer"),
  previewImage: document.getElementById("previewImage"),
  fileName: document.getElementById("fileName"),
  analyzeBtn: document.getElementById("analyzeBtn"),
  loadingState: document.getElementById("loadingState"),
  resultCard: document.getElementById("resultCard"),
  resultText: document.getElementById("resultText"),
  confidenceText: document.getElementById("confidenceText"),
  errorText: document.getElementById("errorText"),
};

function getCsrfToken() {
  const name = "csrftoken";
  const cookies = document.cookie ? document.cookie.split(";") : [];
  for (const cookie of cookies) {
    const trimmed = cookie.trim();
    if (trimmed.startsWith(`${name}=`)) {
      return decodeURIComponent(trimmed.slice(name.length + 1));
    }
  }
  return "";
}

function showError(message) {
  elements.errorText.textContent = message;
  elements.errorText.classList.remove("hidden");
}

function clearError() {
  elements.errorText.textContent = "";
  elements.errorText.classList.add("hidden");
}

function resetResult() {
  elements.resultText.textContent = "";
  elements.resultText.classList.remove("danger", "success");
  elements.confidenceText.textContent = "";
  elements.resultCard.classList.add("hidden");
}

function setLoading(isLoading) {
  elements.analyzeBtn.disabled = isLoading;
  elements.loadingState.classList.toggle("hidden", !isLoading);
}

function previewFile(file) {
  const reader = new FileReader();
  reader.onload = (event) => {
    elements.previewImage.src = event.target?.result || "";
    elements.fileName.textContent = file.name;
    elements.previewContainer.classList.remove("hidden");
  };
  reader.readAsDataURL(file);
}

function isImage(file) {
  return file && file.type.startsWith("image/");
}

function setSelectedFile(file) {
  if (!isImage(file)) {
    showError("Please upload a valid image file.");
    return;
  }

  clearError();
  resetResult();
  state.selectedFile = file;
  previewFile(file);
}

function getPredictionPayload(data) {
  const predictedClass = String(
    data.prediction || data.result || data.class || data.label || ""
  ).toLowerCase();

  const confidenceRaw = Number(data.confidence);
  const confidence = Number.isFinite(confidenceRaw)
    ? `${(confidenceRaw * (confidenceRaw <= 1 ? 100 : 1)).toFixed(2)}%`
    : "N/A";

  const isTbDetected =
    predictedClass.includes("tuberculosis") ||
    predictedClass.includes("tb") ||
    predictedClass.includes("positive");

  return {
    isTbDetected,
    label: isTbDetected ? "Tuberculosis Detected" : "Normal",
    confidence,
  };
}

function hasPredictionData(data) {
  return ["prediction", "result", "class", "label", "confidence"].some(
    (key) => key in data
  );
}

async function analyzeImage() {
  if (!state.selectedFile) {
    showError("Please upload an X-ray image before analysis.");
    return;
  }

  clearError();
  resetResult();
  setLoading(true);

  try {
    const formData = new FormData();
    formData.append("image", state.selectedFile);

    const response = await fetch("/predict/", {
      method: "POST",
      headers: {
        "X-CSRFToken": getCsrfToken(),
      },
      body: formData,
    });

    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.error || "Server returned an error while processing the image.");
    }

    if (!hasPredictionData(data)) {
      elements.resultText.textContent = data.message || "Image saved successfully.";
      elements.resultText.classList.add("success");
      elements.confidenceText.textContent =
        data.warning || "Prediction is currently unavailable in this environment.";
      elements.resultCard.classList.remove("hidden");
      return;
    }

    const prediction = getPredictionPayload(data);
    elements.resultText.textContent = prediction.label;
    elements.resultText.classList.add(prediction.isTbDetected ? "danger" : "success");
    elements.confidenceText.textContent = `Confidence: ${prediction.confidence}`;
    elements.resultCard.classList.remove("hidden");
  } catch (error) {
    showError(error.message || "An unexpected error occurred. Please try again.");
  } finally {
    setLoading(false);
  }
}

function bindDropZoneEvents() {
  const stopDefaults = (event) => {
    event.preventDefault();
    event.stopPropagation();
  };

  ["dragenter", "dragover", "dragleave", "drop"].forEach((eventName) => {
    elements.dropZone.addEventListener(eventName, stopDefaults);
  });

  ["dragenter", "dragover"].forEach((eventName) => {
    elements.dropZone.addEventListener(eventName, () => {
      elements.dropZone.classList.add("drag-active");
    });
  });

  ["dragleave", "drop"].forEach((eventName) => {
    elements.dropZone.addEventListener(eventName, () => {
      elements.dropZone.classList.remove("drag-active");
    });
  });

  elements.dropZone.addEventListener("drop", (event) => {
    const file = event.dataTransfer?.files?.[0];
    if (file) {
      setSelectedFile(file);
    }
  });

  elements.dropZone.addEventListener("click", () => elements.fileInput.click());
  elements.dropZone.addEventListener("keydown", (event) => {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      elements.fileInput.click();
    }
  });
}

function bindFormEvents() {
  elements.fileInput.addEventListener("change", (event) => {
    const file = event.target.files?.[0];
    if (file) {
      setSelectedFile(file);
    }
  });

  elements.form.addEventListener("submit", async (event) => {
    event.preventDefault();
    await analyzeImage();
  });
}

function init() {
  bindDropZoneEvents();
  bindFormEvents();
}

init();
