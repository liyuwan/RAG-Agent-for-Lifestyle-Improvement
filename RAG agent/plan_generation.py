# plan_generation.py
import json
import logging
from datetime import datetime, timedelta
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

def generate_and_save_meal_plan(userId, query, SYSTEM_PROMPT, biometric_info, food_menu, isWeekly, start_date=None):
    meal_instructions = (
        "Create a balanced meal plan using the food items provided, following these rules:\n"
        "1. Use MAX 2 servings of any single food item per day across all meals (e.g., item can appear twice total).\n"
        "2. Include different WHOLE FOOD protein sources in each meal (e.g., chicken, eggs, legumes) - limit protein bars/shakes to 1 serving daily.\n"
        "3. Include VEGETABLES in at least 2 meals (fruit smoothies don't count as vegetables).\n"
        "4. Ensure each meal contains balanced macros: 20-35% protein, 30-50% carbs, 15-35% fats.\n"
        "5. Total daily calories must match nutritional targets (±5%). Verify meal sums mathematically.\n"
        "6. Never repeat exact food combinations across meals - prioritize diverse ingredients.\n"
        "7. Avoid processed snacks as main meal components - use only as supplements if needed.\n\n"
        "Nutritional Guidelines:\n"
        "- Breakfast: 400-600 calories\n"
        "- Lunch: 500-700 calories\n"
        "- Dinner: 500-700 calories\n"
        "- Total Daily: 1500-2000 calories\n\n"
        "Format as JSON with per-meal nutrition and verification section:\n"
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
        "    \"calories\": SUM(meals),\n"
        "    \"protein_g\": SUM(meals),\n"
        "    \"carbs_g\": SUM(meals),\n"
        "    \"fats_g\": SUM(meals)\n"
        "  },\n"
        "  \"verification\": {\n"
        "    \"max_serving_check\": bool,\n"
        "    \"vegetable_inclusion\": bool,\n"
        "    \"protein_variety_check\": bool\n"
        "  }\n"
        "}\n"
        "INCLUDE ONLY JSON! DOUBLE-CHECK CALORIE MATH!"
    )
    weekly_meal_plans = []
    # Use the provided start_date or default to today
    start_date = start_date or datetime.now().date()
    start_date = datetime.combine(start_date, datetime.min.time())  # Ensure time is set to 00:00:00
    
    days_range = 7 if isWeekly else 1
    for day in range(days_range):
        prompt = (
            f"System Instructions:\n{SYSTEM_PROMPT}\n\n"
            f"Given the following context and user information, generate a meal plan in JSON format as instructed.\n\n"
            f"User Information:\n{biometric_info}\n"
            f"Food menu:\n{food_menu}\n"
            f"User Query: {query}\n\n"
            f"{meal_instructions}"
        )
        
        # DEBUG: Log prompt sent to LLM for meal plan generation
        logging.debug(f"Prompt for meal plan generation (Day {day + 1}): {prompt}\n\n\n")
        try:
            response = invoke_llm_with_retry(prompt)
            logging.debug(f"Raw LLM response (Day {day + 1}): {response}\n\n\n")
            
            meal_plan = extract_json_from_response(response)
            logging.debug(f"Parsed meal plan (Day {day + 1}): {meal_plan}\n\n\n")
            
            if 'breakfast' in meal_plan:
                target_date = start_date + timedelta(days=day)
                meal_plan_data = {
                    'meal_plan': meal_plan,
                    'target_date': target_date
                }
                weekly_meal_plans.append(meal_plan_data)
        except Exception as e:
            logging.error(f"Error in generating meal plan for day {day + 1}: {e}")
            return "Error generating meal plan. Please try again."
    
    if weekly_meal_plans:
        for meal_plan_data in weekly_meal_plans:
            # Remove target_date from meal_plan content
            meal_plan_content = meal_plan_data['meal_plan']
            save_plan_to_firestore(userId, 'meal', json.dumps(meal_plan_content, indent=2), meal_plan_data['target_date'])
        return "Your weekly meal plan has been updated! 🥗 Check the 'Meals Plan' page to view it."
    else:
        return "Error generating weekly meal plan. Please try again."

def generate_and_save_workout_plan(userId, query, SYSTEM_PROMPT, biometric_info, isWeekly, start_date=None):
    workout_instructions = (
        "Please generate a workout plan in JSON format using the following format:\n\n"
        '''[
        {"exercise": "name", "duration": minutes, "intensity": "low/medium/high"}
        ]'''
        "\nINCLUDE ONLY THE JSON WITH NO ADDITIONAL TEXT!\n"
        "IMPORTANT: Tailor the workout plan to the user's specified workout level. For example, if the user's workout level is 'very mild', ensure that all exercises are low intensity, gentle, and include sufficient rest periods."
        "Also, design the workout as a single session that fits within a reasonable daily timeframe (e.g., 30 to 60 minutes total), and do not include unrealistic rest durations (e.g., no 'Rest' exercise with durations exceeding a few minutes). "
        "Ensure that the workout session does not contain multiple rounds in the same day unless explicitly specified."
    )
    
    weekly_workout_plans = []
    # Use the provided start_date or default to today
    start_date = start_date or datetime.now().date()
    start_date = datetime.combine(start_date, datetime.min.time())  # Ensure time is set to 00:00:00
    
    days_range = 7 if isWeekly else 1
    for day in range(days_range):
        prompt = (
            f"System Instructions:\n{SYSTEM_PROMPT}\n\n"
            f"Given the following context and user information, generate a workout plan in JSON format as instructed.\n\n"
            f"User Information:\n{biometric_info}\n"
            f"User Query: {query}\n\n"
            f"{workout_instructions}"
        )
        
        # DEBUG: Log prompt sent to LLM for workout plan generation
        logging.debug(f"Prompt for workout plan generation (Day {day + 1}): {prompt}\n\n\n")
        try:
            response = invoke_llm_with_retry(prompt)
            logging.debug(f"Raw LLM response (Day {day + 1}): {response}\n\n\n")
            
            workout_plan = extract_json_from_response(response)
            logging.debug(f"Parsed workout plan (Day {day + 1}): {workout_plan}\n\n\n")
            
            if workout_plan:
                target_date = start_date + timedelta(days=day)
                workout_plan_data = {
                    'workout_plan': workout_plan,
                    'target_date': target_date
                }
                weekly_workout_plans.append(workout_plan_data)
        except Exception as e:
            logging.error(f"Error in generating workout plan for day {day + 1}: {e}")
            return "Error generating workout plan. Please try again."
    
    if weekly_workout_plans:
        for workout_plan_data in weekly_workout_plans:
            # Remove target_date from workout_plan content
            workout_plan_content = workout_plan_data['workout_plan']
            save_plan_to_firestore(userId, 'workout', json.dumps(workout_plan_content, indent=2), workout_plan_data['target_date'])
        return "Your weekly workout plan has been updated! 💪 Check the 'Workout Plan' page to view it."
    else:
        return "Error generating weekly workout plan. Please try again."
