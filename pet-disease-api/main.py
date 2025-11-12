# --- IMPORTS ---
import io
import numpy as np
from PIL import Image
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import tensorflow as tf
import threading

# --- CONFIG PATHS ---
MODEL_PATH = "assets/final_model_100epoch.tflite"
LABELS_PATH = "assets/labels.txt"
TOP_K = 5

# --- GLOBALS (will be loaded in lifespan) ---
interpreter = None
input_details = None
output_details = None
input_height = input_width = input_channels = None
input_dtype = None
labels = []
lock = threading.Lock()

# -------------------------------------------------------------------
# 🧩 Lifespan context: load model once when app starts
# -------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    global interpreter, input_details, output_details
    global input_height, input_width, input_channels, input_dtype, labels

    print("🚀 Loading TFLite model and labels...")
    # --- Load labels ---
    with open(LABELS_PATH, "r", encoding="utf-8") as f:
        labels = [line.strip() for line in f if line.strip()]

    # --- Load TFLite model ---
    interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # --- Model input info ---
    _, input_height, input_width, input_channels = input_details[0]["shape"]
    input_height = int(input_height)
    input_width = int(input_width)
    input_channels = int(input_channels)
    print(f"✅ Model input shape: {input_details[0]['shape']}")
    input_dtype = input_details[0]["dtype"]
    print(f"✅ Model ready: {input_height}x{input_width}x{input_channels}, dtype={input_dtype}")
    print(f"✅ Loaded {len(labels)} labels.")

    yield  # <-- app runs here

    # --- Cleanup on shutdown ---
    interpreter = None
    print("🧹 Model resources released.")


# -------------------------------------------------------------------
# 🚀 FastAPI APP
# -------------------------------------------------------------------
app = FastAPI(title="Pet Disease Classifier API", lifespan=lifespan)

# Enable CORS for frontend (adjust for production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # change to your Flutter web origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# -------------------------------------------------------------------
# 🔧 Utility functions
# -------------------------------------------------------------------
def preprocess_image(file_bytes: bytes) -> np.ndarray:
    """Read and preprocess the image for model input."""
    try:
        img = Image.open(io.BytesIO(file_bytes)).convert("RGB")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid image file")

    img = img.resize((input_width, input_height), Image.BILINEAR)
    x = np.expand_dims(np.asarray(img), axis=0)

    if input_dtype == np.float32:
        x = x.astype(np.float32) / 255.0
    elif input_dtype == np.uint8:
        x = x.astype(np.uint8)
    else:
        x = x.astype(input_dtype)

    return x


def predict_image(x: np.ndarray):
    """Run TFLite inference and return top predictions."""
    with lock:
        interpreter.set_tensor(input_details[0]["index"], x)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]["index"])[0]

    # Apply softmax
    probs = tf.nn.softmax(output).numpy()
    top_idx = int(np.argmax(probs))
    top_conf = float(probs[top_idx])

    # Top-K
    top_k_idx = np.argsort(-probs)[:TOP_K]
    top_k = [
        {
            "label": labels[i] if i < len(labels) else f"class_{i}",
            "confidence": float(probs[i]),
        }
        for i in top_k_idx
    ]

    return {
        "predicted_disease": labels[top_idx] if top_idx < len(labels) else f"class_{top_idx}",
        "confidence": top_conf,
        "top_k": top_k,
    }


# -------------------------------------------------------------------
# 🏠 Root endpoint
# -------------------------------------------------------------------
@app.get("/")
def root():
    return {
        "status": "ok",
        "message": "Pet Disease Classifier API is running.",
        "model_info": {
            "height": input_height,
            "width": input_width,
            "channels": input_channels,
            "dtype": str(input_dtype),
        },
        "num_labels": len(labels),
    }


# -------------------------------------------------------------------
# 🧾 Prediction endpoint
# -------------------------------------------------------------------
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    """Accepts an image file and returns the predicted disease."""
    if file.content_type not in ("image/jpeg", "image/png", "image/webp"):
        raise HTTPException(status_code=415, detail="Only JPEG, PNG, or WEBP images are supported")

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Empty file")

    x = preprocess_image(image_bytes)
    result = predict_image(x)
    return result
#
#uvicorn main:app --host 0.0.0.0 --port 8000 --reload
# http://localhost:8000/docs
