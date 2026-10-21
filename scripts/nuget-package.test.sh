#!/usr/bin/env bash
# Exercise actual SDK packing and a disposable local feed, never NuGet.org.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
releaser=${DOTNET_RELEASER_BIN:-dotnet-releaser}
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

for tag in main v1.2 v01.2.3 'v1.2.3/other' 'v1.2.3;echo unwanted'; do
  if bash "$root/scripts/nuget-release-version.sh" "$tag" >"$scratch/rejection.log" 2>&1; then
    echo "FAIL: accepted invalid release tag: $tag" >&2
    exit 1
  fi
done

for version in 1.2.3 2.0.0-rc.1; do
  [[ $(bash "$root/scripts/nuget-release-version.sh" "v$version") == "$version" ]]
  fixture="$scratch/$version"
  mkdir -p "$fixture"
  git -C "$root" archive HEAD -- src global.json | tar -x -C "$fixture"
  cp "$root/dotnet-releaser.toml" "$fixture/dotnet-releaser.toml"
  (cd "$fixture"; Version="$version" "$releaser" build dotnet-releaser.toml)
  package="$fixture/artifacts-dotnet-releaser/Example.$version.nupkg"
  [[ -f "$package" ]] || { echo 'FAIL: packing produced no version-bound library package' >&2; exit 1; }
  unzip -p "$package" Example.nuspec >"$scratch/package.nuspec"
  grep -Fq "<version>$version</version>" "$scratch/package.nuspec"
  [[ $(find "$fixture/artifacts-dotnet-releaser" -name '*.nupkg' -type f | wc -l | tr -d ' ') == 1 ]]
  mkdir -p "$scratch/feed"
  dotnet nuget push "$package" --source "$scratch/feed"
  cmp "$package" "$scratch/feed/Example.$version.nupkg"
done
echo 'PASS: release tags bind real SDK packages and local-feed delivery bytes'
