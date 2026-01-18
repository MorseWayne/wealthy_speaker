#!/bin/bash

# Wealthy Speaker - 本地启动脚本
# 用于在 Ubuntu 上直接运行所有服务
#
# 用法:
#   ./start.sh              启动所有服务
#   ./start.sh collector    只启动 Collector
#   ./start.sh analyzer     只启动 Analyzer
#   ./start.sh web          只启动 Web
#   ./start.sh -h|--help    显示帮助

set -e

# 加载公共函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 初始化
init_common

# ============================================================
# 帮助信息
# ============================================================
show_help() {
    echo "用法: $0 [服务名称] [选项]"
    echo ""
    echo "服务名称 (可选):"
    echo "  collector    只启动 Data Collector 服务"
    echo "  analyzer     只启动 AI Analyzer 服务"
    echo "  web          只启动 Web 界面服务"
    echo "  all          启动所有服务 (默认)"
    echo ""
    echo "选项:"
    echo "  -h, --help   显示此帮助信息"
    echo "  -f, --force  强制启动（如果端口被占用则先停止）"
    echo ""
    echo "示例:"
    echo "  $0              启动所有服务"
    echo "  $0 web          只启动 Web 服务"
    echo "  $0 -f           强制重启所有服务"
    echo ""
}

# ============================================================
# 依赖检查
# ============================================================
check_dependencies() {
    log_info "检查系统依赖..."
    
    local missing_deps=0
    
    for cmd in psql redis-cli go python3 node; do
        if ! check_command "$cmd"; then
            log_error "$cmd 未安装"
            missing_deps=1
        fi
    done
    
    if [ $missing_deps -eq 1 ]; then
        log_error "请先安装缺失的依赖"
        exit 1
    fi
    
    log_success "所有依赖检查通过"
}

# 检查基础服务
check_infrastructure() {
    log_info "检查基础服务..."
    
    # 检查并启动 PostgreSQL
    if ! sudo systemctl is-active --quiet postgresql 2>/dev/null; then
        log_warning "PostgreSQL 未运行，正在启动..."
        sudo systemctl start postgresql
        sleep 2
    fi
    
    if sudo systemctl is-active --quiet postgresql 2>/dev/null; then
        log_success "PostgreSQL 运行中"
    else
        log_error "PostgreSQL 启动失败"
        exit 1
    fi
    
    # 检查并启动 Redis
    if ! redis-cli ping > /dev/null 2>&1; then
        log_warning "Redis 未运行，正在启动..."
        sudo systemctl start redis-server 2>/dev/null || sudo systemctl start redis 2>/dev/null
        sleep 2
    fi
    
    if redis-cli ping > /dev/null 2>&1; then
        log_success "Redis 运行中"
    else
        log_error "Redis 启动失败"
        exit 1
    fi
    
    # 检查并初始化数据库
    init_database
}

# 初始化数据库
init_database() {
    log_info "检查数据库配置..."
    
    local db_name="${DB_NAME:-financial_db}"
    local db_user="${DB_USER:-fin_user}"
    local db_password="${DB_PASSWORD:-}"
    local db_host="${DB_HOST:-localhost}"
    local db_port="${DB_PORT:-5432}"
    
    if [ -z "$db_password" ]; then
        log_error "DB_PASSWORD 未设置，请在 .env 文件中配置"
        exit 1
    fi
    
    # 检查数据库用户是否存在
    if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${db_user}'" 2>/dev/null | grep -q 1; then
        log_warning "数据库用户 ${db_user} 不存在，正在创建..."
        sudo -u postgres psql -c "CREATE USER ${db_user} WITH PASSWORD '${db_password}';" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "数据库用户 ${db_user} 创建成功"
        else
            log_error "数据库用户创建失败"
            exit 1
        fi
    else
        log_success "数据库用户 ${db_user} 已存在"
    fi
    
    # 检查数据库是否存在
    if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${db_name}'" 2>/dev/null | grep -q 1; then
        log_warning "数据库 ${db_name} 不存在，正在创建..."
        sudo -u postgres psql -c "CREATE DATABASE ${db_name} OWNER ${db_user};" 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "数据库 ${db_name} 创建成功"
        else
            log_error "数据库创建失败"
            exit 1
        fi
        
        # 授权
        sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${db_name} TO ${db_user};" 2>/dev/null
    else
        log_success "数据库 ${db_name} 已存在"
    fi
    
    # 测试连接
    if PGPASSWORD="${db_password}" psql -h "$db_host" -p "$db_port" -U "${db_user}" -d "${db_name}" -c "SELECT 1;" > /dev/null 2>&1; then
        log_success "数据库连接正常"
    else
        log_error "无法连接到数据库，请检查密码配置"
        exit 1
    fi
}

# ============================================================
# 服务启动函数
# ============================================================

# 启动 Collector 服务
start_collector() {
    local force="${1:-false}"
    
    log_info "启动 Data Collector 服务..."
    
    local port="${SERVICE_PORTS[collector]}"
    
    if ! check_port "$port"; then
        if [ "$force" = "true" ]; then
            log_warning "端口 $port 已被占用，正在停止..."
            stop_service_by_port "$port"
        else
            log_warning "端口 $port 已被占用，跳过启动 Collector (使用 -f 强制启动)"
            return 1
        fi
    fi
    
    cd "$PROJECT_ROOT/collector"
    
    # 确保数据库环境变量已设置（从 .env 加载）
    if [ -z "${DB_PASSWORD:-}" ]; then
        log_error "DB_PASSWORD 未设置"
        return 1
    fi

    # 统一 Collector 监听地址（优先使用 COLLECTOR_ADDR，否则根据端口生成）
    if [ -z "${COLLECTOR_ADDR:-}" ]; then
        export COLLECTOR_ADDR=":${port}"
    fi
    
    # 启动服务（环境变量已在 load_env 中加载）
    nohup go run cmd/server/main.go > "$LOG_DIR/collector.log" 2>&1 &
    echo $! > "$LOG_DIR/collector.pid"
    
    # 等待服务启动
    if wait_for_service "$port" 10; then
        log_success "Collector 服务启动成功 (PID: $(cat "$LOG_DIR/collector.pid"), 端口: $port)"
        return 0
    else
        log_error "Collector 服务启动失败，请查看日志: $LOG_DIR/collector.log"
        return 1
    fi
}

# 启动 Analyzer 服务
start_analyzer() {
    local force="${1:-false}"
    
    log_info "启动 AI Analyzer 服务..."
    
    local port="${SERVICE_PORTS[analyzer]}"
    
    if ! check_port "$port"; then
        if [ "$force" = "true" ]; then
            log_warning "端口 $port 已被占用，正在停止..."
            stop_service_by_port "$port"
        else
            log_warning "端口 $port 已被占用，跳过启动 Analyzer (使用 -f 强制启动)"
            return 1
        fi
    fi
    
    cd "$PROJECT_ROOT/analyzer"
    
    # 检查虚拟环境
    if [ ! -d "venv" ] || [ ! -f "venv/bin/activate" ]; then
        log_warning "Python 虚拟环境不存在或不完整，正在创建..."
        rm -rf venv 2>/dev/null
        python3 -m venv venv
        if [ ! -f "venv/bin/activate" ]; then
            log_error "虚拟环境创建失败"
            return 1
        fi
        source venv/bin/activate
        pip install -r requirements.txt
    else
        source venv/bin/activate
    fi
    
    # 设置环境变量（尽量全部从 .env 统一管理）
    local db_host="${DB_HOST:-localhost}"
    local db_port="${DB_PORT:-5432}"
    local db_user="${DB_USER:-fin_user}"
    local db_password="${DB_PASSWORD:-}"
    local db_name="${DB_NAME:-financial_db}"

    local redis_host="${REDIS_HOST:-localhost}"
    local redis_port="${REDIS_PORT:-6379}"
    local redis_db="${REDIS_DB:-0}"

    # 允许直接在 .env 中指定 DATABASE_URL / REDIS_URL；否则根据 DB_/REDIS_ 拼接
    export DATABASE_URL="${DATABASE_URL:-postgresql://${db_user}:${db_password}@${db_host}:${db_port}/${db_name}}"
    export REDIS_URL="${REDIS_URL:-redis://${redis_host}:${redis_port}/${redis_db}}"
    export HOST="${ANALYZER_HOST:-0.0.0.0}"
    export PORT="$port"
    
    # 启动服务
    nohup python main.py > "$LOG_DIR/analyzer.log" 2>&1 &
    echo $! > "$LOG_DIR/analyzer.pid"
    
    # 等待服务启动
    if wait_for_service "$port" 10; then
        log_success "Analyzer 服务启动成功 (PID: $(cat "$LOG_DIR/analyzer.pid"), 端口: $port)"
        return 0
    else
        log_error "Analyzer 服务启动失败，请查看日志: $LOG_DIR/analyzer.log"
        return 1
    fi
}

# 启动 Web 服务
start_web() {
    local force="${1:-false}"
    
    log_info "启动 Web 界面服务..."
    
    local port="${SERVICE_PORTS[web]}"
    
    if ! check_port "$port"; then
        if [ "$force" = "true" ]; then
            log_warning "端口 $port 已被占用，正在停止..."
            stop_service_by_port "$port"
        else
            log_warning "端口 $port 已被占用，跳过启动 Web (使用 -f 强制启动)"
            return 1
        fi
    fi
    
    cd "$PROJECT_ROOT/web"
    
    # 检查依赖
    if [ ! -d "node_modules" ]; then
        log_warning "Node.js 依赖未安装，正在安装..."
        npm install
    fi
    
    # 设置环境变量
    export PORT="$port"
    export DATA_COLLECTOR_URL="${DATA_COLLECTOR_URL:-http://localhost:${SERVICE_PORTS[collector]}}"
    export AI_ANALYZER_URL="${AI_ANALYZER_URL:-http://localhost:${SERVICE_PORTS[analyzer]}}"
    
    # 启动服务
    nohup npm start > "$LOG_DIR/web.log" 2>&1 &
    echo $! > "$LOG_DIR/web.pid"
    
    # 等待服务启动
    if wait_for_service "$port" 10; then
        log_success "Web 服务启动成功 (PID: $(cat "$LOG_DIR/web.pid"), 端口: $port)"
        return 0
    else
        log_error "Web 服务启动失败，请查看日志: $LOG_DIR/web.log"
        return 1
    fi
}

# ============================================================
# 状态显示
# ============================================================
show_status() {
    echo ""
    log_info "=== 服务状态 ==="
    echo ""
    
    for service in collector analyzer web; do
        local port="${SERVICE_PORTS[$service]}"
        local name="${SERVICE_NAMES[$service]}"
        
        if ! check_port "$port"; then
            local pid
            pid=$(get_port_pid "$port")
            log_success "$name 运行中 (端口: $port, PID: $pid)"
        else
            log_warning "$name 未运行 (端口: $port)"
        fi
    done
    
    echo ""
    log_info "=== 访问地址 ==="
    echo ""
    echo "  Web 界面:       http://localhost:${SERVICE_PORTS[web]}"
    echo "  Collector API:  http://localhost:${SERVICE_PORTS[collector]}"
    echo "  Analyzer API:   http://localhost:${SERVICE_PORTS[analyzer]}"
    echo ""
    log_info "=== 日志文件 ==="
    echo ""
    echo "  Collector: $LOG_DIR/collector.log"
    echo "  Analyzer:  $LOG_DIR/analyzer.log"
    echo "  Web:       $LOG_DIR/web.log"
    echo ""
}

# ============================================================
# 主函数
# ============================================================
main() {
    local target="all"
    local force="false"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--force)
                force="true"
                shift
                ;;
            collector|analyzer|web|all)
                target="$1"
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_header "Wealthy Speaker - 本地启动脚本"
    
    # 加载环境变量
    if ! load_env; then
        log_error ".env 文件不存在，请从 .env.example 复制并配置"
        exit 1
    fi
    
    # 检查依赖
    check_dependencies
    
    # 检查基础服务
    check_infrastructure
    
    # 启动应用服务
    case $target in
        collector)
            start_collector "$force"
            ;;
        analyzer)
            start_analyzer "$force"
            ;;
        web)
            start_web "$force"
            ;;
        all)
            start_collector "$force" || true
            start_analyzer "$force" || true
            start_web "$force" || true
            ;;
    esac
    
    # 显示状态
    show_status
    
    log_success "启动操作完成！"
    echo ""
}

# 运行主函数
main "$@"
