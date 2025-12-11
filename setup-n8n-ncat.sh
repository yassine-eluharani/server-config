#!/bin/bash

set -euo pipefail

########################################
# CONFIG – EDIT THESE BEFORE RUNNING
########################################

# Your main domain (no subdomain here)
DOMAIN="yourdomain.com"

# Subdomains
N8N_SUBDOMAIN="n8n"
API_SUBDOMAIN="api"

# n8n basic auth
N8N_BASIC_AUTH_USER="admin"
N8N_BASIC_AUTH_PASSWORD="yourStrongPassword123"

# NCAT app configuration
NCAT_APP_NAME="NCAToolkit"
NCAT_API_KEY="super_secret_token_123"

########################################
# Derived values (no need to edit below)
########################################

N8N_FQDN="${N8N_SUBDOMAIN}.${DOMAIN}"
API_FQDN="${API_SUBDOMAIN}.${DOMAIN}"

if [[ "$DOMAIN" == "yourdomain.com" ]]; then
  echo "⚠️ Please edit this script and set DOMAIN, passwords, and API key before running."
  exit 1
fi

echo "🚀 Setting up n8n & NCAT for:"
echo "  n8n  → https://${N8N_FQDN}"
echo "  NCAT → https://${API_FQDN}"
sleep 2

########################################
# 1. System update & install Docker + deps
########################################

echo "📦 Updating system and installing Docker & helpers..."
apt update && apt upgrade -y

apt install -y \
  ca-certificates gnupg lsb-release \
  debian-keyring debian-archive-keyring apt-transport-https \
  docker.io docker-compose-plugin

systemctl enable --now docker

########################################
# 2. Install Caddy from official repo
########################################

echo "🌐 Installing Caddy..."

if [ ! -f /etc/apt/trusted.gpg.d/caddy.gpg ]; then
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/caddy.gpg
fi

if [ ! -f /etc/apt/sources.list.d/caddy-stable.list ]; then
  curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
    | tee /etc/apt/sources.list.d/caddy-stable.list
fi

apt update
apt install -y caddy
systemctl enable --now caddy

########################################
# 3. n8n Docker Compose setup
########################################

echo "⚙️ Setting up n8n in /opt/n8n..."

mkdir -p /opt/n8n
cat <<EOF > /opt/n8n/docker-compose.yml
version: "3.9"

services:
  n8n:
    image: n8nio/n8n
    restart: unless-stopped
    ports:
      - "127.0.0.1:5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
      - N8N_SECURE_COOKIE=true
      - GENERIC_TIMEZONE=Africa/Casablanca
    volumes:
      - n8n_data:/home/node/.n8n
      - ./media:/data/media
    networks:
      - internal

volumes:
  n8n_data:

networks:
  internal:
EOF

########################################
# 4. NCAT Docker Compose + .env
########################################

echo "⚙️ Setting up NCAT in /opt/ncat..."

mkdir -p /opt/ncat

cat <<EOF > /opt/ncat/.env
APP_NAME=${NCAT_APP_NAME}
APP_DEBUG=false
APP_DOMAIN=${API_FQDN}
APP_URL=https://${API_FQDN}
API_KEY=${NCAT_API_KEY}
EOF

cat <<'EOF' > /opt/ncat/docker-compose.yml
version: "3.8"

services:
  ncat:
    image: stephengpope/no-code-architects-toolkit:latest
    env_file:
      - .env
    ports:
      - "127.0.0.1:4000:8080"
    volumes:
      - storage:/var/www/html/storage/app
      - logs:/var/www/html/storage/logs
    restart: unless-stopped

volumes:
  storage:
  logs:
EOF

########################################
# 5. Caddyfile for both domains
########################################

echo "📑 Writing /etc/caddy/Caddyfile..."

cat <<EOF > /etc/caddy/Caddyfile
${N8N_FQDN} {
    reverse_proxy 127.0.0.1:5678
}

${API_FQDN} {
    reverse_proxy 127.0.0.1:4000
}
EOF

systemctl reload caddy

########################################
# 6. Start Docker services
########################################

echo "🐳 Starting n8n and NCAT containers..."

cd /opt/n8n
docker compose up -d

cd /opt/ncat
docker compose up -d

########################################
# 7. Final info
########################################

cat <<EOF

✅ Setup complete!

Make sure you have these DNS records at Namecheap (or your registrar):

  A  @        -> your VPS IP
  A  ${N8N_SUBDOMAIN}   -> your VPS IP
  A  ${API_SUBDOMAIN}   -> your VPS IP

Then access:

  n8n  → https://${N8N_FQDN}
  NCAT → https://${API_FQDN}

n8n basic auth:
  user: ${N8N_BASIC_AUTH_USER}
  pass: ${N8N_BASIC_AUTH_PASSWORD}

To change NCAT config later, edit:
/opt/ncat/.env

Then restart it:
/opt/ncat$ docker compose down
/opt/ncat$ docker compose up -d

EOF
