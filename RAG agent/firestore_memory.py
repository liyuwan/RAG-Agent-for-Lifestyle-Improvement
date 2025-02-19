# firestore_memory.py
from config import db
from firebase_admin import firestore

class FirestoreMemory:
    def __init__(self, user_id):
        self.user_id = user_id
        self.history_ref = db.collection('users').document(self.user_id).collection('chat_history')
        self.history = self.load_memory()

    def load_memory(self):
        try:
            docs = self.history_ref.order_by('timestamp').stream()
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
        self.history_ref.add({
            'user_input': user_input,
            'bot_response': bot_response,
            'timestamp': firestore.SERVER_TIMESTAMP
        })

    def get_history(self):
        memory = self.load_memory()
        return '\n'.join([f"User: {entry['user']}\nBot: {entry['bot']}" for entry in memory])
