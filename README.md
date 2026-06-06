# .NET Template

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A minimal, batteries-included .NET template for new projects and libraries. Skip the boilerplate — start from a clean, idiomatic scaffold with the house defaults, linting, CI/CD, releases, and agent tooling already wired up.

## ✨ What's included

- **Idiomatic scaffold** — an [`Example.slnx`](Example.slnx) solution wiring a library project ([`src/Example`](src/Example)) to a matching xUnit test project ([`tests/Example.Tests`](tests/Example.Tests)). A single documented member with tests shows the house testing pattern — rename `Example` to your own name and replace the example with your first type.
- **House defaults** — every project builds with `Nullable`, `ImplicitUsings`, `AnalysisMode=All`, `EnforceCodeStyleInBuild`, XML documentation generation, and `TreatWarningsAsErrors` enabled, so code-style and analyzer findings are build errors, not warnings. Editor and analyzer rules live in [`.editorconfig`](.editorconfig).
- **CI/CD** — a required-checks workflow on pull requests and the merge queue ([`ci.yaml`](.github/workflows/ci.yaml)); the .NET build/test validation runs via an org-required reusable workflow enforced by branch rules (run `dotnet build` / `dotnet test` locally before a PR).
- **Releases & publishing** — merge [Conventional Commits](https://www.conventionalcommits.org/) to `main` and [semantic-release](https://github.com/semantic-release/semantic-release) cuts a `v*` tag and GitHub release ([`release.yaml`](.github/workflows/release.yaml)); that tag then publishes the library to NuGet via the shared [`publish-dotnet-library`](https://github.com/devantler-tech/reusable-workflows) workflow ([`publish.yaml`](.github/workflows/publish.yaml)).
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

Then make it your own — rename the solution, library project, namespace, and test project from `Example` to your project's name, and replace `ExampleClass` with your first type. A clean build and test confirms the scaffold is wired up:

```bash
dotnet build
dotnet test
```

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