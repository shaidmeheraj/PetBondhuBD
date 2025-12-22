import os
from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from langgraph.checkpoint.memory import MemorySaver
from langchain_groq import ChatGroq
from langchain.messages import HumanMessage
from langgraph.graph import StateGraph, add_messages, END
from dotenv import load_dotenv

os.environ["GROQ_API_KEY"] = "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"

llm = ChatGroq(model="llama-3.1-8b-instant")
memory = MemorySaver()

class ChatBotState(dict):
    message: list

def chatbot(state: ChatBotState):
    return {"message": [llm.invoke(state["message"])]}

graph = StateGraph(ChatBotState)
graph.add_node("chatbot", chatbot)
graph.set_entry_point("chatbot")
graph.add_edge("chatbot", END)
bot = graph.compile(checkpointer=memory)

config = {"configurable": {"thread_id": 1}}

app = FastAPI()

# CORS allow all (Flutter-friendly)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatRequest(BaseModel):
    text: str

@app.post("/chat")
def chat_api(req: ChatRequest):
    response = bot.invoke(
        {"message": [HumanMessage(content=req.text)]}, 
        config=config
    )
    reply = response["message"][-1].content
    return {"reply": reply}


#uvicorn chatbot_api:app
#http://127.0.0.1:8000/chat

#uvicorn chatbot_api:app --host 0.0.0.0 --port 8001
