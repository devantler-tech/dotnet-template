#!/usr/bin/env bash
# Refuse unpublished branches and pre-migration tags without changing the checkout.
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [[ $# != 1 ]]; then
  echo 'usage: bash scripts/nuget-release-source.sh vMAJOR.MINOR.PATCH[-PRERELEASE]' >&2
  exit 2
fi
bash "$script_dir/nuget-release-version.sh" "$1" >/dev/null
commit=$(git rev-parse --verify "refs/tags/$1^{commit}")
git merge-base --is-ancestor "$commit" refs/remotes/origin/main || {
  echo 'release tag must belong to the fetched main branch' >&2
  exit 1
}
for file in scripts/nuget-release-source.sh scripts/nuget-release-version.sh dotnet-releaser.toml; do
  git cat-file -e "$commit:$file" || {
    echo 'release tag predates the local publisher migration; create a new release on main' >&2
    exit 1
  }
done
printf '%s\n' "$commit"
