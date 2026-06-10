#!/usr/bin/env bash
# 四阶段工作流 · 一键安装/卸载
# 用法:
#   bash 安装.sh            把两个 Skill 软链进 ~/.claude/skills/（与 code-self-review 同机制）
#   bash 安装.sh --check    只检查当前安装状态，不改动
#   bash 安装.sh --uninstall 移除软链（不删源文件）
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$HERE/skills"
SKILLS_DST="$HOME/.claude/skills"
NAMES=(verify-closure attribute-rootcause)

log() { printf '%s\n' "$*"; }

do_check() {
  log "=== 安装状态 ==="
  for n in "${NAMES[@]}"; do
    local dst="$SKILLS_DST/$n"
    if [ -L "$dst" ]; then
      log "  ✓ $n  → $(readlink "$dst")"
    elif [ -e "$dst" ]; then
      log "  ⚠ $n  已存在但不是软链（手动确认是否覆盖）"
    else
      log "  ✗ $n  未安装"
    fi
  done
  log ""
  log "源文件:"
  for n in "${NAMES[@]}"; do
    [ -f "$SKILLS_SRC/$n/SKILL.md" ] && log "  ✓ $SKILLS_SRC/$n/SKILL.md" || log "  ✗ 缺 $SKILLS_SRC/$n/SKILL.md"
  done
}

do_install() {
  mkdir -p "$SKILLS_DST"
  for n in "${NAMES[@]}"; do
    local src="$SKILLS_SRC/$n" dst="$SKILLS_DST/$n"
    [ -d "$src" ] || { log "✗ 源缺失: $src"; continue; }
    if [ -L "$dst" ]; then
      log "= 已是软链，跳过: $n"
    elif [ -e "$dst" ]; then
      log "⚠ 已存在同名（非软链），未覆盖: $dst  —— 手动处理后重跑"
    else
      ln -s "$src" "$dst"
      log "✓ 链接: $n → $src"
    fi
  done
  log ""
  log "完成。重启 Claude Code 会话后，下列触发词可唤起:"
  log "  验证闭环: 「验证一下」「修好了吗」「上线了没」「确认生效」"
  log "  归因:     「这是代码问题吗」「先别急着改」「根因是什么」「归因」"
  log ""
  log "下一步(可选，需你确认):"
  log "  - 把 环境真相档案.md 复制进目标项目根"
  log "  - 把 CLAUDE.md片段-回灌与阶段纪律.md 粘进项目 CLAUDE.md"
  log "  - 把 取值地图增补.md §6.9 并进 code-self-review（SSOT 在 原项目 仓，改前确认）"
}

do_uninstall() {
  for n in "${NAMES[@]}"; do
    local dst="$SKILLS_DST/$n"
    if [ -L "$dst" ]; then rm "$dst"; log "✓ 移除软链: $n"
    elif [ -e "$dst" ]; then log "⚠ 非软链，未动: $dst"
    else log "= 本就没有: $n"; fi
  done
  log "源文件未删，随时可重装。"
}

case "${1:-}" in
  --check)     do_check ;;
  --uninstall) do_uninstall ;;
  ""|--install) do_install ;;
  *) log "用法: bash 安装.sh [--check|--uninstall]"; exit 1 ;;
esac
