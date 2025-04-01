include backend/nodejs-middleware/build.mk
include backend/python-ai-service/build.mk

init:
	@echo "Initializing the project..."

install: install-nodejs
clean: clean-nodejs clean-python

push:
	git push origin $(git branch --show-current)