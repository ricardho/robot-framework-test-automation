"""Single place where every setting is resolved.

Used in two ways:
* as a Robot Framework **variable file** (``get_variables``), so suites get
  ``${BASE_URL}``, ``${BROWSER}``... already resolved;
* as a plain module by Python libraries (``get``/``required``).

Resolution order, first non-blank value wins:
    1. ``robot --variable NAME:value`` (Robot gives CLI variables precedence over variable files)
    2. environment variable ``NAME``
    3. local ``.env`` file (git-ignored)
    4. versioned ``config/settings.toml``
    5. default passed by the caller
"""

from __future__ import annotations

import os
import tomllib
from functools import cache
from pathlib import Path

from dotenv import dotenv_values

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SETTINGS_FILE = PROJECT_ROOT / "config" / "settings.toml"
DOTENV_FILE = PROJECT_ROOT / ".env"

VALID_BROWSERS = ("chromium", "firefox", "webkit")
VALID_EVIDENCE_MODES = ("failure", "always", "steps")


class MissingConfigurationError(RuntimeError):
    """Raised when a required setting (usually a secret) is not provided."""

    ROBOT_SUPPRESS_NAME = True


@cache
def _dotenv() -> dict[str, str]:
    if not DOTENV_FILE.is_file():
        return {}
    return {key: value for key, value in dotenv_values(DOTENV_FILE).items() if value is not None}


@cache
def _settings() -> dict[str, str]:
    if not SETTINGS_FILE.is_file():
        return {}
    with SETTINGS_FILE.open("rb") as file:
        return {key: str(value) for key, value in tomllib.load(file).items()}


def _robot_cli_value(name: str) -> str | None:
    """Value given with ``--variable`` when running inside Robot, else None."""
    try:
        from robot.libraries.BuiltIn import BuiltIn, RobotNotRunningError

        return BuiltIn().get_variable_value(f"${{{name}}}")
    except (ImportError, RobotNotRunningError):
        return None


def get(name: str, default: str | None = None) -> str | None:
    """Resolve ``name`` through env var, .env and settings file."""
    for source in (os.environ, _dotenv(), _settings()):
        value = source.get(name)
        if value is not None and str(value).strip():
            return str(value).strip()
    return default


def required(name: str) -> str:
    """Resolve a mandatory setting or fail fast explaining how to provide it."""
    value = _robot_cli_value(name) or get(name)
    if not value:
        raise MissingConfigurationError(
            f"Missing configuration '{name}'. Set the environment variable {name}, "
            f"add it to .env (copy .env.example) or pass --variable {name}:<value>. "
            "In GitHub Actions create it as a repository secret."
        )
    return value


def _choice(name: str, default: str, valid: tuple[str, ...]) -> str:
    value = (get(name, default) or default).lower()
    if value not in valid:
        raise ValueError(f"Invalid {name} '{value}'. Valid values: {', '.join(valid)}.")
    return value


def _flag(name: str, default: str) -> bool:
    return (get(name, default) or default).lower() in ("true", "1", "yes")


def get_variables() -> dict[str, object]:
    """Variable file entry point. Secrets are NOT exported here: they are read
    lazily with the ``Get Required Config`` keyword so a missing secret only
    breaks the tests that need it."""
    return {
        "API_BASE_URL": get("API_BASE_URL", "https://serverest.dev"),
        "BASE_URL": get("BASE_URL", "https://front.serverest.dev"),
        "BROWSER": _choice("BROWSER", "chromium", VALID_BROWSERS),
        "HEADLESS": _flag("HEADLESS", "true"),
        "TIMEOUT": get("TIMEOUT", "15s"),
        "MOBILE_DEVICE_IOS": get("MOBILE_DEVICE_IOS", "iPhone 14"),
        "MOBILE_DEVICE_ANDROID": get("MOBILE_DEVICE_ANDROID", "Pixel 7"),
        "APPIUM_URL": get("APPIUM_URL", "http://127.0.0.1:4723"),
        # Appium needs an absolute path; relative values are resolved from the project root
        "ANDROID_APP": str(PROJECT_ROOT / get("ANDROID_APP", "apps/mda-2.3.0-27.apk")),
        "SERVEREST_ADMIN_EMAIL": get("SERVEREST_ADMIN_EMAIL", "rf-automation.admin@example.com"),
        "EVIDENCE_MODE": _choice("EVIDENCE_MODE", "failure", VALID_EVIDENCE_MODES),
        "EVIDENCE_PDF": _flag("EVIDENCE_PDF", "true"),
    }
