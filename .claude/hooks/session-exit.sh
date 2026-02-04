#!/bin/bash
# session-exit.sh - Checks for uncommitted work before session ends
# Hook: Uncommitted Work Check

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    exit 0
fi

# Check for uncommitted changes
CHANGES=$(git status --porcelain 2>/dev/null)

if [[ -n "$CHANGES" ]]; then
    echo "" >&2
    echo "========================================" >&2
    echo "WARNING: Uncommitted changes detected!" >&2
    echo "========================================" >&2
    echo "" >&2
    git status --short >&2
    echo "" >&2
    echo "Consider committing before ending session:" >&2
    echo "  git add <files> && git commit -m 'WIP: <description>'" >&2
    echo "" >&2
fi

exit 0
