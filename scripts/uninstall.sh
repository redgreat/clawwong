#!/usr/bin/env bash
#
# OpenClaw (小龙虾) 卸载脚本
# 安全卸载，不影响系统其他项目
#
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==================== 加载 nvm ====================
load_nvm() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        # shellcheck source=/dev/null
        source "$NVM_DIR/nvm.sh"
    fi
}

# ==================== 停止 Gateway ====================
stop_gateway() {
    info "停止 Gateway 守护进程..."

    # 尝试停止 launchd 服务 (macOS)
    local plist="$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist"
    if [[ -f "$plist" ]]; then
        launchctl unload "$plist" 2>/dev/null && ok "已卸载 launchd 服务" || true
        rm -f "$plist"
        ok "已移除 launchd 配置: $plist"
    else
        info "未发现 launchd 服务配置"
    fi

    # 杀掉残留进程
    if pgrep -f "openclaw.*gateway" > /dev/null 2>&1; then
        pkill -f "openclaw.*gateway" 2>/dev/null && ok "已终止 Gateway 进程" || true
    fi
}

# ==================== 卸载 npm 包 ====================
uninstall_package() {
    info "卸载 OpenClaw npm 全局包..."

    if command -v openclaw &>/dev/null; then
        npm uninstall -g openclaw
        ok "已卸载 openclaw 全局包"
    else
        info "openclaw 命令不存在，跳过 npm 卸载"
    fi
}

# ==================== 清理工作区数据 ====================
cleanup_workspace() {
    local workspace="$HOME/.openclaw"

    if [[ -d "$workspace" ]]; then
        echo ""
        warn "发现 OpenClaw 工作区: $workspace"
        warn "该目录包含你的配置、技能和对话数据。"
        echo ""
        read -rp "是否删除工作区数据？(y/N) " answer
        if [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]; then
            rm -rf "$workspace"
            ok "已删除工作区: $workspace"
        else
            info "保留工作区数据: $workspace"
        fi
    fi
}

# ==================== 主流程 ====================
main() {
    echo ""
    echo "🦞 ============================================="
    echo "   OpenClaw (小龙虾) 卸载脚本"
    echo "============================================="
    echo ""

    read -rp "确认要卸载 OpenClaw？(y/N) " confirm
    if [[ "${confirm,,}" != "y" && "${confirm,,}" != "yes" ]]; then
        info "取消卸载。"
        exit 0
    fi

    echo ""
    load_nvm
    stop_gateway
    uninstall_package
    cleanup_workspace

    echo ""
    echo "============================================="
    ok "🦞 OpenClaw 已卸载！"
    echo "============================================="
    echo ""
    info "以下未被清理（因为可能被其他项目使用）："
    echo "  - nvm 和 Node.js 版本"
    echo "  - .nvmrc 文件"
    echo ""
    info "如需清理 Node.js 版本，请手动运行："
    echo "  nvm uninstall <version>"
    echo ""
}

main "$@"
