const axios = require('axios');
const AIPromptGenerator = require('../utils/aiPromptGenerator');
const DDLItem = require('../models/DDLItem');

class AIService {
    constructor() {
        // AIPromptGenerator 是静态类，不需要实例化
    }

    async planDeadline(ddlItem) {
        // 正确的类型检查方式
        if (ddlItem && ddlItem instanceof Object) {
            try {
                // 使用静态方法生成提示
                const message = AIPromptGenerator.generatePrompt(ddlItem);
                
                // 使用 await 处理 axios 请求
                const response = await axios.post(
                    'http://localhost:5001/llm/generate',
                    {
                        model: 'deepseek/deepseek-chat',
                        messages: [{
                            role: 'user',
                            content: message
                        }]
                    }
                );
                
                // 返回实际的响应数据
                return response.data;
            } catch (error) {
                console.error("AI service error:", error);
                throw new Error("Failed to get AI response: " + error.message);
            }
        } else {
            throw new Error("Invalid DDLItem");
        }
    }
}

module.exports = AIService;