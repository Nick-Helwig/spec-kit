
import re, sys, json, pathlib

RULES = {
    "tasks_line": re.compile(r"^- \[[ X]\] T\d{3}\s(\[P\d?\]\s)?\[US-\d{3}\]\s.+")
}

def scan_file(path, patterns):
    txt = pathlib.Path(path).read_text(encoding="utf-8", errors="ignore")
    errors = []
    for name, pat in patterns.items():
        if name.startswith("heading:"):
            if not re.search(pat, txt, flags=re.MULTILINE):
                errors.append(f"Missing heading: {pat}")
    return errors

def validate_spec_md(path):
    txt = pathlib.Path(path).read_text(encoding="utf-8", errors="ignore")
    errs = []
    heads = [
        r"^##\s+Clarifications \(Resolved\)",
        r"^##\s+Assumptions \(Must Validate in Research\)",
        r"^##\s+Requirements",
        r"^##\s+Success Criteria",
        r"^##\s+Definition of Ready — Spec",
    ]
    for h in heads:
        if not re.search(h, txt, flags=re.MULTILINE):
            errs.append(f"[spec] Missing heading: {h}")
    # ID samples
    for tag in ["FR-", "SC-", "US-"]:
        if re.search(fr"{tag}\d\b", txt) and not re.search(fr"{tag}\d{{3}}\b", txt):
            errs.append(f"[spec] Unpadded ID detected for {tag} (use {tag}###)")
    return errs

def validate_plan_md(path):
    txt = pathlib.Path(path).read_text(encoding="utf-8", errors="ignore")
    errs = []
    heads = [
        r"^##\s+Evidence-to-Decision Map",
        r"^##\s+Component Map",
        r"^##\s+Interaction Contracts",
        r"^##\s+Definition of Ready — Plan",
    ]
    for h in heads:
        if not re.search(h, txt, flags=re.MULTILINE):
            errs.append(f"[plan] Missing heading: {h}")
    # Require at least one RT- in the Evidence-to-Decision section
    section = re.search(r"##\s+Evidence-to-Decision Map([\s\S]+?)(\n##\s+|$)", txt)
    if section:
        if not re.search(r"\bRT-\d+\b", section.group(1)):
            errs.append("[plan] Evidence-to-Decision Map lacks RT-IDs")
    else:
        errs.append("[plan] Evidence-to-Decision Map section not found")
    return errs

def validate_tasks_md(path):
    txt = pathlib.Path(path).read_text(encoding="utf-8", errors="ignore")
    errs = []
    heads = [
        r"^##\s+Agent Execution Contract",
        r"^##\s+Traceability Summary",
        r"^##\s+Definition of Ready — Tasks",
    ]
    for h in heads:
        if not re.search(h, txt, flags=re.MULTILINE):
            errs.append(f"[tasks] Missing heading: {h}")
    for i, line in enumerate(txt.splitlines(), 1):
        if line.lstrip().startswith("- ["):
            if not RULES["tasks_line"].match(line.strip()):
                errs.append(f"[tasks] Line {i} fails canonical format: {line.strip()}")
    return errs

def main(paths):
    all_errs = []
    for p in paths:
        name = pathlib.Path(p).name.lower()
        if name == "spec.md":
            all_errs += validate_spec_md(p)
        elif name == "plan.md":
            all_errs += validate_plan_md(p)
        elif name == "tasks.md":
            all_errs += validate_tasks_md(p)
    if all_errs:
        print("VALIDATION: FAIL")
        for e in all_errs:
            print(" -", e)
        sys.exit(1)
    else:
        print("VALIDATION: PASS")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python scripts/validate_spec_kit.py <paths...>")
        sys.exit(2)
    main(sys.argv[1:])
