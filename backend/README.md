# Deadliner‑Web 后端使用与部署文档

## 前提条件

- 操作系统：Windows / macOS / Linux  
- Git  
- **Node.js** ≥ 14（含 npm）  
- **Python** ≥ 3.8（含 venv & pip）  
- **SQLite3**（可选，若已内置则无需额外安装）  
- （可选）Docker & Docker Compose  

---

## 环境变量

### Node.js 中间件

在 `backend/nodejs‑backend/.env` 中配置：

```env
JWT_SECRET=你的JWT密钥
```

### Python AI 服务

在 backend/python‑ai‑service/.env 中（可选）：

```env
FLASK_ENV=production
LLM_MODEL_PATH=/path/to/your/model
```

---

## 安装与启动

### 安装依赖

```bash
# 进入 Node.js 服务目录
cd backend/nodejs‑backend
npm install

# 进入 Python AI 服务目录
cd ../python‑ai‑service
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 启动服务

#### Python AI 服务

```bash
# 在 python‑ai‑service 下
source venv/bin/activate
python -m app.main
# 默认监听：0.0.0.0:5001
```

#### Node.js 中间件

```bash
# 在 nodejs‑backend 下
npm start
# 默认监听：0.0.0.0:3000
```

> 可并行运行，或使用 Docker Compose 容器化管理。

## 后端 API 概览

所有接口均以 `/api/v1` 为前缀。

### 用户与认证

| 方法 | 路径                       | 描述                       |
| ---- | -------------------------- | -------------------------- |
| POST | `/api/v1/auth/register`    | 用户注册，返回 `{ token }` |
| POST | `/api/v1/auth/login`       | 用户登录，返回 `{ token }` |
| GET  | `/api/v1/users/{id}`       | 获取指定用户的详情         |
| PUT  | `/api/v1/users/{id}`       | 更新指定用户的信息         |

### DDL 项目管理

| 方法   | 路径                         | 描述                   |
| ------ | ---------------------------- | ---------------------- |
| GET    | `/api/v1/db/items`           | 列出所有 DDL 项目      |
| GET    | `/api/v1/db/items/{id}`      | 获取单个 DDL 项目      |
| POST   | `/api/v1/db/items`           | 新增一个 DDL 项目      |
| PUT    | `/api/v1/db/items/{id}`      | 更新指定的 DDL 项目    |
| DELETE | `/api/v1/db/items/{id}`      | 删除指定的 DDL 项目    |

### AI 规划

| 方法 | 路径                          | 描述                              |
| ---- | ----------------------------- | --------------------------------- |
| POST | `/api/v1/ai/plan`             | 提交任务规划请求，返回 `{ taskId }` |
| GET  | `/api/v1/ai/status/{taskId}`  | 查询 AI 规划任务执行状态          |
| GET  | `/api/v1/ai/result/{taskId}`  | 获取 AI 规划结果                  |

### LLM 生成（Python 服务）

| 方法 | 路径             | 描述                                   |
| ---- | ---------------- | -------------------------------------- |
| POST | `/llm/generate`  | 提交 `{ model, messages }`，返回 LLM 响应 |

---

## 数据库

- **SQLite** + **Sequelize ORM**  
- 默认存储文件：`backend/nodejs‑backend/database/*.sqlite`  
- 如需清空或重建：  
  ```bash
  rm backend/nodejs-backend/database/*.sqlite
  npm run migrate   # （后续可集成 Sequelize CLI）
  ```

--- 

## 部署建议

1. **环境变量**  
   - `NODE_ENV=production`  
   - `FLASK_ENV=production`  
   - `JWT_SECRET=<你的密钥>`  
   - `LLM_MODEL_PATH=<模型路径>`

2. **进程管理**  
   - Node.js: 使用 **PM2** 或 **systemd**  
   - Python (Flask): 使用 **Gunicorn + Supervisor** 或 **uWSGI**

3. **容器化**  
   - 编写 `Dockerfile`（分别为 Node.js 与 Python 服务）  
   - 使用 `docker-compose.yml` 编排，多服务共用网络  

4. **反向代理 & TLS**  
   - 前端由 **Nginx** 代理，转发到 3000（Node）与 5001（Python）  
   - 使用 **Let’s Encrypt** 自动管理 HTTPS 证书

5. **监控与日志**  
   - 日志轮转：**Logrotate**  
   - 错误跟踪：**Sentry** 或 **Rollbar**  
   - 健康检查：可自定义 `/api/v1/health` 接口并由监控系统定期探测

6. **安全优化**  
   - 强制 HTTPS、启用 CORS 白名单  
   - 限流：防止暴力破解  
   - 定期更新依赖，修补安全漏洞  
