# Spec: V6 Hooks Implementation

**Date**: 2026-02-02
**Status**: Approved
**Complexity**: 3
**Research**: `spec/research/R-005--v6-hooks-integration/requirements-v2.md`

## Context

Implement 4 Claude Code hooks to enforce V6 Spec-Driven Development guardrails that are currently documentation-only. These hooks provide automated validation of workflow compliance without blocking legitimate work.

## Complexity Assessment

| Dimension | Value | Score |
|-----------|-------|-------|
| Files touched | 6 (4 new + 2 modified) | 1 |
| Lines of code | ~300 | 1 |
| Dependencies added | 0 | 0 |
| External integrations | 0 | 0 |
| Behavior change | Yes (new warnings/blocks) | 1 |
| **Total** | | **3** |

## Files to Change

### Create

- `.claude/hooks/validation-format-check.sh` — Hook 2: Warn on missing validation evidence
- `.claude/hooks/spec-scope-enforcement.sh` — Hook 3: Block edits outside spec scope
- `.claude/hooks/self-review-gate.sh` — Hook 4: Block stop without self-review
- `.claude/hooks/frontmatter-prose-check.sh` — Hook 1: Warn on frontmatter/prose mismatch
- `.claude/hooks/lib/platform.sh` — Shared platform compatibility helpers

### Modify

- `.claude/hooks/protected-paths.sh` — Add state file exceptions and override support
- `.claude/settings.json` — Register new hooks with correct ordering

## Tasks

### T1: Create platform compatibility library

- File: `.claude/hooks/lib/platform.sh`
- Changes:
  - Create `md5_hash()` function (GNU vs BSD detection)
  - Create `date_to_epoch()` function (GNU vs BSD date parsing)
  - Create `lowercase()` function (bash 3.x compatible)
  - Create `file_age_seconds()` function
  - Create `file_mtime_epoch()` function for TTL checks:
    - Linux: `stat -c %Y "$file"`
    - macOS: `stat -f %m "$file"`
    - Detection: `[[ "$OSTYPE" == "darwin"* ]]`
- Validation: `bash -n .claude/hooks/lib/platform.sh && echo "Syntax OK"`

### T2: Modify protected-paths.sh for state file exceptions

- Depends on: T1
- File: `.claude/hooks/protected-paths.sh`
- Changes:
  - Add exception for `.claude/hooks/.self-review-*` files
  - Add exception for `.claude/hooks/.scope-override-*` files
  - Add override file check (if override exists and fresh, allow)
  - Source platform.sh for md5_hash and file_age_seconds
  - Override file TTL mechanism:
    - TTL: 60 seconds from file mtime
    - Check: `file_mtime_epoch()` from platform.sh
    - If file age >= 60 seconds: delete and continue to normal checks
    - If file age < 60 seconds: exit 0 (allow)
- Validation: `bash -n .claude/hooks/protected-paths.sh && echo "Syntax OK"`

### T3: Implement Hook 2 (Validation Format Check)

- Depends on: T1
- File: `.claude/hooks/validation-format-check.sh`
- Changes:
  - PostToolUse hook for Edit|Write on `spec/work/*/log.md`
  - Parse done tasks, check for validation YAML block
  - Verify: command, exit_code, timestamp, output_head OR output_tail
  - Verify: `**Result**: pass | fail` after closing code fence (required field)
  - Warn via stderr, always exit 0
- Validation: `bash -n .claude/hooks/validation-format-check.sh && echo "Syntax OK"`

### T4: Implement Hook 3 (Spec Scope Enforcement)

- Depends on: T1
- File: `.claude/hooks/spec-scope-enforcement.sh`
- Changes:
  - PreToolUse hook for Edit|Write
  - Check always-allowed list:
    - Workflow: `spec/work/*/log.md`, `spec/work/*/spec.md`, `spec/research/**/*`
    - Test: `tests/**/*`, `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**/*`, `**/test_*.py`, `**/*_test.go`
    - Package: `package.json`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Cargo.lock`, `go.sum`, `requirements.txt`, `poetry.lock`
    - Config: `tsconfig.json`, `.eslintrc*`, `.prettierrc*`, `jest.config.*`, `vitest.config.*`
  - Path normalization:
    - Strip leading `./` or `/`
    - Resolve `..` segments
    - Case-sensitive on Linux, case-insensitive on macOS (use platform.sh)
  - Find active spec via log.md frontmatter
  - Parse "Files to Change" section
  - Create override file for protected-paths coordination:
    - TTL: 60 seconds from file mtime
    - Cleanup: delete if file age >= 60 seconds
  - Block if file not in spec, allow otherwise
- Validation: `bash -n .claude/hooks/spec-scope-enforcement.sh && echo "Syntax OK"`

### T5: Implement Hook 4 (Self-Review Gate)

- Depends on: T1
- File: `.claude/hooks/self-review-gate.sh`
- Changes:
  - Stop hook (fires on session end)
  - Skip conditions (allow immediately with exit 0):
    - No active work item (status: implement)
    - Active work item has `tasks_completed: 0`
    - Active work item has `status: blocked`
    - Active work item `last_updated` > 24 hours ago (stale)
    - Bypass file exists: `.claude/hooks/bypass-self-review`
  - Find active work item (status: implement, not stale)
  - Check self-review completion (confidence, checklist, passed)
  - File-based loop prevention (3 attempts + 5 min timeout)
  - Graceful degradation on malformed files
- Validation: `bash -n .claude/hooks/self-review-gate.sh && echo "Syntax OK"`

### T6: Implement Hook 1 (Frontmatter/Prose Check)

- Depends on: T1
- File: `.claude/hooks/frontmatter-prose-check.sh`
- Changes:
  - PostToolUse hook for Edit|Write on `spec/work/*/log.md`
  - Skip conditions (exit 0 immediately):
    - No frontmatter present
    - `status` != `implement`
    - `tasks_completed: 0`
    - Mismatch of +1 (allow in-progress tolerance)
  - Parse frontmatter `tasks_completed`
  - Count prose task entries with `**Status**: done`
  - Support both `T1:` and `Task 1:` formats
  - Warn on mismatch (> 1 difference), always exit 0
- Validation: `bash -n .claude/hooks/frontmatter-prose-check.sh && echo "Syntax OK"`

### T7: Update settings.json with hook registrations

- File: `.claude/settings.json`
- Changes:
  - Add PreToolUse hooks in order: spec-scope-enforcement, then protected-paths
  - Add PostToolUse hooks: validation-format-check, frontmatter-prose-check
  - Add Stop hook: self-review-gate
  - Ensure correct matchers (Edit|Write, Bash for commit gate)
- Validation: `python3 -m json.tool .claude/settings.json > /dev/null && echo "Valid JSON"`

### T8: Integration testing

- Files: All hooks
- Changes: None (testing only)
- Validation:
  - Test Hook 2: Edit log.md with missing validation → expect warning
  - Test Hook 3: Edit file not in spec → expect block
  - Test Hook 4: Attempt stop with incomplete self-review → expect block
  - Test Hook 1: Edit log.md with mismatch → expect warning
- Validation: Manual verification of each scenario

## Validation

```bash
# Syntax check all hooks
for f in .claude/hooks/*.sh .claude/hooks/lib/*.sh; do
  bash -n "$f" && echo "$f: OK" || echo "$f: FAIL"
done

# JSON validation
python3 -m json.tool .claude/settings.json > /dev/null && echo "settings.json: OK"
```

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
- **Then** the edit is allowed with audit log to stderr

### AC-04: Hook 4 prevents infinite loops

- **Given** an incomplete self-review
- **When** agent attempts to stop 4+ times over 5+ minutes
- **Then** stop is allowed with warning

### AC-05: Hook 4 scopes to current work only

- **Given** W-001 (stale, 24h old) and W-002 (active)
- **When** agent stops with W-002 self-review complete
- **Then** stop is allowed (W-001 ignored as stale)

### AC-06: Platform compatibility

- **Given** macOS or Linux environment
- **When** any hook executes
- **Then** no platform-specific errors occur (md5, date, bash version)

### AC-07: Hook ordering is correct

- **Given** spec-scope-enforcement and protected-paths both configured
- **When** editing a spec-listed protected file
- **Then** spec-scope runs first, creates override, protected-paths respects it

## Adversarial Review

### Potential Failure Modes

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Hook silent failure (bad exit code) | Medium | High | All hooks log to stderr on error, explicit exit codes |
| Platform detection fails | Low | Medium | Fallback to POSIX-compatible commands where possible |
| Override file race condition | Low | Low | 60-second TTL is generous; cleanup on stale |
| Infinite loop in Stop hook | Medium | High | File-based counter with 3-attempt + 5-min timeout |
| Regex false positive/negative | Medium | Medium | Test both `T1:` and `Task 1:` formats explicitly |
| State file corruption | Low | Medium | Reset on parse error, fail open |

### Known Limitations

1. **Hook 1b (commit gate) deferred**: Pre-commit enforcement via Bash matcher is complex; warn-only is sufficient for v1
2. **No automated integration tests**: T8 requires manual verification
3. **BSD date edge cases**: Timestamps with timezone offsets may fail on macOS

## Notes

- AGENTS.md Section 8.3 already updated (AND → OR for output fields)
- Hook priority order: 2 → 3 → 4 → 1 (per requirements-v2.md)
- All hooks use warn-only or fail-open behavior to avoid blocking legitimate work
