#!/usr/bin/env python3
"""
gen_qrc.py — Regenerate qml/qml.qrc from assets/balsam_out/

Run from the Oven_HMI_G2L_QT5/ directory:
    python3 tools/gen_qrc.py

What it does:
  - Reads every model directory under assets/balsam_out/
  - Generates <file alias="..."> entries for each .qml wrapper and every .mesh
  - Preserves the non-model sections of qml.qrc (QML app files, assets media)
  - Writes the result back to qml/qml.qrc

Why this script exists:
  Qt5 balsam renames mesh files to object-name-based filenames
  (e.g. mesh_mesh.mesh -> circle_020.mesh).  Both the .qml wrapper and the
  qml.qrc alias section must be consistent with those new names.  This script
  derives the alias entries directly from the filesystem so there is no manual
  typing of filenames.

Models embedded by default (turkey excluded — not wired into DrinkModel3D yet):
  pizza, chicken, fish, meatball, bread

To add turkey, add "turkey" to MODELS below.
"""

import os
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Directory this script lives in
SCRIPT_DIR = Path(__file__).parent

# Project root (one level up from tools/)
PROJECT_ROOT = SCRIPT_DIR.parent

BALSAM_OUT   = PROJECT_ROOT / "assets" / "balsam_out"
QRC_PATH     = PROJECT_ROOT / "qml" / "qml.qrc"

# Models to embed.  Turkey is excluded by default because DrinkModel3D.qml
# has a case for it but qml.qrc never included it.  Add "turkey" here when
# you are ready to wire it up.
MODELS = ["pizza", "chicken", "fish", "meatball", "bread"]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def model_entries(model_name: str) -> list[str]:
    """Return the list of <file ...> XML lines for one model."""
    model_dir  = BALSAM_OUT / model_name
    meshes_dir = model_dir / "meshes"

    if not model_dir.exists():
        print(f"  WARNING: balsam_out/{model_name}/ not found — skipping", file=sys.stderr)
        return []

    # Capitalised QML name  (e.g. "pizza" -> "Pizza.qml")
    qml_files = sorted(model_dir.glob("*.qml"))
    if not qml_files:
        print(f"  WARNING: no .qml in balsam_out/{model_name}/ — skipping", file=sys.stderr)
        return []
    qml_name = qml_files[0].name      # e.g. "Pizza.qml"

    lines = []
    indent = "        "   # 8 spaces — matches the existing qml.qrc style

    # .qml wrapper
    lines.append(
        f'{indent}<file alias="models/{model_name}/{qml_name}">'
        f'../assets/balsam_out/{model_name}/{qml_name}</file>'
    )

    # .mesh files — sorted for deterministic output
    mesh_files = sorted(meshes_dir.glob("*.mesh"))
    if not mesh_files:
        print(f"  WARNING: no .mesh files in balsam_out/{model_name}/meshes/ — check balsam output", file=sys.stderr)

    for mesh in mesh_files:
        lines.append(
            f'{indent}<file alias="models/{model_name}/meshes/{mesh.name}">'
            f'../assets/balsam_out/{model_name}/meshes/{mesh.name}</file>'
        )

    return lines


# ---------------------------------------------------------------------------
# QRC template
# ---------------------------------------------------------------------------

def build_qrc() -> str:
    """Build the complete qml.qrc XML string."""

    # Collect model sections
    model_xml_blocks = []
    for model in MODELS:
        entries = model_entries(model)
        if entries:
            block_lines = [f"\n        <!-- {model} -->"] + entries
            model_xml_blocks.append("\n".join(block_lines))

    models_xml = "\n".join(model_xml_blocks)

    return f"""\
<RCC>
    <qresource prefix="/qml">
        <!-- App QML files -->
        <file>Main.qml</file>
        <file>MenuPage.qml</file>
        <file>AdjustmentPage.qml</file>
        <file>ProcessingPage.qml</file>
        <file>Screensaver.qml</file>
        <file>StartupPage.qml</file>
        <file>HomePage.qml</file>
        <file>CarouselMenu.qml</file>
        <file>Theme.qml</file>
        <file>DrinkModel3D.qml</file>
        <file>qmldir</file>
        <file>drinks.js</file>
{models_xml}
    </qresource>

    <qresource prefix="/assets">
        <!-- Qt5 port: background video disabled; .mov excluded from the binary to
             save ~30 MB. Re-add this line if video playback is restored.
        <file alias="media/baking_pizza.mov">../assets/media/baking_pizza.mov</file>
        -->

        <file alias="media/click.wav">../assets/media/click.wav</file>
        <file alias="media/click_2.wav">../assets/media/click_2.wav</file>
        <file alias="media/left_click.png">../assets/media/left_click.png</file>
        <file alias="media/left_unclick.png">../assets/media/left_unclick.png</file>
        <file alias="media/right_click.png">../assets/media/right_click.png</file>
        <file alias="media/right_unclick.png">../assets/media/right_unclick.png</file>
        <file alias="media/bread.png">../assets/media/bread.png</file>
        <file alias="media/fish.png">../assets/media/fish.png</file>
        <file alias="media/meatball.png">../assets/media/meatball.png</file>
        <file alias="media/chicken.png">../assets/media/chicken.png</file>
        <file alias="media/pizza.png">../assets/media/pizza.png</file>
    </qresource>
</RCC>
"""


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    # Sanity check: must be run from Oven_HMI_G2L_QT5/ or the paths will be wrong
    if not (PROJECT_ROOT / "qml" / "qml.qrc").exists():
        print("ERROR: Run this script from Oven_HMI_G2L_QT5/", file=sys.stderr)
        print(f"  Expected to find: {QRC_PATH}", file=sys.stderr)
        sys.exit(1)

    print(f"Generating {QRC_PATH} ...")
    print(f"  Source: {BALSAM_OUT}")
    print(f"  Models: {', '.join(MODELS)}")

    # Validate balsam_out exists
    if not BALSAM_OUT.exists():
        print(f"ERROR: {BALSAM_OUT} does not exist.", file=sys.stderr)
        print("  Run balsam on the .glb files first (see BUILD.md).", file=sys.stderr)
        sys.exit(1)

    # Verify mesh format (v3) before writing — catch mistakes early
    bad = []
    import struct
    for model in MODELS:
        for mesh in sorted((BALSAM_OUT / model / "meshes").glob("*.mesh")):
            with open(mesh, "rb") as f:
                header = f.read(12)
            if len(header) < 6:
                bad.append(str(mesh))
                continue
            file_id, file_version = struct.unpack_from("<IH", header, 0)
            if file_id != 0xC8A07F4D or file_version != 3:
                bad.append(f"{mesh} (id=0x{file_id:08X} ver={file_version})")

    if bad:
        print("ERROR: The following meshes are NOT Qt5 v3 format:", file=sys.stderr)
        for b in bad:
            print(f"  {b}", file=sys.stderr)
        print("  Re-run balsam with a Qt5.15 balsam binary (see BUILD.md).", file=sys.stderr)
        sys.exit(1)

    content = build_qrc()
    QRC_PATH.write_text(content, encoding="utf-8")

    # Print a summary
    total_meshes = sum(
        len(list((BALSAM_OUT / m / "meshes").glob("*.mesh"))) for m in MODELS
    )
    print(f"  Written {QRC_PATH.name}: {len(MODELS)} models, {total_meshes} meshes total.")
    print("Done.")


if __name__ == "__main__":
    main()
