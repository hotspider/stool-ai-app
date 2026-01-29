import base64
import json
import os
import sys
import urllib.request


def read_b64(path: str) -> str:
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def post_analyze(image_path: str, user_confirmed: bool = False):
    url = "https://api.tapgiga.com/analyze"
    payload = {
        "image": read_b64(image_path),
        "age_months": 30,
        "odor": "none",
        "pain_or_strain": False,
        "diet_keywords": "banana",
        "context": {
            "foods_eaten": "米饭,香蕉",
            "drinks_taken": "温水",
            "mood_state": "精神好",
            "other_notes": "无",
        },
        "user_confirmed_stool": user_confirmed,
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Content-Type": "application/json",
            "User-Agent": "verify-detection-flow/1.0",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        body = resp.read().decode("utf-8")
        return json.loads(body)


def assert_stool(name: str, resp: dict):
    is_stool = resp.get("is_stool_image")
    conf = resp.get("stool_confidence")
    if is_stool is not True:
        raise AssertionError(f"{name}: expected is_stool_image=true, got {is_stool}")
    if conf is not None and isinstance(conf, (int, float)) and conf < 0.25:
        raise AssertionError(f"{name}: stool_confidence too low ({conf})")


def assert_not_stool(name: str, resp: dict):
    is_stool = resp.get("is_stool_image")
    if is_stool is not False:
        raise AssertionError(f"{name}: expected is_stool_image=false, got {is_stool}")


def main():
    mushy = os.path.expanduser(os.environ.get("MUSHY_IMAGE", "~/Desktop/mushy.jpg"))
    diaper = os.path.expanduser(os.environ.get("DIAPER_IMAGE", "~/Desktop/diaper.jpg"))
    non_stool = os.path.expanduser(os.environ.get("NON_STOOL_IMAGE", "~/Desktop/non_stool.jpg"))

    if not os.path.exists(mushy) or not os.path.exists(diaper) or not os.path.exists(non_stool):
        print("Missing image path(s). Set MUSHY_IMAGE/DIAPER_IMAGE/NON_STOOL_IMAGE.")
        sys.exit(1)

    cases = [
        ("mushy", mushy, True),
        ("diaper", diaper, True),
        ("non_stool", non_stool, False),
    ]

    for name, path, expect_stool in cases:
        resp = post_analyze(path, user_confirmed=True if name in ("mushy", "diaper") else False)
        print(
            f"[{name}] is_stool_image={resp.get('is_stool_image')} "
            f"stool_confidence={resp.get('stool_confidence')} "
            f"scene={resp.get('stool_scene')} form={resp.get('stool_form_hint')}"
        )
        if expect_stool:
            assert_stool(name, resp)
        else:
            assert_not_stool(name, resp)

    print("PASS")


if __name__ == "__main__":
    main()
