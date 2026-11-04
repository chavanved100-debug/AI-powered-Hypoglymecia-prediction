"""Direct registration tests — no email verification step exists."""

from __future__ import annotations

from hashlib import sha256

from backend.tests.helpers import VALID, BaseCase


class RegistrationTests(BaseCase):
    def test_registration_creates_account_without_verification(self) -> None:
        resp = self._register()
        self.assertEqual(resp.status_code, 201)
        data = resp.get_json()
        self.assertEqual(data["status"], "registered")
        self.assertEqual(data["name"], "Test User")
        self.assertEqual(data["email"], "user@example.com")

        users = self._rows("SELECT name, email FROM users")
        self.assertEqual(
            users, [{"name": "Test User", "email": "user@example.com"}]
        )

    def test_registration_response_never_contains_password_material(self) -> None:
        resp = self._register()
        body = resp.get_data(as_text=True)
        self.assertNotIn(VALID["password"], body)
        self.assertNotIn("password_hash", body)
        self.assertNotIn('"salt"', body)

    def test_stores_salted_hash_not_plaintext_password(self) -> None:
        self._register()
        rows = self._rows("SELECT salt, password_hash FROM users")
        self.assertEqual(len(rows), 1)
        self.assertNotEqual(rows[0]["password_hash"], VALID["password"])
        self.assertTrue(rows[0]["salt"])
        expected = sha256(
            f"{rows[0]['salt']}::{VALID['password']}".encode()
        ).hexdigest()
        self.assertEqual(rows[0]["password_hash"], expected)

        raw = self.db_path.read_bytes()
        self.assertNotIn(VALID["password"].encode(), raw)

    def test_duplicate_email_rejected_case_insensitively(self) -> None:
        self.assertEqual(self._register().status_code, 201)

        again = self._register(email="USER@EXAMPLE.COM")
        self.assertEqual(again.status_code, 409)
        self.assertEqual(again.get_json()["error"], "account_exists")
        self.assertEqual(len(self._rows("SELECT id FROM users")), 1)

    def test_validation_errors_create_no_account(self) -> None:
        cases = [
            ({"name": ""}, "invalid_name"),
            ({"email": "not-an-email"}, "invalid_email"),
            ({"password": "12345"}, "weak_password"),
        ]
        for overrides, code in cases:
            resp = self._register(**overrides)
            self.assertEqual(resp.status_code, 400)
            self.assertEqual(resp.get_json()["error"], code)
        self.assertEqual(self._rows("SELECT id FROM users"), [])

    def test_empty_payload_is_rejected(self) -> None:
        resp = self.client.post("/auth/register", json={})
        self.assertEqual(resp.status_code, 400)
        self.assertEqual(resp.get_json()["error"], "invalid_name")

    def test_removed_otp_routes_are_gone(self) -> None:
        for path in (
            "/auth/register/start",
            "/auth/register/verify",
            "/auth/register/resend",
        ):
            self.assertEqual(
                self.client.post(path, json={}).status_code,
                404,
                msg=f"{path} must no longer be registered",
            )


if __name__ == "__main__":
    import unittest

    unittest.main()
