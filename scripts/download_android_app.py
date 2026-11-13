"""Downloads the Sauce Labs My Demo App APK used by tests/mobile (skips when present).

Usage: uv run python scripts/download_android_app.py
"""

import sys
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "libraries"))

import config_resolver  # noqa: E402  (needs the path above)


def main() -> int:
    variables = config_resolver.get_variables()
    target = Path(variables["ANDROID_APP"])
    url = config_resolver.get("ANDROID_APP_URL")
    if target.is_file():
        print(f"APK already present: {target}")
        return 0
    if not url:
        print("ANDROID_APP_URL is not configured.", file=sys.stderr)
        return 1
    target.parent.mkdir(parents=True, exist_ok=True)
    print(f"Downloading {url}")
    urllib.request.urlretrieve(url, target)  # noqa: S310 (fixed https URL from config)
    print(f"Saved {target} ({target.stat().st_size // 1024} KiB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
