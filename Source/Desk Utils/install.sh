#!/bin/bash
set -euo pipefail

# Build a local Release app and replace /Applications/DeskUtils.app.
SCRIPT_DIR="$(CDPATH= cd -- "$(/usr/bin/dirname "${BASH_SOURCE[0]}")" && /bin/pwd -P)"
PROJECT_PATH="${SCRIPT_DIR}/DeskUtils.xcodeproj"
BUILD_DIR="${SCRIPT_DIR}/.build/install"
BUILT_APP="${BUILD_DIR}/Release/DeskUtils.app"
INSTALL_PATH="/Applications/DeskUtils.app"

if [[ "$(/usr/bin/uname -s)" != "Darwin" ]]; then
    /usr/bin/printf '%s\n' 'DeskUtils must be built and installed on macOS.' >&2
    exit 1
fi

if [[ ! -d "${PROJECT_PATH}" ]]; then
    /usr/bin/printf 'Xcode project not found: %s\n' "${PROJECT_PATH}" >&2
    exit 1
fi

/usr/bin/printf '%s\n' 'Building DeskUtils (Release)…'
/usr/bin/xcodebuild \
    -project "${PROJECT_PATH}" \
    -target DeskUtils \
    -configuration Release \
    -sdk macosx \
    "SYMROOT=${BUILD_DIR}/Products" \
    "OBJROOT=${BUILD_DIR}/Intermediates" \
    "CONFIGURATION_BUILD_DIR=${BUILD_DIR}/Release" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY=- \
    DEVELOPMENT_TEAM= \
    build

if [[ ! -x "${BUILT_APP}/Contents/MacOS/DeskUtils" ]]; then
    /usr/bin/printf 'Release executable not found: %s\n' "${BUILT_APP}" >&2
    exit 1
fi

# Request elevated access only if the installation location requires it.
INSTALL_NEEDS_SUDO=false
if [[ ! -w /Applications ]] || [[ -e "${INSTALL_PATH}" && ! -w "${INSTALL_PATH}" ]]; then
    INSTALL_NEEDS_SUDO=true
fi

install_command() {
    if [[ "${INSTALL_NEEDS_SUDO}" == true ]]; then
        /usr/bin/sudo "$@"
    else
        "$@"
    fi
}

STAGING_DIR="$(install_command /usr/bin/mktemp -d /Applications/.DeskUtils-install.XXXXXX)"
cleanup() {
    install_command /bin/rm -rf -- "${STAGING_DIR}"
}
trap cleanup EXIT

# Finish copying before replacing the existing app; remove stale bundle files.
install_command /usr/bin/ditto "${BUILT_APP}" "${STAGING_DIR}/DeskUtils.app"
install_command /bin/rm -rf -- "${INSTALL_PATH}"
install_command /bin/mv "${STAGING_DIR}/DeskUtils.app" "${INSTALL_PATH}"

/usr/bin/printf 'Installed: %s\n' "${INSTALL_PATH}"
