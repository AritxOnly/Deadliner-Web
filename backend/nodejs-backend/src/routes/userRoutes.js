const express = require('express');
const router = express.Router();

const UserService = require('../services/userService');

const userService = new UserService();

router.get('/:id', (req, res) => {
    const userId = req.params.id
    if (userId) {
        userService.getUserInfo(userId);
    } else {
        console.log("Invalid user ID");
    }
});

router.get('/:username/prefs', (req, res) => {
    const username = req.params.username
    if (username) {
        const prefs = userService.getUserPrefs(username);
        prefs.then((prefs) => {
            res.json(prefs);
        });
    } else {
        console.log("Invalid username");
    }
})

router.post('/:username/prefs', (req, res) => {
    const username = req.params.username
    const prefs = req.body.prefs
    if (username && prefs) {
        userService.updateUserPrefs(username, prefs);
        res.json(prefs);
    } else {
        console.log("Invalid username");
    }
})

module.exports = router;