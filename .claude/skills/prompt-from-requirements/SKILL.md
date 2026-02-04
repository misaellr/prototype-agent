---
name: prompt-from-requirements
description: Converts ambiguous goals into precise internal prompt specifications. Use when requirements are unclear, incomplete, or conflicting.
---

# Prompt-from-Requirements (Reverse Prompting)

## Purpose
Convert an ambiguous goal into a precise internal prompt specification and execute it once.

## Runtime policy (when to run)
Run SK-004 if:
- `ambiguity = high`, OR
- Inputs are incomplete/conflicting and a clean prompt spec would reduce churn

## Inputs
Required:
- `goal_statement`
- `output_requirements`
- `constraints`

Optional:
- `scoring_rubric`
- `examples`

## Procedure
1. **S1 Internal Prompt Spec**: define scope, exclusions, format, rubric, and verification hooks.
2. **S2 Execute Once**: run a single generation using the internal spec.
3. **S3 Assumptions & Questions**: emit explicit assumption_log + open_questions for missing constraints.

## Stop conditions
- `max_iterations = 1`

## Outputs
Primary:
- `result`

Artifacts:
- `internal_prompt_spec`
- `assumption_log`
- `open_questions`

## Audit (SkillRunRecord)
Include:
- internal prompt spec
- assumptions and open questions

## Guardrails
- Do not add hidden requirements; log assumptions explicitly.
- If ambiguity remains, do not “invent” user intent; ask targeted questions.

## Failure modes
- **Overfitting interpretation**: mitigated by mandatory open_questions when ambiguity persists.
