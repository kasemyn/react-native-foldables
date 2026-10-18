#!/usr/bin/env bash
# Runs audit.sh against every fixtures/<scenario> dir and compares output and exit code.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIT_SCRIPT="$SCRIPT_DIR/audit.sh"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
failed_scenarios=0
passed_scenarios=0

audit_output_without_boilerplate() {
  sed -E 's/(blocking)\. Static checks only.*/\1./'
}

assert_scenario() {
  local scenario_dir="$1" scenario_name actual_output actual_exit_code expected_exit_code
  scenario_name=$(basename "$scenario_dir")
  actual_output=$(bash "$AUDIT_SCRIPT" "$scenario_dir" | audit_output_without_boilerplate; exit "${PIPESTATUS[0]}")
  actual_exit_code=$?
  expected_exit_code=$(cat "$scenario_dir/expected-exit-code")

  if [ "$actual_output" = "$(cat "$scenario_dir/expected-output.txt")" ] && [ "$actual_exit_code" = "$expected_exit_code" ]; then
    echo "PASS  $scenario_name"
    passed_scenarios=$((passed_scenarios + 1))
    return
  fi
  echo "FAIL  $scenario_name (exit $actual_exit_code, expected $expected_exit_code)"
  diff <(printf '%s\n' "$actual_output") "$scenario_dir/expected-output.txt" | sed 's/^/      /'
  failed_scenarios=$((failed_scenarios + 1))
}

for scenario_dir in "$FIXTURES_DIR"/*/; do
  assert_scenario "${scenario_dir%/}"
done

echo
echo "${passed_scenarios} passed, ${failed_scenarios} failed"
[ "$failed_scenarios" -eq 0 ]
