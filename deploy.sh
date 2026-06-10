#!/usr/bin/env bash
# 四阶段 AI 开发工作流 · 一键部署
# 用法:
#   bash deploy.sh                                  仅全局安装（软链 Skills 到 Claude + Codex）
#   bash deploy.sh /path/to/project                 全局 + 项目级部署
#   bash deploy.sh --with-review-addon /path        部署项目时同时安装 code-self-review 增补
#   bash deploy.sh --install-review-addon           仅安装 code-self-review 取值地图增补
#   bash deploy.sh --uninstall-review-addon         移除 code-self-review 取值地图增补
#   bash deploy.sh --check [/path]                  查状态
#   bash deploy.sh --uninstall [/path]              卸载（项目级会确认删 ai-workflow/）
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$HERE/skills"
CLAUDE_SKILLS_DST="$HOME/.claude/skills"
CODEX_SKILLS_DST="$HOME/.codex/skills"
SKILL_NAMES=(ai-task-preflight verify-closure attribute-rootcause)
REVIEW_ADDON_BEGIN="<!-- FOUR-STAGE-VALUE-MAP-ADDON-BEGIN -->"
REVIEW_ADDON_END="<!-- FOUR-STAGE-VALUE-MAP-ADDON-END -->"

# ── 探测结果变量（Phase 2 用）──
DETECTED_LANG=""
DETECTED_FRAMEWORK=""
DETECTED_FRONTEND=""
DETECTED_BUILD=""
DETECTED_CI=""
DETECTED_DB=""
DETECTED_HAS_NACOS=false
DETECTED_HAS_FLOW=false
DETECTED_JAVA_VERSION=""

# ── 工具函数 ──────────────────────────────────────────────

log()   { printf '  ✓ %s\n' "$*"; }
warn()  { printf '  ⚠ %s\n' "$*" >&2; }
skip()  { printf '  = %s\n' "$*"; }
die()   { printf '  ✗ %s\n' "$*" >&2; exit 1; }

separator() { printf '\n  %s\n' "────────────────────────────────────────"; }

# ── Phase 1: 全局安装 ─────────────────────────────────────

install_skills_to_dir() {
  local label="$1" dst_root="$2"
  printf '\n  ▶ %s Skills: %s\n' "$label" "$dst_root"
  mkdir -p "$dst_root"
  for n in "${SKILL_NAMES[@]}"; do
    local src="$SKILLS_SRC/$n" dst="$dst_root/$n"
    [ -d "$src" ] || { warn "源缺失: $src"; continue; }
    if [ -L "$dst" ]; then
      local current
      current="$(readlink "$dst")"
      if [ "$current" = "$src" ]; then
        skip "已是正确软链: $n"
      else
        warn "软链指向不同位置: $n → $current（期望 $src）"
      fi
    elif [ -e "$dst" ]; then
      warn "已存在同名（非软链）: $dst —— 手动处理后重跑"
    else
      ln -s "$src" "$dst"
      log "链接: $n → $src"
    fi
  done
}

check_skills_in_dir() {
  local label="$1" dst_root="$2"
  printf '\n  ▶ %s Skills 状态: %s\n' "$label" "$dst_root"
  for n in "${SKILL_NAMES[@]}"; do
    local dst="$dst_root/$n"
    if [ -L "$dst" ]; then
      log "$n  → $(readlink "$dst")"
    elif [ -e "$dst" ]; then
      warn "$n  已存在但不是软链"
    else
      printf '  ✗ %s  未安装\n' "$n"
    fi
  done
}

uninstall_skills_from_dir() {
  local label="$1" dst_root="$2"
  printf '\n  ▶ 卸载 %s Skills: %s\n' "$label" "$dst_root"
  for n in "${SKILL_NAMES[@]}"; do
    local dst="$dst_root/$n"
    if [ -L "$dst" ]; then rm "$dst"; log "移除软链: $n"
    elif [ -e "$dst" ]; then warn "非软链，未动: $dst"
    else skip "本就没有: $n"; fi
  done
}

do_global_install() {
  printf '\n  ▶ 全局安装 Skills\n'
  install_skills_to_dir "Claude" "$CLAUDE_SKILLS_DST"
  install_skills_to_dir "Codex" "$CODEX_SKILLS_DST"
}

do_global_check() {
  printf '\n  ▶ 全局 Skills 状态\n'
  check_skills_in_dir "Claude" "$CLAUDE_SKILLS_DST"
  check_skills_in_dir "Codex" "$CODEX_SKILLS_DST"
  printf '\n  源文件:\n'
  for n in "${SKILL_NAMES[@]}"; do
    [ -f "$SKILLS_SRC/$n/SKILL.md" ] && log "$SKILLS_SRC/$n/SKILL.md" || warn "缺 $SKILLS_SRC/$n/SKILL.md"
  done
  do_review_addon_check
}

do_global_uninstall() {
  printf '\n  ▶ 卸载全局 Skills\n'
  uninstall_skills_from_dir "Claude" "$CLAUDE_SKILLS_DST"
  uninstall_skills_from_dir "Codex" "$CODEX_SKILLS_DST"
}

# ── code-self-review 增补 ─────────────────────────────────

find_review_skill_files() {
  if [ -n "${CODE_SELF_REVIEW_SKILL:-}" ]; then
    [ -f "$CODE_SELF_REVIEW_SKILL" ] && printf '%s\n' "$CODE_SELF_REVIEW_SKILL"
    return
  fi

  local candidates=(
    "$CLAUDE_SKILLS_DST/code-self-review/SKILL.md"
    "$CODEX_SKILLS_DST/code-self-review/SKILL.md"
    "$HOME/.agents/skills/code-self-review/SKILL.md"
  )

  local f
  for f in "${candidates[@]}"; do
    [ -f "$f" ] && printf '%s\n' "$f"
  done
}

review_addon_block() {
  cat <<'ADDON'
## 6.9 取值绕路红线（四阶段工作流增补）

> SSOT：项目内 `ai-workflow/环境真相档案.md` §四「取值地图」。凡"取外部值走了禁用歧路"均为违规候选，命中后必须给出正路。

| 检测 | 命令 / 模式 | 命中判定 | 正路 |
|------|-------------|---------|------|
| 字典名扁平查（跨级串值） | `git grep -nE 'getCodeNameByParentCodeType' -- 'backend-module/*'` | ❌ | `selectByParentCodeType` 按层级（`TypeNameResolver`） |
| 合同状态名查字典（静默变空） | `git grep -nE 'codeUtils.*(contract_status\|getCodeName).*status' -- 'backend-module/*'` 后人工核对是否在取状态名 | ❌ | `BusinessStatusEnum.getName` |
| 审批人单维度取岗（找不到人） | `git grep -nE '(APPROVER_ROLE\|selectApproverIds)' -- 'backend-module/*'` 后核对是否带回退 | ⚠️ 无回退则 ❌ | `selectApproversWithFallback`（部门→签约主体回退） |
| 全量组织却用受限子集 | `git grep -nE 'UserScopedDepartmentApi' -- 'frontend-app/src/*'` 后核对该处是否需"全量组织架构" | ⚠️ 需全量却用它则 ❌ | 页面侧不带 userId 调 `getOrganTree` 取 `orgType=3` |
| 选择器带出字段未往返 | `git grep -nE '(setOrgan\|setSignEntity\|选人回调).*(Name\|Id)' -- 'frontend-app/src/*'` 后核对 payload/VO/loadDetail 是否齐 | ⚠️（人工确认完整往返） | payload+列+VO+loadDetail 全补 |
| 新概念自创查法 | `[human-only]`：出现"取某外部名/某外部 ID"且未走环境真相档案 §四任一正路 | ⚠️ 标"取值地图未覆盖，先问人，勿自创" | 停下问人，补进取值地图 |

### §6.9 一键扫命令

```bash
git grep -nE 'getCodeNameByParentCodeType' -- 'backend-module/*'
git grep -nE 'codeUtils.*contract_status' -- 'backend-module/*'
git grep -nE 'UserScopedDepartmentApi' -- 'frontend-app/src/*'
git grep -nE 'APPROVER_ROLE' -- 'backend-module/*'
```

维护约定：新增正路/歧路先改项目 `ai-workflow/环境真相档案.md` §四，再补检测行；报告里必须写出正路，不能只说"违规"。
ADDON
}

install_review_addon_to_file() {
  local target="$1"
  local block_file tmp_file
  block_file="$(mktemp)"
  tmp_file="$(mktemp)"
  {
    printf '%s\n' "$REVIEW_ADDON_BEGIN"
    review_addon_block
    printf '%s\n' "$REVIEW_ADDON_END"
  } > "$block_file"

  if grep -q "$REVIEW_ADDON_BEGIN" "$target" 2>/dev/null; then
    awk -v begin="$REVIEW_ADDON_BEGIN" -v end="$REVIEW_ADDON_END" -v block_file="$block_file" '
      index($0, begin) > 0 {
        while ((getline line < block_file) > 0) print line
        close(block_file)
        while (getline && index($0, end) == 0) {}
        next
      }
      { print }
    ' "$target" > "$tmp_file"
    mv "$tmp_file" "$target"
    rm -f "$block_file"
    log "更新 code-self-review 增补: $target"
  else
    cp "$target" "$target.bak.$(date +%Y%m%d%H%M%S)"
    {
      printf '\n'
      cat "$block_file"
      printf '\n'
    } >> "$target"
    rm -f "$tmp_file" "$block_file"
    log "追加 code-self-review 增补: $target"
  fi
}

do_review_addon_install() {
  printf '\n  ▶ 安装 code-self-review 取值地图增补\n'
  local found=false target
  while IFS= read -r target; do
    found=true
    install_review_addon_to_file "$target"
  done < <(find_review_skill_files)

  if [ "$found" = false ]; then
    warn "未找到 code-self-review/SKILL.md"
    warn "可用 CODE_SELF_REVIEW_SKILL=/path/to/SKILL.md bash deploy.sh --install-review-addon 指定"
    return 1
  fi
}

do_review_addon_uninstall() {
  printf '\n  ▶ 卸载 code-self-review 取值地图增补\n'
  local found=false target tmp_file
  while IFS= read -r target; do
    found=true
    if grep -q "$REVIEW_ADDON_BEGIN" "$target" 2>/dev/null; then
      tmp_file="$(mktemp)"
      awk -v begin="$REVIEW_ADDON_BEGIN" -v end="$REVIEW_ADDON_END" '
        index($0, begin) > 0 { skip=1; next }
        index($0, end) > 0 { skip=0; next }
        !skip { print }
      ' "$target" > "$tmp_file"
      mv "$tmp_file" "$target"
      log "移除 code-self-review 增补: $target"
    else
      skip "未安装增补: $target"
    fi
  done < <(find_review_skill_files)

  [ "$found" = true ] || warn "未找到 code-self-review/SKILL.md"
}

do_review_addon_check() {
  printf '\n  ▶ code-self-review 增补状态\n'
  local found=false target
  while IFS= read -r target; do
    found=true
    if grep -q "$REVIEW_ADDON_BEGIN" "$target" 2>/dev/null; then
      log "已安装: $target"
    else
      printf '  ✗ 未安装: %s\n' "$target"
    fi
  done < <(find_review_skill_files)

  [ "$found" = true ] || skip "未找到 code-self-review/SKILL.md"
}

# ── Phase 2: 项目级部署 ──────────────────────────────────

# 校验目标项目
validate_project() {
  local proj="$1"
  [ -d "$proj" ] || die "目标路径不存在: $proj"
  # 防止部署到自身
  local proj_real
  proj_real="$(cd "$proj" && pwd)"
  [ "$proj_real" = "$HERE" ] && die "不能部署到四阶段仓库自身"
  true
}

# 探测技术栈
detect_tech_stack() {
  local proj="$1"
  printf '\n  ▶ 探测技术栈\n'

  # ── Java / Maven ──
  if [ -f "$proj/pom.xml" ]; then
    DETECTED_LANG="java"
    DETECTED_BUILD="maven"
    # Java 版本
    DETECTED_JAVA_VERSION=$(sed -n 's/.*<java.version>\([0-9]*\)<\/java.version>.*/\1/p' "$proj/pom.xml" 2>/dev/null | head -1 || true)
    [ -z "$DETECTED_JAVA_VERSION" ] && DETECTED_JAVA_VERSION=$(sed -n 's/.*<source>\([0-9]*\)<\/source>.*/\1/p' "$proj/pom.xml" 2>/dev/null | head -1 || true)
    # Spring Boot
    if grep -q 'spring-boot-starter-parent\|org.springframework.boot' "$proj/pom.xml" 2>/dev/null; then
      DETECTED_FRAMEWORK="spring-boot"
    fi
    # 多模块
    local modules
    modules=$(grep -c '<module>' "$proj/pom.xml" 2>/dev/null || true)
    modules="${modules:-0}"
    [ "$modules" -gt 0 ] && log "检测到 Maven 多模块项目（${modules} 个子模块）"
    [ -n "$DETECTED_JAVA_VERSION" ] && log "Java $DETECTED_JAVA_VERSION"
  fi

  # ── Gradle ──
  if [ -f "$proj/build.gradle" ] || [ -f "$proj/build.gradle.kts" ]; then
    DETECTED_LANG="java"
    DETECTED_BUILD="gradle"
    log "检测到 Gradle 构建"
  fi

  # ── 前端 ──
  local pkg="$proj/package.json"
  if [ -f "$pkg" ]; then
    if grep -q '"vue"' "$pkg" 2>/dev/null; then
      DETECTED_FRONTEND="vue"
      log "检测到 Vue"
    elif grep -q '"react"' "$pkg" 2>/dev/null; then
      DETECTED_FRONTEND="react"
      log "检测到 React"
    fi
    if grep -q '"vite"' "$pkg" 2>/dev/null; then
      DETECTED_BUILD="${DETECTED_BUILD:+$DETECTED_BUILD/}vite"
      log "检测到 Vite"
    fi
  fi

  # ── 数据库驱动 ──
  if [ -f "$proj/pom.xml" ]; then
    if grep -q 'mysql-connector' "$proj/pom.xml" 2>/dev/null; then
      DETECTED_DB="mysql"
      log "检测到 MySQL 驱动"
    elif grep -q 'postgresql' "$proj/pom.xml" 2>/dev/null; then
      DETECTED_DB="postgresql"
      log "检测到 PostgreSQL 驱动"
    elif grep -q 'oracle' "$proj/pom.xml" 2>/dev/null; then
      DETECTED_DB="oracle"
      log "检测到 Oracle 驱动"
    fi
  fi

  # ── Nacos ──
  local nacos_hits
  nacos_hits=$(grep -rl 'nacos' "$proj" --include='pom.xml' --include='*.yml' --include='*.yaml' --include='*.properties' 2>/dev/null || true)
  if [ -n "$nacos_hits" ]; then
    DETECTED_HAS_NACOS=true
    log "检测到 Nacos 配置"
  fi

  # ── 流程引擎 ──
  local bpmn_hits
  bpmn_hits=$(find "$proj" \( -name '*.bpmn' -o -name '*.bpmn20.xml' \) -print -quit 2>/dev/null || true)
  if [ -n "$bpmn_hits" ]; then
    DETECTED_HAS_FLOW=true
    log "检测到 BPMN 流程文件"
  fi

  # ── CI ──
  if [ -f "$proj/Jenkinsfile" ]; then
    DETECTED_CI="jenkins"
    log "检测到 Jenkins CI"
  elif [ -f "$proj/.gitlab-ci.yml" ]; then
    DETECTED_CI="gitlab"
    log "检测到 GitLab CI"
  elif [ -d "$proj/.github/workflows" ]; then
    DETECTED_CI="github"
    log "检测到 GitHub Actions"
  fi

  # 汇总
  if [ -z "$DETECTED_LANG" ]; then warn "未能自动检测主语言，模板将使用通用版本"; fi
}

# 创建 ai-workflow/ 目录，复制通用文档
create_workflow_dir() {
  local proj="$1"
  local awd="$proj/ai-workflow"

  printf '\n  ▶ 创建 ai-workflow/ 目录\n'

  if [ -d "$awd" ]; then
    skip "ai-workflow/ 已存在，更新通用文档"
  else
    mkdir -p "$awd"
    log "创建: $awd"
  fi

  # 复制通用文档（蓝图、推广手册）
  cp "$HERE/四阶段蓝图.md" "$awd/四阶段蓝图.md"
  log "复制: 四阶段蓝图.md"
  cp "$HERE/推广手册.md" "$awd/推广手册.md"
  log "复制: 推广手册.md"

  # 复制可视化 HTML
  if [ -f "$HERE/四阶段工作流.html" ]; then
    cp "$HERE/四阶段工作流.html" "$awd/四阶段工作流.html"
    log "复制: 四阶段工作流.html"
  fi
}

# 生成项目级环境真相档案
generate_truth_archive() {
  local proj="$1"
  local awd="$proj/ai-workflow"
  local target="$awd/环境真相档案.md"

  printf '\n  ▶ 生成环境真相档案\n'

  # 如果用户已手动编辑过，不覆盖
  if [ -f "$target" ] && ! grep -q 'AUTO-GENERATED' "$target" 2>/dev/null; then
    warn "环境真相档案已存在且含用户编辑，跳过生成"
    return
  fi

  local proj_name
  proj_name="$(basename "$proj")"

  # 预计算各段内容（避免 heredoc 内复杂命令替换问题）
  local sec_build="- **构建工具：** [待填]"
  sec_build="$sec_build
- **构建命令：** [待填]"
  case "$DETECTED_BUILD" in
    *maven*)
      sec_build="- **构建工具：** Maven
- **构建命令：** \`mvn clean package -DskipTests\`（待确认）"
      ;;
    *gradle*)
      sec_build="- **构建工具：** Gradle
- **构建命令：** \`./gradlew build\`（待确认）"
      ;;
  esac

  local sec_ci="[待填]"
  if [ "$DETECTED_CI" = "jenkins" ]; then sec_ci="Jenkins（待确认 job 名）"
  elif [ -n "$DETECTED_CI" ]; then sec_ci="${DETECTED_CI}（待确认）"; fi

  local sec_db="- **数据库：** [待填]"
  if [ "$DETECTED_DB" = "mysql" ]; then sec_db="- **数据库：** MySQL"
  elif [ "$DETECTED_DB" = "postgresql" ]; then sec_db="- **数据库：** PostgreSQL"
  elif [ "$DETECTED_DB" = "oracle" ]; then sec_db="- **数据库：** Oracle"; fi

  local sec_flow="- 本项目未检测到流程引擎文件。如有流程引擎，手动补充本节。"
  if [ "$DETECTED_HAS_FLOW" = true ]; then
    sec_flow="- **检测到流程引擎文件**，需要填写以下内容：
- 使用哪个流程引擎？（ezgo / Flowable / Camunda / 其他） [待填]
- token 机制？按钮标签在哪配？变量命名规范？ [待填]
- 回调地址和参数格式？ [待填]
- 编号生成规则？ [待填]"
  fi

  local sec_nacos="### 配置中心
- 使用什么配置中心？ [待填]"
  if [ "$DETECTED_HAS_NACOS" = true ]; then
    sec_nacos="### Nacos 配置
- **namespace / group / data-id：** [待填]
- **哪些配置项影响行为而非代码？** [待填]
- **热更新机制：** [待填]"
  fi

  local sec_frontend="- **前端框架：** [待填]"
  if [ "$DETECTED_FRONTEND" = "vue" ]; then
    sec_frontend="- **前端框架：** Vue
- **构建命令：** \`npm run build\` / \`pnpm build\`（待确认）"
  elif [ "$DETECTED_FRONTEND" = "react" ]; then
    sec_frontend="- **前端框架：** React
- **构建命令：** \`npm run build\` / \`pnpm build\`（待确认）"
  fi

  cat > "$target" <<ARCHIVE
# 环境真相档案 · ${proj_name}

<!-- AUTO-GENERATED by deploy.sh —— 填写后可删除此行 -->

> **用法：** AI 每次会话启动时读此档案。结构性真相（稳定的）写这里；运行时状态（会变的）永远现场探，不写进档案。

## 一、部署链路真相

${sec_build}
- **代码 push 到哪个远端？** [待填]
- **谁/怎么触发构建？** ${sec_ci}
- **怎么部署/重启？** [待填]
- **日志在哪？** [待填]
- **部署 SUCCESS 后怎么验"真生效"（探针）？** [待填]
- **前端缓存怎么破？** [待填]
- **token 多久过期？** [待填]

## 二、数据库真相

${sec_db}
- **有没有 Flyway / Liquibase？** [待填]
- **迁移脚本谁跑？手动还是自动？** [待填]
- **加列的标准流程：** [待填]
- **DB 版本/方言坑：** [待填]

## 三、外部应用 ID 权威表

> 一律从常量/配置取，不硬编码。

| 标识 | 值 | 来源 | 备注 |
|------|----|------|------|
| appId | [待填] | [待填：配置文件/环境变量/nacos] | |
| tenantId | [待填] | AuthUtil / 框架 | 不硬编码 |
| [其他] | [待填] | [待填] | |

## 四、取值地图（核心）

> 凡"取外部值"的概念都要进此表。每个概念只有一条正路，偏离即 bug 候选。

| 外部概念 | ✅ 唯一正路 | ❌ 禁用歧路 | 走歧路后果 |
|----------|-----------|-----------|-----------|
| [待填] | [待填] | [待填] | [待填] |

**填写方法：**
1. 梳理本项目中所有"从外部系统/字典/配置取值"的概念
2. 每个概念找到唯一的正确取法（正路），记录到表格
3. 标记已知的错误取法（歧路）和其后果
4. 没进表的概念，AI 碰到时必须**停下问人**，不许自创查法

## 五、流程引擎 / 配置系统真相

${sec_flow}

${sec_nacos}

## 六、前端/构建真相

${sec_frontend}
- **哪些命令别跑？** [待填]
- **怎么验产物？** [待填]
- **覆盖样式的范式？** [待填]

## 七、协作/边界真相

- **需求管理系统：** [待填：Jira/其他]
- **哪些仓库/模块是只读边界？** [待填]
- **危险动作清单（写库、部署、删数据等）：** [待填]

## 八、回灌候选区

> 踩坑即起草，人审后合并到上面对应章节。

（暂无条目 —— 使用过程中持续积累）
ARCHIVE

  log "生成: 环境真相档案.md"
}

# 生成取值地图指南（通用版，非具体项目规则）
generate_value_map_guide() {
  local proj="$1"
  local awd="$proj/ai-workflow"
  local target="$awd/取值地图指南.md"

  printf '\n  ▶ 生成取值地图指南\n'

  # 如果用户已手动编辑过，不覆盖
  if [ -f "$target" ] && ! grep -q 'AUTO-GENERATED' "$target" 2>/dev/null; then
    warn "取值地图指南已存在且含用户编辑，跳过生成"
    return
  fi

  cat > "$target" <<GUIDE
# 取值地图指南

<!-- AUTO-GENERATED by deploy.sh —— 填写后可删除此行 -->

## 什么是取值地图？

取值地图是四阶段工作流 **阶段 2** 的核心工具。它解决的问题是：

> 代码调用了正确的 API，但**走错了取值路径**，导致数据错误。这类 bug 裸眼看不出来，grep 硬编码数字也抓不到（因为用的都是合法 API），只有跑起来才会出问题。

**典型场景：**
- 用扁平字典查询去查层级树 → 值交叉污染（"类别 A"串成"类别 B"）
- 用错误的 key 取配置值 → 拿到别的业务的值
- 查 foundation 状态字典取业务状态 → 码值对不上 → 静默变空
- 用单维度取岗位 → 维度不兼容 → 找不到审批人

## 如何建立取值地图？

### Step 1: 梳理外部概念

找出项目中所有"从外部系统取值"的概念：
- 数据字典（组织类型、合同类型、状态枚举...）
- 岗位/角色/权限
- 外部系统 ID（appId、tenantId...）
- 配置中心（nacos）中的关键配置项
- 流程引擎中的变量和回调

### Step 2: 钉到唯一正路

对每个概念，找到**唯一正确的取值方法**。记录到 \`环境真相档案.md\` §四 的表格中：

| 外部概念 | ✅ 唯一正路 | ❌ 禁用歧路 | 走歧路后果 |
|----------|-----------|-----------|-----------|

### Step 3: 标记禁用歧路

把已知的错误取法也记录下来。这样 code-self-review 可以用 grep 扫描禁用方法名。

## 本项目取值地图

> 将填写好的取值地图维护在 \`环境真相档案.md\` §四。此文件为填写指南。

（填写完成后，可将禁用歧路整理成 grep 检测规则，合并进 code-self-review skill 的 §6.9）
GUIDE

  log "生成: 取值地图指南.md"
}

# 注入 CLAUDE.md 片段（带标记，幂等）
inject_claude_md() {
  local proj="$1"
  local target="$proj/CLAUDE.md"

  printf '\n  ▶ 注入 CLAUDE.md 片段\n'

  local begin_marker="<!-- FOUR-STAGE-AI-WORKFLOW-BEGIN -->"
  local end_marker="<!-- FOUR-STAGE-AI-WORKFLOW-END -->"

  # 片段内容（来自 CLAUDE.md片段-回灌与阶段纪律.md，lines 7-39）
  local snippet
  snippet=$(cat <<'SNIPPET'
<!-- 四阶段工作流 · 自动注入 · 不要手动修改此区域 -->
<!-- 要卸载: bash deploy.sh --uninstall /path/to/project -->

## AI 开发纪律 · 四阶段（本项目强制）

> 这是「配置即行为 + 远端CI + 手工运维」项目的纪律。详规见 `ai-workflow/四阶段蓝图.md`。**按 0→1→2→3 顺序执行，不跳步。**

### 阶段 0 · 归因（动码前先定层）
动任何代码前，先把问题钉到 **代码 / 配置 / 运维 / 数据** 某一层并给证据。
**不是"代码"层就不许写代码**——先去对应层求证。
（流程引擎/nacos/UIM 里一半"bug"是配置/运维，写代码修=白费+引新 bug。触发 `attribute-rootcause` skill。）

### 阶段 1 · 外部真相（先核对，再动手）
动手前读 `ai-workflow/环境真相档案.md`（或本 CLAUDE.md 的"环境真相"段）。
**结构性真相入档案、运行时状态现场探针**——别把"列建了没/jar 新不新"写死进文档（必过期），也别靠现探去问稳定结构。

### 阶段 2 · 取值地图（不写死 ID 的真正含义）
取任何外部值前查「取值地图」（档案 §四）把概念钉到**唯一正路**。
**警告**：不写死 ID ≠ 只是别写裸数字。走真 API 也会取错值。表里没有的概念，**停下问人，绝不自创查法**。

### 阶段 3 · 验证闭环（无实证不许说"修好了"）
**铁律**：「修好了 / 部署成功 / 应该没问题 / 已完成」这类话，没有线上实证一律不许说出口。Evidence before assertions。
按改动类型取实证（触发 `verify-closure` skill）：
- 后端：确认代码已 push + 构建新 jar
- DB：实查列存在（**确认是否有自动迁移**）
- 前端：清缓存重登后线上验
- **部署 SUCCESS ≠ 生效**

### 回灌（每次收尾必做）
任务收尾，若学到一条**新的外部真相**（新藏身处/新探针/新配置坑），**主动起草一条**追加到 `ai-workflow/环境真相档案.md` §八回灌候选区，交人审。真相档案是活体，AI 是默认抄写员。

### Hooks / 危险动作
- 危险/对外动作（写库、部署、删数据）先取证、先确认；改/删前先查清目标。
- hook 被拦（protect-files / safe-bash 等）先确认意图，别绕过。

### 开工前准备
需求模糊、目标不清、验收不明时，先触发 `ai-task-preflight`，形成任务简报，再进入阶段 0。
SNIPPET
)

  # 不存在 CLAUDE.md → 创建
  if [ ! -f "$target" ]; then
    {
      printf '%s\n' "$begin_marker"
      printf '%s\n' "$snippet"
      printf '%s\n' "$end_marker"
    } > "$target"
    log "创建 CLAUDE.md 并注入片段"
    return
  fi

  # CLAUDE.md 已存在，检查标记
  if grep -Eq "FOUR-[^-]+-AI-WORKFLOW-BEGIN" "$target" 2>/dev/null; then
    # 标记已存在 → 替换内容（支持升级）
    local tmp_file
    tmp_file="$(mktemp)"
    awk -v begin="$begin_marker" -v end="$end_marker" -v snippet="$snippet" '
      $0 ~ /FOUR-[^-]+-AI-WORKFLOW-BEGIN/ {
        print begin
        print snippet
        getline
        while ($0 !~ /FOUR-[^-]+-AI-WORKFLOW-END/) { getline }
        print end
        next
      }
      { print }
    ' "$target" > "$tmp_file" && mv "$tmp_file" "$target"
    log "更新 CLAUDE.md 中的四阶段片段"
  else
    # 无标记 → 追加
    {
      printf '\n%s\n' "$begin_marker"
      printf '%s\n' "$snippet"
      printf '%s\n' "$end_marker"
    } >> "$target"
    log "追加四阶段片段到 CLAUDE.md"
  fi
}

# 打印部署摘要
print_summary() {
  local proj="$1"
  local awd="$proj/ai-workflow"

  separator
  printf '\n  ══ 四阶段工作流 · 部署完成 ══\n\n'

  printf '  ✓ 全局: Skills 已安装到 ~/.claude/skills/ 和 ~/.codex/skills/\n'
  [ -n "$proj" ] && printf '  ✓ 项目: %s\n' "$proj"

  printf '\n  ── 检测到的技术栈 ──\n'
  [ -n "$DETECTED_LANG" ]      && printf '    语言: %s\n' "$DETECTED_LANG"
  [ -n "$DETECTED_FRAMEWORK" ] && printf '    框架: %s\n' "$DETECTED_FRAMEWORK"
  [ -n "$DETECTED_FRONTEND" ]  && printf '    前端: %s\n' "$DETECTED_FRONTEND"
  [ -n "$DETECTED_BUILD" ]     && printf '    构建: %s\n' "$DETECTED_BUILD"
  [ -n "$DETECTED_DB" ]        && printf '    数据库: %s\n' "$DETECTED_DB"
  [ -n "$DETECTED_CI" ]        && printf '    CI: %s\n' "$DETECTED_CI"
  [ "$DETECTED_HAS_NACOS" = true ] && printf '    Nacos: 检测到\n'
  [ "$DETECTED_HAS_FLOW" = true ]  && printf '    流程引擎: 检测到\n'
  [ -z "$DETECTED_LANG" ] && printf '    （未能自动检测，模板使用通用版本）\n'

  printf '\n  ── 下一步（必须手动完成）──\n\n'
  printf '  1. 编辑 ai-workflow/环境真相档案.md\n'
  printf '     → 搜索 [待填] 标记，逐项填写\n'
  printf '     → 重点：部署链路、数据库真相、appId 权威表\n\n'
  printf '  2. 建立本项目的取值地图\n'
  printf '     → 阅读 ai-workflow/取值地图指南.md\n'
  printf '     → 填写 ai-workflow/环境真相档案.md §四\n\n'
  printf '  3. 把取值地图禁用歧路加入 code-self-review §6.9\n'
  printf '     → bash deploy.sh --install-review-addon\n\n'
  printf '  4. 打开四阶段工作流说明页（可选）\n'
  printf '     → ai-workflow/四阶段工作流.html\n\n'
  printf '  5. 重启 Claude Code / Codex 会话，触发词生效:\n'
  printf '     开工准备: 「开始前准备」「需求澄清」「先 grill 我」\n'
  printf '     验证闭环: 「验证一下」「修好了吗」「确认生效」\n'
  printf '     归因:     「根因是什么」「先别急着改」「归因」\n'
}

# ── 项目级卸载 ──

do_project_uninstall() {
  local proj="$1"
  local awd="$proj/ai-workflow"

  printf '\n  ▶ 项目级卸载\n'

  # 移除 CLAUDE.md 中的标记区域
  local target="$proj/CLAUDE.md"
  if [ -f "$target" ] && grep -Eq "FOUR-[^-]+-AI-WORKFLOW-BEGIN" "$target" 2>/dev/null; then
    local tmp_file
    tmp_file="$(mktemp)"
    awk '
      /FOUR-[^-]+-AI-WORKFLOW-BEGIN/ { skip=1; next }
      /FOUR-[^-]+-AI-WORKFLOW-END/   { skip=0; next }
      !skip { print }
    ' "$target" > "$tmp_file" && mv "$tmp_file" "$target"
    log "移除 CLAUDE.md 中的四阶段片段"
  else
    skip "CLAUDE.md 中无四阶段片段"
  fi

  # 确认删除 ai-workflow/
  if [ -d "$awd" ]; then
    printf '  ⚠ 是否删除 %s ？可能包含你的编辑。[y/N] ' "$awd"
    local answer
    read -r answer
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
      rm -rf "$awd"
      log "已删除: $awd"
    else
      skip "保留: $awd"
    fi
  else
    skip "ai-workflow/ 不存在"
  fi
}

# ── 项目级状态检查 ──

do_project_check() {
  local proj="$1"
  local awd="$proj/ai-workflow"

  printf '\n  ▶ 项目级状态: %s\n' "$proj"

  [ -d "$awd" ] && log "ai-workflow/ 存在" || printf '  ✗ ai-workflow/ 不存在\n'

  # CLAUDE.md 标记
  local target="$proj/CLAUDE.md"
  if [ -f "$target" ] && grep -Eq "FOUR-[^-]+-AI-WORKFLOW-BEGIN" "$target" 2>/dev/null; then
    log "CLAUDE.md 四阶段片段已注入"
  else
    printf '  ✗ CLAUDE.md 未注入四阶段片段\n'
  fi

  # 关键文件
  [ -f "$awd/环境真相档案.md" ] && log "环境真相档案.md 存在" || printf '  ✗ 环境真相档案.md 缺失\n'
  [ -f "$awd/取值地图指南.md" ] && log "取值地图指南.md 存在" || printf '  ✗ 取值地图指南.md 缺失\n'
  [ -f "$awd/四阶段蓝图.md" ] && log "四阶段蓝图.md 存在" || printf '  ✗ 四阶段蓝图.md 缺失\n'

  # 待填项统计
  if [ -f "$awd/环境真相档案.md" ]; then
    local pending
    pending=$(grep -c '\[待填\]' "$awd/环境真相档案.md" 2>/dev/null || echo "0")
    printf '\n  环境真相档案待填项: %s 处\n' "$pending"
  fi
}

# ── 主入口 ──────────────────────────────────────────────

main() {
  local mode="install"
  local project_path=""
  local install_review_addon=false

  # 解析参数
  while [ $# -gt 0 ]; do
    case "$1" in
      --check)     mode="check"; shift ;;
      --uninstall) mode="uninstall"; shift ;;
      --install-review-addon) mode="install-review-addon"; shift ;;
      --uninstall-review-addon) mode="uninstall-review-addon"; shift ;;
      --with-review-addon) install_review_addon=true; shift ;;
      --help|-h)
        echo "用法:"
        echo "  bash deploy.sh                                  仅全局安装（Claude + Codex）"
        echo "  bash deploy.sh /path/to/project                 全局 + 项目级部署"
        echo "  bash deploy.sh --with-review-addon /path        部署项目时同时安装 code-self-review 增补"
        echo "  bash deploy.sh --install-review-addon           仅安装 code-self-review 取值地图增补"
        echo "  bash deploy.sh --uninstall-review-addon         移除 code-self-review 取值地图增补"
        echo "  bash deploy.sh --check [/path]                  查状态"
        echo "  bash deploy.sh --uninstall [/path]              卸载"
        echo ""
        echo "可选环境变量:"
        echo "  CODE_SELF_REVIEW_SKILL=/path/to/SKILL.md        指定 code-self-review skill 文件"
        exit 0
        ;;
      -*) die "未知参数: $1（试试 --help）" ;;
      *)  project_path="$1"; shift ;;
    esac
  done

  # 规范化项目路径
  if [ -n "$project_path" ]; then
    requested_path="$project_path"
    project_path="$(cd "$requested_path" 2>/dev/null && pwd)" || die "路径无效: $requested_path"
  fi

  separator
  printf '  四阶段 AI 开发工作流 · deploy.sh\n'
  separator

  case "$mode" in
    check)
      do_global_check
      [ -n "$project_path" ] && do_project_check "$project_path"
      ;;

    uninstall)
      do_global_uninstall
      [ -n "$project_path" ] && do_project_uninstall "$project_path"
      printf '\n  卸载完成。\n'
      ;;

    install-review-addon)
      do_review_addon_install
      ;;

    uninstall-review-addon)
      do_review_addon_uninstall
      ;;

    install)
      # Phase 1: 全局（始终执行）
      do_global_install

      # Phase 2: 项目级（指定路径时执行）
      if [ -n "$project_path" ]; then
        validate_project "$project_path"
        detect_tech_stack "$project_path"
        create_workflow_dir "$project_path"
        generate_truth_archive "$project_path"
        generate_value_map_guide "$project_path"
        inject_claude_md "$project_path"
        if [ "$install_review_addon" = true ]; then
          do_review_addon_install || warn "跳过 code-self-review 增补；主部署已完成"
        fi
        print_summary "$project_path"
      else
        if [ "$install_review_addon" = true ]; then
          do_review_addon_install || warn "跳过 code-self-review 增补；全局 Skills 已安装"
        fi
        # 仅全局安装，打印简要提示
        printf '\n  ✓ 全局 Skills 安装完成。\n'
        printf '  → 要部署到项目: bash deploy.sh /path/to/project\n'
        printf '  → 要安装 review 增补: bash deploy.sh --install-review-addon\n'
        printf '  → 重启 Claude Code / Codex 会话后触发词生效:\n'
        printf '    开工准备: 「开始前准备」「需求澄清」「先 grill 我」\n'
        printf '    验证闭环: 「验证一下」「修好了吗」「确认生效」\n'
        printf '    归因:     「根因是什么」「先别急着改」「归因」\n'
      fi
      ;;
  esac

  separator
}

main "$@"
