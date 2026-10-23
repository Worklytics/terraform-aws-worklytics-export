#!/usr/bin/env bash
# REQUIRES: git
# DESCRIPTION: Print GitHub release notes for a tag to stdout.
#
# Prefers the matching CHANGELOG.md section, remaps Added/Fixed to Features/Fixes,
# and hoists breaking changes to the top. Falls back to categorizing merged PRs.
# Omits GitHub's "New Contributors" / author shout-outs.

set -euo pipefail

usage() {
  echo "Usage: $0 <tag>" >&2
  echo "  tag  e.g. v1.2.3 (GITHUB_REF_NAME is used if omitted in Actions)" >&2
  exit 1
}

TAG="${1:-${GITHUB_REF_NAME:-}}"
if [[ -z "$TAG" ]]; then
  usage
fi

ROOT="$(git rev-parse --show-toplevel)"
CHANGELOG="${ROOT}/CHANGELOG.md"
VERSION="${TAG#v}"

github_repo() {
  if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
    echo "${GITHUB_REPOSITORY}"
    return
  fi
  local url
  url="$(git remote get-url origin 2>/dev/null || true)"
  url="${url%.git}"
  url="${url#git@github.com:}"
  url="${url#https://github.com/}"
  url="${url#ssh://git@github.com/}"
  echo "${url}"
}

previous_tag() {
  # Semver order, not git ancestry — tags in this repo are not always ancestors
  # of main (e.g. v0.5.0 was cut from a merge commit off to the side).
  git tag -l 'v[0-9]*' --sort=v:refname | awk -v cur="${TAG}" '
    $0 == cur { print prev; exit }
    { prev = $0 }
    END { if ($0 != cur && $0 != "") print $0 }
  '
}

# Extract a ## [heading] section from CHANGELOG.md (body only, no ## heading).
extract_changelog_section() {
  local heading="$1"
  awk -v heading="${heading}" '
    BEGIN { p = 0 }
    /^## \[/ {
      if (p) exit
      if ($0 ~ "^## \\[" heading "\\]") {
        p = 1
        next
      }
      next
    }
    p { print }
  ' "${CHANGELOG}"
}

# Drop Keep-a-Changelog process notes like "Next release should be ...".
strip_process_notes() {
  awk '
    /^>/ && /Next release should be/ { skip = 1; next }
    skip && /^>/ { next }
    skip && /^[[:space:]]*$/ { skip = 0; next }
    { skip = 0; print }
  '
}

# Remap Keep-a-Changelog headings, hoist breaking-change bullets, emit in a
# stable order. Blank / heading-only input prints nothing.
format_changelog_body() {
  awk '
    function remap(h) {
      if (h == "### Added") return "### Features"
      if (h == "### Fixed") return "### Fixes"
      if (h == "### Changed") return "### Changes"
      if (h ~ /^### [Bb]reaking/) return "### Breaking changes"
      return h
    }
    function flush_bullet(    is_breaking) {
      if (bullet == "") return
      is_breaking = (tolower(bullet) ~ /breaking change/)
      if (is_breaking && cur != "### Breaking changes") {
        breaking = breaking bullet
      } else {
        buf = buf bullet
      }
      bullet = ""
    }
    function store_section() {
      flush_bullet()
      if (cur != "") {
        sub(/\n+$/, "", buf)
        sections[cur] = buf "\n"
      }
      buf = ""
    }
    function nonempty(s) {
      return (s ~ /[^[:space:]]/)
    }
    function dump(title) {
      body = (title == "### Breaking changes") ? (breaking sections[title]) : sections[title]
      if (!nonempty(body)) return
      if (emitted) print ""
      print title
      printf "%s", body
      if (body !~ /\n$/) print ""
      emitted = 1
      seen[title] = 1
    }
    /^### / {
      store_section()
      cur = remap($0)
      buf = ""
      bullet = ""
      next
    }
    /^- / {
      flush_bullet()
      bullet = $0 "\n"
      next
    }
    /^[[:space:]]*$/ {
      next
    }
    {
      if (bullet != "") {
        bullet = bullet $0 "\n"
      } else {
        buf = buf $0 "\n"
      }
    }
    END {
      store_section()
      dump("### Breaking changes")
      dump("### Features")
      dump("### Fixes")
      dump("### Changes")
      dump("### Deprecated")
      dump("### Removed")
      dump("### Security")
      for (h in sections) {
        if (!seen[h]) dump(h)
      }
    }
  '
}

changelog_has_content() {
  local text="$1"
  # Ignore headings and blank lines when deciding whether the section is empty.
  echo "${text}" | grep -vE '^[[:space:]]*$|^#' | grep -q '[^[:space:]]'
}

REPO="$(github_repo)"
PREV="$(previous_tag)"

changelog_body=""
if [[ -f "${CHANGELOG}" ]]; then
  raw="$(extract_changelog_section "${VERSION}")"
  if ! changelog_has_content "${raw}"; then
    raw="$(extract_changelog_section "v${VERSION}")"
  fi
  if ! changelog_has_content "${raw}"; then
    # Tag may have been cut before Unreleased was promoted.
    raw="$(extract_changelog_section "Unreleased")"
  fi
  if changelog_has_content "${raw}"; then
    changelog_body="$(printf '%s\n' "${raw}" | strip_process_notes | format_changelog_body)"
    if ! changelog_has_content "${changelog_body}"; then
      changelog_body=""
    fi
  fi
fi

categorize_pr() {
  local title="$1"
  local labels="$2"
  local t
  t="$(printf '%s' "${title}" | tr '[:upper:]' '[:lower:]')"
  labels="$(printf '%s' "${labels}" | tr '[:upper:]' '[:lower:]')"

  if [[ "${labels}" == *breaking* || "${t}" == *breaking* ]]; then
    echo breaking
    return
  fi
  if [[ "${labels}" == *bug* ]]; then
    echo fixes
    return
  fi
  if [[ "${labels}" == *enhancement* ]]; then
    echo features
    return
  fi
  if [[ "${labels}" == *documentation* ]]; then
    echo docs
    return
  fi
  if [[ "${t}" =~ (^|[^[:alpha:]])(fix|fixed|fixes|bugfix|hotfix)([^[:alpha:]]|$) ]]; then
    echo fixes
    return
  fi
  if [[ "${t}" =~ (^|[^[:alpha:]])(feat|feature)([^[:alpha:]]|$) ]]; then
    echo features
    return
  fi
  if [[ "${t}" =~ (^|[^[:alpha:]])(added|adds|adding|add)([^[:alpha:]]|$) ]]; then
    echo features
    return
  fi
  if [[ "${t}" =~ (^|[^[:alpha:]])(support)([^[:alpha:]]|$) ]]; then
    echo features
    return
  fi
  if [[ "${t}" =~ (^|[^[:alpha:]])(docs?|documentation|readme)([^[:alpha:]]|$) ]]; then
    echo docs
    return
  fi
  if [[ "${t}" =~ (^|[^[:alpha:]])(ci|tests?|testing|workflow|lint)([^[:alpha:]]|$) ]]; then
    echo ci
    return
  fi
  echo other
}

# Populate categorized PR arrays from git history (no authors / contributors).
pr_breaking=()
pr_features=()
pr_fixes=()
pr_docs=()
pr_ci=()
pr_other=()
full_changelog=""

load_prs_from_git() {
  local range_end="${TAG}"
  if ! git rev-parse "${TAG}^{commit}" >/dev/null 2>&1; then
    range_end="HEAD"
  fi
  local log_range
  if [[ -n "${PREV}" ]]; then
    log_range="${PREV}..${range_end}"
  else
    log_range="${range_end}"
  fi

  local subject num title url cat item seen_prs=" "
  while IFS= read -r subject; do
    num=""
    title=""
    if [[ "${subject}" =~ Merge\ pull\ request\ #([0-9]+) ]]; then
      num="${BASH_REMATCH[1]}"
      title="${subject}"
    elif [[ "${subject}" =~ \(#([0-9]+)\) ]]; then
      num="${BASH_REMATCH[1]}"
      title="$(printf '%s' "${subject}" | sed -E "s/[[:space:]]*\\(#${num}\\)[[:space:]]*$//")"
    else
      continue
    fi
    if [[ "${seen_prs}" == *" ${num} "* ]]; then
      continue
    fi
    seen_prs="${seen_prs}${num} "
    url="https://github.com/${REPO}/pull/${num}"
    cat="$(categorize_pr "${title}" "")"
    item="- [${title}](${url})"
    case "${cat}" in
      breaking) pr_breaking+=("${item}") ;;
      features) pr_features+=("${item}") ;;
      fixes) pr_fixes+=("${item}") ;;
      docs) pr_docs+=("${item}") ;;
      ci) pr_ci+=("${item}") ;;
      *) pr_other+=("${item}") ;;
    esac
  done < <(git log "${log_range}" --pretty='%s')
}

emit_pr_section() {
  local heading="$1"
  shift
  if [[ "$#" -eq 0 ]]; then
    return
  fi
  echo "### ${heading}"
  echo
  local item
  for item in "$@"; do
    echo "${item}"
  done
  echo
}

if [[ -z "${changelog_body}" ]]; then
  load_prs_from_git
fi

if [[ -z "${full_changelog}" && -n "${REPO}" && -n "${PREV}" ]]; then
  full_changelog="**Full Changelog**: https://github.com/${REPO}/compare/${PREV}...${TAG}"
elif [[ -z "${full_changelog}" && -n "${REPO}" ]]; then
  full_changelog="**Full Changelog**: https://github.com/${REPO}/releases/tag/${TAG}"
fi

{
  if [[ -n "${changelog_body}" ]]; then
    printf '%s\n' "${changelog_body}"
    echo
  else
    emit_pr_section "Breaking changes" "${pr_breaking[@]+"${pr_breaking[@]}"}"
    emit_pr_section "Features" "${pr_features[@]+"${pr_features[@]}"}"
    emit_pr_section "Fixes" "${pr_fixes[@]+"${pr_fixes[@]}"}"
    emit_pr_section "Documentation" "${pr_docs[@]+"${pr_docs[@]}"}"
    emit_pr_section "Tests & CI" "${pr_ci[@]+"${pr_ci[@]}"}"
    emit_pr_section "Other changes" "${pr_other[@]+"${pr_other[@]}"}"
  fi
  if [[ -n "${full_changelog}" ]]; then
    echo "${full_changelog}"
  fi
}
