# plan_generation.py
import json
import logging
from helpers import invoke_llm_with_retry, extract_json_from_response, save_plan_to_firestore

def generate_nutrient_context(targets):
    return (
        f"Nutritional Targets:\n"
        f"- Calories: {targets['calories']}\n"
        f"- Protein: {targets['protein_g']}g\n"
        f"- Carbohydrates: {targets['carbs_g']}g\n"
        f"- Fats: {targets['fats_g']}g\n\n"
        "Select foods from the following options:\n"
    )

def generate_and_save_meal_plan(userId, query, SYSTEM_PROMPT, biometric_info, context_info):
    meal_instructions = (
        "Create a varied meal plan using the food items provided in the context, following these rules:\n"
        "1. Use MAXIMUM 2 servings of any single food item per day across all meals combined (e.g., an item can appear in one meal once and another meal once, but never three times total).\n"
        "2. Include different protein sources in each meal (e.g., beef in one, chicken in another).\n"
        "3. Ensure vegetables or fruits are included in at least 2 meals.\n"
        "4. Total daily calories must match the nutritional targets.\n"
        "5. Never repeat the exact same combination of food items across multiple meals.\n"
        "6. Avoid listing the same food item multiple times within a single meal unless necessary to meet nutritional targets—prioritize variety.\n\n"
        "Each entry in 'food_items' represents one serving. Select foods from the provided context below.\n\n"
        "Format as JSON:\n"
        "{\n"
        "  \"breakfast\": {\n"
        "    \"food_items\": [\"item1\", \"item2\"],\n"
        "    \"calories\": number,\n"
        "    \"protein_g\": number,\n"
        "    \"carbs_g\": number,\n"
        "    \"fats_g\": number\n"
        "  },\n"
        "  \"lunch\": {...},\n"
        "  \"dinner\": {...},\n"
        "  \"total_daily\": {\n"
        "    \"calories\": number,\n"
        "    \"protein_g\": number,\n"
        "    \"carbs_g\": number,\n"
        "    \"fats_g\": number\n"
        "  }\n"
        "}\n"
        "INCLUDE ONLY JSON! ADD NUTRITION BREAKDOWN PER MEAL!"
    )
    
    prompt = (
        f"System Instructions:\n{SYSTEM_PROMPT}\n\n"
        f"Given the following context and user information, generate a meal plan in JSON format as instructed.\n\n"
        f"User Information:\n{biometric_info}\n"
        f"Relevant Context:\n{context_info}\n"
        f"User Query: {query}\n\n"
        f"{meal_instructions}"
    )
    
    # DEBUG: Log prompt sent to LLM for meal plan generation
    logging.debug(f"Prompt for meal plan generation: {prompt}\n\n\n")
    try:
        response = invoke_llm_with_retry(prompt)
        logging.debug(f"Raw LLM response: {response}\n\n\n")
        
        meal_plan = extract_json_from_response(response)
        logging.debug(f"Parsed meal plan: {meal_plan}\n\n\n")
        
        if 'breakfast' in meal_plan:
            save_plan_to_firestore(userId, 'meal', json.dumps(meal_plan, indent=2))
        return "Your meal plan has been updated! 🥗 Check the 'Meals Plan' page to view it."
    except Exception as e:
        logging.error(f"Error in generating meal plan: {e}")
        return "Error generating meal plan. Please try again."

def generate_and_save_workout_plan(userId, query,SYSTEM_PROMPT, biometric_info, context_info):
    workout_instructions = (
        "Please generate a workout plan in JSON format using the following format:\n\n"
        '''[
        {"exercise": "name", "duration": minutes, "intensity": "low/medium/high"}
        ]'''
        "\nINCLUDE ONLY THE JSON WITH NO ADDITIONAL TEXT!\n"
    )
    prompt = (
        f"System Instructions:\n{SYSTEM_PROMPT}\n\n"
        f"Given the following context and user information, generate a workout plan in JSON format as instructed.\n\n"
        f"User Information:\n{biometric_info}\n"
        f"Relevant Context:\n{context_info}\n"
        f"User Query: {query}\n\n"
        f"{workout_instructions}"
    )
    
    # DEBUG: Log prompt sent to LLM for workout plan generation
    logging.debug(f"Prompt for workout plan generation: {prompt}")
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
