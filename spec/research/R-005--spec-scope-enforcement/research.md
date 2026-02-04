# Research: Spec Scope Enforcement Hook (Hook 3)

**Date**: 2026-02-01
**Status**: Draft

---

## Problem

During the implementation phase (Stage 3), the Implementer agent should only modify files explicitly listed in the approved spec.md. Without enforcement, agents may make unplanned changes that:
- Introduce scope creep
- Bypass the approval process
- Make changes that weren't reviewed during spec approval

---

## Codebase Findings

### 1. Spec Template Structure (`spec/templates/spec-template.md`)

The "Files to Change" section uses this format:

```markdown
## Files to Change

### Create

| File | Purpose |
|------|---------|
| `path/to/new-file.ts` | <why this file is needed> |

### Modify

| File | Changes |
|------|---------|
| `path/to/existing.ts` | <what to change> |
```

**Key observations**:
- Two subsections: "Create" and "Modify"
- Table format with file paths in first column
- Paths wrapped in backticks (e.g., `` `path/to/file.ts` ``)
- Some specs may have "None" in table (e.g., `| None | No new files needed |`)

### 2. Real-World Example (`spec/work/W-007--v6-consistency-fixes/spec.md`)

```markdown
## Files to Change

### Create

| File | Purpose |
|------|---------|
| None | No new files needed |

### Modify

| File | Changes |
|------|---------|
| `AGENTS.md` | Update Section 7.1 (research.md template) to V6 format |
| `.claude/agents/researcher.md` | Change v4 → v6, add Research AC reference |
```

### 3. Existing Hook Infrastructure

**settings.json hook registration**:
```json
{
  "matcher": "Write",
  "hooks": [
    {
      "type": "command",
      "command": ".claude/hooks/protected-paths.sh \"$TOOL_INPUT\""
    }
  ]
}
```

**Hook behavior**:
- Exit code 0 = allow
- Exit code 2 = block (with stderr message shown to user)
- `$TOOL_INPUT` contains the tool's input (file path for Write/Edit)

### 4. Workflow State (`AGENTS.md` Section 4.3)

The log.md frontmatter contains workflow state:
```yaml
---
status: research|specify|implement|complete|blocked
current_task: T<n>
---
```

Only `status: implement` should have scope enforcement active.

---

## Requirements Document

### REQ-1: Locate Active Spec

**Strategy** (priority order):
1. Find `spec/work/*/log.md` where frontmatter `status: implement`
2. If none, find most recently modified `spec/work/*/spec.md`
3. If no spec exists, scope enforcement is **disabled** (research phase)

**Rationale**: Only implementation phase benefits from scope enforcement. Research and specify phases are exploratory.

### REQ-2: Parse "Files to Change" Section

**Algorithm**:
1. Read spec.md content
2. Find `## Files to Change` heading
3. For subsections `### Create` and `### Modify`:
   - Find table rows (lines starting with `|`)
   - Extract first column after `|`
   - Strip backticks and whitespace
   - Skip rows containing "None", "File", "---" (header/separator)
4. Combine all paths into allowed files list

**Parsing rules**:
- Paths may be relative (e.g., `src/file.ts`) or project-relative with leading backtick
- Strip backticks: `` `path/file.ts` `` becomes `path/file.ts`
- Handle edge cases: empty table, "None" placeholder, malformed rows

### REQ-3: Match Target File Against Allowed List

**Matching logic**:
```
target_file = normalize(input_path)
allowed_files = parse_files_to_change(spec.md)

ALLOW if:
  - target_file matches any path in allowed_files (exact or suffix match)
  - target_file is a special file (see REQ-4)
  - No active spec exists (research phase)

BLOCK if:
  - target_file not in allowed_files
  - target_file is not a special file
  - Active spec exists
```

**Path normalization**:
- Remove leading `./` or `/`
- Resolve to project-relative path
- Handle both absolute paths and relative paths from project root

### REQ-4: Special Files (Always Allowed)

These files should **always be allowed** regardless of spec:

| File Pattern | Reason |
|--------------|--------|
| `spec/work/*/log.md` | Implementer must update progress log |
| `spec/work/*/spec.md` | Researcher may update spec during specify phase |
| `spec/research/*` | Research artifacts during research phase |

**Note**: `spec/templates/*` should NOT be in this list - template edits require explicit spec approval.

### REQ-5: Edge Cases

| Case | Behavior |
|------|----------|
| No `spec/work/` directory exists | ALLOW (fresh project) |
| No spec.md files exist | ALLOW (research phase) |
| Multiple work items with `status: implement` | WARN and use most recent |
| "Files to Change" section not found | WARN and BLOCK all non-special files |
| Empty allowed files list | BLOCK all non-special files |
| Malformed spec.md | WARN and BLOCK all non-special files |
| File path variations (abs vs rel) | Normalize both to project-relative |

### REQ-6: Hook Registration

**Tools to hook**: Both `Edit` and `Write`

**Rationale**: 
- `Write` creates or overwrites files
- `Edit` modifies existing files
- Both can make out-of-spec changes

**settings.json addition**:
```json
{
  "matcher": "Edit",
  "hooks": [
    {
      "type": "command", 
      "command": ".claude/hooks/spec-scope.sh \"$TOOL_INPUT\""
    }
  ]
},
{
  "matcher": "Write",
  "hooks": [
    {
      "type": "command",
      "command": ".claude/hooks/spec-scope.sh \"$TOOL_INPUT\""
    }
  ]
}
```

**Note**: This runs in addition to existing `protected-paths.sh` for Write.

### REQ-7: User Messaging

**Block message format**:
```
BLOCKED: File 'src/unauthorized.ts' not in spec

Allowed files (from spec/work/W-007--v6-consistency-fixes/spec.md):
  - AGENTS.md
  - .claude/agents/researcher.md
  - .claude/agents/implementer.md
  ...

To edit this file:
1. Update spec.md to include it in "Files to Change"
2. Get human approval for the spec change
3. Retry the edit
```

**Allow message**: No output (silent allow)

### REQ-8: Caching Consideration

**Performance optimization** (optional):
- Cache parsed allowed files list for current spec
- Invalidate cache when spec.md modified
- For MVP, re-parse on each hook invocation (simpler)

---

## Decision Criteria Summary

### ALLOW edit when:
1. Target file appears in "Files to Change" (Create or Modify section)
2. Target file is a special file (`spec/work/*/log.md`, `spec/work/*/spec.md`, `spec/research/*`)
3. No active spec exists (research phase)

### BLOCK edit when:
1. Active spec exists AND
2. Target file not in "Files to Change" AND
3. Target file is not a special file

---

## Options Analysis

### Option A: Strict Enforcement (Recommended)

- **Approach**: Block all edits not in spec, with explicit special file exceptions
- **Pros**: 
  - Enforces discipline
  - Prevents scope creep
  - Aligns with v6 philosophy
- **Cons**: 
  - May frustrate if spec is incomplete
  - Requires spec update workflow for unforeseen files

### Option B: Warning Only

- **Approach**: Log warning but allow all edits
- **Pros**: 
  - Non-disruptive
  - Educational without blocking
- **Cons**: 
  - Doesn't enforce discipline
  - Scope creep still possible

### Option C: Strict with Override Flag

- **Approach**: Block by default, allow with `--force-edit` or similar
- **Pros**: 
  - Enforcement with escape hatch
  - Best of both worlds
- **Cons**: 
  - More complex implementation
  - May be abused

---

## Recommendation

**Implement Option A: Strict Enforcement**

Rationale:
1. Aligns with v6 philosophy of explicit state and human approval gates
2. Forces proper workflow: update spec -> get approval -> implement
3. Consistent with existing protected-paths.sh approach
4. Special file exceptions handle legitimate needs (log.md, spec.md updates)

The enforcement is scoped to implementation phase only, so research and specify phases remain flexible.

---

## Research Acceptance Criteria

Before marking research complete, verify:
- [x] Found 3+ prior art examples or implementations
  - `protected-paths.sh`: blocking pattern
  - `git-safety.sh`: command parsing pattern  
  - `W-007 spec.md`: real "Files to Change" format
  - `settings.json`: hook registration pattern
- [x] Identified trade-offs for 2+ approaches
  - Option A: Strict (discipline vs friction)
  - Option B: Warning (flexible vs permissive)
  - Option C: Override flag (complex vs flexible)
- [x] Recommended approach with clear rationale
  - Option A with special file exceptions
- [x] Open questions documented
  - See below
- [x] Scope is clear enough for specification phase
  - Yes, all requirements defined

**Completion Confidence**: High

---

## Open Questions

1. **Environment variable for active spec**: Should we support `ACTIVE_SPEC=/path/to/spec.md` override for explicit control?
   - [ASSUMPTION: No, use automatic detection for simplicity]

2. **Multiple active implementations**: What if two work items both have `status: implement`?
   - [ASSUMPTION: Use most recently modified, log warning]

3. **Cache invalidation**: Should we cache the allowed files list?
   - [ASSUMPTION: No cache for MVP, re-parse each invocation]
