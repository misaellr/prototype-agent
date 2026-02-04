#!/usr/bin/env bash
# validation-format-check.sh - PostToolUse hook for log.md validation format
# Hook: Validation Format Check (Hook 2)
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

# Find all done task sections
# Look for pattern: ### <date> - T<n>: ... or ### <date> - Task <n>: ...
# Followed by **Status**: done

# Use awk to extract done task blocks and check validation format
# A task block starts with ### and ends at the next ### or end of file

check_validation_format() {
    local task_name="$1"
    local task_content="$2"
    local warnings=""
    local has_validation_block=false
    local has_result=false
    local has_command=false
    local has_exit_code=false
    local has_timestamp=false
    local has_output=false
    
    # Check for **Validation**: followed by ```yaml block
    if echo "$task_content" | grep -q '\*\*Validation\*\*:'; then
        has_validation_block=true
        
        # Extract validation block content (between ```yaml and ```)
        local validation_block
        validation_block=$(echo "$task_content" | sed -n '/\*\*Validation\*\*:/,/^```$/p')
        
        # Check for required fields within the validation block
        if echo "$validation_block" | grep -qE '^command:'; then
            has_command=true
        fi
        if echo "$validation_block" | grep -qE '^exit_code:'; then
            has_exit_code=true
        fi
        if echo "$validation_block" | grep -qE '^timestamp:'; then
            has_timestamp=true
        fi
        # Check for output_head OR output_tail (either is acceptable)
        if echo "$validation_block" | grep -qE '^output_head:|^output_tail:'; then
            has_output=true
        fi
    fi
    
    # Check for **Result**: pass or **Result**: fail after the validation block
    if echo "$task_content" | grep -qE '\*\*Result\*\*:\s*(pass|fail)'; then
        has_result=true
    fi
    
    # Generate warnings for missing elements
    if [[ "$has_validation_block" != "true" ]]; then
        warnings="$warnings\n  - Missing **Validation**: yaml block"
    else
        if [[ "$has_command" != "true" ]]; then
            warnings="$warnings\n  - Missing 'command:' field in validation block"
        fi
        if [[ "$has_exit_code" != "true" ]]; then
            warnings="$warnings\n  - Missing 'exit_code:' field in validation block"
        fi
        if [[ "$has_timestamp" != "true" ]]; then
            warnings="$warnings\n  - Missing 'timestamp:' field in validation block"
        fi
        if [[ "$has_output" != "true" ]]; then
            warnings="$warnings\n  - Missing 'output_head:' or 'output_tail:' field in validation block"
        fi
    fi
    
    if [[ "$has_result" != "true" ]]; then
        warnings="$warnings\n  - Missing '**Result**: pass | fail' after validation block"
    fi
    
    if [[ -n "$warnings" ]]; then
        echo "$task_name:$warnings"
    fi
}

# Extract done task blocks using awk
# Parse task sections: look for ### <content> with **Status**: done
done_tasks=$(awk '
BEGIN { in_task=0; task_name=""; task_content="" }
/^### [0-9]{4}-[0-9]{2}-[0-9]{2}.*- (T[0-9]+:|Task [0-9]+:)/ {
    # If we were in a task, output it
    if (in_task && task_content ~ /\*\*Status\*\*: *done/) {
        print "TASK_START:" task_name
        print task_content
        print "TASK_END"
    }
    # Start new task
    in_task=1
    task_name=$0
    task_content=""
    next
}
/^---$/ {
    # Section divider - end of task
    if (in_task && task_content ~ /\*\*Status\*\*: *done/) {
        print "TASK_START:" task_name
        print task_content
        print "TASK_END"
    }
    in_task=0
    task_name=""
    task_content=""
    next
}
/^## / {
    # New major section - end of task
    if (in_task && task_content ~ /\*\*Status\*\*: *done/) {
        print "TASK_START:" task_name
        print task_content
        print "TASK_END"
    }
    in_task=0
    task_name=""
    task_content=""
    next
}
in_task {
    task_content = task_content "\n" $0
}
END {
    # Handle last task if any
    if (in_task && task_content ~ /\*\*Status\*\*: *done/) {
        print "TASK_START:" task_name
        print task_content
        print "TASK_END"
    }
}
' "$FILE_PATH")

# Process each done task and collect warnings
all_warnings=""
current_task=""
current_content=""
in_task_block=false

while IFS= read -r line; do
    if [[ "$line" =~ ^TASK_START: ]]; then
        current_task="${line#TASK_START:}"
        current_content=""
        in_task_block=true
    elif [[ "$line" == "TASK_END" ]]; then
        if [[ -n "$current_task" ]]; then
            task_warnings=$(check_validation_format "$current_task" "$current_content")
            if [[ -n "$task_warnings" ]]; then
                all_warnings="$all_warnings$task_warnings\n"
            fi
        fi
        in_task_block=false
        current_task=""
        current_content=""
    elif [[ "$in_task_block" == "true" ]]; then
        current_content="$current_content$line"$'\n'
    fi
done <<< "$done_tasks"

# Output warnings to stderr if any were found
if [[ -n "$all_warnings" ]]; then
    echo "WARNING: Validation format issues in $FILE_PATH" >&2
    echo -e "$all_warnings" >&2
    echo "See AGENTS.md Section 8.3 for required validation format." >&2
fi

# Always exit 0 (warn-only hook)
exit 0
