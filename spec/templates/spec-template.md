# Spec: <work name>

> Location: `spec/work/W-<id>--<name>/spec.md`

**Date**: YYYY-MM-DD
**Status**: Draft | Approved
**Complexity**: <0-5>
**Research**: `spec/research/R-<id>--<topic>/research.md` *(if applicable)*

---

## Context

<1-2 sentences: what we're building and why>

---

## Intent (required for complexity 4-5, optional for 2-3, skip for 0-1)

> *This section captures the "why" behind the work. Include for complex changes to ensure traceability.*

### Problem

<2-3 sentences: what's broken or missing today>

### Use Cases

| ID | As a... | I want... | So that... |
|----|---------|-----------|------------|
| UC-01 | <role> | <action> | <benefit> |
| UC-02 | <role> | <action> | <benefit> |

### Capabilities

| ID | Capability | Solves |
|----|------------|--------|
| CAP-01 | <what system does> | UC-01 |
| CAP-02 | <what system does> | UC-02 |

---

## Files to Change

### Create

| File | Purpose |
|------|---------|
| `path/to/new-file.ts` | <why this file is needed> |

### Modify

| File | Changes |
|------|---------|
| `path/to/existing.ts` | <what to change> |

---

## Tasks

### T1: <name>

- **File**: `path/to/file.ts`
- **Changes**: <specific changes to make>
- **Validation**: `<command to verify>`

### T2: <name>

- **File**: `path/to/file.ts`
- **Changes**: <specific changes to make>
- **Validation**: `<command to verify>`

---

## Validation

```bash
# Primary validation (run after each task)
./tools/validate/validate.sh

# Specific tests for this work
<test command>
```

---

## Acceptance Criteria

> *Use Given/When/Then format for testable, unambiguous criteria.*

### AC-01: <Descriptive name>

- **Given** <precondition or initial state>
- **When** <action or trigger>
- **Then** <observable outcome>
- **And** <additional outcome> *(optional)*

### AC-02: <Descriptive name>

- **Given** <precondition or initial state>
- **When** <action or trigger>
- **Then** <observable outcome>

### AC-03: <Descriptive name>

- **Given** <precondition or initial state>
- **When** <action or trigger>
- **Then** <observable outcome>

---

## Notes

<any implementation hints, patterns to follow, or gotchas>

> **Uncertainty markers** (use when spec is incomplete):
> - `[NEEDS CLARIFICATION: <question>]` — Human must answer before proceeding
> - `[ASSUMPTION: <assumption>]` — Proceeding with this assumption
> - `[TBD: <topic>]` — Decision deferred
