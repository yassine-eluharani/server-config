# VPS Setup – Zsh Shell + n8n + NCAT API

This repo contains simple automation scripts to turn a **fresh VPS** into:

- A comfy **dev environment** (Zsh, Oh My Zsh, Powerlevel10k, Neovim)
- A small **automation stack in Docker**:
  - `n8n` accessible at `https://n8n.yourdomain.com`
  - `NCAT` (No-Code Architects Toolkit API) accessible at `https://api.yourdomain.com`
  - Fronted by **Caddy** with automatic HTTPS via Let's Encrypt

---

## Files Overview

### `setup.sh` (optional)

Sets up your **terminal/dev environment**:

- Updates the system
- Installs:
  - `zsh`, `git`, `curl`, `neovim`, `wget`, `fonts-powerline`
- Installs & configures:
  - **Oh My Zsh**
  - **Powerlevel10k** theme
  - Useful aliases (`ll`, `l`)
  - Plugins: `git`, `docker`, `docker-compose`
- Creates a minimal **Neovim config**: line numbers, syntax highlight, mouse support

Use this on **any new VPS** where you want a nice shell/dev experience.  
If you already have your own setup, you can skip this script.

---

### `setup-n8n-ncat.sh`

This is the **main script**. It:

1. Installs:
   - Docker and the `docker compose` plugin
   - Caddy (reverse proxy) from the official repo
2. Sets up **n8n** in `/opt/n8n` with:
   - Docker Compose file
   - Local bind: `127.0.0.1:5678`
   - Basic auth (username/password from script config)
   - Data volume + `./media` folder inside `/opt/n8n`
3. Sets up **NCAT API** in `/opt/ncat` with:
   - `.env` file (APP_URL, APP_DOMAIN, API_KEY, etc.)
   - Docker Compose file exposing `127.0.0.1:4000` internally
4. Creates a **Caddyfile** at `/etc/caddy/Caddyfile` with:
   - `n8n.yourdomain.com` → reverse proxy to `127.0.0.1:5678`
   - `api.yourdomain.com` → reverse proxy to `127.0.0.1:4000`
5. Starts the Docker services:
   - `docker compose up -d` in `/opt/n8n`
   - `docker compose up -d` in `/opt/ncat`

After this script:

- `https://n8n.yourdomain.com` → n8n UI (with basic auth)
- `https://api.yourdomain.com` → NCAT API

> 🔐 Certificates and HTTPS are handled automatically by Caddy using Let's Encrypt.

---

## Requirements

Before you run the scripts, you should have:

- A VPS running **Ubuntu/Debian** (or compatible)
- SSH access as `root` or a sudo user
- A registered domain (e.g. from Namecheap)
- Ability to configure **DNS A rec**
