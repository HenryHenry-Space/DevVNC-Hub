# Dev VNC Server

🖥️ 通用开发用远程桌面服务 - 用于 SSH 远程连接时的 GUI 应用调试

## 功能特点

- 🚀 一键启动虚拟桌面环境
- 🌐 支持浏览器访问 (noVNC)
- 🔌 支持 VNC 客户端连接
- ⚙️ 可配置分辨率、端口、窗口管理器
- 🐍 提供 Python CLI 接口
- 📦 易于安装和管理

## 快速开始

### 安装

```bash
# 克隆项目
cd /home/henry/workspace/dev_app_vnc

# 运行安装脚本
./scripts/install.sh
```

### 使用

```bash
# 启动远程桌面
dev-vnc start

# 查看状态
dev-vnc status

# 查看访问信息
dev-vnc info

# 在 VNC 环境中运行程序
dev-vnc run python my_gui_app.py

# 停止服务
dev-vnc stop
```

## 访问方式

### 浏览器访问 (推荐)

启动服务后，打开浏览器访问：
- `http://localhost:6080/vnc.html`
- `http://<服务器IP>:6080/vnc.html`

### VNC 客户端

使用任意 VNC 客户端连接：
- 地址: `localhost:5999` 或 `<服务器IP>:5999`
- 密码: `devvnc123` (可配置)

## 配置

### 配置文件

配置文件位于 `~/.config/dev-vnc/config.env`：

```bash
# 显示器编号
DEV_VNC_DISPLAY=99

# VNC 端口
DEV_VNC_PORT=5999

# noVNC Web 端口
DEV_VNC_NOVNC_PORT=6080

# 分辨率
DEV_VNC_RESOLUTION=1920x1080x24

# VNC 密码
DEV_VNC_PASSWORD=devvnc123

# 窗口管理器 (fluxbox, openbox, i3)
DEV_VNC_WM=fluxbox
```

### 环境变量

也可以通过环境变量覆盖配置：

```bash
DEV_VNC_RESOLUTION=2560x1440x24 dev-vnc start
```

## 命令参考

| 命令 | 说明 |
|------|------|
| `dev-vnc start` | 启动远程桌面服务 |
| `dev-vnc stop` | 停止远程桌面服务 |
| `dev-vnc restart` | 重启服务 |
| `dev-vnc status` | 显示服务状态 |
| `dev-vnc info` | 显示访问信息 |
| `dev-vnc logs [type]` | 显示日志 (vnc/novnc/all) |
| `dev-vnc run <cmd>` | 在 VNC 环境中运行命令 |
| `dev-vnc config` | 显示当前配置 |
| `dev-vnc install-deps` | 安装系统依赖 |
| `dev-vnc help` | 显示帮助信息 |

## Python CLI

也可以使用 Python CLI：

```bash
# 安装
pip install -e .

# 使用
devvnc start
devvnc status
devvnc run python my_app.py
```

## 系统要求

### 支持的操作系统

- Ubuntu / Debian
- Fedora / CentOS / RHEL
- Arch Linux

### 依赖

- Xvfb
- x11vnc
- fluxbox (或其他窗口管理器)
- noVNC
- websockify
- Python 3.8+

## 典型使用场景

### 远程 GUI 开发

在 SSH 连接的远程服务器上调试 GUI 应用：

```bash
# SSH 连接到服务器
ssh user@server

# 启动远程桌面
dev-vnc start

# 在本地浏览器打开 http://server:6080/vnc.html

# 运行 GUI 应用
dev-vnc run python my_gui_app.py
```

### CI/CD 中的 GUI 测试

在无头环境中运行 GUI 测试：

```bash
# 启动虚拟桌面
dev-vnc start

# 运行 GUI 测试
dev-vnc run pytest tests/gui/
```

### 容器中的 GUI 应用

在 Docker 容器中运行 GUI 应用：

```dockerfile
FROM ubuntu:22.04

# 安装依赖
RUN apt-get update && apt-get install -y \
    xvfb x11vnc fluxbox novnc websockify

# 复制 dev-vnc
COPY . /app/dev-vnc
RUN /app/dev-vnc/scripts/install.sh

EXPOSE 5999 6080

CMD ["dev-vnc", "start"]
```

## 项目结构

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

## 故障排除

### 服务无法启动

1. 检查依赖是否安装：
   ```bash
   dev-vnc install-deps
   ```

2. 检查端口是否被占用：
   ```bash
   netstat -tlnp | grep -E '5999|6080'
   ```

3. 查看日志：
   ```bash
   dev-vnc logs
   ```

### 无法连接

1. 检查防火墙设置：
   ```bash
   sudo ufw allow 5999
   sudo ufw allow 6080
   ```

2. 确认服务正在运行：
   ```bash
   dev-vnc status
   ```

## License

MIT License

## 致谢

本项目基于 BNN-Pipeline 项目中的远程桌面功能开发。
