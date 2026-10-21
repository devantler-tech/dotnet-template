#!/usr/bin/env bash
# Exercise the workflow payload handed to Actions, including negative controls.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

check_validation() {
  yq -o=json '.' "$1" | jq -e '
    (.on | has("pull_request") and has("merge_group") and (has("workflow_call") | not)) and
    .permissions == {} and
    (.jobs.test.strategy.matrix.os | sort) == ["macos-latest", "ubuntu-latest", "windows-latest"] and
    .jobs.test.permissions.contents == "read" and
    .jobs.test.permissions.packages == "read" and
    .jobs.test.permissions["code-quality"] == "write" and
    (.jobs.test | has("uses") | not) and
    ([.jobs.test.steps[] | select(.uses? | strings | startswith("devantler-tech/.github/actions/run-dotnet-tests@"))] | length) == 1 and
    ([.jobs.test.steps[] | select(.uses? | strings | startswith("devantler-tech/.github/actions/run-dotnet-tests@"))][0] |
      (.uses | test("@[0-9a-f]{40}$")) and
      .with["github-token"] == "${{ github.event_name != '\''pull_request'\'' && secrets.GITHUB_TOKEN || '\'''\'' }}")
  ' >/dev/null
}

check_publisher() {
  yq -o=json '.' "$1" | jq -e '
    (.on | has("workflow_dispatch") and (.push.tags == ["v*"]) and (has("workflow_call") | not)) and
    .permissions == {} and
    (.jobs.publish | has("uses") | not) and
    .jobs.publish.permissions == {"contents":"read", "packages":"write"} and
    ([.jobs.publish.steps[] | select(.env.NUGET_API_KEY? == "${{ secrets.NUGET_API_KEY }}" and .env.GITHUB_TOKEN? == "${{ secrets.GITHUB_TOKEN }}")] | length) == 1 and
    ([.jobs.publish.steps[] | select(.run? | strings | contains("dotnet tool install --global dotnet-releaser --version 0.24.0"))] | length) == 1
  ' >/dev/null
}

check_validation "$root/.github/workflows/run-dotnet-tests.yaml" || {
  echo 'FAIL: local validation must retain all platforms, read-only checkout and PR token isolation' >&2
  exit 1
}
check_publisher "$root/.github/workflows/publish.yaml" || {
  echo 'FAIL: publication must be local, explicitly permissioned and tool-pinned' >&2
  exit 1
}

# Missing platforms, credential widening and a remote job must not satisfy the contract.
for mutation in \
  'del(.jobs.test.strategy.matrix.os[2])' \
  '.jobs.test.permissions.contents = "write"' \
  '.jobs.test.steps += [{"uses":"devantler-tech/.github/actions/run-dotnet-tests@main"}]' \
  '.jobs.test.uses = "devantler-tech/.github/.github/workflows/run-dotnet-tests.yaml@main"'; do
  yq "$mutation" "$root/.github/workflows/run-dotnet-tests.yaml" >"$scratch/validation.yaml"
  if check_validation "$scratch/validation.yaml"; then
    echo "FAIL: validation accepted unsafe mutation: $mutation" >&2
    exit 1
  fi
done
for mutation in \
  '.permissions.contents = "write"' \
  '.jobs.publish.uses = "devantler-tech/.github/.github/workflows/publish-dotnet-library.yaml@main"' \
  '(.jobs.publish.steps[] | select(.env.NUGET_API_KEY)).env.NUGET_API_KEY = "wrong-secret"'; do
  yq "$mutation" "$root/.github/workflows/publish.yaml" >"$scratch/publisher.yaml"
  if check_publisher "$scratch/publisher.yaml"; then
    echo "FAIL: publication accepted unsafe mutation: $mutation" >&2
    exit 1
  fi
done
echo 'PASS: repository-owned .NET workflow boundaries and negative controls'
