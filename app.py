from flask import Flask, request, jsonify
from nutrition_rag import call_rag_agent, listen_for_audio, speak_text

app = Flask(__name__)

# Define route for text query
@app.route('/query', methods=['POST'])
def query_rag():
    data = request.get_json()  # Get the JSON data from the request
    user_query = data.get('query', '')  # Extract the query
    user_id = data.get('user_id', '')  # Extract the user ID
    
    if not user_query or not user_id:
        return jsonify({"error": "Query and user_id are required"}), 400
    
    # Call RAG agent with the user ID
    response = call_rag_agent(user_query, user_id)
    
    return jsonify({"response": response}), 200


if __name__ == '__main__':
    app.run(debug=True)
