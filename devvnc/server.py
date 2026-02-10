"""
Dev VNC Server - 服务器核心实现 / Core server implementation
"""

import os
import socket
import subprocess
import time
from pathlib import Path
from typing import Optional, List, Dict

from .config import DevVNCConfig


class DevVNCServer:
    """VNC 远程桌面服务器 / VNC remote desktop server"""
    
    def __init__(self, config: Optional[DevVNCConfig] = None):
        self.config = config or DevVNCConfig.from_env()
        self._processes: Dict[str, subprocess.Popen] = {}
    
    def is_running(self) -> bool:
        """检查服务是否正在运行 / Check whether the service is running"""
        if self.config.pid_file.exists():
            try:
                pid = int(self.config.pid_file.read_text().strip())
                # 检查进程是否存在 / Check whether the process exists
                os.kill(pid, 0)
                return True
            except (ProcessLookupError, ValueError):
                pass
        return False
    
    def get_status(self) -> Dict[str, bool]:
        """获取各组件状态 / Get component status"""
        status = {
            "xvfb": False,
            "x11vnc": False,
            "novnc": False,
            "window_manager": False,
        }
        
    # 检查 Xvfb / Check Xvfb
        status["xvfb"] = self._check_process(f"Xvfb :{self.config.display_num}")
        
    # 检查 x11vnc / Check x11vnc
        status["x11vnc"] = self._check_process(f"x11vnc.*:{self.config.display_num}")
        
    # 检查 websockify (noVNC) / Check websockify (noVNC)
        status["novnc"] = self._check_process(f"websockify.*{self.config.novnc_port}")
        
    # 检查窗口管理器 / Check window manager
        status["window_manager"] = self._check_process(self.config.window_manager)
        
        return status
    
    def _check_process(self, pattern: str) -> bool:
        """检查进程是否存在 / Check whether a process exists"""
        try:
            result = subprocess.run(
                ["pgrep", "-f", pattern],
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        except Exception:
            return False
    
    def _kill_process(self, pattern: str) -> None:
        """终止匹配的进程 / Terminate matching processes"""
        try:
            subprocess.run(
                ["pkill", "-f", pattern],
                capture_output=True
            )
        except Exception:
            pass
    
    def start(self) -> bool:
        """启动服务 / Start the service"""
        if self.is_running():
            print("⚠️  服务已在运行 / Service is already running")
            return True
        
        self.config.ensure_dirs()
        self._check_dependencies()
        self._setup_vnc_password()
        
        print("\n🚀 启动远程桌面服务... / Starting remote desktop service...\n")
        
        # 清理旧进程 / Clean up old processes
        self._cleanup()
        time.sleep(1)
        
        try:
            # 1. 启动 Xvfb / Start Xvfb
            print(f"📺 启动虚拟显示器 (Display :{self.config.display_num})... / Starting virtual display")
            self._start_xvfb()
            time.sleep(2)
            
            # 2. 启动窗口管理器 / Start window manager
            print(f"🪟 启动窗口管理器 ({self.config.window_manager})... / Starting window manager")
            self._start_window_manager()
            time.sleep(1)
            
            # 3. 启动 VNC / Start VNC
            print(f"🔌 启动 VNC 服务器 (端口 {self.config.vnc_port})... / Starting VNC server")
            self._start_vnc()
            time.sleep(1)
            
            # 4. 启动 noVNC / Start noVNC
            print(f"🌐 启动 noVNC Web 服务器 (端口 {self.config.novnc_port})... / Starting noVNC web server")
            self._start_novnc()
            time.sleep(1)
            
            # 保存 PID / Save PID
            self.config.pid_file.write_text(str(os.getpid()))
            
            print("\n✅ 远程桌面服务已成功启动！ / Remote desktop service started!")
            self.show_info()
            return True
            
        except Exception as e:
            print(f"\n❌ 启动失败: {e} / Start failed")
            self._cleanup()
            return False
    
    def stop(self) -> bool:
        """停止服务 / Stop the service"""
        print("\n🛑 停止远程桌面服务... / Stopping remote desktop service...")
        
        self._cleanup()
        
        # 清理 PID 文件 / Clean PID files
        for pid_file in self.config.run_dir.glob("*.pid"):
            pid_file.unlink(missing_ok=True)
        
        print("✅ 远程桌面服务已停止 / Remote desktop service stopped")
        return True
    
    def restart(self) -> bool:
        """重启服务 / Restart the service"""
        self.stop()
        time.sleep(2)
        return self.start()
    
    def _cleanup(self) -> None:
        """清理所有相关进程 / Clean all related processes"""
        self._kill_process(f"Xvfb :{self.config.display_num}")
        self._kill_process(f"x11vnc.*:{self.config.display_num}")
        self._kill_process(f"websockify.*{self.config.novnc_port}")
        self._kill_process(self.config.window_manager)
    
    def _check_dependencies(self) -> None:
        """检查依赖 / Check dependencies"""
        missing = []
        
        for cmd in ["Xvfb", "x11vnc", "websockify"]:
            if not self._command_exists(cmd):
                missing.append(cmd)
        
        if not self._command_exists(self.config.window_manager):
            missing.append(self.config.window_manager)
        
        if missing:
            raise RuntimeError(
                f"缺少依赖: {', '.join(missing)} / Missing dependencies\n"
                f"请运行: dev-vnc install-deps / Please run: dev-vnc install-deps"
            )
    
    def _command_exists(self, cmd: str) -> bool:
        """检查命令是否存在 / Check whether a command exists"""
        try:
            result = subprocess.run(
                ["which", cmd],
                capture_output=True
            )
            return result.returncode == 0
        except Exception:
            return False
    
    def _setup_vnc_password(self) -> None:
        """设置 VNC 密码 / Set VNC password"""
        passwd_file = Path.home() / ".vnc" / "passwd"
        
        if not passwd_file.exists():
            try:
                subprocess.run(
                    ["x11vnc", "-storepasswd", self.config.password, str(passwd_file)],
                    capture_output=True,
                    text=True,
                    input="y\n"
                )
            except Exception:
                pass
    
    def _start_xvfb(self) -> None:
        """启动 Xvfb / Start Xvfb"""
        cmd = [
            "Xvfb",
            f":{self.config.display_num}",
            "-screen", "0", self.config.resolution
        ]
        
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        self._processes["xvfb"] = proc
        self._save_pid("xvfb", proc.pid)
    
    def _start_window_manager(self) -> None:
        """启动窗口管理器 / Start window manager"""
        env = os.environ.copy()
        env["DISPLAY"] = self.config.display
        
        proc = subprocess.Popen(
            [self.config.window_manager],
            env=env,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        self._processes["wm"] = proc
        self._save_pid("wm", proc.pid)
    
    def _start_vnc(self) -> None:
        """启动 VNC 服务器 / Start VNC server"""
        passwd_file = Path.home() / ".vnc" / "passwd"
        log_file = self.config.log_dir / "x11vnc.log"
        
        cmd = [
            "x11vnc",
            "-display", self.config.display,
            "-forever",
            "-shared",
            "-rfbport", str(self.config.vnc_port),
            "-rfbauth", str(passwd_file),
            "-bg",
            "-o", str(log_file)
        ]
        
        subprocess.run(cmd, capture_output=True)
    
    def _start_novnc(self) -> None:
        """启动 noVNC / Start noVNC"""
    # 查找 noVNC 路径 / Find noVNC path
        novnc_paths = [
            "/usr/share/novnc",
            "/usr/share/javascript/novnc",
            "/usr/share/webapps/novnc",
        ]
        
        novnc_path = None
        for path in novnc_paths:
            if os.path.isdir(path):
                novnc_path = path
                break
        
        if not novnc_path:
            print("⚠️  noVNC 未找到，仅提供 VNC 连接 / noVNC not found, VNC only")
            return
        
        log_file = self.config.log_dir / "websockify.log"
        
        with open(log_file, "w") as f:
            proc = subprocess.Popen(
                [
                    "websockify",
                    f"--web={novnc_path}",
                    str(self.config.novnc_port),
                    f"localhost:{self.config.vnc_port}"
                ],
                stdout=f,
                stderr=f
            )
            self._processes["novnc"] = proc
            self._save_pid("novnc", proc.pid)
    
    def _save_pid(self, name: str, pid: int) -> None:
        """保存 PID / Save PID"""
        pid_file = self.config.run_dir / f"{name}.pid"
        pid_file.write_text(str(pid))
    
    def get_local_ip(self) -> str:
        """获取本机 IP 地址 / Get local IP address"""
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except Exception:
            return "localhost"
    
    def show_info(self) -> None:
        """显示访问信息 / Show access information"""
        local_ip = self.get_local_ip()
        
        print("""
╔══════════════════════════════════════════════════════════════╗
║                 🖥️  远程桌面访问信息                         ║
║                 🖥️  Remote Desktop Access                    ║
╚══════════════════════════════════════════════════════════════╝
""")
        print("  📍 浏览器访问 (推荐) / Browser access (recommended):")
        print(f"     http://{local_ip}:{self.config.novnc_port}/vnc.html")
        print(f"     http://localhost:{self.config.novnc_port}/vnc.html (本机 / local)")
        print()
        print("  🔌 VNC 客户端连接 / VNC client:")
        print(f"     地址 / Address: {local_ip}:{self.config.vnc_port}")
        print(f"     密码 / Password: {self.config.password}")
        print()
        print("  🚀 在远程桌面中运行 GUI 程序 / Run GUI apps in remote desktop:")
        print(f"     export DISPLAY={self.config.display}")
        print("     your-gui-application")
        print()
        print("  💡 快捷命令 / Quick command:")
        print("     devvnc run <command>")
        print()
    
    def show_status(self) -> None:
        """显示状态 / Show status"""
        status = self.get_status()
        
        print("""
╔══════════════════════════════════════════════════════════════╗
║                    📊 服务状态                              ║
║                    📊 Service Status                         ║
╚══════════════════════════════════════════════════════════════╝
""")
        
        def status_icon(running: bool) -> str:
            return "✅ 运行中 / Running" if running else "❌ 未运行 / Stopped"
        
        print(f"  Xvfb:           {status_icon(status['xvfb'])}")
        print(f"  x11vnc:         {status_icon(status['x11vnc'])}")
        print(f"  noVNC:          {status_icon(status['novnc'])}")
        print(f"  {self.config.window_manager}:       {status_icon(status['window_manager'])}")
        print()
    
    def show_config(self) -> None:
        """显示配置 / Show configuration"""
        print("""
╔══════════════════════════════════════════════════════════════╗
║                    ⚙️  当前配置                              ║
║                    ⚙️  Current Configuration                  ║
╚══════════════════════════════════════════════════════════════╝
""")
        for key, value in self.config.to_dict().items():
            print(f"  {key}: {value}")
        print()
    
    def show_logs(self, log_type: str = "all") -> None:
        """显示日志 / Show logs"""
        if log_type in ("vnc", "all"):
            vnc_log = self.config.log_dir / "x11vnc.log"
            if vnc_log.exists():
                print("=== VNC 日志 / VNC Logs ===")
                print(vnc_log.read_text()[-5000:])  # 最后 5000 字符 / Last 5000 chars
        
        if log_type in ("novnc", "all"):
            novnc_log = self.config.log_dir / "websockify.log"
            if novnc_log.exists():
                print("\n=== noVNC 日志 / noVNC Logs ===")
                print(novnc_log.read_text()[-5000:])
    
    def run_command(self, command: List[str]) -> int:
        """在 VNC 环境中运行命令 / Run command in VNC environment"""
        if not self.is_running():
            print("❌ 服务未运行，请先执行: devvnc start / Service not running, run: devvnc start")
            return 1
        
        env = os.environ.copy()
        env["DISPLAY"] = self.config.display
        
        result = subprocess.run(command, env=env)
        return result.returncode
