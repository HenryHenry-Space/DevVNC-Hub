"""
Dev VNC Server - 命令行接口 / Command-line interface
"""

import argparse
import sys
from typing import List, Optional

from . import __version__
from .server import DevVNCServer


def main(args: Optional[List[str]] = None) -> int:
    """主入口 / Entry point"""
    parser = argparse.ArgumentParser(
        prog="devvnc",
        description="Dev VNC Server - 通用开发用远程桌面服务",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  devvnc start                  # 启动服务
  devvnc stop                   # 停止服务
  devvnc status                 # 查看状态
  devvnc run python app.py      # 在 VNC 环境中运行命令

环境变量:
  DEV_VNC_DISPLAY      显示器编号 (默认: 99)
  DEV_VNC_PORT         VNC 端口 (默认: 5999)
  DEV_VNC_NOVNC_PORT   noVNC 端口 (默认: 6080)
  DEV_VNC_RESOLUTION   分辨率 (默认: 1920x1080x24)
  DEV_VNC_PASSWORD     VNC 密码 (默认: devvnc123)
  DEV_VNC_WM           窗口管理器 (默认: fluxbox)
"""
    )
    
    parser.add_argument(
        "--version", "-V",
        action="version",
        version=f"%(prog)s {__version__}"
    )
    
    subparsers = parser.add_subparsers(dest="command", help="可用命令")
    
    # start
    start_parser = subparsers.add_parser("start", help="启动远程桌面服务")
    
    # stop
    stop_parser = subparsers.add_parser("stop", help="停止远程桌面服务")
    
    # restart
    restart_parser = subparsers.add_parser("restart", help="重启远程桌面服务")
    
    # status
    status_parser = subparsers.add_parser("status", help="显示服务状态")
    
    # info
    info_parser = subparsers.add_parser("info", help="显示访问信息")
    
    # config
    config_parser = subparsers.add_parser("config", help="显示当前配置")
    
    # logs
    logs_parser = subparsers.add_parser("logs", help="显示日志")
    logs_parser.add_argument(
        "type",
        nargs="?",
        default="all",
        choices=["vnc", "novnc", "all"],
        help="日志类型"
    )
    
    # run
    run_parser = subparsers.add_parser("run", help="在 VNC 环境中运行命令")
    run_parser.add_argument("cmd", nargs=argparse.REMAINDER, help="要运行的命令")
    
    # 解析参数 / Parse arguments
    parsed = parser.parse_args(args)
    
    if not parsed.command:
        parser.print_help()
        return 0
    
    # 创建服务器实例 / Create server instance
    server = DevVNCServer()
    
    # 执行命令 / Execute command
    if parsed.command == "start":
        return 0 if server.start() else 1
    
    elif parsed.command == "stop":
        return 0 if server.stop() else 1
    
    elif parsed.command == "restart":
        return 0 if server.restart() else 1
    
    elif parsed.command == "status":
        server.show_status()
        server.show_info()
        return 0
    
    elif parsed.command == "info":
        server.show_info()
        return 0
    
    elif parsed.command == "config":
        server.show_config()
        return 0
    
    elif parsed.command == "logs":
        server.show_logs(parsed.type)
        return 0
    
    elif parsed.command == "run":
        if not parsed.cmd:
            print("❌ 请指定要运行的命令")
            return 1
        return server.run_command(parsed.cmd)
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
