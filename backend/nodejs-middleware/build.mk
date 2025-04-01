NODEJS_PATH := backend/nodejs-middleware

install-nodejs:
	@echo "[$(DETECTED_OS)] Installing Node.js dependencies..."
	cd $(NODEJS_PATH) && $(NPM) install

start-nodejs:
	@echo "[$(DETECTED_OS)] Starting Node.js server..."
	cd $(NODEJS_PATH) && $(NPM) start

test-nodejs:
	@echo "[$(DETECTED_OS)] Running Node.js tests..."
	cd $(NODEJS_PATH) && $(NPM) test

clean-nodejs:
	@echo "[$(DETECTED_OS)] Cleaning Node.js modules..."
	if exist "$(NODEJS_PATH)\node_modules" $(RM) "$(NODEJS_PATH)\node_modules"