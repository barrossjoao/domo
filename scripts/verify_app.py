#!/usr/bin/env python3
"""Inspect the generated bundle without launching the app or contacting devices."""
from pathlib import Path
import plistlib
import subprocess

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "dist/Domo.app"


def main():
    with (APP / "Contents/Info.plist").open("rb") as file:
        metadata = plistlib.load(file)
    with (ROOT / "Resources/Info.plist").open("rb") as file:
        source_metadata = plistlib.load(file)
    for key in ("CFBundleShortVersionString", "CFBundleVersion"):
        if metadata.get(key) != source_metadata.get(key):
            raise SystemExit("O aplicativo foi gerado com uma versão diferente do projeto. Compile novamente.")
    for key in ("CFBundleName", "CFBundleDisplayName", "CFBundleExecutable"):
        if metadata.get(key) != "Domo" or source_metadata.get(key) != "Domo":
            raise SystemExit("O pacote precisa usar Domo no nome, na apresentação e no executável.")
    if metadata.get("CFBundleIdentifier") != "br.automatizehouse.mac" or metadata.get("LSUIElement") is not True:
        raise SystemExit("O pacote não está configurado como o app de menu bar esperado.")
    unexpected = [
        file for file in APP.rglob("*")
        if file.is_file() and (file.suffix in {".js", ".cjs", ".html", ".css"} or file.name == "node")
    ]
    if unexpected or (APP / "Contents/Helpers").exists():
        raise SystemExit("O pacote contém arquivos de um runtime legado.")
    linked = subprocess.check_output(
        ["otool", "-L", str(APP / "Contents/MacOS/Domo")], text=True
    )
    if "/WebKit.framework/" in linked:
        raise SystemExit("O executável ainda depende de WebKit.")
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(APP)], check=True)
    print("Pacote válido: menu bar, assinatura local e executável nativo sem runtime web.")


if __name__ == "__main__":
    main()
