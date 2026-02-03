# Self-Hosted Runner System

This repository includes the infrastructure to run ephemeral, containerized GitHub Actions runners. These runners are based on the `tayloraswift/swiftwasm:runner` Docker image, which pre-installs the Swift toolchain and WebAssembly SDKs.

This setup allows you to host a runner on a macOS machine (e.g., Mac Mini) using OrbStack or Docker Desktop, while keeping the environment isolated and ephemeral.

## Architecture

1. **Runner Image**: The `Runner.Dockerfile` builds an image (`tayloraswift/swiftwasm:runner`) containing:
* Ubuntu 24.04
* Swift Toolchain & WASM SDK
* GitHub Actions Runner Agent
* Entrypoint logic to register itself dynamically.


2. **Ephemeral Loop**: The runner is designed to process **one job** and then terminate. This ensures a clean build environment for every run. A loop script on the host machine restarts the container immediately after it exits.
3. **Host Machine**: The Mac Mini acts as the host. It does not need Swift installed; it only needs Docker (alternatively, OrbStack).

## Host Setup (Mac Mini)

To set up a runner on a Mac Mini, you need a single script. This script handles:

1. Fetching the latest runner logic.
2. Preventing the Mac from sleeping (`caffeinate`).
3. Injecting credentials for the target repository.

### 1. Prerequisites

* Docker Desktop (or OrbStack) installed and running.
* A **GitHub Personal Access Token (Classic)** with `repo` scope.

### 2. The Host Script (`start_runner.sh`)

Save the following script on your Mac Mini (e.g., at `~/start_runner.sh`). This script can be used to target **any** repository (public or private) by changing the configuration variables.

```bash
#!/bin/bash

# ==========================================
# CONFIGURATION
# ==========================================

# 1. GitHub Personal Access Token (PAT)
#    Must have 'repo' scope.
#    SECURITY WARNING: Keep this file private on the host machine.
YOUR_GITHUB_PAT="ghp_YOUR_TOKEN_HERE"

# 2. The Target Repository
#    This is where the runner will register and listen for jobs.
#    It does NOT need to be the same repo that hosts the Docker image.
GITHUB_OWNER="tayloraswift"
GITHUB_REPO="swift-docker-wasm"

# 3. Runner Image
#    The Docker Hub image to use (built from this repo).
IMAGE_NAME="tayloraswift/swiftwasm:runner"

# 4. Runner Name
#    A unique name to identify this runner in GitHub Settings.
CONTAINER_NAME="runner-${GITHUB_REPO}"

# 5. Directory for script storage
INSTALL_DIR="$HOME/swift-runner"

# 6. Remote Script URL
#    The logic that runs inside the loop.
REPO_SCRIPT_URL="https://raw.githubusercontent.com/tayloraswift/swift-docker-wasm/master/Scripts/runner-start.sh"

# ==========================================

# Check for Docker
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running."
    echo "   Please ensure the Docker engine is running."
    exit 1
fi

# Setup Directory
if [ ! -d "$INSTALL_DIR" ]; then
    echo "📂 Creating runner directory at $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
fi
cd "$INSTALL_DIR"

# Download the latest loop logic
# We fetch this fresh to ensure updates to the loop logic propagate immediately.
echo "⬇️  Fetching latest runner logic from GitHub..."
curl -s -o runner-start.sh -L "$REPO_SCRIPT_URL"
chmod +x runner-start.sh

# Export variables so the inner script picks them up
export GH_RUNNER_PAT="$YOUR_GITHUB_PAT"
export GITHUB_OWNER="$GITHUB_OWNER"
export GITHUB_REPO="$GITHUB_REPO"
export IMAGE_NAME="$IMAGE_NAME"
export CONTAINER_NAME="$CONTAINER_NAME"
# Pass the runner name to the container so it shows up correctly in GitHub UI
export RUNNER_NAME="${CONTAINER_NAME}-$(hostname)"

echo "------------------------------------------------"
echo "☕️ Starting runner for $GITHUB_OWNER/$GITHUB_REPO"
echo "   Target Image: $IMAGE_NAME"
echo "   Press Ctrl+C to stop."
echo "------------------------------------------------"

# Run with caffeinate to prevent system sleep
caffeinate -i ./runner-start.sh

```

### 3. Usage

1. Make the script executable:
```bash
chmod +x ~/start_runner.sh

```


2. Run it:
```bash
~/start_runner.sh

```


3. Go to your Repository Settings > Actions > Runners to verify the runner is "Idle".

## Maintenance

### Updating the Toolchain

To update the Swift version or SDK:

1. Edit `Ubuntu.Latest.Dockerfile` (or relevant dockerfile) in this repository.
2. Push to `master`.
3. The `Deploy.yml` workflow will automatically rebuild `tayloraswift/swiftwasm:runner`.
4. The active runner on the Mac Mini will detect the new image on its next loop iteration, pull it, and start using it immediately.


## Running for Private Repositories

To use this runner with a private repository on a different account:

1. Generate a PAT on the **other** account.
2. Edit `~/start_runner.sh` on the Mac Mini.
3. Update `YOUR_GITHUB_PAT`, `GITHUB_OWNER`, and `GITHUB_REPO`.
4. Leave `IMAGE_NAME` as `tayloraswift/swiftwasm:runner`.
5. Restart the script.

The runner will use the public tools from this repo to build the private code from the other repo.
