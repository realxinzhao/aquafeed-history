# Maintaining the documentation

The documentation website is published from this repository using GitHub Pages.
It builds automatically when documentation changes reach `main`. Pull requests
build and check the site before publication.

## Where to edit

| Content | Source |
|---|---|
| Overview and quickstart | `website/index.md`, `website/quickstart.md` |
| Methods and source roles | `docs/METHODS.md` |
| Coverage assumptions | `docs/COVERAGE_ASSUMPTIONS.md` |
| Source register | `data/raw/literature/source_register.csv` |
| Source audit | `docs/SOURCE_AUDIT.md` |
| Validation record | `validation/EXECUTION_STATUS.md` |
| Publication priorities | `docs/PUBLICATION_ROADMAP.md` |
| Site navigation and appearance | `mkdocs.yml`, `website/assets/` |

The existing scientific documents are reused at build time. Do not edit
`_site_docs/` or `dist/`: these are generated folders. Links to code and data remain
links to GitHub, while links between published documents stay inside the website.
The source register page is generated from its CSV, preserving the source entries.
Current coefficient selection is explained in the methods guide.

## Build locally

The website build uses **Python 3.11 or newer and Zensical**. These tools are only
needed to build the website; coefficient calculation and export still use base R.

```sh
python -m pip install -r website/requirements.txt
python website/prepare_docs.py
zensical build --strict --clean -f mkdocs.yml
python website/check_site.py
```

For a local browsing session, run `zensical serve -f mkdocs.yml` after preparing the
source documents. Re-run `prepare_docs.py` after editing a document outside the
staging directory. The workflow is defined in `.github/workflows/docs.yml`.

## Publishing

GitHub Pages uses **GitHub Actions** as its publishing source. The workflow builds
static pages, checks internal links, and publishes successful main-branch builds.
No API tokens, analytics accounts or separate hosting subscription are needed.
The public address is <https://realxinzhao.github.io/aquafeed-history/>.

Changes to scientific inputs need the project's usual R checks as well as a
website build. A successful website build verifies rendering and internal links;
it does not validate new feed assumptions.
