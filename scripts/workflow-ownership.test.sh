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
    .jobs.test.permissions == {"contents":"read"} and
    ([.jobs.test.steps[] | select(.uses? | strings | startswith("actions/checkout@"))] |
      length == 1 and .[0].with["persist-credentials"] == false) and
    (.jobs.test | has("uses") | not) and
    ([.jobs.test.steps[] | select(.uses? | strings | startswith("devantler-tech/.github/actions/run-dotnet-tests@"))] | length) == 1 and
    ([.jobs.test.steps[] | select(.uses? | strings | startswith("devantler-tech/.github/actions/run-dotnet-tests@"))][0] |
      (.uses | test("@[0-9a-f]{40}$")) and
      .with["github-token"] == "")
  ' >/dev/null
}

check_publisher() {
  yq -o=json '.' "$1" | jq -e '
    (.on | has("workflow_dispatch") and (.push.tags == ["v*"]) and (has("workflow_call") | not)) and
    .permissions == {} and
    .concurrency == {"group":"${{ github.workflow }}-${{ inputs.tag || github.ref_name }}", "cancel-in-progress":false} and
    (.jobs.publish | has("uses") | not) and
    .jobs.package.permissions == {"contents":"read"} and
    .jobs.publish.permissions == {"id-token":"write"} and
    .jobs.publish.needs == "package" and
    ([.jobs.package.steps[] | select(.uses? | strings | startswith("actions/checkout@"))] |
      length == 1 and .[0].with["persist-credentials"] == false and .[0].with.ref == "main") and
    ([.jobs.publish.steps[] | select(.env.NUGET_API_KEY? == "${{ steps.login.outputs.NUGET_API_KEY }}")] | length) == 1 and
    ([.jobs.publish.steps[] | select(.env.GITHUB_TOKEN? != null)] | length) == 0 and
    ([.jobs.package.steps[] | select(.run? | strings | contains("dotnet-releaser --version 0.24.0"))] | length) == 1 and
    ([.jobs.publish.steps[] | select(.uses? | strings | startswith("actions/setup-dotnet@"))] |
      length == 1 and (.[0].uses | test("@[0-9a-f]{40}$")))
  ' >/dev/null
}

check_validation "$root/.github/workflows/run-dotnet-tests.yaml" || {
  echo 'FAIL: local validation must retain all platforms, read-only checkout and candidate token isolation' >&2
  exit 1
}
check_publisher "$root/.github/workflows/publish.yaml" || {
  echo 'FAIL: publication must be local, explicitly permissioned and tool-pinned' >&2
  exit 1
}

# Missing platforms, credential widening and a remote job must not satisfy the contract.
# An unrelated new step must not turn a negative control into a no-op.
for preparation in '.' '.jobs.test.steps = [{"name":"Additional preparation", "run":"true"}] + .jobs.test.steps'; do
  yq "$preparation" "$root/.github/workflows/run-dotnet-tests.yaml" >"$scratch/validation-base.yaml"
  check_validation "$scratch/validation-base.yaml"
  for mutation in \
    'del(.jobs.test.strategy.matrix.os[2])' \
    '.jobs.test.permissions.contents = "write"' \
    '(.jobs.test.steps[] | select(.uses | test("^devantler-tech/\\.github/actions/run-dotnet-tests@"))).with."github-token" = "credential-fixture"' \
    'del(.jobs.test.steps[] | select(.uses | test("^actions/checkout@")).with."persist-credentials")' \
    '.jobs.test.steps += [{"uses":"devantler-tech/.github/actions/run-dotnet-tests@main"}]' \
    '.jobs.test.uses = "devantler-tech/.github/.github/workflows/run-dotnet-tests.yaml@main"'; do
    yq "$mutation" "$scratch/validation-base.yaml" >"$scratch/validation.yaml"
    if check_validation "$scratch/validation.yaml"; then
      echo "FAIL: validation accepted unsafe mutation: $mutation" >&2
      exit 1
    fi
  done
done
for preparation in '.' '.jobs.package.steps = [{"name":"Additional preparation", "run":"true"}] + .jobs.package.steps'; do
  yq "$preparation" "$root/.github/workflows/publish.yaml" >"$scratch/publisher-base.yaml"
  check_publisher "$scratch/publisher-base.yaml"
  for mutation in \
    'del(.concurrency)' \
    '.concurrency."cancel-in-progress" = true' \
    '.permissions.contents = "write"' \
    '.jobs.publish.uses = "devantler-tech/.github/.github/workflows/publish-dotnet-library.yaml@main"' \
    'del(.jobs.package.steps[] | select(.uses | test("^actions/checkout@")).with."persist-credentials")' \
    '(.jobs.publish.steps[] | select(.env.NUGET_API_KEY)).env.NUGET_API_KEY = "wrong-secret"'; do
    yq "$mutation" "$scratch/publisher-base.yaml" >"$scratch/publisher.yaml"
    if check_publisher "$scratch/publisher.yaml"; then
      echo "FAIL: publication accepted unsafe mutation: $mutation" >&2
      exit 1
    fi
  done
done
echo 'PASS: repository-owned .NET workflow boundaries and negative controls'
