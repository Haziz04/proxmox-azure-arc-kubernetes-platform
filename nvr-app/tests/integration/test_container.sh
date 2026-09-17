#!/bin/bash

set -e

IMAGE_NAME="$1"
CONTAINER_NAME="nvr-integration-test"
TEST_PORT="18082"
EXPECTED_VERSION="$2"

cleanup() {
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}

trap cleanup EXIT

docker run -d \
    --name "$CONTAINER_NAME" \
    -p ${TEST_PORT}:8080 \
    -e APP_VERSION="$EXPECTED_VERSION" \
    -e APP_ENV=ci \
    "$IMAGE_NAME"

echo "Waiting for application..."

for i in {1..20}; do
    if curl -fsS "http://127.0.0.1:${TEST_PORT}/health" >/tmp/nvr-health.json; then
        break
    fi

    sleep 2
done

cat /tmp/nvr-health.json

python3 - <<EOF
import json

with open("/tmp/nvr-health.json") as f:
    data = json.load(f)

assert data["status"] == "ok"
assert data["version"] == "$EXPECTED_VERSION"
assert data["environment"] == "ci"

print("Integration test PASSED")
EOF
