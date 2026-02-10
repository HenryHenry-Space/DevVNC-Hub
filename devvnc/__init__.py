"""
Dev VNC Server - 通用开发用远程桌面服务 / Remote desktop service for development
"""

__version__ = "1.0.0"
__author__ = "Henry"

from .server import DevVNCServer
from .config import DevVNCConfig

__all__ = ["DevVNCServer", "DevVNCConfig", "__version__"]
