# Research Log: Hook 4 — Self-Review Gate

## Session: 2026-02-01

### Files Searched

| File | Relevance | Key Findings |
|------|-----------|--------------|
| `spec/templates/log-template.md` | High | Defines Self-Review Checkpoint structure (lines 142-193) |
| `AGENTS.md` | High | Section 6.2 defines Self-Review Protocol; Section 13 defines hook patterns |
| `.claude/settings.json` | High | Shows existing hook configuration pattern |
| `.claude/hooks/session-exit.sh` | High | Reference pattern for Stop hook (warning style) |
| `.claude/hooks/protected-paths.sh` | High | Reference pattern for blocking hook (exit 2) |
| `spec/work/W-007--v6-consistency-fixes/log.md` | High | Real-world completed Self-Review example |

### Key Findings

1. **Self-Review Checkpoint Structure** (log-template.md:142-193):
   - AC Verification table with AC ID, Criterion, Met?, Evidence columns
   - Self-Review Checklist (5 checkbox items)
   - Scope Check (Added beyond spec? / Deferred from spec?)
   - Confidence Assessment table + Overall Confidence
   - Final Result section

2. **Self-Review Protocol** (AGENTS.md:324-332):
   - Re-read each AC from spec.md
   - Verify each criterion is met (not assumed)
   - Check for scope creep (additions not in spec)
   - Check code review readiness
   - Complete checkpoint, assign confidence
   - Medium/Low confidence requires human review

3. **Existing Hook Patterns**:
   - Warning style: exit 0, output to stderr (session-exit.sh)
   - Blocking style: exit 2, output to stderr (protected-paths.sh, git-safety.sh)
   - Stop hooks receive no $TOOL_INPUT (settings.json:23-32)

4. **Completed Self-Review Example** (W-007 log.md:191-243):
   - AC table filled with Yes/No and evidence
   - Checklist items marked [x] with notes
   - Scope check answered with No/Yes: <details>
   - Confidence table filled with High/Med/Low
   - Overall Confidence: High
   - Final Result section completed

### Template Placeholder Patterns Identified

From log-template.md, placeholders to detect:
- AC table: `<from spec>`, `Yes/No`, `<where verified>`
- Checklist: `[ ]` (unchecked boxes)
- Scope check: `No / Yes: <what and why>`
- Confidence: `High | Medium | Low` (unpicked)
- Final Result: `YYYY-MM-DD`, `<1-2 sentences: what was accomplished>`

### Edge Cases Identified

1. Research phase — no self-review needed
2. Specify phase — no self-review needed
3. Implementation just started — no tasks completed yet
4. `stop_hook_active` flag — prevent infinite loop
5. User explicitly bypassing — escape hatch pattern

### Decision: Hook Type

**Agent vs Prompt**: This hook MUST be `command` type because:
- Needs to read log.md file to check sections
- Needs to parse YAML frontmatter (status field)
- Needs to check multiple patterns in file content
- Prompt hooks cannot read files

`prompt` type would only work if the agent self-reports completion status, which is unreliable.
