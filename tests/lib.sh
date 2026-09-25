#!/usr/bin/env bash
# Shared helpers for tests/*.test.sh. Source, don't execute.

TESTS_RUN=0
TESTS_FAILED=0

pass() { TESTS_RUN=$((TESTS_RUN + 1)); echo "  ok   $1"; }
fail() { TESTS_RUN=$((TESTS_RUN + 1)); TESTS_FAILED=$((TESTS_FAILED + 1)); echo "  FAIL $1"; shift; for line in "$@"; do echo "       $line"; done; }

assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then pass "$name"; else fail "$name" "expected: $expected" "actual:   $actual"; fi
}

assert_contains() {
  local name="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then pass "$name"; else fail "$name" "expected to contain: $needle" "output: $haystack"; fi
}

assert_not_contains() {
  local name="$1" needle="$2" haystack="$3"
  if [[ "$haystack" != *"$needle"* ]]; then pass "$name"; else fail "$name" "expected NOT to contain: $needle" "output: $haystack"; fi
}

finish() {
  echo "$TESTS_RUN run, $TESTS_FAILED failed"
  [[ "$TESTS_FAILED" -eq 0 ]]
}
