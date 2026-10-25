#!/usr/bin/env bash
set -euo pipefail

WORKDIR="$(pwd)"
GROUP="agent-workspace"
RESTRICT_USER="agent"
COMMAND="codex --sandbox workspace-write --ask-for-approval never"
SETUP=false
RECENT=false
HOURS=""

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

setup_group() {
    # Create the group if it doesn't exist.
    if ! dseditgroup -o checkmember -m admin "$GROUP" >/dev/null 2>&1; then
        sudo dseditgroup -o create "$GROUP"
    fi

    # Ensure both users are members.
    sudo dseditgroup -o edit -a admin -t user "$GROUP"
    sudo dseditgroup -o edit -a agent -t user "$GROUP"
}

case "${1:-}" in
    -x)
        SETUP=true
        shift
        ;;
    -i)
        RECENT=true
        if [[ $# -lt 2 ]]; then
            echo "Usage: $0 -i <hours>" >&2
            exit 2
        fi
        HOURS="$2"
        if [[ ! "$HOURS" =~ ^[0-9]+([.][0-9]+)?$ ]] || ! awk -v h="$HOURS" 'BEGIN { exit !(h > 0) }'; then
            echo "Error: hours must be a positive number: $HOURS" >&2
            exit 2
        fi
        shift 2
        ;;
esac

if [[ "$SETUP" == true || "$RECENT" == true ]]; then
    setup_group

    if [[ "$SETUP" == true ]]; then
        # Original -x behavior: fix the entire workspace recursively.
        sudo chgrp -R "$GROUP" "$WORKDIR"
        sudo chmod -R u+rwX,g+rwX,o-rwx "$WORKDIR"
        find "$WORKDIR" -type d -exec sudo chmod g+s {} +
        echo "Full workspace permission setup completed: $WORKDIR"
    else
        MINUTES="$(awk -v h="$HOURS" 'BEGIN { printf "%.0f", h * 60 }')"
        echo "Finding entries changed in the last $HOURS hour(s), plus anything the agent cannot use..."

        FLIST="$(mktemp)"
        DLIST="$(mktemp)"
        trap 'rm -f "$FLIST" "$DLIST"' EXIT

        # Match recent entries (birth or mtime) union'd with anything still
        # not group-usable, so a copy that kept its original timestamps
        # (ditto/cp -p/rsync -a/unzip) still gets fixed.
        RECENT_EXPR=( \( -Bmin "-$MINUTES" -o -mmin "-$MINUTES" \) )
        # Skip entries the agent already owns (e.g. .claude/.cc-writes).
        BROKEN_EXPR=( ! -user "$RESTRICT_USER" \
                      \( ! -group "$GROUP" \
                          -o \( -type f ! -perm -g+rw \) \
                          -o \( -type d ! -perm -g+rwx \) \
                          -o \( -type d ! -perm -2000 \) \) )
        SELECT_EXPR=( \( "${RECENT_EXPR[@]}" -o "${BROKEN_EXPR[@]}" \) )

        sudo /usr/bin/find "$WORKDIR" \( -type f -o -type d \) "${SELECT_EXPR[@]}" -print0 > "$FLIST"

        if [[ ! -s "$FLIST" ]]; then
            echo "Nothing matched; no workspace permissions were changed."
        else
            # Unique ancestor directories up to WORKDIR, in a single pass.
            sudo /usr/bin/find "$WORKDIR" -type d "${SELECT_EXPR[@]}" -print0 > "$DLIST"
            tr '\0' '\n' < "$FLIST" | awk -v root="$WORKDIR" '
                {
                    d = $0; sub(/\/[^\/]*$/, "", d)
                    while (length(d) >= length(root) && !(d in seen)) {
                        seen[d] = 1; print d
                        if (d == root) break
                        sub(/\/[^\/]*$/, "", d)
                    }
                }' | tr '\n' '\0' >> "$DLIST"

            echo "Updating permissions for $(tr -cd '\0' < "$FLIST" | wc -c | tr -d ' ') file(s) and $(tr -cd '\0' < "$DLIST" | wc -c | tr -d ' ') director(ies)..."

            xargs -0 sudo chgrp "$GROUP" < "$FLIST"
            xargs -0 sudo chgrp "$GROUP" < "$DLIST"
            xargs -0 sudo chmod u+rwX,g+rwX,o-rwx < "$FLIST"
            xargs -0 sudo chmod u+rwX,g+rwX,o-rwx < "$DLIST"
            xargs -0 sudo chmod g+s < "$DLIST"

            # Confirm nothing is still inaccessible before reporting success.
            LEFTOVER="$(sudo /usr/bin/find "$WORKDIR" "${BROKEN_EXPR[@]}" -print 2>/dev/null | head -20)"
            if [[ -n "$LEFTOVER" ]]; then
                echo "WARNING: still not group-usable by '$RESTRICT_USER':" >&2
                printf '  %s\n' "$LEFTOVER" >&2
                echo "Run '$0 -x' to fix the whole workspace." >&2
            else
                echo "Permission update completed; all of $WORKDIR is readable by '$RESTRICT_USER'."
            fi
        fi      
    fi

    # Any remaining positional args are folders to lock the agent user out of.
    if [[ $# -gt 0 ]]; then
        echo
        for folder in "$@"; do
            restrict_folder "$folder"
            echo
        done
    fi

    exit 0
fi

sudo -H -u agent \
    HOME=/Users/agent \
    bash -lc "cd '$WORKDIR' && umask 007 && exec $COMMAND"
