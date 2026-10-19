#!/usr/bin/env python3
"""Compile the Swift package and stage a signed macOS application."""
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
DIST = ROOT / "dist"
APP = DIST / "Domo.app"


def main():
    subprocess.run(
        ["swift", "build", "--configuration", "release", "--product", "Domo"],
        cwd=ROOT,
        check=True,
    )
    binary_directory = subprocess.check_output(
        ["swift", "build", "--configuration", "release", "--show-bin-path"],
        cwd=ROOT,
        text=True,
    ).strip()
    with (ROOT / "Resources/Info.plist").open("rb") as file:
        metadata = plistlib.load(file)
    if APP.exists():
        with (APP / "Contents/Info.plist").open("rb") as file:
            if plistlib.load(file).get("CFBundleIdentifier") != metadata["CFBundleIdentifier"]:
                raise SystemExit("O destino pertence a outro aplicativo; nenhum arquivo foi substituído.")

    DIST.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".package-", dir=DIST) as directory:
        temporary = Path(directory)
        staged = temporary / APP.name
        executable = staged / "Contents/MacOS/Domo"
        resources = staged / "Contents/Resources"
        executable.parent.mkdir(parents=True)
        resources.mkdir(parents=True)
        shutil.copy2(Path(binary_directory) / "Domo", executable)
        shutil.copy2(ROOT / "Resources/Info.plist", staged / "Contents/Info.plist")
        shutil.copytree(ROOT / "Licenses", resources / "Licenses")
        subprocess.run(["codesign", "--force", "--sign", "-", str(staged)], check=True)
        subprocess.run(["codesign", "--verify", "--deep", "--strict", str(staged)], check=True)

        previous = temporary / "previous.app"
        if APP.exists():
            APP.rename(previous)
        try:
            staged.rename(APP)
        except OSError:
            if previous.exists():
                previous.rename(APP)
            raise
    print(f"Aplicativo pronto: {APP}")


if __name__ == "__main__":
    main()
