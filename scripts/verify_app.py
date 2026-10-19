#!/usr/bin/env python3
"""Inspect the generated bundle without launching the app or contacting devices."""
from pathlib import Path
import base64
import plistlib
import subprocess

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "dist/Domo.app"


def main():
    with (APP / "Contents/Info.plist").open("rb") as file:
        metadata = plistlib.load(file)
    with (ROOT / "Resources/Info.plist").open("rb") as file:
        source_metadata = plistlib.load(file)
    for key in ("CFBundleShortVersionString", "CFBundleVersion", "SUFeedURL", "SUPublicEDKey"):
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
        and file.relative_to(APP).as_posix() != "Contents/Frameworks/Sparkle.framework/Versions/B/Resources/ReleaseNotesColorStyle.css"
    ]
    if unexpected or (APP / "Contents/Helpers").exists():
        raise SystemExit("O pacote contém arquivos de um runtime legado.")
    linked = subprocess.check_output(
        ["otool", "-L", str(APP / "Contents/MacOS/Domo")], text=True
    )
    if "/WebKit.framework/" in linked:
        raise SystemExit("O executável ainda depende de WebKit.")
    if "@rpath/Sparkle.framework/" not in linked:
        raise SystemExit("O executável não está vinculado ao Sparkle.")
    if metadata.get("SUFeedURL") != "https://github.com/barrossjoao/domo/releases/latest/download/appcast.xml":
        raise SystemExit("O feed precisa apontar para a release pública do Domo.")
    if len(base64.b64decode(metadata.get("SUPublicEDKey", ""), validate=True)) != 32:
        raise SystemExit("A chave pública de atualização é inválida.")
    for key in ("SUEnableAutomaticChecks", "SUAutomaticallyUpdate", "SUVerifyUpdateBeforeExtraction", "SURequireSignedFeed"):
        if metadata.get(key) is not True:
            raise SystemExit(f"Configuração de atualização ausente: {key}")
    if metadata.get("SUShowReleaseNotes") is not False:
        raise SystemExit("As atualizações não devem abrir notas em uma webview.")
    framework = APP / "Contents/Frameworks/Sparkle.framework"
    if not (framework / "Sparkle").is_file() or not (framework / "Versions/Current").is_symlink():
        raise SystemExit("O framework Sparkle ou seus links simbólicos não foram preservados.")
    load_commands = subprocess.check_output(["otool", "-l", str(APP / "Contents/MacOS/Domo")], text=True)
    if "@executable_path/../Frameworks" not in load_commands:
        raise SystemExit("O executável não encontra os frameworks embarcados.")
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(APP)], check=True)
    print("Pacote válido: menu bar, assinatura local e executável nativo sem runtime web.")


if __name__ == "__main__":
    main()
