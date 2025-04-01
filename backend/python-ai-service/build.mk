PYTHON_PATH := backend/python-ai-service

install-python:
	@echo "Installing dependencies in Python AI service..."
	pip install -r $(PYTHON_PATH)/requirements.txt

clean-python:
	@echo "Cleaning Python AI service..."
	rm -rf $(PYTHON_PATH)/__pycache__