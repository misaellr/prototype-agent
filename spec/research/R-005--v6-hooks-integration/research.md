# Research: V6 Hooks Integration

**Date**: 2026-02-01
**Status**: Draft

---

## Problem

V6 defines many guardrails (validation logging, frontmatter updates, self-review checkpoints) that rely on agent compliance rather than deterministic enforcement. The previous V6 implementation session demonstrated this gap when Section 7 and agent files were missed—something V6's own Research AC would have caught if enforced.

---

## Codebase Findings

| File | Relevance |
|------|-----------|
| `AGENTS.md` Section 13 | Current hooks: block destructive git commands, protect paths |
| `AGENTS.md` Section 8.3 | Validation evidence format (YAML block) - not enforced |
| `AGENTS.md` Section 7.4 | Frontmatter contract - documented only |
| `AGENTS.md` Section 6.2 | Self-Review Protocol - "NOT optional" but not enforced |
| `.claude/hooks/*.sh` | Existing safety hooks (git-safety, protected-paths, session-exit) |

---

## External References

| Source | Key Insight |
|--------|-------------|
| Claude Code Hooks Guide | Three hook types: command (shell), prompt (single LLM call), agent (subagent with tools) |
| Hooks Reference | `stop_hook_active` field prevents infinite loops in Stop hooks |

---

## Key Findings

### Finding 1: Current Hooks Are Purely Defensive

Section 13 hooks only **block** destructive operations:
- `git checkout main/master`, `git push --force`, `rm -rf`
- Writes to `.env*`, `AGENTS.md`, `.claude/*`

They do **not assist** with workflow compliance (validation logging, frontmatter updates, self-review).

### Finding 2: 11 Gaps Identified (5 High Priority)

| Priority | Gap | Current Enforcement |
|----------|-----|---------------------|
| **HIGH** | Validation evidence logging | Documented only |
| **HIGH** | Frontmatter state updates | Documented only |
| **HIGH** | Frontmatter/prose consistency | Agent compliance |
| **HIGH** | Self-Review Checkpoint | Documented only |
| **HIGH** | Validation must pass before done | Documented only |
| MEDIUM | Spec approval before implementation | Documented only |
| MEDIUM | Research AC completion | Agent compliance |
| MEDIUM | Complexity check before work | Documented only |
| MEDIUM | Git commit between tasks | Documented only |
| MEDIUM | Uncertainty marker handling | Documented only |
| LOW | Intent section for complexity 4-5 | Documented only |

### Finding 3: Hook-to-Workflow Mapping

| Hook Event | Research | Specify | Implement |
|------------|:--------:|:-------:|:---------:|
| SessionStart | Load brief | Load research | Verify state |
| PreToolUse | - | Validate format | **Enforce scope** |
| PostToolUse | Log searches | Check complexity | **Auto-log validation** |
| Stop | **Enforce Research AC** | Validate completeness | **Enforce Self-Review** |
| SessionEnd | - | - | Warn uncommitted |

### Finding 4: Hook Type Selection

| Condition | Recommended Type |
|-----------|------------------|
| Pattern matching (paths, regex) | `command` |
| File content analysis | `agent` |
| Yes/no decision on context | `prompt` |
| Long-running (tests) | `command` with async |

### Finding 5: Infinite Loop Risk in Stop Hooks

Stop hooks can cause infinite loops if they keep returning `{ok: false}`. The `stop_hook_active` field in hook input is `true` when Claude is already continuing due to a previous hook. **Must check this field and exit early.**

---

## Options

### Option A: Minimal - Format Enforcement Only

**Approach**: Add command hooks to validate log.md format (YAML validation block structure, frontmatter fields) without semantic checks.

**Pros**:
- Low complexity, fast execution
- No LLM calls, deterministic
- Easy to debug

**Cons**:
- Catches format errors only, not semantic issues
- Won't verify AC are actually met

### Option B: Moderate - Add Mechanical Checks

**Approach**: Option A plus agent hooks for frontmatter/prose consistency and validation format enforcement.

**Pros**:
- Catches state corruption (a documented V6 failure mode)
- Higher value with moderate complexity
- Agent hooks only where needed

**Cons**:
- Adds latency (~10-30s per check)
- Requires careful infinite-loop prevention

### Option C: Full - Automated Reviewer

**Approach**: Option B plus Stop hooks that spawn a Reviewer subagent to verify all AC before allowing completion.

**Pros**:
- Enforces "verify each criterion is met, not assumed"
- Catches the exact gap that caused V6 implementation issues

**Cons**:
- High latency (60-120s per stop)
- Complex to implement correctly
- Risk of false positives blocking legitimate completion

---

## Recommendation

**Chosen**: Option B (Moderate - Mechanical Checks)

**Rationale**:
1. Highest value-to-friction ratio
2. Addresses documented V6 failure modes (frontmatter drift, skipped validation)
3. Avoids the complexity and latency of full semantic verification
4. Can expand to Option C after validating Option B works

---

## Research Acceptance Criteria

Before marking research complete, verify:

- [x] Found 3+ prior art examples or implementations (existing hooks in .claude/hooks/, Claude Code docs, V5 session learnings)
- [x] Identified trade-offs for 2+ approaches (3 options with pros/cons)
- [x] Recommended approach with clear rationale (Option B)
- [x] Open questions documented (see below)
- [x] Scope is clear enough for specification phase (yes - 4 specific hooks to implement)

**Completion Confidence**: High

---

## Proposed Hooks (for Specification)

### Hook 1: Frontmatter/Prose Consistency (PostToolUse on log.md)
- **Type**: agent
- **Trigger**: Edit/Write to `*/log.md`
- **Action**: Count task entries, compare to frontmatter `tasks_completed`
- **Complexity**: Low-Medium
- **Value**: HIGH

### Hook 2: Validation Format Enforcement (PostToolUse on log.md)
- **Type**: prompt
- **Trigger**: Edit/Write to `*/log.md`
- **Action**: Check for YAML validation block (command, exit_code, timestamp)
- **Complexity**: Low
- **Value**: MEDIUM-HIGH

### Hook 3: Spec Scope Enforcement (PreToolUse)
- **Type**: command
- **Trigger**: Edit/Write to code files
- **Action**: Block edits to files not in spec.md "Files to Change"
- **Complexity**: Low
- **Value**: HIGH

### Hook 4: Self-Review Gate (Stop)
- **Type**: agent
- **Trigger**: Stop during implementation phase
- **Action**: Verify Self-Review Checkpoint completed in log.md
- **Complexity**: Medium
- **Value**: HIGH

---

## Open Questions

- **Q1**: What's the acceptable latency budget for Stop hooks? (suggest: 30s max)
- **Q2**: Should there be an escape hatch for urgent fixes?
- **Q3**: How to detect current V6 phase (research vs. specify vs. implement)?
- **Q4**: Should hooks apply to all complexity levels or only 3+?
