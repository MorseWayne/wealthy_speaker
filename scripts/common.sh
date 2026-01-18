#!/bin/bash

# Wealthy Speaker - 公共函数库
# 所有脚本共享的函数和变量

# ============================================================
# 颜色定义
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ============================================================
# 路径定义
# ============================================================
# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
# 项目根目录（scripts 的父目录）
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
# 日志目录
LOG_DIR="$PROJECT_ROOT/logs"

# ============================================================
# 服务配置
# ============================================================
declare -A SERVICE_PORTS=(
    ["collector"]=8080
    ["analyzer"]=8000
    ["web"]=3000
)

declare -A SERVICE_NAMES=(
    ["collector"]="Data Collector"
    ["analyzer"]="AI Analyzer"
    ["web"]="Web Interface"
)

declare -A SERVICE_HEALTH_URLS=(
    ["collector"]="http://localhost:8080/health"
    ["analyzer"]="http://localhost:8000/health"
    ["web"]="http://localhost:3000/health"
)

# ============================================================
# 日志函数
# ============================================================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_check_ok() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_check_fail() {
    echo -e "${RED}[✗]${NC} $1"
}

# 打印分隔线
print_header() {
    echo ""
    log_info "========================================"
    log_info "  $1"
    log_info "========================================"
    echo ""
}

print_section() {
    echo ""
    log_info "=========================================="
    log_info "  $1"
    log_info "=========================================="
    echo ""
}

# ============================================================
# 工具函数
# ============================================================

# 检查命令是否存在
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        return 1
    fi
    return 0
}

# 检查端口是否被占用
check_port() {
    local port="$1"
    if lsof -Pi :"$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1  # 被占用
    fi
    return 0  # 空闲
}

# 获取端口占用的 PID
get_port_pid() {
    local port="$1"
    lsof -ti:"$port" 2>/dev/null | head -1
}

# 检查进程是否存在
is_process_running() {
    local pid="$1"
    ps -p "$pid" > /dev/null 2>&1
}

# 等待端口可用
wait_for_port() {
    local port="$1"
    local timeout="${2:-30}"
    local count=0
    
    while ! check_port "$port" && [ $count -lt $timeout ]; do
        sleep 1
        count=$((count + 1))
    done
    
    [ $count -lt $timeout ]
}

# 等待服务启动
wait_for_service() {
    local port="$1"
    local timeout="${2:-10}"
    local count=0
    
    while check_port "$port" && [ $count -lt $timeout ]; do
        sleep 1
        count=$((count + 1))
    done
    
    ! check_port "$port"
}

# HTTP 健康检查
http_health_check() {
    local url="$1"
    local timeout="${2:-5}"
    
    curl -sf --connect-timeout "$timeout" "$url" > /dev/null 2>&1
}

# ============================================================
# 环境变量
# ============================================================

# 加载 .env 文件
load_env() {
    local env_file="${1:-$PROJECT_ROOT/.env}"
    
    if [ -f "$env_file" ]; then
        # 安全加载环境变量，忽略注释和空行
        while IFS='=' read -r key value; do
            # 跳过注释和空行
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            # 去除首尾空白
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            
            # 去除值两端的引号
            value="${value#\"}"
            value="${value%\"}"
            value="${value#\'}"
            value="${value%\'}"
            
            # 导出变量
            export "$key=$value"
        done < "$env_file"
        return 0
    else
        return 1
    fi
}

# ============================================================
# 服务管理
# ============================================================

# 检查服务状态（返回 0 表示运行中）
check_service_status() {
    local service="$1"
    local port="${SERVICE_PORTS[$service]}"
    
    ! check_port "$port"
}

# 停止服务
stop_service_by_pid() {
    local service_name="$1"
    local pid_file="$LOG_DIR/${service_name}.pid"
    local timeout="${2:-10}"
    
    if [ ! -f "$pid_file" ]; then
        return 1  # PID 文件不存在
    fi
    
    local pid
    pid=$(cat "$pid_file")
    
    if ! is_process_running "$pid"; then
        rm -f "$pid_file"
        return 1  # 进程不存在
    fi
    
    # 发送 SIGTERM
    kill "$pid" 2>/dev/null
    
    # 等待进程结束
    local count=0
    while is_process_running "$pid" && [ $count -lt $timeout ]; do
        sleep 1
        count=$((count + 1))
    done
    
    # 如果还没结束，强制杀掉
    if is_process_running "$pid"; then
        kill -9 "$pid" 2>/dev/null
        sleep 1
    fi
    
    rm -f "$pid_file"
    return 0
}

# 通过端口停止服务
stop_service_by_port() {
    local port="$1"
    local timeout="${2:-5}"
    
    local pids
    pids=$(lsof -ti:"$port" 2>/dev/null)
    
    if [ -z "$pids" ]; then
        return 1  # 没有进程
    fi
    
    # 发送 SIGTERM
    echo "$pids" | xargs kill 2>/dev/null
    
    # 等待
    sleep 1
    
    # 检查是否还有进程
    local remaining
    remaining=$(lsof -ti:"$port" 2>/dev/null)
    
    if [ -n "$remaining" ]; then
        echo "$remaining" | xargs kill -9 2>/dev/null
        sleep 1
    fi
    
    return 0
}

# ============================================================
# 帮助信息
# ============================================================

# 显示版本信息
show_version() {
    local cmd="$1"
    local name="$2"
    
    if check_command "$cmd"; then
        local version
        if [ "$cmd" = "go" ]; then
            version=$(go version 2>&1 | head -n 1)
        else
            version=$("$cmd" --version 2>&1 | head -n 1)
        fi
        echo "    $name: $version"
    fi
}

# ============================================================
# 初始化
# ============================================================

# 确保日志目录存在
ensure_log_dir() {
    mkdir -p "$LOG_DIR"
}

# 初始化公共设置
init_common() {
    ensure_log_dir
}
