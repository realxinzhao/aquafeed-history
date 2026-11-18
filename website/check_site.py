"""Check built documentation links and assets, including the GitHub project prefix."""

from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1] / "dist"
PREFIX = "/aquafeed-history/"


class Page(HTMLParser):
    def __init__(self, path):
        super().__init__(convert_charrefs=True)
        self.ids = set()
        self.links = []
        self.feed(path.read_text(encoding="utf-8"))

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "id" in attrs:
            self.ids.add(attrs["id"])
        for attr in ("href", "src"):
            if attr in attrs:
                self.links.append(attrs[attr])


def main():
    pages = {path.resolve(): Page(path) for path in ROOT.rglob("*.html")}
    errors = []
    checked = 0
    for origin, page in pages.items():
        for link in page.links:
            parts = urlsplit(link)
            if parts.scheme or parts.netloc:
                continue
            path = unquote(parts.path)
            if path.startswith(PREFIX):
                target = ROOT / path[len(PREFIX):]
            elif path.startswith("/"):
                target = ROOT / path.lstrip("/")
            elif path:
                target = origin.parent / path
            else:
                target = origin
            target = target.resolve()
            if target.is_dir():
                target /= "index.html"
            checked += 1
            if not target.is_relative_to(ROOT.resolve()) or not target.exists():
                errors.append(f"{origin.relative_to(ROOT)}: missing {link}")
            elif parts.fragment and target in pages and unquote(parts.fragment) not in pages[target].ids:
                errors.append(f"{origin.relative_to(ROOT)}: missing anchor {link}")
    if errors:
        raise SystemExit("\n".join(errors))
    if not (ROOT / "index.html").is_file() or len(pages) < 9:
        raise SystemExit("The expected documentation pages were not built.")
    print(f"Checked {len(pages)} HTML pages and {checked} internal links/assets: all resolved.")


if __name__ == "__main__":
    main()
