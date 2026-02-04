#!/usr/bin/env bash
# Hook 4: Self-Review Gate
# Type: Stop hook (fires on session end)
# Purpose: Ensure self-review is completed before session ends
#
# Exit codes:
#   0 - Allow stop
#   2 - Block stop (self-review incomplete)

set -euo pipefail

# Source platform compatibility library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/platform.sh"

# Constants
ATTEMPTS_FILE="${SCRIPT_DIR}/.self-review-attempts"
BYPASS_FILE="${SCRIPT_DIR}/bypass-self-review"
MAX_ATTEMPTS=3
TIMEOUT_SECONDS=300  # 5 minutes
STALE_SECONDS=86400  # 24 hours

# Log message to stderr
log() {
    echo "[self-review-gate] $*" >&2
}

# Find active work item with status: implement
# Returns path to log.md or empty string
find_active_work_item() {
    local work_dir="${SCRIPT_DIR}/../../spec/work"
    
    if [[ ! -d "$work_dir" ]]; then
        echo ""
        return
    fi
    
    for log_file in "$work_dir"/*/log.md; do
        [[ -f "$log_file" ]] || continue
        
        # Extract frontmatter
        local in_frontmatter=""
        local status=""
        local last_updated=""
        
        while IFS= read -r line; do
            if [[ "$line" == "---" ]]; then
                if [[ -z "$in_frontmatter" ]]; then
                    in_frontmatter="true"
                else
                    break
                fi
                continue
            fi
            
            if [[ -n "$in_frontmatter" ]]; then
                if [[ "$line" =~ ^status:\ *(.+)$ ]]; then
                    status="${BASH_REMATCH[1]}"
                elif [[ "$line" =~ ^last_updated:\ *(.+)$ ]]; then
                    last_updated="${BASH_REMATCH[1]}"
                fi
            fi
        done < "$log_file"
        
        # Check if this is an active implementation work item
        if [[ "$status" == "implement" ]]; then
            # Check if stale (> 24 hours)
            if [[ -n "$last_updated" ]]; then
                local updated_epoch
                updated_epoch=$(date_to_epoch "$last_updated")
                local now_epoch
                now_epoch=$(date +%s)
                local age=$((now_epoch - updated_epoch))
                
                if [[ "$age" -ge "$STALE_SECONDS" ]]; then
                    log "Skipping stale work item: $(dirname "$log_file") (${age}s old > ${STALE_SECONDS}s)"
                    continue
                fi
            fi
            
            echo "$log_file"
            return
        fi
    done
    
    echo ""
}

# Get frontmatter field value
get_frontmatter_field() {
    local log_file="$1"
    local field="$2"
    
    local in_frontmatter=""
    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            if [[ -z "$in_frontmatter" ]]; then
                in_frontmatter="true"
            else
                break
            fi
            continue
        fi
        
        if [[ -n "$in_frontmatter" ]]; then
            if [[ "$line" =~ ^${field}:\ *(.+)$ ]]; then
                echo "${BASH_REMATCH[1]}"
                return
            fi
        fi
    done < "$log_file"
    
    echo ""
}

# Check if self-review is complete
# Returns "true" if complete, "false" otherwise
# Requires: Overall Confidence filled in AND Self-Review Passed: Yes
check_self_review_complete() {
    local log_file="$1"

    local has_confidence=""
    local has_passed=""

    while IFS= read -r line; do
        # Check for filled-in confidence (not just template)
        if [[ "$line" =~ ^\*\*Overall\ Confidence\*\*:\ *(High|Medium|Low)$ ]]; then
            has_confidence="true"
        fi

        # Check for Self-Review Passed: Yes
        if [[ "$line" =~ ^\*\*Self-Review\ Passed\*\*:\ *Yes ]]; then
            has_passed="true"
        fi
    done < "$log_file"

    if [[ -n "$has_confidence" && -n "$has_passed" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Check and update loop prevention state
# Returns "true" if should allow stop, "false" if should block
check_loop_prevention() {
    local now_epoch
    now_epoch=$(date +%s)
    
    # Check if attempts file exists and read state
    if [[ -f "$ATTEMPTS_FILE" ]]; then
        local first_attempt=""
        local attempt_count=""
        
        # Read attempts file (format: first_epoch:count)
        local content
        content=$(cat "$ATTEMPTS_FILE" 2>/dev/null) || content=""
        
        if [[ "$content" =~ ^([0-9]+):([0-9]+)$ ]]; then
            first_attempt="${BASH_REMATCH[1]}"
            attempt_count="${BASH_REMATCH[2]}"
        else
            # Malformed file, reset
            first_attempt="$now_epoch"
            attempt_count="0"
        fi
        
        local elapsed=$((now_epoch - first_attempt))
        
        # Check if timeout exceeded (5 minutes)
        if [[ "$elapsed" -ge "$TIMEOUT_SECONDS" ]]; then
            log "Timeout exceeded (${elapsed}s >= ${TIMEOUT_SECONDS}s), allowing stop"
            rm -f "$ATTEMPTS_FILE"
            echo "true"
            return
        fi
        
        # Check if max attempts exceeded
        if [[ "$attempt_count" -ge "$MAX_ATTEMPTS" ]]; then
            log "Max attempts exceeded ($attempt_count >= $MAX_ATTEMPTS), allowing stop"
            rm -f "$ATTEMPTS_FILE"
            echo "true"
            return
        fi
        
        # Increment attempt count
        attempt_count=$((attempt_count + 1))
        echo "${first_attempt}:${attempt_count}" > "$ATTEMPTS_FILE"
        log "Self-review incomplete (attempt $attempt_count of $MAX_ATTEMPTS)"
        echo "false"
        return
    else
        # First attempt, create state file
        echo "${now_epoch}:1" > "$ATTEMPTS_FILE"
        log "Self-review incomplete (attempt 1 of $MAX_ATTEMPTS)"
        echo "false"
        return
    fi
}

# Main execution
main() {
    # Check bypass file first
    if [[ -f "$BYPASS_FILE" ]]; then
        log "Bypass file exists, allowing stop"
        exit 0
    fi
    
    # Find active work item
    local log_file
    log_file=$(find_active_work_item)
    
    if [[ -z "$log_file" ]]; then
        log "No active work item found, allowing stop"
        rm -f "$ATTEMPTS_FILE"  # Clean up state
        exit 0
    fi
    
    # Get work item status and tasks_completed
    local status
    status=$(get_frontmatter_field "$log_file" "status")
    
    local tasks_completed
    tasks_completed=$(get_frontmatter_field "$log_file" "tasks_completed")
    
    # Skip conditions
    if [[ "$status" == "blocked" ]]; then
        log "Work item is blocked, allowing stop"
        rm -f "$ATTEMPTS_FILE"
        exit 0
    fi
    
    if [[ "$tasks_completed" == "0" ]]; then
        log "No tasks completed yet, allowing stop"
        rm -f "$ATTEMPTS_FILE"
        exit 0
    fi
    
    # Check if self-review is complete
    local is_complete
    is_complete=$(check_self_review_complete "$log_file")
    
    if [[ "$is_complete" == "true" ]]; then
        log "Self-review is complete, allowing stop"
        rm -f "$ATTEMPTS_FILE"
        exit 0
    fi
    
    # Self-review is incomplete, check loop prevention
    local allow_stop
    allow_stop=$(check_loop_prevention)
    
    if [[ "$allow_stop" == "true" ]]; then
        log "WARNING: Self-review incomplete but limit reached, allowing stop"
        exit 0
    else
        log "Please complete the Self-Review Checkpoint in log.md before stopping"
        log "Required: Confidence rating, checklist items, and Self-Review Passed: Yes"
        exit 2
    fi
}

main "$@"
