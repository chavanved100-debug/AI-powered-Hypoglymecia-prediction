"""Login endpoint tests for directly-registered accounts."""

from __future__ import annotations

from backend import auth_utils
from backend.tests.helpers import VALID, BaseCase


class LoginTests(BaseCase):
    def test_login_succeeds_after_registration(self) -> None:
        self.assertEqual(self._register().status_code, 201)

        resp = self._login()
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        self.assertEqual(data["status"], "ok")
        self.assertEqual(data["name"], "Test User")
        self.assertEqual(data["email"], "user@example.com")

    def test_unregistered_email_rejected(self) -> None:
        resp = self._login(email="nobody@example.com")
        self.assertEqual(resp.status_code, 404)
        self.assertEqual(resp.get_json()["error"], "user_not_found")

    def test_wrong_password_rejected(self) -> None:
        self._register()

        resp = self._login(password="wrong-password")
        self.assertEqual(resp.status_code, 401)
        self.assertEqual(resp.get_json()["error"], "invalid_password")

    def test_login_email_is_case_insensitive(self) -> None:
        self._register()

        resp = self._login(email="USER@Example.COM")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()["email"], "user@example.com")

    def test_login_response_never_contains_password_material(self) -> None:
        self._register()

        resp = self._login()
        body = resp.get_data(as_text=True)
        self.assertNotIn(VALID["password"], body)
        self.assertNotIn("password_hash", body)
        self.assertNotIn('"salt"', body)

    def test_invalid_email_rejected(self) -> None:
        resp = self._login(email="not-an-email")
        self.assertEqual(resp.status_code, 400)
        self.assertEqual(resp.get_json()["error"], "invalid_email")


class LoginThrottleTests(BaseCase):
    def _register_account(self) -> None:
        resp = self._register()
        self.assertEqual(resp.status_code, 201)

    def test_lockout_after_repeated_failures_blocks_correct_password(self) -> None:
        self._register_account()

        for _ in range(auth_utils.MAX_LOGIN_FAILURES):
            resp = self._login(password="wrong-guess")
            self.assertEqual(resp.status_code, 401)

        locked = self._login(password=VALID["password"])
        self.assertEqual(locked.status_code, 429)
        self.assertEqual(locked.get_json()["error"], "login_limited")

    def test_unknown_email_also_rate_limited(self) -> None:
        for _ in range(auth_utils.MAX_LOGIN_FAILURES):
            resp = self._login(email="ghost@example.com")
            self.assertEqual(resp.status_code, 404)

        locked = self._login(email="ghost@example.com")
        self.assertEqual(locked.status_code, 429)
        self.assertEqual(locked.get_json()["error"], "login_limited")

    def test_successful_login_clears_failure_counter(self) -> None:
        self._register_account()
        self._login(password="wrong-one")
        self._login(password="wrong-two")
        self.assertEqual(len(self._rows("SELECT email FROM login_rate")), 1)

        ok = self._login()
        self.assertEqual(ok.status_code, 200)
        self.assertEqual(self._rows("SELECT email FROM login_rate"), [])

    def test_lockout_expires_after_window(self) -> None:
        self._register_account()
        for _ in range(auth_utils.MAX_LOGIN_FAILURES):
            self._login(password="wrong-guess")
        self.assertEqual(self._login().status_code, 429)

        self._execute(
            "UPDATE login_rate SET window_start = 1 WHERE email = ?",
            (VALID["email"].lower(),),
        )
        resp = self._login()
        self.assertEqual(resp.status_code, 200)


class RequestHardeningTests(BaseCase):
    def test_oversized_request_body_rejected(self) -> None:
        resp = self.client.post(
            "/auth/login",
            json={"email": "u@example.com", "padding": "x" * (70 * 1024)},
        )
        self.assertEqual(resp.status_code, 413)


if __name__ == "__main__":
    import unittest

    unittest.main()
