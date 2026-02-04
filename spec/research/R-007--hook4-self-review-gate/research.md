# Research: Hook 4 — Self-Review Gate

**Date**: 2026-02-01
**Status**: Draft

## Problem

The Self-Review Protocol (AGENTS.md Section 6.2) requires Implementers to complete a Self-Review Checkpoint before marking work complete. Currently, this is a manual process with no enforcement. An agent could mark work as complete (triggering a Stop event) without actually completing the self-review, defeating its purpose.

## Codebase Findings

### Self-Review Checkpoint Structure (log-template.md:142-193)

The Self-Review Checkpoint contains five mandatory sections:

```
## Self-Review Checkpoint

### Acceptance Criteria Verification
| AC ID | Criterion | Met? | Evidence |
|-------|-----------|:----:|----------|
| AC-01 | <from spec> | Yes/No | <where verified> |

### Self-Review Checklist
- [ ] Re-read each acceptance criterion from spec.md
- [ ] Verified each criterion is met (not assumed)
- [ ] Checked: Did I add anything NOT in the spec?
- [ ] Checked: Would this pass code review?
- [ ] If ANY doubt exists, flagged for human review

### Scope Check
- **Added beyond spec?** No / Yes: <what and why>
- **Deferred from spec?** No / Yes: <what and why>

### Confidence Assessment
**Overall Confidence**: High | Medium | Low
| Aspect | Confidence | Notes |
|--------|:----------:|-------|
| Code correctness | High/Med/Low | <notes> |

## Final Result
**Completed**: YYYY-MM-DD
**All Acceptance Criteria Met**: Yes / No
**Self-Review Passed**: Yes / No
```

### Self-Review Protocol Requirements (AGENTS.md:324-332)

The Implementer MUST:
1. Re-read each acceptance criterion from spec.md
2. Verify each criterion is met (not assumed)
3. Check: Did I add anything NOT in the spec?
4. Check: Would this pass code review?
5. Complete the Self-Review Checkpoint in log.md
6. Assign confidence rating: High | Medium | Low
7. If confidence is Medium or Low, request human review

### Existing Hook Patterns

| Hook | Type | Event | Behavior |
|------|------|-------|----------|
| `session-exit.sh` | command | Stop | Warning only (exit 0) |
| `protected-paths.sh` | command | PreToolUse (Write) | Block (exit 2) |
| `git-safety.sh` | command | PreToolUse (Bash) | Block (exit 2) |

### Completed Self-Review Example (W-007)

A properly completed self-review shows:
- AC table rows with `Yes` or `No` in Met? column, actual evidence text
- Checklist items with `[x]` marks and optional notes
- Scope check with concrete answers (`No` or `Yes: <specific reason>`)
- Confidence table with single values (`High`, `Medium`, or `Low`)
- Overall Confidence with single picked value
- Final Result with actual dates and summaries

## Verification Requirements

### Section Detection: Complete vs Template

| Section | Placeholder Pattern | Completed Pattern |
|---------|---------------------|-------------------|
| AC Verification Table | `Yes/No`, `<from spec>`, `<where verified>` | `Yes` or `No` (single value), actual criterion text, actual evidence |
| Self-Review Checklist | `- [ ]` (unchecked) | `- [x]` (checked) |
| Scope Check | `No / Yes: <what and why>` | `No` or `Yes: <actual reason>` |
| Overall Confidence | `High \| Medium \| Low` | `High` or `Medium` or `Low` (single value) |
| Confidence Table | `High/Med/Low` | `High`, `Medium`, or `Low` (single value) |
| Completed Date | `YYYY-MM-DD` | Actual date (e.g., `2026-02-01`) |
| Summary | `<1-2 sentences...>` | Actual text (no angle brackets) |
| AC Met | `Yes / No` | `Yes` or `No` |
| Self-Review Passed | `Yes / No` | `Yes` or `No` |

### Minimum Completion Criteria

For the self-review to be considered "complete", ALL of these must be true:

1. **Overall Confidence is set**: Contains exactly `High`, `Medium`, or `Low` (not the template `High | Medium | Low`)

2. **Checklist has checked items**: At least 4 of 5 items marked `[x]` (allowing one to remain unchecked if not applicable)

3. **Self-Review Passed is answered**: Contains exactly `Yes` or `No` (not `Yes / No`)

4. **All Acceptance Criteria Met is answered**: Contains exactly `Yes` or `No`

### Confidence-Based Flags

| Confidence Level | Hook Behavior |
|------------------|---------------|
| High | Allow stop (pass) |
| Medium | Warn but allow (suggest human review) |
| Low | Warn but allow (strongly suggest human review) |

Note: Medium/Low confidence does NOT block, because the protocol says "request human review" not "must have human review". The warning ensures the agent/user is aware.

## Edge Cases

### 1. Research Phase (No Self-Review Needed)

**Detection**: `log.md` frontmatter contains `status: research`
**Behavior**: Allow stop without checking self-review

### 2. Specify Phase (No Self-Review Needed)

**Detection**: `log.md` frontmatter contains `status: specify`
**Behavior**: Allow stop without checking self-review

### 3. Work Just Started (No Tasks Completed)

**Detection**: `log.md` frontmatter contains `tasks_completed: 0`
**Behavior**: Allow stop without checking self-review (nothing to review)

### 4. Blocked Status

**Detection**: `log.md` frontmatter contains `status: blocked`
**Behavior**: Allow stop without checking self-review (work paused, not completing)

### 5. Infinite Loop Prevention

**Risk**: Hook blocks → agent tries to complete self-review → hook runs again
**Detection**: Environment variable `SELF_REVIEW_HOOK_ACTIVE=1`
**Behavior**: If already active, skip check (exit 0)

### 6. Escape Hatch for User Override

**Pattern**: File `.claude/hooks/bypass-self-review` exists
**Behavior**: If file exists, warn but don't block
**Use case**: User knows they want to stop mid-implementation

### 7. No Active Work Item

**Detection**: No `spec/work/W-*` directories with `status: implement`
**Behavior**: Allow stop (nothing to review)

### 8. Multiple Work Items

**Detection**: Multiple directories with `status: implement`
**Behavior**: Check ALL active work items; block if ANY has incomplete self-review

## Decision Criteria

### When to ALLOW Stop

1. No `spec/work/W-*/log.md` file exists
2. Frontmatter `status` is NOT `implement` (research, specify, blocked, complete)
3. Frontmatter `tasks_completed: 0` (nothing to review yet)
4. Self-review sections are properly completed:
   - Overall Confidence is set (High, Medium, or Low)
   - Self-Review Checklist has 4+ checked items
   - Self-Review Passed is answered (Yes or No)
   - All Acceptance Criteria Met is answered (Yes or No)
5. Escape hatch file exists (with warning)

### When to BLOCK Stop

1. `status: implement` AND `tasks_completed > 0` AND any of:
   - Overall Confidence not set (still shows `High | Medium | Low`)
   - Fewer than 4 checklist items checked
   - Self-Review Passed not answered
   - All Acceptance Criteria Met not answered

## Options

### Option A: Full Validation (Recommended)

**Approach**: Check all required self-review sections before allowing stop
- Parse frontmatter for status/tasks_completed
- Check Overall Confidence is single value
- Count checked checklist items
- Verify Final Result fields answered

**Pros**:
- Enforces complete self-review
- Catches incomplete work
- Clear feedback on what's missing

**Cons**:
- More complex implementation
- Regex parsing could have edge cases
- Slightly slower hook execution

### Option B: Minimal Validation

**Approach**: Only check if Self-Review section exists and has some content
- Look for `## Self-Review Checkpoint` section
- Check if any `[x]` marks exist
- Check if `**Overall Confidence**:` line has non-template content

**Pros**:
- Simpler implementation
- Faster execution
- Fewer false positives

**Cons**:
- Could miss partially completed sections
- Less thorough validation
- Easier to bypass accidentally

### Option C: Prompt-Based Self-Check

**Approach**: Use a prompt hook that asks the agent to self-verify
- Hook type: `prompt`
- Ask agent: "Have you completed the Self-Review Checkpoint?"
- Trust agent response

**Pros**:
- Simplest implementation
- No file parsing needed
- Agent can explain context

**Cons**:
- Relies on agent honesty
- Agent may forget or misremember
- No independent verification

## Recommendation

**Option A: Full Validation** is recommended because:

1. **Reliability**: Independent verification is more reliable than self-reporting
2. **Consistency with existing hooks**: Other hooks (git-safety, protected-paths) use file inspection
3. **Clear feedback**: Can tell user exactly what's missing
4. **Escape hatch**: Bypass file provides flexibility when needed

Implementation complexity is manageable because:
- Bash + grep can handle the parsing
- Pattern matching is straightforward
- Existing hook patterns provide templates

## Hook Type Decision

**Type**: `command` (not `prompt`)

**Rationale**:
1. Hook must read `log.md` to verify completion — prompts cannot read files
2. Hook must parse YAML frontmatter — requires shell tools
3. Hook must match multiple patterns — regex/grep needed
4. Independence — agent self-reporting is unreliable for enforcement

## Research Acceptance Criteria

- [x] Found 3+ prior art examples or implementations
  - session-exit.sh (Stop hook pattern)
  - protected-paths.sh (blocking pattern)
  - W-007 log.md (completed self-review example)
  - log-template.md (structure reference)
- [x] Identified trade-offs for 2+ approaches
  - Full Validation vs Minimal Validation vs Prompt-Based
- [x] Recommended approach with clear rationale
  - Option A: Full Validation
- [x] Open questions documented
  - See below
- [x] Scope is clear enough for specification phase
  - Decision criteria, edge cases, and detection patterns defined

**Completion Confidence**: High

## Open Questions

1. **Checklist threshold**: Should all 5 items be checked, or is 4/5 acceptable? (Current assumption: 4/5)

2. **Partial work submission**: If 5/10 tasks done and user wants to stop, should self-review be required? (Current assumption: No, only when `status: complete` or last task)

3. **Warning vs Block for Medium/Low confidence**: Should Medium/Low block or just warn? (Current assumption: Warn only, per protocol language "request human review")
