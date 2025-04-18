const express = require('express');
const router = express.Router();

const UserService = require('../services/userService');

const userService = new UserService();

// 用户注册
router.post('/register', async (req, res) => {
    try {
        const { username, password } = req.body;
        if (!username || !password) {
            return res.status(400).json({ error: 'Missing username or password' });
        }
        
        const userId = await userService.register(username, password);
        const token = userService.generateToken({ id: userId, username });
        res.json({ token });
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

// 用户登录
router.post('/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        if (!username || !password) {
            return res.status(400).json({ error: 'Missing username or password' });
        }

        const token = await userService.login(username, password);
        console.log(`User ${username} logged in with token ${token}`);
        res.json({ token });
    } catch (err) {
        res.status(401).json({ error: err.message });
    }
});

module.exports = router;