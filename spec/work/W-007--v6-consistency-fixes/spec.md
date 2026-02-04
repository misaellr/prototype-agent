# Spec: V6 Consistency Fixes

> Location: `spec/work/W-007--v6-consistency-fixes/spec.md`

**Date**: 2026-02-01
**Status**: Draft
**Complexity**: 3
**Research**: `spec/research/R-004--v6-implementation-gaps/research.md`

---

## Context

The V6 implementation updated the primary template files but missed secondary locations where template content is duplicated (AGENTS.md Section 7) and version references exist (.claude/agents/*.md). This creates inconsistency where different documentation locations show V5 vs V6 format.

---

## Intent (required for complexity 4-5, optional for 2-3, skip for 0-1)

> *Including Intent section for traceability since this affects multiple files.*

### Problem

After V6 implementation, agents reading AGENTS.md Section 7 see V5 templates (checkbox AC, no Intent section, no Self-Review), while agents using `spec/templates/*.md` see V6 format. Agent role files reference v4 instead of v6.

### Use Cases

| ID | As a... | I want... | So that... |
|----|---------|-----------|------------|
| UC-01 | Agent reading AGENTS.md | Consistent V6 guidance in Section 7 | I don't produce V5-format artifacts |
| UC-02 | Agent assuming a role | Role file to reference v6 | I follow correct protocol |
| UC-03 | Implementer agent | Self-Review guidance in my role file | I follow V6 self-review protocol |

### Capabilities

| ID | Capability | Solves |
|----|------------|--------|
| CAP-01 | Section 7 templates match spec/templates/*.md | UC-01 |
| CAP-02 | Agent role files reference v6 | UC-02 |
| CAP-03 | Implementer role includes Self-Review | UC-03 |

---

## Files to Change

### Create

| File | Purpose |
|------|---------|
| None | No new files needed |

### Modify

| File | Changes |
|------|---------|
| `AGENTS.md` | Update Section 7.1 (research.md template) to V6 format |
| `AGENTS.md` | Update Section 7.2 (spec.md template) to V6 format |
| `AGENTS.md` | Update Section 7.3 (log.md template) to V6 format |
| `.claude/agents/researcher.md` | Change v4 → v6, add Research AC reference |
| `.claude/agents/implementer.md` | Change v4 → v6, add Self-Review Protocol |
| `.claude/agents/reviewer.md` | Change v4 → v6 |
| `.claude/agents/documenter.md` | Change v4 → v6 |
| `.claude/agents/janitor.md` | Change v4 → v6 |

---

## Tasks

### T1: Update AGENTS.md Section 7.1 (research.md template)

- **File**: `AGENTS.md`
- **Lines**: 370-405
- **Changes**:
  - Add `## Research Acceptance Criteria` section with 5-item checklist
  - Add `**Completion Confidence**: High | Medium | Low`
  - Add uncertainty markers guidance in Open Questions section
- **Validation**: `grep -A 10 "Research Acceptance" AGENTS.md | head -15`

### T2: Update AGENTS.md Section 7.2 (spec.md template)

- **File**: `AGENTS.md`
- **Lines**: 407-452
- **Changes**:
  - Add `**Complexity**: <0-5>` to frontmatter
  - Add `## Intent (required for complexity 4-5)` section with Problem, Use Cases, Capabilities
  - Replace checkbox AC with Given/When/Then format:
    ```
    ### AC-01: <Descriptive name>
    - **Given** <precondition>
    - **When** <action>
    - **Then** <outcome>
    ```
  - Add uncertainty markers guidance in Notes section
- **Validation**: `grep -A 5 "Given.*When.*Then\|AC-01" AGENTS.md`

### T3: Update AGENTS.md Section 7.3 (log.md template)

- **File**: `AGENTS.md`
- **Lines**: 454-486
- **Changes**:
  - Add `## Self-Review Checkpoint` section with:
    - AC Verification table
    - Self-Review Checklist (5 items)
    - Confidence Assessment
  - Add `**Self-Review Passed**: Yes / No` to Final Result
- **Validation**: `grep -A 10 "Self-Review Checkpoint" AGENTS.md`

### T4: Update .claude/agents/researcher.md

- **File**: `.claude/agents/researcher.md`
- **Line**: 9
- **Changes**:
  - Change `v4` to `v6`
  - Add to Stage 1 workflow: "6. Complete Research Acceptance Criteria checklist"
  - Add note: "Research is done when AC checklist is complete, not when time expires"
- **Validation**: `grep "v6\|Research Acceptance" .claude/agents/researcher.md`

### T5: Update .claude/agents/implementer.md

- **File**: `.claude/agents/implementer.md`
- **Line**: 9
- **Changes**:
  - Change `v4` to `v6`
  - Add new section after "Checkpoint":
    ```
    6. **Self-Review** (before marking complete)
       - Re-read each acceptance criterion
       - Verify each is met (not assumed)
       - Check: Did I add anything NOT in spec?
       - Assign confidence: High | Medium | Low
       - If Medium/Low, request human review
    ```
- **Validation**: `grep -A 10 "Self-Review\|v6" .claude/agents/implementer.md`

### T6: Update .claude/agents/reviewer.md

- **File**: `.claude/agents/reviewer.md`
- **Line**: 9
- **Changes**: Change `v4` to `v6`
- **Validation**: `grep "v6" .claude/agents/reviewer.md`

### T7: Update .claude/agents/documenter.md

- **File**: `.claude/agents/documenter.md`
- **Line**: 9
- **Changes**: Change `v4` to `v6`
- **Validation**: `grep "v6" .claude/agents/documenter.md`

### T8: Update .claude/agents/janitor.md

- **File**: `.claude/agents/janitor.md`
- **Line**: 9
- **Changes**: Change `v4` to `v6`
- **Validation**: `grep "v6" .claude/agents/janitor.md`

### T9: Add sync reminder comment to AGENTS.md Section 7

- **File**: `AGENTS.md`
- **Line**: After line 368 (before Section 7.1)
- **Changes**: Add comment:
  ```
  > **Sync Notice**: These inline templates MUST stay synchronized with
  > `spec/templates/*.md`. When updating templates, update BOTH locations.
  ```
- **Validation**: `grep "Sync Notice" AGENTS.md`

---

## Validation

```bash
# Primary validation - check all v4 references are gone
grep -r "v4" .claude/agents/ && echo "FAIL: v4 references remain" || echo "PASS: No v4 references"

# Check V6 markers in Section 7
grep -c "Given.*When.*Then\|Self-Review\|Research Acceptance" AGENTS.md

# Check agent files reference v6
grep -l "v6" .claude/agents/*.md | wc -l  # Should be 5
```

---

## Acceptance Criteria

> *Use Given/When/Then format for testable, unambiguous criteria.*

### AC-01: Section 7.1 matches research-template.md

- **Given** the research.md template in Section 7.1 of AGENTS.md
- **When** compared to `spec/templates/research-template.md`
- **Then** Section 7.1 includes Research Acceptance Criteria section
- **And** Section 7.1 includes Completion Confidence field
- **And** Section 7.1 includes uncertainty markers guidance

### AC-02: Section 7.2 matches spec-template.md

- **Given** the spec.md template in Section 7.2 of AGENTS.md
- **When** compared to `spec/templates/spec-template.md`
- **Then** Section 7.2 includes Complexity field in frontmatter
- **And** Section 7.2 includes Intent section (marked as optional)
- **And** Section 7.2 uses Given/When/Then AC format (not checkboxes)
- **And** Section 7.2 includes uncertainty markers guidance

### AC-03: Section 7.3 matches log-template.md

- **Given** the log.md template in Section 7.3 of AGENTS.md
- **When** compared to `spec/templates/log-template.md`
- **Then** Section 7.3 includes Self-Review Checkpoint section
- **And** Section 7.3 includes Confidence Assessment
- **And** Section 7.3 Final Result includes Self-Review Passed field

### AC-04: All agent files reference v6

- **Given** the 5 agent role files in `.claude/agents/`
- **When** searching for version references
- **Then** all files reference "v6" (not v4 or v5)
- **And** zero files contain "v4" string

### AC-05: Implementer includes Self-Review guidance

- **Given** the implementer.md agent role file
- **When** reading the workflow section
- **Then** Self-Review steps are documented
- **And** confidence rating requirement is mentioned

### AC-06: Researcher includes Research AC guidance

- **Given** the researcher.md agent role file
- **When** reading the Stage 1 workflow
- **Then** Research Acceptance Criteria completion is required
- **And** research completion criteria are referenced

### AC-07: Sync notice added to Section 7

- **Given** AGENTS.md Section 7 "Artifact Templates"
- **When** reading the section header area
- **Then** a sync notice exists warning about dual maintenance

---

## Notes

**Why inline templates exist**: Section 7 provides quick reference for readers who want to understand the format without opening separate files. This is valuable for onboarding.

**Future prevention**: R-003 should have included a "Files to Change" section with grep-based discovery:
```bash
# Commands that would have found these issues:
grep -rn "template\|## Research\|## Spec\|## Log" AGENTS.md
grep -rn "v4\|v5" .claude/
```

> **Uncertainty markers** (use when spec is incomplete):
> - `[NEEDS CLARIFICATION: <question>]` — Human must answer before proceeding
> - `[ASSUMPTION: <assumption>]` — Proceeding with this assumption
> - `[TBD: <topic>]` — Decision deferred

No uncertainty markers needed - all requirements are clear.
