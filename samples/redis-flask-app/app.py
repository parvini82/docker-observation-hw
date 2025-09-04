import os
import redis
from flask import Flask, request, jsonify

app = Flask(__name__)

# Redis connection
redis_client = redis.Redis(
    host=os.getenv("REDIS_HOST", "localhost"),
    port=int(os.getenv("REDIS_PORT", 6379)),
    decode_responses=True,
)


@app.get("/")
def hello():
    return {"message": "Hello from Redis Flask App in Docker!"}


@app.post("/items")
def add_item():
    """Add an item to Redis"""
    try:
        data = request.get_json()
        if not data or "key" not in data or "value" not in data:
            return jsonify({"error": "Missing key or value"}), 400

        key = data["key"]
        value = data["value"]

        # Set the key-value pair in Redis
        redis_client.set(key, value)

        return (
            jsonify({"message": "Item added successfully", "key": key, "value": value}),
            201,
        )

    except redis.ConnectionError:
        return jsonify({"error": "Cannot connect to Redis"}), 503
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.get("/items/<key>")
def get_item(key):
    """Get an item from Redis by key"""
    try:
        value = redis_client.get(key)
        if value is None:
            return jsonify({"error": "Key not found"}), 404

        return jsonify({"key": key, "value": value})

    except redis.ConnectionError:
        return jsonify({"error": "Cannot connect to Redis"}), 503
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.get("/items")
def list_items():
    """List all keys in Redis"""
    try:
        keys = redis_client.keys("*")
        items = {}
        for key in keys:
            value = redis_client.get(key)
            items[key] = value

        return jsonify({"count": len(items), "items": items})

    except redis.ConnectionError:
        return jsonify({"error": "Cannot connect to Redis"}), 503
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    # Bind to 0.0.0.0 so it's reachable from outside the container
    app.run(
        host=os.getenv("FLASK_BIND_HOST", "0.0.0.0"),
        port=int(os.getenv("FLASK_PORT", 5000)),
        debug=True,
    )
