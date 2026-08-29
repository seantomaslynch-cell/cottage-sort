#!/usr/bin/env bash
# Export Cottage Sort for the web.
#
# Requires the Godot 4.7 Web export templates:
#   Godot editor > Editor > Manage Export Templates > Download and Install
#
# Usage:  GODOT=/path/to/godot tools/export_web.sh
set -euo pipefail

GODOT="${GODOT:-godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/web"
mkdir -p "$OUT"

echo "Exporting Web build -> $OUT"
if ! "$GODOT" --headless --path "$ROOT" --export-release "Web" "$OUT/index.html"; then
	echo
	echo "Export failed. If it mentions a missing export template, open the editor and run"
	echo "Editor > Manage Export Templates > Download and Install, then retry."
	exit 1
fi

echo
echo "Done. Preview locally with a plain static server:"
echo "  python -m http.server 8060 --directory \"$OUT\""
echo "then open http://localhost:8060/"
