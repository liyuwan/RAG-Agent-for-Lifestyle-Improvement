# plan_generation.py
import json
import logging
from helpers import invoke_llm_with_retry, extract_json_from_response, save_plan_to_firestore

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
        logging.debug(f"Raw LLM response: {response}")
        
        meal_plan = extract_json_from_response(response)
        logging.debug(f"Parsed meal plan: {meal_plan}")
        
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
        {"exercise": "name", "duration": minutes, "intensity": "low/medium/high"}
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
        logging.debug(f"Raw LLM response: {response}")
        
        workout_plan = extract_json_from_response(response)
        logging.debug(f"Parsed workout plan: {workout_plan}")
        
        if isinstance(workout_plan, list) and workout_plan:
            save_plan_to_firestore(userId, 'workout', json.dumps(workout_plan, indent=2))
        return "Workout plan updated. 💪 Please check your workout plan page."
    except Exception as e:
        logging.error(f"Error in generating workout plan: {e}")
        return "Error generating workout plan. Please try again."
