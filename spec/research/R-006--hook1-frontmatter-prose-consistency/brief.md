# Brief: Hook 1 - Frontmatter/Prose Consistency Check

**Date**: 2026-02-01
**Requester**: User
**Parent**: R-005--v6-hooks-integration

## Goal

Define the exact requirements for a hook that verifies `log.md` frontmatter `tasks_completed` count matches the actual count of completed task entries in the prose section.

## Scope

- Parsing requirements for frontmatter extraction
- Pattern matching for completed tasks in prose
- Edge case identification
- Decision criteria for pass/fail
- Tool/dependency selection

## Constraints

- Output: Requirements document only (no code)
- Hook type: Will be an `agent` hook per R-005 recommendation
- Trigger: PostToolUse on Edit/Write to `*/log.md`
