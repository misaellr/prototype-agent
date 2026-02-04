---
name: quality-bar-calibration
description: Standardizes quality by matching an exemplar or rubric. Use when outputs must match a quality standard or maintain consistency across multiple documents.
---

# Quality Bar Calibration (Reference Class / Exemplar Priming)

## Purpose
Standardize quality (structure, depth, actionability) across outputs by matching an exemplar or rubric.

## Runtime policy (when to run)
Run SK-008 if ANY condition is true:
- A high-quality exemplar is provided and the output must match its quality bar
- A rubric/standard must be applied consistently across multiple documents
- `multi_document_consistency >= med`

## Inputs
Required:
- `exemplar_or_rubric`
- `new_input`

Optional:
- `must_match_qualities_list`

## Procedure
1. **S1 Extract Features**: derive structure and quality features (sections, depth, evidence style).
2. **S2 Generate + Self-Check**: produce output and run a conformance check against features.

## Stop conditions
- `max_iterations = 1`

## Outputs
Primary:
- `calibrated_output`

Artifacts:
- `quality_features`
- `conformance_check`

## Audit (SkillRunRecord)
Include:
- quality_features
- conformance_check result

## Guardrails
- Emulate structure/quality; do not copy large verbatim text.
- If exemplar contains sensitive info, avoid replicating it.

## Failure modes
- **Overfitting to quirks**: mitigated by preferring rubric-based features.
