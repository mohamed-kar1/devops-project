from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        "message": "Bienvenue sur l'API DevOps",
        "status": "running",
        "version": "1.0.1",
        "env": os.getenv("ENV", "production")
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

@app.route('/api/info')
def info():
    return jsonify({
        "app": "devops-api",
        "author": "Master DSBD & IA",
        "description": "Projet Final DevOps 2026"
    })

if __name__ == '__main__':
    port = int(os.getenv("PORT", 8888))
    app.run(host='0.0.0.0', port=port, debug=False)
