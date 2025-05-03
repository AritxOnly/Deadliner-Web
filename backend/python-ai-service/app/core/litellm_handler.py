from litellm import completion
from app.model.models import Model

"""
    # 统一的LLM调用接口
    :param model: 模型名称
    :param messages: 消息列表
    :return: 响应结果
"""
def generate_response(model_instance: Model, messages) -> dict:
    try:
        response = completion(
            model=model_instance.type.value, 
            messages=messages
        )
        return response.model_dump() if hasattr(response, "model_dump") else vars(response)
    except Exception as e:
        return { "error": str(e), "type": "LLM_API_ERROR" }