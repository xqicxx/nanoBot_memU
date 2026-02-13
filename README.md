# NanoBot + MemU (Personal Fork)

This repo contains a NanoBot fork with the built-in file memory removed and replaced with **MemU**.

## Repo Layout

- `nanobot/`: NanoBot (memory → MemU integration lives here)
- `memU_test/`: MemU Python package (used by NanoBot via `memu.app.MemoryService`)

## Quick Start (Linux / Ubuntu)

```bash
# 1) Create a virtualenv (recommended; avoids PEP 668 "externally-managed-environment")
python3 -m venv /opt/nanobot-venv
source /opt/nanobot-venv/bin/activate

# 2) Install both projects (editable)
pip install -U pip
pip install -e memU_test
pip install -e nanobot

# 3) One-time init
nanobot onboard

# 4) Chat (CLI)
nanobot agent -m "Hello!"
```

## Persistent Environment Variables (bash)

Put your API keys/model endpoints in `~/.bashrc` so they persist across sessions:

```bash
cat <<'EOF' >> ~/.bashrc

# NanoBot / MemU
export DEEPSEEK_API_KEY="REPLACE_ME"
export DEEPSEEK_BASE_URL="https://api.deepseek.com/v1"
export DEEPSEEK_CHAT_MODEL="deepseek-chat"

export SILICONFLOW_API_KEY="REPLACE_ME"
export SILICONFLOW_BASE_URL="https://api.siliconflow.cn/v1"
export SILICONFLOW_EMBED_MODEL="BAAI/bge-m3"

# Optional: MemU DB DSN (defaults to sqlite at workspace/.memu/memu.db)
# export MEMU_DB_DSN="sqlite:////absolute/path/to/memu.db"
EOF

source ~/.bashrc
```

Do not commit real keys into git.

## MemU Integration Notes

- Retrieval: MemU memory context is fetched before each prompt.
- Writeback: each turn is memorized after the assistant responds, with a lightweight skip filter.
- Isolation: `user_id = f"{channel}:{chat_id}:{sender_id}"`

See `nanobot/README_MEMU.md` for details.

