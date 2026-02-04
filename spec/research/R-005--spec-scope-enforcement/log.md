# Log: R-005 Spec Scope Enforcement Research

## Session: 2026-02-01

### Files Searched

| File/Pattern | Relevance | Finding |
|--------------|-----------|---------|
| `spec/templates/spec-template.md` | High | Defines "Files to Change" section structure with "Create" and "Modify" subsections in table format |
| `AGENTS.md` | High | Section 7.2 shows spec.md template, Section 13 documents safety hooks |
| `spec/work/W-007--v6-consistency-fixes/spec.md` | High | Real example showing file paths in table format with backticks |
| `.claude/hooks/protected-paths.sh` | High | Pattern for blocking writes, uses exit code 2 to block |
| `.claude/hooks/git-safety.sh` | High | Pattern for command argument parsing |
| `.claude/settings.json` | High | Shows hook registration with matcher for "Write" tool |

### Key Findings

1. **Spec Template Structure**:
   - "Files to Change" section has two subsections: "Create" and "Modify"
   - Files listed in table format: `| path/to/file.ts | description |`
   - Paths wrapped in backticks in the table

2. **Current Hook Infrastructure**:
   - PreToolUse hooks receive `$TOOL_INPUT` as argument
   - Exit code 2 blocks the operation
   - Exit code 0 allows the operation
   - Write tool already has protected-paths.sh hook registered

3. **Active Spec Detection**:
   - Work items in `spec/work/W-<id>--<name>/`
   - Only one spec should be "active" per agent session
   - Need strategy for finding the current spec

### Approaches Considered

1. **Environment Variable Approach**: Set `ACTIVE_SPEC` env var when starting work
   - Pros: Explicit, no guessing
   - Cons: Requires manual setup, can be forgotten

2. **Most Recent Spec Approach**: Find newest spec.md in spec/work/
   - Pros: Automatic, no setup needed
   - Cons: Ambiguous if multiple work items exist

3. **Frontmatter Status Approach**: Parse log.md frontmatter for `status: implement`
   - Pros: Uses existing workflow state
   - Cons: More complex parsing, requires log.md sync

4. **Always Allow with Warning**: Warn but don't block out-of-spec edits
   - Pros: Non-disruptive
   - Cons: Doesn't enforce discipline

### Decision

Recommend **Frontmatter Status Approach** with **Most Recent as fallback**:
1. First look for log.md with `status: implement`
2. If none found, use most recently modified spec.md
3. If no spec exists, allow all (research phase)

This aligns with the v6 workflow where only implementation phase has scope constraints.
