#!/usr/bin/env bash
# 四阶段 AI 开发工作流 · Claude Code /four-stage-install 命令入口安装器
# 用法:
#   curl -fsSL https://raw.githubusercontent.com/Coder42Y/four-gate-ai-workflow/master/install-claude-command.sh -o /tmp/four-stage-install-claude-command.sh
#   bash /tmp/four-stage-install-claude-command.sh
set -euo pipefail

REPO_URL="${FOUR_STAGE_WORKFLOW_REPO:-https://github.com/Coder42Y/four-gate-ai-workflow.git}"
INSTALL_DIR="${FOUR_STAGE_WORKFLOW_HOME:-$HOME/.four-stage-ai-workflow}"
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
SKILL_NAME="four-stage-install"
SRC_SKILL="$INSTALL_DIR/claude-skills/$SKILL_NAME"
DST_SKILL="$CLAUDE_SKILLS_DIR/$SKILL_NAME"

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

[ -f "$SRC_SKILL/SKILL.md" ] || die "安装入口 skill 缺失: $SRC_SKILL/SKILL.md"

mkdir -p "$CLAUDE_SKILLS_DIR"

if [ -L "$DST_SKILL" ]; then
  current="$(readlink "$DST_SKILL")"
  if [ "$current" != "$SRC_SKILL" ]; then
    rm "$DST_SKILL"
    ln -s "$SRC_SKILL" "$DST_SKILL"
    log "更新 /$SKILL_NAME 软链: $DST_SKILL -> $SRC_SKILL"
  else
    log "/$SKILL_NAME 已安装: $DST_SKILL -> $SRC_SKILL"
  fi
elif [ -e "$DST_SKILL" ]; then
  die "已存在同名 Claude skill（非软链）: $DST_SKILL。请手动备份/删除后重跑。"
else
  ln -s "$SRC_SKILL" "$DST_SKILL"
  log "安装 /$SKILL_NAME: $DST_SKILL -> $SRC_SKILL"
fi

cat <<NEXT

  ✓ Claude Code 命令入口安装完成。

  之后每个新业务 repo：

    cd /path/to/business-repo
    claude

  在 Claude Code 里输入：

    /four-stage-install

  它会在当前业务 repo 执行四阶段工作流部署：
  - 全局安装/更新 Codex + Claude workflow skills
  - 生成 ai-workflow/
  - 注入 AGENTS.md / CLAUDE.md
  - 尝试安装 code-self-review 取值地图增补

NEXT
