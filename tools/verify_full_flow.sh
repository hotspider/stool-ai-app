#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-https://api.tapgiga.com}"
PROXY_BASE="${PROXY_BASE:-https://openai-proxy-c4hk.onrender.com}"

echo "==> ping worker"
curl -sS "$API_BASE/ping" | tee /tmp/ping_worker.json
echo

echo "==> ping proxy"
curl -sS "$PROXY_BASE/ping" | tee /tmp/ping_proxy.json
echo

echo "==> analyze minimal (no image, expect ok=false but MUST return schema headers if handled)"
set +e
curl -sS -D /tmp/analyze_headers.txt -o /tmp/analyze_body.json -X POST "$API_BASE/analyze" \
  -H "Content-Type: application/json" \
  -d '{"image":"test","age_months":30,"odor":"none","pain_or_strain":false,"diet_keywords":"banana"}'
set -e

echo "==> headers"
sed -n '1,30p' /tmp/analyze_headers.txt
echo "==> body (first 1200 chars)"
python3 - <<'PY'
try:
  with open("/tmp/analyze_body.json","r",encoding="utf-8") as f:
    s=f.read()
  print(s[:1200])
except Exception as e:
  print("read body failed:", e)
PY

echo "==> model echo"
python3 - <<'PY'
import json
import re

headers = ""
try:
  with open("/tmp/analyze_headers.txt","r",encoding="utf-8") as f:
    headers = f.read()
except Exception:
  pass

model_header = None
for line in headers.splitlines():
  if line.lower().startswith("x-openai-model:"):
    model_header = line.split(":",1)[1].strip()
    break

try:
  data = json.load(open("/tmp/analyze_body.json","r",encoding="utf-8"))
  print("x-openai-model:", model_header or "missing")
  print("model_used:", data.get("model_used"))
  print("proxy_version:", data.get("proxy_version"))
  print("worker_version:", data.get("worker_version"))
except Exception as e:
  print("model echo parse failed:", e)
PY

echo "==> schema checks"
jq -e '
  if .error_code == "INVALID_IMAGE" then
    .schema_version == 2
  else
    .schema_version == 2 and
    (.ok == true or .ok == false) and
    (.headline | type=="string") and
    (.score | type=="number") and
    (.risk_level | type=="string") and
    (.confidence | type=="number") and
    (.uncertainty_note | type=="string") and
    (.stool_features | type=="object") and
    (.reasoning_bullets | length >= 5) and
    (.actions_today | length >= 8) and
    (.red_flags | length >= 5) and
    (.follow_up_questions | length >= 6) and
    (.ui_strings.sections | length >= 4)
  end
' /tmp/analyze_body.json >/dev/null && echo "schema ok" || (echo "schema failed" && exit 1)

echo
echo "==> If you want real image verify:"
echo "   VERIFY_IMG=/path/to/1.jpg $0"
echo

if [ "${VERIFY_IMG:-}" != "" ]; then
  if [ ! -f "$VERIFY_IMG" ]; then
    echo "VERIFY_IMG not found: $VERIFY_IMG" >&2
    exit 1
  fi
  if [ ! -r "$VERIFY_IMG" ]; then
    echo "VERIFY_IMG not readable: $VERIFY_IMG" >&2
    exit 1
  fi
  echo "==> analyze real image: $VERIFY_IMG"
  B64=$(python3 - <<'PY'
import base64, os, sys
p = os.environ.get("VERIFY_IMG", "")
if not p:
    print("")
    sys.exit(1)
with open(p, "rb") as f:
    sys.stdout.write(base64.b64encode(f.read()).decode("ascii"))
PY
)
  curl -sS -D /tmp/analyze_headers_real.txt -o /tmp/analyze_body_real.json -X POST "$API_BASE/analyze" \
    -H "Content-Type: application/json" \
    -d "{\"image\":\"$B64\",\"age_months\":30,\"odor\":\"none\",\"pain_or_strain\":false,\"diet_keywords\":\"banana\"}" >/dev/null
  echo "==> headers (real)"
  sed -n '1,40p' /tmp/analyze_headers_real.txt
  echo "==> body keys (real)"
  python3 - <<'PY'
import json
d=json.load(open("/tmp/analyze_body_real.json","r",encoding="utf-8"))
print("ok:", d.get("ok"))
print("schema_version:", d.get("schema_version"))
print("headline:", (d.get("headline") or "")[:80])
print("score:", d.get("score"))
print("confidence:", d.get("confidence"))
print("ui_sections:", len((d.get("ui_strings") or {}).get("sections") or []))
PY
fi

echo "==> DONE"
