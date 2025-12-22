from typing import Annotated
from dotenv import load_dotenv
from langchain_groq import ChatGroq 
from langgraph.checkpoint.memory import MemorySaver 
from typing import Annotated, TypedDict
from langchain.messages import HumanMessage
from langgraph.graph import StateGraph,add_messages,END

memory = MemorySaver()


# now load the api key from .env to our coding enviroment:)
# model means which model we wnat to use like: chatgpt-3 something like that 
# we will use a free model from facebook, with some limitation:)
load_dotenv()
llm = ChatGroq(model="llama-3.1-8b-instant")

class ChatBotState(TypedDict):
    message : Annotated[list,add_messages]



# making node:
def chatbot(state:ChatBotState):
   return {"message":[llm.invoke(state["message"])]}


#build and compline the graph:
graph = StateGraph(ChatBotState)
graph.add_node("chatbot",chatbot)
graph.set_entry_point("chatbot")
graph.add_edge("chatbot",END)

bot = graph.compile(checkpointer=memory)
config = {"configurable":{
    "thread_id":1
}}


while True:
    user_input = input("user: ")
    if user_input in ["exit","bye","end"]:
        break 
    result = bot.invoke({"message":[HumanMessage(content=user_input)]},config=config)
    print(f"bot: {result['message'][-1].content}")



