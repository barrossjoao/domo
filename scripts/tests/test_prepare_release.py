from pathlib import Path
import base64
import importlib.util
import tempfile
import unittest
import xml.etree.ElementTree as ET

spec = importlib.util.spec_from_file_location("prepare_release", Path(__file__).parents[1] / "prepare_release.py")
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class ReleaseValidationTests(unittest.TestCase):
    def setUp(self):
        self.metadata = {"CFBundleShortVersionString": "2.2.9", "CFBundleVersion": "14"}

    def test_tag_rejects_different_version_and_invalid_build(self):
        release.validate_tag("v2.2.9", self.metadata)
        for tag in ("v2.2.8", "2.2.9", "v2.2.9-beta", "v2.2.9/other"):
            with self.assertRaises(ValueError):
                release.validate_tag(tag, self.metadata)
        with self.assertRaises(ValueError):
            release.validate_tag("v2.2.9", dict(self.metadata, CFBundleVersion="0"))

    def test_feed_rejects_wrong_version_url_size_and_missing_signature(self):
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory) / "Domo-2.2.9-mac-universal.zip"
            archive.write_bytes(b"synthetic archive")
            feed = Path(directory) / "appcast.xml"
            root = ET.Element("rss")
            item = ET.SubElement(ET.SubElement(root, "channel"), "item")
            version = ET.SubElement(item, f"{{{release.SPARKLE}}}version")
            version.text = "14"
            ET.SubElement(item, f"{{{release.SPARKLE}}}shortVersionString").text = "2.2.9"
            signature_key = f"{{{release.SPARKLE}}}edSignature"
            enclosure = ET.SubElement(item, "enclosure", {
                "url": f"{release.REPOSITORY}/releases/download/v2.2.9/{archive.name}",
                "length": str(archive.stat().st_size),
                signature_key: base64.b64encode(bytes(64)).decode(),
            })
            def validate():
                ET.ElementTree(root).write(feed)
                return release.validate_feed(feed, archive, self.metadata, "v2.2.9")
            self.assertEqual(validate(), enclosure.get(signature_key))
            for key, invalid in (("url", "https://example.invalid/app.zip"), ("length", "0"), (signature_key, "")):
                previous = enclosure.get(key)
                enclosure.set(key, invalid)
                with self.assertRaises(ValueError):
                    validate()
                enclosure.set(key, previous)
            version.text = "13"
            with self.assertRaises(ValueError):
                validate()


if __name__ == "__main__":
    unittest.main()
