from firestore_memory import FirestoreMemory
from helpers import extract_json_from_response, get_user_biometric_data
from plan_generation import generate_and_save_meal_plan, generate_and_save_workout_plan
from llm_setup import qa_chain
from config import *
import logging

# Configure logging to show DEBUG and higher-level messages
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()  # Outputs to console
    ]
)

SYSTEM_PROMPT = """You are a knowledgeable AI assistant specializing in nutrition, fitness, and general health. 
Your primary tasks are:
1. Answer general questions about nutrition, fitness, and health with accurate, evidence-based information.
2. Create personalized meal and workout plans for users based on their biometric data and preferences.

For general questions:
- Provide clear, concise, and evidence-based answers.
- Avoid speculative statements and rely on established knowledge.

For personalized plans:
- Use the provided user-specific biometric data and context to create tailored meal and workout plans.
- Do not tell users to consult a doctor or registered dietitian for personalized plans. It is your task to provide such plans.
- Rely on the Food Data provided for creating the plans.
- Avoid generic advice and focus on the user's individual needs.

Always prioritize accuracy and clarity in your responses."""

def generate_nutrient_targets(biometric_data):
    nutrient_prompt = (
        f"Calculate DAILY nutritional targets considering:\n"
        f"1. User's weight: {biometric_data.get('weight', 'N/A')}kg\n"
        f"2. Fitness goals: {biometric_data.get('fitnessGoals', 'N/A')}\n"
        f"3. Recommended macronutrient splits\n\n"
        "Response format:\n"
        '''{
        "calories": 2000,
        "protein_g": {"min": 120, "target": 150, "max": 180},
        "carbs_g": {"min": 200, "target": 250, "max": 300},
        "fats_g": {"min": 50, "target": 70, "max": 90},
        "rationale": "short explanation"
        }'''
        "\nINCLUDE ONLY JSON!"
    )
    try:
        response = qa_chain.invoke(nutrient_prompt)
        # DEBUG: Log raw LLM response for nutrient targets
        logging.debug(f"Raw LLM response for nutrient targets: {response['result']}\n\n")
        parsed_targets = extract_json_from_response(response['result'])
        # DEBUG: Log parsed nutrient targets
        logging.debug(f"Parsed nutrient targets: {parsed_targets}\n\n\n\n\n")
        return parsed_targets
    except Exception as e:
        print(f"Error generating nutrient targets: {e}")
        return None

def call_rag_agent(query, userId):
    is_meal_plan = any(keyword in query.lower() for keyword in ['meal plan', 'meals plan', 'diet plan', 'nutrition plan'])
    is_workout_plan = any(keyword in query.lower() for keyword in ['workout plan', 'exercise plan'])
    
    if is_meal_plan or is_workout_plan:
        memory = FirestoreMemory(userId)
        biometric_data = get_user_biometric_data(userId)
        messages = []
        
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

        # Handle meal plan with nutrient-based retrieval
        if is_meal_plan:
            # Generate nutrient targets
            nutrient_targets = generate_nutrient_targets(biometric_data)
            if not nutrient_targets:
                return "Error generating nutritional targets. Please try again."
            
            # Create nutrient-based query
            nutrient_query = (
                f"Food items matching these DAILY targets:\n"
                f"- Calories: {nutrient_targets['calories']} ±10%\n"
                f"- Protein: {nutrient_targets['protein_g']['target']}g ±15%\n"
                f"FILTER BY:\n"
                f"- Food category: {biometric_data.get('preferenceFood', 'general')}\n"
                f"- Exclude allergens: {biometric_data.get('foodAllergies', 'none')}\n"
                f"PRIORITIZE items with:\n"
                f"- Complete protein sources\n"
                f"- Whole food ingredients\n"
                f"- Low processed options"
            )
            
            # DEBUG: Log nutrient query sent to retriever
            logging.debug(f"Nutrient query for retrieval: {nutrient_query}\n\n")
            
            # Retrieve relevant food items
            try:
                retrieved_docs = qa_chain.retriever.invoke(nutrient_query)
                
                # DEBUG: Log retrieved food items from vector store
                logging.debug(f"Retrieved food items for nutrient query: {[doc.page_content for doc in retrieved_docs]}\n\n\n\n\n")
                
                context_info = (
                    "Nutritional Context:\n" + 
                    "\n".join([doc.page_content for doc in retrieved_docs[:5]]) + 
                    f"\n\nDaily Targets: {nutrient_query}"
                ) if retrieved_docs else "No relevant food items found."
            except Exception as e:
                print(f"Nutrition retrieval error: {e}")
                context_info = "Nutrition data unavailable."

            messages.append(generate_and_save_meal_plan(
                userId, query, SYSTEM_PROMPT, biometric_info, context_info
            ))

        # Handle workout plan with original retrieval
        if is_workout_plan:
            try:
                retrieved_docs = qa_chain.retriever.invoke(query)
                
                # DEBUG: Log retrieved documents for workout query
                logging.debug(f"Retrieved documents for workout query: {[doc.page_content for doc in retrieved_docs]}")
                
                context_info = (
                    "Exercise Context:\n" + 
                    "\n".join([doc.page_content for doc in retrieved_docs[:3]])
                ) if retrieved_docs else "No relevant exercise data."
            except Exception as e:
                print(f"Workout retrieval error: {e}")
                context_info = "Workout data unavailable."

            messages.append(generate_and_save_workout_plan(
                userId, query, SYSTEM_PROMPT, biometric_info, context_info
            ))

        final_message = "\n".join(messages)
        memory.append_to_history(query, final_message)
        return final_message
    else:
        try:
            memory = FirestoreMemory(userId)
            conversation_history = memory.get_history()
            biometric_data = get_user_biometric_data(userId)
            
            # Handle general questions
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
        
            prompt = (
                f"System Instructions:\n{SYSTEM_PROMPT}\n\n"
                f"User Information:\n{biometric_info}\n"
                f"Conversation History:\n{conversation_history}\n\n"
                f"User Query: {query}\n\n"
                "Provide a clear, concise, and evidence-based response using your training knowledge.\n\n"
                "Use some related emojis to make the response more engaging and human-like.\n"
            )
            
            # DEBUG: Log prompt for general question
            logging.debug(f"Prompt for general question: {prompt}")
            
            response = qa_chain.invoke(prompt)
            
            # DEBUG: Log raw LLM response for general question
            logging.debug(f"Raw LLM response for general question: {response['result']}")
            final_response = response['result'].rstrip('\n')
            memory.append_to_history(query, final_response)
            return final_response
        except Exception as e:
            print(f"Error during QA chain execution: {e}")
            return "I apologize, but I encountered an error processing your request. Please try again."