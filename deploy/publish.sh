#!/usr/bin/env bash
# deploy/publish.sh - build the site and release it to the nginx server over SSH.
# Each release lands in $DEPLOY_PATH/<commit-sha>/, a "current" symlink in the
# same directory points at the newest release, and only the last DEPLOY_KEEP
# releases are kept. Configuration lives in deploy/config.sh (gitignored).
# Only Tim runs this.
#
#   ./deploy/publish.sh                 deploy current main
#   ./deploy/publish.sh --dry-run       show what would be uploaded, change nothing
#   ./deploy/publish.sh --list          show releases and what current points at
#   ./deploy/publish.sh --rollback <sha>
#   ./deploy/publish.sh --test          full rehearsal against a local folder,
#                                       no server needed (DEPLOY_TEST_PATH to
#                                       override /tmp/timv-publish-test)

set -euo pipefail

cd "$(dirname "$0")/.."

# --- arguments -------------------------------------------------------------

MODE="deploy"
DRY_RUN=0
LOCAL_TEST=0
ROLLBACK_SHA=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --list) MODE="list" ;;
    --test) LOCAL_TEST=1 ;;
    --rollback)
      MODE="rollback"
      ROLLBACK_SHA="${2:-}"
      if [ -z "$ROLLBACK_SHA" ]; then
        echo "publish: --rollback needs a commit sha (see --list)." >&2
        exit 1
      fi
      shift
      ;;
    *)
      echo "publish: unknown argument '$1'." >&2
      exit 1
      ;;
  esac
  shift
done

# --- configuration ---------------------------------------------------------

DEPLOY_KEEP="${DEPLOY_KEEP:-5}"

if [ "$LOCAL_TEST" = "1" ]; then
  DEPLOY_PATH="${DEPLOY_TEST_PATH:-/tmp/timv-publish-test}"
  remote_run() { bash -c "$1"; }
  DEST_PREFIX="$DEPLOY_PATH"
else
  if [ -f deploy/config.sh ]; then
    # shellcheck source=/dev/null
    . deploy/config.sh
  fi

  if [ -z "${DEPLOY_HOST:-}" ] || [ -z "${DEPLOY_USER:-}" ] || [ -z "${DEPLOY_PATH:-}" ]; then
    echo "publish: missing configuration." >&2
    echo "Copy deploy/config.sh.example to deploy/config.sh, fill it in, and try again." >&2
    exit 1
  fi

  DEPLOY_PORT="${DEPLOY_PORT:-22}"
  DEPLOY_IDENTITY="${DEPLOY_IDENTITY:-}"

  SSH_CMD="ssh -p $DEPLOY_PORT"
  if [ -n "$DEPLOY_IDENTITY" ]; then
    SSH_CMD="$SSH_CMD -i $DEPLOY_IDENTITY"
  fi
  REMOTE="$DEPLOY_USER@$DEPLOY_HOST"
  remote_run() { $SSH_CMD "$REMOTE" "$1"; }
  DEST_PREFIX="$REMOTE:$DEPLOY_PATH"
fi

# Point the current symlink at a release. Remote uses the atomic
# ln+mv -T dance (GNU coreutils); local test mode uses plain ln -sfn.
switch_current() {
  if [ "$LOCAL_TEST" = "1" ]; then
    remote_run "cd '$DEPLOY_PATH' && ln -sfn '$1' current"
  else
    remote_run "cd '$DEPLOY_PATH' && ln -sfn '$1' current.tmp && mv -T current.tmp current"
  fi
}

# --- list ------------------------------------------------------------------

if [ "$MODE" = "list" ]; then
  echo "publish: releases ($DEPLOY_PATH):"
  remote_run "ls -1t '$DEPLOY_PATH' 2>/dev/null | grep -E '^[0-9a-f]{40}\$' || echo '(none)'"
  echo "current -> $(remote_run "readlink '$DEPLOY_PATH/current' 2>/dev/null" || echo '(unset)')"
  exit 0
fi

# --- safety checks ---------------------------------------------------------

# GitHub Actions sets CI=true; the workflow only runs on main with a clean
# checkout, so the local checks below are for manual runs only. --test
# rehearses against a local folder and skips them.
if [ -z "${CI:-}" ] && [ "$LOCAL_TEST" = "0" ]; then
  BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  if [ "$BRANCH" != "main" ]; then
    echo "publish: refusing to deploy from branch '$BRANCH'. Only main gets published." >&2
    exit 1
  fi

  if [ -n "$(git status --porcelain)" ]; then
    echo "publish: working tree is dirty. Commit or stash first." >&2
    exit 1
  fi
fi

# --- rollback --------------------------------------------------------------

if [ "$MODE" = "rollback" ]; then
  remote_run "test -d '$DEPLOY_PATH/$ROLLBACK_SHA'" || {
    echo "publish: release $ROLLBACK_SHA not found on the server." >&2
    exit 1
  }
  switch_current "$ROLLBACK_SHA"
  echo "publish: rolled back to $ROLLBACK_SHA."
  exit 0
fi

# --- build -----------------------------------------------------------------

if [ ! -d node_modules ]; then
  echo "publish: node_modules missing, running npm install." >&2
  npm install
fi

SHA="$(git rev-parse HEAD)"

echo "publish: building $SHA."
rm -rf public resources
HUGO_ENV=production hugo --gc --minify

if [ ! -f public/index.html ]; then
  echo "publish: build produced no public/index.html." >&2
  exit 1
fi

# --- release ---------------------------------------------------------------

RSYNC_FLAGS=(-az --delete --stats)
if [ "$LOCAL_TEST" = "0" ]; then
  RSYNC_FLAGS+=(-e "$SSH_CMD")
fi
if [ "$DRY_RUN" = "1" ]; then
  RSYNC_FLAGS+=(-n)
fi

PREVIOUS="$(remote_run "readlink '$DEPLOY_PATH/current' 2>/dev/null" || true)"

echo "publish: releasing to $DEST_PREFIX/$SHA/"
if [ "$DRY_RUN" = "0" ]; then
  remote_run "mkdir -p '$DEPLOY_PATH'"
fi
rsync "${RSYNC_FLAGS[@]}" public/ "$DEST_PREFIX/$SHA/"

if [ "$DRY_RUN" = "1" ]; then
  echo "publish: dry run, symlink switch and pruning skipped."
  echo "publish: current -> ${PREVIOUS:-none}"
  exit 0
fi

echo "publish: switching current (was ${PREVIOUS:-none})."
switch_current "$SHA"

echo "publish: pruning to the last $DEPLOY_KEEP releases (never the live one)."
remote_run "cd '$DEPLOY_PATH' && live=\$(basename \"\$(readlink current 2>/dev/null)\" 2>/dev/null || true); if [ -n \"\$live\" ]; then ls -1dt */ 2>/dev/null | grep -E '^[0-9a-f]{40}/\$' | sed 's:/*\$::' | grep -vx \"\$live\" | tail -n +$DEPLOY_KEEP | xargs -r rm -rf; else ls -1dt */ 2>/dev/null | grep -E '^[0-9a-f]{40}/\$' | sed 's:/*\$::' | tail -n +$((DEPLOY_KEEP + 1)) | xargs -r rm -rf; fi"

echo "publish: done. $SHA is live. Rollback with: deploy/publish.sh --rollback <sha>"
