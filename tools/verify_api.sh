#!/usr/bin/env bash
set -euo pipefail

# ---- config ----
API_BASE="${API_BASE:-https://api.tapgiga.com}"
ENDPOINT="${ENDPOINT:-/analyze}"
IMG="${IMG:-$HOME/Downloads/1.jpg}"

AGE_MONTHS="${AGE_MONTHS:-30}"
ODOR="${ODOR:-none}"
PAIN_OR_STRAIN="${PAIN_OR_STRAIN:-false}"
DIET_KEYWORDS="${DIET_KEYWORDS:-banana}"
# ----------------

if [[ ! -f "$IMG" ]]; then
  echo "[verify_api] ERROR: image file not found: $IMG" >&2
  echo "Usage: IMG=/absolute/path.jpg API_BASE=https://api.tapgiga.com ./tools/verify_api.sh" >&2
  exit 2
fi

if [[ ! -r "$IMG" ]]; then
  echo "[verify_api] ERROR: image file not readable: $IMG" >&2
  exit 2
fi

FILE_SIZE=$(wc -c < "$IMG" | tr -d ' ')
if [[ "$FILE_SIZE" -le 0 ]]; then
  echo "[verify_api] ERROR: image file empty: $IMG" >&2
  exit 2
fi

# base64 encode (no line wraps)
B64=$(python3 - <<PY
import base64, sys
p = r"""$IMG"""
with open(p, "rb") as f:
    sys.stdout.write(base64.b64encode(f.read()).decode("ascii"))
PY
)

B64_LEN=${#B64}
if [[ "$B64_LEN" -lt 1000 ]]; then
  echo "[verify_api] ERROR: base64 too short ($B64_LEN). IMG=$IMG" >&2
  exit 3
fi

JSON=$(python3 - <<PY
import json
print(json.dumps({
  "image": r"""$B64""",
  "age_months": int("$AGE_MONTHS"),
  "odor": "$ODOR",
  "pain_or_strain": (str("$PAIN_OR_STRAIN").lower() == "true"),
  "diet_keywords": "$DIET_KEYWORDS"
}))
PY
)

URL="${API_BASE}${ENDPOINT}"
echo "[verify_api] URL=$URL"
echo "[verify_api] IMG=$IMG size=$FILE_SIZE base64Len=$B64_LEN"

# curl: print status separately, preview first 4000 chars
RESP_AND_CODE=$(curl -sS -w "\nHTTP_STATUS:%{http_code}\n" \
  -H "Content-Type: application/json" \
  --data-binary "$JSON" \
  "$URL" || true)

HTTP_STATUS=$(echo "$RESP_AND_CODE" | tail -n 1 | sed 's/HTTP_STATUS://')
BODY=$(echo "$RESP_AND_CODE" | sed '$d')

echo "HTTP Status: $HTTP_STATUS"
echo "$BODY" | head -c 4000
echo
