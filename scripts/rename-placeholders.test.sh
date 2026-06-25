#!/usr/bin/env sh
# rename-placeholders.test.sh — exercise scripts/rename-placeholders.sh end-to-end.
#
# rename-placeholders.sh is the first thing a newcomer runs after `Use this
# template`. A silent regression in it — a missed file, a botched sed that leaks a
# dot into a C# type name, or a rewritten upstream link — ships broken to every
# project created from this template, and it has no other coverage. This test pins
# its real behaviour:
#   * the Example scaffold (.slnx, src/, tests/, code, README) is repointed to the
#     new project name,
#   * a DOTTED project name (e.g. `Acme.Widget`) keeps the namespace dotted but
#     strips the dot from the C# *type* names (`AcmeWidgetClass`) — a C# type
#     identifier cannot contain a dot,
#   * the upstream "Use this template" links (the repository-page URL and the
#     `--template devantler-tech/dotnet-template` flag) are LEFT INTACT,
#   * the maintenance docs (`AGENTS.md`) are LEFT UNTOUCHED,
#   * no stray sed temp files are left behind,
#   * the renamed scaffold still builds and tests, and
#   * the input guardrails reject an invalid name and the template's own name.
#
# It runs the script against a throwaway copy so the real working tree is never
# mutated. Run locally with `sh scripts/rename-placeholders.test.sh`; CI runs it
# via .github/workflows/validate-scaffold.yaml.
set -eu

OLD="Example"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

fail() {
	echo "FAIL: $*" >&2
	exit 1
}

# Build a throwaway copy of the working tree and make it its own git repo, so the
# script's `git rev-parse` / `git mv` see exactly the template's files in
# isolation. Echoes the new copy's path. Everything operating on it runs in a
# subshell so the caller's cwd is never disturbed.
make_copy() {
	work="$(mktemp -d)"
	cp -R "$repo_root"/. "$work"/
	rm -rf "$work/.git"
	(
		cd "$work"
		git init -q
		git add .
		git -c user.email=test@example.com -c user.name=test commit -qm init
	)
	printf '%s' "$work"
}

# ============================================================================
# Case 1: guardrails — each must reject, exit non-zero, and mutate nothing.
# ============================================================================
work1="$(make_copy)"
trap 'rm -rf "$work1" "${work2:-}" "${work3:-}"' EXIT
cd "$work1"
script="./scripts/rename-placeholders.sh"

if "$script" "$OLD" >/dev/null 2>&1; then
	fail "expected rejection when the new name equals the template's own ($OLD)"
fi
if "$script" "not a name" >/dev/null 2>&1; then
	fail "expected rejection of an invalid name (contains spaces)"
fi
if "$script" "bad-name" >/dev/null 2>&1; then
	fail "expected rejection of an invalid .NET identifier (contains a hyphen)"
fi
if "$script" "1Bad" >/dev/null 2>&1; then
	fail "expected rejection of an invalid .NET identifier (starts with a digit)"
fi
if ! git diff --quiet; then
	fail "a rejected invocation modified the tree — guardrails must bail out first"
fi

# ============================================================================
# Case 2: happy path with a simple name — full rename, then build & test.
# ============================================================================
work2="$(make_copy)"
cd "$work2"
"$script" "Widget"

# 2a) Directories/files renamed; the Example originals are gone.
for p in \
	"Widget.slnx" \
	"src/Widget/Widget.csproj" \
	"src/Widget/WidgetClass.cs" \
	"tests/Widget.Tests/Widget.Tests.csproj" \
	"tests/Widget.Tests/WidgetClassTests.cs"; do
	[ -f "$p" ] || fail "expected renamed file missing: $p"
done
for p in "Example.slnx" "src/Example" "tests/Example.Tests"; do
	[ -e "$p" ] && fail "template original should be gone after rename: $p"
done

# 2b) Contents repointed; no Example remnant in the solution/project/code files
#     (README keeps the dotnet-template upstream tokens, AGENTS.md is untouched —
#     both checked separately below, so scope this to *.slnx/*.csproj/*.cs).
grep -q "^namespace Widget;" "src/Widget/WidgetClass.cs" ||
	fail "namespace not repointed in WidgetClass.cs"
grep -qF 'Project Path="src/Widget/Widget.csproj"' "Widget.slnx" ||
	fail "solution Project Path not repointed in Widget.slnx"
grep -qF '..\src\Widget\Widget.csproj' "tests/Widget.Tests/Widget.Tests.csproj" ||
	fail "test ProjectReference not repointed to the renamed library"
if git grep -qw "$OLD" -- '*.slnx' '*.csproj' '*.cs'; then
	fail "template name '$OLD' still present in a .slnx/.csproj/.cs file after rename"
fi

# 2c) Upstream "Use this template" links LEFT INTACT (carry the dotnet-template
#     token, never Example — must survive the rename).
grep -qF "https://github.com/devantler-tech/dotnet-template" README.md ||
	fail "repository-page upstream link was not preserved"
grep -qF -- "--template devantler-tech/dotnet-template" README.md ||
	fail "--template upstream link was not preserved"

# 2d) Maintenance docs LEFT UNTOUCHED (the script deliberately skips AGENTS.md).
git diff --quiet -- AGENTS.md ||
	fail "AGENTS.md was modified — the script must leave the maintenance docs alone"

# 2e) No stray temp files left behind by the in-place sed.
if git status --porcelain --untracked-files=all | grep -q '\.rename\.'; then
	fail "stray *.rename.* temp file left behind"
fi

# 2f) The renamed scaffold still builds and tests.
dotnet build
dotnet test

# ============================================================================
# Case 3: a DOTTED name — namespace stays dotted, C# type names drop the dot.
#         This is the subtle, easy-to-break branch of the script (type_token).
# ============================================================================
work3="$(make_copy)"
cd "$work3"
"$script" "Acme.Widget"

# Solution/project paths and dirs use the dotted name…
for p in \
	"Acme.Widget.slnx" \
	"src/Acme.Widget/Acme.Widget.csproj" \
	"tests/Acme.Widget.Tests/Acme.Widget.Tests.csproj"; do
	[ -f "$p" ] || fail "expected dotted-name file missing: $p"
done
# …but the type files and identifiers drop the dot (a C# type can't contain one).
[ -f "src/Acme.Widget/AcmeWidgetClass.cs" ] ||
	fail "type file should use the dot-free token: AcmeWidgetClass.cs"
[ -f "tests/Acme.Widget.Tests/AcmeWidgetClassTests.cs" ] ||
	fail "test type file should use the dot-free token: AcmeWidgetClassTests.cs"
grep -q "^namespace Acme.Widget;" "src/Acme.Widget/AcmeWidgetClass.cs" ||
	fail "namespace should stay dotted (Acme.Widget) in the dotted-name case"
grep -q "class AcmeWidgetClass" "src/Acme.Widget/AcmeWidgetClass.cs" ||
	fail "type name should drop the dot (AcmeWidgetClass) in the dotted-name case"

echo "PASS: rename-placeholders.sh end-to-end (guardrails + rename + dotted-name type token + upstream-link & AGENTS.md preservation + build/test)"
