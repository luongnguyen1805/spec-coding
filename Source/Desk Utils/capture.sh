#!/bin/bash
# Capture launch, Manage Apps, and Manage Folders in separate UI tests.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(/usr/bin/dirname -- "${BASH_SOURCE[0]}")" && /bin/pwd -P)"
if [[ $# -ne 0 ]]; then
    printf 'Usage: "%s/capture.sh"\n' "$SCRIPT_DIR"
    exit 1
fi
if /usr/bin/pgrep -x DeskUtils > /dev/null; then
    printf 'Quit DeskUtils before running capture.sh.\n' >&2
    exit 1
fi
STAMP="$(/bin/date '+%Y%m%d-%H%M%S')-$$"
RESULTS="$SCRIPT_DIR/AutomationArtifacts/Capture-$STAMP.xcresult"
/bin/mkdir -p "$SCRIPT_DIR/AutomationArtifacts"
/usr/bin/xcodebuild test \
    -project "$SCRIPT_DIR/DeskUtils.xcodeproj" \
    -scheme DeskUtils \
    -configuration Debug \
    -destination 'platform=macOS' \
    -derivedDataPath "$SCRIPT_DIR/AutomationArtifacts/Build" \
    -resultBundlePath "$RESULTS" \
    -parallel-testing-enabled NO \
    -only-testing:DeskUtilsUITests/DeskUtilsCaptureTests
for NAME in launch apps folders; do
    SCREENSHOT="$SCRIPT_DIR/$NAME.png"
    /usr/bin/python3 "$SCRIPT_DIR/export-capture.py" "$RESULTS" "$SCREENSHOT" "$NAME"
    if [[ ! -s "$SCREENSHOT" ]]; then
        printf 'Screenshot missing: %s\n' "$SCREENSHOT" >&2
        exit 1
    fi
    printf 'Saved screenshot: %s\n' "$SCREENSHOT"
done
printf 'Test results: %s\n' "$RESULTS"
