# helpers.py
import json
import re
from io import BytesIO
from pygame import mixer
from gtts import gTTS
import speech_recognition as sr
from firebase_admin import firestore
from config import db
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
from google.api_core.exceptions import ResourceExhausted
from llm_setup import llm

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

def save_plan_to_firestore(user_id, plan_type, plan_content, target_date):
    plan_data = json.loads(plan_content)
    
    # Determine the collection based on the plan type
    if plan_type.lower() == 'meal':
        collection_name = 'meal_plans'
    elif plan_type.lower() == 'workout':
        collection_name = 'workout_plans'
    else:
        collection_name = 'other_plans'  # Default collection for other plan types

    plan_ref = db.collection('users').document(user_id).collection(collection_name).document()
    plan_ref.set({
        'type': plan_type.lower(),
        'content': plan_content,
        'date': firestore.SERVER_TIMESTAMP,
        'target_date': target_date,
        'metadata': {
            'calories': None,
            'exercises': [],
            'ingredients': []
        }
    })

    # Retrieve all plans and sort by date
    plans_query = db.collection('users').document(user_id).collection(collection_name).order_by('date', direction=firestore.Query.DESCENDING)
    plans = plans_query.stream()
    plan_ids = [plan.id for plan in plans]

    # Keep only the latest 42 plans (plans for 6 weeks)
    if len(plan_ids) > 42:
        for plan_id in plan_ids[42:]:
            db.collection('users').document(user_id).collection(collection_name).document(plan_id).delete()

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
    return llm.invoke(prompt).content.rstrip('\n')

def extract_json_from_response(text):
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        json_match = re.search(r'```(?:json)?\s*({.*?}|\[.*?])\s*```', text, re.DOTALL)
        if json_match:
            return json.loads(json_match.group(1).strip())
        
        # Fallback: extract from first {} or [] block
        start = text.find('{')
        end = text.rfind('}') + 1
        if start != -1 and end != 0:
            return json.loads(text[start:end])
        
        start = text.find('[')
        end = text.rfind(']') + 1
        if start != -1 and end != 0:
            return json.loads(text[start:end])
        
        raise ValueError("No valid JSON found")
