#!/bin/bash

# Wealthy Speaker - 状态检查脚本
# 用于检查所有服务的运行状态
#
# 用法:
#   ./status.sh           显示简要状态
#   ./status.sh -v        显示详细信息（包括资源和日志）
#   ./status.sh -h        显示帮助

# 加载公共函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 初始化
init_common

# ============================================================
# 帮助信息
# ============================================================
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -v, --verbose   显示详细信息（资源使用和日志）"
    echo "  -j, --json      以 JSON 格式输出"
    echo "  -h, --help      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0              显示服务状态"
    echo "  $0 -v           显示详细状态"
    echo ""
}

# ============================================================
# 状态检查函数
# ============================================================

# 检查单个服务状态
check_service() {
    local service="$1"
    local port="${SERVICE_PORTS[$service]}"
    local name="${SERVICE_NAMES[$service]}"
    local health_url="${SERVICE_HEALTH_URLS[$service]}"
    
    printf "%-20s" "$name:"
    
    if ! check_port "$port"; then
        local pid
        pid=$(get_port_pid "$port")
        echo -e "${GREEN}运行中${NC} (端口: $port, PID: $pid)"
        
        # HTTP 健康检查
        if [ -n "$health_url" ]; then
            if http_health_check "$health_url" 3; then
                echo -e "                    ${GREEN}✓ 健康检查通过${NC}"
            else
                echo -e "                    ${YELLOW}⚠ 健康检查失败${NC}"
            fi
        fi
        return 0
    else
        echo -e "${RED}未运行${NC} (端口: $port)"
        return 1
    fi
}

# 检查 Redis 连接
check_redis() {
    printf "%-20s" "Redis:"
    
    if redis-cli ping > /dev/null 2>&1; then
        echo -e "${GREEN}运行中${NC}"
        
        # 显示 Redis 信息
        local used_memory
        local connected_clients
        used_memory=$(redis-cli info memory 2>/dev/null | grep "used_memory_human" | cut -d: -f2 | tr -d '\r')
        connected_clients=$(redis-cli info clients 2>/dev/null | grep "connected_clients" | cut -d: -f2 | tr -d '\r')
        
        if [ -n "$used_memory" ]; then
            echo -e "                    内存: $used_memory, 连接数: $connected_clients"
        fi
        return 0
    else
        echo -e "${RED}未运行${NC}"
        return 1
    fi
}

# 检查数据库连接
check_database() {
    printf "%-20s" "PostgreSQL:"
    
    if sudo systemctl is-active --quiet postgresql 2>/dev/null; then
        echo -e "${GREEN}运行中${NC}"
        
        # 加载环境变量
        if load_env 2>/dev/null; then
            # 测试连接
            if [ -n "${DB_PASSWORD:-}" ] && [ -n "${DB_USER:-}" ] && [ -n "${DB_NAME:-}" ]; then
                if PGPASSWORD="${DB_PASSWORD}" psql -h localhost -U "${DB_USER}" -d "${DB_NAME}" -c "SELECT 1;" > /dev/null 2>&1; then
                    echo -e "                    ${GREEN}✓ 数据库连接正常${NC}"
                    
                    # 显示数据库大小
                    local db_size
                    db_size=$(PGPASSWORD="${DB_PASSWORD}" psql -h localhost -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT pg_size_pretty(pg_database_size('${DB_NAME}'));" 2>/dev/null | xargs)
                    if [ -n "$db_size" ]; then
                        echo -e "                    数据库大小: $db_size"
                    fi
                else
                    echo -e "                    ${YELLOW}⚠ 无法连接到数据库${NC}"
                fi
            fi
        fi
        return 0
    else
        echo -e "${RED}未运行${NC}"
        return 1
    fi
}

# ============================================================
# 详细信息
# ============================================================

# 显示资源使用情况
show_resources() {
    echo ""
    log_info "资源使用情况:"
    echo ""
    
    # 系统资源
    echo -e "${CYAN}系统资源:${NC}"
    
    # CPU (兼容不同系统)
    local cpu_usage
    cpu_usage=$(top -bn1 2>/dev/null | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf "%.1f%%", 100 - $1}')
    if [ -n "$cpu_usage" ]; then
        echo "  CPU: $cpu_usage"
    fi
    
    # 内存
    local mem_info
    mem_info=$(free -h 2>/dev/null | awk '/^Mem:/ {printf "%s / %s", $3, $2}')
    if [ -n "$mem_info" ]; then
        echo "  内存: $mem_info"
    fi
    
    # 磁盘
    local disk_info
    disk_info=$(df -h / 2>/dev/null | awk 'NR==2 {printf "%s / %s (%s)", $3, $2, $5}')
    if [ -n "$disk_info" ]; then
        echo "  磁盘: $disk_info"
    fi
    
    echo ""
    
    # 各服务的资源使用
    echo -e "${CYAN}服务资源:${NC}"
    
    for service in collector analyzer web; do
        local port="${SERVICE_PORTS[$service]}"
        local name="${SERVICE_NAMES[$service]}"
        local pid
        pid=$(get_port_pid "$port")
        
        if [ -n "$pid" ]; then
            local cpu mem
            cpu=$(ps -p "$pid" -o %cpu= 2>/dev/null | xargs)
            mem=$(ps -p "$pid" -o %mem= 2>/dev/null | xargs)
            printf "  %-20s CPU: %5s%%, MEM: %5s%%\n" "$name" "$cpu" "$mem"
        fi
    done
}

# 显示最近日志
show_logs() {
    echo ""
    log_info "最近的日志 (最后 5 行):"
    echo ""
    
    for service in collector analyzer web; do
        local log_file="$LOG_DIR/${service}.log"
        if [ -f "$log_file" ]; then
            echo -e "${CYAN}=== ${SERVICE_NAMES[$service]} ===${NC}"
            tail -5 "$log_file" 2>/dev/null || echo "  无法读取日志"
            echo ""
        fi
    done
}

# JSON 输出
show_json() {
    echo "{"
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"services\": {"
    
    local first=true
    for service in collector analyzer web; do
        local port="${SERVICE_PORTS[$service]}"
        local name="${SERVICE_NAMES[$service]}"
        local running="false"
        local pid=""
        
        if ! check_port "$port"; then
            running="true"
            pid=$(get_port_pid "$port")
        fi
        
        [ "$first" = "true" ] || echo ","
        first=false
        
        echo -n "    \"$service\": {\"name\": \"$name\", \"port\": $port, \"running\": $running"
        [ -n "$pid" ] && echo -n ", \"pid\": $pid"
        echo -n "}"
    done
    
    echo ""
    echo "  }"
    echo "}"
}

# ============================================================
# 主函数
# ============================================================
main() {
    local verbose=false
    local json=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -j|--json)
                json=true
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # JSON 模式
    if [ "$json" = "true" ]; then
        show_json
        exit 0
    fi
    
    print_header "Wealthy Speaker - 服务状态"
    
    log_info "基础服务:"
    echo ""
    check_database || true
    check_redis || true
    echo ""
    
    log_info "应用服务:"
    echo ""
    for service in collector analyzer web; do
        check_service "$service" || true
    done
    echo ""
    
    log_info "访问地址:"
    echo ""
    echo "  Web 界面:       http://localhost:${SERVICE_PORTS[web]}"
    echo "  Collector API:  http://localhost:${SERVICE_PORTS[collector]}"
    echo "  Analyzer API:   http://localhost:${SERVICE_PORTS[analyzer]}"
    
    # 详细模式
    if [ "$verbose" = "true" ]; then
        show_resources
        show_logs
    else
        echo ""
        log_info "提示: 使用 '$0 -v' 查看详细信息和日志"
    fi
    
    echo ""
    log_info "日志目录: $LOG_DIR"
    echo ""
}

# 运行主函数
main "$@"
