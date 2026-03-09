#!/usr/bin/env bash
#
# OpenClaw (小龙虾) 启动脚本
#
set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

# 加载 nvm
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

# 切换到项目 .nvmrc 指定的版本
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
if [[ -f "$PROJECT_DIR/.nvmrc" ]]; then
    nvm use --silent 2>/dev/null || true
fi

# 检查 openclaw 是否已安装
if ! command -v openclaw &>/dev/null; then
    err "openclaw 未安装，请先运行 ./scripts/install.sh"
    exit 1
fi

echo ""
info "🦞 正在启动 OpenClaw Gateway..."
echo ""

# 尝试通过 launchd 启动（如果已配置）
PLIST="$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist"
if [[ -f "$PLIST" ]]; then
    launchctl load "$PLIST" 2>/dev/null || true
    ok "已通过 launchd 启动 Gateway 守护进程"
    echo ""
    info "查看日志:  openclaw gateway --verbose"
    info "查看状态:  ./scripts/status.sh"
else
    info "未发现 launchd 服务配置，以前台模式启动..."
    info "按 Ctrl+C 停止"
    echo ""
    openclaw gateway --port 18789 --verbose
fi
