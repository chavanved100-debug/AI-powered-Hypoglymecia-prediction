"""Flask authentication API: direct registration and password login.

Secrets stay backend-only: this module never returns password hashes or
credentials in any response.
"""

from __future__ import annotations

import logging
import os
import sqlite3
import time
from pathlib import Path

from dotenv import load_dotenv
from flask import Flask, current_app, g, jsonify, request

from . import auth_utils

_BACKEND_DIR = Path(__file__).resolve().parent
for _env_path in (_BACKEND_DIR / ".env", _BACKEND_DIR.parent / ".env"):
    if _env_path.is_file():
        load_dotenv(_env_path)

DEFAULT_DATABASE = _BACKEND_DIR / "guard.db"

logger = logging.getLogger(__name__)

_SCHEMA = """
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE COLLATE NOCASE,
    salt TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    created_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS login_rate (
    email TEXT PRIMARY KEY COLLATE NOCASE,
    window_start INTEGER NOT NULL,
    fail_count INTEGER NOT NULL
);
"""


def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(
            current_app.config["DATABASE"],
            isolation_level=None,
        )
        g.db.row_factory = sqlite3.Row
    return g.db


def _close_db(exception=None):
    db = g.pop("db", None)
    if db is not None:
        db.close()


def _safe_rollback(db):
    try:
        db.execute("ROLLBACK")
    except sqlite3.OperationalError:
        pass


def _payload() -> dict:
    data = request.get_json(silent=True)
    return data if isinstance(data, dict) else {}


def _email_from_payload(data: dict) -> str:
    return str(data.get("email", "")).strip().lower()


def _error(message: str, code: str, status: int):
    return jsonify(error=code, message=message), status


def register():
    data = _payload()
    name = str(data.get("name", "")).strip()
    email = _email_from_payload(data)
    password = str(data.get("password", ""))
    if not name:
        return _error("Enter your name", "invalid_name", 400)
    if not auth_utils.is_valid_email(email):
        return _error("Enter a valid email", "invalid_email", 400)
    if len(password) < auth_utils.MIN_PASSWORD_LENGTH:
        return _error(
            "Password must be at least 6 characters", "weak_password", 400
        )

    db = get_db()
    now = int(time.time())
    salt, password_hash = auth_utils.hash_password(password)

    try:
        db.execute("BEGIN IMMEDIATE")
        if db.execute("SELECT 1 FROM users WHERE email = ?", (email,)).fetchone():
            _safe_rollback(db)
            return _error("An account already exists", "account_exists", 409)
        db.execute(
            "INSERT INTO users (name, email, salt, password_hash, created_at) "
            "VALUES (?, ?, ?, ?, ?)",
            (name, email, salt, password_hash, now),
        )
        db.execute("COMMIT")
    except sqlite3.IntegrityError:
        _safe_rollback(db)
        return _error("An account already exists", "account_exists", 409)
    except Exception:
        _safe_rollback(db)
        raise

    logger.info("Registration successful")
    return jsonify(
        status="registered",
        message="Account created.",
        name=name,
        email=email,
    ), 201


def login():
    """Authenticate an account.

    Repeated failures for one email are throttled to blunt password
    brute-forcing.
    """
    data = _payload()
    email = _email_from_payload(data)
    password = str(data.get("password", ""))
    if not auth_utils.is_valid_email(email):
        return _error("Enter a valid email", "invalid_email", 400)

    db = get_db()
    now = int(time.time())
    try:
        db.execute("BEGIN IMMEDIATE")
        rate = db.execute(
            "SELECT window_start, fail_count FROM login_rate WHERE email = ?",
            (email,),
        ).fetchone()
        within_window = (
            rate is not None
            and rate["window_start"]
            > now - auth_utils.LOGIN_FAILURE_WINDOW_SECONDS
        )
        if within_window and rate["fail_count"] >= auth_utils.MAX_LOGIN_FAILURES:
            _safe_rollback(db)
            return _error(
                "Too many failed attempts. Try again later.",
                "login_limited",
                429,
            )

        row = db.execute(
            "SELECT name, salt, password_hash FROM users WHERE email = ?",
            (email,),
        ).fetchone()
        password_ok = row is not None and auth_utils.verify_password(
            password, row["salt"], row["password_hash"]
        )

        if not password_ok:
            if within_window:
                window_start = rate["window_start"]
                fail_count = rate["fail_count"] + 1
            else:
                window_start = now
                fail_count = 1
            db.execute(
                "INSERT INTO login_rate (email, window_start, fail_count) "
                "VALUES (?, ?, ?) ON CONFLICT(email) DO UPDATE SET "
                "window_start = excluded.window_start, "
                "fail_count = excluded.fail_count",
                (email, window_start, fail_count),
            )
            db.execute("COMMIT")
            if row is None:
                return _error(
                    "No account found for this email", "user_not_found", 404
                )
            return _error("Incorrect password", "invalid_password", 401)

        db.execute("DELETE FROM login_rate WHERE email = ?", (email,))
        db.execute("COMMIT")
    except Exception:
        _safe_rollback(db)
        raise

    logger.info("Login successful")
    return jsonify(status="ok", name=row["name"], email=email), 200


def create_app(test_config=None):
    app = Flask(__name__)
    app.config.from_mapping(
        DATABASE=os.getenv("DATABASE") or str(DEFAULT_DATABASE),
        MAX_CONTENT_LENGTH=64 * 1024,
    )
    if test_config:
        app.config.update(test_config)

    app.teardown_appcontext(_close_db)

    with app.app_context():
        db = get_db()
        db.executescript(_SCHEMA)

    app.add_url_rule("/auth/register", "register", register, methods=["POST"])
    app.add_url_rule("/auth/login", "login", login, methods=["POST"])
    return app
