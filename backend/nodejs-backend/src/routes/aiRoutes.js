const express = require('express');
const DDLItem = require('../models/DDLItem');
const AIService = require('../services/aiService');
const DBService = require('../services/dbService');

const router = express.Router();

const dbService = new DBService();
const aiService = new AIService();

router.get('/plan/:id', async (req, res) => {
    try {
        const id = req.params.id;
        // 使用 await 等待异步操作完成
        const ddlItem = await dbService.getDDLById(id);
        
        if (!ddlItem) {
            return res.status(404).json({ error: "DDL item not found" });
        }
        
        const response = await aiService.planDeadline(ddlItem);
        res.json(response);
    } catch (error) {
        console.error("Error in /plan/:id route:", error);
        res.status(500).json({ 
            message: "Something went wrong!", 
            error: error.message 
        });
    }
});

// Todo:

module.exports = router;