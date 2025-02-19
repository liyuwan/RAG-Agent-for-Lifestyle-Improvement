# data_processing.py
import os
import json
from langchain.schema import Document
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFLoader, DirectoryLoader
from config import JSON_FILE_PATH
from tqdm import tqdm
from concurrent.futures import ThreadPoolExecutor

def process_json():
    json_documents = []
    if os.path.exists(JSON_FILE_PATH):
        with open(JSON_FILE_PATH, "r", encoding="utf-8") as f:
            json_data = json.load(f)
        print(f"✅ JSON file loaded successfully! Total records: {len(json_data)}")

        for i, item in enumerate(json_data):
            text_content = f"Food: {item.get('name', 'N/A')}\n"
            if 'nutrients' in item:
                nutrients_text = [
                    f"{nutrient.get('name', 'N/A')}: {nutrient.get('amount', 'N/A')} {nutrient.get('unit', '')}"
                    for nutrient in item['nutrients']
                ]
                text_content += "Nutrients:\n" + "\n".join(nutrients_text)
            json_documents.append(Document(page_content=text_content, metadata={"source": "USDA"}))

            if i < 5:  # Debug print for first 5 items
                print(f"🔎 JSON to Text [{i+1}]:\n{text_content}\n{'-'*40}")

    splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=20)
    return splitter.split_documents(json_documents) if json_documents else []

def process_pdfs():
    loader = DirectoryLoader('Nutrition Data', glob='./*.pdf', loader_cls=PyPDFLoader)
    raw_data = loader.load()
    splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=0)
    return splitter.split_documents(raw_data)

def load_all_documents(batch_size):
    with ThreadPoolExecutor() as executor:
        future_json = executor.submit(process_json)
        future_pdfs = executor.submit(process_pdfs)

    usda_data = future_json.result()
    pdf_data = future_pdfs.result()

    all_documents = usda_data + pdf_data
    print(f"📄 Total Documents: {len(all_documents)}")
    return all_documents
