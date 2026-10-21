#!/usr/bin/env bash
# Resolve a supported release tag before any package publication.
set -euo pipefail
if [[ $# != 1 ]]; then
  echo 'usage: bash scripts/nuget-release-version.sh vMAJOR.MINOR.PATCH[-PRERELEASE]' >&2
  exit 2
fi
tag=$1
if [[ ! "$tag" =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?$ ]]; then
  echo 'release tag must be vMAJOR.MINOR.PATCH with an optional prerelease' >&2
  exit 2
fi
printf '%s\n' "${tag#v}"
