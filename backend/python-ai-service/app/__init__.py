from flask import Flask

def create_app():
    app = Flask(__name__)
    
    # 延迟导入路由（避免循环）
    from app.routes.llm_routes import llm_bp
    app.register_blueprint(llm_bp)
    
    return app