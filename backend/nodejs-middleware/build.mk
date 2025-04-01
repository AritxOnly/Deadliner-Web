NODEJS_PATH := backend/nodejs-middleware

# 安装依赖
install-nodejs:
	@echo "Installing dependencies in Node.js middleware..."
	cd $(NODEJS_PATH) && npm install

# 启动服务器
start-nodejs:
	@echo "Starting the Node.js middleware server..."
	cd $(NODEJS_PATH) && npm start

# 运行测试
test-nodejs:
	@echo "Running tests in Node.js middleware..."
	cd $(NODEJS_PATH) && npm test

# 清理 node_modules 并重新安装
clean-nodejs:
	@echo "Cleaning node_modules and reinstalling..."
	rm -rf node_modules
	cd $(NODEJS_PATH) && npm install