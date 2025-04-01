# llm_setup.py
from langchain_google_genai import ChatGoogleGenerativeAI

# Initialize LLMs
llm = ChatGoogleGenerativeAI(model='gemini-1.5-pro', temperature=0.3)