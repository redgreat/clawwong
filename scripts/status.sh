#!/usr/bin/env bash
#
# OpenClaw (小龙虾) 状态检查脚本
#
set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }

# 加载 nvm
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

echo ""
echo "🦞 ============================================="
echo "   OpenClaw 状态检查"
echo "============================================="
echo ""

# 1. Node.js 版本
info "--- Node.js ---"
if command -v node &>/dev/null; then
    ok "Node.js: $(node --version)"
    ok "npm:     $(npm --version)"
else
    err "Node.js 未安装"
fi

# 2. OpenClaw 版本
echo ""
info "--- OpenClaw ---"
if command -v openclaw &>/dev/null; then
    ok "版本:    $(openclaw --version 2>/dev/null || echo 'unknown')"
    ok "路径:    $(which openclaw)"
else
    err "openclaw 未安装"
fi

# 3. Gateway 进程
echo ""
info "--- Gateway 进程 ---"
if pgrep -f "openclaw.*gateway" > /dev/null 2>&1; then
    ok "Gateway 正在运行"
    pgrep -af "openclaw.*gateway" | while read -r line; do
        echo "         PID: $line"
    done
else
    warn "Gateway 未运行"
fi

# 4. launchd 服务
echo ""
info "--- launchd 服务 ---"
PLIST="$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist"
if [[ -f "$PLIST" ]]; then
    ok "服务配置存在: $PLIST"
    if launchctl list 2>/dev/null | grep -q "openclaw"; then
        ok "服务已加载"
    else
        warn "服务未加载"
    fi
else
    info "未配置 launchd 服务"
fi

# 5. 工作区
echo ""
info "--- 工作区 ---"
WORKSPACE="$HOME/.openclaw"
if [[ -d "$WORKSPACE" ]]; then
    ok "工作区路径: $WORKSPACE"
    # 显示目录大小
    local_size="$(du -sh "$WORKSPACE" 2>/dev/null | cut -f1)"
    info "工作区大小: ${local_size}"
else
    warn "工作区不存在 (未运行过 onboard)"
fi

# 6. openclaw doctor
echo ""
info "--- 健康检查 ---"
if command -v openclaw &>/dev/null; then
    info "运行 openclaw doctor ..."
    echo ""
    openclaw doctor 2>&1 || true
fi

echo ""
