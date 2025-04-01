PYTHON_PATH := backend/python-ai-service
VENV_NAME := venv

# 检测操作系统并设置虚拟环境路径
ifeq ($(OS),Windows_NT)
    VENV_BIN := $(PYTHON_PATH)/$(VENV_NAME)/Scripts
    PYTHON_EXE := $(VENV_BIN)/python.exe
else
    VENV_BIN := $(PYTHON_PATH)/$(VENV_NAME)/bin
    PYTHON_EXE := $(VENV_BIN)/python
endif

# 创建虚拟环境（跨平台）
create-venv:
	@echo "[$(DETECTED_OS)] Creating Python virtual environment..."
	$(PYTHON) -m venv "$(PYTHON_PATH)/$(VENV_NAME)"
	@echo "Virtual environment created at: $(PYTHON_PATH)/$(VENV_NAME)"

# 安装依赖到虚拟环境
install-python: create-venv
	@echo "[$(DETECTED_OS)] Installing Python dependencies..."
	"$(PYTHON_EXE)" -m pip install -r $(PYTHON_PATH)/requirements.txt

clean-python:
	@echo "[$(DETECTED_OS)] Cleaning Python environment..."
	if exist "$(PYTHON_PATH)/$(VENV_NAME)" $(RM) "$(PYTHON_PATH)/$(VENV_NAME)"
	if exist "$(PYTHON_PATH)/__pycache__" $(RM) "$(PYTHON_PATH)/__pycache__"