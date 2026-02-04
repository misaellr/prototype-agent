---
name: boundary-case-pack
description: Generates high-leverage edge cases and validates solutions against them. Use for classification, validation, parsing, migration, or rules-based decisioning tasks.
---

# Boundary Case Pack (Strategic Edge-Case Learning)

## Purpose
Generate a small suite of high-leverage edge cases and validate a solution/classifier against them.

## Runtime policy (when to run)
Run SK-003 if ANY condition is true:
- The task is classification, validation, parsing, migration, or rules-based decisioning
- The system is prone to “looks correct” failures (subtle boundary conditions)
- You need fixtures/tests to prevent regressions

## Inputs
Required:
- `task_definition`
- `categories_or_constraints`
- `candidate_solution_or_classifier`

Optional:
- `known_failure_modes`
- `prior_incidents`

## Procedure
1. **S1 Themes**: identify 3 failure-mode themes (boundary, deceptive, ambiguous).
2. **S2 Suite**: create 6–12 minimal fixtures with expected outcomes.
3. **S3 Evaluate**: run the candidate logic against the suite; record mismatches.
4. **S4 Patch**: update guidance/logic; re-run suite once.

## Stop conditions
- `max_iterations = 2`
- Cap fixtures to 12 unless user requests more.

## Outputs
Primary:
- `patched_guidance_or_logic`

Artifacts:
- `edge_case_suite`
- `evaluation_report`
- `post_patch_report`

## Audit (SkillRunRecord)
Include:
- fixtures count
- mismatches
- patch summary

## Guardrails
- Avoid generating harmful payloads; keep fixtures safe and relevant.
- Tie at least 2 fixtures to real constraints/incidents when available.

## Failure modes
- **Synthetic suite**: mitigated by grounding fixtures in real constraints/incidents.
- **Fixture explosion**: mitigated by strict caps.
