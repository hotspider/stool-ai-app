#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-https://api.tapgiga.com}"
OPENAI_PROXY_URL="${OPENAI_PROXY_URL:-https://openai-proxy-c4hk.onrender.com}"

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1"; exit 1; }; }
need_cmd curl
need_cmd python3

echo "==> [1/3] Proxy /ping"
curl -sS "$OPENAI_PROXY_URL/ping" | head -c 200
echo -e "\n"

echo "==> [2/3] Worker /ping"
curl -sS "$API_BASE/ping" | head -c 200
echo -e "\n"

echo "==> [3/3] Worker /analyze"
IMG_DATA_URL="$(python3 - <<'PY'
import base64, struct, zlib
width, height = 32, 32
rows = []
for y in range(height):
    row = b"\x00" + b"\xFF\xFF\xFF" * width
    rows.append(row)
raw = b"".join(rows)
compressed = zlib.compress(raw)

def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)

png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", compressed)
png += chunk(b"IEND", b"")

b64 = base64.b64encode(png).decode("ascii")
print("data:image/png;base64," + b64)
PY
)"
payload="$(python3 - <<PY
import json
print(json.dumps({
  "image": """$IMG_DATA_URL""",
  "age_months": 30,
  "odor": "none",
  "pain_or_strain": False,
  "diet_keywords": "banana"
}))
PY
)"

resp="$(curl -sS -w "\nHTTP_STATUS:%{http_code}\n" \
  -H "Content-Type: application/json" \
  --data-binary "$payload" \
  "$API_BASE/analyze" || true)"
status="$(echo "$resp" | tail -n 1 | sed 's/HTTP_STATUS://')"
body="$(echo "$resp" | sed '$d')"
echo "HTTP Status: $status"
echo "$body" | head -c 1200
echo

BODY="$body" python3 - <<'PY'
import json, sys
import re

import os
body = os.environ.get("BODY", "")
try:
    data = json.loads(body)
except Exception as e:
    print("[verify_full_flow] ERROR: response is not JSON:", e)
    sys.exit(1)

required = [
    "headline","score","confidence","stool_features","actions_today",
    "ui_strings","summary","bristol_type","color","texture","hydration_hint","diet_advice"
]
missing = [k for k in required if k not in data]

sf_required = ["bristol_type","color","texture","volume","visible_findings"]
at_required = ["diet","hydration","care","avoid"]
ui_required = ["summary","tags","sections"]

sf = data.get("stool_features") or {}
at = data.get("actions_today") or {}
ui = data.get("ui_strings") or {}

missing += [f"stool_features.{k}" for k in sf_required if k not in sf]
missing += [f"actions_today.{k}" for k in at_required if k not in at]
missing += [f"ui_strings.{k}" for k in ui_required if k not in ui]

if missing:
    print("[verify_full_flow] ERROR: missing fields:", ", ".join(missing))
    sys.exit(1)

print("[verify_full_flow] OK: required fields present")
PY

echo "==> DONE"
