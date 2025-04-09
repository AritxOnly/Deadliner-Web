const express = require('express');
const bodyParser = require('body-parser');
const morgan = require('morgan');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const dbRoutes = require('./routes/dbRoutes'); // 数据库操作路由
const authRoutes = require('./routes/authRoutes'); // 认证路由

// 全局变量
const LOG_LEVEL = 'dev';
const API_DIR = '/api/v1';

// 初始化 Express 应用
const app = express();

// 中间件
app.use(cors());
app.use(morgan(LOG_LEVEL));
app.use(bodyParser.json());

app.use(API_DIR + '/db', dbRoutes);
app.use(API_DIR + '/auth', authRoutes);
app.use(API_DIR, express.Router().get('/', (req, res) => {
    res.json({ message: 'Welcome to the API!' });
}));

// 处理未匹配的路由
app.use((req, res, next) => {
    res.status(404).json({ message: 'Not found' });
})

// 错误处理
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ message: 'Something went wrong!', error: err.message });
})

// 启动服务器
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});