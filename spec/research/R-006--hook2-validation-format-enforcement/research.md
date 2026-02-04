# Research: Hook 2 - Validation Format Enforcement

**Date**: 2026-02-01
**Status**: Draft

---

## Problem

V6 requires that every implementation task logs validation evidence in a structured YAML format (AGENTS.md Section 8.3). Currently, this is "documented only" with no enforcement. Agents may skip or malform validation blocks, leading to incomplete audit trails and potential false "done" status.

---

## Codebase Findings

| File | Relevance |
|------|-----------|
| `AGENTS.md:599-621` | Section 8.3 defines validation evidence format |
| `spec/templates/log-template.md:82-95` | Template showing validation YAML structure |
| `spec/work/W-007--v6-consistency-fixes/log.md` | Real examples of correct validation blocks |
| `spec/research/R-005--v6-hooks-integration/research.md` | Hook 2 proposed as `prompt` type |
| `.claude/settings.json` | Current hook configuration patterns |

---

## Source Material Analysis

### Section 8.3 Evidence Format (AGENTS.md:599-621)

The canonical format is:

```yaml
**Validation**:
command: "<exact command run>"
exit_code: <0 or error code>
timestamp: <ISO8601>
output_head: |
  <first 10-20 lines>
output_tail: |
  <last 10-20 lines>
```

**Explicit requirements from Section 8.3**:
- "Exact command (not paraphrased)"
- "Exit code (not just 'passed')"
- "Timestamp (for audit trail)"
- "Output head AND tail (catches hidden failures)"
- "No validation = not done."

### Template Structure (log-template.md:82-95)

The template shows validation inside a YAML code block:

```yaml
**Validation**:
```yaml
command: "<exact command run>"
exit_code: 0
timestamp: YYYY-MM-DDTHH:MM:SSZ
output_head: |
  <first 10-20 lines of output>
output_tail: |
  <last 10-20 lines of output>
```

### Real Examples (W-007 log.md)

Observed patterns in actual usage:
- All entries have `command`, `exit_code`, `timestamp`
- Some entries omit `output_tail` (grep with small output)
- `output_head` always present
- Timestamps in ISO8601 format (e.g., `2026-02-01T21:15:00Z`)
- Exit codes are numeric (0 for pass)

---

## Validation Requirements

### Required Fields

| Field | Type | Constraints |
|-------|------|-------------|
| `command` | string | Non-empty, quoted string with exact command |
| `exit_code` | integer | Numeric (0, 1, 2, etc.) |
| `timestamp` | string | ISO8601 format: `YYYY-MM-DDTHH:MM:SSZ` or with timezone offset |

### Optional Fields

| Field | Type | Constraints |
|-------|------|-------------|
| `output_head` | multiline string | YAML literal block (`\|`) |
| `output_tail` | multiline string | YAML literal block (`\|`) |

**Note**: Section 8.3 says "Output head AND tail (catches hidden failures)" as a required element. However, real usage (W-007) shows `output_tail` is sometimes omitted for small outputs. **Recommendation**: Require at least one of `output_head` or `output_tail`.

### Format Constraints

| Constraint | Validation Rule |
|------------|-----------------|
| command not empty | `command` field exists and has content |
| exit_code numeric | Must match regex `^[0-9]+$` |
| timestamp ISO8601 | Must match `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(Z|[+-]\d{2}:\d{2})$` |
| output format | If present, must be multiline YAML block |

---

## Edge Cases

### 1. Task Still In Progress

**Scenario**: A task entry exists with `**Status**: done` but no validation block yet (agent writing incrementally).

**Decision**: Hook triggers on `**Status**: done`. If status is not `done`, validation is not required.

**Rule**: Only check for validation when `**Status**: done` appears in the task entry.

### 2. Multiple Validation Blocks in One Task

**Scenario**: Agent runs multiple validation commands for a single task.

**Decision**: Allow multiple validation blocks. Each block must be valid individually.

**Rule**: If multiple `**Validation**:` blocks exist in a task, all must conform to format.

### 3. Research Phase Entries

**Scenario**: Research log.md files do not have implementation tasks.

**Detection**: 
- File path contains `spec/research/`
- OR frontmatter `status: research`

**Rule**: Skip validation checks for research phase logs.

### 4. Specify Phase Entries

**Scenario**: During specification phase, there are no implementation tasks.

**Detection**:
- Frontmatter `status: specify`
- OR no `## Stage 3: Implement` section

**Rule**: Skip validation checks for specify phase logs.

### 5. Blocked Tasks

**Scenario**: Task is `**Status**: blocked` - no validation expected.

**Rule**: Only require validation for `**Status**: done`, not `blocked`.

### 6. Failed Validation

**Scenario**: Validation ran but failed (`exit_code: 1`, `**Result**: fail`).

**Rule**: The validation block itself is still valid. The hook checks format, not pass/fail status.

### 7. Micro-Task Path (Complexity 0)

**Scenario**: Complexity 0 work uses commit message as log (Section 5.5).

**Detection**: No `spec/work/W-*` directory created.

**Rule**: Hook only applies to files matching `spec/work/*/log.md`. Micro-tasks are out of scope.

### 8. Template Placeholders

**Scenario**: Log.md contains template placeholders like `<exact command run>`.

**Rule**: Validation block with placeholders should be flagged (not valid).

---

## Decision Criteria

### When to ALLOW (proceed with commit/edit)

1. File is NOT in `spec/work/*/log.md` path
2. File is in research phase (`spec/research/*`)
3. File has frontmatter `status: research` or `status: specify`
4. No task entries with `**Status**: done`
5. All `**Status**: done` entries have valid validation blocks:
   - `command` field present and non-empty
   - `exit_code` field present and numeric
   - `timestamp` field present and ISO8601 format
   - At least one of `output_head` or `output_tail` present (recommended)

### When to BLOCK (reject the edit)

1. Task entry has `**Status**: done` AND:
   - No `**Validation**:` block present, OR
   - `command` field missing or empty, OR
   - `exit_code` field missing or non-numeric, OR
   - `timestamp` field missing or malformed

### Warning Only (allow but notify)

1. `output_head` or `output_tail` missing (best practice, not hard block)
2. Placeholder text detected in fields (e.g., `<exact command>`)

---

## Hook Type Analysis

### Option A: `command` Type (Pattern Matching)

**Approach**: Bash script with regex/grep to validate YAML structure.

**Pros**:
- Fast execution (< 100ms)
- Deterministic, no LLM variability
- Easy to test and debug
- No additional cost

**Cons**:
- YAML parsing in bash is fragile
- Multiline block detection is complex
- Cannot handle context-aware decisions

**Feasibility**: Moderate. Would need to:
1. Parse task boundaries
2. Detect `**Status**: done`
3. Parse YAML block structure
4. Validate field formats

### Option B: `prompt` Type (LLM Judgment)

**Approach**: Single LLM call to analyze log.md content.

**Pros**:
- Handles complex context (phase detection)
- Natural language error messages
- Can handle edge cases gracefully
- Simpler prompt vs. complex regex

**Cons**:
- Latency (1-3 seconds per check)
- LLM cost per edit
- Potential for inconsistent results
- Overkill for format validation

**Feasibility**: High, but may be overengineered.

### Option C: Hybrid Approach

**Approach**: `command` for basic format checks, `prompt` for edge case decisions.

**Pros**:
- Fast path for common cases
- LLM only invoked for ambiguous situations

**Cons**:
- Added complexity
- Two hooks to maintain

**Feasibility**: High complexity, questionable value.

---

## Recommendation

**Chosen**: `command` Type (Option A)

**Rationale**:

1. **Deterministic**: Format validation should be consistent, not probabilistic
2. **Fast**: Every log.md edit would trigger this; latency matters
3. **Cost-effective**: No LLM calls for mechanical format checking
4. **Debuggable**: Bash script can be tested independently
5. **Sufficient**: The validation format is structured enough for pattern matching

**Implementation Strategy**:

Use a bash script with `awk` or `grep` to:
1. Check if file matches `spec/work/*/log.md`
2. Skip if frontmatter status is `research` or `specify`
3. Find all task entries with `**Status**: done`
4. For each, verify presence of validation block with required fields
5. Validate field formats using regex
6. Return exit 0 (allow), exit 2 (block), or exit 0 with warning message

---

## Research Acceptance Criteria

Before marking research complete, verify:

- [x] Found 3+ prior art examples or implementations
  - AGENTS.md Section 8.3 (canonical format)
  - log-template.md (template structure)  
  - W-007 log.md (real usage examples)
  - Existing hooks (git-safety.sh, protected-paths.sh patterns)
- [x] Identified trade-offs for 2+ approaches
  - `command` vs `prompt` vs hybrid
- [x] Recommended approach with clear rationale
  - `command` type for deterministic, fast, cost-effective checking
- [x] Open questions documented (see below)
- [x] Scope is clear enough for specification phase
  - Yes: required fields, edge cases, and decision criteria defined

**Completion Confidence**: High

---

## Open Questions

1. **Strictness level**: Should missing `output_head`/`output_tail` be a hard block or warning?
   - **Recommendation**: Warning only (allows small-output commands)

2. **Retroactive enforcement**: Should existing log.md files be grandfathered?
   - **Recommendation**: No - hook only fires on edits

3. **Performance budget**: What is acceptable latency for this hook?
   - **Recommendation**: < 200ms (command type easily achieves this)

4. **Escape hatch**: Should there be a way to bypass for urgent fixes?
   - **Recommendation**: No escape hatch; fix the format instead

---

## Appendix: Sample Validation Patterns

### Valid Validation Block

```yaml
**Validation**:
```yaml
command: "npm test"
exit_code: 0
timestamp: 2026-02-01T21:15:00Z
output_head: |
  PASS src/tests/foo.test.ts
  All tests passed
```

### Invalid: Missing exit_code

```yaml
**Validation**:
```yaml
command: "npm test"
timestamp: 2026-02-01T21:15:00Z
output_head: |
  All tests passed
```

### Invalid: Non-numeric exit_code

```yaml
**Validation**:
```yaml
command: "npm test"
exit_code: passed
timestamp: 2026-02-01T21:15:00Z
```

### Invalid: Malformed timestamp

```yaml
**Validation**:
```yaml
command: "npm test"
exit_code: 0
timestamp: Feb 1, 2026
```

### Valid: Multiple validation blocks

```yaml
**Validation**:
```yaml
command: "npm run lint"
exit_code: 0
timestamp: 2026-02-01T21:15:00Z
output_head: |
  No linting errors
```

```yaml
command: "npm test"
exit_code: 0
timestamp: 2026-02-01T21:16:00Z
output_head: |
  All tests passed
```
