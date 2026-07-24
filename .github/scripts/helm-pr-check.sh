#!/usr/bin/env bash

set -uo pipefail

base_sha="${1:-}"
head_sha="${2:-HEAD}"

if [[ -z "$base_sha" ]]; then
  echo "Usage: $0 <base-sha> [head-sha]" >&2
  exit 2
fi

report="${HELM_PR_REPORT:-${GITHUB_STEP_SUMMARY:-helm-pr-check-summary.md}}"
work_dir="$(mktemp -d)"
base_tree="$work_dir/base"
head_tree="$work_dir/head"
mkdir -p "$base_tree" "$head_tree"
: > "$report"

finish() {
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" && "$report" != "$GITHUB_STEP_SUMMARY" && -f "$report" ]]; then
    cat "$report" >> "$GITHUB_STEP_SUMMARY"
  fi
  rm -rf "$work_dir"
}
trap finish EXIT

status=0

append_report() {
  printf '%s\n' "$*" >> "$report"
}

metadata_value() {
  local chart_file="$1"
  local key="$2"

  sed -nE "s/^${key}:[[:space:]]*[\"']?([^\"'#[:space:]]+)[\"']?.*$/\1/p" \
    "$chart_file" | head -n 1
}

prepare_chart() {
  local chart_dir="$1"

  if grep -qE '^dependencies:[[:space:]]*$' "$chart_dir/Chart.yaml"; then
    helm dependency build "$chart_dir" >/dev/null
  fi
}

render_chart() {
  local chart_dir="$1"
  local release_name="$2"
  local destination="$3"

  helm template "$release_name" "$chart_dir" \
    --namespace helm-diff \
    --include-crds > "$destination"
}

if ! git archive "$base_sha" | tar -x -C "$base_tree"; then
  echo "Could not extract base commit $base_sha." >&2
  exit 2
fi
if ! git archive "$head_sha" | tar -x -C "$head_tree"; then
  echo "Could not extract head commit $head_sha." >&2
  exit 2
fi

declare -A changed_charts=()
while IFS= read -r -d '' path; do
  if [[ "$path" =~ ^charts/([^/]+)/ ]]; then
    changed_charts["${BASH_REMATCH[1]}"]=1
  fi
done < <(git diff --name-only -z "$base_sha" "$head_sha" -- charts/)

mapfile -t chart_names < <(printf '%s\n' "${!changed_charts[@]}" | sort)

append_report "## Helm PR validation"
append_report ""
append_report "Compared \`${base_sha:0:12}\` with \`${head_sha:0:12}\` using Helm \`$(helm version --short)\`."
append_report ""

if [[ "${#chart_names[@]}" -eq 0 ]]; then
  append_report "No chart changes were detected."
  exit 0
fi

append_report "| Chart | Chart version | App version | Result |"
append_report "|---|---|---|---|"

for chart_name in "${chart_names[@]}"; do
  base_chart="$base_tree/charts/$chart_name"
  head_chart="$head_tree/charts/$chart_name"
  base_chart_file="$base_chart/Chart.yaml"
  head_chart_file="$head_chart/Chart.yaml"
  chart_status="passed"

  old_version="-"
  new_version="-"
  old_app_version="-"
  new_app_version="-"

  if [[ -f "$base_chart_file" ]]; then
    old_version="$(metadata_value "$base_chart_file" version)"
    old_app_version="$(metadata_value "$base_chart_file" appVersion)"
  fi
  if [[ -f "$head_chart_file" ]]; then
    new_version="$(metadata_value "$head_chart_file" version)"
    new_app_version="$(metadata_value "$head_chart_file" appVersion)"
  fi

  if [[ ! -f "$head_chart_file" ]]; then
    chart_status="removed"
  elif [[ -f "$base_chart_file" && "$old_version" == "$new_version" ]]; then
    chart_status="failed: version unchanged"
    status=1
  fi

  if [[ -f "$head_chart_file" ]]; then
    if ! prepare_chart "$head_chart" || ! helm lint "$head_chart"; then
      chart_status="failed: lint"
      status=1
    fi
  fi

  append_report "| \`$chart_name\` | \`$old_version\` → \`$new_version\` | \`$old_app_version\` → \`$new_app_version\` | $chart_status |"
done

append_report ""
append_report "### Rendered manifest changes"
append_report ""
append_report "The manifests below use each chart's default \`values.yaml\`. Chart-specific production values should be added as separate render scenarios when they become available in this repository."

for chart_name in "${chart_names[@]}"; do
  base_chart="$base_tree/charts/$chart_name"
  head_chart="$head_tree/charts/$chart_name"
  base_chart_file="$base_chart/Chart.yaml"
  head_chart_file="$head_chart/Chart.yaml"
  base_render="$work_dir/$chart_name-base.yaml"
  head_render="$work_dir/$chart_name-head.yaml"
  manifest_diff="$work_dir/$chart_name.diff"
  release_name="$(printf 'pr-%s' "$chart_name" | tr -cd '[:alnum:]-' | cut -c1-53)"

  append_report ""
  append_report "<details>"
  append_report "<summary><code>$chart_name</code></summary>"
  append_report ""

  if [[ ! -f "$base_chart_file" ]]; then
    : > "$base_render"
  elif ! prepare_chart "$base_chart" || ! render_chart "$base_chart" "$release_name" "$base_render"; then
    append_report "Could not render the chart from the base commit."
    append_report ""
    append_report "</details>"
    status=1
    continue
  fi

  if [[ ! -f "$head_chart_file" ]]; then
    : > "$head_render"
  elif ! render_chart "$head_chart" "$release_name" "$head_render"; then
    append_report "Could not render the chart from the pull request."
    append_report ""
    append_report "</details>"
    status=1
    continue
  fi

  diff -u \
    --label "$chart_name (base)" \
    --label "$chart_name (pull request)" \
    "$base_render" "$head_render" > "$manifest_diff" || true

  if [[ ! -s "$manifest_diff" ]]; then
    append_report "No rendered manifest changes with default values."
  else
    append_report '```diff'
    head -n 600 "$manifest_diff" >> "$report"
    if [[ "$(wc -l < "$manifest_diff")" -gt 600 ]]; then
      append_report ""
      append_report "... diff truncated after 600 lines ..."
    fi
    append_report '```'
  fi

  append_report ""
  append_report "</details>"
done

append_report ""
if [[ "$status" -eq 0 ]]; then
  append_report "All changed charts passed validation."
else
  append_report "One or more charts failed validation. See the job log and table above."
fi

exit "$status"
