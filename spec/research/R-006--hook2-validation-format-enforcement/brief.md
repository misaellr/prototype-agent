# Brief: Hook 2 - Validation Format Enforcement

**Date**: 2026-02-01
**Requested by**: Human

## Goal

Define exact requirements for a hook that enforces validation evidence format in log.md task entries, ensuring compliance with AGENTS.md Section 8.3.

## Key Questions

1. What are the required and optional fields in the validation YAML block?
2. What format constraints apply (timestamp format, exit_code type)?
3. What edge cases must be handled (in-progress tasks, multiple blocks, research phase)?
4. Should this be a `prompt` or `command` type hook?
5. When should the hook block vs. allow?
