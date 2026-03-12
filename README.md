# 🦞 OpenClaw (小龙虾) 安装部署记录

> MacBook Pro 2020 M1 / 16GB / macOS
>
> 安装时间：2026-03-09 ~ 2026-03-10

---

## 环境概览

| 组件 | 版本 | 安装方式 | 路径 |
|------|------|----------|------|
| Node.js | v24.14.0 | nvm | `~/.nvm/versions/node/v24.14.0/` |
| OpenClaw | 2026.3.8 | npm 全局 | `~/.nvm/versions/node/v24.14.0/bin/openclaw` |
| Ollama | 0.17.7 | 官方脚本 | `/Applications/Ollama.app` |
| 飞书插件 | 内置 | OpenClaw 自带 | 随 OpenClaw 安装 |
| 本地模型 | qwen2.5:7b | ollama pull | `~/.ollama/models/` |

---

## 安装步骤

### 1. 安装 OpenClaw

```bash
# 通过 nvm 使用 Node.js 24（已有，满足 ≥22 要求）
nvm use 24

# 全局安装 OpenClaw
npm install -g openclaw@latest

# 运行设置向导
openclaw onboard --install-daemon
```

### 2. 配置飞书渠道

飞书插件为 OpenClaw 内置，无需额外安装。

**飞书开放平台操作：**

1. 打开 [飞书开放平台](https://open.feishu.cn/app)，创建企业自建应用
2. 复制 **App ID** (`cli_xxx`) 和 **App Secret**
3. 「添加应用能力」→ 启用**机器人**
4. 「权限管理」→ 添加 `im:message`、`im:message:send_as_bot` 等权限
5. 「事件与回调」→ 选择 **WebSocket 长连接**，添加事件 `im.message.receive_v1`
6. 「版本管理与发布」→ 创建版本并发布

**OpenClaw 配置：**

```bash
# 向导会引导填入 App ID 和 App Secret
openclaw channels add
```

**首次配对：**

飞书里给机器人发消息后，会收到配对码，在终端批准：

```bash
openclaw pairing approve feishu <配对码>
```

### 3. 安装 Ollama 本地模型

```bash
# 安装 Ollama（brew 可能因版本冲突失败，用官方脚本）
curl -fsSL https://ollama.com/install.sh | sh

# 下载 Qwen2.5 7B 模型（约 4.7GB，中文能力好）
ollama pull qwen2.5:7b

# 测试模型
ollama run qwen2.5:7b
```

### 4. OpenClaw 配置本地模型

```bash
openclaw configure
```

选择步骤：
1. Select sections → **Model**
2. Model/auth provider → **Custom Provider**
3. API Base URL → `http://127.0.0.1:11434/v1`
4. Model name → `qwen2.5:7b`

### 5. Web 控制台与外网访问 (NAS/DDNS 穿透)

OpenClaw 默认带有本机的 Web 可视化工作台（Dashboard），提供系统状态监控、运行日志查看和模型设置功能。

**控制台地址**：`http://127.0.0.1:18789` （默认仅限本机访问）

如果需要通过 NAS 或者路由器的 DDNS 将控制台映射到外网，并解决因为非 HTTPS 环境而被浏览器拦截认证的问题，请执行以下命令：

```bash
# 1. 允许局域网其他设备访问（将绑定地址从 loopback 改为 lan 或者 all）
openclaw config set gateway.bind lan

# 2. 允许所有来源域名的跨域请求
openclaw config set gateway.controlUi.allowedOrigins '["*"]'

# 3. （可选，针对只有 HTTP 而没有 HTTPS 证书的 NAS）允许在不安全的网络下强制使用令牌认证
openclaw config set gateway.controlUi.allowInsecureAuth true

# 4. （关键）彻底关闭前端控制台对设备“指纹”的硬性要求，允许单纯用 Token 穿透
openclaw config set gateway.controlUi.dangerouslyDisableDeviceAuth true

# 5. 获取本机网关的唯一安全登录令牌 Token (请做好保密)
openclaw config get gateway.auth.token

# 6. 生效配置
openclaw gateway restart
```
**如何在外网直接登录**：
拿到 Token 后，在任意浏览器中（建议无痕模式首次打开缓存防串）用如下带参数的方式访问你配置的外网地址：
`http://你的外网域名:转发的端口/#token=你的那串长长的Token值` （即可秒下认证）。

### 6. 更换/添加第三方云端大模型 (如 DeepSeek)

如果你发现本地的 Qwen 模型较慢或能力不够，希望在 Web 端使用速度快且更强大的第三方模型（比如 DeepSeek V3、Kimi 或者通义千问），直接在终端执行添加 provider 即可：

```bash
# 添加 DeepSeek 官方接口为例：
openclaw config add-provider deepseek --base-url "https://api.deepseek.com/v1" --api-key "sk-你的APIKEY" --model-ids "deepseek-chat" --model-name "DeepSeek-V3" --alias deepseek

# 重启网关后生效
openclaw gateway restart
```
配置完成后去 Web 控制台的 `Agent（代理）` 页面，点击原有的模型选中下拉框，就能看到新增加的 `deepseek-chat`，选中并点击右下角 `Save` 即刻切换完毕。

---

## 遇到的问题 & 解决方案

### 问题 1：`zsh: command not found: openclaw`

**原因**：`~/.zshrc` 中 nvm 加载路径硬编码了 `/opt/homebrew/Cellar/nvm/0.39.3/nvm.sh`，但 nvm 已升级到 `0.40.3`，旧路径不存在导致 nvm 未加载。

**解决**：修改 `~/.zshrc`，将路径改为通用写法：

```bash
# 修复前（硬编码版本号，升级后会失效）
[ -s "/opt/homebrew/Cellar/nvm/0.39.3/nvm.sh" ] && . "/opt/homebrew/Cellar/nvm/0.39.3/nvm.sh"

# 修复后（使用 $NVM_DIR 变量，永不过期）
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
```

### 问题 2：`API rate limit reached`

**原因**：Gemini 免费 API Key 有每分钟请求次数限制。

**解决**：
- 等几分钟配额恢复
- 或切换为本地 Ollama 模型（无限制）

### 问题 3：飞书 `app do not have bot`

**原因**：飞书应用没有启用「机器人」能力。

**解决**：在飞书开放平台 →「添加应用能力」→ 启用「机器人」→ 重新发布应用。

### 问题 4：飞书 `duplicate plugin id detected` 警告

**原因**：手动安装了 `@openclaw/feishu` 插件，但 OpenClaw 已内置飞书支持，导致两份冲突。

**解决**：删除手动安装的插件：

```bash
rm -rf ~/.openclaw/extensions/feishu
openclaw gateway restart
```

### 问题 5：`brew install ollama` 失败

**原因**：Homebrew cask 定义冲突（`conflicts_with` stanza 报错）。

**解决**：使用官方安装脚本替代 brew：

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

---

## 管理脚本

项目 `scripts/` 目录提供了以下管理脚本：

| 脚本 | 功能 |
|------|------|
| `scripts/install.sh` | 一键安装 OpenClaw |
| `scripts/uninstall.sh` | 完全卸载 OpenClaw |
| `scripts/start.sh` | 启动 Gateway |
| `scripts/stop.sh` | 停止 Gateway |
| `scripts/status.sh` | 查看运行状态 |
| `scripts/setup-feishu.sh` | 飞书配置指南 |
| `scripts/setup-ollama.sh` | Ollama 安装 & 模型下载 |

---

## 常用命令速查

```bash
# OpenClaw
openclaw onboard              # 设置向导
openclaw configure             # 修改配置
openclaw gateway restart       # 重启网关
openclaw doctor                # 健康检查
openclaw tui                   # 终端对话界面
openclaw status                # 查看渠道状态
openclaw pairing approve <ch> <code>  # 批准配对

# Ollama
ollama list                    # 查看已安装模型
ollama run qwen2.5:7b          # 直接对话
ollama pull <model>            # 下载模型
ollama rm <model>              # 删除模型

# 管理脚本
./scripts/start.sh             # 启动
./scripts/stop.sh              # 停止
./scripts/status.sh            # 状态
./scripts/uninstall.sh         # 卸载
```

---

## 卸载清理

```bash
# 1. 卸载 OpenClaw
./scripts/uninstall.sh

# 2. 卸载 Ollama（可选）
ollama rm qwen2.5:7b           # 删除模型
rm -rf ~/.ollama               # 删除模型数据
rm -rf /Applications/Ollama.app
sudo rm /usr/local/bin/ollama

# 3. 以上操作不影响：nvm、Node.js、pyenv 等其他工具
```
