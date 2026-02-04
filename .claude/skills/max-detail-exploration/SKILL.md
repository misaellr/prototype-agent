---
name: max-detail-exploration
description: Exposes full reasoning surface with implementation details, edge cases, failure modes, and alternatives. Use for deep exploration of novel or complex domains.
---

# Max-Detail Exploration (Deliberate Over-Instruction)

## Purpose
Expose the full reasoning surface: implementation details, edge cases, failure modes, and alternatives.

## Runtime policy (when to run)
Run SK-006 if:
- `novelty = high` OR `decision_tradeoff >= med`, AND
- The user explicitly requests deep exploration (not summaries)

## Inputs
Required:
- `question`
- `context`
- `constraints`

Optional:
- `sections_to_include`
- `exclusions`

## Procedure
1. **S1 Deep Dive**: generate a structured deep analysis with mandated sections:
   - implementation details
   - edge cases & exceptions
   - failure modes
   - tradeoffs & alternatives
   - precedents (optional)
2. **S2 Decision Index**: output a decision_points list and recommended next validations.

## Stop conditions
- `max_iterations = 1`

## Outputs
Primary:
- `deep_dive`

Artifacts:
- `toc`
- `decision_points`
- `next_validations`

## Audit (SkillRunRecord)
Include:
- toc
- decision_points
- unresolved items

## Guardrails
- Avoid unsafe/forbidden detail; keep content informational.
- Stay within scope; do not “research” unless explicitly requested.

## Failure modes
- **Verbose but not actionable**: mitigated by mandatory decision_points.
