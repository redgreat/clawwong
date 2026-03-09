#!/usr/bin/env bash
#
# OpenClaw (小龙虾) 停止脚本
#
set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }

echo ""
info "🦞 正在停止 OpenClaw Gateway..."
echo ""

stopped=false

# 尝试通过 launchd 停止
PLIST="$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist"
if [[ -f "$PLIST" ]]; then
    launchctl unload "$PLIST" 2>/dev/null && {
        ok "已通过 launchd 停止 Gateway 守护进程"
        stopped=true
    } || true
fi

# 杀掉残留进程
if pgrep -f "openclaw.*gateway" > /dev/null 2>&1; then
    pkill -f "openclaw.*gateway" 2>/dev/null && {
        ok "已终止 Gateway 进程"
        stopped=true
    } || true
fi

if [[ "$stopped" == "false" ]]; then
    warn "未发现正在运行的 Gateway 进程"
fi

echo ""
