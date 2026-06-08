#!/usr/bin/env bash
set -u

csv_escape() {
  printf '%s' "$1" | sed 's/"/""/g; s/^/"/; s/$/"/'
}

# Expected triggering tests come from the image's own, version-specific
# trigger_tests file. 
expected_tests() {
  local pid="$1"
  local bid="$2"
  local f="${D4J_HOME:-/opt/defects4j}/framework/projects/$pid/trigger_tests/$bid"

  [[ -f "$f" ]] && sed -n 's/^--- //p' "$f" | sort -u
}

observed_tests() {
  local dir="$1"
  local log="$2"

  if [[ -f "$dir/failing_tests" ]]; then
    grep '^--- ' "$dir/failing_tests" \
      | sed 's/^--- //' \
      | sort -u
  else
    grep -E '^[[:space:]]*-[[:space:]]+' "$log" \
      | sed -E 's/^[[:space:]]*-[[:space:]]+//' \
      | sort -u
  fi
}

if [[ "$#" -eq 0 ]]; then
  mapfile -t BUG_IDS < <(d4j-list)
else
  BUG_IDS=("$@")
fi

printf "Project;Bug;Status;ExpectedCount;ObservedCount;Missing;Unexpected\n"

for bug_id in "${BUG_IDS[@]}"; do
  pid="${bug_id%-*}"
  bid="${bug_id##*-}"
  workdir="/work/$pid/$bid"
  log="/tmp/$pid-$bid.test.log"

  printf '%s;%s;' \
    "$pid" \
    "$bid"

  rm -rf "$workdir"

  if ! d4j-checkout "$pid-$bid" >/tmp/checkout.log 2>&1; then
    printf "CHECKOUT_FAILED;0;0;;\n"
    continue
  fi

  cd "$workdir" || {
    printf "CD_FAILED;0;0;;\n"
    continue
  }

  defects4j test >"$log" 2>&1

  expected_file="/tmp/$pid-$bid.expected"
  observed_file="/tmp/$pid-$bid.observed"

  expected_tests "$pid" "$bid" >"$expected_file"
  observed_tests "$workdir" "$log" >"$observed_file"

  missing="$(comm -23 "$expected_file" "$observed_file" | paste -sd ',' -)"
  unexpected="$(comm -13 "$expected_file" "$observed_file" | paste -sd ',' -)"

  expected_count="$(wc -l <"$expected_file" | tr -d ' ')"
  observed_count="$(wc -l <"$observed_file" | tr -d ' ')"

  if [[ -z "$missing" && -z "$unexpected" ]]; then
    status="OK"
  else
    status="MISMATCH"
  fi

  printf '%s;%s;%s;%s;%s\n' \
    "$status" \
    "$expected_count" \
    "$observed_count" \
    "$(csv_escape "$missing")" \
    "$(csv_escape "$unexpected")"

  cd /work
  rm -rf "$workdir"
done
