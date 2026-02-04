---
work_id: W-<id>
work_name: <name>
research_id: null
status: research | specify | implement | complete | blocked
current_task: T1
tasks_completed: 0
tasks_total: <number>
started: YYYY-MM-DD
last_updated: YYYY-MM-DDTHH:MM:SSZ
blockers: []
---

# Log: <work name>

> Location: `spec/work/W-<id>--<name>/log.md`
>
> This log captures **all session activity** across the 3-stage workflow.
> Each stage appends to this file, preserving the full history.

**Progress**: Task 1 of <total> (0% complete)

**Spec**: `spec.md`
**Research**: `spec/research/R-<id>--<topic>/` *(if applicable)*

---

## Stage 1: Research Import

> *Skip this section if no research was performed. Import summary from research.md (max 10 lines).*

**Source**: `spec/research/R-<id>--<topic>/research.md`

**Key Findings**:
- <finding 1>
- <finding 2>
- <finding 3>

**Approaches Evaluated**:
| Approach | Verdict | Reason |
|----------|---------|--------|
| <approach A> | Rejected | <why> |
| <approach B> | Selected | <why> |

**Critical Decisions**:
| Decision | Rationale |
|----------|-----------|
| <decision> | <why> |

---

## Stage 2: Specify

### Session: YYYY-MM-DD HH:MM

**Input**: <research.md or direct request>

**Files Examined**:
| File | Purpose |
|------|---------|
| `path/to/file.ts` | <why we looked at it> |

**Implementation Decisions**:
| Decision | Alternatives | Rationale |
|----------|--------------|-----------|
| <what we decided> | <other options> | <why this choice> |

**Output**: `spec.md` created

---

## Stage 3: Implement

### YYYY-MM-DD HH:MM — Task 1: <name>

**Status**: done | blocked

**Changes**:
- `path/to/file.ts` — <what changed>

**Validation**:
```yaml
command: "<exact command run>"
exit_code: 0
timestamp: YYYY-MM-DDTHH:MM:SSZ
output_head: |
  <first 10-20 lines of output>
output_tail: |
  <last 10-20 lines of output>
```

**Result**: pass | fail

**Notes**: <any issues, decisions, or observations>

---

### YYYY-MM-DD HH:MM — Task 2: <name>

**Status**: <status>

**Changes**:
- <files>

**Validation**:
```yaml
command: "<command>"
exit_code: 0
timestamp: YYYY-MM-DDTHH:MM:SSZ
output_head: |
  <output>
output_tail: |
  <output>
```

**Result**: <pass/fail>

**Notes**: <notes>

---

## Decisions Summary

> All decisions across all stages, for quick reference

| Date | Stage | Decision | Rationale |
|------|-------|----------|-----------|
| YYYY-MM-DD | Research | <decision> | <why> |
| YYYY-MM-DD | Specify | <decision> | <why> |
| YYYY-MM-DD | Implement | <decision> | <why> |

---

## Blockers

| Issue | Stage | Status | Resolution |
|-------|-------|--------|------------|
| <description> | <stage> | open / resolved | <how resolved> |

---

## Self-Review Checkpoint

> *Complete this section before marking work as done. This is NOT optional.*

### Acceptance Criteria Verification

| AC ID | Criterion | Met? | Evidence |
|-------|-----------|:----:|----------|
| AC-01 | <from spec> | Yes/No | <where verified> |
| AC-02 | <from spec> | Yes/No | <where verified> |
| AC-03 | <from spec> | Yes/No | <where verified> |

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
| Test coverage | High/Med/Low | <notes> |
| Edge cases handled | High/Med/Low | <notes> |
| No regressions | High/Med/Low | <notes> |

> **If confidence is Medium or Low on any aspect, request human review before proceeding.**

---

## Final Result

**Completed**: YYYY-MM-DD

**Summary**: <1-2 sentences: what was accomplished>

**All Acceptance Criteria Met**: Yes / No

**Self-Review Passed**: Yes / No

**Follow-ups**: <any future work identified>
