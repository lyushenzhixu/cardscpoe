"""
CardScope 数据管道配置
从环境变量或 .env 文件加载 API Keys
"""
import os
from dataclasses import dataclass
from pathlib import Path

# 尝试加载 dotenv
try:
    from dotenv import load_dotenv
    env_path = Path(__file__).parent / ".env"
    load_dotenv(env_path)
except ImportError:
    pass


def get_env(key: str, default: str = "") -> str:
    return os.environ.get(key, default).strip()


@dataclass
class Config:
    supabase_url: str
    supabase_service_role_key: str
    balldontlie_key: str
    sportsdb_key: str
    pricecharting_key: str


_config: Config | None = None


def get_config() -> Config:
    global _config
    if _config is None:
        _config = Config(
            supabase_url=get_env("SUPABASE_URL"),
            supabase_service_role_key=get_env("SUPABASE_SERVICE_ROLE_KEY"),
            balldontlie_key=get_env("BALLDONTLIE_API_KEY"),
            sportsdb_key=get_env("SPORTSDB_API_KEY", "1"),
            pricecharting_key=get_env("PRICECHARTING_API_KEY"),
        )
    return _config


# 兼容直接导入
SUPABASE_URL = get_env("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = get_env("SUPABASE_SERVICE_ROLE_KEY")
BALLDONTLIE_API_KEY = get_env("BALLDONTLIE_API_KEY")
SPORTSDB_API_KEY = get_env("SPORTSDB_API_KEY", "1")
PRICECHARTING_API_KEY = get_env("PRICECHARTING_API_KEY")

# 限流
BALLDONTLIE_RPM = 30
SPORTSDB_DELAY_SEC = 0.5
PRICECHARTING_DELAY_SEC = 1.1
