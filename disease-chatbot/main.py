# main.py
# Single FastAPI app combining:
#  - Pet Disease Classifier (TFLite)
#  - Chatbot (Groq / LangGraph)

import io
import os
from pyexpat.errors import messages
import threading
from contextlib import asynccontextmanager
from typing import List
from urllib import response

import numpy as np
from PIL import Image
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

# ML imports (TFLite)
import tensorflow as tf

# LLM / chat imports
# Keep these imports as in your original snippet; ensure packages are installed.
from langgraph.checkpoint.memory import MemorySaver
from langchain_groq import ChatGroq
from langchain.messages import HumanMessage
from langgraph.graph import StateGraph, END

# -------------------------------------------------------------------
# Configuration (paths / constants)
# -------------------------------------------------------------------
load_dotenv()  # loads .env if present

MODEL_PATH = os.getenv("TFLITE_MODEL_PATH", "assets/final_model_100epoch.tflite")
LABELS_PATH = os.getenv("LABELS_PATH", "assets/labels.txt")
TOP_K = int(os.getenv("TOP_K", "5"))

# Groq settings (use env var)
GROQ_API_KEY = os.getenv("GROQ_API_KEY", os.getenv("GROQ_API_KEY_INLINE", "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"))
GROQ_MODEL = os.getenv("GROQ_MODEL", "llama-3.1-8b-instant")

# -------------------------------------------------------------------
# Globals used by TFLite model (loaded at startup)
# -------------------------------------------------------------------
interpreter = None
input_details = None
output_details = None
input_height = input_width = input_channels = None
input_dtype = None
labels: List[str] = []
tflite_lock = threading.Lock()

# -------------------------------------------------------------------
# Globals used by LLM/chat
# -------------------------------------------------------------------
llm = None
memory = None
chat_bot = None

# -------------------------------------------------------------------
# Lifespan: load model and initialize LLM once when app starts
# -------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    global interpreter, input_details, output_details
    global input_height, input_width, input_channels, input_dtype, labels
    global llm, memory, chat_bot

    # --- Load labels ---
    try:
        with open(LABELS_PATH, "r", encoding="utf-8") as f:
            labels = [line.strip() for line in f if line.strip()]
    except Exception as e:
        print(f"⚠️ Could not load labels from {LABELS_PATH}: {e}")
        labels = []

    # --- Load TFLite model ---
    try:
        print("🚀 Loading TFLite model...")
        interpreter = tf.lite.Interpreter(model_path=MODEL_PATH)
        interpreter.allocate_tensors()
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()

        # Extract input shape
        # Some models return shape like [1, H, W, C]
        shape = input_details[0]["shape"]
        if len(shape) == 4:
            _, input_height, input_width, input_channels = shape
        elif len(shape) == 3:
            input_height, input_width, input_channels = shape
        else:
            # fallback: try to coerce
            input_height = int(shape[1]) if len(shape) > 1 else None
            input_width = int(shape[2]) if len(shape) > 2 else None
            input_channels = int(shape[-1])

        input_height = int(input_height)
        input_width = int(input_width)
        input_channels = int(input_channels)
        input_dtype = input_details[0]["dtype"]

        print(f"✅ TFLite model loaded: {MODEL_PATH}")
        print(f"   Input: {input_height}x{input_width}x{input_channels} (dtype={input_dtype})")
        print(f"   Labels loaded: {len(labels)}")
    except Exception as e:
        print(f"❌ Failed to load TFLite model: {e}")
        interpreter = None

    # --- Initialize Groq LLM / LangGraph chatbot ---
    try:
        if not GROQ_API_KEY:
            raise RuntimeError("GROQ_API_KEY not set")

        # set environment variable used by ChatGroq if required
        os.environ["GROQ_API_KEY"] = GROQ_API_KEY

        print("🧠 Initializing Groq LLM and chat graph...")
        llm = ChatGroq(model=GROQ_MODEL)
        memory = MemorySaver()

        # Simple state schema: a list of messages
        class ChatBotState(dict):
            message: list

        def chatbot_node(state: ChatBotState):
            messages = state["message"]          # keep history
            response = llm.invoke(messages)      # AIMessage
            return {"message": messages + [response]}


        graph = StateGraph(ChatBotState)
        graph.add_node("chatbot", chatbot_node)
        graph.set_entry_point("chatbot")
        graph.add_edge("chatbot", END)
        chat_bot = graph.compile(checkpointer=memory)
        print("✅ Chatbot initialized.")
    except Exception as e:
        print(f"❌ Chatbot initialization failed: {e}")
        chat_bot = None

    yield  # app runs

    # Cleanup (best-effort)
    try:
        interpreter = None
        print("🧹 TFLite interpreter cleared.")
    except Exception:
        pass

    try:
        chat_bot = None
        print("🧹 Chatbot cleared.")
    except Exception:
        pass


# -------------------------------------------------------------------
# FastAPI app
# -------------------------------------------------------------------
app = FastAPI(title="Pet Disease Classifier + Chatbot API", lifespan=lifespan)

# CORS (allow all for development; lock down in production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # change to your Flutter/web origin(s) for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# -------------------------------------------------------------------
# Utility: image preprocessing & prediction
# -------------------------------------------------------------------
def preprocess_image(file_bytes: bytes) -> np.ndarray:
    if interpreter is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    try:
        img = Image.open(io.BytesIO(file_bytes)).convert("RGB")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid image file")

    img = img.resize((input_width, input_height), Image.BILINEAR)
    x = np.expand_dims(np.asarray(img), axis=0)

    # Cast to model dtype
    if input_dtype == np.float32:
        x = x.astype(np.float32) / 255.0
    elif input_dtype == np.uint8:
        x = x.astype(np.uint8)
    else:
        x = x.astype(input_dtype)

    return x


def predict_image(x: np.ndarray):
    if interpreter is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    with tflite_lock:
        interpreter.set_tensor(input_details[0]["index"], x)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]["index"])[0]

    # Softmax to get probabilities; handle shape mismatch gracefully
    try:
        probs = tf.nn.softmax(output).numpy()
    except Exception:
        # If model already outputs probabilities
        probs = np.array(output, dtype=float)
        s = probs.sum()
        if s > 0:
            probs = probs / s

    # Top prediction
    top_idx = int(np.argmax(probs))
    top_conf = float(probs[top_idx])

    # Top-K list
    top_k_idx = np.argsort(-probs)[:TOP_K]
    top_k = [
        {
            "label": labels[i] if i < len(labels) else f"class_{i}",
            "confidence": float(probs[i]),
            "index": int(i),
        }
        for i in top_k_idx
    ]

    return {
        "predicted_disease": labels[top_idx] if top_idx < len(labels) else f"class_{top_idx}",
        "confidence": top_conf,
        "top_k": top_k,
        "num_labels": len(labels),
    }


# -------------------------------------------------------------------
# Root / health endpoint
# -------------------------------------------------------------------
@app.get("/")
def root():
    return {
        "status": "ok",
        "message": "Pet Disease Classifier + Chatbot API is running.",
        "model_info": {
            "height": input_height,
            "width": input_width,
            "channels": input_channels,
            "dtype": str(input_dtype) if input_dtype is not None else None,
            "num_labels": len(labels),
            "model_path": MODEL_PATH,
        },
        "chatbot": {
            "initialized": chat_bot is not None,
            "model": GROQ_MODEL,
        },
    }


# -------------------------------------------------------------------
# Prediction endpoint (image -> disease)
# -------------------------------------------------------------------
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    if file.content_type not in ("image/jpeg", "image/png", "image/webp"):
        raise HTTPException(status_code=415, detail="Only JPEG, PNG, or WEBP images are supported")

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Empty file")

    x = preprocess_image(image_bytes)
    result = predict_image(x)
    return result


# -------------------------------------------------------------------
# Chat endpoint (text -> chat reply)
# -------------------------------------------------------------------
class ChatRequest(BaseModel):
    text: str


@app.post("/chat")
def chat_api(req: ChatRequest):
    if chat_bot is None:
        raise HTTPException(status_code=503, detail="Chatbot not available")

    try:
        result = chat_bot.invoke(
            {"message": [HumanMessage(content=req.text)]},
            config={"configurable": {"thread_id": os.urandom(8).hex()}},
        )

        reply_text = result["message"][-1].content
        return {"reply": reply_text}

    except Exception as e:
        print("CHAT ERROR:", e)
        raise HTTPException(status_code=500, detail=str(e))



# -------------------------------------------------------------------
# Optional: uvicorn run
# -------------------------------------------------------------------
if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

#uvicorn main:app --host 0.0.0.0 --port 8000 --reload
