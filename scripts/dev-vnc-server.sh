#!/bin/bash
# ============================================================
# Dev VNC Server - 通用开发用远程桌面服务 / Remote desktop service for development
# 用于 SSH 远程连接时的 GUI 应用调试 / Debug GUI apps over SSH
# ============================================================

set -e

# 加载配置文件 (如果存在) / Load config file (if present)
CONFIG_FILE="${DEV_VNC_CONFIG:-$HOME/.config/dev-vnc/config.env}"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# 默认配置 / Default settings
DISPLAY_NUM="${DEV_VNC_DISPLAY:-99}"
VNC_PORT="${DEV_VNC_PORT:-5999}"
NOVNC_PORT="${DEV_VNC_NOVNC_PORT:-6080}"
RESOLUTION="${DEV_VNC_RESOLUTION:-1920x1080x24}"
VNC_PASSWORD="${DEV_VNC_PASSWORD:-devvnc123}"
WINDOW_MANAGER="${DEV_VNC_WM:-fluxbox}"

# 工作目录 / Working directories
LOG_DIR="${DEV_VNC_LOG_DIR:-$HOME/.dev-vnc/logs}"
RUN_DIR="${DEV_VNC_RUN_DIR:-$HOME/.dev-vnc/run}"
PID_FILE="$RUN_DIR/server.pid"

# 颜色输出 / Colored output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# 初始化目录 / Initialize directories
init_dirs() {
    mkdir -p "$LOG_DIR"
    mkdir -p "$RUN_DIR"
    mkdir -p "$HOME/.vnc"
}

# 设置 VNC 密码 / Set VNC password
setup_vnc_password() {
    if [ ! -f "$HOME/.vnc/passwd" ]; then
        log_step "设置 VNC 密码..."
    # 使用 x11vnc 的 storepasswd 或手动创建 / Use x11vnc storepasswd or create manually
        if command -v x11vnc &> /dev/null; then
            echo "$VNC_PASSWORD" | x11vnc -storepasswd - "$HOME/.vnc/passwd"
        else
            log_warn "x11vnc 未安装，无法设置密码"
        fi
    fi
}

# 检查依赖 / Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v Xvfb &> /dev/null; then
        missing_deps+=("xvfb")
    fi
    
    if ! command -v x11vnc &> /dev/null; then
        missing_deps+=("x11vnc")
    fi
    
    if ! command -v websockify &> /dev/null; then
        missing_deps+=("websockify")
    fi
    
    case "$WINDOW_MANAGER" in
        fluxbox)
            if ! command -v fluxbox &> /dev/null; then
                missing_deps+=("fluxbox")
            fi
            ;;
        openbox)
            if ! command -v openbox &> /dev/null; then
                missing_deps+=("openbox")
            fi
            ;;
        i3)
            if ! command -v i3 &> /dev/null; then
                missing_deps+=("i3")
            fi
            ;;
    esac
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少依赖: ${missing_deps[*]}"
        echo ""
        echo "请运行以下命令安装依赖:"
        echo "  sudo apt install ${missing_deps[*]}"
        echo ""
        echo "或运行安装脚本:"
        echo "  dev-vnc install-deps"
        exit 1
    fi
}

# 检查是否已经在运行 / Check if already running
check_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$pid" ] && ps -p "$pid" > /dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# 获取进程 PID / Get process PID
get_pid() {
    local name=$1
    local pid_file="$RUN_DIR/${name}.pid"
    if [ -f "$pid_file" ]; then
        cat "$pid_file" 2>/dev/null
    fi
}

# 保存进程 PID / Save process PID
save_pid() {
    local name=$1
    local pid=$2
    echo "$pid" > "$RUN_DIR/${name}.pid"
}

# 启动服务 / Start service
start_desktop() {
    if check_running; then
        log_warn "桌面服务已在运行"
        show_status
        return 0
    fi
    
    init_dirs
    check_dependencies
    setup_vnc_password
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              🚀 Dev VNC Server 启动中...                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # 清理旧进程 / Clean old processes
    cleanup_processes
    sleep 1
    
    # 1. 启动虚拟显示器 / Start virtual display
    log_step "启动虚拟显示器 (Display :$DISPLAY_NUM, 分辨率 $RESOLUTION)..."
    Xvfb :$DISPLAY_NUM -screen 0 $RESOLUTION &
    save_pid "xvfb" $!
    sleep 2
    
    # 设置 DISPLAY 环境变量 / Set DISPLAY environment variable
    export DISPLAY=:$DISPLAY_NUM
    
    # 2. 启动窗口管理器 / Start window manager
    log_step "启动窗口管理器 ($WINDOW_MANAGER)..."
    case "$WINDOW_MANAGER" in
        fluxbox)
            fluxbox &
            ;;
        openbox)
            openbox &
            ;;
        i3)
            i3 &
            ;;
        *)
            fluxbox &
            ;;
    esac
    save_pid "wm" $!
    sleep 1
    
    # 3. 启动 VNC 服务器 / Start VNC server
    log_step "启动 VNC 服务器 (端口 $VNC_PORT)..."
    x11vnc -display :$DISPLAY_NUM \
           -forever \
           -shared \
           -rfbport $VNC_PORT \
           -rfbauth ~/.vnc/passwd \
           -bg \
           -o "$LOG_DIR/x11vnc.log"
    sleep 1
    
    # 4. 启动 noVNC (Web 访问) / Start noVNC (web access)
    log_step "启动 noVNC Web 服务器 (端口 $NOVNC_PORT)..."
    
    # 查找 novnc 路径 / Find novnc path
    NOVNC_PATH=""
    for path in "/usr/share/novnc" "/usr/share/javascript/novnc" "/usr/share/webapps/novnc"; do
        if [ -d "$path" ]; then
            NOVNC_PATH="$path"
            break
        fi
    done
    
    if [ -n "$NOVNC_PATH" ]; then
        websockify --web="$NOVNC_PATH" $NOVNC_PORT localhost:$VNC_PORT > "$LOG_DIR/websockify.log" 2>&1 &
        save_pid "novnc" $!
        log_info "noVNC 已启动"
    else
        log_warn "noVNC 未找到，仅提供 VNC 连接"
    fi
    
    # 保存主 PID / Save main PID
    echo $$ > "$PID_FILE"
    
    sleep 2
    echo ""
    log_info "远程桌面服务已成功启动！"
    show_access_info
}

# 停止服务 / Stop service
stop_desktop() {
    echo ""
    log_step "停止远程桌面服务..."
    
    cleanup_processes
    
    # 清理 PID 文件 / Clean PID files
    rm -f "$RUN_DIR"/*.pid
    
    log_info "远程桌面服务已停止"
}

# 清理进程 / Clean processes
cleanup_processes() {
    pkill -f "Xvfb :$DISPLAY_NUM" 2>/dev/null || true
    pkill -f "x11vnc.*:$DISPLAY_NUM" 2>/dev/null || true
    pkill -f "websockify.*$NOVNC_PORT" 2>/dev/null || true
    pkill -f "fluxbox" 2>/dev/null || true
    pkill -f "openbox" 2>/dev/null || true
}

# 显示状态 / Show status
show_status() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    📊 服务状态                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    local all_running=true
    
    if pgrep -f "Xvfb :$DISPLAY_NUM" > /dev/null; then
        echo -e "  Xvfb:          ${GREEN}✅ 运行中${NC}"
    else
        echo -e "  Xvfb:          ${RED}❌ 未运行${NC}"
        all_running=false
    fi
    
    if pgrep -f "x11vnc.*:$DISPLAY_NUM" > /dev/null; then
        echo -e "  x11vnc:        ${GREEN}✅ 运行中${NC}"
    else
        echo -e "  x11vnc:        ${RED}❌ 未运行${NC}"
        all_running=false
    fi
    
    if pgrep -f "websockify.*$NOVNC_PORT" > /dev/null; then
        echo -e "  noVNC:         ${GREEN}✅ 运行中${NC}"
    else
        echo -e "  noVNC:         ${YELLOW}⚠️ 未运行${NC}"
    fi
    
    if pgrep -f "$WINDOW_MANAGER" > /dev/null; then
        echo -e "  $WINDOW_MANAGER:       ${GREEN}✅ 运行中${NC}"
    else
        echo -e "  $WINDOW_MANAGER:       ${YELLOW}⚠️ 未运行${NC}"
    fi
    
    echo ""
    
    if $all_running; then
        return 0
    else
        return 1
    fi
}

# 显示访问信息 / Show access info
show_access_info() {
    # 获取本机 IP 地址 / Get local IP address
    LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 🖥️  远程桌面访问信息                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "  ${CYAN}📍 浏览器访问 (推荐):${NC}"
    echo "     http://$LOCAL_IP:$NOVNC_PORT/vnc.html"
    echo "     http://localhost:$NOVNC_PORT/vnc.html (本机)"
    echo ""
    echo -e "  ${CYAN}🔌 VNC 客户端连接:${NC}"
    echo "     地址: $LOCAL_IP:$VNC_PORT"
    echo "     密码: $VNC_PASSWORD"
    echo ""
    echo -e "  ${CYAN}🚀 在远程桌面中运行 GUI 程序:${NC}"
    echo "     export DISPLAY=:$DISPLAY_NUM"
    echo "     your-gui-application"
    echo ""
    echo -e "  ${CYAN}💡 快捷命令:${NC}"
    echo "     dev-vnc run <command>  # 在 VNC 环境中运行命令"
    echo ""
}

# 在 VNC 环境中运行命令 / Run command in VNC environment
run_in_vnc() {
    if ! check_running; then
        log_error "桌面服务未运行，请先执行: dev-vnc start"
        exit 1
    fi
    
    export DISPLAY=:$DISPLAY_NUM
    "$@"
}

# 显示日志 / Show logs
show_logs() {
    local log_type="${1:-all}"
    
    case "$log_type" in
        vnc)
            if [ -f "$LOG_DIR/x11vnc.log" ]; then
                cat "$LOG_DIR/x11vnc.log"
            else
                log_warn "VNC 日志文件不存在"
            fi
            ;;
        novnc)
            if [ -f "$LOG_DIR/websockify.log" ]; then
                cat "$LOG_DIR/websockify.log"
            else
                log_warn "noVNC 日志文件不存在"
            fi
            ;;
        all)
            echo "=== VNC 日志 ==="
            [ -f "$LOG_DIR/x11vnc.log" ] && tail -n 20 "$LOG_DIR/x11vnc.log"
            echo ""
            echo "=== noVNC 日志 ==="
            [ -f "$LOG_DIR/websockify.log" ] && tail -n 20 "$LOG_DIR/websockify.log"
            ;;
        *)
            log_error "未知日志类型: $log_type"
            echo "可用: vnc, novnc, all"
            ;;
    esac
}

# 显示帮助 / Show help
show_help() {
    echo ""
    echo "Dev VNC Server - 通用开发用远程桌面服务"
    echo ""
    echo "用法: dev-vnc <命令> [选项]"
    echo ""
    echo "命令:"
    echo "  start           启动远程桌面服务"
    echo "  stop            停止远程桌面服务"
    echo "  restart         重启远程桌面服务"
    echo "  status          显示服务状态"
    echo "  info            显示访问信息"
    echo "  logs [type]     显示日志 (vnc/novnc/all)"
    echo "  run <cmd>       在 VNC 环境中运行命令"
    echo "  install-deps    安装依赖"
    echo "  config          显示当前配置"
    echo "  help            显示此帮助信息"
    echo ""
    echo "环境变量:"
    echo "  DEV_VNC_DISPLAY        显示器编号 (默认: 99)"
    echo "  DEV_VNC_PORT           VNC 端口 (默认: 5999)"
    echo "  DEV_VNC_NOVNC_PORT     noVNC 端口 (默认: 6080)"
    echo "  DEV_VNC_RESOLUTION     分辨率 (默认: 1920x1080x24)"
    echo "  DEV_VNC_PASSWORD       VNC 密码 (默认: devvnc123)"
    echo "  DEV_VNC_WM             窗口管理器 (默认: fluxbox)"
    echo "  DEV_VNC_CONFIG         配置文件路径"
    echo ""
    echo "示例:"
    echo "  dev-vnc start"
    echo "  dev-vnc run python my_gui_app.py"
    echo "  DEV_VNC_RESOLUTION=2560x1440x24 dev-vnc restart"
    echo ""
}

# 显示配置 / Show configuration
show_config() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    ⚙️  当前配置                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Display:        :$DISPLAY_NUM"
    echo "  VNC Port:       $VNC_PORT"
    echo "  noVNC Port:     $NOVNC_PORT"
    echo "  Resolution:     $RESOLUTION"
    echo "  Window Manager: $WINDOW_MANAGER"
    echo "  Log Dir:        $LOG_DIR"
    echo "  Run Dir:        $RUN_DIR"
    echo "  Config File:    $CONFIG_FILE"
    echo ""
}

# 安装依赖 / Install dependencies
install_deps() {
    log_step "安装依赖..."
    
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y xvfb x11vnc fluxbox novnc websockify
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y xorg-x11-server-Xvfb x11vnc fluxbox novnc python3-websockify
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm xorg-server-xvfb x11vnc fluxbox novnc python-websockify
    else
        log_error "不支持的包管理器，请手动安装依赖"
        exit 1
    fi
    
    log_info "依赖安装完成"
}

# 主命令处理 / Main command dispatch
case "${1:-help}" in
    start)
        start_desktop
        ;;
    stop)
        stop_desktop
        ;;
    restart)
        stop_desktop
        sleep 2
        start_desktop
        ;;
    status)
        show_status
        ;;
    info)
        show_access_info
        ;;
    logs)
        show_logs "${2:-all}"
        ;;
    run)
        shift
        run_in_vnc "$@"
        ;;
    install-deps)
        install_deps
        ;;
    config)
        show_config
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "未知命令: $1"
        show_help
        exit 1
        ;;
esac
