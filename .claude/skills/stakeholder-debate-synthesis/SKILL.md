---
name: stakeholder-debate-synthesis
description: Surfaces competing priorities, critiques tradeoffs, synthesizes recommendations. Use for decisions spanning multiple stakeholders with competing goals.
---

# Stakeholder Debate & Synthesis (Multi-Persona Debate)

## Purpose
Surface competing priorities, critique tradeoffs, and synthesize a recommendation with explicit conditions and risks.

## Runtime policy (when to run)
Run SK-009 if:
- `decision_tradeoff = high`, OR
- The decision spans multiple stakeholders with competing goals (cost vs quality vs time, etc.)

## Inputs
Required:
- `topic`
- `personas_with_priorities` (2–4 personas)
- `constraints`

Optional:
- `decision_criteria_weights`

## Procedure
1. **S1 Positions**: each persona states a position (bounded length).
2. **S2 Critiques**: each persona critiques others; record agreement points and tensions.
3. **S3 Synthesis**:
   - recommendation
   - explicit tradeoffs
   - conditions to recommend differently
   - key risks

## Stop conditions
- `max_iterations = 1`

## Outputs
Primary:
- `recommendation`

Artifacts:
- `critique_matrix`
- `agreements`
- `tensions`
- `decision_conditions`
- `risks`

## Audit (SkillRunRecord)
Include:
- personas
- key tradeoffs
- decision conditions

## Guardrails
- Personas are analytical lenses, not manipulative roleplay.
- No fabricated facts; mark unknowns.

## Failure modes
- **False consensus**: mitigated by requiring explicit tensions output.
