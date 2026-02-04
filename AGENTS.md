# AGENTS.md — Simplified Spec-Driven Development (v6)

## 1. Purpose

This file defines a **3-stage development workflow** for AI coding agents:

```
Research → Specify → Implement
```

All agents MUST follow this file. If any instruction conflicts, **AGENTS.md wins**.

---

## 2. Core Principles

### 2.1 Context Window Discipline

- Each stage produces a **condensed artifact** that fits in one context window
- Clear the context (`/clear`) between stages to preserve quality
- Never rely on chat history—persist state in versioned files

### 2.2 Externalized State (The Harness Pattern)

Agents are stateless. All continuity comes from files:

```
new_state = agent(current_files, tools)
```

The `spec/` directory is the agent's memory:
- `spec/project/` — persistent project context
- `spec/research/` — research outputs (optional)
- `spec/work/` — active implementation tracks

### 2.3 Validation as Truth

A task is not "done" without:
1. Validation command executed
2. Output recorded in `log.md`
3. Human checkpoint completed

### 2.4 Human-in-the-Loop Gates

Agents MUST stop and wait for human approval:
- After completing research
- After completing spec
- After each implementation task (if specified)
- When blocked or uncertain

---

## 3. Directory Structure

```
/
  AGENTS.md                    # This file (canonical)
  CLAUDE.md                    # Thin adapter → "Follow /AGENTS.md"

  spec/
    project/
      index.md                 # Project overview and navigation
      techstack.md             # Languages, tools, validation command
      conventions.md           # Style, naming, patterns

    research/                  # Stage 1 outputs (optional)
      R-001--<topic>/
        brief.md               # Input: what we're exploring
        research.md            # Output: findings, options, recommendation
        log.md                 # Session log: what was searched, tried, decided

    work/                      # Stage 2-3: spec + implementation
      W-001--<name>/
        spec.md                # The implementation spec
        log.md                 # Append-only progress + decisions (all stages)

    templates/
      research-template.md
      spec-template.md
      log-template.md

  .claude/
    agents/                    # Agent role definitions
      researcher.md
      implementer.md
      reviewer.md
      documenter.md
      janitor.md
    hooks/                     # Safety hooks (see Section 13)
    skills/                    # Reusable prompt skills
    settings.json              # Claude Code configuration

  tools/
    validate/
      validate.sh              # Primary validation entrypoint
```

---

## 4. The 3-Stage Workflow

### Overview

| Stage | Agent | Input | Output | Gate |
|-------|-------|-------|--------|------|
| **Research** | Researcher | Brief + codebase + docs | `research.md` | Human approves findings |
| **Specify** | Researcher | `research.md` | `spec.md` | Human approves spec |
| **Implement** | Implementer | `spec.md` | Code + `log.md` | Human approves each task |

### Stage 1: Research (Optional)

**When to use**: New features, unfamiliar territory, external integrations, architecture decisions.

**When to skip**: Bugfixes, simple features, cleanup, refactors where approach is clear.

**Goal**: Gather context, explore options, recommend an approach.

**Workflow**:
1. Create `spec/research/R-<id>--<topic>/`
2. Write `brief.md` with the question/goal
3. Create `log.md` to track the session
4. Research: codebase patterns, external docs, implementation examples
   - **Log each search**: what you looked for, what you found
   - **Log dead ends**: approaches considered and rejected
5. Write `research.md` with findings and recommendation
6. **STOP** for human approval

**Session Log** (`log.md` during research):
- Files searched and relevance assessment
- External docs consulted
- Approaches tried or considered
- Decisions made (with rationale)

**Output** (`research.md`):
- Problem summary (2-3 sentences)
- Relevant codebase files and patterns found
- External documentation/examples consulted
- 2-3 approach options with tradeoffs
- Recommended approach with rationale

**Research Acceptance Criteria** (v6):
Before marking research complete, verify:
- [ ] Found 3+ prior art examples or implementations
- [ ] Identified trade-offs for 2+ approaches
- [ ] Recommended approach with clear rationale
- [ ] Open questions documented (if any remain)
- [ ] Scope is clear enough for specification phase

### Stage 2: Specify

**Goal**: Transform research (or direct request) into an implementation spec.

**Workflow**:
1. Create `spec/work/W-<id>--<name>/`
2. Create `log.md` with frontmatter (set `research_id` if applicable)
3. If research was performed, import summary to `log.md` Stage 1 section
4. Analyze research and codebase to determine implementation approach
   - **Log files examined**: what informed the spec
   - **Log decisions**: why this approach vs alternatives
5. Write `spec.md` with requirements, files to change, and validation
6. **STOP** for human approval

**Session Log** (`log.md` during specify):
- Research artifacts consulted
- Files examined to understand current state
- Implementation decisions (why these files, this approach)
- Alternatives considered

**Output** (`spec.md`):
- Context (1-2 sentences: what and why)
- Files to create or modify (exact paths)
- Changes per file (what to add/modify/remove)
- Validation commands (exact commands to run)
- Acceptance criteria (testable statements)

### Stage 3: Implement

**Goal**: Execute the spec, one task at a time.

**Workflow**:
1. Read `spec.md` to understand the plan
2. Read `log.md` frontmatter to get `current_task`
3. **Verify state consistency**:
   - Count completed task entries in prose section
   - Compare to `tasks_completed` in frontmatter
   - If mismatch, STOP and request human review
4. Implement the current task (one file or one logical change)
5. Run validation commands
6. Log results in `log.md` prose section
7. Update frontmatter: increment `tasks_completed`, advance `current_task`, update `last_updated`
8. **STOP** for human checkpoint (or continue if pre-approved)
9. Repeat until spec is complete

**Session Log** (`log.md` during implement):
- Task started (timestamp, task name)
- Files changed
- Validation command + output
- Result (pass/fail)
- Decisions made during implementation
- Blockers encountered

**Rules**:
- One task = one atomic change (max 1-2 files)
- Always run validation after each task
- Never mark done without evidence
- Update frontmatter before prose (frontmatter is source of truth)
- If blocked, set `status: blocked` in frontmatter and stop

---

## 5. Complexity Guardrails

### 5.1 Complexity Thresholds

| Dimension | Simple | Complex |
|-----------|--------|---------|
| **Files touched** | 1-2 | 3+ |
| **Lines of code** | < 100 | 100+ |
| **Dependencies added** | 0 | 1+ |
| **External integrations** | 0 | 1+ |
| **Behavior change** | None/minimal | User-visible |

### 5.2 Ceremony Selection

| Complexity Score | Research | Specify | Intent Section | Implement |
|------------------|----------|---------|----------------|-----------|
| **0 (all Simple)** | No | No | No | Log only |
| **1-2** | No | Minimal | No | Yes |
| **2-3** | No | Yes | Optional | Yes |
| **4-5** | Yes | Yes | **Required** | Yes |

**Minimal spec**: Files to change + validation command (no tasks breakdown).

**Intent Section** (v6): For complexity 4-5 work, the spec MUST include an Intent section with:
- Problem statement (what's broken today)
- Use cases (As a... I want... So that...)
- Capabilities (what the system will do)

### 5.3 Mandatory Complexity Check

Before starting work, answer these 5 questions:

1. How many files will this touch? (1-2 = 0, 3+ = 1)
2. Estimated lines of code? (< 100 = 0, 100+ = 1)
3. New dependencies? (No = 0, Yes = 1)
4. External integrations? (No = 0, Yes = 1)
5. User-visible behavior change? (No = 0, Yes = 1)

**Total score determines ceremony level** (see 5.2).

### 5.4 Override Protocol

To use less ceremony than the score indicates:
1. State the score and intended ceremony level
2. Justify the override (e.g., "well-understood pattern", "isolated change")
3. Get human approval before proceeding

**Never** skip logging. Even trivial fixes get a log entry.

### 5.5 Micro-Task Protocol

For complexity score 0 (all dimensions simple), use the fast-path:

**Qualifications**:
- Single file change
- < 10 lines modified
- No behavior change
- No new dependencies
- Validation passes on first try

**Fast-Path Workflow**:
1. Skip work-item directory creation
2. Make the change
3. Run validation
4. Commit with structured message:
   ```
   fix(scope): description

   Complexity: 0
   Validation: <command> (exit 0)
   Files: <path>
   ```

**Upgrade Rule**: If ANY qualification fails during implementation,
stop and create full work-item with spec.md + log.md.

**Never skip logging entirely** — the commit message IS the log.

---

## 6. Agent Roles

### 6.1 Researcher

**Mission**: Explore and specify. Convert ambiguity into clear specs.

**Edits**: `spec/research/`, `spec/work/*/spec.md`

**Does not**: Write implementation code

**Workflow**:
1. Understand the goal
2. Research codebase, docs, examples
3. Produce `research.md` (Stage 1) or `spec.md` (Stage 2)
4. Stop for human approval

### 6.2 Implementer

**Mission**: Execute one spec task at a time. Validate and log evidence.

**Edits**: Code + `spec/work/*/log.md`

**Does not**: Modify spec or requirements

**Workflow**:
1. Read `spec.md`
2. Read `log.md` frontmatter to get `current_task`
3. Verify frontmatter `tasks_completed` matches prose task count
4. Implement the current task
5. Run validation
6. Update `log.md`: frontmatter (`tasks_completed`, `current_task`, `last_updated`) then prose
7. Stop for checkpoint

**Self-Review Protocol** (v6):
Before marking work complete, the Implementer MUST:
1. Re-read each acceptance criterion from spec.md
2. Verify each criterion is met (not assumed)
3. Check: Did I add anything NOT in the spec?
4. Check: Would this pass code review?
5. Complete the Self-Review Checkpoint in log.md
6. Assign confidence rating: High | Medium | Low
7. If confidence is Medium or Low, request human review

### 6.3 Reviewer

**Mission**: Verify work meets spec requirements.

**Edits**: `spec/work/*/log.md` (findings only)

**Does not**: Modify code

**Workflow**:
1. Read spec and log
2. Run validation commands
3. Compare results to acceptance criteria
4. Report: approve / request changes / reject

### 6.4 Documenter

**Mission**: Update user-facing documentation.

**Edits**: `docs/`, `README.md`, `CHANGELOG.md`

**Does not**: Modify code

**Trigger**: After work is approved

### 6.5 Janitor

**Mission**: Cleanup and maintenance (behavior-preserving only).

**Edits**: Code + `log.md`

**Does not**: Add features

---

## 7. Artifact Templates

### 7.1 research.md Template

> **Sync Notice**: This template MUST stay synchronized with `spec/templates/research-template.md`.

```markdown
# Research: <topic>

**Date**: YYYY-MM-DD
**Status**: Draft | Approved

## Problem
<2-3 sentences: what we're trying to solve>

## Codebase Findings
- `path/to/file.ts` — <what pattern or code is relevant>
- `path/to/other.ts` — <what pattern or code is relevant>

## External References
- <documentation URL or source> — <key insight>

## Options

### Option A: <name>
- Approach: <description>
- Pros: <benefits>
- Cons: <drawbacks>

### Option B: <name>
- Approach: <description>
- Pros: <benefits>
- Cons: <drawbacks>

## Recommendation
<which option and why>

## Research Acceptance Criteria

Before marking research complete, verify:
- [ ] Found 3+ prior art examples or implementations
- [ ] Identified trade-offs for 2+ approaches
- [ ] Recommended approach with clear rationale
- [ ] Open questions documented (if any remain)
- [ ] Scope is clear enough for specification phase

**Completion Confidence**: High | Medium | Low

## Open Questions
- <anything unresolved>
- Use `[NEEDS CLARIFICATION: <question>]` for items requiring human input
```

### 7.2 spec.md Template

> **Sync Notice**: This template MUST stay synchronized with `spec/templates/spec-template.md`.

```markdown
# Spec: <work name>

**Date**: YYYY-MM-DD
**Status**: Draft | Approved
**Complexity**: <0-5>
**Research**: `spec/research/R-<id>--<topic>/research.md` (if applicable)

## Context
<1-2 sentences: what we're building and why>

## Intent (required for complexity 4-5, optional for 2-3, skip for 0-1)

### Problem
<2-3 sentences: what's broken or missing today>

### Use Cases
| ID | As a... | I want... | So that... |
|----|---------|-----------|------------|
| UC-01 | <role> | <action> | <benefit> |

### Capabilities
| ID | Capability | Solves |
|----|------------|--------|
| CAP-01 | <what system does> | UC-01 |

## Files to Change

### Create
- `path/to/new-file.ts` — <purpose>

### Modify
- `path/to/existing.ts` — <what to change>

## Tasks

### T1: <name>
- File: `path/to/file.ts`
- Changes: <specific changes>
- Validation: `<command>`

### T2: <name>
- File: `path/to/file.ts`
- Changes: <specific changes>
- Validation: `<command>`

## Validation
```bash
./tools/validate/validate.sh
```

## Acceptance Criteria

### AC-01: <Descriptive name>
- **Given** <precondition or initial state>
- **When** <action or trigger>
- **Then** <observable outcome>

### AC-02: <Descriptive name>
- **Given** <precondition>
- **When** <action>
- **Then** <outcome>

## Notes
Use `[NEEDS CLARIFICATION: <question>]` for items requiring human input.
Use `[ASSUMPTION: <assumption>]` when proceeding with an assumption.
```

### 7.3 log.md Template

> **Sync Notice**: This template MUST stay synchronized with `spec/templates/log-template.md`.

```markdown
# Log: <work name>

## Progress

### YYYY-MM-DD HH:MM — Task 1: <name>
**Status**: done | blocked
**Changes**: <files modified>
**Validation**:
```yaml
command: "<exact command>"
exit_code: 0
timestamp: YYYY-MM-DDTHH:MM:SSZ
output_head: |
  <first 10-20 lines>
```
**Result**: pass | fail
**Notes**: <any issues or decisions>

---

## Decisions

| Date | Decision | Options | Rationale |
|------|----------|---------|-----------|
| YYYY-MM-DD | <what was decided> | A, B, C | <why> |

## Blockers

- [ ] <blocker description> — Status: open | resolved

## Self-Review Checkpoint

> Complete this section before marking work as done.

### Self-Review Checklist
- [ ] Re-read each acceptance criterion from spec.md
- [ ] Verified each criterion is met (not assumed)
- [ ] Checked: Did I add anything NOT in the spec?
- [ ] Checked: Would this pass code review?
- [ ] If ANY doubt exists, flagged for human review

### Confidence Assessment
**Overall Confidence**: High | Medium | Low

## Final Result
**Completed**: YYYY-MM-DD
**Summary**: <what was accomplished>
**All Acceptance Criteria Met**: Yes / No
**Self-Review Passed**: Yes / No
```

### 7.4 Frontmatter Contract

The `log.md` file MUST begin with YAML frontmatter containing machine-readable progress state:

```yaml
---
work_id: W-<id>           # Work item identifier
work_name: <name>         # Human-readable name
research_id: R-<id>|null  # Link to research if applicable
status: research|specify|implement|complete|blocked
current_task: T<n>        # Task ID currently in progress
tasks_completed: <n>      # Count of completed tasks
tasks_total: <n>          # Total tasks in spec
started: YYYY-MM-DD       # Date work began
last_updated: ISO8601     # Last modification timestamp
blockers: []              # Array of blocker descriptions
---
```

**Update Rules**:
1. Update frontmatter BEFORE updating prose sections
2. `current_task` advances when a task is marked done
3. `tasks_completed` increments with each completed task
4. `status` changes at stage transitions
5. `last_updated` changes on every edit

**Source of Truth**: Frontmatter is authoritative. Prose summaries are for human readability. If they conflict, frontmatter wins.

---

## 8. Validation Contract

### 8.1 Primary Command

Default: `./tools/validate/validate.sh`

Override in `spec/project/techstack.md` (repo-relative paths only).

The validation script MUST:
- Run lint/format checks
- Run relevant tests
- Exit non-zero on failure
- Print actionable errors

### 8.2 Target

- Fast local validation: < 2 minutes
- If CI is slow, create a local fast subset

### 8.3 Evidence

Every task logs validation in `log.md` using this structured format:

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
**Result**: pass | fail

**Required elements**:
- Exact command (not paraphrased)
- Exit code (not just "passed")
- Timestamp (for audit trail)
- Output head OR tail (at least one required; include both for long outputs)

**No validation = not done.**

### 8.4 Acceptance Criteria Format (v6)

Use **Given/When/Then** format for all acceptance criteria:

```markdown
### AC-01: <Descriptive name>
- **Given** <precondition or initial state>
- **When** <action or trigger>
- **Then** <observable outcome>
- **And** <additional outcome> (optional)
```

**Why this format**:
- Testable: Each criterion maps to a verification step
- Unambiguous: No room for interpretation
- Traceable: Log can reference AC-01, AC-02, etc.

**Example**:
```markdown
### AC-01: Invalid credentials rejected
- **Given** a user with invalid credentials
- **When** they attempt to log in
- **Then** the system returns HTTP 401
- **And** displays "Invalid username or password"
```

### 8.5 Uncertainty Markers (v6)

When specifications are incomplete, agents MUST use explicit markers rather than guessing:

| Marker | Meaning | Action |
|--------|---------|--------|
| `[NEEDS CLARIFICATION: <question>]` | Human input required | STOP and ask |
| `[ASSUMPTION: <assumption>]` | Proceeding with assumption | Document and continue |
| `[TBD: <topic>]` | Decision deferred | Continue with other work |

**Rules**:
- Agents MUST NOT proceed past `[NEEDS CLARIFICATION]` without human input
- `[ASSUMPTION]` requires documentation in log.md Decisions section
- `[TBD]` items must be tracked as follow-ups

**Example**:
```markdown
## Authentication
The system SHALL use [NEEDS CLARIFICATION: OAuth 2.0 or JWT?] for token management.

[ASSUMPTION: Session timeout is 30 minutes based on industry standard]
```

### 8.6 Language Conventions (v6)

Use normative language for clarity in specifications:

| Term | Meaning | Example |
|------|---------|---------|
| **SHALL/MUST** | Mandatory requirement | "The API SHALL return 401 on invalid credentials" |
| **SHOULD** | Recommended but not required | "The UI SHOULD show loading indicator" |
| **MAY** | Optional | "The API MAY cache responses" |

---

## 9. MDAP Principles (Simplified)

### Atomic Tasks
- Each task implements ONE thing
- Each task touches at most 1-2 files
- If you can't verify with ≤3 commands, decompose further

### Explicit State
- All inputs come from files, not memory
- All outputs go to files
- Agent = pure function on files

### Red Flags (Discard + Retry)
- Malformed or off-format output
- Abnormally long response for small change
- Output doesn't match spec

### Git Discipline

**Commit Protocol**:
1. Before starting a task: ensure working tree is clean
2. After task passes validation: commit with message `T<n>: <task name>`
3. Never commit failing code

**Rollback Protocol**:
1. If validation fails after changes: `git checkout -- <files>`
2. If task is partially complete: `git stash` before retry
3. If multiple tasks need rollback: `git revert` to last good commit

**Recovery States**:

| State | Detection | Recovery |
|-------|-----------|----------|
| Validation failed | Non-zero exit | Revert changes, retry task |
| Partial implementation | Blocker logged | Stash, reassess, retry or decompose |
| Wrong approach | Human review | Revert to pre-task commit, re-spec |
| Corrupted state | Tests pass but wrong behavior | Revert to last known-good, full re-test |

**Never**:
- Force push to shared branches
- Commit code that fails validation
- Skip the commit step between tasks
- Amend commits after pushing

---

## 10. Handoff Protocol

```
[Need clarity?] → Researcher → research.md
                      ↓
              (human approval)
                      ↓
              Researcher → spec.md
                      ↓
              (human approval)
                      ↓
              Implementer → code + log.md
                      ↓
              (human checkpoint per task)
                      ↓
              Reviewer → approve/reject
                      ↓
              Documenter → docs/
```

**Shortcuts**:
- Simple work: Skip research, go straight to spec
- Trivial work: Skip spec, implement and log

---

## 11. Definition of Done

### Research Done
- `research.md` exists with findings and recommendation
- Research Acceptance Criteria checklist completed (v6)
- Human approved

### Spec Done
- `spec.md` exists with files, tasks, and validation
- Acceptance criteria in Given/When/Then format (v6)
- Intent section included if complexity 4-5 (v6)
- Human approved

### Work Done
- All tasks in spec completed
- All validation passing
- `log.md` has evidence for each task
- Self-Review Checkpoint completed with confidence rating (v6)
- Human approved final result

---

## 12. Quick Reference

### Starting New Work

```bash
# Complex: Research first
mkdir -p spec/research/R-001--feature-name
# → Write brief.md, then research.md

# Simple: Straight to spec
mkdir -p spec/work/W-001--feature-name
# → Write spec.md, then implement
```

### Agent Commands

```
Research: "Read the brief and research this topic. Output research.md."
Specify: "Based on the research, write spec.md for implementation."
Implement: "Execute task 1 from spec.md. Run validation. Log results."
```

### Validation Ritual

After every change:
1. Run `./tools/validate/validate.sh`
2. Log command + output in `log.md`
3. Stop if failed; continue if passed

---

## Appendix A: Migration from v5

| v5 | v6 |
|----|----|
| Checkbox acceptance criteria | Given/When/Then format |
| No intent section | Optional Intent (required for complexity 4-5) |
| No self-review | Self-Review Checkpoint in log.md |
| No research AC | Research Acceptance Criteria checklist |
| Implicit uncertainty | Explicit `[NEEDS CLARIFICATION]` markers |
| Informal language | Normative language (SHALL/MUST/SHOULD) |

**V6 Philosophy**: V6 = V5 + Formalization (without overhead)

**Backwards Compatibility**:
- All v5 specs remain valid in v6
- New sections are additive, not breaking
- Intent section only required for complexity 4-5
- Self-review is mandatory but lightweight

**Migration Steps**:
1. Update AGENTS.md to v6
2. Update templates in `spec/templates/`
3. Existing work items continue as-is
4. New work items use v6 format

---

## Appendix B: Migration from v3 (Historical)

| v3 | v4/v5 |
|----|-------|
| `spec/discovery/` | `spec/research/` |
| `ideations/` + `definitions/` | Single `research.md` |
| `spec/tracks/` | `spec/work/` |
| 6 track files | 2 files: `spec.md` + `log.md` |
| Specifier + Planner | Researcher |

The v4/v5 simplification:
- Fewer files, same principles
- Context window optimized
- Graduated ceremony for different work sizes

---

## 13. Safety Hooks

V6 includes automated safety hooks that enforce critical guardrails. These hooks run automatically and cannot be bypassed by agents.

### 13.1 Blocked Operations

The following operations are **blocked by hooks** (not just documented):

| Operation | Why Blocked | Alternative |
|-----------|-------------|-------------|
| `git checkout main/master` | Prevents accidental main branch work | Create feature branch first |
| `git push --force` | Prevents history destruction | Regular push or rebase |
| `rm -rf` | Prevents catastrophic deletion | Use `rm -r` (no force) |
| `git reset --hard` | Prevents work loss | Use `git stash` |
| `git clean -f` | Prevents untracked file loss | Use `git clean -n` first |
| Write to `.env*` | Prevents credential exposure | Ask human to edit |
| Write to `AGENTS.md` | Prevents governance corruption | Ask human to edit |
| Write to `.claude/*` | Prevents hook tampering | Ask human to edit |

### 13.2 Session Exit Check

When a session ends, the agent receives a warning if:
- There are uncommitted changes in the working tree
- There are staged but uncommitted files

This is a **warning only** - it does not block session termination.

### 13.3 Hook Configuration

Hooks are defined in `.claude/settings.json` and scripts in `.claude/hooks/`. These files are protected and cannot be modified by agents.

### 13.4 When Hooks Block You

If a hook blocks an operation you believe is legitimate:
1. **Do not attempt to bypass** - hooks exist for safety
2. **Document the situation** in your log.md
3. **Ask the human** to perform the operation manually
4. **Continue with other work** while waiting

Attempting to bypass hooks (e.g., by modifying `.claude/` files) will itself be blocked.
