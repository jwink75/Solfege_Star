#!/usr/bin/env bash
# ==============================================================================
# Solfège Star - HTML5 Web Export & Local Server Script
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/web-build"
CORONA_BUILDER="/Applications/Corona-3731/Native/Corona/mac/bin/CoronaBuilder.app/Contents/MacOS/CoronaBuilder"

if [ ! -f "$CORONA_BUILDER" ]; then
    echo "Error: CoronaBuilder not found at: $CORONA_BUILDER"
    exit 1
fi

# Ensure Application Support symlink exists for CoronaBuilder
CORONA_APP_SUPPORT="$HOME/Library/Application Support/Corona"
if [ ! -d "$CORONA_APP_SUPPORT/Native" ]; then
    echo "Creating Corona Native symlink in Application Support..."
    mkdir -p "$CORONA_APP_SUPPORT"
    ln -s "/Applications/Corona-3731/Native/" "$CORONA_APP_SUPPORT/Native"
fi

echo "Building Solfège Star for HTML5 (Web)..."
mkdir -p "$OUTPUT_DIR"

PARAMS_FILE=$(mktemp /tmp/solfege_build_params.XXXXXX.lua)
cat << LUA > "$PARAMS_FILE"
local params = {
    platform = 'html5',
    appName = 'SolfegeStar',
    appVersion = '1.0',
    dstPath = '${OUTPUT_DIR}',
    projectPath = '${SCRIPT_DIR}',
}
return params
LUA

"$CORONA_BUILDER" build --lua "$PARAMS_FILE"
rm -f "$PARAMS_FILE"

# Move generated files from nested .html5 directory to root of web-build if needed
if [ -d "${OUTPUT_DIR}/SolfegeStar.html5" ]; then
    mv "${OUTPUT_DIR}/SolfegeStar.html5"/* "${OUTPUT_DIR}/"
    rmdir "${OUTPUT_DIR}/SolfegeStar.html5"
fi

# Set proper page title
if [ -f "${OUTPUT_DIR}/index.html" ]; then
    sed -i '' 's|<title>SolfegeStar</title>|<title>Solfège Star</title>|g' "${OUTPUT_DIR}/index.html"
fi

echo "HTML5 build completed successfully in: ${OUTPUT_DIR}"

if [[ "${1:-}" == "--serve" || "${1:-}" == "-s" ]]; then
    PORT="${2:-8080}"
    echo "Starting local test server at: http://localhost:${PORT}"
    echo "Press Ctrl+C to stop."
    python3 -m http.server --directory "$OUTPUT_DIR" "$PORT"
fi
