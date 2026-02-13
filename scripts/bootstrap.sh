#!/usr/bin/env bash
set -euo pipefail

export DEFAULT_MODEL="${NANOBOT_DEFAULT_MODEL:-minimax/MiniMax-M2.1}"
export MINIMAX_API_KEY="${MINIMAX_API_KEY:-}"
export MINIMAX_API_BASE="${MINIMAX_API_BASE:-https://api.minimax.io/v1}"
export MEMU_DB_DSN="${MEMU_DB_DSN:-sqlite:///${HOME}/.nanobot/memu.db}"
export DEEPSEEK_API_KEY="${DEEPSEEK_API_KEY:-}"
export DEEPSEEK_BASE_URL="${DEEPSEEK_BASE_URL:-https://api.deepseek.com/v1}"
export DEEPSEEK_CHAT_MODEL="${DEEPSEEK_CHAT_MODEL:-deepseek-chat}"
export DEEPSEEK_CLIENT_BACKEND="${DEEPSEEK_CLIENT_BACKEND:-sdk}"
export SILICONFLOW_API_KEY="${SILICONFLOW_API_KEY:-}"
export SILICONFLOW_BASE_URL="${SILICONFLOW_BASE_URL:-https://api.siliconflow.cn/v1}"
export SILICONFLOW_EMBED_MODEL="${SILICONFLOW_EMBED_MODEL:-BAAI/bge-m3}"
export SILICONFLOW_CLIENT_BACKEND="${SILICONFLOW_CLIENT_BACKEND:-sdk}"
export WA_MARK_ONLINE="${WA_MARK_ONLINE:-1}"
export WA_AUTO_READ="${WA_AUTO_READ:-1}"

if [[ -z "${MINIMAX_API_KEY}" ]]; then
  echo "ERROR: MINIMAX_API_KEY is required."
  echo "Example:"
  echo "  MINIMAX_API_KEY=xxx MEMU_DB_DSN=sqlite:////absolute/path/memu.db bash scripts/bootstrap.sh"
  exit 1
fi
if [[ -z "${SILICONFLOW_API_KEY}" ]]; then
  echo "WARN: SILICONFLOW_API_KEY not set. MemU embeddings will fail."
fi
if [[ -z "${DEEPSEEK_API_KEY}" ]]; then
  echo "WARN: DEEPSEEK_API_KEY not set. MemU LLM steps may fail."
fi

# Ensure DB directory exists if using sqlite DSN
if [[ "${MEMU_DB_DSN}" == sqlite:///* ]]; then
  db_path="${MEMU_DB_DSN#sqlite:///}"
  db_dir="$(dirname "${db_path}")"
  mkdir -p "${db_dir}"
fi

# Write ~/.nanobot/config.json
python3 - <<'PY'
import json
import os
from pathlib import Path

default_model = os.environ["DEFAULT_MODEL"]
api_key = os.environ["MINIMAX_API_KEY"]
api_base = os.environ["MINIMAX_API_BASE"]

config = {
    "agents": {
        "defaults": {
            "model": default_model,
        },
    },
    "providers": {
        "minimax": {
            "apiKey": api_key,
            "apiBase": api_base,
        },
    },
}

path = Path.home() / ".nanobot" / "config.json"
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(config, indent=2), encoding="utf-8")
print(f"Wrote {path}")
PY

# Persist env vars in ~/.bashrc (idempotent)
bashrc="${HOME}/.bashrc"
marker_begin="# >>> nanobot-memu >>>"
marker_end="# <<< nanobot-memu <<<"

if ! grep -q "${marker_begin}" "${bashrc}" 2>/dev/null; then
  printf -v key_esc %q "${MINIMAX_API_KEY}"
  printf -v base_esc %q "${MINIMAX_API_BASE}"
  printf -v dsn_esc %q "${MEMU_DB_DSN}"
  printf -v ds_key_esc %q "${DEEPSEEK_API_KEY}"
  printf -v ds_base_esc %q "${DEEPSEEK_BASE_URL}"
  printf -v ds_model_esc %q "${DEEPSEEK_CHAT_MODEL}"
  printf -v ds_backend_esc %q "${DEEPSEEK_CLIENT_BACKEND}"
  printf -v sf_key_esc %q "${SILICONFLOW_API_KEY}"
  printf -v sf_base_esc %q "${SILICONFLOW_BASE_URL}"
  printf -v sf_model_esc %q "${SILICONFLOW_EMBED_MODEL}"
  printf -v sf_backend_esc %q "${SILICONFLOW_CLIENT_BACKEND}"
  printf -v wa_online_esc %q "${WA_MARK_ONLINE}"
  printf -v wa_read_esc %q "${WA_AUTO_READ}"
  {
    echo ""
    echo "${marker_begin}"
    echo "export MINIMAX_API_KEY=${key_esc}"
    echo "export MINIMAX_API_BASE=${base_esc}"
    if [[ -n "${DEEPSEEK_API_KEY}" ]]; then
      echo "export DEEPSEEK_API_KEY=${ds_key_esc}"
      echo "export DEEPSEEK_BASE_URL=${ds_base_esc}"
      echo "export DEEPSEEK_CHAT_MODEL=${ds_model_esc}"
      echo "export DEEPSEEK_CLIENT_BACKEND=${ds_backend_esc}"
    fi
    if [[ -n "${SILICONFLOW_API_KEY}" ]]; then
      echo "export SILICONFLOW_API_KEY=${sf_key_esc}"
      echo "export SILICONFLOW_BASE_URL=${sf_base_esc}"
      echo "export SILICONFLOW_EMBED_MODEL=${sf_model_esc}"
      echo "export SILICONFLOW_CLIENT_BACKEND=${sf_backend_esc}"
    fi
    echo "export WA_MARK_ONLINE=${wa_online_esc}"
    echo "export WA_AUTO_READ=${wa_read_esc}"
    echo "export MEMU_DB_DSN=${dsn_esc}"
    echo "${marker_end}"
  } >> "${bashrc}"
  echo "Updated ${bashrc}"
else
  echo "Found existing nanobot-memu block in ${bashrc}, skipping."
fi

echo "Done. Restart your shell or run: source ~/.bashrc"
