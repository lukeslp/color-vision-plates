"""Explicit public routes must not expose unrelated files from the server root."""
import importlib.util
import json
from html.parser import HTMLParser
from urllib.parse import urlsplit
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("plates_api", ROOT / "api.py")
api = importlib.util.module_from_spec(spec)
spec.loader.exec_module(api)


class StaticRoutesTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.original_root = api.app.root_path
        api.app.root_path = self.directory.name
        self.addCleanup(setattr, api.app, "root_path", self.original_root)
        self.client = api.app.test_client()
        self.root = Path(self.directory.name)
        for name in ("index.html", "color-math.js", "privacy.html", "pwa.webmanifest", "og-beta.png",
                     "icon-512.png", "icon-512-maskable.png"):
            (self.root / name).write_text("public fixture " + name)
        (self.root / ".well-known").mkdir()
        (self.root / ".well-known/assetlinks.json").write_text("[]")
        # Harmless stand-ins: no real database, environment, or Git data read.
        (self.root / "private-sentinel.txt").write_text("private sentinel")
        (self.root / ".git").mkdir()
        (self.root / ".git/config").write_text("private sentinel")
        (self.root / "beta.db").write_text("private sentinel")
        (self.root / ".env").write_text("private sentinel")

    def test_public_routes_remain_available(self):
        for path in ("/", "/color-math.js", "/privacy", "/privacy.html", "/pwa.webmanifest",
                     "/og-beta.png", "/og-beta-v2.png", "/.well-known/assetlinks.json"):
            with self.subTest(path=path):
                with self.client.get(path) as response:
                    self.assertEqual(response.status_code, 200)
        with self.client.get("/health") as response:
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.json["status"], "healthy")

    def test_page_and_manifest_icons_are_local_and_served(self):
        class IconLinks(HTMLParser):
            def __init__(self):
                super().__init__()
                self.paths = set()

            def handle_starttag(self, tag, attrs):
                attrs = dict(attrs)
                if tag == "link" and attrs.get("rel") in ("icon", "apple-touch-icon"):
                    self.paths.add(attrs["href"])

        links = IconLinks()
        links.feed((ROOT / "index.html").read_text())
        manifest = json.loads((ROOT / "pwa.webmanifest").read_text())
        paths = links.paths | {icon["src"] for icon in manifest["icons"]}
        self.assertEqual(paths, {"icon-512.png", "icon-512-maskable.png"})
        for source in paths:
            with self.subTest(source=source):
                parsed = urlsplit(source)
                self.assertFalse(parsed.scheme or parsed.netloc, "Icons must work without a remote host")
                self.assertTrue((ROOT / source).is_file())
                with self.client.get("/" + source) as response:
                    self.assertEqual(response.status_code, 200)
                    self.assertEqual(response.mimetype, "image/png")

    def test_unlisted_files_are_not_served(self):
        for name in ("private-sentinel.txt", ".git/config", "beta.db", ".env"):
            for prefix in ("/", "/./", "/%2e/"):
                with self.subTest(path=prefix + name):
                    with self.client.get(prefix + name) as response:
                        self.assertEqual(response.status_code, 404)
                        self.assertNotIn(b"private sentinel", response.data)


if __name__ == "__main__":
    unittest.main()
