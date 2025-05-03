const express = require('express');
const router = express.Router();

const UserService = require('../services/userService');

const userService = UserService();

router.get('/:id', (req, res) => {
    const userId = req.params.id
    if (userId) {
        userService.getUserInfo(userId);
    } else {
        console.log("Invalid user ID");
    }
});