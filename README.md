# .NET Template

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A minimal, batteries-included .NET template for new projects and libraries. Skip the boilerplate — start from a clean, idiomatic scaffold with the house defaults, linting, CI/CD, releases, and agent tooling already wired up.

## ✨ What's included

- **Idiomatic scaffold** — an [`Example.slnx`](Example.slnx) solution wiring a library project ([`src/Example`](src/Example)) to a matching xUnit test project ([`tests/Example.Tests`](tests/Example.Tests)). A single documented member with tests shows the house testing pattern; [`scripts/rename-placeholders.sh`](scripts/rename-placeholders.sh) repoints the `Example` scaffold to your own project name in one shot.
- **House defaults** — every project builds with `Nullable`, `ImplicitUsings`, `AnalysisMode=All`, `EnforceCodeStyleInBuild`, XML documentation generation, and `TreatWarningsAsErrors` enabled, so code-style and analyzer findings are build errors, not warnings. Editor and analyzer rules live in [`.editorconfig`](.editorconfig).
- **Feature-flag ready** — a portable [OpenFeature](https://openfeature.dev/) scaffold ([`src/Example/FeatureFlags.cs`](src/Example/FeatureFlags.cs)) so new features land **behind a flag, default-off**, are tested in both states, and are switched on only after validation. Ships an in-memory provider (no backend needed); swap in flagd or another provider without touching call sites. See [`AGENTS.md`](AGENTS.md#feature-flags).
- **CI/CD** — a required-checks workflow on pull requests and the merge queue ([`ci.yaml`](.github/workflows/ci.yaml)); the .NET build/test validation runs via an org-required reusable workflow enforced by branch rules (run `dotnet build` / `dotnet test` locally before a PR).
- **Releases & publishing** — merge [Conventional Commits](https://www.conventionalcommits.org/) to `main` and [semantic-release](https://github.com/semantic-release/semantic-release) cuts a `v*` tag and GitHub release ([`release.yaml`](.github/workflows/release.yaml)); that tag then publishes the library to NuGet via the shared [`publish-dotnet-library`](https://github.com/devantler-tech/actions/blob/main/.github/workflows/publish-dotnet-library.yaml) workflow ([`publish.yaml`](.github/workflows/publish.yaml)).
- **Dependency management** — [Dependabot](https://docs.github.com/code-security/dependabot) keeps dependencies and pinned GitHub Actions current.
- **Agent-ready** — [`AGENTS.md`](AGENTS.md) conventions and a `.claude/skills/maintain` card so the autonomous Daily AI Assistant (and any agentic tool) can maintain the repo.

The target framework is declared in the project files — currently `net10.0` in [`src/Example/Example.csproj`](src/Example/Example.csproj).

## 🚀 Use this template

Create a new repository from the template with the GitHub CLI:

```bash
gh repo create my-project --template devantler-tech/dotnet-template --public --clone
cd my-project
```

Or click **Use this template** on the [repository page](https://github.com/devantler-tech/dotnet-template).

Then make it your own — run the personalisation script to repoint the scaffold (solution, projects, namespaces, and README references) to your project's name in one shot, then replace the sample `ExampleClass` with your first real type. A clean build and test confirms the scaffold is wired up:

```bash
./scripts/rename-placeholders.sh <ProjectName>   # e.g. Widget
dotnet build
dotnet test
```

Run the script with no argument to derive a PascalCase name from your `origin` GitHub remote. It leaves the **Use this template** links above and the maintenance docs untouched; review the result with `git diff`. (Prefer to rename by hand? Repoint `Example` across the `.slnx`, `src/`, `tests/`, and README references yourself.)

## 🔄 Staying current

A weekly **template-sync** workflow opens a PR in your repository whenever this
template's shared plumbing changes, so instances never drift from the
portfolio's CI/lint/agent-file conventions. It never touches your code: every
file falls into one of three ownership classes:

- **Template-owned plumbing** — synced downstream by the weekly PR: the
  `.github/workflows/` CI/publish/release workflows, the shared configs
  (`.editorconfig`, `.gitattributes`, `.pre-commit-config.yaml`), and the
  `CLAUDE.md`/`GEMINI.md` shims. Change these upstream in the template,
  never by hand in an instance.
- **Instance-owned** — listed in [`.templatesyncignore`](.templatesyncignore),
  never touched by a sync: your solution and code (the `.slnx`, all of `src/`
  and `tests/`), the toolchain floor (`global.json` — the SDK floor and every
  `<TargetFramework>` must move in lockstep, so the whole upgrade is yours),
  identity and docs (`README.md`, `AGENTS.md`, `LICENSE`, `CODEOWNERS`), and
  the configs you tailor (`.releaserc`, `.gitignore`, `dependabot.yaml`).
- **Scaffold-time-only** — the rename script and the template's own
  `validate-scaffold.yaml` gate arrive when the repo is created and are ignored
  by sync afterwards, so you can delete them and they stay gone.

The sync workflow no-ops in this template repository itself. In devantler-tech
instances it works out of the box (the org provides the App credentials); an
instance elsewhere is off by default — opt in by supplying your own GitHub App
(one allowed to open PRs in your repository): add its private key as the
`APP_PRIVATE_KEY` secret, its client ID as the `APP_CLIENT_ID` repository
variable, and set the repository variable `TEMPLATE_SYNC_ENABLED=true`. Note
that outside devantler-tech the synced `ci.yaml` is only an empty required-check
aggregator (the real build/test workflows are injected by devantler-tech org
rulesets): replace it with your own CI and add `.github/workflows/ci.yaml` to
your `.templatesyncignore` so later syncs preserve your version.

## 📝 Usage

### Add a project to the solution

```bash
dotnet new classlib --output src/<name-of-project>
dotnet sln Example.slnx add src/<name-of-project>
```

### Build your solution

```bash
dotnet build
```

### Test your solution

```bash
dotnet test
```

> Warnings are treated as errors, so a clean `dotnet build` and `dotnet test` are required before opening a pull request.

## 🤖 Maintenance

This template is maintained by an autonomous AI assistant. The conventions, validation commands, and contribution workflow live in [`AGENTS.md`](AGENTS.md).