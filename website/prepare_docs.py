"""Stage the existing research documentation without duplicating its source text."""

import csv
import html
import re
import shutil
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit, urlunsplit

ROOT = Path(__file__).resolve().parents[1]
STAGING = ROOT / "_site_docs"
REPOSITORY = "https://github.com/realxinzhao/aquafeed-history"
PAGES = {
    "website/index.md": "index.md",
    "website/quickstart.md": "quickstart.md",
    "docs/METHODS.md": "methods.md",
    "docs/COVERAGE_ASSUMPTIONS.md": "coverage.md",
    "docs/SOURCE_AUDIT.md": "source-audit.md",
    "validation/EXECUTION_STATUS.md": "validation.md",
    "docs/PUBLICATION_ROADMAP.md": "roadmap.md",
    "website/maintenance.md": "maintenance.md",
}
SITE_PAGES = set(PAGES.values()) | {"sources.md"}
INLINE_LINK = re.compile(r"(!?\[[^\]\n]*\]\()([^\s)]+)(\))")


def repository_url(path):
    kind = "tree" if (ROOT / path).is_dir() else "blob"
    return f"{REPOSITORY}/{kind}/main/{quote(path, safe='/')}"


def rewrite_target(target, source):
    parts = urlsplit(target)
    if parts.scheme or parts.netloc or not parts.path:
        return target
    # The website's short authored pages use the final navigation filenames.
    if source.startswith("website/") and parts.path in SITE_PAGES:
        return target
    path = (ROOT / source).parent / unquote(parts.path)
    path = path.resolve()
    if not path.is_relative_to(ROOT) or not path.exists():
        raise ValueError(f"Unresolved repository link in {source}: {target}")
    relative = path.relative_to(ROOT).as_posix()
    if relative in PAGES:
        return urlunsplit(("", "", PAGES[relative], parts.query, parts.fragment))
    url = repository_url(relative)
    if parts.query:
        url += "?" + parts.query
    if parts.fragment:
        url += "#" + parts.fragment
    return url


def stage_markdown(source):
    text = (ROOT / source).read_text(encoding="utf-8")
    rewritten = []
    fence = None
    for line in text.splitlines(keepends=True):
        match = re.match(r"^\s*(`{3,}|~{3,})", line)
        if match:
            marker = match.group(1)
            if fence is None:
                fence = marker
            elif marker[0] == fence[0] and len(marker) >= len(fence):
                fence = None
            rewritten.append(line)
        elif fence:
            rewritten.append(line)
        else:
            rewritten.append(INLINE_LINK.sub(
                lambda m: m.group(1) + rewrite_target(m.group(2), source) + m.group(3), line))
    return "".join(rewritten) + (
        '\n\n<div class="af-source-note" markdown>\n'
        f"[Source document on GitHub]({repository_url(source)}). "
        "This page is built from the repository documentation.\n</div>\n"
    )


def source_register():
    path = ROOT / "data/raw/literature/source_register.csv"
    with path.open(encoding="utf-8-sig", newline="") as stream:
        records = list(csv.DictReader(stream))
    text = [
        "# Source register\n",
        "Bibliography, scope and limitations for the sources retained in this project. "
        "The [methods guide](methods.md#source-roles) explains which values are selected "
        "for the current coefficients. Some entries provide contextual evidence only.\n",
        f"Generated from the [{len(records)}-entry source register]"
        f"({repository_url('data/raw/literature/source_register.csv')}). "
        "Source records and their numerical tables remain in the repository.\n",
    ]
    labels = {
        "publication_year": "Publication", "data_years": "Data period",
        "geography_scope": "Scope", "location": "Location in source",
        "evidence_type": "Evidence type", "limitations": "Limitations",
    }
    for row in records:
        text += [f"## {html.escape(row['source_id'])}\n", f"**{html.escape(row['citation'])}**\n"]
        for key, label in labels.items():
            if row.get(key):
                text.append(f"**{label}:** {html.escape(row[key])}\n")
        source = row.get("url", "")
        if source.startswith(("https://", "http://")):
            text.append(f"[Open source]({source})\n")
        elif source:
            text.append(f"**Provenance:** {html.escape(source)}\n")
    return "\n".join(text)


def main():
    if STAGING.exists():
        shutil.rmtree(STAGING)
    STAGING.mkdir()
    for source, destination in PAGES.items():
        (STAGING / destination).write_text(stage_markdown(source), encoding="utf-8")
    (STAGING / "sources.md").write_text(source_register(), encoding="utf-8")
    shutil.copytree(ROOT / "website/assets", STAGING / "assets")
    print(f"Prepared {len(SITE_PAGES)} documentation pages from repository sources.")


if __name__ == "__main__":
    main()
