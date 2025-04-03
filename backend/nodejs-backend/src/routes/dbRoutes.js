const express = require('express');
const router = express.Router();

const DBService = require('../services/dbService');
const DDLItem = require('../models/DDLItem');

dbService = new DBService();

router.get('/items', (req, res) => {
    dbService.getAllDDLs().then((items) => {
        res.json(items);
    }).catch((err) => {
        res.status(500).json({ error: err.message });
    });
});

router.get('/items/:id', (req, res) => {
    const id = req.params.id;
    dbService.getDDLById(id).then((item) => {
        res.json(item);
    }).catch((err) => {
        res.status(500).json({ error: err.message });
    });
});

router.post('/items', (req, res) => {
    const item = req.body;
    dbService.insertDDL(
        item.name,
        item.startTime,
        item.endTime,
        item.note,
        item.type
    ).then((id) => {
        res.json({ id });
    }).catch((err) => {
        res.status(500).json({ error: err.message });
    });
});

router.put('/items/:id', (req, res) => {
    const body = req.body;
    dbService.getDDLById(req.params.id).then(orgItem => {
        const item = new DDLItem({
            id: req.params.id,
            name: body.name ?? orgItem.name,
            startTime: body.startTime ?? orgItem.startTime,
            endTime: body.endTime ?? orgItem.endTime,
            isCompleted: body.isCompleted ?? orgItem.isCompleted,
            completeTime: body.completeTime ?? orgItem.completeTime,
            note: body.note ?? orgItem.note,
            isArchived: body.isArchived ?? orgItem.isArchived,
            isStared: body.isStared ?? orgItem.isStared,
            type: body.type ?? orgItem.type,
            habitCount: body.habitCount ?? orgItem.habitCount
        });
        return dbService.updateDDL(item);
    }).then(() => {
        res.json({ success: true });
    }).catch((err) => {
        res.status(500).json({ error: err.message });
    });
});

router.delete('/items/:id', (req, res) => {
    const id = req.params.id;
    dbService.deleteDDL(id).then(() => {
        res.json({ success: true });
    }).catch((err) => {
        res.status(500).json({ error: err.message });
    });
});

module.exports = router;