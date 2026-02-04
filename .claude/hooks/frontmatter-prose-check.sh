#!/usr/bin/env bash
# frontmatter-prose-check.sh - PostToolUse hook for log.md frontmatter/prose consistency
# Hook: Frontmatter/Prose Check (Hook 1)
# Trigger: PostToolUse on Edit|Write for spec/work/*/log.md
# Behavior: Warn-only (always exit 0)

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


# Only process spec/work/*/log.md files
if [[ ! "$FILE_PATH" =~ spec/work/[^/]+/log\.md$ ]]; then
    exit 0
fi

# Check if file exists and is readable
if [[ ! -r "$FILE_PATH" ]]; then
    exit 0
fi

# Extract frontmatter (between first --- and second ---)
frontmatter=$(awk '
BEGIN { in_fm=0; started=0 }
/^---$/ { 
    if (!started) { started=1; in_fm=1; next }
    else { in_fm=0; exit }
}
in_fm { print }
' "$FILE_PATH")

# Skip condition: No frontmatter present
if [[ -z "$frontmatter" ]]; then
    exit 0
fi

# Extract status from frontmatter
status=$(echo "$frontmatter" | grep -E '^status:' | sed 's/^status:[[:space:]]*//')

# Skip condition: status != implement
if [[ "$status" != "implement" ]]; then
    exit 0
fi

# Extract tasks_completed from frontmatter
tasks_completed=$(echo "$frontmatter" | grep -E '^tasks_completed:' | sed 's/^tasks_completed:[[:space:]]*//')

# Default to 0 if not found or not a number
if [[ ! "$tasks_completed" =~ ^[0-9]+$ ]]; then
    tasks_completed=0
fi

# Skip condition: tasks_completed is 0
if [[ "$tasks_completed" -eq 0 ]]; then
    exit 0
fi

# Count prose task entries with **Status**: done
# Look for pattern: ### <date> - T<n>: ... or ### <date> - Task <n>: ...
# Followed by **Status**: done in the task block

prose_count=$(awk '
BEGIN { count=0; in_task=0; task_content="" }
/^### [0-9]{4}-[0-9]{2}-[0-9]{2}.*- (T[0-9]+:|Task [0-9]+:)/ {
    # Check previous task before starting new one
    if (in_task && task_content ~ /\*\*Status\*\*:[[:space:]]*done/) {
        count++
    }
    in_task=1
    task_content=""
    next
}
/^---$/ {
    # Section divider - end of task
    if (in_task && task_content ~ /\*\*Status\*\*:[[:space:]]*done/) {
        count++
    }
    in_task=0
    task_content=""
    next
}
/^## / {
    # New major section - end of task
    if (in_task && task_content ~ /\*\*Status\*\*:[[:space:]]*done/) {
        count++
    }
    in_task=0
    task_content=""
    next
}
in_task {
    task_content = task_content "\n" $0
}
END {
    # Handle last task if any
    if (in_task && task_content ~ /\*\*Status\*\*:[[:space:]]*done/) {
        count++
    }
    print count
}
' "$FILE_PATH")

# Calculate difference
difference=$((tasks_completed - prose_count))

# Make difference absolute
if [[ $difference -lt 0 ]]; then
    difference=$((difference * -1))
fi

# Skip condition: Mismatch of +1 (allow in-progress tolerance)
if [[ $difference -le 1 ]]; then
    exit 0
fi

# Warn on mismatch (> 1 difference)
echo "WARNING: Frontmatter/prose mismatch in $FILE_PATH" >&2
echo "  Frontmatter tasks_completed: $tasks_completed" >&2
echo "  Prose done task entries: $prose_count" >&2
echo "  Difference: $difference (> 1 allowed tolerance)" >&2
echo "  Please verify frontmatter matches prose section." >&2
echo "  See AGENTS.md Section 7.4 for Frontmatter Contract." >&2

# Always exit 0 (warn-only hook)
exit 0
