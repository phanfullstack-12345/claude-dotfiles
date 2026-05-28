#!/usr/bin/env bash
# artifact-gate.sh — PreToolUse hook that blocks risky shipping commands
# unless the current working directory has the required artifacts under
# .claude-artifacts/. Skip the gate by setting CLAUDE_SKIP_ARTIFACT_GATE=1.
#
# Reads the PreToolUse JSON payload on stdin. Emits a JSON decision on stdout.
#
# Required artifacts to ship (presence + non-empty + valid JSON where applicable):
#   spec.md OR diagnosis.md   (one of)
#   plan.md
#   verification.json         (parse-able, "all_green": true if present)
#   review-decision.json      (decision in {PASS, PASS_WITH_RISK})

set -u

INPUT="$(cat /dev/stdin 2>/dev/null || echo '{}')"
CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo '')"

# Trigger patterns — commands that "ship" something.
SHIP_PATTERN='(^|[^a-z])git[[:space:]]+push([[:space:]]|$)|(^|[^a-z])gh[[:space:]]+pr[[:space:]]+create|(^|[^a-z])npm[[:space:]]+publish|(^|[^a-z])pnpm[[:space:]]+publish|(^|[^a-z])vercel[[:space:]]+deploy|(^|[^a-z])fly[[:space:]]+deploy|kubectl[[:space:]]+apply.*prod'

# Bail if not a shipping command, or escape hatch is set, or no command captured.
if [ -z "$CMD" ] || ! printf '%s' "$CMD" | grep -qE "$SHIP_PATTERN"; then
  printf '%s' '{"decision":"allow"}'
  exit 0
fi
if [ "${CLAUDE_SKIP_ARTIFACT_GATE:-0}" = "1" ]; then
  printf '%s' '{"decision":"allow"}'
  exit 0
fi

# Find artifacts dir at git-root if possible, otherwise fall back to $PWD.
# This makes the gate work regardless of which subdirectory the Bash command was invoked from.
GIT_ROOT="$(git -C "${PWD}" rev-parse --show-toplevel 2>/dev/null || true)"
ART_DIR="${GIT_ROOT:-$PWD}/.claude-artifacts"

# If no artifact dir at all, allow but warn — user may not have run /fix or /cook this session.
# We only block when a partial set exists (signal: someone ran the workflow and skipped a phase).
if [ ! -d "$ART_DIR" ]; then
  printf '%s' '{"decision":"allow","systemMessage":"artifact-gate: no .claude-artifacts/ found — assuming non-workflow command. If you ran /fix or /cook, populate the artifacts before shipping."}'
  exit 0
fi

missing=()
[ -s "$ART_DIR/plan.md" ] || missing+=("plan.md")

# spec.md OR diagnosis.md (one of)
if [ ! -s "$ART_DIR/spec.md" ] && [ ! -s "$ART_DIR/diagnosis.md" ]; then
  missing+=("spec.md OR diagnosis.md")
fi

# verification.json
if [ ! -s "$ART_DIR/verification.json" ]; then
  missing+=("verification.json")
else
  if ! jq -e . "$ART_DIR/verification.json" >/dev/null 2>&1; then
    missing+=("verification.json (invalid JSON)")
  fi
fi

# review-decision.json — must parse and decision must be PASS or PASS_WITH_RISK
if [ ! -s "$ART_DIR/review-decision.json" ]; then
  missing+=("review-decision.json")
else
  decision="$(jq -r '.decision // empty' "$ART_DIR/review-decision.json" 2>/dev/null || echo '')"
  case "$decision" in
    PASS|PASS_WITH_RISK) ;;
    *) missing+=("review-decision.json (decision must be PASS or PASS_WITH_RISK, got: '$decision')") ;;
  esac
fi

if [ ${#missing[@]} -eq 0 ]; then
  printf '%s' '{"decision":"allow","systemMessage":"artifact-gate: all artifacts present, ship approved."}'
  exit 0
fi

# Block with a structured reason.
reason="ARTIFACT GATE BLOCKED: shipping command '${CMD}' refused. Missing or invalid artifacts under .claude-artifacts/: $(printf '%s, ' "${missing[@]}" | sed 's/, $//'). Complete the /fix or /cook workflow, OR set CLAUDE_SKIP_ARTIFACT_GATE=1 to override for this command."
# JSON-escape the reason
reason_json="$(printf '%s' "$reason" | jq -Rs .)"
printf '{"decision":"block","reason":%s}' "$reason_json"
