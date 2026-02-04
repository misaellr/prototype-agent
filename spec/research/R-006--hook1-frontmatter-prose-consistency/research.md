# Research: Hook 1 - Frontmatter/Prose Consistency Check Requirements

**Date**: 2026-02-01
**Status**: Draft
**Parent**: R-005--v6-hooks-integration

---

## 1. Problem Summary

V6 requires that the `tasks_completed` field in `log.md` frontmatter accurately reflects the number of completed task entries in the prose section. This invariant is documented but not enforced. When frontmatter and prose drift out of sync, it causes state corruption that can mislead the Implementer agent about current progress.

From AGENTS.md Section 6.2:
> 3. Verify frontmatter `tasks_completed` matches prose task count
> 4. If mismatch, STOP and request human review

This hook enforces that check automatically.

---

## 2. Parsing Requirements

### 2.1 Frontmatter Extraction

**Source**: Lines 1-12 of `log-template.md`

**Format**: YAML frontmatter delimited by `---` markers.

```yaml
---
work_id: W-<id>
work_name: <name>
research_id: null
status: research | specify | implement | complete | blocked
current_task: T1
tasks_completed: 0        # <-- TARGET FIELD
tasks_total: <number>
started: YYYY-MM-DD
last_updated: YYYY-MM-DDTHH:MM:SSZ
blockers: []
---
```

**Extraction Method**:
1. Read file content
2. Locate first `---` (must be line 1)
3. Locate second `---`
4. Parse content between delimiters as YAML
5. Extract `tasks_completed` as integer

**Tools**: 
- `grep -n '^---$'` to find delimiter lines
- `sed -n '2,<line>p'` to extract frontmatter content
- `grep 'tasks_completed:'` + `cut`/`awk` to extract value

**Alternative**: Direct YAML parsing with `yq` if available (more robust but adds dependency)

### 2.2 Completed Task Count in Prose

**Source**: Stage 3: Implement section of `log-template.md` (lines 72-119)

**Pattern to Match**: Task entries under "Stage 3: Implement" with `**Status**: done`

**Task Entry Structure** (from template):

```markdown
### YYYY-MM-DD HH:MM — Task N: <name>

**Status**: done | blocked

**Changes**:
- `path/to/file.ts` — <what changed>

**Validation**:
```yaml
command: "<exact command run>"
exit_code: 0
...
```

**Result**: pass | fail

**Notes**: <any issues, decisions, or observations>
```

**Pattern Analysis**:

| Pattern Component | Regex | Notes |
|-------------------|-------|-------|
| Task header | `^### .* — T(ask )?[0-9]+:` | Captures "Task 1:" or "T1:" variants |
| Status line | `^\*\*Status\*\*: done` | Must be exactly "done" |
| Blocked status | `^\*\*Status\*\*: blocked` | Should NOT count as completed |

**Counting Method**:
1. Find all task headers in Stage 3 section
2. For each task header, find the immediately following `**Status**:` line
3. Count only those with value `done` (not `blocked`)

**Edge Case from Real Example** (W-007 log.md lines 140-153):
```markdown
### 2026-02-01 21:23 — T6-T8: Update reviewer, documenter, janitor

**Status**: done
```
This is a COMBINED task entry covering T6, T7, and T8. The count should be **3 completed tasks** from this single entry, not 1.

---

## 3. Detailed Parsing Rules

### 3.1 Frontmatter Rules

| Rule | Description |
|------|-------------|
| FM-1 | Frontmatter MUST start at line 1 with `---` |
| FM-2 | Frontmatter MUST end with a second `---` |
| FM-3 | `tasks_completed` MUST be a non-negative integer |
| FM-4 | If `tasks_completed` is missing, treat as error (not 0) |

### 3.2 Prose Task Counting Rules

| Rule | Description |
|------|-------------|
| PT-1 | Only count tasks in "Stage 3: Implement" section |
| PT-2 | Task header format: `### <timestamp> — T<n>: <name>` OR `### <timestamp> — Task <n>: <name>` |
| PT-3 | Combined tasks (e.g., `T6-T8:`) count as the number of tasks in the range |
| PT-4 | Status `done` = completed |
| PT-5 | Status `blocked` = NOT completed |
| PT-6 | Missing status line = error (flag for review) |
| PT-7 | Status line must immediately follow the task header (within 5 lines) |

### 3.3 Combined Task Parsing (PT-3)

**Pattern**: `T<n>-T<m>:` or `Task <n>-<m>:`

**Examples**:
- `T6-T8:` = 3 tasks (T6, T7, T8)
- `Task 1-3:` = 3 tasks
- `T5, T6, T7:` = 3 tasks (comma-separated variant)

**Calculation**: `(end - start) + 1`

---

## 4. Edge Cases

### 4.1 No Frontmatter

**Detection**: File does not start with `---` on line 1

**Decision**: `ok=false`

**Reason**: "Missing YAML frontmatter. File must start with --- delimiter."

### 4.2 Empty log.md

**Detection**: File is empty or contains only whitespace

**Decision**: `ok=false`

**Reason**: "Empty log.md file. Expected YAML frontmatter."

### 4.3 Research Phase (No Implementation Tasks Yet)

**Detection**: 
- `status: research` in frontmatter, OR
- `tasks_completed: 0` AND no Stage 3 section

**Decision**: `ok=true` (skip check)

**Rationale**: Research and Specify phases legitimately have 0 completed tasks and may not have a Stage 3 section yet.

### 4.4 Specify Phase

**Detection**: `status: specify` in frontmatter

**Decision**: `ok=true` (skip check)

**Rationale**: Same as research phase.

### 4.5 Task Marked "blocked" Not "done"

**Detection**: `**Status**: blocked`

**Decision**: Do NOT count as completed

**Rationale**: Blocked tasks have not completed successfully.

### 4.6 Frontmatter Says Complete But Prose Missing Tasks

**Detection**: 
- `tasks_completed: 5` in frontmatter
- Only 3 `**Status**: done` entries found in prose

**Decision**: `ok=false`

**Reason**: "Frontmatter says 5 tasks completed, but only 3 'done' task entries found in prose."

### 4.7 Prose Has More Done Tasks Than Frontmatter Claims

**Detection**:
- `tasks_completed: 2` in frontmatter
- 4 `**Status**: done` entries found in prose

**Decision**: `ok=false`

**Reason**: "Frontmatter says 2 tasks completed, but 4 'done' task entries found in prose. Frontmatter may need update."

### 4.8 Malformed Status Line

**Detection**: Status line present but value is not `done` or `blocked`
- e.g., `**Status**: in progress`
- e.g., `**Status**: partial`

**Decision**: `ok=false`

**Reason**: "Task <n> has invalid status '<value>'. Expected 'done' or 'blocked'."

### 4.9 Missing Status Line

**Detection**: Task header found but no `**Status**:` line within 5 lines

**Decision**: `ok=false`

**Reason**: "Task <n> is missing **Status**: line."

### 4.10 Work Already Complete

**Detection**: `status: complete` in frontmatter

**Decision**: Still validate (do NOT skip)

**Rationale**: Completed work should still be internally consistent. This catches retroactive edits that break consistency.

### 4.11 Non-log.md Files

**Detection**: File path does not end with `log.md`

**Decision**: `ok=true` (skip - not applicable)

**Rationale**: Hook only applies to log.md files.

### 4.12 Research log.md (Not Work log.md)

**Detection**: File path matches `spec/research/*/log.md`

**Decision**: `ok=true` (skip check)

**Rationale**: Research logs track exploration, not task completion. They may have different frontmatter fields.

---

## 5. Decision Criteria Summary

### 5.1 When to Return `ok=true`

| Condition | Rationale |
|-----------|-----------|
| Not a log.md file | Hook not applicable |
| Research log.md (`spec/research/*/log.md`) | Different structure, no tasks |
| Status is `research` or `specify` | Pre-implementation phase |
| `tasks_completed` matches prose count | Consistent state |

### 5.2 When to Return `ok=false` with Reason

| Condition | Reason Message |
|-----------|----------------|
| No frontmatter | "Missing YAML frontmatter" |
| Empty file | "Empty log.md file" |
| `tasks_completed` missing | "Frontmatter missing tasks_completed field" |
| Count mismatch (prose < frontmatter) | "Frontmatter says N completed, but only M found in prose" |
| Count mismatch (prose > frontmatter) | "Frontmatter says N completed, but M found in prose" |
| Invalid status value | "Task X has invalid status 'Y'" |
| Missing status line | "Task X is missing **Status**: line" |
| Frontmatter parse error | "Failed to parse frontmatter: <error>" |

---

## 6. Required Tools/Dependencies

### 6.1 Core Shell Tools (Always Available)

| Tool | Purpose |
|------|---------|
| `grep` | Pattern matching for delimiters, headers, status |
| `sed` | Extract frontmatter block |
| `awk` | Parse field values, arithmetic |
| `cut` | Extract specific fields |
| `wc -l` | Count lines/matches |
| `head`/`tail` | Select specific line ranges |

### 6.2 Optional Enhanced Tools

| Tool | Purpose | Fallback |
|------|---------|----------|
| `yq` | YAML parsing | `grep` + `awk` |
| `jq` | JSON output formatting | Plain text output |

### 6.3 Recommended Implementation Approach

**Hybrid Approach**: Use shell tools for extraction, explicit scripting for logic.

1. **Extract frontmatter** (shell):
   ```bash
   frontmatter_end=$(grep -n '^---$' "$file" | sed -n '2p' | cut -d: -f1)
   tasks_completed=$(sed -n "2,$((frontmatter_end-1))p" "$file" | grep 'tasks_completed:' | awk '{print $2}')
   ```

2. **Count prose tasks** (shell):
   ```bash
   # Find task headers with "done" status
   prose_done=$(grep -A5 '^### .* — T' "$file" | grep -c '^\*\*Status\*\*: done')
   ```

3. **Handle combined tasks** (awk):
   ```bash
   # Parse T6-T8 style headers
   # This requires more complex logic - see spec for details
   ```

4. **Compare and decide** (shell):
   ```bash
   if [ "$tasks_completed" -ne "$prose_done" ]; then
       echo "Mismatch: frontmatter=$tasks_completed, prose=$prose_done"
       exit 1
   fi
   ```

---

## 7. Input/Output Contract

### 7.1 Hook Input

The hook receives the file path being edited:
- Via `$TOOL_INPUT` for command hooks
- Via hook context for agent hooks

**Expected Input Structure** (for agent hook):
```json
{
  "tool": "Edit",
  "input": {
    "file_path": "/path/to/spec/work/W-007--name/log.md",
    "old_string": "...",
    "new_string": "..."
  }
}
```

### 7.2 Hook Output

**For `ok=true`**:
```json
{
  "ok": true
}
```

**For `ok=false`**:
```json
{
  "ok": false,
  "reason": "<detailed message explaining the inconsistency>"
}
```

---

## 8. Relevant Codebase Files

| File | Relevance |
|------|-----------|
| `spec/templates/log-template.md` | Canonical log.md structure |
| `AGENTS.md` Section 7.4 | Frontmatter contract |
| `AGENTS.md` Section 6.2 | Implementer workflow (mentions consistency check) |
| `.claude/settings.json` | Hook configuration format |
| `.claude/hooks/git-safety.sh` | Prior art for command hook |
| `spec/work/W-007--*/log.md` | Real-world example with combined tasks |

---

## 9. Research Acceptance Criteria

- [x] Found 3+ prior art examples: log-template.md, AGENTS.md, W-007/log.md, git-safety.sh
- [x] Identified trade-offs for 2+ approaches: shell-only vs YAML parser vs hybrid
- [x] Recommended approach with clear rationale: Hybrid shell approach
- [x] Open questions documented: See below
- [x] Scope is clear enough for specification phase: Yes

**Completion Confidence**: High

---

## 10. Open Questions

1. **Q1**: Should the hook warn or block on mismatch? 
   - **Recommendation**: Block (`ok=false`) - frontmatter is source of truth

2. **Q2**: How to handle the file BEFORE the edit vs AFTER?
   - **Recommendation**: Check AFTER the edit (PostToolUse validates the result)

3. **Q3**: Should combined task notation (T6-T8) be mandatory or optional?
   - **Recommendation**: Support but not require - parse when found, treat single tasks normally

4. **Q4**: Performance target for hook execution?
   - **Recommendation**: < 500ms (shell parsing is fast)

---

## 11. Recommendation

Proceed to specification phase with a **command hook** (not agent hook) since:

1. All parsing can be done with shell tools (grep/sed/awk)
2. No LLM reasoning required - purely mechanical check
3. Command hooks are faster and more deterministic
4. Matches the pattern of existing hooks (git-safety.sh, protected-paths.sh)

The hook should:
1. Extract `tasks_completed` from frontmatter
2. Count `**Status**: done` entries in prose (handling combined tasks)
3. Compare counts
4. Return ok=true if match, ok=false with reason if mismatch
5. Skip check for research/specify phases and research log files
