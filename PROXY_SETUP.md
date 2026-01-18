# Docker 代理配置指南

本文档说明如何为 Docker 构建配置代理。

## 方式 1：通过环境变量（推荐）

在 `.env` 文件中添加代理配置：

```bash
# 代理配置（如果需要）
HTTP_PROXY=http://your-proxy-server:port
HTTPS_PROXY=http://your-proxy-server:port
NO_PROXY=localhost,127.0.0.1
```

### 示例配置

```bash
# 使用本地代理
HTTP_PROXY=http://127.0.0.1:7890
HTTPS_PROXY=http://127.0.0.1:7890
NO_PROXY=localhost,127.0.0.1

# 或者使用公司代理
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=http://proxy.company.com:8080
NO_PROXY=localhost,127.0.0.1,*.company.com
```

配置完成后，直接运行构建命令即可：

```bash
docker compose build
```

## 方式 2：命令行传递代理

如果不想修改 `.env` 文件，可以在命令行中传递代理参数：

```bash
HTTP_PROXY=http://127.0.0.1:7890 \
HTTPS_PROXY=http://127.0.0.1:7890 \
NO_PROXY=localhost,127.0.0.1 \
docker compose build
```

## 方式 3：配置 Docker 守护进程代理（全局）

如果想让 Docker 守护进程本身使用代理，可以配置系统级代理：

### systemd 系统（Ubuntu/Debian/CentOS）

1. 创建 Docker 服务配置目录：

```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
```

1. 创建代理配置文件：

```bash
sudo nano /etc/systemd/system/docker.service.d/http-proxy.conf
```

1. 添加以下内容：

```ini
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:7890"
Environment="HTTPS_PROXY=http://127.0.0.1:7890"
Environment="NO_PROXY=localhost,127.0.0.1"
```

1. 重新加载配置并重启 Docker：

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

1. 验证配置：

```bash
sudo systemctl show --property=Environment docker
```

## 验证代理是否生效

构建时查看日志，应该能看到包下载速度明显提升：

```bash
docker compose build --progress=plain
```

## 常见代理软件端口

- **Clash**: 7890 (HTTP), 7891 (SOCKS5)
- **V2Ray**: 10809 (HTTP), 10808 (SOCKS5)
- **Shadowsocks**: 1080 (SOCKS5)

## 注意事项

1. **代理地址**: 确保代理服务正在运行且可访问
2. **NO_PROXY**: 添加内部服务地址到 NO_PROXY，避免内部通信走代理
3. **SOCKS 代理**: Docker 构建不支持 SOCKS5 代理，需要使用 HTTP 代理
4. **认证代理**: 如果代理需要认证，格式为 `http://username:password@proxy:port`

## 故障排查

### 代理连接失败

```bash
# 测试代理是否可用
curl -x http://127.0.0.1:7890 https://www.google.com

# 或者测试国内网站
curl -x http://127.0.0.1:7890 https://mirrors.tuna.tsinghua.edu.cn
```

### 查看 Docker 构建日志

```bash
docker compose build --progress=plain --no-cache collector
```

### 清理缓存重新构建

```bash
docker compose build --no-cache
```
