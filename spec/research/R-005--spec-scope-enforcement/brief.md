# Brief: Spec Scope Enforcement Hook

**Date**: 2026-02-01
**Researcher**: Agent

## Goal

Define requirements for Hook 3: Spec Scope Enforcement, which blocks edits to files not listed in the active spec.md "Files to Change" section.

## Questions to Answer

1. How to locate the active spec.md file
2. How to parse the "Files to Change" section
3. How to handle edge cases (no spec, multiple specs, special files)
4. What tools should be hooked (Edit, Write, or both)
5. When to allow vs block edits

## Context

This hook enforces the v6 workflow by ensuring the Implementer agent only modifies files explicitly listed in the approved spec. This prevents scope creep and unplanned changes.
