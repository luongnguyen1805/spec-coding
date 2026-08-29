#!/usr/bin/env bash
set -euo pipefail

WORKDIR="$(pwd)"
GROUP="agent-workspace"
COMMAND="gemini --skip-trust --yolo"
RESTRICT_USER="agent"
SETUP=false

restrict_folder() {
    local target="$1"

    if [[ ! -d "$target" ]]; then
        echo "Error: folder does not exist: $target" >&2
        return 1
    fi

    target="$(cd "$target" && pwd)"

    echo "Restricting user '$RESTRICT_USER' from:"
    echo "  $target"

    sudo chmod +a "$RESTRICT_USER deny read,write,execute,delete,append,readattr,writeattr,readextattr,writeextattr,readsecurity,writesecurity,chown" "$target"

    echo "ACL:"
    ls -lde "$target"
}

while getopts "x" opt; do
    case "$opt" in
        x)
            SETUP=true
            ;;
        *)
            echo "Usage: $0 [-x [restrict-folder1] [restrict-folder2] ...]"
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

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

    # Any remaining positional args are folders to lock the agent user out of
    if [[ $# -gt 0 ]]; then
        echo
        for folder in "$@"; do
            restrict_folder "$folder"
            echo
        done
    fi

    exit 0
fi

# Run Claude as restricted user
exec sudo -H -u agent \
    HOME=/Users/agent \
    bash -lc "cd '$WORKDIR' && umask 007 &&  exec $COMMAND"