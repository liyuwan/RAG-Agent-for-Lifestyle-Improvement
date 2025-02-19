# llm_setup.py
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.chains import RetrievalQA
from vector_store import get_vector_store

# Initialize LLMs
llm = ChatGoogleGenerativeAI(model='gemini-1.5-pro', temperature=0.7)
structured_llm = ChatGoogleGenerativeAI(model='gemini-1.5-pro', temperature=0.3)

# Setup the QA chain
def get_qa_chain(retriever):
    return RetrievalQA.from_chain_type(
        llm=llm,
        chain_type="stuff",
        retriever=retriever,
        return_source_documents=True
    )

# Load the retriever and initialize QA chain immediately if desired
retriever, _ = get_vector_store()
qa_chain = get_qa_chain(retriever)
