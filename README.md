# NanoBot + MemU (Personal Fork)

This repo contains a NanoBot fork with the built-in file memory removed and replaced with **MemU**.

## Repo Layout

- `nanobot/`: NanoBot (memory → MemU integration lives here)
- `memU_test/`: MemU Python package (used by NanoBot via `memu.app.MemoryService`)

## Quick Start (Linux / Ubuntu)

```bash
# Requires Python 3.13+ for MemU
# 1) Create a virtualenv (recommended; avoids PEP 668 "externally-managed-environment")
python3 -m venv /opt/nanobot-venv
source /opt/nanobot-venv/bin/activate

# 2) Install both projects (editable)
pip install -U pip
pip install -e memU_test
pip install -e nanobot

# 3) One-time init (workspace + templates)
nanobot onboard

# 4) Configure (default model = MiniMax 2.1, MemU DB persistence)
# Replace MINIMAX_API_KEY and optionally MEMU_DB_DSN.
MINIMAX_API_KEY="REPLACE_ME" \
DEEPSEEK_API_KEY="REPLACE_ME" \
SILICONFLOW_API_KEY="REPLACE_ME" \
MEMU_DB_DSN="sqlite:////opt/nanobot-data/memu.db" \
bash scripts/bootstrap.sh

# 5) Chat (CLI)
nanobot agent -m "Hello!"
```

## One-Step Setup (MiniMax 2.1 + MemU persistence)

```bash
nanobot onboard
MINIMAX_API_KEY="REPLACE_ME" \
DEEPSEEK_API_KEY="REPLACE_ME" \
SILICONFLOW_API_KEY="REPLACE_ME" \
MEMU_DB_DSN="sqlite:////opt/nanobot-data/memu.db" \
bash scripts/bootstrap.sh
```

This writes:
- `~/.nanobot/config.json` with default model `minimax/MiniMax-M2.5`
- `~/.bashrc` env block with `MINIMAX_API_KEY`, `MINIMAX_API_BASE`, `MEMU_DB_DSN`
- If provided, it also persists MemU keys for DeepSeek (LLM) and SiliconFlow (embeddings)

## Config.json (No Env for MemU)

You can keep **all MemU settings in `~/.nanobot/config.json`** (no env required). Example:

```json
{
  "agents": { "defaults": { "model": "minimax/MiniMax-M2.5" } },
  "providers": {
    "minimax": { "apiKey": "REPLACE_ME", "apiBase": "https://api.minimaxi.com/v1" }
  },
  "channels": {
    "whatsapp": { "enabled": true, "bridgeUrl": "ws://localhost:3001", "allowFrom": [] }
  },
  "memu": {
    "enabled": true,
    "dbDsn": "sqlite:////root/.nanobot/workspace/.memu/memu.db",
    "default": {
      "provider": "openai",
      "baseUrl": "https://api.deepseek.com/v1",
      "apiKey": "REPLACE_ME",
      "chatModel": "deepseek-chat",
      "clientBackend": "sdk"
    },
    "embedding": {
      "provider": "openai",
      "baseUrl": "https://api.siliconflow.cn/v1",
      "apiKey": "REPLACE_ME",
      "embedModel": "BAAI/bge-m3",
      "clientBackend": "sdk"
    }
  }
}
```

## Persistent Environment Variables (bash)

Put your API keys/model endpoints in `~/.bashrc` so they persist across sessions:

```bash
cat <<'EOF' >> ~/.bashrc

# NanoBot / MemU
export MINIMAX_API_KEY="REPLACE_ME"
export MINIMAX_API_BASE="https://api.minimaxi.com/v1"

export DEEPSEEK_API_KEY="REPLACE_ME"
export DEEPSEEK_BASE_URL="https://api.deepseek.com/v1"
export DEEPSEEK_CHAT_MODEL="deepseek-chat"

export SILICONFLOW_API_KEY="REPLACE_ME"
export SILICONFLOW_BASE_URL="https://api.siliconflow.cn/v1"
export SILICONFLOW_EMBED_MODEL="BAAI/bge-m3"

# WhatsApp Bridge behavior (optional; defaults to 1 in bridge code)
export WA_MARK_ONLINE="1"
export WA_AUTO_READ="1"

# Optional: MemU DB DSN (defaults to sqlite at workspace/.memu/memu.db)
export MEMU_DB_DSN="sqlite:////opt/nanobot-data/memu.db"
EOF

source ~/.bashrc
```

Do not commit real keys into git.

## Systemd (Auto-start Agent + Bridge)

```bash
# Build bridge (one-time)
cd nanobot/bridge
npm install
npm run build

# Run bootstrap once as the service user
nanobot onboard
MINIMAX_API_KEY="REPLACE_ME" \
DEEPSEEK_API_KEY="REPLACE_ME" \
SILICONFLOW_API_KEY="REPLACE_ME" \
MEMU_DB_DSN="sqlite:////opt/nanobot-data/memu.db" \
bash scripts/bootstrap.sh

# Install env + units
sudo mkdir -p /etc/nanobot
sudo cp systemd/nanobot.env.example /etc/nanobot/nanobot.env
sudo ${EDITOR:-vi} /etc/nanobot/nanobot.env
sudo cp systemd/nanobot-agent@.service /etc/systemd/system/
sudo cp systemd/nanobot-bridge@.service /etc/systemd/system/
sudo systemctl daemon-reload

# Start services (replace $(whoami) if needed). The agent unit runs `nanobot gateway`
# (non-interactive) and will fall back to ~/nanoBot_memU + ~/nanobot-venv if paths are not set.
sudo systemctl enable --now nanobot-agent@$(whoami)
sudo systemctl enable --now nanobot-bridge@$(whoami)
```

## MemU Integration Notes

- Retrieval: MemU memory context is fetched before each prompt.
- Writeback: each turn is memorized after the assistant responds, with a lightweight skip filter.
- Isolation: `user_id = f"{channel}:{chat_id}:{sender_id}"`

See `nanobot/README_MEMU.md` for details.
