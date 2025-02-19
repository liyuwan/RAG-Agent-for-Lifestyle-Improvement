# qa_agent.py
from firestore_memory import FirestoreMemory
from helpers import get_user_biometric_data
from plan_generation import generate_and_save_meal_plan, generate_and_save_workout_plan
from llm_setup import qa_chain
from config import *
from vector_store import get_vector_store

SYSTEM_PROMPT = """You are a personalized AI assistant specializing in nutrition and fitness. 
Your task is to use the provided user-specific biometric data and context to create tailored meal and workout plans for users. 
Do not tell users to consult a doctor or registered dietitian for personalized plans. It is your task to provide such plans. 
Rely on the Food Data provided for creating the plans. 
Do not generate plans solely based on your own assumptions; incorporate the provided data. 
Avoid generic advice and focus on the user's individual needs. 
Avoid speculative statements."""

def call_rag_agent(query, userId):
    is_meal_plan = any(keyword in query.lower() for keyword in ['meal plan', 'meals plan', 'diet plan', 'nutrition plan'])
    is_workout_plan = any(keyword in query.lower() for keyword in ['workout plan', 'exercise plan'])
    
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
                f"- Workout level: {biometric_data.get('workoutLevelString', 'N/A')}\n"
                f"- Last Updated: {biometric_data.get('last_updated', 'N/A')}\n"
            )
        else:
            biometric_info = "No biometric data available for this user.\n"

        try:
            retrieved_docs = qa_chain.retriever.invoke(query)
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
                retrieved_docs = qa_chain.retriever.invoke(query)
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
