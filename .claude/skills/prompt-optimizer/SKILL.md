---
name: prompt-optimizer
description: Turns prompts into reusable assets by improving constraints, clarity, and reasoning scaffolds. Use when creating prompts for reuse by others or for repeated execution.
---

# Prompt Optimizer (Recursive Prompt Optimization)

## Purpose
Turn a prompt into a reusable asset by iteratively improving constraints, clarity, and reasoning scaffolds.

## Runtime policy (when to run)
Run SK-005 if ANY condition is true:
- `repeatability = high` (prompt will be reused)
- The prompt is intended for other users/agents
- You have a measurable rubric/tests and want to optimize quality

## Inputs
Required:
- `current_prompt`
- `goal`
- `evaluation_rubric`

Optional:
- `common_failures`
- `examples_of_good_output`

## Procedure
1. **V1 Constraint Addition**: add guardrails, required sections, exclusions.
2. **V2 Ambiguity Resolution**: replace vague instructions with operational definitions.
3. **V3 Reasoning/Verification**: add decomposition + checks; optionally reference SK-001 or SK-007 patterns.

For each version:
- show diff
- explain rationale
- provide full prompt text

## Stop conditions
- `max_iterations = 1`

## Outputs
Primary:
- `prompt_v3_ready`

Artifacts:
- `prompt_v1`, `prompt_v2`
- `diff_v1`, `diff_v2`, `diff_v3`
- `rationale_notes` (include a “minimal viable prompt” variant)

## Audit (SkillRunRecord)
Include:
- diffs
- rubric used
- rationale

## Guardrails
- Do not expand scope beyond the stated goal.
- Avoid unsafe capabilities; preserve security constraints.

## Failure modes
- **Prompt bloat**: mitigated by requiring minimal viable variant.
