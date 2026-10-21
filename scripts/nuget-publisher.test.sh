#!/usr/bin/env bash
# Run the actual secret-bearing workflow step with a non-networking command boundary.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
workflow="$root/.github/workflows/publish.yaml"
yq -o=json '.' "$workflow" >"$scratch/workflow.json"
# A separate runner prevents tagged code from altering the publisher or leaving a process behind.
jq -e '
  .jobs.package.permissions == {"contents":"read"} and
  .jobs.publish.needs == "package" and
  .jobs.publish.permissions == {"id-token":"write"} and
  ([.env // {}, .jobs.package.env // {}, .jobs.package.steps[].env // {}] |
    tostring | contains("secrets.") | not) and
  ([.jobs.publish.steps[] | select(.uses? | strings | startswith("actions/checkout@"))] | length) == 0 and
  ([.jobs.publish.steps[] | select(.run?)] | length) == 1 and
  ([.jobs.publish.steps[] | select(.uses? | strings | startswith("NuGet/login@"))] |
    length == 1 and .[0].id == "login" and .[0].with.user == "${{ vars.NUGET_USER }}") and
  ([.jobs.publish.steps[] | select(.env.NUGET_API_KEY? == "${{ steps.login.outputs.NUGET_API_KEY }}")] | length) == 1
' "$scratch/workflow.json" >/dev/null || {
  echo 'FAIL: package code must be isolated from short-lived publication credentials' >&2
  exit 1
}
jq -r '.jobs.publish.steps[] | select(.run?).run' "$scratch/workflow.json" >"$scratch/push.sh"
mkdir -p "$scratch/bin" "$scratch/packages"
printf 'package bytes\n' >"$scratch/packages/Example.1.2.3.nupkg"
cat >"$scratch/bin/dotnet" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
[[ $# == 7 && $1 == nuget && $2 == push && $3 == 'packages/*.nupkg' &&
  $4 == --source && $5 == https://api.nuget.org/v3/index.json &&
  $6 == --api-key && $7 == credential-fixture ]] || exit 51
cp packages/Example.1.2.3.nupkg delivered.nupkg
SH
chmod +x "$scratch/bin/dotnet"
(cd "$scratch"; PATH="$scratch/bin:$PATH" NUGET_API_KEY=credential-fixture bash push.sh)
cmp "$scratch/packages/Example.1.2.3.nupkg" "$scratch/delivered.nupkg"
if (cd "$scratch"; PATH="$scratch/bin:$PATH" NUGET_API_KEY='' bash push.sh) >"$scratch/no-key" 2>&1; then
  echo 'FAIL: publication accepted an absent credential' >&2
  exit 1
fi
echo 'PASS: clean publisher sends only prepared package bytes and refuses an absent key'
