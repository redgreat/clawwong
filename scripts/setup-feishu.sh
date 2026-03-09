#!/usr/bin/env bash
#
# OpenClaw (小龙虾) 飞书渠道配置指南
# 打印飞书配置步骤，辅助用户完成配置
#
set -euo pipefail

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
step()  { echo -e "${CYAN}[STEP]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }

# 加载 nvm
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

echo ""
echo "🦞 ============================================="
echo "   OpenClaw 飞书渠道配置指南"
echo "============================================="
echo ""

info "飞书接入使用 WebSocket 长连接模式，不需要公网 IP"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  第一步：在飞书开放平台创建应用"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
step "1. 打开飞书开放平台: https://open.feishu.cn/app"
step "2. 点击 '创建企业自建应用'"
step "3. 填写应用名称（如 'OpenClaw AI助手'）和描述"
step "4. 进入应用详情，复制 App ID (格式: cli_xxx) 和 App Secret"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  第二步：配置权限和机器人能力"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
step "5. 在'权限管理'中添加以下权限:"
echo "     - im:message (消息)"
echo "     - im:message:send_as_bot (以机器人身份发送消息)"
echo "     - im:message.p2p_msg:readonly (读取私聊消息)"
echo "     - im:message.group_at_msg:readonly (读取群@消息)"
echo "     - im:message:readonly (读取消息)"
echo "     - im:resource (资源)"
echo "     - im:chat.members:bot_access (群成员)"
echo "     - contact:user.employee_id:readonly (用户信息)"
echo ""
step "6. 在'添加应用能力'中启用'机器人'能力"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  第三步：配置事件订阅"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
step "7. 在'事件与回调'中:"
echo "     - 选择 '使用长连接接收事件 (WebSocket)'"
echo "     - 添加事件: im.message.receive_v1"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  第四步：发布应用"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
step "8. 在'版本管理与发布'中创建版本并提交审核"
step "9. 等待管理员审批（企业自建应用通常自动通过）"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  第五步：在 OpenClaw 中配置飞书"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
step "运行以下命令（交互式配置）:"
echo "  openclaw channels add"
echo ""
step "或手动编辑配置文件: ~/.openclaw/openclaw.json"
echo '  {
    "channels": {
      "feishu": {
        "enabled": true,
        "dmPolicy": "pairing",
        "accounts": {
          "main": {
            "appId": "cli_xxx",
            "appSecret": "你的AppSecret",
            "botName": "OpenClaw AI助手"
          }
        }
      }
    }
  }'
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  第六步：启动并测试"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
step "查看 Gateway 状态:  openclaw gateway status"
step "重启 Gateway:       openclaw gateway restart"
step "查看日志:           openclaw logs --follow"
step "在飞书中给机器人发消息测试"
echo ""

warn "首次发消息时会收到配对码，运行以下命令批准:"
echo "  openclaw pairing approve feishu <配对码>"
echo ""
