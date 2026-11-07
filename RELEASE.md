# Releasing banditlab 0.1.0

Status when this folder was prepared (Ubuntu, R 4.3.3, ggplot2 3.4.4):

- `R CMD check --as-cran`: **Status: OK** (0 errors, 0 warnings, 0 notes)
- Spelling (`spelling::spell_check_package()`): no errors (en-GB, `inst/WORDLIST`)
- pkgdown site: builds fully, including the NR link-adaptation article

Not tested there (no internet access to CRAN, no LaTeX): URL checks, the
PDF manual, and ggplot2 >= 3.5.0. Steps 4 and 5 cover these.

## 1. Put the code on GitHub

**If `RProDigest/banditlab` already exists**, apply this folder on a branch
so you can review the diff before merging:

```bash
git clone https://github.com/RProDigest/banditlab.git
cd banditlab
git checkout -b release-0.1.0
rsync -av --exclude .git /path/to/this/banditlab/ ./
git status && git diff          # review: anything deleted that you want to keep?
git add -A
git commit -m "Prepare 0.1.0: ggplot2 compatibility fix, CI, pkgdown, NR article"
git push -u origin release-0.1.0
```

Open a pull request, wait for the R-CMD-check workflow to pass on all five
platforms, then merge to `main`.

**If the repository does not exist yet:**

```bash
cd /path/to/this/banditlab
git init -b main && git add -A && git commit -m "banditlab 0.1.0"
gh repo create RProDigest/banditlab --public --source=. --push
```

## 2. Turn on the pkgdown website

The `pkgdown` workflow builds the site on every push to `main` and pushes it
to a `gh-pages` branch. After its first successful run:

GitHub repo -> Settings -> Pages -> Build and deployment -> Source:
"Deploy from a branch" -> Branch: `gh-pages`, folder `/ (root)` -> Save.

The site appears at <https://rprodigest.github.io/banditlab/>. The URL is
already in `DESCRIPTION`, `_pkgdown.yml` and the README badge.

(Alternative, from R in the repo: `usethis::use_pkgdown_github_pages()`
does the same setup.)

The NR article (`vignettes/articles/`) is website-only: it takes about
4 minutes to run, so it is excluded from the CRAN build.

## 3. Check CI is green

GitHub repo -> Actions. Both `R-CMD-check` and `pkgdown` should pass. If
ggplot2 >= 3.5.0 causes any problem, it will show up here.

## 4. Final local checks (on your machine, with internet and LaTeX)

```r
devtools::document()        # roxygen2: should change nothing
devtools::check(remote = TRUE, manual = TRUE)   # adds URL + PDF manual checks
urlchecker::url_check()     # optional: fixes redirected URLs
```

Expected: one NOTE, "New submission". Anything else, fix before step 5.

## 5. Check on CRAN's own builders

```r
devtools::check_win_devel()   # emails results to the maintainer address
rhub::rhub_setup()            # once; adds an rhub workflow to the repo
rhub::rhub_check()            # runs on GitHub Actions
```

Then edit `cran-comments.md` so it states the results you actually got
(it currently lists the planned environments).

## 6. Submit

```r
devtools::submit_cran()
```

CRAN sends a confirmation link to **RProDigest@protonmail.com** (the
`Maintainer` in DESCRIPTION). Click it, or the submission is not processed.
Make sure that inbox is one you check: all CRAN correspondence goes there.

After submitting, a `CRAN-SUBMISSION` file appears; it is already in
`.Rbuildignore`. Commit it.

## 7. If the reviewer asks for changes

First submissions are usually reviewed by a person. Reply by resubmitting
with the fixes and a short note at the top of `cran-comments.md`
("This is a resubmission. In this version I have: ..."). Bump nothing
unless asked.

## 8. After acceptance

```bash
git tag v0.1.0 && git push --tags
gh release create v0.1.0 --title "banditlab 0.1.0" --notes-file NEWS.md
```

Then add "(development version)" at the top of `NEWS.md` and bump
`Version:` to `0.1.0.9000` for ongoing work.
