# GitHub Copilot review instructions — dotnet-template

`devantler-tech/dotnet-template` is a **minimal .NET template**: an empty,
idiomatic scaffold (a library project plus a matching xUnit test project) wired up
with the house defaults and the standard CI/CD, release, and agent tooling, so a
new package starts from a current baseline. Targets `net10.0`; published to NuGet
on `v*` tags. Enforce the rules below when reviewing. They complement `AGENTS.md`
(the canonical, cross-tool instructions) — keep both in sync; if a PR changes a
convention here, it updates `AGENTS.md` too.

## Scope & altitude
- This is a **template, not a product** — flag any PR that adds application
  features, business logic, or non-scaffold dependencies. The bias is minimal,
  idiomatic, current.
- `src/Example/` (`ExampleClass.cs`) and `tests/Example.Tests/`
  (`ExampleClassTests.cs`) are an intentional sample meant to be renamed/replaced,
  not a feature set. Don't approve filler code or extra projects added beyond the
  one library + one test project.

## .NET & toolchain
- The repo builds with **warnings as errors** (`TreatWarningsAsErrors=true`,
  `AnalysisMode=All`) and `Nullable`/`ImplicitUsings` enabled with XML-doc
  generation — a clean `dotnet build` must produce **zero** warnings. Flag code
  that suppresses analyzer warnings (`#pragma warning disable`, `<NoWarn>`) to
  dodge a finding instead of fixing the root cause, and any new public API missing
  XML docs.
- Keep the target framework (`net10.0`) and SDK pinning aligned with the house
  workflows — flag a hardcoded framework/SDK version in prose or workflows that
  could drift.
- Idiomatic, nullable-aware C#: no unjustified `!` null-forgiving operators, no
  swallowed exceptions, `async`/`await` over blocking calls, tests via xUnit
  `[Fact]`/`[Theory]`.

## Format & analyzers
- `.editorconfig` defines formatting and analyzer rules enforced at build; code
  must pass `dotnet format`. The `.pre-commit-config.yaml` `dotnet-format` hook
  runs it on staged C# — flag formatting drift.

## Commits, CI & security
- **PR titles must be Conventional Commits** (`feat:`/`fix:`/`chore:`/`docs:`/
  `ci:`/`refactor:`/`test:`) — the repo squash-merges the title into the
  changelog/release, so a non-conventional or bracket-prefixed title corrupts it.
  Flag violations.
- Workflow changes must pass `actionlint`. Pin third-party actions to a
  full-length commit SHA, set least-privilege `permissions:`, and keep the house
  workflows intact (`ci.yaml` is the required-checks aggregator; `publish.yaml`
  publishes the NuGet library on `v*` tags via the reusable
  `publish-dotnet-library` workflow). Flag unpinned actions and over-broad token
  scopes.
- Never weaken or skip a check to make CI pass (no skipped tests, `--no-verify`,
  disabled steps, or "flaky"-dismissals) — fix the underlying cause.

## Generated & config files
- Don't hand-edit generated artifacts; re-run the generator instead. Keep the
  `README` and badges accurate to what actually ships.

Keep this file concise (≤ 4000 chars — Copilot review truncates beyond that) and
in sync with `AGENTS.md`.
