#!/usr/bin/env bash
#
# Ollama 安装 & 模型下载脚本
# 适用于 macOS (Apple Silicon M1/M2/M3)
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

# 默认模型（中文能力好，适合 16GB 内存）
DEFAULT_MODEL="qwen2.5:7b"

echo ""
echo "🦙 ============================================="
echo "   Ollama 安装 & 模型下载脚本"
echo "============================================="
echo ""

# ==================== 安装 Ollama ====================
install_ollama() {
    if command -v ollama &>/dev/null; then
        ok "Ollama 已安装: $(ollama --version)"
        return 0
    fi

    info "正在安装 Ollama..."

    # macOS 官方安装脚本
    if [[ "$(uname)" == "Darwin" ]]; then
        curl -fsSL https://ollama.com/install.sh | sh
    else
        err "此脚本仅支持 macOS"
        exit 1
    fi

    if command -v ollama &>/dev/null; then
        ok "Ollama 安装成功: $(ollama --version)"
    else
        err "Ollama 安装失败"
        exit 1
    fi
}

# ==================== 启动 Ollama 服务 ====================
ensure_ollama_running() {
    info "检查 Ollama 服务..."

    if curl -s http://127.0.0.1:11434/api/tags &>/dev/null; then
        ok "Ollama 服务已在运行"
        return 0
    fi

    info "启动 Ollama 服务..."
    # macOS 上 Ollama 安装后会自动以 app 形式运行
    # 如果没有，手动启动
    if [[ -d "/Applications/Ollama.app" ]]; then
        open /Applications/Ollama.app
        sleep 3
    else
        ollama serve &>/dev/null &
        sleep 2
    fi

    if curl -s http://127.0.0.1:11434/api/tags &>/dev/null; then
        ok "Ollama 服务已启动"
    else
        warn "Ollama 服务可能未就绪，请等待几秒后重试"
    fi
}

# ==================== 下载模型 ====================
pull_model() {
    local model="${1:-$DEFAULT_MODEL}"

    info "检查模型: $model"

    if ollama list 2>/dev/null | grep -q "$model"; then
        ok "模型 $model 已存在"
        return 0
    fi

    info "正在下载模型 $model（首次下载约 4-5GB，请耐心等待）..."
    echo ""
    ollama pull "$model"
    echo ""
    ok "模型 $model 下载完成"
}

# ==================== 测试模型 ====================
test_model() {
    local model="${1:-$DEFAULT_MODEL}"

    echo ""
    info "正在测试模型 $model ..."
    echo ""

    echo '你好，请用一句话介绍你自己。' | ollama run "$model" --nowordwrap 2>/dev/null

    echo ""
    ok "模型测试完成"
}

# ==================== 信息总结 ====================
print_summary() {
    echo ""
    echo "============================================="
    ok "🦙 Ollama 安装 & 模型下载完成！"
    echo "============================================="
    echo ""
    info "已安装模型:"
    ollama list 2>/dev/null
    echo ""
    info "Ollama API 地址: http://127.0.0.1:11434"
    info "OpenAI 兼容地址: http://127.0.0.1:11434/v1"
    echo ""
    info "常用命令:"
    echo "  ollama list                  # 查看已下载的模型"
    echo "  ollama run $DEFAULT_MODEL    # 直接对话测试"
    echo "  ollama pull <model>          # 下载其他模型"
    echo "  ollama rm <model>            # 删除模型"
    echo ""
    info "OpenClaw 配置本地模型:"
    echo "  openclaw configure"
    echo "  → Model → Custom Provider"
    echo "  → API Base URL: http://127.0.0.1:11434/v1"
    echo "  → Model name:   $DEFAULT_MODEL"
    echo ""
}

# ==================== 主流程 ====================
main() {
    local model="${1:-$DEFAULT_MODEL}"

    install_ollama
    ensure_ollama_running
    pull_model "$model"

    read -rp "是否测试模型？(y/N) " answer
    if [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]; then
        test_model "$model"
    fi

    print_summary
}

main "$@"
