#!/bin/bash
# git-safety.sh - Blocks dangerous git and shell commands
# Hooks: Main Branch Protection, Force Push Block, Dangerous Command Block

COMMAND="$1"

# Main Branch Protection
if [[ "$COMMAND" =~ (checkout|switch)[[:space:]]+(main|master)[[:space:]]*$ ]]; then
    echo "BLOCKED: Cannot checkout/switch to protected branch (main/master)" >&2
    echo "Create a feature branch instead: git checkout -b <branch-name>" >&2
    exit 2
fi

# Force Push Block
if [[ "$COMMAND" =~ push[[:space:]].*(-f|--force|--force-with-lease) ]]; then
    echo "BLOCKED: Force push is prohibited" >&2
    echo "Use regular push or resolve conflicts manually" >&2
    exit 2
fi

# Dangerous Command Block
if [[ "$COMMAND" =~ rm[[:space:]]+-rf ]]; then
    echo "BLOCKED: rm -rf is prohibited - use rm -r for safer deletion" >&2
    exit 2
fi

if [[ "$COMMAND" =~ git[[:space:]]+reset[[:space:]]+--hard ]]; then
    echo "BLOCKED: git reset --hard is prohibited - use git stash or git checkout <file>" >&2
    exit 2
fi

if [[ "$COMMAND" =~ git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f ]]; then
    echo "BLOCKED: git clean -f is prohibited - use git clean -n for dry-run first" >&2
    exit 2
fi

exit 0
