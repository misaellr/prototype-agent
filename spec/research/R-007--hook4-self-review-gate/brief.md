# Research Brief: Hook 4 — Self-Review Gate

**Date**: 2026-02-01
**Requested by**: User

## Goal

Define requirements for a hook that blocks session completion (Stop event) during implementation unless the Self-Review Checkpoint in log.md is properly completed.

## Questions to Answer

1. What sections of the Self-Review Checkpoint must be filled?
2. How to detect "completed" vs "template placeholder"?
3. What confidence level triggers human review flag?
4. What edge cases need handling (research phase, spec phase, early implementation)?
5. Should this be an `agent` hook (can read files) or `prompt` hook?

## Context

The Self-Review Protocol (AGENTS.md Section 6.2) requires Implementers to complete a Self-Review Checkpoint before marking work complete. This hook enforces that requirement programmatically.
