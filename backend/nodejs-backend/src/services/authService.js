const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

class AuthService {
    constructor() {
        this.db = new sqlite3.Database(
            path.resolve(__dirname, '../../database/users.db'),
            sqlite3.OPEN_READWRITE | sqlite3.OPEN_CREATE
        );
        
        this.initializeDatabase();
        this.SECRET_KEY = process.env.JWT_SECRET || 'XRHtKv7qx3bZT0WwIPNJig==';
        this.SALT_ROUNDS = 12;
    }

    initializeDatabase() {
        const createTableQuery = `
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        `;
        this.db.run(createTableQuery);
    }

    // 用户注册
    async register(username, password) {
        const existingUser = await this.getUserByUsername(username);
        if (existingUser) {
            throw new Error('Username already exists');
        }

        const hashedPassword = await bcrypt.hash(password, this.SALT_ROUNDS);
        return new Promise((resolve, reject) => {
            const stmt = this.db.prepare(
                'INSERT INTO users (username, password_hash) VALUES (?, ?)'
            );
            stmt.run(username, hashedPassword, function(err) {
                if (err) reject(err);
                else resolve(this.lastID);
            });
            stmt.finalize();
        });
    }

    // 用户登录
    async login(username, password) {
        const user = await this.getUserByUsername(username);
        if (!user) {
            throw new Error('Invalid credentials');
        }

        const isValid = await bcrypt.compare(password, user.password_hash);
        if (!isValid) {
            throw new Error('Invalid credentials');
        }

        return this.generateToken(user);
    }

    // 生成JWT令牌
    generateToken(user) {
        return jwt.sign(
            { id: user.id, username: user.username },
            this.SECRET_KEY,
            { expiresIn: '1h' }
        );
    }

    // 通过用户名获取用户
    getUserByUsername(username) {
        return new Promise((resolve, reject) => {
            this.db.get(
                'SELECT * FROM users WHERE username = ?',
                [username],
                (err, row) => {
                    if (err) reject(err);
                    else resolve(row);
                }
            );
        });
    }
}

module.exports = AuthService;