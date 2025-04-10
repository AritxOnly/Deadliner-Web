from flask import Blueprint, request, jsonify
from app.core.litellm_handler import generate_response
from app.model.models import Model, ModelType

llm_bp = Blueprint('llm', __name__, url_prefix='/llm')

@llm_bp.route('/generate', methods=['POST'])
def handle_generate():
    data = request.json
    model = Model(
        type=ModelType(data.get('model')),
        api_key=None
    )
    response = generate_response(
        model_instance=model, 
        messages=data.get('messages')
    )
    print(response['choices'][0]['message']['content'])
    return jsonify(response)
