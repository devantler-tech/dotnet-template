#!/usr/bin/env bash
# Exercise tag eligibility against a real repository, including historical tags.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
if [[ ! -f "$root/scripts/nuget-release-source.sh" ]]; then
  echo 'FAIL: release publication has no source eligibility check' >&2
  exit 1
fi
yq -r '.jobs.package.steps[] | select(.id == "release").run' "$root/.github/workflows/publish.yaml" >"$scratch/select.sh"
[[ -s "$scratch/select.sh" ]] || { echo 'FAIL: publisher does not validate its release source' >&2; exit 1; }
git init -q -b main "$scratch/repo"
cd "$scratch/repo"
git config user.name fixture
git config user.email fixture@example.invalid
git config commit.gpgsign false
mkdir scripts
cp "$root/scripts/nuget-release-version.sh" scripts/
touch dotnet-releaser.toml
git add scripts/nuget-release-version.sh dotnet-releaser.toml
git commit -qm 'historical release'
git tag v1.0.0
cp "$root/scripts/nuget-release-source.sh" scripts/
git add scripts/nuget-release-source.sh
git commit -qm 'adopt publication boundary'
eligible=$(git rev-parse HEAD)
git tag v1.2.3
git tag -a v2.0.0-rc.1 -m prerelease
git update-ref refs/remotes/origin/main HEAD
git switch -qc feature
touch feature
git add feature
git commit -qm 'unreleased feature'
git tag v9.0.0
git switch -q main
for tag in v1.2.3 v2.0.0-rc.1; do
  actual=$(bash "$root/scripts/nuget-release-source.sh" "$tag")
  [[ "$actual" == "$eligible" ]] || { echo 'FAIL: wrong release commit' >&2; exit 1; }
  RELEASE_TAG="$tag" GITHUB_OUTPUT="$scratch/output" bash "$scratch/select.sh" >"$scratch/selected" 2>&1
  [[ $(git rev-parse HEAD) == "$eligible" ]]
  grep -Fxq "version=${tag#v}" "$scratch/output"
done
for tag in v1.0.0 v9.0.0 v8.0.0 main 'v1.2.3;echo unwanted'; do
  if RELEASE_TAG="$tag" GITHUB_OUTPUT="$scratch/output" bash "$scratch/select.sh" >"$scratch/rejected" 2>&1; then
    echo "FAIL: accepted ineligible release: $tag" >&2
    exit 1
  fi
  [[ $(git rev-parse HEAD) == "$eligible" ]] || { echo 'FAIL: rejected tag changed checkout' >&2; exit 1; }
done
git update-ref -d refs/remotes/origin/main
if RELEASE_TAG=v1.2.3 GITHUB_OUTPUT="$scratch/output" bash "$scratch/select.sh" >"$scratch/rejected" 2>&1; then
  echo 'FAIL: accepted release without release-branch evidence' >&2
  exit 1
fi
echo 'PASS: stable and annotated prerelease tags resolve; historical, off-main and unknown tags refuse'
