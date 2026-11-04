"""Credential helper tests."""

from __future__ import annotations

import unittest
from hashlib import sha256

from backend import auth_utils


class PasswordHelperTests(unittest.TestCase):
    def test_password_helpers_match_flutter_algorithm(self) -> None:
        salt, digest = auth_utils.hash_password("hunter22")
        self.assertEqual(
            digest, sha256(f"{salt}::hunter22".encode()).hexdigest()
        )
        self.assertTrue(auth_utils.verify_password("hunter22", salt, digest))
        self.assertFalse(auth_utils.verify_password("hunter23", salt, digest))


class EmailValidationTests(unittest.TestCase):
    def test_email_validation(self) -> None:
        self.assertTrue(auth_utils.is_valid_email("a.b+tag@sub.example.com"))
        self.assertFalse(auth_utils.is_valid_email("nope"))
        self.assertFalse(auth_utils.is_valid_email("a@b"))
        self.assertFalse(auth_utils.is_valid_email("a b@c.com"))


if __name__ == "__main__":
    unittest.main()
