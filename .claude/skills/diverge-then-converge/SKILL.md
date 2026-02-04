---
name: diverge-then-converge
description: Generates breadth via exploration then converges on selection with calibrated confidence. Use for ideation, uncertainty, or when multiple candidate solutions are needed.
---

# Diverge-Then-Converge (Temperature Simulation)

## Purpose
Generate breadth (exploration) and then converge (selection) with calibrated confidence.

## Runtime policy (when to run)
Run SK-010 if ANY condition is true:
- `uncertainty >= med`
- ideation is required before a decision
- you need multiple candidate solutions/options

## Inputs
Required:
- `problem`
- `constraints`
- `evaluation_criteria`

Optional:
- `risk_tolerance`

## Procedure
1. **S1 Diverge**: generate 5–7 options; for each, list primary failure reasons.
2. **S2 Converge**: score options against criteria and select top option; justify.
3. **S3 Calibrate**: confidence per component + unknowns + next validation step.

## Stop conditions
- `max_iterations = 1`
- Cap options to 7 unless user requests more.

## Outputs
Primary:
- `selected_option`

Artifacts:
- `option_set`
- `failure_notes`
- `scored_matrix`
- `confidence_table`
- `next_steps`

## Audit (SkillRunRecord)
Include:
- scoring criteria
- scored matrix
- confidence table

## Guardrails
- Do not invent facts to boost options; mark unknowns explicitly.

## Failure modes
- **Option explosion**: mitigated by strict cap.
