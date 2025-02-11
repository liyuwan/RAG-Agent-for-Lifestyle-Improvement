import os
import google.generativeai as genai
import speech_recognition as sr
from gtts import gTTS
from io import BytesIO
from pygame import mixer
from dotenv import load_dotenv
from datetime import date
import json
import textwrap
import string
import requests
from tqdm import tqdm
import firebase_admin
from firebase_admin import credentials, firestore
from langchain_google_genai import ChatGoogleGenerativeAI, GoogleGenerativeAIEmbeddings
from langchain_chroma import Chroma
from langchain_community.document_loaders import PyPDFLoader, DirectoryLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains import RetrievalQA
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.schema import Document
from concurrent.futures import ThreadPoolExecutor




# ---------------------- Firebase & Environment Setup ----------------------
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

def get_user_biometric_data(user_id):
    try:
        user_doc = db.collection('users').document(user_id).get()
        if user_doc.exists:
            return user_doc.to_dict()  # Returns a dictionary of biometric data
        else:
            return None
    except Exception as e:
        print(f"Error fetching user data: {e}")
        return None

mixer.init()
today = str(date.today())

dotenv_path = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(dotenv_path)
api_key = os.environ.get("GOOGLE_API_KEY")
genai.configure(api_key=api_key)

# Vector Store Configuration

persist_directory = 'db'
BATCH_SIZE = 5000  # Increase for faster embedding
vector_store_exists = os.path.exists(persist_directory)
embeddings = GoogleGenerativeAIEmbeddings(model='models/embedding-001')

# File Paths
json_file_path = "Nutrition Data/usda_food_data.json"

# Function to process JSON data
def process_json():
    json_documents = []
    if os.path.exists(json_file_path):
        with open(json_file_path, "r", encoding="utf-8") as f:
            json_data = json.load(f)
        print(f"✅ JSON file loaded successfully! Total records: {len(json_data)}")

        for i, item in enumerate(json_data):
            text_content = f"Food: {item.get('name', 'N/A')}\n"
            if 'nutrients' in item:
                nutrients_text = [f"{nutrient.get('name', 'N/A')}: {nutrient.get('amount', 'N/A')} {nutrient.get('unit', '')}" for nutrient in item['nutrients']]
                text_content += "Nutrients:\n" + "\n".join(nutrients_text)
            json_documents.append(Document(page_content=text_content, metadata={"source": "USDA"}))

            if i < 5:  # Debug print for first 5
                print(f"🔎 JSON to Text [{i+1}]:\n{text_content}\n{'-'*40}")

    return RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=20).split_documents(json_documents) if json_documents else []

# Function to process PDFs
def process_pdfs():
    loader = DirectoryLoader('Nutrition Data', glob='./*.pdf', loader_cls=PyPDFLoader)
    raw_data = loader.load()
    return RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=0).split_documents(raw_data)


# Load vector store before embedding
if vector_store_exists:
    print("Loading existing vector store...")
    vectordb = Chroma(persist_directory=persist_directory, embedding_function=embeddings)
    retriever = vectordb.as_retriever(search_kwargs={"k": 5})  # Create retriever early
    print("✅ Vector store loaded successfully!")
else:
    print("Creating new vector store...")
    vectordb = Chroma(
        persist_directory=persist_directory,
        embedding_function=embeddings
    )
    # Run JSON & PDF processing in parallel
    with ThreadPoolExecutor() as executor:
        future_json = executor.submit(process_json)
        future_pdfs = executor.submit(process_pdfs)

    usda_data = future_json.result()
    pdf_data = future_pdfs.result()

    # Combine all documents
    all_documents = usda_data + pdf_data
    print(f"📄 Total Documents: {len(all_documents)}")

    # Add documents in batches 
    print("\n💾 Adding documents to vector store...")
    for i in tqdm(range(0, len(all_documents), BATCH_SIZE), desc="Embedding"):
        batch = all_documents[i:i + BATCH_SIZE]
        vectordb.add_documents(batch)  
    print("\n✅ Vector store creation completed!")


    # Create retriever
    retriever = vectordb.as_retriever(search_kwargs={"k": 5})


# ---------------------- Initialize LLM ----------------------
llm = ChatGoogleGenerativeAI(model='gemini-1.5-pro', temperature=0.7)

'''
# ---------------------- Custom Memory Handler ----------------------
class FileBasedMemory:
    def __init__(self, memory_file='chat_history.json'):
        self.memory_file = memory_file
        self.history = self.load_memory()

    def load_memory(self):
        if os.path.exists(self.memory_file):
            with open(self.memory_file, 'r') as file:
                return json.load(file)
        return []

    def save_memory(self):
        with open(self.memory_file, 'w') as file:
            json.dump(self.history, file, indent=4)

    def append_to_history(self, user_input, bot_response):
        self.history.append({'user': user_input, 'bot': bot_response})
        self.save_memory()

    def get_history(self):
        return '\n'.join([f"User: {entry['user']}\nBot: {entry['bot']}" for entry in self.history])
'''

# ---------------------- Firestore Memory ----------------------
class FirestoreMemory:
    def __init__(self, user_id):
        self.user_id = user_id
        self.history_ref = db.collection('users').document(self.user_id).collection('chat_history')
        self.history = self.load_memory()
        
    def load_memory(self):
        try:
            history_ref = db.collection('users').document(self.user_id).collection('chat_history')
            docs = history_ref.order_by('timestamp').stream()
            return [{
                'user': doc.get('user_input'),
                'bot': doc.get('bot_response'),
                'timestamp': doc.get('timestamp')
            } for doc in docs]
        except Exception as e:
            print(f"Error loading chat history: {e}")
            return []

    def append_to_history(self, user_input, bot_response):
        # Keep only last 20 messages
        if len(self.history) >= 20:
            oldest = self.history_ref.order_by('timestamp').limit(1).get()
            for doc in oldest:
                doc.reference.delete()
        
        # Add new entry
        self.history_ref.add({
            'user_input': user_input,
            'bot_response': bot_response,
            'timestamp': firestore.SERVER_TIMESTAMP
        })

    def get_history(self):
        memory = self.load_memory()
        return '\n'.join([f"User: {entry['user']}\nBot: {entry['bot']}" for entry in memory])


# ---------------------- Initialize QA Chain ----------------------
qa_chain = RetrievalQA.from_chain_type(
    llm=llm,
    chain_type="stuff",
    retriever=retriever,
    return_source_documents=True  # Enable source document return
)

# ---------------------- Helper Functions ----------------------
'''
def wrap_text_preserve_newlines(text, width=110):
    lines = text.split('\n')
    wrapped_lines = [textwrap.fill(line, width=width) for line in lines]
    return '\n'.join(wrapped_lines).rstrip('\n')

def process_llm_response(llm_response):
    final_response = wrap_text_preserve_newlines(
        llm_response.get('result', 'No response generated.')
    )
    
    source_info = "\n\nSources:\n"
    if 'source_documents' in llm_response and llm_response["source_documents"]:
        relevant_sources = [
            source.metadata.get('source', 'Unknown Source')
            for source in llm_response["source_documents"]
            if source.metadata.get('relevance_score', 0) > 0.5
        ]
        if relevant_sources:
            for i, source_name in enumerate(relevant_sources):
                source_info += f"{i + 1}. {source_name}\n"
        else:
            source_info += "No relevant sources found.\n"
    else:
        source_info += "No sources found.\n"

    final_response_with_sources = final_response + source_info

    return final_response_with_sources
'''

def speak_text(text):
    try:
        cleaned_text = text.replace('\n', ' ').strip()
        if len(cleaned_text) > 200:
            chunks = [cleaned_text[i:i+200] for i in range(0, len(cleaned_text), 200)]
            for chunk in chunks:
                tts = gTTS(text=chunk, lang='en')
                with BytesIO() as mp3_file:
                    tts.write_to_fp(mp3_file)
                    mp3_file.seek(0)
                    mixer.music.load(mp3_file)
                    mixer.music.play()
                    while mixer.music.get_busy():
                        pass
        else:
            tts = gTTS(text=cleaned_text, lang='en')
            with BytesIO() as mp3_file:
                tts.write_to_fp(mp3_file)
                mp3_file.seek(0)
                mixer.music.load(mp3_file)
                mixer.music.play()
                while mixer.music.get_busy():
                    pass
    except Exception as e:
        print(f"Error speaking text: {e}")

def listen_for_audio():
    recognizer = sr.Recognizer()
    mic = sr.Microphone()
    recognizer.dynamic_energy_threshold = False
    recognizer.energy_threshold = 400

    with mic as source:
        recognizer.adjust_for_ambient_noise(source, duration=0.5)
        print("Listening for your query...")
        audio = recognizer.listen(source, timeout=30, phrase_time_limit=30)
    
    try:
        request = recognizer.recognize_google(audio, language="en-EN")
        return request
    except Exception as e:
        print("Error recognizing speech:", e)
        return None


# ---------------------- Main RAG Agent Function ----------------------

# Store the system prompt globally so it's not included in every request
SYSTEM_PROMPT = """You are a personalized AI assistant specializing in nutrition and fitness. 
Your task is to use the provided user-specific biometric data and context to create tailored meal and workout plans for users. 
Do not tell users to consult a doctor or registered dietitian for personalized plans. It is your task to provide such plans. 
Rely on the Food Data provided for creating the plans. 
Do not generate plans solely based on your own assumptions; incorporate the provided data. 
Avoid generic advice and focus on the user's individual needs. 
Keep the answers brief, with a maximum of 6 lines. 
Avoid speculative statements."""

def call_rag_agent(query, userId):  
    # Retrieve relevant documents from your nutrition PDFs
    try:
        retrieved_docs = retriever.invoke(query)
    except Exception as e:
        print(f"Error during retrieval: {e}")
        retrieved_docs = []

    context_info = (
        f"Here is some information from your Nutrition Data PDFs and USDA food data that might help:\n"
        f"{' '.join([doc.page_content for doc in retrieved_docs[:3]])}\n"
        if retrieved_docs else "No relevant information found in Nutrition Data PDFs.\n"
    )

    # Get the conversation history from Firestore
    memory = FirestoreMemory(userId)
    
    conversation_history = memory.get_history()

    # Fetch biometric data
    biometric_data = get_user_biometric_data(userId)
    if biometric_data:
        biometric_info = (
            f"User's Biometric Data:\n"
            f"- Name: {biometric_data.get('name', 'N/A')}\n"
            f"- Age: {biometric_data.get('age', 'N/A')} years\n"
            f"- Height: {biometric_data.get('height', 'N/A')} cm\n"
            f"- Weight: {biometric_data.get('weight', 'N/A')} kg\n"
            f"- Heart Conditions: {biometric_data.get('healthConditions', 'None')}\n"
            f"- Food Allergies: {biometric_data.get('foodAllergies', 'None')}\n"
            f"- Preference Food: {biometric_data.get('preferenceFood', 'None')}\n"
            f"- Fitness Goals: Endurance({biometric_data.get('fitnessGoals', {}).get('endurance', False)}), "
            f"Muscle Gain({biometric_data.get('fitnessGoals', {}).get('muscleGain', False)}), "
            f"Strength({biometric_data.get('fitnessGoals', {}).get('strength', False)}), "
            f"Weight Loss({biometric_data.get('fitnessGoals', {}).get('weightLoss', False)})\n"
            f"- Last Updated: {biometric_data.get('last_updated', 'N/A')}\n"
        )
    else:
        biometric_info = "No biometric data available for this user.\n"
    

    # Build final prompt dynamically
    prompt =(
        f"Given the following context and user information, please respond to the user's query.\n\n"
        f"Assistant Role and Guidelines:\n{SYSTEM_PROMPT}\n\n"
        f"User Information:\n{biometric_info}\n"
        f"Relevant Context:\n{context_info}\n"
        f"Conversation History:\n{conversation_history}\n\n"
        f"User Query: {query}"
    )

    # Invoke LLM with stored system prompt
    try:
        response = qa_chain.invoke(prompt)

        final_response = response['result'].rstrip('\n')
        memory.append_to_history(query, final_response)

        return final_response
    except Exception as e:
        print(f"Error during QA chain execution: {e}")
        return "I apologize, but I encountered an error processing your request. Please try again."
