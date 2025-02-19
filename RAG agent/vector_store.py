# vector_store.py
import os
from langchain_google_genai import GoogleGenerativeAIEmbeddings
from langchain_chroma import Chroma
from tqdm import tqdm
from config import PERSIST_DIRECTORY, BATCH_SIZE
from data_processing import load_all_documents

# Initialize the embedding function
embeddings = GoogleGenerativeAIEmbeddings(model='models/embedding-001')

def get_vector_store():
    if os.path.exists(PERSIST_DIRECTORY):
        print("Loading existing vector store...")
        vectordb = Chroma(persist_directory=PERSIST_DIRECTORY, embedding_function=embeddings)
        retriever = vectordb.as_retriever(search_kwargs={"k": 5})
        print("✅ Vector store loaded successfully!")
    else:
        print("Creating new vector store...")
        vectordb = Chroma(persist_directory=PERSIST_DIRECTORY, embedding_function=embeddings)
        all_documents = load_all_documents(BATCH_SIZE)
        print("\n💾 Adding documents to vector store...")
        for i in tqdm(range(0, len(all_documents), BATCH_SIZE), desc="Embedding"):
            batch = all_documents[i:i + BATCH_SIZE]
            vectordb.add_documents(batch)
        print("\n✅ Vector store creation completed!")
        retriever = vectordb.as_retriever(search_kwargs={"k": 5})
    return retriever, vectordb
