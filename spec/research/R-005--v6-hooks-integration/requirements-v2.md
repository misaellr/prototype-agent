# Revised Requirements: V6 Hooks Integration (v2)

**Date**: 2026-02-01
**Status**: Draft
**Previous Version**: research.md (v1)
**Changes**: Addresses all P0 issues from adversarial validation

---

## Summary of P0 Fixes

| Hook | P0 Issue | Resolution |
|------|----------|------------|
| 1 | PostToolUse deadlock | Change to **warn-only** (not blocking) + commit-time enforcement |
| 2 | Format ambiguity | Define canonical format with code fence |
| 2 | output_head/tail conflict | Require at least one, update AGENTS.md |
| 3 | Protected-paths conflict | **Spec overrides protected-paths** with audit trail |
| 3 | Test files blocked | Add test patterns to always-allowed |
| 4 | Env var loop prevention | Use **file-based state** with timeout |

---

## Hook 1: Frontmatter/Prose Consistency (REVISED)

### Problem Addressed
PostToolUse timing creates deadlock: agent updates frontmatter first (per V6 rules), hook runs, fails because prose hasn't been updated yet, blocks the edit.

### Revised Approach: Warn-Only + Commit Gate

**Change 1**: Hook becomes **warning-only** (exit 0, stderr message)
- Allows incremental edits during implementation
- Warns agent if mismatch detected
- Does not block work

**Change 2**: Add **pre-commit hook** for enforcement
- Runs `git commit` time, not edit time
- Blocks commit if mismatch exists
- Agent must fix before committing

### Revised Requirements

```yaml
Hook 1: frontmatter-prose-check
  Event: PostToolUse
  Matcher: Edit|Write
  Type: command
  Behavior: WARN (exit 0 with stderr)

  Trigger Conditions:
    - File matches: spec/work/*/log.md
    - Frontmatter status: implement
    - tasks_completed > 0

  Check Logic:
    1. Parse frontmatter tasks_completed (integer)
    2. Count prose task entries with "**Status**: done"
    3. If mismatch: warn via stderr
    4. Always exit 0 (allow edit)

  Task Counting Rules:
    - Pattern: ^### .* — (T|Task )([0-9]+)(-T?([0-9]+))?:
    - Single task (T1:): count as 1
    - Range (T6-T8:): count as (end - start + 1)
    - Comma list (T1, T2:): count items
    - Only count if followed by "**Status**: done" within same block

  Edge Cases:
    - No frontmatter: skip (exit 0)
    - status != implement: skip
    - tasks_completed: 0: skip
    - Mismatch of +1: allow (in-progress update)
```

### Pre-Commit Enforcement (Separate Hook)

```yaml
Hook 1b: frontmatter-prose-commit-gate
  Event: PreToolUse
  Matcher: Bash
  Type: command
  Behavior: BLOCK if git commit with mismatch

  Trigger Conditions:
    - Command matches: git commit
    - Active work item exists with status: implement

  Check Logic:
    1. Find active log.md
    2. Verify frontmatter matches prose count
    3. If mismatch: exit 2 with clear message
    4. If match: exit 0
```

---

## Hook 2: Validation Format Enforcement (REVISED)

### Problems Addressed
1. Format ambiguity between YAML in code fence vs inline markdown
2. Conflict between "AND" (AGENTS.md) and "OR" (research) for output fields

### Revised Approach: Canonical Format + AGENTS.md Update

**Change 1**: Define ONE canonical format

```markdown
**Validation**:
```yaml
command: "<exact command>"
exit_code: <integer>
timestamp: <ISO8601>
output_head: |
  <first 10-20 lines>
```
```

**Change 2**: Require `output_head` OR `output_tail` (at least one)
- Update AGENTS.md Section 8.3 to match
- Rationale: Small outputs don't need both

**Change 3**: Add `**Result**: pass | fail` as required field after validation block

### Revised Requirements

```yaml
Hook 2: validation-format-check
  Event: PostToolUse
  Matcher: Edit|Write
  Type: command
  Behavior: WARN (exit 0 with stderr)

  Trigger Conditions:
    - File matches: spec/work/*/log.md
    - Contains "**Status**: done" for any task

  Required Fields (per done task):
    - command: non-empty string
    - exit_code: integer (0-255)
    - timestamp: ISO8601 pattern YYYY-MM-DDTHH:MM:SS
    - output_head OR output_tail: at least one present
    - **Result**: pass | fail (after closing code fence)

  Validation Patterns:
    - command: ^command:\s*["']?.+["']?$
    - exit_code: ^exit_code:\s*[0-9]+$
    - timestamp: ^timestamp:\s*[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}
    - output: ^output_(head|tail):\s*\|?

  Parsing Approach:
    - Do NOT use regex for code fence boundaries
    - Use line-by-line parsing that respects YAML literal blocks
    - Validation blocks start after "**Validation**:" line
    - End at closing ``` fence (count opening/closing pairs)
    - Or: Require validation blocks use simple format (no nested fences in output)

  Edge Cases:
    - Task in progress (no Status: done): skip
    - Research/Specify phase: skip
    - Blocked task: skip
    - Multiple validation blocks: validate each
```

### Required AGENTS.md Update

```markdown
# Section 8.3 - Change from:
"Output head AND tail (catches hidden failures)"

# To:
"Output head OR tail (at least one required; include both for long outputs)"
```

---

## Hook 3: Spec Scope Enforcement (REVISED)

### Problems Addressed
1. Conflict with protected-paths.sh (AGENTS.md is protected but may be in spec)
2. Test files blocked (breaks TDD workflow)

### Revised Approach: Spec Overrides + Extended Allowlist

**Change 1**: Spec-listed files override protected-paths
- If file is in spec.md "Files to Change", it's allowed
- Add audit trail: log override to stderr
- Protected-paths still blocks files NOT in spec

**Change 2**: Extend always-allowed list

```yaml
Always Allowed (no spec needed):
  # Workflow files
  - spec/work/*/log.md
  - spec/work/*/spec.md
  - spec/research/**/*

  # Test files (NEW)
  - tests/**/*
  - **/*.test.*
  - **/*.spec.*
  - **/__tests__/**/*
  - **/test_*.py
  - **/*_test.go

  # Package management (NEW)
  - package.json
  - package-lock.json
  - yarn.lock
  - pnpm-lock.yaml
  - Cargo.lock
  - go.sum
  - requirements.txt
  - poetry.lock

  # Config files (NEW)
  - tsconfig.json
  - .eslintrc*
  - .prettierrc*
  - jest.config.*
  - vitest.config.*
```

### Revised Requirements

```yaml
Hook 3: spec-scope-enforcement
  Event: PreToolUse
  Matcher: Edit|Write
  Type: command
  Behavior: BLOCK (exit 2) or ALLOW (exit 0)

  Decision Logic (in order):
    1. If file in always-allowed list: ALLOW
    2. If no active spec (research phase): ALLOW
    3. If file in spec "Files to Change": ALLOW (log override if protected)
    4. Otherwise: BLOCK

  Active Spec Detection:
    - Find spec/work/*/log.md with frontmatter status: implement
    - Use most recent by last_updated
    - If none found: no active spec (allow all)

  Path Normalization:
    - Strip leading ./ or /
    - Resolve .. segments
    - Compare case-sensitively on Linux, case-insensitively on macOS
    - Match against both exact path and basename

  Override Logging:
    - When allowing protected file due to spec listing:
    - Log to stderr: "OVERRIDE: <file> allowed (in spec, normally protected)"
    - This creates audit trail without blocking
```

### Hook Coordination

```yaml
Hook Order (settings.json):
  PreToolUse:
    1. spec-scope-enforcement  # Runs first, may override
    2. protected-paths         # Runs second, respects overrides

  Implementation:
    - spec-scope creates .claude/hooks/.scope-override-<hash> file
    - protected-paths checks for override file before blocking
    - Override file auto-expires after 60 seconds

Hook 3 Prerequisite: Modify protected-paths.sh
  Task: Add override file check before pattern matching

  Changes:
    1. At top of script (after FILE_PATH assignment), check for override file
    2. Hash: MD5 of file path (echo -n "$FILE_PATH" | md5sum | cut -d' ' -f1)
    3. Override file: .claude/hooks/.scope-override-<hash>
    4. If override exists and < 60 seconds old: exit 0 (allow)
    5. If override exists and >= 60 seconds: delete it, continue to normal checks

  Platform Note:
    - Linux: md5sum
    - macOS: md5 -q
    - Detection: command -v md5sum >/dev/null && ... || md5 -q
```

---

## Hook 4: Self-Review Gate (REVISED)

### Problem Addressed
Environment variable for infinite loop prevention doesn't persist between tool calls.

### Revised Approach: File-Based State with Timeout

**Change 1**: Use file-based loop prevention

```yaml
State File: .claude/hooks/.self-review-check-<work_id>
Contents:
  check_count: <integer>
  first_check: <ISO8601>
  last_check: <ISO8601>

Behavior:
  - First check: create file, check_count=1
  - Subsequent checks: increment check_count
  - If check_count > 3 AND elapsed > 5 minutes: allow with warning
  - If self-review complete: delete file
```

**Change 2**: Scope to current work item only
- Only check the single most recent work item with status: implement
- Ignore stale items (last_updated > 24 hours ago)

**Change 3**: Add graceful degradation
- If log.md is malformed: warn and allow (fail open)
- If state file is corrupted: reset and continue

### Revised Requirements

```yaml
Hook 4: self-review-gate
  Event: Stop
  Matcher: (none - fires on all stops)
  Type: command
  Behavior: BLOCK (exit 2) or ALLOW (exit 0)

  Skip Conditions (allow immediately):
    - No active work item (status: implement)
    - Active work item has tasks_completed: 0
    - Active work item has status: blocked
    - Active work item last_updated > 24 hours ago
    - Bypass file exists: .claude/hooks/bypass-self-review

  Loop Prevention:
    - State file: .claude/hooks/.self-review-state
    - Track: check_count, first_check_time
    - If check_count > 3 AND elapsed > 5 minutes:
      - Allow with WARNING: "Self-review incomplete but allowing stop after 3 attempts"
      - Reset state file

  Self-Review Completeness Check:
    Required sections (all must be non-template):

    1. Confidence Assessment:
       - Pattern: ^\*\*Overall Confidence\*\*:\s*(High|Medium|Low)\s*$
       - NOT: High | Medium | Low (template)

    2. Self-Review Checklist:
       - Count: [x] checkboxes
       - Minimum: 4 of 5 checked

    3. Self-Review Passed:
       - Pattern: ^\*\*Self-Review Passed\*\*:\s*(Yes|No)\s*$
       - NOT: Yes / No (template)

  Pattern Matching Rules:
    - Case-insensitive for Yes/No/High/Medium/Low
    - Flexible whitespace: \s* between elements
    - Accept common variations: YES, yes, Yes

  Blocking Message:
    "Self-Review Checkpoint incomplete. Please complete:
     - Overall Confidence (currently: <value or 'template'>)
     - Checklist (<n>/5 checked)
     - Self-Review Passed (currently: <value or 'template'>)

     To bypass: touch .claude/hooks/bypass-self-review"

Hook 4 Prerequisite: Modify protected-paths.sh
  Task: Add exception for self-review and scope-override state files

  Add to top of protected-paths.sh (after FILE_PATH assignment):
    # Allow hook state files (self-review, scope-override)
    if [[ "$FILE_PATH" =~ \.claude/hooks/\.(self-review|scope-override) ]]; then
        exit 0
    fi

  Rationale: These state files must be writable by hooks themselves
```

### State File Format

```yaml
# .claude/hooks/.self-review-state
work_id: W-008
check_count: 2
first_check: 2026-02-01T10:30:00Z
last_check: 2026-02-01T10:35:00Z
```

---

## Platform Compatibility

```yaml
GNU grep required:
  Flags used: -E, -o, -A, -c
  macOS users: brew install grep (use ggrep)
  Or: Use POSIX alternatives (awk for extraction)
  Recommended: Use awk for field extraction instead of grep -o

Date parsing:
  Linux: date -d "$timestamp" +%s
  macOS: date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" +%s
  Detection: [[ "$OSTYPE" == "darwin"* ]]
  Recommended: Create platform_date_to_epoch() helper function

MD5 hashing:
  Linux: echo -n "$path" | md5sum | cut -d' ' -f1
  macOS: echo -n "$path" | md5 -q
  Detection: command -v md5sum >/dev/null

Bash version:
  Required: 4.0+ for ${var,,} lowercase conversion
  macOS default: 3.2 (upgrade with brew install bash)
  Workaround: tr '[:upper:]' '[:lower:]' for case conversion
```

---

## Implementation Priority

Based on revised complexity and value:

| Priority | Hook | Complexity | Value | Notes |
|----------|------|------------|-------|-------|
| 1 | Hook 2 (Validation Format) | Low | High | Simplest, high impact |
| 2 | Hook 3 (Scope Enforcement) | Medium | High | Requires hook coordination |
| 3 | Hook 4 (Self-Review Gate) | Medium | High | State management adds complexity |
| 4 | Hook 1 (Frontmatter/Prose) | Medium | Medium | Warn-only reduces urgency |

---

## Files to Update

1. **AGENTS.md Section 8.3**: Change output_head/tail from AND to OR
2. **AGENTS.md Section 13**: Document new hooks and override behavior
3. **.claude/settings.json**: Add new hook configurations
4. **.claude/hooks/**: Create new hook scripts
5. **spec/templates/log-template.md**: Clarify exact format requirements

---

## Open Questions (Resolved)

| Question | Resolution |
|----------|------------|
| Acceptable latency for Stop hooks? | 30s max, with timeout fallback |
| Escape hatch for urgent fixes? | Yes, bypass file + 3-attempt timeout |
| Apply to all complexity levels? | Yes, but warn-only for complexity 0-2 |
| How to detect current phase? | Frontmatter status field |

---

## Acceptance Criteria

### AC-01: Hook 2 validates format correctly
- **Given** a log.md with a done task missing validation block
- **When** the file is edited
- **Then** stderr contains warning about missing validation

### AC-02: Hook 3 allows test files
- **Given** a spec that doesn't list test files
- **When** agent creates `tests/feature.test.ts`
- **Then** the edit is allowed (test files always-allowed)

### AC-03: Hook 3 allows spec-listed protected files
- **Given** a spec that lists AGENTS.md in Files to Change
- **When** agent edits AGENTS.md
- **Then** the edit is allowed with audit log

### AC-04: Hook 4 prevents infinite loops
- **Given** an incomplete self-review
- **When** agent attempts to stop 4+ times over 5+ minutes
- **Then** stop is allowed with warning

### AC-05: Hook 4 scopes to current work only
- **Given** W-001 (stale, 48h old) and W-002 (active)
- **When** agent stops with W-002 self-review complete
- **Then** stop is allowed (W-001 ignored)
