/**
 * 生成用于AI规划的提示
 * 根据DDLItem类型生成不同的提示内容
 */
class AIPromptGenerator {
    /**
     * 根据DDLItem生成AI提示
     * @param {DDLItem} ddlItem - DDL项目对象
     * @returns {string} 生成的提示文本
     */
    static generatePrompt(ddlItem) {
        // 基础信息部分
        const baseInfo = `
任务名称: ${ddlItem.name}
开始时间: ${ddlItem.startTime || '未设置'}
截止时间: ${ddlItem.endTime || '未设置'}
任务类型: ${ddlItem.type}
完成状态: ${ddlItem.isCompleted ? '已完成' : '未完成'}
`;

        // 根据类型生成不同的提示
        if (ddlItem.type === 'habit') {
            // 习惯类型，解析note字段中的JSON数据
            try {
                const habitData = JSON.parse(ddlItem.note || '{}');
                const completedDates = habitData.completedDates || new Set();
                const frequencyType = habitData.frequencyType || '未设置';
                const frequency = habitData.frequency || 0;
                const total = habitData.total || 0;
                const refreshDate = habitData.refreshDate || '未设置';

                return `
请帮我规划以下习惯养成计划:
${baseInfo}
习惯频率类型: ${frequencyType}
习惯频率: ${frequency}
总计次数: ${total}
刷新日期: ${refreshDate}
已完成日期数: ${completedDates.size}
当前完成次数: ${ddlItem.habitCount || 0}

请根据以上信息，提供以下建议:
1. 如何保持这个习惯的连续性
2. 针对当前进度的鼓励和建议
3. 如何提高习惯的执行效率
4. 克服可能遇到的困难的策略
5. 下一阶段的目标设定
`;
            } catch (e) {
                // JSON解析失败，使用默认习惯提示
                return `
请帮我规划以下习惯养成计划:
${baseInfo}
当前完成次数: ${ddlItem.habitCount || 0}

请提供习惯养成的建议和如何保持动力的方法。
`;
            }
        } else {
            // 普通任务类型
            return `
请帮我规划以下截止日期任务:
${baseInfo}
任务备注: ${ddlItem.note || '无'}

请根据以上信息，提供以下建议:
1. 任务分解：将这个任务分解为哪些具体步骤
2. 时间规划：如何合理安排时间完成这个任务
3. 优先级建议：这个任务的优先级如何，应该何时开始处理
4. 可能的风险：完成过程中可能遇到的困难和解决方案
5. 资源需求：完成任务可能需要的资源或工具
`;
        }
    }

    /**
     * 根据DDLItem生成AI提示（进阶版：要求输出json）
     * @param {DDLItem} ddlItem - DDL项目对象
     * @returns {string} 生成的提示文本
     */
    static generateAdvancedPrompt(ddlItem) {
        // 基础信息部分
        const baseInfo = `
任务名称: ${ddlItem.name}
开始时间: ${ddlItem.startTime || '未设置'}
截止时间: ${ddlItem.endTime || '未设置'}
任务类型: ${ddlItem.type}
完成状态: ${ddlItem.isCompleted ? '已完成' : '未完成'}
`;

        // 根据类型生成不同的提示
        if (ddlItem.type === 'habit') {
            // 习惯类型，解析note字段中的JSON数据
            try {
                const habitData = JSON.parse(ddlItem.note || '{}');
                const completedDates = habitData.completedDates || new Set();
                const frequencyType = habitData.frequencyType || '未设置';
                const frequency = habitData.frequency || 0;
                const total = habitData.total || 0;
                const refreshDate = habitData.refreshDate || '未设置';

                return `
请帮我规划以下习惯养成计划:
${baseInfo}
习惯频率类型: ${frequencyType}
习惯频率: ${frequency}
总计次数: ${total}
刷新日期: ${refreshDate}
已完成日期数: ${completedDates.size}
当前完成次数: ${ddlItem.habitCount || 0}

请根据以上信息，提供下面这样的JSON格式的任务划分：
{
    "阶段1": ["startTime", "endTime", "description"],
    "阶段2": ["startTime", "endTime", "description"],
    ...
    "阶段n": ["startTime", "endTime", "description"]
}
`;
            } catch (e) {
                // JSON解析失败，使用默认习惯提示
                return `
请帮我规划以下习惯养成计划:
${baseInfo}
当前完成次数: ${ddlItem.habitCount || 0}

请提供习惯养成的建议和如何保持动力的方法。
`;
            }
        } else {
            // 普通任务类型
            return `
请帮我规划以下截止日期任务:
${baseInfo}
任务备注: ${ddlItem.note || '无'}

请根据以上信息，提供下面这样的JSON格式的任务划分：
{
    "阶段1": ["startTime", "endTime", "description"],
    "阶段2": ["startTime", "endTime", "description"],
    ...
    "阶段n": ["startTime", "endTime", "description"]
}
`;
        }
    }
}

module.exports = AIPromptGenerator;