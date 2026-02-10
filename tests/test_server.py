"""
Dev VNC Server 测试 / Tests
"""

import os
import sys
from unittest.mock import patch, MagicMock

import pytest

# 添加项目路径 / Add project path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from devvnc.config import DevVNCConfig
from devvnc.server import DevVNCServer


class TestDevVNCConfig:
    """测试配置类 / Test config"""
    
    def test_default_config(self):
        """测试默认配置 / Test default config"""
        config = DevVNCConfig()
        
        assert config.display_num == 99
        assert config.vnc_port == 5999
        assert config.novnc_port == 6080
        assert config.resolution == "1920x1080x24"
        assert config.password == "devvnc123"
        assert config.window_manager == "fluxbox"
    
    def test_display_property(self):
        """测试 display 属性 / Test display property"""
        config = DevVNCConfig(display_num=42)
        assert config.display == ":42"
    
    def test_from_env(self):
        """测试从环境变量加载 / Test loading from env"""
        with patch.dict(os.environ, {
            "DEV_VNC_DISPLAY": "50",
            "DEV_VNC_PORT": "5950",
            "DEV_VNC_RESOLUTION": "2560x1440x24",
        }):
            config = DevVNCConfig.from_env()
            
            assert config.display_num == 50
            assert config.vnc_port == 5950
            assert config.resolution == "2560x1440x24"
    
    def test_to_dict(self):
        """测试转换为字典 / Test to_dict"""
        config = DevVNCConfig()
        d = config.to_dict()
        
        assert "display_num" in d
        assert "vnc_port" in d
        assert "resolution" in d


class TestDevVNCServer:
    """测试服务器类 / Test server"""
    
    def test_init(self):
        """测试初始化 / Test initialization"""
        server = DevVNCServer()
        assert server.config is not None
    
    def test_custom_config(self):
        """测试自定义配置 / Test custom config"""
        config = DevVNCConfig(vnc_port=6000)
        server = DevVNCServer(config=config)
        
        assert server.config.vnc_port == 6000
    
    @patch("devvnc.server.subprocess.run")
    def test_check_process(self, mock_run):
        """测试进程检查 / Test process check"""
        mock_run.return_value = MagicMock(returncode=0)
        
        server = DevVNCServer()
        result = server._check_process("test")
        
        assert result is True
        mock_run.assert_called_once()
    
    def test_get_status(self):
        """测试获取状态 / Test status retrieval"""
        server = DevVNCServer()
        status = server.get_status()
        
        assert "xvfb" in status
        assert "x11vnc" in status
        assert "novnc" in status
        assert "window_manager" in status
    
    def test_get_local_ip(self):
        """测试获取本地 IP / Test local IP"""
        server = DevVNCServer()
        ip = server.get_local_ip()
        
        assert ip is not None


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
