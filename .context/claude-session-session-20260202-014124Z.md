---
cli: claude
agent: claude-code
model: claude-opus-4-5-20251101
session-id: session-20260202-014124Z
---

# Session: V6 Hooks Integration Research (Comprehensive Handoff)
**Date**: 2026-02-02
**Duration**: ~2 hours

---

## Executive Summary

Conducted multi-layer research and validation on integrating Claude Code hooks into V6 Spec-Driven Development framework. **Status: Research complete, 4 blocking issues remain before specification.**

---

## Current State Snapshot

### Files Created This Session

| File | Purpose | Status |
|------|---------|--------|
| `spec/research/R-005--v6-hooks-integration/brief.md` | Research goal and scope | Complete |
| `spec/research/R-005--v6-hooks-integration/research.md` | Initial findings (v1) | Superseded by requirements-v2 |
| `spec/research/R-005--v6-hooks-integration/log.md` | Full session log | Complete |
| `spec/research/R-005--v6-hooks-integration/requirements-v2.md` | **Revised requirements** | Needs updates for deep validation findings |

### Key Decisions Made

1. **Keep Section 7 duplication** - Sync notices already in place, provides quick-reference value
2. **Option B (Moderate - Mechanical Checks)** - 4 specific hooks, not all 11 gaps
3. **Warn-only for Hook 1** - Avoids PostToolUse deadlock
4. **Spec overrides protected-paths** - With audit trail
5. **File-based state for Hook 4** - Not environment variables

### What Is Pending

- [ ] Update requirements-v2.md with deep validation fixes
- [ ] Update AGENTS.md Section 8.3 (AND → OR for output fields)
- [ ] Create W-008 specification
- [ ] Implement hooks

---

## Research Findings: Exhaustive Detail

### 11 V6 Gaps Identified (5 High Priority)

| # | Gap | Priority | Current Enforcement | Proposed Hook |
|---|-----|----------|---------------------|---------------|
| 1 | Validation evidence logging | HIGH | Documented only | Hook 2 |
| 2 | Frontmatter state updates | HIGH | Documented only | Hook 1 |
| 3 | Frontmatter/prose consistency | HIGH | Agent compliance | Hook 1 |
| 4 | Self-Review Checkpoint | HIGH | Documented only | Hook 4 |
| 5 | Validation must pass before done | HIGH | Documented only | Hook 2 |
| 6 | Spec approval before implementation | MEDIUM | Documented only | Hook 3 |
| 7 | Research AC completion | MEDIUM | Agent compliance | (deferred) |
| 8 | Complexity check before work | MEDIUM | Documented only | (deferred) |
| 9 | Git commit between tasks | MEDIUM | Documented only | Hook 1b |
| 10 | Uncertainty marker handling | MEDIUM | Documented only | (deferred) |
| 11 | Intent section for complexity 4-5 | LOW | Documented only | (deferred) |

### The 4 Priority Hooks

#### Hook 1: Frontmatter/Prose Consistency Check

**Purpose**: Verify `tasks_completed` in frontmatter matches count of done tasks in prose.

**Requirements-v2 Approach**:
- Event: PostToolUse, Matcher: Edit|Write
- Behavior: WARN only (exit 0 with stderr)
- Plus Hook 1b: PreToolUse on Bash, blocks `git commit` if mismatch

**Regex Pattern** (from requirements-v2 line 61):
```
^### .* — T([0-9]+)(-T?([0-9]+))?:
```

**Deep Validation Finding - BLOCKER**:
- Template uses `Task 1:` format (log-template.md line 74)
- Real logs use `T1:` format (W-007)
- Regex only matches `T1:`, NOT `Task 1:`
- **Fix**: Change regex to `^### .* — (T|Task )([0-9]+)(-T?([0-9]+))?:`

**Additional Issues**:
- GNU grep `-o` flag not available in BSD grep (macOS)
- `$TOOL_INPUT` format for PostToolUse not verified empirically

---

#### Hook 2: Validation Format Enforcement

**Purpose**: Ensure log.md task entries include proper YAML validation evidence.

**Canonical Format** (from requirements-v2 lines 106-115):
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

**Validation Patterns** (lines 144-147):
```
command:    ^command:\s*["']?.+["']?$
exit_code:  ^exit_code:\s*[0-9]+$
timestamp:  ^timestamp:\s*[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}
output:     ^output_(head|tail):\s*\|?
```

**Deep Validation Findings - 2 BLOCKERS**:

1. **Nested code fences break parsing**:
   - If `output_head` contains markdown with code fences, regex fence detection fails
   - **Fix**: Use line-by-line YAML-aware parsing, not regex fence matching

2. **AGENTS.md still says "AND"**:
   - AGENTS.md Section 8.3 line 618: "Output head AND tail"
   - Requirements-v2: "output_head OR output_tail"
   - **Fix**: Update AGENTS.md FIRST before implementing hook

**Additional Issues**:
- Exit code pattern accepts 256+ (invalid POSIX)
- Exit code pattern rejects negatives (signals return -1)
- Task boundary detection underspecified

---

#### Hook 3: Spec Scope Enforcement

**Purpose**: Block edits to files not listed in spec.md "Files to Change" section.

**Decision Logic** (from requirements-v2 lines 225-229):
```
1. If file in always-allowed list: ALLOW
2. If no active spec (research phase): ALLOW
3. If file in spec "Files to Change": ALLOW (log override if protected)
4. Otherwise: BLOCK
```

**Always-Allowed List** (lines 183-214):
```yaml
# Workflow files
- spec/work/*/log.md
- spec/work/*/spec.md
- spec/research/**/*

# Test files
- tests/**/*
- **/*.test.*
- **/*.spec.*
- **/__tests__/**/*
- **/test_*.py
- **/*_test.go

# Package management
- package.json, package-lock.json, yarn.lock, pnpm-lock.yaml
- Cargo.lock, go.sum, requirements.txt, poetry.lock

# Config files
- tsconfig.json, .eslintrc*, .prettierrc*, jest.config.*, vitest.config.*
```

**Hook Coordination** (lines 250-260):
```yaml
Implementation:
  - spec-scope creates .claude/hooks/.scope-override-<hash> file
  - protected-paths checks for override file before blocking
  - Override file auto-expires after 60 seconds
```

**Deep Validation Finding - REQUIRES CLARIFICATION**:
- Requirements imply modifying `protected-paths.sh` to check for override files
- This is NOT explicitly listed as a task
- Hash scheme (MD5? SHA1?) not specified
- **Fix**: Add explicit task to modify protected-paths.sh, specify hash as MD5

**Additional Issues**:
- Bash cannot natively match `**` glob patterns in conditionals
- Need to use case + regex combination for pattern matching
- Platform detection needed for case sensitivity (macOS vs Linux)

---

#### Hook 4: Self-Review Gate

**Purpose**: Block Stop event unless Self-Review Checkpoint is completed.

**Skip Conditions** (from requirements-v2 lines 304-309):
- No active work item (status: implement)
- tasks_completed: 0
- status: blocked
- last_updated > 24 hours ago
- Bypass file exists: `.claude/hooks/bypass-self-review`

**Self-Review Completeness Check** (lines 318-331):
```yaml
1. Confidence Assessment:
   - Pattern: ^\*\*Overall Confidence\*\*:\s*(High|Medium|Low)\s*$
   - NOT: High | Medium | Low (template with pipes)

2. Self-Review Checklist:
   - Count: [x] checkboxes
   - Minimum: 4 of 5 checked

3. Self-Review Passed:
   - Pattern: ^\*\*Self-Review Passed\*\*:\s*(Yes|No)\s*$
   - NOT: Yes / No (template with slash)
```

**State File Format** (lines 349-355):
```yaml
# .claude/hooks/.self-review-state
work_id: W-008
check_count: 2
first_check: 2026-02-01T10:30:00Z
last_check: 2026-02-01T10:35:00Z
```

**Deep Validation Finding - BLOCKER**:
- `protected-paths.sh` blocks all writes to `.claude/`
- State file `.claude/hooks/.self-review-state` would be blocked
- **Fix**: Add exception to protected-paths.sh for `.self-review-*` files

**Additional Issues**:
- YAML parsing in bash is complex (no native parser)
- Date arithmetic differs between GNU and BSD date
- macOS: `date -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s`
- Linux: `date -d "$ts" +%s`
- Template detection regex must handle both `|` (pipe) and `/` (slash) separators

---

## Technical Details to Preserve

### Platform Compatibility Issues

| Feature | GNU (Linux) | BSD (macOS) | Workaround |
|---------|-------------|-------------|------------|
| `grep -o` | Yes | No | Use awk |
| `grep -P` | Yes | No | Use extended regex |
| Date parsing | `date -d` | `date -j -f` | Platform detection |
| Case conversion | `${var,,}` | Not in bash 3.x | External tool or upgrade |

### Protected-Paths Modifications Required

Current `protected-paths.sh` patterns (lines 11-21):
```bash
PROTECTED_PATTERNS=(
    "^\.env$"
    "^\.env\."
    "^AGENTS\.md$"
    "^credentials"
    "^secrets"
    "^\.claude/"  # <-- Blocks Hook 3 & 4 state files
    ".*\.pem$"
    ".*_rsa$"
    "^id_rsa"
)
```

**Required Changes**:
1. Add override file check at top of script
2. Add exception for `.self-review-*` pattern
3. Add exception for `.scope-override-*` pattern

### Existing Hook Infrastructure

**settings.json structure**:
```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": ".claude/hooks/git-safety.sh \"$TOOL_INPUT\"" }] },
      { "matcher": "Write", "hooks": [{ "type": "command", "command": ".claude/hooks/protected-paths.sh \"$TOOL_INPUT\"" }] }
    ],
    "Stop": [
      { "matcher": "", "hooks": [{ "type": "command", "command": ".claude/hooks/session-exit.sh" }] }
    ]
  }
}
```

---

## Explicit Next Actions (Before Specification)

### Action 1: Fix Hook 1 Regex Pattern
- **File**: `spec/research/R-005--v6-hooks-integration/requirements-v2.md`
- **Line**: 61
- **Current**: `^### .* — T([0-9]+)(-T?([0-9]+))?:`
- **Change to**: `^### .* — (T|Task )([0-9]+)(-T?([0-9]+))?:`
- **Why**: Template uses `Task 1:`, real logs use `T1:`, regex must match both

### Action 2: Add Hook 2 Parsing Clarification
- **File**: `spec/research/R-005--v6-hooks-integration/requirements-v2.md`
- **Location**: After line 147
- **Add**:
```yaml
Parsing Approach:
  - Do NOT use regex for code fence boundaries
  - Use line-by-line parsing that respects YAML literal blocks
  - Or: Require validation blocks use simple format (no nested fences in output)
```
- **Why**: Nested code fences in output_head break regex fence detection

### Action 3: Update AGENTS.md Section 8.3
- **File**: `AGENTS.md`
- **Line**: ~618
- **Current**: "Output head AND tail (catches hidden failures)"
- **Change to**: "Output head OR tail (at least one required; include both for long outputs)"
- **Why**: Matches requirements-v2, resolves contradiction

### Action 4: Add protected-paths.sh Modification Task
- **File**: `spec/research/R-005--v6-hooks-integration/requirements-v2.md`
- **Location**: After line 260
- **Add**:
```yaml
Hook 3 Prerequisite: Modify protected-paths.sh
  Task: Add override file check before pattern matching

  Changes:
    1. At top of script, check for .claude/hooks/.scope-override-<hash>
    2. Hash: MD5 of file path (echo -n "$path" | md5sum | cut -d' ' -f1)
    3. If override exists and < 60 seconds old: exit 0 (allow)
    4. If override exists and >= 60 seconds: delete it, continue
```
- **Why**: Hook 3 creates override files that protected-paths must respect

### Action 5: Add State File Exception for Hook 4
- **File**: `spec/research/R-005--v6-hooks-integration/requirements-v2.md`
- **Location**: After line 345
- **Add**:
```yaml
Hook 4 Prerequisite: Modify protected-paths.sh
  Task: Add exception for self-review state files

  Add to top of protected-paths.sh:
    # Allow self-review state files
    if [[ "$FILENAME" =~ ^\.self-review- ]]; then
        exit 0
    fi
```
- **Why**: State file is in `.claude/hooks/` which is normally protected

### Action 6: Add Platform Compatibility Section
- **File**: `spec/research/R-005--v6-hooks-integration/requirements-v2.md`
- **Location**: New section before Implementation Priority
- **Add**:
```yaml
Platform Compatibility:
  GNU grep required:
    - Flags used: -E, -o, -A, -c
    - macOS users: brew install grep (use ggrep)
    - Or: Use POSIX alternatives (awk for extraction)

  Date parsing:
    - Linux: date -d "$timestamp" +%s
    - macOS: date -j -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" +%s
    - Detection: [[ "$OSTYPE" == "darwin"* ]]

  Bash version:
    - Required: 4.0+ for ${var,,} lowercase
    - macOS default: 3.2 (upgrade with brew install bash)
```
- **Why**: Deep validation found platform-specific issues

---

## Verification Checklist (Before Proceeding to Specification)

After addressing the 6 actions above:

- [ ] **Regex Test**: Verify `(T|Task )` pattern matches both `T1:` and `Task 1:`
- [ ] **AGENTS.md Updated**: Section 8.3 says "OR" not "AND"
- [ ] **No Contradictions**: requirements-v2.md and AGENTS.md are consistent
- [ ] **protected-paths.sh Tasks**: Both Hook 3 and Hook 4 prerequisites documented
- [ ] **Platform Requirements**: Documented with workarounds
- [ ] **Acceptance Criteria**: All 5 AC still valid after changes

---

## Acceptance Criteria (From requirements-v2.md)

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

---

## Files to Reference in Next Session

| File | Purpose |
|------|---------|
| `spec/research/R-005--v6-hooks-integration/requirements-v2.md` | **Primary requirements document** - needs updates |
| `spec/research/R-005--v6-hooks-integration/log.md` | Full research log with decisions |
| `AGENTS.md` | V6 protocol - Section 8.3 needs update |
| `.claude/hooks/protected-paths.sh` | Existing hook - needs modifications |
| `.claude/settings.json` | Hook configuration |
| `spec/templates/log-template.md` | Template format reference |

---

## Quality Check: What Might Be Missing?

| Concern | Status | Evidence |
|---------|--------|----------|
| Deep validation findings captured? | Complete | All 4 hooks documented with blockers |
| Regex patterns preserved? | Complete | Exact patterns included |
| Platform issues documented? | Complete | GNU vs BSD table included |
| protected-paths changes specified? | Complete | Both Hook 3 and Hook 4 prereqs listed |
| Next actions are specific? | Complete | File, line, exact change, rationale |

**Unrecoverable After Session Clear**:
- Sub-agent research files may not have been read (R-006, R-007)
- Exact agent outputs from deep validation not preserved (summaries are)

---

## References

- Claude Code Hooks Guide: https://code.claude.com/docs/en/hooks-guide
- Previous Session: `.context/claude-session-session-20260202-004527Z.md`
- V6 Evolution Plan: `/home/misael/agent-studio/v5-templates/spec/research/R-003--v6-evolution-plan/plan.md`
