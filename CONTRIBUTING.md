# Contributing to the .NET template

Help make the scaffold easier to adopt: improve an onboarding explanation, an example test or a
focused tooling fix. Discuss substantial work in an
[issue](https://github.com/devantler-tech/dotnet-template/issues) first; this starter intentionally
stays minimal. Send sensitive vulnerabilities through this repository's private
[Report a vulnerability](https://github.com/devantler-tech/dotnet-template/security/advisories/new)
form, not a public issue or PR.

This guide is for the **upstream template**. Projects generated from it should replace this guide
with their own process. Newly created projects include `CONTRIBUTING.md` in
[`.templatesyncignore`](.templatesyncignore). Existing projects must add and commit that entry
in their own ignore file before accepting a sync that introduces this guide: updates to the
ignore file itself do not propagate through sync. That consumer-side entry protects your guide.

## Make a first upstream change

You need Git, the .NET SDK selected by [global.json](global.json), and network access for public
NuGet restore. The current floor is SDK 10.0.300 with `latestFeature` roll-forward within 10.0.x;
check `dotnet --version` from the checkout's root. A .NET runtime alone is insufficient.
Use a POSIX shell for the scaffold tests. No publishing key, GitHub App secret, cluster or
production infrastructure is needed for this local path.

Fork `devantler-tech/dotnet-template` on GitHub. Replace `YOUR-LOGIN` with your login:

```sh
git clone https://github.com/YOUR-LOGIN/dotnet-template.git
cd dotnet-template
git switch -c docs/first-contribution
```

Make a small wording improvement in `README.md`. Do not run the rename script in this upstream
checkout: it must retain the `Example` identity. Then run the required local baseline from the root,
including for documentation PRs:

```sh
dotnet build
dotnet test
git diff --check
```

The build restores packages automatically and must finish with no warnings or errors. The test
run must pass its five scaffold tests; zero discovered tests is not a passing contribution check.
These checks do not publish anything or replace native CI and current-head review.

For changes to this README's onboarding explanation, also exercise the disposable scaffold path:

```sh
sh scripts/validate-agent-shims.test.sh
sh scripts/rename-placeholders.test.sh
```

Both commands must exit 0 and print `PASS`. Rename tests work on temporary copies and clean them
up; your upstream checkout is not renamed. CI runs these plus a complete retired-link scan with
positive/negative controls and organization-required build/test checks. See
[AGENTS.md validation](AGENTS.md#validation) for the full matrix. Workflow edits also need `actionlint`.

## Submit your change

Review the diff, configure commit signing and stage explicit changed paths. For a README edit:

```sh
git add README.md
git commit -S -m "docs: clarify .NET template onboarding"
git push -u origin docs/first-contribution
```

Open a **draft** PR to `devantler-tech/dotnet-template:main` using the inherited
[PR template](https://github.com/devantler-tech/.github/blob/main/.github/PULL_REQUEST_TEMPLATE.md).
Keep Why/What focused on the reader-facing problem and outcome, link the issue for substantial
work, and put detailed validation evidence in a comment or check summary. Use a Conventional
Commit title and disclose AI assistance when used. Address findings; required CI and a successful
substantive review at the exact current head must pass before merge.

Follow the inherited [code of conduct](https://github.com/devantler-tech/.github/blob/main/.github/CODE_OF_CONDUCT.md)
and preserve the [Apache-2.0 license](LICENSE). Publishing, App installation and downstream CI setup
are maintainer procedures, not first-contribution requirements.
