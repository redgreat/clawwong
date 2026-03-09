#!/usr/bin/env bash
#
# OpenClaw (小龙虾) 一键安装脚本
# 使用 nvm 管理 Node.js 环境，不影响系统其他项目
#
set -euo pipefail

# ==================== 颜色定义 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 重置颜色

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 需要的 Node.js 最低主版本
REQUIRED_NODE_MAJOR=22

# ==================== 检测 nvm ====================
load_nvm() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        # shellcheck source=/dev/null
        source "$NVM_DIR/nvm.sh"
    else
        err "未检测到 nvm，请先安装 nvm："
        err "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
        exit 1
    fi
}

# ==================== 检测 / 安装 Node.js ====================
ensure_node() {
    info "检查 Node.js 版本..."

    # 如果项目有 .nvmrc，先切换
    if [[ -f "$PROJECT_DIR/.nvmrc" ]]; then
        info "发现 .nvmrc，切换到指定版本..."
        nvm use --silent 2>/dev/null || {
            local nvmrc_ver
            nvmrc_ver="$(cat "$PROJECT_DIR/.nvmrc")"
            warn "Node.js v${nvmrc_ver} 未安装，正在通过 nvm 安装..."
            nvm install "$nvmrc_ver"
            nvm use "$nvmrc_ver"
        }
    fi

    local node_ver
    node_ver="$(node --version 2>/dev/null || echo "none")"

    if [[ "$node_ver" == "none" ]]; then
        warn "当前没有可用的 Node.js，正在安装 v${REQUIRED_NODE_MAJOR}..."
        nvm install "$REQUIRED_NODE_MAJOR"
        nvm use "$REQUIRED_NODE_MAJOR"
        node_ver="$(node --version)"
    fi

    # 取主版本号 (去掉 v 和 .x.x)
    local major
    major="${node_ver#v}"
    major="${major%%.*}"

    if (( major < REQUIRED_NODE_MAJOR )); then
        warn "当前 Node.js ${node_ver} 低于要求 (>= ${REQUIRED_NODE_MAJOR})，正在安装..."
        nvm install "$REQUIRED_NODE_MAJOR"
        nvm use "$REQUIRED_NODE_MAJOR"
        node_ver="$(node --version)"
    fi

    ok "Node.js 版本: ${node_ver}"
    ok "npm    版本: $(npm --version)"
}

# ==================== 安装 OpenClaw ====================
install_openclaw() {
    info "检查 OpenClaw 是否已安装..."

    if command -v openclaw &>/dev/null; then
        local current_ver
        current_ver="$(openclaw --version 2>/dev/null || echo "unknown")"
        warn "OpenClaw 已安装 (${current_ver})，将升级到最新版..."
    else
        info "首次安装 OpenClaw..."
    fi

    info "正在通过 npm 全局安装 openclaw@latest ..."
    npm install -g openclaw@latest

    ok "OpenClaw 安装完成: $(openclaw --version 2>/dev/null)"
}

# ==================== 运行 onboard 向导 ====================
run_onboard() {
    echo ""
    echo "============================================="
    info "即将启动 OpenClaw 设置向导 (onboard)"
    info "向导会引导你完成以下配置："
    info "  1. Gateway 网关配置"
    info "  2. 工作区 (Workspace) 设置"
    info "  3. 消息渠道 (Channels) 连接"
    info "  4. 技能 (Skills) 安装"
    echo "============================================="
    echo ""

    read -rp "是否现在启动设置向导？(y/N) " answer
    if [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]; then
        openclaw onboard --install-daemon
    else
        info "跳过向导。你可以稍后运行以下命令手动启动："
        info "  openclaw onboard --install-daemon"
    fi
}

# ==================== 安装信息总结 ====================
print_summary() {
    echo ""
    echo "============================================="
    ok "🦞 OpenClaw 安装完成！"
    echo "============================================="
    echo ""
    info "常用命令："
    echo "  openclaw onboard           # 运行设置向导"
    echo "  openclaw gateway --verbose  # 手动启动 Gateway"
    echo "  openclaw doctor             # 健康检查"
    echo "  openclaw agent --message \"你好\"  # 发送消息测试"
    echo ""
    info "管理脚本 (在项目 scripts/ 目录下)："
    echo "  ./scripts/start.sh          # 启动 Gateway"
    echo "  ./scripts/stop.sh           # 停止 Gateway"
    echo "  ./scripts/status.sh         # 查看状态"
    echo "  ./scripts/uninstall.sh      # 完全卸载"
    echo ""
    info "工作区路径: ~/.openclaw/"
    info "nvm 版本:   使用 .nvmrc 文件锁定，不影响其他项目"
    echo ""
}

# ==================== 主流程 ====================
main() {
    echo ""
    echo "🦞 ============================================="
    echo "   OpenClaw (小龙虾) 安装脚本"
    echo "   $(date '+%Y-%m-%d %H:%M:%S')"
    echo "============================================="
    echo ""

    load_nvm
    ensure_node
    install_openclaw
    run_onboard
    print_summary
}

main "$@"
