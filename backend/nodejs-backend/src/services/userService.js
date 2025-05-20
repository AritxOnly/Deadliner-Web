const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

class UserService {
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
                token_left INTEGER DEFAULT 0,
                is_vip INTEGER DEFAULT 0,
                is_admin INTEGER DEFAULT 0,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        `;
        this.db.run(createTableQuery);

        // 添加 api_key 字段
        this.db.run(`
            ALTER TABLE users ADD COLUMN api_key TEXT
          `, (err) => {
            if (err && !err.message.includes('duplicate column')) {
              console.error('添加 api_key 字段失败:', err.message);
            }
          });
        
        // 添加 prefs 字段
        this.db.run(`
            ALTER TABLE users ADD COLUMN prefs TEXT
          `, (err) => {
            if (err &&!err.message.includes('duplicate column')) {
              console.error('添加 prefs 字段失败:', err.message);
            }
          });
    }

    generateApiKey = () => crypto.randomBytes(32).toString('hex');

    // 用户注册
    async register(username, password, isVip = false) {
        const existingUser = await this.getUserByUsername(username);
        if (existingUser) {
            throw new Error('Username already exists');
        }

        const hashedPassword = await bcrypt.hash(password, this.SALT_ROUNDS);
        const tokenLeft = isVip ? 8000 : 0;
        const apiKey = this.generateApiKey();
        return new Promise((resolve, reject) => {
            const stmt = this.db.prepare(
                'INSERT INTO users (username, password_hash, token_left, api_key) VALUES (?, ?, ?, ?)'
            );
            stmt.run(username, hashedPassword, tokenLeft, apiKey, function(err) {
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

        this.db.all('SELECT id FROM users WHERE api_key IS NULL', [], (err, rows) => {
            if (err) return console.error(err);
    
            rows.forEach((user) => {
                const newKey = this.generateApiKey();
                this.db.run('UPDATE users SET api_key = ? WHERE id = ?', [newKey, user.id]);
            });
        });

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

    /**
     * **用户相关**
     */

    // 通过用户名获取用户
    async getUserByUsername(username) {
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

    async getUserById(userId) {
        return new Promise((resolve, reject) => {
            this.db.get(
                'SELECT * FROM users WHERE id =?',
                [userId],
                (err, row) => {
                    if (err) reject(err);
                    else resolve(row);
                }
            );
        });
    }

    async updateUserInfo(userId, newInfo) {
        userInfo = await this.getUserById(userId);
        userInfo.username = newInfo.username? newInfo.username : userInfo.username;
        userInfo.password_hash = newInfo.password? await bcrypt.hash(newInfo.password, this.SALT_ROUNDS) : userInfo.password_hash;
        userInfo.is_vip = newInfo.is_vip? newInfo.is_vip : userInfo.is_vip;
        userInfo.token_left = newInfo.token_left? newInfo.token_left : userInfo.token_left;

        return new Promise((resolve, reject) => {
            this.db.run(
                'UPDATE users SET username = ?, password_hash = ?, is_vip = ?, token_left = ? WHERE id = ?',
                [userInfo.username, userInfo.password_hash, userInfo.is_vip, userInfo.token_left, userId],
                (err) => {
                    if (err) reject(err);
                    else resolve(userInfo);
                }
            )
        })
    }
    
    async getUserByApiKey(apiKey) {
        return new Promise((resolve, reject) => {
            this.db.get(
                'SELECT * FROM users WHERE api_key = ?',
                [apiKey],
                (err, row) => {
                    if (err) reject(err);
                    else resolve(row);
                }
            );
        });
    }

    async updateUserPrefs(username, prefs) {
        return new Promise((resolve, reject) => {
            this.db.run(
                'UPDATE users SET prefs =? WHERE username =?',
                [prefs, username],
                (err) => {
                    if (err) reject(err);
                    else resolve();
                }
            )
        })
    }

    async getUserPrefs(username) {
        return new Promise((resolve, reject) => {
            this.db.get(
                'SELECT prefs FROM users WHERE username =?',
                [username],
                (err, row) => {
                    if (err) reject(err);
                    else resolve(row.prefs);
                }
            );
        });
    }
}

module.exports = UserService;