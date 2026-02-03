#!/bin/bash

# Configuration
IMAGE_NAME="tayloraswift/swiftwasm:runner"
CONTAINER_NAME="swift-wasm-runner-ephemeral"
GITHUB_OWNER="tayloraswift"
GITHUB_REPO="swift-docker-wasm"

# Ensure PAT is available
if [ -z "$GH_RUNNER_PAT" ]; then
    echo "Error: GH_RUNNER_PAT environment variable is not set."
    exit 1
fi

echo "Starting ephemeral runner loop for $GITHUB_OWNER/$GITHUB_REPO..."

while true; do
    echo "------------------------------------------------"
    echo "Checking for updates to $IMAGE_NAME..."
    docker pull $IMAGE_NAME
    docker image prune -f

    echo "Launching runner..."
    # --rm: Automatically remove container when it exits
    # --name: Specific name to prevent collisions
    docker run --rm \
        --name "$CONTAINER_NAME" \
        -e GITHUB_PAT="$GH_RUNNER_PAT" \
        -e GITHUB_OWNER="$GITHUB_OWNER" \
        -e GITHUB_REPO="$GITHUB_REPO" \
        -e RUNNER_NAME="mac-mini-docker-$(date +%s)" \
        $IMAGE_NAME

    echo "Runner exited. Restarting in 5 seconds..."
    sleep 5
done
