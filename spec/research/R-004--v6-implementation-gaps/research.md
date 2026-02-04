# Research: V6 Implementation Gaps

> Location: `spec/research/R-004--v6-implementation-gaps/research.md`

**Date**: 2026-02-01
**Status**: Complete

---

## Problem

The V6 implementation updated the primary template files (`spec/templates/*.md`) and key AGENTS.md sections, but failed to update secondary locations where template content is duplicated or referenced. This creates inconsistency where agents reading different parts of the documentation get different (V5 vs V6) guidance.

---

## Codebase Findings

Files and patterns relevant to this work:

| File | Relevance |
|------|-----------|
| `AGENTS.md:370-486` | Section 7 "Artifact Templates" contains INLINE copies of all three templates in V5 format |
| `AGENTS.md:449-451` | Checkbox AC format `- [ ] <testable statement>` instead of Given/When/Then |
| `.claude/agents/researcher.md:9` | References "v4" instead of "v6" |
| `.claude/agents/implementer.md:9` | References "v4" instead of "v6", missing Self-Review |
| `.claude/agents/reviewer.md:9` | References "v4" instead of "v6" |
| `.claude/agents/documenter.md:9` | References "v4" instead of "v6" |
| `.claude/agents/janitor.md:9` | References "v4" instead of "v6" |

---

## Root Cause Analysis

### Why R-003 Specification Missed These

| Root Cause | Evidence | Impact |
|------------|----------|--------|
| **No comprehensive grep for template content** | R-003 Section 5 lists specific sections (8.3, 5.2, 6.2) but didn't search for all template occurrences | Section 7 inline templates missed |
| **No grep for version strings** | R-003 didn't include `grep -r "v4\|v5"` in analysis | Agent files missed |
| **Focus on "what to add" not "what to update"** | R-003 specified new sections but didn't inventory existing content | Duplication not identified |
| **Template files treated as single source of truth** | Assumption that updating `spec/templates/*.md` was sufficient | AGENTS.md Section 7 copies not recognized |

### Content Duplication Map

```
Template Content Locations:
├── spec/templates/spec-template.md     ← PRIMARY (updated to V6)
├── spec/templates/research-template.md ← PRIMARY (updated to V6)
├── spec/templates/log-template.md      ← PRIMARY (updated to V6)
├── AGENTS.md Section 7.1               ← DUPLICATE (still V5) ❌
├── AGENTS.md Section 7.2               ← DUPLICATE (still V5) ❌
├── AGENTS.md Section 7.3               ← DUPLICATE (still V5) ❌
└── .claude/agents/*.md                 ← REFERENCES v4 ❌
```

---

## External References

| Source | Key Insight |
|--------|-------------|
| DRY Principle | "Every piece of knowledge must have a single, unambiguous representation" - violated by having templates in two places |
| R-003 plan.md | Original spec didn't include "Files to Change" section with grep-based discovery |

---

## Options

### Option A: Update All Duplicates

**Approach**: Update AGENTS.md Section 7 and all agent files to V6 format

**Pros**:
- Complete consistency
- Agents reading Section 7 get correct format
- Agent role files reference correct version

**Cons**:
- More files to maintain
- Future V7 must remember to update all locations

### Option B: Remove Section 7 Duplicates

**Approach**: Replace Section 7 inline templates with references to `spec/templates/*.md`

**Pros**:
- Single source of truth
- Future updates only need one location
- AGENTS.md becomes shorter

**Cons**:
- Readers must open separate files to see templates
- Less convenient for quick reference

### Option C: Hybrid - Short Examples + References

**Approach**: Keep brief examples in Section 7 but mark as "abbreviated" with link to full templates

**Pros**:
- Quick reference preserved
- Clear that full templates are authoritative
- Easier to maintain

**Cons**:
- Still some duplication (risk of drift)

---

## Recommendation

**Chosen**: Option A (Update All Duplicates)

**Rationale**:
1. V5 had this same structure and it works - the issue is we forgot to update, not that the structure is wrong
2. Section 7 provides valuable quick reference for readers
3. The real fix is better specification process (grep-based discovery), not architecture change
4. Changing structure now adds risk; updating content is straightforward

**Additional**: Add a comment in AGENTS.md Section 7 noting that these must stay in sync with `spec/templates/*.md`.

---

## Research Acceptance Criteria

> *Research is "done" when these criteria are met, not when time expires.*

Before marking research complete, verify:

- [x] Found 3+ prior art examples or implementations — Found 8 affected locations
- [x] Identified trade-offs for 2+ approaches — 3 options analyzed
- [x] Recommended approach with clear rationale — Option A selected
- [x] Open questions documented (if any remain) — None
- [x] Scope is clear enough for specification phase — Yes, 8 files identified

**Completion Confidence**: High

---

## Open Questions

None. All affected files identified. Ready for specification.
