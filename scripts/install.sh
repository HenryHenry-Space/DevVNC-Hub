#!/bin/bash
# ============================================================
# Dev VNC Server - 安装脚本 / Installation script
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 颜色输出 / Colored output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# 检测操作系统 / Detect operating system
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    echo "$OS"
}

# 安装系统依赖 / Install system dependencies
install_system_deps() {
    log_step "安装系统依赖... / Installing system dependencies..."
    
    OS=$(detect_os)
    
    case "$OS" in
        *Ubuntu*|*Debian*)
            log_info "检测到 Debian/Ubuntu 系统 / Detected Debian/Ubuntu"
            sudo apt update
            sudo apt install -y \
                xvfb \
                x11vnc \
                fluxbox \
                novnc \
                websockify \
                python3 \
                python3-pip \
                python3-venv
            ;;
        *Fedora*|*CentOS*|*Red\ Hat*)
            log_info "检测到 Red Hat 系列系统 / Detected Red Hat family"
            sudo dnf install -y \
                xorg-x11-server-Xvfb \
                x11vnc \
                fluxbox \
                novnc \
                python3-websockify \
                python3 \
                python3-pip
            ;;
        *Arch*)
            log_info "检测到 Arch Linux / Detected Arch Linux"
            sudo pacman -S --noconfirm \
                xorg-server-xvfb \
                x11vnc \
                fluxbox \
                novnc \
                python-websockify \
                python \
                python-pip
            ;;
        *)
            log_warn "未知操作系统: $OS / Unknown OS: $OS"
            log_warn "请手动安装以下依赖 / Please install dependencies manually:"
            echo "  - xvfb (Xvfb)"
            echo "  - x11vnc"
            echo "  - fluxbox (或其他窗口管理器) / fluxbox (or other window manager)"
            echo "  - novnc"
            echo "  - websockify"
            echo "  - python3"
            return 1
            ;;
    esac
    
    log_info "系统依赖安装完成 / System dependencies installed"
}

# 安装 Python 包 / Install Python package
install_python_package() {
    log_step "安装 Python 包... / Installing Python package..."
    
    cd "$PROJECT_DIR"
    
    # 使用 pip 安装 / Install with pip
    if command -v pip3 &> /dev/null; then
        pip3 install -e .
    elif command -v pip &> /dev/null; then
        pip install -e .
    else
    log_error "未找到 pip，请先安装 Python pip / pip not found, install pip first"
        return 1
    fi
    
    log_info "Python 包安装完成 / Python package installed"
}

# 创建配置目录 / Create configuration directory
setup_config() {
    log_step "设置配置目录... / Setting configuration directory..."
    
    CONFIG_DIR="$HOME/.config/dev-vnc"
    mkdir -p "$CONFIG_DIR"
    
    if [ ! -f "$CONFIG_DIR/config.env" ]; then
        cp "$PROJECT_DIR/config/config.env.example" "$CONFIG_DIR/config.env"
    log_info "已创建配置文件: $CONFIG_DIR/config.env / Config created"
    else
    log_info "配置文件已存在，跳过 / Config already exists, skipping"
    fi
    
    # 创建运行时目录 / Create runtime directories
    mkdir -p "$HOME/.dev-vnc/logs"
    mkdir -p "$HOME/.dev-vnc/run"
}

# 设置 VNC 密码 / Set VNC password
setup_vnc_password() {
    log_step "设置 VNC 密码... / Setting VNC password..."
    
    mkdir -p "$HOME/.vnc"
    
    if [ ! -f "$HOME/.vnc/passwd" ]; then
        if command -v x11vnc &> /dev/null; then
            echo "devvnc123" | x11vnc -storepasswd - "$HOME/.vnc/passwd"
            log_info "VNC 密码已设置 / VNC password set"
        else
            log_warn "x11vnc 未安装，跳过密码设置 / x11vnc not installed, skip password"
        fi
    else
    log_info "VNC 密码已存在，跳过 / VNC password exists, skipping"
    fi
}

# 安装命令行工具 / Install CLI tool
install_cli() {
    log_step "安装命令行工具... / Installing CLI tool..."
    
    # 创建符号链接 / Create symlink
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
    
    # 链接 shell 脚本 / Link shell script
    ln -sf "$PROJECT_DIR/scripts/dev-vnc-server.sh" "$INSTALL_DIR/dev-vnc"
    chmod +x "$PROJECT_DIR/scripts/dev-vnc-server.sh"
    
    log_info "命令行工具已安装到 $INSTALL_DIR/dev-vnc / CLI installed"
    
    # 检查 PATH / Check PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    log_warn "请将 $INSTALL_DIR 添加到 PATH / Add $INSTALL_DIR to PATH"
        echo ""
    echo "添加以下行到 ~/.bashrc 或 ~/.zshrc: / Add the following line to ~/.bashrc or ~/.zshrc:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi
}

# 完整安装 / Full install
full_install() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           🚀 Dev VNC Server 安装程序                         ║"
    echo "║           🚀 Dev VNC Server Installer                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    install_system_deps
    install_python_package
    setup_config
    setup_vnc_password
    install_cli
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           ✅ 安装完成！                                      ║"
    echo "║           ✅ Installation Complete!                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "使用方法 / Usage:"
    echo "  dev-vnc start     # 启动远程桌面 / Start remote desktop"
    echo "  dev-vnc stop      # 停止远程桌面 / Stop remote desktop"
    echo "  dev-vnc status    # 查看状态 / Show status"
    echo "  dev-vnc info      # 查看访问信息 / Show access info"
    echo ""
    echo "或使用 Python CLI / Or use Python CLI:"
    echo "  devvnc start"
    echo "  devvnc --help"
    echo ""
}

# 仅安装依赖 / Dependencies only
deps_only() {
    install_system_deps
}

# 卸载 / Uninstall
uninstall() {
    log_step "卸载 Dev VNC Server... / Uninstalling Dev VNC Server..."
    
    # 停止服务 / Stop service
    if command -v dev-vnc &> /dev/null; then
        dev-vnc stop 2>/dev/null || true
    fi
    
    # 删除命令行工具 / Remove CLI tool
    rm -f "$HOME/.local/bin/dev-vnc"
    
    # 卸载 Python 包 / Uninstall Python package
    pip3 uninstall -y dev-vnc 2>/dev/null || true
    pip uninstall -y dev-vnc 2>/dev/null || true
    
    log_info "卸载完成 / Uninstall complete"
    log_info "配置文件保留在 ~/.config/dev-vnc/ / Config kept at ~/.config/dev-vnc/"
}

# 显示帮助 / Show help
show_help() {
    echo "Dev VNC Server 安装脚本 / Dev VNC Server installer"
    echo ""
    echo "用法 / Usage: $0 [命令]"
    echo ""
    echo "命令 / Commands:"
    echo "  install       完整安装 (默认) / Full install (default)"
    echo "  deps          仅安装系统依赖 / Dependencies only"
    echo "  python        仅安装 Python 包 / Python package only"
    echo "  cli           仅安装命令行工具 / CLI only"
    echo "  uninstall     卸载 / Uninstall"
    echo "  help          显示此帮助 / Show help"
    echo ""
}

# 主命令处理 / Main command dispatch
case "${1:-install}" in
    install)
        full_install
        ;;
    deps)
        deps_only
        ;;
    python)
        install_python_package
        ;;
    cli)
        install_cli
        ;;
    uninstall)
        uninstall
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
    log_error "未知命令: $1 / Unknown command: $1"
        show_help
        exit 1
        ;;
esac
