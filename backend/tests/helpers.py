"""Shared test fixtures for direct registration and login."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from backend.app import create_app, get_db

VALID = {
    "name": "Test User",
    "email": "User@Example.com",
    "password": "secret123",
}


class BaseCase(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.db_path = Path(tmp.name) / "test.db"
        self.app = create_app(
            {"TESTING": True, "DATABASE": str(self.db_path)}
        )
        self.client = self.app.test_client()

    def _register(self, **overrides):
        return self.client.post(
            "/auth/register", json={**VALID, **overrides}
        )

    def _login(self, email=VALID["email"], password=VALID["password"]):
        return self.client.post(
            "/auth/login", json={"email": email, "password": password}
        )

    def _rows(self, sql: str, params=()):
        with self.app.app_context():
            db = get_db()
            return [dict(r) for r in db.execute(sql, params).fetchall()]

    def _execute(self, sql: str, params=()) -> None:
        with self.app.app_context():
            db = get_db()
            db.execute(sql, params)
