const express = require('express');
const bodyParser = require('body-parser');
const morgan = require('morgan');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const authMiddleware = require('./middleware/authMiddleware');

const { sequelize } = require('./models');  // 数据库模型
const authRoutes = require('./routes/authRoutes'); // 认证路由
const userRoutes = require('./routes/userRoutes'); // 用户路由
const dbRoutes = require('./routes/dbRoutes'); // 数据库操作路由
const aiRoutes = require('./routes/aiRoutes'); // AI 规划路由

// 全局变量
const LOG_LEVEL = 'dev';
const API_DIR = '/api/v1';

// 初始化 Express 应用
const app = express();

// 中间件
app.use(cors());
app.use(morgan(LOG_LEVEL));
app.use(bodyParser.json());

app.use(API_DIR + '/auth', authRoutes);
app.use(API_DIR + '/users', authMiddleware, userRoutes);
app.use(API_DIR + '/db', authMiddleware, dbRoutes);
app.use(API_DIR + '/ai', authMiddleware, aiRoutes);

// 启动数据库连接
sequelize.authenticate()
  .then(() => {
    console.log('Database connection has been established successfully.');
  })
  .catch(err => {
    console.error('Unable to connect to the database:', err);
  });

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