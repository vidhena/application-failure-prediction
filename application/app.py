from flask import Flask, jsonify
import time

app = Flask(__name__)

@app.route("/")
def home():
    return jsonify({
        "application": "Application Failure Prediction Platform v2",
        "status": "running"
    })

@app.route("/health")
def health():
    return jsonify({
        "status": "healthy"
    })

@app.route("/stress")
def stress():
    start = time.time()

    while time.time() - start < 10:
        _ = 10 * 10

    return jsonify({
        "message": "Stress test completed"
    })

@app.route("/error")
def error():
    return jsonify({
        "status": "error",
        "message": "Sample application error"
    }), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)