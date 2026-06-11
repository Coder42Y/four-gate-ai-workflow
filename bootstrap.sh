#!/usr/bin/env bash
# 四阶段 AI 开发工作流 · 远程一行安装入口
# 用法:
#   curl -fsSL https://raw.githubusercontent.com/Coder42Y/four-gate-ai-workflow/master/bootstrap.sh -o /tmp/four-stage-bootstrap.sh
#   bash /tmp/four-stage-bootstrap.sh --with-review-addon /path/to/project
set -euo pipefail

REPO_URL="${FOUR_STAGE_WORKFLOW_REPO:-https://github.com/Coder42Y/four-gate-ai-workflow.git}"
INSTALL_DIR="${FOUR_STAGE_WORKFLOW_HOME:-$HOME/.four-stage-ai-workflow}"

log() { printf '  %s\n' "$*"; }
die() { printf '  ✗ %s\n' "$*" >&2; exit 1; }

detect_default_branch() {
  local current=""
  if [ -d "$INSTALL_DIR/.git" ] && command -v git >/dev/null 2>&1; then
    current="$(git -C "$INSTALL_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  fi
  if [ -n "$current" ] && [ "$current" != "HEAD" ]; then
    printf '%s\n' "$current"
  else
    printf 'master\n'
  fi
}

BRANCH="${FOUR_STAGE_WORKFLOW_BRANCH:-$(detect_default_branch)}"

if ! command -v git >/dev/null 2>&1; then
  die "需要先安装 git"
fi

if [ -d "$INSTALL_DIR/.git" ]; then
  log "更新工作流仓库: $INSTALL_DIR"
  git -C "$INSTALL_DIR" fetch --quiet origin "$BRANCH"
  git -C "$INSTALL_DIR" checkout --quiet "$BRANCH"
  git -C "$INSTALL_DIR" pull --ff-only --quiet origin "$BRANCH"
else
  log "克隆工作流仓库到: $INSTALL_DIR"
  rm -rf "$INSTALL_DIR"
  git clone --quiet --depth=1 --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
fi

if [ $# -eq 0 ]; then
  set -- --with-review-addon "$PWD"
fi

log "执行 deploy.sh $*"
exec bash "$INSTALL_DIR/deploy.sh" "$@"
