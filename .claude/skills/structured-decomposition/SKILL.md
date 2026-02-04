---
name: structured-decomposition
description: Reduces omission risk via deterministic scaffold of facts, assumptions, decomposition, synthesis, verification. Use by default for non-trivial tasks.
---

# Structured Decomposition (Zero-Shot Reasoning Scaffold)

## Purpose
Reduce omission risk by forcing a deterministic scaffold: facts, assumptions, decomposition, synthesis, verification.

## Runtime policy (when to run)
Run SK-007 by default for any task that is not trivial.

Skip only if:
- The user requests a short direct answer AND the task is genuinely trivial.

## Inputs
Required:
- `problem_statement`

Optional:
- `known_facts`
- `constraints`
- `desired_output_format`

## Procedure
1. **S1 Fill Scaffold**:
   - problem definition
   - known information
   - assumptions
   - subproblems
   - analysis per subproblem
   - synthesis
   - verification
2. **S2 Finalize**:
   - final answer
   - confidence
   - critical assumptions

## Stop conditions
- `max_iterations = 1`

## Outputs
Primary:
- `final_answer`

Artifacts:
- `filled_scaffold`
- `critical_assumptions`
- `verification_notes`

## Audit (SkillRunRecord)
Include:
- critical_assumptions
- verification_notes

## Guardrails
- If facts are missing, mark as assumptions.
- Do not invent evidence.

## Failure modes
- **Performative scaffolding**: mitigated by mandatory verification_notes linked to constraints.
