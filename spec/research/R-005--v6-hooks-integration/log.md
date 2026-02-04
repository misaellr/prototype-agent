---
research_id: R-005
research_name: v6-hooks-integration
status: research
started: 2026-02-01
last_updated: 2026-02-01T02:30:00Z
---

# Log: R-005 V6 Hooks Integration Research

## Session: 2026-02-01

### Research Approach

Used 3 parallel sub-agents to investigate different aspects:

| Agent | Focus Area | Key Output |
|-------|------------|------------|
| Gap Analyzer | V6 guardrails lacking enforcement | 11 gaps identified, 5 high priority |
| Hook Mapper | Hook events to V6 workflow stages | Complete mapping table |
| Agent Hook Evaluator | Prompt/agent hooks for quality verification | 4 opportunities assessed |

### Files Examined

| File | Relevance |
|------|-----------|
| `AGENTS.md` | Full V6 protocol, Section 13 existing hooks |
| `spec/templates/log-template.md` | Self-Review Checkpoint structure |
| `.claude/hooks/*.sh` | Current hook implementations |
| Claude Code Hooks Guide | Hook types, lifecycle events, matchers |

### Key Discoveries

1. **Section 13 hooks are defensive only** - They block bad actions but don't assist workflow compliance

2. **Frontmatter is "source of truth" but not enforced** - Agents can write inconsistent values with no automated check

3. **Self-Review is "NOT optional" but easily skipped** - Template emphasizes this but nothing prevents skipping

4. **The V6 implementation gap was predictable** - Missing Section 7 updates happened because Research AC ("found 3+ locations") wasn't enforced

5. **Infinite loop risk is real** - Stop hooks need `stop_hook_active` guard

### Decisions

| Decision | Alternatives | Rationale |
|----------|--------------|-----------|
| Recommend Option B (Mechanical Checks) | A (format only), C (full reviewer) | Best value/friction ratio |
| Focus on 4 specific hooks | Implement all 11 gaps | Incremental, testable |
| Use agent type for file analysis | prompt type | Need tool access for file reading |
| Use command type for scope checks | agent type | Fast, deterministic, no LLM needed |

### Research Acceptance Criteria Verification

| Criterion | Met? | Evidence |
|-----------|:----:|----------|
| 3+ prior art examples | Yes | Existing .claude/hooks/*, Claude Code docs, V5 session |
| 2+ approaches with tradeoffs | Yes | Options A, B, C with pros/cons |
| Clear recommendation | Yes | Option B with rationale |
| Open questions documented | Yes | 4 questions listed |
| Scope clear for spec phase | Yes | 4 hooks defined with trigger/action |

**Completion Confidence**: High

### Output

- `brief.md`: Research goal and scope
- `research.md`: Full findings with recommendation
- `log.md`: This session log

### Next Steps

1. Human review of research findings
2. If approved, create `spec/work/W-008--v6-hooks-implementation/spec.md`
3. Implement 4 hooks in priority order

---

## Session: 2026-02-01 (Implementation Requirements Research)

### Approach

1. Created detailed requirements for each of 4 hooks using parallel researcher agents
2. Launched 4 parallel reviewer agents for adversarial validation
3. Synthesized findings into revised requirements (v2)

### Requirements Research (4 parallel agents)

| Hook | Agent Output | Key Findings |
|------|--------------|--------------|
| 1. Frontmatter/Prose | R-006 research created | Command hook sufficient, not agent |
| 2. Validation Format | R-006 research created | Command hook, format ambiguity found |
| 3. Scope Enforcement | R-005 research created | PreToolUse on Edit/Write |
| 4. Self-Review Gate | R-007 research created | File-based state needed |

### Adversarial Validation Results

| Hook | Verdict | Pass Rate | Critical Issues |
|------|---------|-----------|-----------------|
| 1 | Request-Changes | 5/11 | PostToolUse deadlock with frontmatter-first workflow |
| 2 | Request-Changes | 6/10 | Format ambiguity, output_head/tail conflict |
| 3 | **FAIL** | - | Protected-paths conflict, test files blocked |
| 4 | Request-Changes | 9/11 | Env var loop prevention won't work |

### P0 Issues Identified

| Hook | Issue | Resolution |
|------|-------|------------|
| 1 | PostToolUse deadlock | Warn-only + commit-time enforcement |
| 2 | Format ambiguity | Define canonical format with code fence |
| 2 | output conflict | Require OR, update AGENTS.md |
| 3 | Protected-paths conflict | Spec overrides with audit trail |
| 3 | Test files blocked | Add to always-allowed list |
| 4 | Env var doesn't persist | File-based state with timeout |

### Revised Requirements (v2)

Created `requirements-v2.md` addressing all P0 issues:

1. **Hook 1**: Changed to warn-only (not blocking) + pre-commit gate
2. **Hook 2**: Defined canonical YAML-in-code-fence format
3. **Hook 3**: Spec overrides protected-paths + extended allowlist
4. **Hook 4**: File-based loop prevention with 3-attempt + 5-min timeout

### Implementation Priority (Revised)

| Priority | Hook | Rationale |
|----------|------|-----------|
| 1 | Validation Format | Simplest, high impact |
| 2 | Scope Enforcement | Requires hook coordination |
| 3 | Self-Review Gate | State management complexity |
| 4 | Frontmatter/Prose | Warn-only reduces urgency |

### Research Acceptance Criteria (Re-verified)

| Criterion | Met? | Evidence |
|-----------|:----:|----------|
| 3+ prior art examples | Yes | Existing hooks, docs, W-007 examples |
| 2+ approaches with tradeoffs | Yes | Original options + revised approaches |
| Clear recommendation | Yes | 4 hooks with priority order |
| Open questions resolved | Yes | All resolved in requirements-v2.md |
| Scope clear for spec | Yes | Detailed requirements per hook |

**Completion Confidence**: High

### Artifacts Created

- `requirements-v2.md`: Revised requirements addressing P0 issues
- Sub-research: R-006 (hooks 1-2), R-007 (hook 4)

### Next Steps

1. Human review of `requirements-v2.md`
2. If approved, proceed to specification phase
3. Create `spec/work/W-008--v6-hooks-implementation/spec.md`
