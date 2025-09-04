import os
from flask import Flask

app = Flask(__name__)


@app.get("/")
def hello():
    return {"message": "Hello from Flask in Docker!"}


if __name__ == "__main__":
    # Bind to 0.0.0.0 so it's reachable from outside the container
    app.run(
        host=os.getenv("FLASK_BIND_HOST", "0.0.0.0"),
        port=os.getenv("FLASK_PORT", 5000),
        debug=True,
    )
