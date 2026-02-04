#!/usr/bin/env bash
# Platform compatibility library for Claude Code hooks
# Provides cross-platform functions for macOS (BSD) and Linux (GNU)
# Compatible with bash 3.x and later

# Detect platform once
_PLATFORM_IS_DARWIN=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    _PLATFORM_IS_DARWIN="true"
fi

# md5_hash - Generate MD5 hash of input string
# Usage: md5_hash "string to hash"
# Returns: 32-character hex MD5 hash
md5_hash() {
    local input="$1"
    if [[ -n "$_PLATFORM_IS_DARWIN" ]]; then
        # macOS: use md5 command
        echo -n "$input" | md5 -q
    else
        # Linux: use md5sum command
        echo -n "$input" | md5sum | cut -d' ' -f1
    fi
}

# date_to_epoch - Convert ISO 8601 date string to Unix epoch
# Usage: date_to_epoch "2026-02-01T12:00:00Z"
# Returns: Unix timestamp (seconds since epoch)
# Note: Expects ISO 8601 format with Z suffix
date_to_epoch() {
    local date_str="$1"
    if [[ -n "$_PLATFORM_IS_DARWIN" ]]; then
        # macOS: use date -j with format string
        # Strip the 'Z' suffix and parse
        local clean_date="${date_str%Z}"
        date -j -f "%Y-%m-%dT%H:%M:%S" "$clean_date" +%s 2>/dev/null || echo "0"
    else
        # Linux: use date -d which handles ISO 8601 natively
        date -d "$date_str" +%s 2>/dev/null || echo "0"
    fi
}

# lowercase - Convert string to lowercase (bash 3.x compatible)
# Usage: lowercase "MIXED Case String"
# Returns: lowercase string
lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# file_mtime_epoch - Get file modification time as Unix epoch
# Usage: file_mtime_epoch "/path/to/file"
# Returns: Unix timestamp of last modification
file_mtime_epoch() {
    local file="$1"
    if [[ ! -e "$file" ]]; then
        echo "0"
        return 1
    fi
    if [[ -n "$_PLATFORM_IS_DARWIN" ]]; then
        # macOS: stat -f %m
        stat -f %m "$file" 2>/dev/null || echo "0"
    else
        # Linux: stat -c %Y
        stat -c %Y "$file" 2>/dev/null || echo "0"
    fi
}

# file_age_seconds - Get file age in seconds
# Usage: file_age_seconds "/path/to/file"
# Returns: Number of seconds since file was last modified
file_age_seconds() {
    local file="$1"
    local mtime
    local now
    
    mtime=$(file_mtime_epoch "$file")
    if [[ "$mtime" == "0" ]]; then
        echo "0"
        return 1
    fi
    
    now=$(date +%s)
    echo $((now - mtime))
}
