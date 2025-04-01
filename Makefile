# 检测操作系统
ifeq ($(OS),Windows_NT)
    DETECTED_OS := Windows
    RM := rd /s /q
    PYTHON := python
    NPM := npm.cmd
else
    DETECTED_OS := $(shell uname -s)
    RM := rm -rf
    PYTHON := python3
    NPM := npm
endif

# 包含子模块配置
include backend/nodejs-middleware/build.mk
include backend/python-ai-service/build.mk

CURRENT_BRANCH := $(shell git branch --show-current)

# 公共命令
init: create-venv
	@echo "Project initialized with Python virtual environment."

install: install-nodejs install-python
clean: clean-nodejs clean-python

push:
	@echo "Pushing to branch: $(CURRENT_BRANCH)"
	git push origin $(CURRENT_BRANCH)

.PHONY: init install clean push