#!/bin/bash
# Build the redstick-brief plugin into a .plugin file ready to send Cam.
#
# Usage:  ./build.sh
# Output: ../redstick-brief.plugin (one folder up, in the Plugins directory)
#
# Requires: zip (preinstalled on macOS)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLUGIN_NAME="redstick-brief"
OUTPUT_PATH="$SCRIPT_DIR/../$PLUGIN_NAME.plugin"

echo "Building $PLUGIN_NAME..."

# Validate the plugin manifest is valid JSON
python3 -c "import json; json.load(open('$SCRIPT_DIR/.claude-plugin/plugin.json'))" \
  && echo "  [OK] plugin.json valid" \
  || { echo "  [ERROR] plugin.json invalid JSON"; exit 1; }

# Bump the version timestamp comment in the manifest (manual semver bumps still required)
echo "  Current version: $(python3 -c "import json; print(json.load(open('$SCRIPT_DIR/.claude-plugin/plugin.json'))['version'])")"

# Remove old build
rm -f "$OUTPUT_PATH"
rm -f "/tmp/$PLUGIN_NAME.plugin"

# Build in /tmp first (writing directly to mounted folders sometimes fails)
# Use a positive include-list (.claude-plugin, commands, skills) so dev-only
# files at the repo root (README.md, SHIP-EMAIL.md, build.sh, EDITING.md, n8n/, etc.)
# never accidentally get bundled into the shipped plugin.
cd "$SCRIPT_DIR"
zip -r "/tmp/$PLUGIN_NAME.plugin" .claude-plugin commands skills -x "*.DS_Store" > /dev/null
cp "/tmp/$PLUGIN_NAME.plugin" "$OUTPUT_PATH"

echo "  [OK] Built: $OUTPUT_PATH"
echo ""
echo "Send to Cam:"
echo "  $OUTPUT_PATH"
