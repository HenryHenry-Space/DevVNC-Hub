# Dev VNC Server

🖥️ 通用开发用远程桌面服务 - 用于 SSH 远程连接时的 GUI 应用调试  
🖥️ A general-purpose remote desktop service for development, designed for GUI debugging over SSH

## 功能特点 / Features

- 🚀 一键启动虚拟桌面环境 / One-click virtual desktop startup
- 🌐 支持浏览器访问 (noVNC) / Browser access via noVNC
- 🔌 支持 VNC 客户端连接 / VNC client support
- ⚙️ 可配置分辨率、端口、窗口管理器 / Configurable resolution, ports, and window manager
- 🐍 提供 Python CLI 接口 / Python CLI included
- 📦 易于安装和管理 / Easy to install and manage

## 快速开始 / Quick Start

### 安装 / Install

```bash
# 克隆项目 / Clone repository
cd /home/henry/workspace/dev_app_vnc

# 运行安装脚本 / Run install script
./scripts/install.sh
```

### 使用 / Usage

```bash
# 启动远程桌面 / Start remote desktop
dev-vnc start

# 查看状态 / Show status
dev-vnc status

# 查看访问信息 / Show access info
dev-vnc info

# 在 VNC 环境中运行程序 / Run command in VNC
dev-vnc run python my_gui_app.py

# 停止服务 / Stop service
dev-vnc stop
```

## 访问方式 / Access

### 浏览器访问 (推荐) / Browser (recommended)

启动服务后，打开浏览器访问 / After starting the service, open in browser:
- `http://localhost:6080/vnc.html`
- `http://<服务器IP>:6080/vnc.html`

### VNC 客户端 / VNC Client

使用任意 VNC 客户端连接 / Connect with any VNC client:
- 地址 / Address: `localhost:5999` 或 `<服务器IP>:5999`
- 密码 / Password: `devvnc123` (可配置 / configurable)

## 配置 / Configuration

### 配置文件 / Config file

配置文件位于 `~/.config/dev-vnc/config.env` / Config file location: `~/.config/dev-vnc/config.env`

```bash
# 显示器编号 / Display number
DEV_VNC_DISPLAY=99

# VNC 端口 / VNC port
DEV_VNC_PORT=5999

# noVNC Web 端口 / noVNC web port
DEV_VNC_NOVNC_PORT=6080

# 分辨率 / Resolution
DEV_VNC_RESOLUTION=1920x1080x24

# VNC 密码 / VNC password
DEV_VNC_PASSWORD=devvnc123

# 窗口管理器 (fluxbox, openbox, i3) / Window manager
DEV_VNC_WM=fluxbox
```

### 环境变量 / Environment variables

也可以通过环境变量覆盖配置 / Override with environment variables:

```bash
DEV_VNC_RESOLUTION=2560x1440x24 dev-vnc start
```

## 命令参考 / Command reference

| 命令 / Command | 说明 / Description |
|------|------|
| `dev-vnc start` | 启动远程桌面服务 / Start remote desktop |
| `dev-vnc stop` | 停止远程桌面服务 / Stop remote desktop |
| `dev-vnc restart` | 重启服务 / Restart service |
| `dev-vnc status` | 显示服务状态 / Show status |
| `dev-vnc info` | 显示访问信息 / Show access info |
| `dev-vnc logs [type]` | 显示日志 (vnc/novnc/all) / Show logs |
| `dev-vnc run <cmd>` | 在 VNC 环境中运行命令 / Run command in VNC |
| `dev-vnc config` | 显示当前配置 / Show configuration |
| `dev-vnc install-deps` | 安装系统依赖 / Install dependencies |
| `dev-vnc help` | 显示帮助信息 / Show help |

## Python CLI

也可以使用 Python CLI / You can also use the Python CLI:

```bash
# 安装 / Install
pip install -e .

# 使用 / Usage
devvnc start
devvnc status
devvnc run python my_app.py
```

## 系统要求 / System requirements

### 支持的操作系统 / Supported OS

- Ubuntu / Debian
- Fedora / CentOS / RHEL
- Arch Linux

### 依赖 / Dependencies

- Xvfb
- x11vnc
- fluxbox (或其他窗口管理器)
- noVNC
- websockify
- Python 3.8+

## 典型使用场景 / Typical use cases

### 远程 GUI 开发 / Remote GUI development

在 SSH 连接的远程服务器上调试 GUI 应用 / Debug GUI apps over SSH:

```bash
# SSH 连接到服务器 / SSH into server
ssh user@server

# 启动远程桌面 / Start remote desktop
dev-vnc start

# 在本地浏览器打开 / Open in local browser

# 运行 GUI 应用 / Run GUI app
dev-vnc run python my_gui_app.py
```

### CI/CD 中的 GUI 测试 / GUI testing in CI/CD

在无头环境中运行 GUI 测试 / Run GUI tests in headless environments:

```bash
# 启动虚拟桌面 / Start virtual desktop
dev-vnc start

# 运行 GUI 测试 / Run GUI tests
dev-vnc run pytest tests/gui/
```

### 容器中的 GUI 应用 / GUI apps in containers

在 Docker 容器中运行 GUI 应用 / Run GUI apps in Docker:

```dockerfile
FROM ubuntu:22.04

# 安装依赖 / Install dependencies
RUN apt-get update && apt-get install -y \
    xvfb x11vnc fluxbox novnc websockify

# 复制 dev-vnc / Copy dev-vnc
COPY . /app/dev-vnc
RUN /app/dev-vnc/scripts/install.sh

EXPOSE 5999 6080

CMD ["dev-vnc", "start"]
```

## 项目结构 / Project structure

```
dev_app_vnc/
├── README.md
├── pyproject.toml
├── config/
│   └── config.env.example
├── devvnc/
│   ├── __init__.py
│   ├── cli.py
│   ├── server.py
│   └── config.py
├── scripts/
│   ├── dev-vnc-server.sh
│   └── install.sh
├── tests/
│   └── test_server.py
└── docs/
    └── ...
```

## 故障排除 / Troubleshooting

### 服务无法启动 / Service won't start

1. 检查依赖是否安装 / Check dependencies:
   ```bash
   dev-vnc install-deps
   ```

2. 检查端口是否被占用 / Check port usage:
   ```bash
   netstat -tlnp | grep -E '5999|6080'
   ```

3. 查看日志 / View logs:
   ```bash
   dev-vnc logs
   ```

### 无法连接 / Cannot connect

1. 检查防火墙设置 / Check firewall:
   ```bash
   sudo ufw allow 5999
   sudo ufw allow 6080
   ```

2. 确认服务正在运行 / Confirm service is running:
   ```bash
   dev-vnc status
   ```

## License

MIT License
