import os
import google.generativeai as genai
import speech_recognition as sr
from gtts import gTTS
from io import BytesIO
from pygame import mixer
from dotenv import load_dotenv
from datetime import date
import json
import re
import textwrap
import string
import requests
from tqdm import tqdm
import logging
import firebase_admin
from firebase_admin import credentials, firestore
from langchain_google_genai import ChatGoogleGenerativeAI, GoogleGenerativeAIEmbeddings
from langchain_chroma import Chroma
from langchain_community.document_loaders import PyPDFLoader, DirectoryLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains import RetrievalQA
from langchain.schema import Document
from concurrent.futures import ThreadPoolExecutor
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
from google.api_core.exceptions import ResourceExhausted

# ---------------------- Firebase & Environment Setup ----------------------
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

mixer.init()
today = str(date.today())

dotenv_path = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(dotenv_path)
api_key = os.environ.get("GOOGLE_API_KEY")
genai.configure(api_key=api_key)

# ---------------------- Vector Store Configuration ----------------------
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
                nutrients_text = [
                    f"{nutrient.get('name', 'N/A')}: {nutrient.get('amount', 'N/A')} {nutrient.get('unit', '')}"
                    for nutrient in item['nutrients']
                ]
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
structured_llm = ChatGoogleGenerativeAI(model='gemini-1.5-pro', temperature=0.3)  # For structured outputs

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

def save_plan_to_firestore(user_id, plan_type, plan_content):
    plan_ref = db.collection('users').document(user_id).collection('plans').document()
    plan_ref.set({
        'type': plan_type.lower(),  # 'meal' or 'workout'
        'content': plan_content,
        'date': firestore.SERVER_TIMESTAMP,
        'metadata': {
            'calories': None,  # You can add parsing logic later
            'exercises': [],
            'ingredients': []
        }
    })
    return plan_ref.id

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


@retry(
    retry=retry_if_exception_type(ResourceExhausted),
    wait=wait_exponential(multiplier=2, min=2, max=60),
    stop=stop_after_attempt(5)
)
def invoke_llm_with_retry(prompt):
    return structured_llm.invoke(prompt).content.rstrip('\n')

# ---------------------- JSON-Based Plan Generation Helpers ----------------------

logging.basicConfig(level=logging.DEBUG)

def generate_and_save_meal_plan(userId, query, biometric_info, context_info, conversation_history):
    meal_instructions = (
        "Please generate a meal plan in JSON format using the following format:\n\n"
        '''{
        "breakfast": {"food_items": [], "calories": number},
        "lunch": {"food_items": [], "calories": number},
        "dinner": {"food_items": [], "calories": number}
        }'''
        "\nINCLUDE ONLY THE JSON WITH NO ADDITIONAL TEXT!\n"
    )
    prompt = (
        f"Given the following context and user information, generate a meal plan in JSON format as instructed.\n\n"
        f"User Information:\n{biometric_info}\n"
        f"Relevant Context:\n{context_info}\n"
        f"Conversation History:\n{conversation_history}\n\n"
        f"User Query: {query}\n\n"
        f"{meal_instructions}"
    )
    try:
        response = invoke_llm_with_retry(prompt)
        logging.debug(f"Raw LLM response: {response}")  # Log the raw response
        
        meal_plan = extract_json_from_response(response)
        logging.debug(f"Parsed workout plan: {meal_plan}")  # Log the parsed JSON
        
        if 'breakfast' in meal_plan:
            save_plan_to_firestore(userId, 'meal', json.dumps(meal_plan, indent=2))
        return "Your meal plan has been updated! 🥗 Check the 'Meals Plan' page to view it."
    except Exception as e:
        logging.error(f"Error in generating meal plan: {e}")
        return "Error generating meal plan. Please try again."
    
def generate_and_save_workout_plan(userId, query, biometric_info, context_info, conversation_history):
    workout_instructions = (
        "Please generate a workout plan in JSON format using the following format:\n\n"
        '''[
        {"exercise": "name", "duration": minutes, 
        "intensity": "low/medium/high"}
        ]'''
        "\nINCLUDE ONLY THE JSON WITH NO ADDITIONAL TEXT!\n"
    )
    prompt = (
        f"Given the following context and user information, generate a workout plan in JSON format as instructed.\n\n"
        f"User Information:\n{biometric_info}\n"
        f"Relevant Context:\n{context_info}\n"
        f"Conversation History:\n{conversation_history}\n\n"
        f"User Query: {query}\n\n"
        f"{workout_instructions}"
    )
    try:
        response = invoke_llm_with_retry(prompt)
        logging.debug(f"Raw LLM response: {response}")  # Log the raw response
        
        workout_plan = extract_json_from_response(response)
        logging.debug(f"Parsed workout plan: {workout_plan}")  # Log the parsed JSON
        
        
        # Check if the result is a non-empty list
        if isinstance(workout_plan, list) and workout_plan:
            save_plan_to_firestore(userId, 'workout', json.dumps(workout_plan, indent=2))
        return "Workout plan updated. 💪 Please check your workout plan page."
    except Exception as e:
        logging.error(f"Error in generating workout plan: {e}")
        return "Error generating workout plan. Please try again."
    
def extract_json_from_response(text):
    try:
        # Try parsing the entire text as JSON
        return json.loads(text)
    except json.JSONDecodeError:
        # Handle code blocks with or without 'json' specifier
        json_match = re.search(r'```(?:json)?\s*({.*?}|\[.*?])\s*```', text, re.DOTALL)
        if json_match:
            return json.loads(json_match.group(1).strip())
        
        # Fallback to extracting first {...} or [...]
        start = text.find('{')  # Look for the start of a JSON object
        end = text.rfind('}') + 1  # Look for the end of a JSON object
        if start != -1 and end != 0:
            return json.loads(text[start:end])
        
        start = text.find('[')  # Look for the start of a JSON array
        end = text.rfind(']') + 1  # Look for the end of a JSON array
        if start != -1 and end != 0:
            return json.loads(text[start:end])
        
        raise ValueError("No valid JSON found")    
    
# ---------------------- Main RAG Agent Function ----------------------
SYSTEM_PROMPT = """You are a personalized AI assistant specializing in nutrition and fitness. 
Your task is to use the provided user-specific biometric data and context to create tailored meal and workout plans for users. 
Do not tell users to consult a doctor or registered dietitian for personalized plans. It is your task to provide such plans. 
Rely on the Food Data provided for creating the plans. 
Do not generate plans solely based on your own assumptions; incorporate the provided data. 
Avoid generic advice and focus on the user's individual needs. 
Keep the answers brief, with a maximum of 6 lines. 
Avoid speculative statements."""

def call_rag_agent(query, userId):
    # Check if the query is about generating a plan
    is_meal_plan = any(keyword in query.lower() for keyword in ['meal plan', 'meals plan', 'diet plan', 'nutrition plan'])
    is_workout_plan = any(keyword in query.lower() for keyword in ['workout plan', 'exercise plan'])
    
    # If the query is for plan generation, call the specialized helper functions.
    if is_meal_plan or is_workout_plan:
        memory = FirestoreMemory(userId)
        conversation_history = memory.get_history()
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
        
        messages = []
        if is_meal_plan:
            messages.append(generate_and_save_meal_plan(userId, query, biometric_info, context_info, conversation_history))
        if is_workout_plan:
            messages.append(generate_and_save_workout_plan(userId, query, biometric_info, context_info, conversation_history))
        final_message = "\n".join(messages)
        memory.append_to_history(query, final_message)
        return final_message
    else:
        # Otherwise, use the default QA chain processing
        try:
            memory = FirestoreMemory(userId)
            conversation_history = memory.get_history()
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
            prompt = (
                f"Given the following context and user information, please respond to the user's query.\n\n"
                f"Assistant Role and Guidelines:\n{SYSTEM_PROMPT}\n\n"
                f"User Information:\n{biometric_info}\n"
                f"Conversation History:\n{conversation_history}\n\n"
                f"User Query: {query}\n"
            )
            response = qa_chain.invoke(prompt)
            final_response = response['result'].rstrip('\n')
            memory.append_to_history(query, final_response)
            return final_response
        except Exception as e:
            print(f"Error during QA chain execution: {e}")
            return "I apologize, but I encountered an error processing your request. Please try again."
