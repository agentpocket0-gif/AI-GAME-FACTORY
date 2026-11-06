import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import google_quota


class GeminiProjectPoolTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        google_quota.STATE = Path(self.temp_dir.name) / "state.json"
        google_quota.LOCK = Path(self.temp_dir.name) / "state.lock"

    def test_two_keys_require_confirmed_separate_projects(self):
        with patch.dict(os.environ, {
            "GEMINI_API_KEY_1": "test-key-1",
            "GEMINI_API_KEY_2": "test-key-2",
            "GEMINI_PROJECTS_ARE_SEPARATE": "false",
        }, clear=False):
            with self.assertRaisesRegex(RuntimeError, "different Google Cloud projects"):
                google_quota.reserve_request("video", "gemini-3.5-flash-lite",
                    rpm_cap=10, model_daily_cap=500, group_daily_cap=1000)

    def test_round_robin_uses_both_independent_projects(self):
        with patch.dict(os.environ, {
            "GEMINI_API_KEY_1": "test-key-1",
            "GEMINI_API_KEY_2": "test-key-2",
            "GEMINI_PROJECTS_ARE_SEPARATE": "true",
        }, clear=False):
            first = google_quota.reserve_request("video", "gemini-3.5-flash-lite",
                rpm_cap=10, model_daily_cap=500, group_daily_cap=1000)
            second = google_quota.reserve_request("video", "gemini-3.5-flash-lite",
                rpm_cap=10, model_daily_cap=500, group_daily_cap=1000)
            self.assertEqual(first, ("project_1", "test-key-1"))
            self.assertEqual(second, ("project_2", "test-key-2"))

    def test_quota_is_enforced_separately_for_each_project(self):
        with patch.dict(os.environ, {
            "GEMINI_API_KEY_1": "test-key-1",
            "GEMINI_API_KEY_2": "test-key-2",
            "GEMINI_PROJECTS_ARE_SEPARATE": "true",
        }, clear=False):
            google_quota.reserve_request("gemma4", "gemma-4-26b-a4b-it",
                rpm_cap=1, model_daily_cap=None, group_daily_cap=100)
            google_quota.reserve_request("gemma4", "gemma-4-31b-it",
                rpm_cap=1, model_daily_cap=None, group_daily_cap=100)
            with self.assertRaisesRegex(RuntimeError, "reached the local app-side quota guard"):
                google_quota.reserve_request("gemma4", "gemma-4-26b-a4b-it",
                    rpm_cap=1, model_daily_cap=None, group_daily_cap=100)


if __name__ == "__main__":
    unittest.main()
