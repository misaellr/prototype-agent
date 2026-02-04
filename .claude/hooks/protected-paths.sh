#!/bin/bash
# protected-paths.sh - Blocks writes to sensitive files
# Hook: Protected Path Block

# Source platform compatibility library
SCRIPT_DIR="$(dirname "$0")"
. "$SCRIPT_DIR/lib/platform.sh"

# Extract file_path from JSON input (Edit/Write tools pass JSON with file_path field)
RAW_INPUT="$1"
if [[ "$RAW_INPUT" == "{"* ]]; then
    # Input is JSON - extract file_path field
    FILE_PATH=$(echo "$RAW_INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
else
    # Input is plain path (backwards compatibility)
    FILE_PATH="$RAW_INPUT"
fi

# Handle empty file path
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi


# State file exceptions - always allow hook state files
# These files are used for inter-hook coordination
if [[ "$FILE_PATH" =~ \.claude/hooks/\.self-review- ]] || \
   [[ "$FILE_PATH" =~ \.claude/hooks/\.scope-override- ]]; then
    exit 0
fi

# NEVER-ALLOW patterns - checked BEFORE override lookup
# These files cannot be edited regardless of spec approval (CRIT-01 fix)
NEVER_ALLOW_PATTERNS=(
    "^AGENTS\.md$"
    "^\.env"
    "^\.claude/"
    "^credentials"
    "^secrets"
)

# Extract filename for NEVER-ALLOW pattern matching
FILENAME=$(basename "$FILE_PATH")

# Check NEVER-ALLOW list (no override can bypass this)
for pattern in "${NEVER_ALLOW_PATTERNS[@]}"; do
    if [[ "$FILE_PATH" =~ $pattern ]] || [[ "$FILENAME" =~ $pattern ]]; then
        echo "BLOCKED: '$FILE_PATH' is a governance/credential file (no override allowed)" >&2
        exit 2
    fi
done

# Check for spec-scope override file
# If the spec-scope-enforcement hook has approved this file, allow it
OVERRIDE_DIR="$SCRIPT_DIR"
FILE_HASH=$(md5_hash "$FILE_PATH")
OVERRIDE_FILE="$OVERRIDE_DIR/.scope-override-$FILE_HASH"

if [[ -f "$OVERRIDE_FILE" ]]; then
    FILE_AGE=$(file_age_seconds "$OVERRIDE_FILE")

    if [[ "$FILE_AGE" -ge 60 ]]; then
        # Override file is stale (>= 60 seconds), delete and continue to normal checks
        rm -f "$OVERRIDE_FILE" 2>/dev/null
    else
        # Override file is fresh (< 60 seconds), allow the edit
        exit 0
    fi
fi

# Extract just the filename for pattern matching
FILENAME=$(basename "$FILE_PATH")

# Protected patterns
PROTECTED_PATTERNS=(
    "^\.env$"
    "^\.env\."
    "^AGENTS\.md$"
    "^credentials"
    "^secrets"
    "^\.claude/"
    ".*\.pem$"
    ".*_rsa$"
    "^id_rsa"
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if [[ "$FILENAME" =~ $pattern ]] || [[ "$FILE_PATH" =~ $pattern ]]; then
        echo "BLOCKED: '$FILE_PATH' is a protected file" >&2
        echo "Protected patterns: .env*, AGENTS.md, credentials*, secrets*, .claude/*, *.pem, *_rsa" >&2
        exit 2
    fi
done

exit 0
