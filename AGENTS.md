# ABAP & RAP Utilities

Plug-and-play, expandable collection of generic ABAP/RAP utility classes (single-class,
mostly dependency-free) for SAP teams: ABAP on-prem, S/4HANA, ABAP Cloud / Clean Core.
Public MIT, distributed via abapGit. Product line: **SAP**.

## Package manager + commands
npm (`package-lock.json`): devDeps `@abaplint/cli` 2.120.92, `@abaplint/transpiler-cli` + `@abaplint/runtime` 2.14.15. JS tooling only.
- `npm ci` — install pinned tools.
- `npm run lint` — abaplint with a REAL syntax check (`check_syntax` + `unknown_types` on, syntax v758, open-abap-core as
  the standard-library dependency). An error here = the object would not activate on SAP. `npm run lint:fix` autofixes style.
- `npm test` — ABAP Unit WITHOUT SAP: `abap_transpile.json` lists the pure modules; they are transpiled to JS and their tests
  run on the open-abap kernel (`output/` is git-ignored). Tests that open-abap cannot run are skipped there with a `_why`
  (each was verified green on a real system 2026-11-03); add a skip only with a reason and, ideally, a real-system run.
- `npm run readiness` — abap-mcp Clean Core gate: fails if cloud blockers / non-released API uses exceed
  `docs/readiness-baseline.json`; regenerates `docs/clean-core-readiness.generated.md` (commit it). `--update-baseline` only with a justification.
- `npm run docs` — regenerate `docs/api/` (CI fails if stale; commit the result). `npm run index` — MCP index. `npm run changelog` / `metrics`.

## Verification scope (IMPORTANT)
Three offline lanes: lint = activation-level syntax; `npm test` = behaviour of pure modules on open-abap (no DB, CDS, EML/RAP,
BAL, BCS, GUI); readiness = static Clean Core evidence. Modules touching SAP frameworks (alv, dataset, email, job, lock, logger,
numrange, text, zip, …) are SAP-only: activate + run ABAP Unit in ADT or via abapGit. ATC `CLOUD_READINESS` on the target is final.
Headless real-system runs are possible from this box via the wtc-rap ADT kit (`~/docs/reports/abap-utilities-upgrade-2026-11-03/verify/`).

## Layout
- `src/<tool>/` — one abapGit sub-package per utility (~40: error, string, date, json, logger, rap, alv, http, email, dynsql, fiori, …). Each folder = `zcl_au_<tool>.clas.abap` + `.clas.xml` + per-module `README.md`; objects prefixed `ZCL_AU_`/`ZIF_AU_`/`ZCX_AU_`.
- `src/demo/` — `ZAU_DEMO` report combining several utilities.
- `docs/` — cookbooks/guides (recipes.md = task→tool index; clean-core-*, fiori, rap-cds, anti-patterns, MCP-INTEGRATION, generated `docs/api/`).
- `tools/` — Node helper scripts (api-docs, mcp-index, dev-metrics, ollama-review.sh).
- `index/` — generated MCP search index. `ARCHITECTURE.md` = dependency/cloud policy. `CONTRIBUTING.md` = how to add a utility.

## Install / abapGit
`.abapgit.xml`: STARTING_FOLDER=`/src/`, FOLDER_LOGIC=`PREFIX` — folder `string` → sub-package `ZAU_STRING` under your root package. Cherry-pick a single dependency-free class into a transport, or pull the whole repo. Only cross-dep: most exception-raising tools need the `error` module (`ZCX_AU_ERROR`) first.

## Deploy / CI
No web deploy (it's an ABAP source library). GitHub Actions on every branch+PR: `abaplint.yml` (`npm run lint`), `unit-tests.yml` (`npm test`, offline ABAP Unit), `readiness.yml` (`npm run readiness` + generated matrix must be committed), `api-docs.yml` (regenerates `docs/api`, fails if stale).

## Gotchas
- `ZCL_AU_NUMBER=>ROUND_TO` (was `ROUND` until 2026-11-03: a method named like a built-in function hides it inside the class — never name a method `round`, `lines`, `strlen`, …).
- Cloud-ready column in README: ✅ released APIs only, ⚠️ check release state of a dependency, ❌ SAP GUI/classic (OPEN DATASET, Dynpro) — final proof is ATC `CLOUD_READINESS` on target.
- After touching any `.clas.abap`, run `npm run docs` and commit `docs/api` or api-docs CI breaks.
- This repo prefers referencing mature community projects (abap2xlsx, ajson, ABAP-Logger) over reinventing — see README "Why this repo exists" + `docs/related-projects.md` before adding anything.
