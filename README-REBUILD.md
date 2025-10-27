
# Spec‑Kit Rebuild Notes

This repo has been augmented with a canonical `.specify/` structure, JSON schemas, lint rules,
and a validator script. These additions harden reasoning gates and cross‑agent hand‑offs.

## What's new

- `.specify/memory/constitution.md` — governing policy (copied from `memory/constitution.md`).
- `.specify/schema/*.json` — advisory/enforcing schemas for plan/tasks + lint regex.
- `.specify/state/*.json` — placeholders for traceability, assumptions, and waivers.
- `templates/plan-evidence-template.md` — drop‑in table for Evidence‑to‑Decision Map.
- `scripts/validate_spec_kit.py` — simple gate validator for `spec.md`, `plan.md`, `tasks.md`.

## Quick usage

```bash
# Example validation of a feature folder:
python scripts/validate_spec_kit.py specs/001-*/spec.md specs/001-*/plan.md specs/001-*/tasks.md
```

If validation fails, fix the reported sections/IDs/RT mappings before handing off to Implementor.
