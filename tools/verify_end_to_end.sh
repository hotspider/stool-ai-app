#!/usr/bin/env bash
set -euo pipefail

# ===== Config =====
API_BASE="${API_BASE:-https://api.tapgiga.com}"
OPENAI_PROXY_URL="${OPENAI_PROXY_URL:-https://openai-proxy-c4hk.onrender.com}"
VERIFY_IMG="${VERIFY_IMG:-$HOME/Downloads/1.jpg}"
AGE_MONTHS="${AGE_MONTHS:-30}"
ODOR="${ODOR:-none}"
PAIN_OR_STRAIN="${PAIN_OR_STRAIN:-false}"
DIET_KEYWORDS="${DIET_KEYWORDS:-banana}"

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1"; exit 1; }; }
need_cmd curl
need_cmd python3
need_cmd jq

echo "==> Config:"
echo "    API_BASE=$API_BASE"
echo "    OPENAI_PROXY_URL=$OPENAI_PROXY_URL"
echo "    VERIFY_IMG=$VERIFY_IMG"
echo

echo "==> [1/4] Proxy health"
curl -sS "$OPENAI_PROXY_URL/ping" | head -c 300
echo
curl -sS "$OPENAI_PROXY_URL/health" | head -c 300
echo
curl -sS "$OPENAI_PROXY_URL/version" | head -c 300
echo -e "\n"

echo "==> [2/4] Worker /ping"
curl -sS "$API_BASE/ping" | head -c 300
echo -e "\n"

if [[ ! -f "$VERIFY_IMG" ]]; then
  echo "[verify_end_to_end] ERROR: image file not found: $VERIFY_IMG" >&2
  echo "Set VERIFY_IMG=/absolute/path.jpg and re-run." >&2
  exit 2
fi
if [[ ! -r "$VERIFY_IMG" ]]; then
  echo "[verify_end_to_end] ERROR: image file not readable: $VERIFY_IMG" >&2
  exit 2
fi

echo "==> [3/4] Prepare image payload"
b64="$(python3 - <<PY
import base64
p=r"""$VERIFY_IMG"""
with open(p, "rb") as f:
    print(base64.b64encode(f.read()).decode("ascii"))
PY
)"

payload="$(python3 - <<PY
import json
print(json.dumps({
  "image": """$b64""",
  "age_months": int("$AGE_MONTHS"),
  "odor": "$ODOR",
  "pain_or_strain": (str("$PAIN_OR_STRAIN").lower() == "true"),
  "diet_keywords": "$DIET_KEYWORDS"
}))
PY
)"

echo "==> [4/4] Worker /analyze (schema validation)"
resp="$(curl -sS -w "\nHTTP_STATUS:%{http_code}\n" \
  -H "Content-Type: application/json" \
  --data-binary "$payload" \
  "$API_BASE/analyze" || true)"
status="$(echo "$resp" | tail -n 1 | sed 's/HTTP_STATUS://')"
body="$(echo "$resp" | sed '$d')"
echo "HTTP Status: $status"
echo "$body" | head -c 1200
echo

echo "$body" | jq -e '
  .ok == true
  and .risk_level
  and (.score != null)
  and .confidence
  and .stool_features
  and .actions_today
  and .red_flags
  and .ui_strings
  and .follow_up_questions
  and .headline
  and .summary
  and .uncertainty_note
' >/dev/null && echo "[verify_end_to_end] OK: schema fields present"

echo "==> DONE"
