# .NET Template

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

A minimal, batteries-included .NET template for new projects and libraries. Skip the boilerplate — start from a clean, idiomatic scaffold with the house defaults, linting, CI/CD, releases, and agent tooling already wired up.

It starts as a **library with tests**, not a web app or executable. Your first useful result is a
passing solution build and test run; there is no application to launch or deploy yet. Generated
projects receive the local build/test workflow too; configure branch protection in your repository
to require it before merging.

## ✨ What's included

- **Idiomatic scaffold** — an [`Example.slnx`](Example.slnx) solution wiring a library project ([`src/Example`](src/Example)) to a matching xUnit test project ([`tests/Example.Tests`](tests/Example.Tests)). A single documented member with tests shows the house testing pattern; [`scripts/rename-placeholders.sh`](scripts/rename-placeholders.sh) repoints the `Example` scaffold to your own project name in one shot.
- **House defaults** — every project builds with `Nullable`, `ImplicitUsings`, `AnalysisMode=All`, `EnforceCodeStyleInBuild`, XML documentation generation, and `TreatWarningsAsErrors` enabled, so code-style and analyzer findings are build errors, not warnings. Editor and analyzer rules live in [`.editorconfig`](.editorconfig).
- **Feature-flag ready** — a portable [OpenFeature](https://openfeature.dev/) scaffold ([`src/Example/FeatureFlags.cs`](src/Example/FeatureFlags.cs)) so new features land **behind a flag, default-off**, are tested in both states, and are switched on only after validation. Ships an in-memory provider (no backend needed); swap in flagd or another provider without touching call sites. See [`AGENTS.md`](AGENTS.md#feature-flags).
- **CI/CD** — repository-owned [.NET validation](.github/workflows/run-dotnet-tests.yaml) builds and tests on Ubuntu, Windows and macOS for pull requests and the merge queue; [`ci.yaml`](.github/workflows/ci.yaml) also aggregates template-specific checks. Run `dotnet build` / `dotnet test` locally before a PR.
- **Release and publishing configuration** — [semantic-release](https://github.com/semantic-release/semantic-release) uses eligible [Conventional Commits](https://www.conventionalcommits.org/) on `main` to decide whether to cut a `v*` tag and GitHub release ([`release.yaml`](.github/workflows/release.yaml)). The [publish workflow](.github/workflows/publish.yaml) is configured to publish the library to NuGet on those tags; App credentials and a NuGet publishing key are maintainer setup, not local-build prerequisites. These workflow definitions alone do not prove that your package is published.
- **Dependency management** — [Dependabot](https://docs.github.com/code-security/dependabot) keeps dependencies and pinned GitHub Actions current.
- **Agent-ready** — [`AGENTS.md`](AGENTS.md) conventions and a `.claude/skills/maintain` card so the autonomous Agentic Engineer (and any agentic tool) can maintain the repo.

The target framework is declared in the project files — currently `net10.0` in [`src/Example/Example.csproj`](src/Example/Example.csproj).
The SDK selection is separate: [global.json](global.json) requires the .NET 10 SDK at feature band
10.0.300 or later within 10.0.x (`latestFeature` roll-forward), not just the .NET runtime.

## 🚀 Use this template

You need Git, a compatible .NET SDK as described above, and network access for NuGet restore.
The CLI route also needs the [GitHub CLI](https://cli.github.com/) signed in to your own account.
Start in the directory where you want a new project checkout.

The next command **creates a public GitHub repository** and clones it. Replace `my-project` with
your chosen repository name; use `--private` instead of `--public` if appropriate. Run it only
when you intend to create that repository:

```bash
gh repo create my-project --template devantler-tech/dotnet-template --public --clone
cd my-project
```

Or click **Use this template** on the [repository page](https://github.com/devantler-tech/dotnet-template),
choose its owner and visibility, then clone your new repository and enter its root.

Then make it your own — run the personalisation script to repoint the scaffold (solution, projects, namespaces, and README references) to your project's name in one shot, then replace the sample `ExampleClass` with your first real type. A clean build and test confirms the scaffold is wired up:

```bash
./scripts/rename-placeholders.sh Widget
dotnet build
dotnet test
```

`Widget` is a synthetic project name: replace it with your valid .NET project name. The script
needs a POSIX shell and standard Unix tools; Windows users can use a suitable shell such as Git
Bash. Run it only in a generated project, never an upstream template contribution checkout.
Success means the renamed solution builds without warnings/errors and its five scaffold tests
pass. Build restores dependencies automatically; neither command publishes a package.

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
- **Instance-owned** — listed in your project's own `.templatesyncignore`,
  never touched by a sync. The [supplied file](.templatesyncignore) protects
  your solution and code (the `.slnx`, all of `src/`
  and `tests/`), the toolchain floor (`global.json` — the SDK floor and every
  `<TargetFramework>` must move in lockstep, so the whole upgrade is yours),
  identity and docs (`README.md`, `CONTRIBUTING.md`, `AGENTS.md`, `LICENSE`, `CODEOWNERS`), and
  the configs you tailor (`.releaserc`, `.gitignore`, `dependabot.yaml`).
- **Scaffold-time-only** — the rename script and the template's own
  `validate-scaffold.yaml` gate arrive when the repo is created and are ignored
  by sync afterwards, so you can delete them and they stay gone.

**Existing projects need a one-time documentation migration.** The sync action
does not propagate updates to `.templatesyncignore` itself. Before the sync runs,
add the literal line `CONTRIBUTING.md` to your project's own ignore file and
commit it. If a sync PR is already open, restore your tailored guide and commit
the ignore entry before merging that PR: adding an ignore entry does not undo
changes already proposed. New projects created from the updated template already
include that entry. Review future ownership changes in the consumer's ignore file too.

The sync workflow no-ops in this template repository itself. In devantler-tech
instances it works out of the box (the org provides the App credentials); an
instance elsewhere is off by default — opt in by supplying your own GitHub App
(one allowed to open PRs in your repository): add its private key as the
`APP_PRIVATE_KEY` secret, its client ID as the `APP_CLIENT_ID` repository
variable, and set the repository variable `TEMPLATE_SYNC_ENABLED=true`.
The local .NET validation workflow runs in generated projects without an organization-injected
workflow. Branch protection is separate: require its successful result in your repository.
If you tailor a workflow rather than maintaining it through this template, add its path to
your `.templatesyncignore` so later syncs preserve your version.

## 📝 Usage

### Add a project to the solution

```bash
dotnet new classlib --output src/AnotherLibrary
dotnet sln Widget.slnx add src/AnotherLibrary
```

This example assumes you renamed the scaffold to `Widget` above. Use your own solution filename
and new project name; the commands create a project and update that solution.

### Build your solution

```bash
dotnet build
```

### Test your solution

```bash
dotnet test
```

> Warnings are treated as errors, so a clean `dotnet build` and `dotnet test` are required before opening a pull request.

## Contributing

To improve the upstream template, start with [CONTRIBUTING.md](CONTRIBUTING.md). Generated projects
own their guide and should adapt it to their own contribution process.

## 🤖 Maintenance

The template's CI checks documentation for links to retired repositories using
the configuration in [retired-repo-links.json](.github/retired-repo-links.json).
It requires a complete clean scan and verifies that a seeded retired link fails
in a disposable copy. This gate runs only in the template repository.

Generated projects own their scan configuration and decide when to enable the
shared validator; template sync preserves their paths and historical exceptions.

This template is maintained by an autonomous AI assistant. Its canonical engineering contract and
full validation matrix live in [AGENTS.md](AGENTS.md). Preserve the [Apache-2.0 license](LICENSE).
