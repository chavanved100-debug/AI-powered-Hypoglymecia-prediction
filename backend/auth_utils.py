"""Shared credential helpers and authentication limits.

Password hashes use the same salted SHA-256 format as the Flutter client
implementation. No secrets are ever written to logs.
"""

from __future__ import annotations

import hmac
import re
import secrets
from hashlib import sha256

MAX_LOGIN_FAILURES = 10
LOGIN_FAILURE_WINDOW_SECONDS = 900
MIN_PASSWORD_LENGTH = 6

_EMAIL_RE = re.compile(r"[^@\s]+@[^@\s]+\.[^@\s]+")


def hash_password(password: str) -> tuple[str, str]:
    """Return a random salt and the salted SHA-256 password digest."""
    salt = secrets.token_hex(16)
    return salt, _password_digest(password, salt)


def verify_password(password: str, salt: str, stored_hash: str) -> bool:
    return hmac.compare_digest(_password_digest(password, salt), stored_hash)


def _password_digest(password: str, salt: str) -> str:
    return sha256(f"{salt}::{password}".encode("utf-8")).hexdigest()


def is_valid_email(email: str) -> bool:
    return _EMAIL_RE.fullmatch(email) is not None
