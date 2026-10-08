#!/usr/bin/env bash
# Post-deployment smoke test. Exits non-zero if any check fails so the pipeline can roll back.
set -euo pipefail
: "${SITE_URL:?}" "${EXPECTED_ENV:?}" "${EXPECTED_VERSION:?}"
HEALTH_PATH="${HEALTH_PATH:-/health.txt}"
ATTEMPTS="${ATTEMPTS:-12}"
DELAY="${DELAY:-5}"
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"
FAILED=0

{
  echo "### Smoke test: ${EXPECTED_ENV}"
  echo "| Check | Result |"
  echo "|---|---|"
} >> "$SUMMARY"

run_check() {
  local name="$1"
  shift
  for _ in $(seq 1 "$ATTEMPTS"); do
    if "$@" > /dev/null 2>&1; then
      echo "PASS  $name"
      echo "| $name | PASS |" >> "$SUMMARY"
      return 0
    fi
    sleep "$DELAY"
  done
  echo "FAIL  $name"
  echo "| $name | FAIL |" >> "$SUMMARY"
  FAILED=1
}

check_health() { curl -fsS "${SITE_URL}${HEALTH_PATH}" | grep -qx OK; }
check_page() { curl -fsS "${SITE_URL}/" | grep -q "Hello World"; }
check_version() { curl -fsS "${SITE_URL}/" | grep -q "Version: ${EXPECTED_VERSION}"; }
check_env() { [[ "$(curl -fsS "${SITE_URL}/config.json" | jq -r .environment)" == "${EXPECTED_ENV}" ]]; }

echo "Smoke testing ${SITE_URL} (env=${EXPECTED_ENV}, version=${EXPECTED_VERSION}, health=${HEALTH_PATH})"
run_check "Health endpoint returns OK (${HEALTH_PATH})" check_health
run_check "Home page serves Hello World" check_page
run_check "Deployed version is ${EXPECTED_VERSION}" check_version
run_check "Environment config is ${EXPECTED_ENV}" check_env

exit "$FAILED"
