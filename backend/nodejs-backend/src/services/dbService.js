const path = require('path');
const fs = require('fs');
const sqlite3 = require('sqlite3').verbose();

const DDLItem = require('../models/DDLItem');

class DBService {
    constructor(userId) {
        if (!userId) {
            throw new Error('User ID is required to initialize DBService');
        }
        const dbDir = path.resolve(__dirname, `../../database/${userId}`);
        if (!fs.existsSync(dbDir)) {
            fs.mkdirSync(dbDir, { recursive: true });
        }
        const dbPath = path.resolve(dbDir, "deadliner.db");
        // this.db = new sqlite3.Database(dbPath); // This line seems redundant and can be removed or commented out

        this.db = new sqlite3.Database(dbPath, (err) => {
            if (err) {
                console.error('Error opening database', err);
            } else {
                console.log('Connected to database.');
                this._initialize();
            }
        });
    }

    _initialize() {
        // 创建表，注意这里用 IF NOT EXISTS 防止重复创建
        const createTableQuery = `
          CREATE TABLE IF NOT EXISTS ddl_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            is_completed INTEGER,
            complete_time TEXT NOT NULL,
            note TEXT NOT NULL,
            is_archived INTEGER,
            is_stared INTEGER,
            type TEXT NOT NULL,
            habit_count INTEGER
          )
        `;
        this.db.run(createTableQuery, (err) => {
            if (err) {
                console.error('Error creating table', err);
            }
        });
    }

    // 插入 DDL 数据
    insertDDL(name, startTime, endTime, note = "", type = "task") {
        return new Promise((resolve, reject) => {
            const sql = `
                INSERT INTO ddl_items 
                (name, start_time, end_time, is_completed, complete_time, note, is_archived, is_stared, type, habit_count)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `;
            const params = [
                name,
                startTime,
                endTime,
                0,          // is_completed: false -> 0
                "",         // complete_time
                note,
                0,          // is_archived: false -> 0
                0,          // is_stared: false -> 0
                type,
                0           // habit_count
            ];
            this.db.run(sql, params, function (err) {
                if (err) {
                    reject(err);
                } else {
                    // 返回插入记录的 id
                    resolve(this.lastID);
                }
            });
        });
    }

    // 获取所有 DDL 数据
    getAllDDLs() {
        return new Promise((resolve, reject) => {
            const sql = `SELECT * FROM ddl_items`;
            this.db.all(sql, [], (err, rows) => {
                if (err) {
                    reject(err);
                } else {
                    const results = rows.map(row => new DDLItem({
                        id: row.id,
                        name: row.name,
                        startTime: row.start_time,
                        endTime: row.end_time,
                        isCompleted: Boolean(row.is_completed),
                        completeTime: row.complete_time,
                        note: row.note,
                        isArchived: Boolean(row.is_archived),
                        isStared: Boolean(row.is_stared),
                        type: row.type,
                        habitCount: row.habit_count
                    }));
                    resolve(results);
                }
            });
        });
    }

    // 根据类型获取 DDL 数据（类型转为小写匹配）
    getDDLsByType(type) {
        return new Promise((resolve, reject) => {
            const sql = `
                SELECT * FROM ddl_items 
                WHERE type = ? 
                ORDER BY is_completed ASC, end_time ASC
            `;
            // 假设存储时类型是小写的，如果不是可在插入时处理
            this.db.all(sql, [type.toLowerCase()], (err, rows) => {
                if (err) {
                    reject(err);
                } else {
                    const results = rows.map(row => new DDLItem({
                        id: row.id,
                        name: row.name,
                        startTime: row.start_time,
                        endTime: row.end_time,
                        isCompleted: Boolean(row.is_completed),
                        completeTime: row.complete_time,
                        note: row.note,
                        isArchived: Boolean(row.is_archived),
                        isStared: Boolean(row.is_stared),
                        type: row.type,
                        habitCount: row.habit_count
                    }));
                    resolve(results);
                }
            });
        });
    }

    // 根据 id 获取单条 DDL 数据
    getDDLById(id) {
        return new Promise((resolve, reject) => {
            const sql = `SELECT * FROM ddl_items WHERE id = ?`;
            this.db.get(sql, [id], (err, row) => {
                if (err) {
                    reject(err);
                } else if (row) {
                    resolve(new DDLItem({
                        id: row.id,
                        name: row.name,
                        startTime: row.start_time,
                        endTime: row.end_time,
                        isCompleted: Boolean(row.is_completed),
                        completeTime: row.complete_time,
                        note: row.note,
                        isArchived: Boolean(row.is_archived),
                        isStared: Boolean(row.is_stared),
                        type: row.type,
                        habitCount: row.habit_count
                    }));
                } else {
                    resolve(null);
                }
            });
        });
    }

    // 更新 DDL 数据
    updateDDL(item) {
        return new Promise((resolve, reject) => {
            const sql = `
                UPDATE ddl_items SET 
                name = ?,
                start_time = ?,
                end_time = ?,
                is_completed = ?,
                complete_time = ?,
                note = ?,
                is_archived = ?,
                is_stared = ?,
                type = ?,
                habit_count = ?
                WHERE id = ?
            `;
            const params = [
                item.name,
                item.startTime,
                item.endTime,
                item.isCompleted ? 1 : 0,
                item.completeTime,
                item.note,
                item.isArchived ? 1 : 0,
                item.isStared ? 1 : 0,
                item.type,
                item.habitCount,
                item.id
            ];
            this.db.run(sql, params, function (err) {
                if (err) {
                    reject(err);
                } else {
                    resolve();
                }
            });
        });
    }

    // 删除 DDL 数据
    deleteDDL(id) {
        return new Promise((resolve, reject) => {
            const sql = `DELETE FROM ddl_items WHERE id = ?`;
            this.db.run(sql, [id], function (err) {
                if (err) {
                    reject(err);
                } else {
                    resolve();
                }
            });
        });
    }

    // 关闭数据库（如需要时调用）
    close() {
        this.db.close((err) => {
            if (err) {
                console.error('Error closing the database', err);
            } else {
                console.log('Database closed.');
            }
        });
    }
}

module.exports = DBService;