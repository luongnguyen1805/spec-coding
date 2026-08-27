#!/usr/bin/env bash
set -euo pipefail

WORKDIR="$(pwd)"
GROUP="agent-workspace"
COMMAND="gemini --skip-trust --yolo"
SETUP=false

while getopts "x" opt; do
    case "$opt" in
        x)
            SETUP=true
            ;;
        *)
            echo "Usage: $0 [-x]"
            exit 1
            ;;
    esac
done

if [[ "$SETUP" == true ]]; then
    # Create the group if it doesn't exist
    if ! dseditgroup -o checkmember -m admin "$GROUP" >/dev/null 2>&1; then
        sudo dseditgroup -o create "$GROUP"
    fi

    # Ensure both users are members
    sudo dseditgroup -o edit -a admin -t user "$GROUP"
    sudo dseditgroup -o edit -a agent -t user "$GROUP"

    # Set workspace group ownership
    sudo chgrp -R "$GROUP" "$WORKDIR"

    # Existing files/folders:
    # owner = full access
    # group = full access
    # others = no access
    sudo chmod -R u+rwX,g+rwX,o-rwx "$WORKDIR"

    # Ensure directories pass the group to newly-created items
    find "$WORKDIR" -type d -exec sudo chmod g+s {} +

    echo "Workspace setup completed: $WORKDIR"
    exit 0
fi

# Run Claude as restricted user
exec sudo -H -u agent \
    HOME=/Users/agent \
    bash -lc "cd '$WORKDIR' && umask 007 &&  exec $COMMAND"