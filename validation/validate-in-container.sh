#!/usr/bin/env bash
set -u

EXPECTED_CSV="/expected-failing-tests.csv"

csv_escape() {
  printf '%s' "$1" | sed 's/"/""/g; s/^/"/; s/$/"/'
}

expected_tests() {
  local project="$1"
  local bug="$2"

  awk -F';' -v p="$project" -v b="$bug" '
    NR == 1 { next }
    $1 == p && $2 == b {
      for (i = 3; i <= NF; i++) {
        gsub(/^[ \t]+|[ \t]+$/, "", $i)
        if ($i != "") print $i
      }
    }
  ' "$EXPECTED_CSV" | sort -u
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

if [[ ! -f "$EXPECTED_CSV" ]]; then
  echo "Expected CSV not found: $EXPECTED_CSV" >&2
  exit 2
fi

if [[ "$#" -eq 0 ]]; then
  echo "Usage inside container: validate-in-container.sh Project-BugID [...]" >&2
  exit 2
fi

printf "Project;Bug;Status;ExpectedCount;ObservedCount;Missing;Unexpected\n"

for bug_id in "$@"; do
  project="${bug_id%-*}"
  bug="${bug_id##*-}"
  workdir="/work/$project/$bug"
  log="/tmp/${project}-${bug}.test.log"

  printf '%s;%s;' \
    "$project" \
    "$bug"

  rm -rf "$workdir"

  if ! d4j-checkout "$project-$bug" >/tmp/checkout.log 2>&1; then
    printf "CHECKOUT_FAILED;0;0;;\n"
    continue
  fi

  cd "$workdir" || {
    printf "CD_FAILED;0;0;;\n"
    continue
  }

  defects4j test >"$log" 2>&1

  expected_file="/tmp/${project}-${bug}.expected"
  observed_file="/tmp/${project}-${bug}.observed"

  expected_tests "$project" "$bug" >"$expected_file"
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
done
