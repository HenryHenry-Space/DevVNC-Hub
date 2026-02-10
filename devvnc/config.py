"""
Dev VNC Server 配置管理 / Configuration management
"""

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


@dataclass
class DevVNCConfig:
    """VNC 服务器配置 / VNC server configuration"""
    
    # 显示器配置 / Display settings
    display_num: int = 99
    vnc_port: int = 5999
    novnc_port: int = 6080
    resolution: str = "1920x1080x24"
    
    # 认证 / Authentication
    password: str = "devvnc123"
    
    # 窗口管理器 / Window manager
    window_manager: str = "fluxbox"
    
    # 目录 / Directories
    log_dir: Path = field(default_factory=lambda: Path.home() / ".dev-vnc" / "logs")
    run_dir: Path = field(default_factory=lambda: Path.home() / ".dev-vnc" / "run")
    config_dir: Path = field(default_factory=lambda: Path.home() / ".config" / "dev-vnc")
    
    @classmethod
    def from_env(cls) -> "DevVNCConfig":
        """从环境变量加载配置 / Load config from environment"""
        config = cls()
        
    # 先尝试加载配置文件 / Try loading config file first
        config_file = os.environ.get(
            "DEV_VNC_CONFIG",
            str(Path.home() / ".config" / "dev-vnc" / "config.env")
        )
        
        if os.path.exists(config_file):
            config._load_env_file(config_file)
        
    # 环境变量覆盖 / Override with environment variables
        config.display_num = int(os.environ.get("DEV_VNC_DISPLAY", config.display_num))
        config.vnc_port = int(os.environ.get("DEV_VNC_PORT", config.vnc_port))
        config.novnc_port = int(os.environ.get("DEV_VNC_NOVNC_PORT", config.novnc_port))
        config.resolution = os.environ.get("DEV_VNC_RESOLUTION", config.resolution)
        config.password = os.environ.get("DEV_VNC_PASSWORD", config.password)
        config.window_manager = os.environ.get("DEV_VNC_WM", config.window_manager)
        
        if log_dir := os.environ.get("DEV_VNC_LOG_DIR"):
            config.log_dir = Path(log_dir)
        if run_dir := os.environ.get("DEV_VNC_RUN_DIR"):
            config.run_dir = Path(run_dir)
            
        return config
    
    def _load_env_file(self, filepath: str) -> None:
        """加载 .env 文件 / Load .env file"""
        try:
            with open(filepath, "r") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        key, value = line.split("=", 1)
                        key = key.strip()
                        value = value.strip().strip('"').strip("'")
                        
                        # 展开 $HOME / Expand $HOME
                        value = value.replace("$HOME", str(Path.home()))
                        
                        if key == "DEV_VNC_DISPLAY":
                            self.display_num = int(value)
                        elif key == "DEV_VNC_PORT":
                            self.vnc_port = int(value)
                        elif key == "DEV_VNC_NOVNC_PORT":
                            self.novnc_port = int(value)
                        elif key == "DEV_VNC_RESOLUTION":
                            self.resolution = value
                        elif key == "DEV_VNC_PASSWORD":
                            self.password = value
                        elif key == "DEV_VNC_WM":
                            self.window_manager = value
                        elif key == "DEV_VNC_LOG_DIR":
                            self.log_dir = Path(value)
                        elif key == "DEV_VNC_RUN_DIR":
                            self.run_dir = Path(value)
        except Exception:
            pass  # 忽略解析错误 / Ignore parse errors
    
    @property
    def display(self) -> str:
        """返回 DISPLAY 环境变量值 / Return DISPLAY env value"""
        return f":{self.display_num}"
    
    @property
    def pid_file(self) -> Path:
        """PID 文件路径 / PID file path"""
        return self.run_dir / "server.pid"
    
    def ensure_dirs(self) -> None:
        """确保所有目录存在 / Ensure directories exist"""
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.run_dir.mkdir(parents=True, exist_ok=True)
        self.config_dir.mkdir(parents=True, exist_ok=True)
        
    # VNC 目录 / VNC directory
        vnc_dir = Path.home() / ".vnc"
        vnc_dir.mkdir(exist_ok=True)
    
    def to_dict(self) -> dict:
        """转换为字典 / Convert to dict"""
        return {
            "display_num": self.display_num,
            "vnc_port": self.vnc_port,
            "novnc_port": self.novnc_port,
            "resolution": self.resolution,
            "password": self.password,
            "window_manager": self.window_manager,
            "log_dir": str(self.log_dir),
            "run_dir": str(self.run_dir),
            "config_dir": str(self.config_dir),
        }
