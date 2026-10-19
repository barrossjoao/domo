#!/usr/bin/env python3
"""Package a universal app and generate a signed Sparkle feed before publication."""
from pathlib import Path
import argparse
import base64
import os
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
REPOSITORY = "https://github.com/barrossjoao/domo"
SPARKLE = "http://www.andymatuschak.org/xml-namespaces/sparkle"
TOOLS = ROOT / ".build/artifacts/sparkle/Sparkle/bin"


def validate_tag(tag, metadata):
    if not re.fullmatch(r"v\d+\.\d+\.\d+", tag) or tag != "v" + metadata["CFBundleShortVersionString"]:
        raise ValueError("A tag precisa corresponder à versão em Resources/Info.plist.")
    if not str(metadata["CFBundleVersion"]).isdigit() or int(metadata["CFBundleVersion"]) < 1:
        raise ValueError("O número de build precisa ser um inteiro positivo e crescente.")


def validate_feed(feed, archive, metadata, tag):
    items = ET.parse(feed).findall("./channel/item")
    if len(items) != 1:
        raise ValueError("O feed da release precisa conter exatamente uma versão.")
    item = items[0]
    for key, expected in (("version", metadata["CFBundleVersion"]),
                          ("shortVersionString", metadata["CFBundleShortVersionString"])):
        if item.findtext(f"{{{SPARKLE}}}{key}") != expected:
            raise ValueError("O feed não corresponde ao aplicativo compilado.")
    enclosure = item.find("enclosure")
    if enclosure is None or enclosure.get("url") != f"{REPOSITORY}/releases/download/{tag}/{archive.name}":
        raise ValueError("O download precisa apontar para o pacote desta release.")
    if enclosure.get("length") != str(archive.stat().st_size):
        raise ValueError("O tamanho do download diverge do pacote.")
    signature = enclosure.get(f"{{{SPARKLE}}}edSignature", "")
    if len(base64.b64decode(signature, validate=True)) != 64:
        raise ValueError("O pacote não recebeu uma assinatura EdDSA válida.")
    return signature


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--check-version", action="store_true")
    args = parser.parse_args()
    with (ROOT / "Resources/Info.plist").open("rb") as file:
        metadata = plistlib.load(file)
    validate_tag(args.tag, metadata)
    if args.check_version:
        return
    subprocess.run([sys.executable, str(ROOT / "scripts/verify_app.py")], check=True)
    app = ROOT / "dist/Domo.app"
    architectures = subprocess.check_output(["lipo", "-archs", str(app / "Contents/MacOS/Domo")], text=True).split()
    if set(architectures) != {"arm64", "x86_64"}:
        raise ValueError("Uma release precisa conter Apple silicon e Intel. Compile com --universal.")
    private_key = os.environ.pop("SPARKLE_PRIVATE_KEY", None)
    if private_key is not None and not private_key.strip():
        raise ValueError("O secret SPARKLE_PRIVATE_KEY está vazio.")
    if os.environ.get("GITHUB_ACTIONS") and private_key is None:
        raise ValueError("Configure SPARKLE_PRIVATE_KEY nos secrets do repositório.")
    signing = ["--ed-key-file", "-"] if private_key else ["--account", "domo-releases"]
    destination = ROOT / "dist/release"
    destination.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".release-", dir=ROOT / "dist") as directory:
        directory = Path(directory)
        archive = directory / f"Domo-{metadata['CFBundleShortVersionString']}-mac-universal.zip"
        feed = directory / "appcast.xml"
        subprocess.run(["ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", str(app), str(archive)], check=True)
        subprocess.run([
            str(TOOLS / "generate_appcast"), *signing,
            "--download-url-prefix", f"{REPOSITORY}/releases/download/{args.tag}/",
            "--link", REPOSITORY, "--maximum-deltas", "0", "-o", str(feed), str(directory),
        ], input=private_key, text=True, check=True)
        signature = validate_feed(feed, archive, metadata, args.tag)
        for path, extra in ((archive, [signature]), (feed, [])):
            subprocess.run([str(TOOLS / "sign_update"), *signing, "--verify", str(path), *extra],
                           input=private_key, text=True, check=True)
        for path in (archive, feed):
            shutil.copy2(path, destination / path.name)
    print(f"Release assinada e verificada: {destination}")


if __name__ == "__main__":
    main()
