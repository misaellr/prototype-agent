#!/usr/bin/env bash
# spec-scope-enforcement.sh - PreToolUse hook for Edit|Write scope enforcement
# Hook: Spec Scope Enforcement (Hook 3)
# Trigger: PreToolUse on Edit|Write
# Behavior: Block edits outside spec scope (exit 2), allow in-scope edits (exit 0)

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


# Normalize file path: strip leading ./ or /
normalize_path() {
    local path="$1"
    # Strip leading ./
    path="${path#./}"
    # Strip leading /
    path="${path#/}"
    # Resolve .. segments (basic resolution)
    # This handles common cases like "foo/../bar" -> "bar"
    while [[ "$path" =~ ([^/]+)/\.\.(/|$) ]]; do
        path="${path/${BASH_REMATCH[0]}/${BASH_REMATCH[2]}}"
    done
    # Clean up any double slashes
    path="${path//\/\//\/}"
    # Strip trailing slash
    path="${path%/}"
    echo "$path"
}

# Resolve symlinks if file exists (HIGH-01 fix)
# This prevents symlink attacks where tests/evil.test.ts -> ../AGENTS.md
resolve_symlinks() {
    local path="$1"
    if [[ -L "$path" ]] || [[ -e "$path" ]]; then
        # Use realpath if available (preferred - works on non-existent targets with -m)
        if command -v realpath &>/dev/null; then
            realpath -m "$path" 2>/dev/null || echo "$path"
        # Fallback to readlink -f (GNU) or readlink (BSD)
        elif command -v readlink &>/dev/null; then
            readlink -f "$path" 2>/dev/null || echo "$path"
        else
            echo "$path"
        fi
    else
        echo "$path"
    fi
}

# Compare paths with platform-appropriate case sensitivity
paths_match() {
    local path1="$1"
    local path2="$2"
    
    if [[ -n "$_PLATFORM_IS_DARWIN" ]]; then
        # macOS: case-insensitive comparison
        [[ "$(lowercase "$path1")" == "$(lowercase "$path2")" ]]
    else
        # Linux: case-sensitive comparison
        [[ "$path1" == "$path2" ]]
    fi
}

# Check if file is in always-allowed list
is_always_allowed() {
    local path="$1"
    
    # Workflow files
    # spec/work/*/log.md, spec/work/*/spec.md, spec/research/**/*
    if [[ "$path" =~ ^spec/work/[^/]+/log\.md$ ]] || \
       [[ "$path" =~ ^spec/work/[^/]+/spec\.md$ ]] || \
       [[ "$path" =~ ^spec/research/ ]]; then
        return 0
    fi
    
    # Test files
    # tests/**/*, **/*.test.*, **/*.spec.*, **/__tests__/**/*
    # **/test_*.py, **/*_test.go
    if [[ "$path" =~ ^tests/ ]] || \
       [[ "$path" =~ \.test\.[^/]+$ ]] || \
       [[ "$path" =~ \.spec\.[^/]+$ ]] || \
       [[ "$path" =~ /__tests__/ ]] || \
       [[ "$path" =~ /test_[^/]+\.py$ ]] || \
       [[ "$path" =~ ^test_[^/]+\.py$ ]] || \
       [[ "$path" =~ _test\.go$ ]]; then
        return 0
    fi
    
    # Package files (exact matches at any level)
    local filename
    filename=$(basename "$path")
    case "$filename" in
        package.json|package-lock.json|yarn.lock|pnpm-lock.yaml|\
        Cargo.lock|go.sum|requirements.txt|poetry.lock)
            return 0
            ;;
    esac
    
    # Config files (exact matches or patterns at any level)
    case "$filename" in
        tsconfig.json|jest.config.*|vitest.config.*)
            return 0
            ;;
    esac
    # Handle .eslintrc* and .prettierrc* patterns
    if [[ "$filename" =~ ^\.eslintrc ]] || [[ "$filename" =~ ^\.prettierrc ]]; then
        return 0
    fi
    
    return 1
}

# Find active work item (status: implement in log.md frontmatter)
find_active_work_item() {
    local work_dir="spec/work"
    
    if [[ ! -d "$work_dir" ]]; then
        return 1
    fi
    
    for log_file in "$work_dir"/*/log.md; do
        if [[ -f "$log_file" ]]; then
            # Check for status: implement in frontmatter
            if head -30 "$log_file" | grep -q '^status: implement'; then
                # Return the work item directory
                dirname "$log_file"
                return 0
            fi
        fi
    done
    
    return 1
}

# Parse "Files to Change" section from spec.md
# Returns list of file paths (one per line)
parse_spec_files() {
    local spec_file="$1"
    
    if [[ ! -r "$spec_file" ]]; then
        return 1
    fi
    
    # Extract files from "Files to Change" section
    # Look for:
    # - `path/to/file.ext` — description
    # Under ### Create or ### Modify subsections
    
    awk '
    BEGIN { in_files_section=0 }
    /^## Files to Change/ { in_files_section=1; next }
    /^## [^F]/ { if (in_files_section) exit }
    /^## Files / { next }
    in_files_section && /^- `[^`]+`/ {
        # Extract path from `path` format
        match($0, /`[^`]+`/)
        path = substr($0, RSTART+1, RLENGTH-2)
        print path
    }
    ' "$spec_file"
}

# Check if file is in spec's "Files to Change"
is_in_spec() {
    local target_path="$1"
    local spec_file="$2"
    
    local spec_files
    spec_files=$(parse_spec_files "$spec_file")
    
    if [[ -z "$spec_files" ]]; then
        return 1
    fi
    
    while IFS= read -r spec_path; do
        local normalized_spec_path
        normalized_spec_path=$(normalize_path "$spec_path")
        
        if paths_match "$target_path" "$normalized_spec_path"; then
            return 0
        fi
    done <<< "$spec_files"
    
    return 1
}

# Create override file for protected-paths coordination
create_override_file() {
    local file_path="$1"
    local file_hash
    file_hash=$(md5_hash "$file_path")
    local override_file="$SCRIPT_DIR/.scope-override-$file_hash"
    
    # Cleanup stale override files (>= 60 seconds old)
    for stale_file in "$SCRIPT_DIR"/.scope-override-*; do
        if [[ -f "$stale_file" ]]; then
            local age
            age=$(file_age_seconds "$stale_file")
            if [[ "$age" -ge 60 ]]; then
                rm -f "$stale_file" 2>/dev/null
            fi
        fi
    done
    
    # Create fresh override file
    touch "$override_file"
}

# Main logic
main() {
    # Normalize the target file path
    local normalized_path
    normalized_path=$(normalize_path "$FILE_PATH")

    # Resolve symlinks to prevent symlink attacks (HIGH-01 fix)
    # This ensures tests/evil.test.ts -> ../AGENTS.md is resolved to AGENTS.md
    local resolved_path
    resolved_path=$(resolve_symlinks "$normalized_path")
    # Normalize the resolved path (may have absolute path after resolution)
    resolved_path=$(normalize_path "$resolved_path")

    # Check always-allowed list using RESOLVED path (not original)
    if is_always_allowed "$resolved_path"; then
        exit 0
    fi
    
    # Find active work item
    local work_dir
    work_dir=$(find_active_work_item)
    
    if [[ -z "$work_dir" ]]; then
        # No active work item - allow the edit
        # This handles cases where no spec/work exists or no item is in implement status
        exit 0
    fi
    
    local spec_file="$work_dir/spec.md"
    
    if [[ ! -r "$spec_file" ]]; then
        # No spec.md found - allow the edit
        exit 0
    fi
    
    # Check if file is in spec's "Files to Change"
    if is_in_spec "$normalized_path" "$spec_file"; then
        # File is in spec - create override file and allow
        create_override_file "$normalized_path"
        echo "AUDIT: Allowing edit to '$normalized_path' (in spec Files to Change)" >&2
        exit 0
    fi
    
    # File not in spec and not always-allowed - block
    echo "BLOCKED: '$FILE_PATH' is not in the active spec's Files to Change" >&2
    echo "Active spec: $spec_file" >&2
    echo "Add the file to the spec or use an always-allowed path (tests/*, spec/work/*/log.md, etc.)" >&2
    exit 2
}

main
