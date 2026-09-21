import os

from flask import Flask, jsonify


def status_payload(version, environment):
    return {
        "service": "tvms-nvr",
        "status": "ok",
        "version": version,
        "environment": environment,
    }


def create_app():
    app = Flask(__name__)

    @app.get("/")
    def home():
        version = os.getenv("APP_VERSION", "development")
        environment = os.getenv("APP_ENV", "local")

        return f"""
        <html>
            <head>
                <title>TVMS NVR</title>
            </head>
            <body>
                <h1>TVMS NVR Console</h1>
                <p>Environment: {environment}</p>
                <p>Release: {version}</p>
            </body>
        </html>
        """

    @app.get("/health")
    def health():
        version = os.getenv("APP_VERSION", "development")
        environment = os.getenv("APP_ENV", "local")

        return jsonify(status_payload(version, environment))

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
