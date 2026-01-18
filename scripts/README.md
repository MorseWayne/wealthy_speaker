# Wealthy Speaker 脚本工具

本目录包含用于管理 Wealthy Speaker 服务的脚本工具。

## 脚本列表

| 脚本 | 用途 |
|------|------|
| `common.sh` | 公共函数库（被其他脚本引用） |
| `install.sh` | 安装所有服务的依赖 |
| `start.sh` | 启动服务 |
| `stop.sh` | 停止服务 |
| `restart.sh` | 重启服务 |
| `status.sh` | 查看服务状态 |

## 快速开始

```bash
# 1. 安装依赖
./install.sh

# 2. 启动所有服务
./start.sh

# 3. 查看服务状态
./status.sh

# 4. 停止所有服务
./stop.sh
```

## 脚本详细说明

### install.sh - 依赖安装

安装所有服务需要的依赖包。

```bash
# 安装所有依赖
./install.sh

# 只安装特定组件
./install.sh collector    # Go 依赖
./install.sh analyzer     # Python 依赖
./install.sh web          # Node.js 依赖

# 只检查系统依赖
./install.sh check

# 自动确认所有提示
./install.sh -y

# 跳过系统依赖检查
./install.sh --skip-check
```

### start.sh - 启动服务

启动应用服务（会自动检查并启动 PostgreSQL 和 Redis）。

```bash
# 启动所有服务
./start.sh

# 只启动特定服务
./start.sh collector    # Data Collector
./start.sh analyzer     # AI Analyzer
./start.sh web          # Web 界面

# 强制启动（如果端口被占用则先停止）
./start.sh -f
./start.sh web -f
```

### stop.sh - 停止服务

停止运行中的服务。

```bash
# 停止所有服务
./stop.sh

# 只停止特定服务
./stop.sh collector
./stop.sh analyzer
./stop.sh web

# 强制停止（SIGKILL）
./stop.sh -9
./stop.sh web -9
```

### restart.sh - 重启服务

重启服务（先停止再启动）。

```bash
# 重启所有服务
./restart.sh

# 只重启特定服务
./restart.sh collector
./restart.sh analyzer
./restart.sh web

# 快速重启（减少等待时间）
./restart.sh -q
```

### status.sh - 查看状态

查看服务运行状态。

```bash
# 显示服务状态
./status.sh

# 显示详细信息（资源使用和日志）
./status.sh -v
./status.sh --verbose

# JSON 格式输出
./status.sh -j
./status.sh --json
```

## 服务端口

| 服务 | 端口 | 说明 |
|------|------|------|
| Data Collector | 8080 | Go 数据收集服务 |
| AI Analyzer | 8000 | Python AI 分析服务 |
| Web Interface | 3000 | Node.js Web 界面 |

## 日志文件

所有服务的日志都保存在项目根目录的 `logs/` 目录下：

```
logs/
├── collector.log    # Collector 服务日志
├── collector.pid    # Collector 进程 ID
├── analyzer.log     # Analyzer 服务日志
├── analyzer.pid     # Analyzer 进程 ID
├── web.log          # Web 服务日志
└── web.pid          # Web 进程 ID
```

## 环境变量

脚本会从项目根目录的 `.env` 文件读取环境变量。主要变量：

```bash
# 数据库配置
DB_HOST=localhost
DB_PORT=5432
DB_NAME=wealthy_speaker
DB_USER=wealthy_user
DB_PASSWORD=your_password

# Redis 配置
REDIS_HOST=localhost
REDIS_PORT=6379
```

## 常见问题

### 端口被占用

如果启动时提示端口被占用，可以使用 `-f` 参数强制启动：

```bash
./start.sh -f
```

或者先停止占用端口的进程：

```bash
./stop.sh
./start.sh
```

### 数据库连接失败

1. 确保 PostgreSQL 服务正在运行：
   ```bash
   sudo systemctl status postgresql
   ```

2. 确保数据库和用户已创建：
   ```bash
   sudo -u postgres psql
   CREATE DATABASE wealthy_speaker;
   CREATE USER wealthy_user WITH PASSWORD 'your_password';
   GRANT ALL PRIVILEGES ON DATABASE wealthy_speaker TO wealthy_user;
   ```

3. 检查 `.env` 文件中的数据库配置是否正确。

### Python 虚拟环境问题

如果 Python 依赖安装失败，可以尝试删除虚拟环境重新创建：

```bash
rm -rf analyzer/venv
./install.sh analyzer
```

### 查看服务日志

```bash
# 查看 Collector 日志
tail -f logs/collector.log

# 查看 Analyzer 日志
tail -f logs/analyzer.log

# 查看 Web 日志
tail -f logs/web.log

# 或使用 status.sh 的详细模式
./status.sh -v
```

## 脚本架构

所有脚本共享 `common.sh` 公共库，其中包含：

- 颜色输出定义
- 日志函数（`log_info`, `log_success`, `log_warning`, `log_error`）
- 服务端口配置
- 公共工具函数（端口检查、进程管理等）
- 环境变量加载函数

这种架构确保了代码复用和一致的用户体验。
