#!/usr/bin/env bash
set -euo pipefail

REPOS=(
  "Atlasshaji/ATLAS"
  "Atlasshaji/httptap"
  "Atlasshaji/Atlas_20.0"
  "Atlasshaji/Atlasshaji"
)

BRANCH="upgrade/comprehensive-repair"
PR_TITLE="upgrade: add monitoring, debug/recover, elastic & DB auto-repair workflows"
PR_BODY="This PR adds monitoring, debug/recover, elastic and DB auto-repair workflows. Creates repair-report PRs for human review; no auto-merge."
WORKFLOWS=("check-and-fix.yml" "debug-and-recover.yml" "elastic-health-check.yml" "db-health-check.yml")

read -p "Create PRs and dispatch workflows from branch ${BRANCH} → main? (y/N) " CONF
if [[ "${CONF,,}" != "y" ]]; then
  echo "Aborted."
  exit 0
fi

for repo in "${REPOS[@]}"; do
  echo "Creating PR in $repo..."
  gh pr create --repo "$repo" --title "$PR_TITLE" --body "$PR_BODY" --base main --head "$BRANCH" || echo "PR may already exist or creation failed; continuing."
done

sleep 5

for repo in "${REPOS[@]}"; do
  for wf in "${WORKFLOWS[@]}"; do
    if gh api repos/"$repo"/contents/.github/workflows/"$wf" --jq '.type' >/dev/null 2>&1; then
      echo "Triggering $wf in $repo..."
      gh workflow run "$wf" --repo "$repo" --ref "$BRANCH" || echo "Could not trigger $wf in $repo"
      sleep 1
    else
      echo "Workflow $wf not found in $repo; skipping"
    fi
  done
done

echo "Done. Monitor runs with: gh run list --repo <repo>"
