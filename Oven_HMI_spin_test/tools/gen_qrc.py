#!/usr/bin/env python3
"""
gen_qrc.py — regenerate qml/qml.qrc for the chicken-spin-test project.

Run from the Oven_HMI_spin_test/ root:
    python3 tools/gen_qrc.py

Verifies every .mesh file is Qt5 format v3 (magic 0xC8A07F4D, version 3)
before writing the qrc.  Exits non-zero on any format mismatch.
"""
import os, struct, sys

SCRIPT_DIR  = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)

BALSAM_DIR  = os.path.join(PROJECT_DIR, "assets", "balsam_out", "chicken")
QRC_PATH    = os.path.join(PROJECT_DIR, "qml", "qml.qrc")

MESH_MAGIC   = 0xC8A07F4D
MESH_VERSION = 3


def verify_mesh(path: str) -> bool:
    with open(path, "rb") as f:
        data = f.read(6)
    if len(data) < 6:
        return False
    fid, fv = struct.unpack_from("<IH", data)
    return fid == MESH_MAGIC and fv == MESH_VERSION


def main():
    if not os.path.isdir(BALSAM_DIR):
        print(f"ERROR: balsam_out/chicken not found: {BALSAM_DIR}", file=sys.stderr)
        sys.exit(1)

    mesh_dir = os.path.join(BALSAM_DIR, "meshes")
    meshes   = sorted(f for f in os.listdir(mesh_dir) if f.endswith(".mesh"))

    errors = []
    for m in meshes:
        full = os.path.join(mesh_dir, m)
        if not verify_mesh(full):
            errors.append(m)

    if errors:
        print("ERROR: the following meshes are NOT Qt5 v3 format — re-run balsam:",
              file=sys.stderr)
        for e in errors:
            print(f"  {e}", file=sys.stderr)
        sys.exit(1)

    lines = [
        "<RCC>",
        '    <qresource prefix="/">',
        '        <file alias="qml/Main.qml">../qml/Main.qml</file>',
        '        <file alias="assets/media/chicken.png">../assets/media/chicken.png</file>',
        '        <file alias="qml/models/chicken/Chicken.qml">'
        '../assets/balsam_out/chicken/Chicken.qml</file>',
    ]
    for m in meshes:
        lines.append(
            f'        <file alias="qml/models/chicken/meshes/{m}">'
            f'../assets/balsam_out/chicken/meshes/{m}</file>'
        )
    lines += ["    </qresource>", "</RCC>", ""]

    content = "\n".join(lines)
    with open(QRC_PATH, "w") as f:
        f.write(content)

    print(f"Written {QRC_PATH}")
    print(f"  {len(meshes)} meshes, all format v3")


if __name__ == "__main__":
    main()
