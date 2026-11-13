"""Removes credentials from text that goes into evidence (HTTP bodies, step titles)."""

from __future__ import annotations

import re

import config_resolver

SECRET_NAMES = ("SERVEREST_ADMIN_PASSWORD",)
_JSON_FIELDS = re.compile(r'("(?:password|authorization|token)"\s*:\s*)"[^"]*"', re.IGNORECASE)
_KEY_VALUE = re.compile(r"\b(password|authorization|token)=([^&\s,}]+)", re.IGNORECASE)
_BEARER = re.compile(r"Bearer\s+[A-Za-z0-9._-]+")


def _secret_values() -> list[str]:
    values = []
    for name in SECRET_NAMES:
        value = config_resolver.get(name)
        if value:
            values.append(value)
    return values


def mask(text: str) -> str:
    text = _JSON_FIELDS.sub(r'\1"***"', text)
    text = _KEY_VALUE.sub(r"\1=***", text)
    text = _BEARER.sub("Bearer ***", text)
    for secret in _secret_values():
        text = text.replace(secret, "***")
    return text
