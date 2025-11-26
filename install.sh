#!/bin/bash


# -----------------------------------------------------------------------------
# Install and configure the OpenAI Apps SDK example repo on a clean Debian host.
#
# This script:
#   • Installs Node.js, pnpm, git, and other required tooling.
#   • Clones the openai-apps-sdk-examples repository and builds the frontend.
#   • Sets up a Python virtual environment using uv and starts the backend server.
#   • Installs and configures Caddy as a reverse proxy and automatic SSL provider
#     (via Let's Encrypt / ACME).
#
# Requirements:
#   • A fresh or minimally configured Debian machine.
#   • A domain name that **already points to this machine’s public IP address**.
#     Caddy will use this domain to automatically provision HTTPS certificates.
#
# Usage:
#       ./install.sh <domain>
#
# Example:
#       ./install.sh oai-app.example.com
#
# The script expects a single argument: the domain name (without https://).
# -----------------------------------------------------------------------------

if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

export DOMAIN="https://$1"
echo "[INFO] Installing for domain: $DOMAIN"

echo "[STEP] Installing Node.js and git..."
sudo apt install -y nodejs git

echo "[STEP] Installing pnpm..."
curl -fsSL https://get.pnpm.io/install.sh | sh -
. /root/.bashrc

echo "[STEP] Cloning repository..."
git clone https://github.com/Cefboud/openai-apps-sdk-examples.git /app
cd /app

echo "[STEP] Installing frontend dependencies..."
pnpm install

echo "[STEP] Building frontend..."
BASE_URL=$DOMAIN pnpm run build

echo "[STEP] Installing uv (Python package manager)..."
curl -LsSf https://astral.sh/uv/install.sh | sh
. $HOME/.local/bin/env

echo "[STEP] Creating Python virtual environment..."
uv venv .venv
. .venv/bin/activate

echo "[STEP] Installing backend requirements..."
uv pip install -r pizzaz_server_python/requirements.txt

echo "[STEP] Stopping any existing uvicorn processes..."

# ps aux | grep "[u]v" | awk '{print $2}' | xargs kill -9 2>/dev/null

echo "[STEP] Starting backend server..."
uv run uvicorn pizzaz_server_python.main:app --port 8000 --host localhost &

echo "[STEP] Installing Caddy (if missing)..."
if ! command -v caddy >/dev/null 2>&1; then
    sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    chmod o+r /etc/apt/sources.list.d/caddy-stable.list
    sudo apt update
    sudo apt install -y caddy
fi

echo "[STEP] Writing Caddyfile..."
cat <<EOF > /etc/caddy/Caddyfile 
$DOMAIN {

    @assets {
        path *.js *.css *.png *.jpg
    }

    handle @assets {
        root * /app/assets
        file_server
    }

    header {
        Access-Control-Allow-Origin "*"
    }

    reverse_proxy localhost:8000
}
EOF

echo "[STEP] Starting Caddy..."

sleep 10
sudo systemctl restart caddy

echo "[DONE] Installation completed. Your app should now be available at: $DOMAIN"
