#!/usr/bin/env sh
# rename-placeholders.sh — turn this scaffold into your own project in one shot.
#
# Fresh from `Use this template`, the scaffold is named `Example`: an
# `Example.slnx` solution wiring `src/Example` (`Example.csproj` + `ExampleClass.cs`)
# to `tests/Example.Tests` (`Example.Tests.csproj` + `ExampleClassTests.cs`). That
# `Example` placeholder shows up as directory names, file names, the solution name,
# `<Project Path>` / `<ProjectReference>` paths, and `namespace` / type identifiers.
# Repointing it all by hand is tedious and easy to get half-wrong — a missed
# reference yields a confusing build error on first use — so this script renames
# every `Example` across the solution (.slnx), projects (.csproj), code (.cs) and
# the README in one shot, WITHOUT touching the references that must keep pointing
# at the upstream template:
#   • README's "Use this template" links (`--template devantler-tech/dotnet-template`
#     and the `[repository page]` link) name where the template lives — they carry
#     the `dotnet-template` token, never `Example`, so a rename leaves them intact.
# It also deliberately leaves the maintenance docs (`AGENTS.md`): those describe
# template-upkeep conventions, not your code, and are yours to adapt.
#
# Usage:  scripts/rename-placeholders.sh [ProjectName]
#   e.g.  scripts/rename-placeholders.sh Widget   ->  Widget.slnx, src/Widget, …
# With no argument it derives a PascalCase name from origin's GitHub repo name.
set -eu

OLD="Example"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# --- resolve the new project name -------------------------------------------
new_name="${1:-}"
if [ -z "$new_name" ]; then
  remote="$(git -C "$repo_root" remote get-url origin 2>/dev/null || true)"
  case "$remote" in
  *github.com[:/]*)
    repo="${remote##*/}" # owner/repo -> repo
    repo="${repo%.git}"
    # PascalCase: split the repo name on - _ . and capitalise each segment, so
    # `my-cool-app` -> `MyCoolApp` (an idiomatic .NET project name).
    new_name="$(printf '%s' "$repo" | awk 'BEGIN { RS = "[-_.]"; ORS = "" } { if (length($0) > 0) print toupper(substr($0, 1, 1)) substr($0, 2) }')"
    ;;
  esac
fi

if [ -z "$new_name" ]; then
  echo "usage: scripts/rename-placeholders.sh <ProjectName>" >&2
  echo "       e.g. scripts/rename-placeholders.sh Widget" >&2
  echo "       (could not derive a name from origin's GitHub remote)." >&2
  exit 1
fi

if [ "$new_name" = "$OLD" ]; then
  echo "error: the new name equals the template's own ($OLD)." >&2
  echo "       run this in a project created from the template, with your own name." >&2
  exit 1
fi

# A .NET project / namespace identifier: letter or underscore start, optionally
# dotted (e.g. Widget or Acme.Widget). Reject anything that is not one — it would
# yield an invalid namespace or an unbuildable project.
if ! printf '%s' "$new_name" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$'; then
  echo "error: '$new_name' is not a valid .NET project name (an identifier, optionally dotted)." >&2
  echo "       e.g. Widget or Acme.Widget" >&2
  exit 1
fi

# `Example` plays two roles: the solution / project / namespace name (which may be
# dotted, e.g. `Acme.Widget`) and the sample *type* prefix (`ExampleClass`,
# `ExampleClassTests`), which must stay a single identifier — a C# type name cannot
# contain a dot. So derive a dot-free token for the type names; for a non-dotted
# project name it is identical, leaving that common case unchanged.
type_token="$(printf '%s' "$new_name" | tr -d '.')"

cd "$repo_root"

# Use `git mv` when the tree is a git repo so history follows the renames; fall
# back to a plain `mv` otherwise.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  use_git_mv=1
else
  use_git_mv=0
fi

move() {
  # move SRC DST — skip silently if SRC is absent, so re-runs are idempotent.
  [ -e "$1" ] || return 0
  if [ "$use_git_mv" = 1 ]; then
    git mv "$1" "$2"
  else
    mv "$1" "$2"
  fi
}

# --- 1) rename directories and files (dir first, then its contents) ---------
move "src/$OLD" "src/$new_name"
move "src/$new_name/$OLD.csproj" "src/$new_name/$new_name.csproj"
move "src/$new_name/${OLD}Class.cs" "src/$new_name/${type_token}Class.cs"
move "tests/$OLD.Tests" "tests/$new_name.Tests"
move "tests/$new_name.Tests/$OLD.Tests.csproj" "tests/$new_name.Tests/$new_name.Tests.csproj"
move "tests/$new_name.Tests/${OLD}ClassTests.cs" "tests/$new_name.Tests/${type_token}ClassTests.cs"
move "$OLD.slnx" "$new_name.slnx"

# --- 2) rewrite file contents (solution, projects, code, README) ------------
# `$OLD`, `$new_name` and `$type_token` are validated identifiers (no `/` or sed
# metacharacters), so plain `s///g` substitutions are safe. Two passes, in order:
# first the type names (`ExampleClass`/`ExampleClassTests` -> the dot-free token),
# then everything else (`Example` -> the project name). The first pass must run
# before the second so a dotted project name never leaks a dot into a type name.
# Write to a temp file and `mv` rather than `sed -i`, whose syntax differs between
# GNU and BSD (macOS) sed.
changed=0
subst() {
  f="$1"
  [ -f "$f" ] || return 0
  tmp="$f.rename.$$"
  sed -e "s/${OLD}Class/${type_token}Class/g" -e "s/$OLD/$new_name/g" "$f" >"$tmp"
  if cmp -s "$f" "$tmp"; then
    rm -f "$tmp"
  else
    mv "$tmp" "$f"
    changed=$((changed + 1))
  fi
}

subst "$new_name.slnx"
subst "src/$new_name/$new_name.csproj"
subst "src/$new_name/${type_token}Class.cs"
# FeatureFlags.cs has no `Example` in its filename, so the directory move above
# carries it — but its contents (namespace, flag references) still need repointing.
subst "src/$new_name/FeatureFlags.cs"
subst "tests/$new_name.Tests/$new_name.Tests.csproj"
subst "tests/$new_name.Tests/${type_token}ClassTests.cs"
subst "README.md"

echo "renamed $OLD -> $new_name across $changed file(s) (plus directory/file renames)."
echo "next: review 'git diff', then 'dotnet build && dotnet test'."
