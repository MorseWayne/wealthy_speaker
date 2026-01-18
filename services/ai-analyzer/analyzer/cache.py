"""Redis 缓存模块"""
import json
import hashlib
from typing import Optional, Any
from functools import wraps
import os

try:
    import redis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False


class CacheManager:
    """缓存管理器"""
    
    def __init__(self, redis_url: Optional[str] = None):
        """初始化缓存管理器"""
        self.redis_url = redis_url or os.getenv("REDIS_URL", "redis://localhost:6379/0")
        self._client: Optional[Any] = None
        self._connected = False
        
    @property
    def client(self):
        """获取 Redis 客户端（懒加载）"""
        if not REDIS_AVAILABLE:
            return None
            
        if self._client is None:
            try:
                self._client = redis.from_url(
                    self.redis_url,
                    decode_responses=True,
                    socket_connect_timeout=5,
                    socket_timeout=5
                )
                # 测试连接
                self._client.ping()
                self._connected = True
            except Exception as e:
                print(f"Redis connection failed: {e}")
                self._client = None
                self._connected = False
                
        return self._client
    
    @property
    def is_connected(self) -> bool:
        """检查是否已连接"""
        if self.client is None:
            return False
        try:
            self.client.ping()
            return True
        except Exception:
            self._connected = False
            return False
    
    def _generate_key(self, prefix: str, data: Any) -> str:
        """生成缓存键"""
        data_str = json.dumps(data, sort_keys=True, default=str)
        hash_value = hashlib.md5(data_str.encode()).hexdigest()[:16]
        return f"financial:{prefix}:{hash_value}"
    
    def get(self, key: str) -> Optional[Any]:
        """获取缓存值"""
        if not self.is_connected:
            return None
        try:
            value = self.client.get(key)
            if value:
                return json.loads(value)
        except Exception as e:
            print(f"Cache get error: {e}")
        return None
    
    def set(self, key: str, value: Any, ttl: int = 3600) -> bool:
        """设置缓存值"""
        if not self.is_connected:
            return False
        try:
            self.client.setex(key, ttl, json.dumps(value, default=str))
            return True
        except Exception as e:
            print(f"Cache set error: {e}")
            return False
    
    def delete(self, key: str) -> bool:
        """删除缓存值"""
        if not self.is_connected:
            return False
        try:
            self.client.delete(key)
            return True
        except Exception as e:
            print(f"Cache delete error: {e}")
            return False
    
    def get_sentiment_cache(self, news_list: list) -> Optional[dict]:
        """获取情感分析缓存"""
        key = self._generate_key("sentiment", news_list)
        return self.get(key)
    
    def set_sentiment_cache(self, news_list: list, result: dict, ttl: int = 1800) -> bool:
        """设置情感分析缓存（默认30分钟）"""
        key = self._generate_key("sentiment", news_list)
        return self.set(key, result, ttl)
    
    def get_advice_cache(self, stock_data: list, sentiment_result: dict) -> Optional[dict]:
        """获取投资建议缓存"""
        cache_data = {"stocks": stock_data, "sentiment": sentiment_result}
        key = self._generate_key("advice", cache_data)
        return self.get(key)
    
    def set_advice_cache(self, stock_data: list, sentiment_result: dict, result: dict, ttl: int = 900) -> bool:
        """设置投资建议缓存（默认15分钟）"""
        cache_data = {"stocks": stock_data, "sentiment": sentiment_result}
        key = self._generate_key("advice", cache_data)
        return self.set(key, result, ttl)


# 全局缓存管理器实例
cache_manager = CacheManager()


def cached(prefix: str, ttl: int = 3600):
    """缓存装饰器"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # 生成缓存键
            cache_data = {"args": args[1:], "kwargs": kwargs}  # 跳过 self
            key = cache_manager._generate_key(prefix, cache_data)
            
            # 尝试获取缓存
            cached_result = cache_manager.get(key)
            if cached_result is not None:
                return cached_result
            
            # 执行函数
            result = func(*args, **kwargs)
            
            # 缓存结果
            if result is not None:
                cache_manager.set(key, result, ttl)
            
            return result
        return wrapper
    return decorator
