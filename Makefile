# 检测操作系统
ifeq ($(OS),Windows_NT)
    DETECTED_OS := Windows
    RM := rd /s /q
    PYTHON := python
    NPM := npm.cmd
    DATE := $(shell powershell -Command "Get-Date -Format yyyy-MM-dd")
else
    DETECTED_OS := $(shell uname -s)
    RM := rm -rf
    PYTHON := python3
    NPM := npm
    DATE := $(shell date +%Y-%m-%d)
endif

# 包含子模块配置
include backend/nodejs-backend/build.mk
include backend/python-ai-service/build.mk
include frontend/build.mk

CURRENT_BRANCH := $(shell git branch --show-current)

# 公共命令
init: create-venv
	@echo "Project initialized with Python virtual environment."

install: install-nodejs install-python
clean: clean-nodejs clean-python

run: run-flutter start-nodejs 

push: commit
	@echo "Pushing to branch: $(CURRENT_BRANCH)"
	git push origin $(CURRENT_BRANCH)

pull: commit
	@echo "Pulling from branch: $(CURRENT_BRANCH)"
	git pull origin $(CURRENT_BRANCH)

MSG := commit from Makefile at 

commit:
	@echo "Committing changes to branch: $(CURRENT_BRANCH)"
	git add .
	git commit --allow-empty -am "$(MSG): $(DATE)"

.PHONY: init install clean push
