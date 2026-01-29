#!/usr/bin/env python3
import base64
import json
import os
import sys
import urllib.request


def fail(message):
    print(f"FAIL: {message}")
    sys.exit(1)


def get_image_path():
    if len(sys.argv) > 1:
        return os.path.expanduser(sys.argv[1])
    return os.path.expanduser("~/Desktop/test.jpg")


def main():
    image_path = get_image_path()
    if not os.path.exists(image_path):
        fail(f"image not found: {image_path}")

    with open(image_path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode("utf-8")

    payload = {
        "image": b64,
        "age_months": 30,
        "odor": "none",
        "pain_or_strain": False,
        "diet_keywords": "banana",
        "context_input": {
            "recent_foods": ["banana", "vegetables"],
            "recent_drinks": ["milk"],
            "mood_energy": "good",
            "appetite": "ok",
            "sleep": "good",
            "fever": False,
            "vomit": False,
            "belly_pain": False,
            "stool_times_24h": 1,
            "cold_exposure": True,
            "recent_antibiotics": None,
            "other_notes": "晨起这一泡",
        },
    }

    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "curl/8.6.0",
    }
    verify_token = os.environ.get("VERIFY_TOKEN", "").strip()
    if verify_token:
        headers["X-Verify-Token"] = verify_token

    req = urllib.request.Request(
        "https://api.tapgiga.com/analyze",
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            status = resp.getcode()
            headers = {k.lower(): v for k, v in resp.headers.items()}
            body = resp.read().decode("utf-8")
    except Exception as exc:
        fail(f"request failed: {exc}")

    if status != 200:
        fail(f"HTTP {status}")

    try:
        data = json.loads(body)
    except Exception:
        fail("response is not valid JSON")

    if data.get("schema_version") != 2:
        fail("schema_version is not 2")

    if data.get("ok") is False and data.get("error_code") in (
        "PROXY_ERROR",
        "INVALID_JSON",
    ):
        fail(f"error_code {data.get('error_code')}")

    if headers.get("x-openai-model", "unknown") == "unknown":
        fail("x-openai-model is unknown")
    if data.get("model_used", "unknown") == "unknown":
        fail("model_used is unknown")

    stool = data.get("stool_features") or {}
    if not stool.get("shape_desc"):
        fail("stool_features.shape_desc empty")
    if not stool.get("color_desc"):
        fail("stool_features.color_desc empty")
    if not stool.get("texture_desc"):
        fail("stool_features.texture_desc empty")

    interpretation = data.get("interpretation") or {}
    if len(interpretation.get("why_shape") or []) < 2:
        fail("interpretation.why_shape < 2")
    if len(interpretation.get("why_color") or []) < 2:
        fail("interpretation.why_color < 2")
    if len(interpretation.get("why_texture") or []) < 2:
        fail("interpretation.why_texture < 2")
    if len(interpretation.get("how_context_affects") or []) < 3:
        fail("interpretation.how_context_affects < 3")

    actions = data.get("actions_today") or {}
    for key in ["diet", "hydration", "care", "avoid", "observe"]:
        if len(actions.get(key) or []) < 3:
            fail(f"actions_today.{key} < 3")

    if len(data.get("red_flags") or []) < 5:
        fail("red_flags < 5")

    ui = data.get("ui_strings") or {}
    sections = ui.get("sections") or []
    if len(sections) < 4:
        fail("ui_strings.sections < 4")
    for idx, section in enumerate(sections):
        items = section.get("items") or []
        if len(items) < 3:
            fail(f"ui_strings.sections[{idx}].items < 3")

    print("PASS")


if __name__ == "__main__":
    main()
