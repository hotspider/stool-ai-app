#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# ===== 可改配置区（只改这里）=====
WORKER_DIR="${WORKER_DIR:-$HOME/stool-ai-worker}"
WORKER_NAME="${WORKER_NAME:-stool-ai-worker}"
API_BASE="${API_BASE:-https://api.tapgiga.com}"
OPENAI_PROXY_URL="${OPENAI_PROXY_URL:-https://openai-proxy-c4hk.onrender.com}"

# 你可以通过环境变量传 OPENAI_API_KEY；如果没传脚本会提示你手动输入（但只在第一次）
OPENAI_API_KEY_ENV="${OPENAI_API_KEY:-}"

# 验证用图片（可不传；不传则只做 /ping 和 JSON test）
VERIFY_IMG="${VERIFY_IMG:-}"

echo "==> Config:"
echo "    WORKER_DIR=$WORKER_DIR"
echo "    WORKER_NAME=$WORKER_NAME"
echo "    API_BASE=$API_BASE"
echo "    OPENAI_PROXY_URL=$OPENAI_PROXY_URL"
echo "    VERIFY_IMG=${VERIFY_IMG:-<empty>}"
echo

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1"; exit 1; }; }
need_cmd npx
need_cmd curl
need_cmd python3

# 1) 先验证 Render proxy 活着
echo "==> [1/6] Checking OpenAI Proxy: $OPENAI_PROXY_URL/ping"
curl -sS "$OPENAI_PROXY_URL/ping" | head -c 500
echo -e "\n"

# 2) 写入 Worker secrets（OPENAI_PROXY_URL 必须）
echo "==> [2/6] Setting Worker secret OPENAI_PROXY_URL"
cd "$WORKER_DIR"
printf "%s" "$OPENAI_PROXY_URL" | npx wrangler secret put OPENAI_PROXY_URL >/dev/null
echo "    OK"

# 2.1) 写入 OPENAI_API_KEY（如果你愿意让 Worker 也持有 key；否则也可以只给 Render）
if [[ -n "$OPENAI_API_KEY_ENV" ]]; then
  echo "==> [2.1/6] Setting Worker secret OPENAI_API_KEY from env"
  printf "%s" "$OPENAI_API_KEY_ENV" | npx wrangler secret put OPENAI_API_KEY >/dev/null
  echo "    OK"
else
  echo "==> [2.1/6] OPENAI_API_KEY not provided in env, skipping (OK if only Render has it)"
fi
echo

# 3) 部署 Worker
echo "==> [3/4] Deploying Worker..."
npx wrangler deploy
echo

# 4) 调用全链路验证
echo "==> [4/4] Running full-flow verification"
cd "$ROOT_DIR"
API_BASE="$API_BASE" OPENAI_PROXY_URL="$OPENAI_PROXY_URL" \
  ./tools/verify_full_flow.sh
