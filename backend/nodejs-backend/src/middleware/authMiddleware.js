const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
  // 从请求头获取令牌
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN格式
  
  if (!token) {
    return res.status(401).json({ error: '未提供认证令牌' });
  }
  
  try {
    // 验证令牌
    const SECRET_KEY = process.env.JWT_SECRET || 'XRHtKv7qx3bZT0WwIPNJig==';
    const decoded = jwt.verify(token, SECRET_KEY);
    
    // 将用户信息添加到请求对象
    req.user = decoded;
    
    // 继续处理请求
    next();
  } catch (error) {
    return res.status(403).json({ error: '无效的令牌' });
  }
}

module.exports = authMiddleware;