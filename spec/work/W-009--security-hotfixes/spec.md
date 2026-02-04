# Spec: Security Hotfixes for V6 Hooks

**Date**: 2026-02-02
**Status**: Approved
**Complexity**: 2
**Research**: Quick research from multi-agent testing (session-20260202)

## Context

Multi-agent security testing discovered a critical vulnerability (CRIT-01) and two high-severity issues (HIGH-01, HIGH-02) in the V6 hooks. This spec defines minimal hotfixes to close these vulnerabilities without breaking existing functionality.

## Complexity Assessment

| Dimension | Value | Score |
|-----------|-------|-------|
| Files touched | 2 | 1 |
| Lines of code | ~30 | 0 |
| Dependencies added | 0 | 0 |
| External integrations | 0 | 0 |
| Behavior change | Yes (stricter blocking) | 1 |
| **Total** | | **2** |

## Quick Research Summary

### CRIT-01: Override File Bypass

**Problem**: The `spec-scope-enforcement.sh` creates override files (`.scope-override-*`) that tell `protected-paths.sh` to allow edits. However, `spec.md` is always-allowed, so an agent can:
1. Edit spec.md to add `AGENTS.md` to "Files to Change"
2. spec-scope creates override file
3. protected-paths sees override and allows edit to AGENTS.md

**Root Cause**: Override files are trusted unconditionally for ALL files.

**Fix**: Add NEVER-ALLOW list in `protected-paths.sh` that checks BEFORE override lookup. These files are blocked regardless of any override.

### HIGH-01: Symlink Attack

**Problem**: An agent could create `tests/agents-link.test.ts` as a symlink to `../AGENTS.md`. The `tests/**/*` always-allowed pattern would match, but the write would target AGENTS.md.

**Root Cause**: Path checks use the provided path, not the resolved target.

**Fix**: Add `realpath` resolution in `spec-scope-enforcement.sh` before checking always-allowed patterns.

### HIGH-02: Self-Modifying Spec (Deferred)

**Problem**: spec.md can be edited during implement status, allowing scope expansion.

**Decision**: DEFER to future work. The CRIT-01 fix addresses the most dangerous outcome (protected file modification). Making spec.md read-only during implement would require coordination with the specify→implement transition and has UX implications.

## Files to Change

### Modify

- `.claude/hooks/protected-paths.sh` — Add NEVER-ALLOW list before override check
- `.claude/hooks/spec-scope-enforcement.sh` — Add symlink resolution

## Tasks

### T1: Add NEVER-ALLOW list to protected-paths.sh

- File: `.claude/hooks/protected-paths.sh`
- Changes:
  - Add `NEVER_ALLOW_PATTERNS` array with governance/credential files
  - Add check BEFORE override file lookup (line ~32)
  - Patterns: `AGENTS.md`, `.env*`, `.claude/*`, `credentials*`, `secrets*`
- Validation: `bash -n .claude/hooks/protected-paths.sh && echo "Syntax OK"`

**Implementation Sketch**:
```bash
# NEVER-ALLOW patterns - checked BEFORE override lookup
# These files cannot be edited regardless of spec approval
NEVER_ALLOW_PATTERNS=(
    "^AGENTS\.md$"
    "^\.env"
    "^\.claude/"
    "^credentials"
    "^secrets"
)

# Check NEVER-ALLOW list (no override can bypass this)
for pattern in "${NEVER_ALLOW_PATTERNS[@]}"; do
    if [[ "$FILE_PATH" =~ $pattern ]] || [[ "$FILENAME" =~ $pattern ]]; then
        echo "BLOCKED: '$FILE_PATH' is a governance/credential file (no override allowed)" >&2
        exit 2
    fi
done
```

### T2: Add symlink resolution to spec-scope-enforcement.sh

- File: `.claude/hooks/spec-scope-enforcement.sh`
- Changes:
  - Add symlink resolution after path normalization
  - Use `realpath -m` (doesn't require file to exist) or fallback
  - Apply resolved path to always-allowed checks
- Validation: `bash -n .claude/hooks/spec-scope-enforcement.sh && echo "Syntax OK"`

**Implementation Sketch**:
```bash
# Resolve symlinks if file exists
resolve_symlinks() {
    local path="$1"
    if [[ -L "$path" ]] || [[ -e "$path" ]]; then
        # Use realpath if available, otherwise readlink -f
        if command -v realpath &>/dev/null; then
            realpath -m "$path" 2>/dev/null || echo "$path"
        elif command -v readlink &>/dev/null; then
            readlink -f "$path" 2>/dev/null || echo "$path"
        else
            echo "$path"
        fi
    else
        echo "$path"
    fi
}

# After normalize_path, resolve symlinks
resolved_path=$(resolve_symlinks "$normalized_path")
```

## Validation

```bash
# Syntax check modified hooks
bash -n .claude/hooks/protected-paths.sh && echo "protected-paths.sh: OK"
bash -n .claude/hooks/spec-scope-enforcement.sh && echo "spec-scope-enforcement.sh: OK"

# Test CRIT-01 fix: Override should NOT bypass NEVER-ALLOW
# (manual: create override file, attempt edit to AGENTS.md, expect BLOCKED)

# Test HIGH-01 fix: Symlink should be resolved
# (manual: create symlink in tests/, attempt edit, expect resolved path used)
```

## Acceptance Criteria

### AC-01: NEVER-ALLOW blocks AGENTS.md regardless of override

- **Given** a fresh override file exists for AGENTS.md path
- **When** protected-paths.sh is invoked with AGENTS.md
- **Then** the edit is BLOCKED with "governance/credential file" message
- **And** exit code is 2

### AC-02: NEVER-ALLOW blocks .env files regardless of override

- **Given** a fresh override file exists for .env.local path
- **When** protected-paths.sh is invoked with .env.local
- **Then** the edit is BLOCKED
- **And** exit code is 2

### AC-03: Symlinks resolved before always-allowed check

- **Given** a symlink `tests/link.test.ts` pointing to `../AGENTS.md`
- **When** spec-scope-enforcement.sh is invoked with the symlink path
- **Then** the resolved path (AGENTS.md) is used for checking
- **And** the edit is BLOCKED (not always-allowed)

### AC-04: Normal spec-listed files still work

- **Given** a spec.md that lists `src/feature.ts`
- **When** an agent edits `src/feature.ts`
- **Then** the edit is ALLOWED (existing behavior preserved)

### AC-05: Test files still always-allowed

- **Given** no active spec
- **When** an agent creates `tests/new.test.ts` (not a symlink)
- **Then** the edit is ALLOWED (always-allowed preserved)

## Notes

- HIGH-02 (self-modifying spec) is deferred - address in future iteration
- NEVER-ALLOW is checked BEFORE override to prevent any bypass
- Symlink resolution uses best-effort (realpath → readlink → passthrough)
- Existing functional behavior must be preserved
