#!/usr/bin/env bash
# Richtet die GitHub-Einstellungen des Repos per gh CLI ein. Kann gefahrlos erneut ausgeführt werden.
#
# Voraussetzungen: `gh auth login` mit Admin-Rechten auf dem Repo, und der erste Push nach main ist erfolgt
# (das Ruleset verbietet direkte Pushes auf main).
#
# Aufruf: ./scripts/github-setup.sh [OWNER/REPO]
set -euo pipefail

REPO="${1:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}"

# Name des Pflicht-Checks: <Job-ID in ci.yml> / <Job-Name in rust.yml>.
# Stimmt er nicht, bleiben PRs auf "Expected - waiting for status" hängen: Name im ersten PR prüfen.
REQUIRED_CHECK="rust / result"

step() { printf '\n==> %s\n' "$*"; }

# Führt einen Befehl aus und meldet nur einen Hinweis, wenn er scheitert
# (z. B. weil das Feature im GitHub-Plan oder bei privaten Repos nicht verfügbar ist).
try() {
  local out
  if ! out=$("$@" 2>&1); then
    printf '    ! fehlgeschlagen: %s\n      %s\n' "$*" "$(head -n1 <<<"$out")" >&2
  fi
}

step "Merge-Einstellungen für $REPO"
try gh repo edit "$REPO" \
  --enable-squash-merge \
  --enable-merge-commit=false \
  --enable-rebase-merge=false \
  --enable-auto-merge \
  --delete-branch-on-merge \
  --enable-wiki=false
# Squash-Commit: PR-Titel als Titel, PR-Beschreibung als Text
try gh api -X PATCH "repos/$REPO" -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY

step "Labels"
label() { try gh label create "$1" --repo "$REPO" --color "$2" --description "$3" --force; }
label "bug"             "d73a4a" "Something isn't working"
label "enhancement"     "a2eeef" "New feature or request"
label "breaking-change" "b60205" "Breaks backwards compatibility"
label "documentation"   "0075ca" "Improvements or additions to documentation"
label "chore"           "cfd3d7" "Refactoring and maintenance"
label "ci"              "ededed" "CI, build and tooling"
label "dependencies"    "0366d6" "Dependency updates"
label "security"        "ee0701" "Security-related"
label "needs-triage"    "fbca04" "Needs to be looked at"
label "skip-changelog"  "ffffff" "Exclude from generated release notes"
label "question"        "d876e3" "Further information is requested"
label "good first issue" "7057ff" "Good for newcomers"
label "help wanted"     "008672" "Extra attention is needed"

step "Security-Features"
try gh api -X PUT "repos/$REPO/vulnerability-alerts"
try gh api -X PUT "repos/$REPO/automated-security-fixes"
try gh api -X PUT "repos/$REPO/private-vulnerability-reporting"
try gh api -X PATCH "repos/$REPO" --input - <<<'{"security_and_analysis":{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}}'

step "Actions: Workflows bekommen standardmäßig nur Lesezugriff"
try gh api -X PUT "repos/$REPO/actions/permissions/workflow" -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false

step "Ruleset für den Default-Branch"
payload=$(cat <<JSON
{
  "name": "protect-default-branch",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "bypass_actors": [],
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "required_linear_history" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [ { "context": "$REQUIRED_CHECK" } ]
      }
    }
  ]
}
JSON
)
existing=$(gh api "repos/$REPO/rulesets" --jq '.[] | select(.name == "protect-default-branch") | .id' 2>/dev/null || true)
if [[ -n "$existing" ]]; then
  try gh api -X PUT "repos/$REPO/rulesets/$existing" --input - <<<"$payload"
else
  try gh api -X POST "repos/$REPO/rulesets" --input - <<<"$payload"
fi

printf '\nFertig. Prüfe die Einstellungen unter https://github.com/%s/settings\n' "$REPO"
