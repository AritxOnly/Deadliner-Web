from dataclasses import dataclass
import enum
import os
from dotenv import load_dotenv

# 加载.env文件中的环境变量
load_dotenv()

class ModelType(enum.Enum):
    """
    模型类型
    """
    GPT_3_5_TURBO = "gpt-3.5-turbo"
    GPT_4 = "gpt-4"
    DEEPSEEK_V3 = "deepseek/deepseek-chat"
    DEEPSEEK_R1 = "deepseek/deepseek-reasoner"
    
@dataclass
class Model:
    """
    模型
    """
    type: ModelType
    api_key: str = None
    
    def __post_init__(self):
        # 如果没有提供api_key，尝试从环境变量获取
        if self.api_key is None:
            if self.type in [ModelType.DEEPSEEK_V3, ModelType.DEEPSEEK_R1]:
                self.api_key = os.environ.get('DEEPSEEK_API_KEY')
            elif self.type in [ModelType.GPT_3_5_TURBO, ModelType.GPT_4]:
                self.api_key = os.environ.get('OPENAI_API_KEY')