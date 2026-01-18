#!/bin/bash

# Wealthy Speaker - 停止脚本
# 用于停止所有本地运行的服务
#
# 用法:
#   ./stop.sh              停止所有服务
#   ./stop.sh collector    只停止 Collector
#   ./stop.sh analyzer     只停止 Analyzer
#   ./stop.sh web          只停止 Web
#   ./stop.sh -h|--help    显示帮助

# 不使用 set -e，因为停止服务时某些命令失败是正常的

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
    echo "  collector    只停止 Data Collector 服务"
    echo "  analyzer     只停止 AI Analyzer 服务"
    echo "  web          只停止 Web 界面服务"
    echo "  all          停止所有服务 (默认)"
    echo ""
    echo "选项:"
    echo "  -h, --help   显示此帮助信息"
    echo "  -9, --force  强制杀死进程 (SIGKILL)"
    echo ""
    echo "示例:"
    echo "  $0              停止所有服务"
    echo "  $0 web          只停止 Web 服务"
    echo "  $0 -9           强制停止所有服务"
    echo ""
}

# ============================================================
# 停止函数
# ============================================================

# 杀死进程及其子进程
kill_process_tree() {
    local pid="$1"
    local signal="${2:-TERM}"
    
    # 获取所有子进程
    local children
    children=$(pgrep -P "$pid" 2>/dev/null) || true
    
    # 先杀子进程
    for child in $children; do
        kill_process_tree "$child" "$signal"
    done
    
    # 再杀父进程
    kill -"$signal" "$pid" 2>/dev/null || true
}

# 停止单个服务
stop_service() {
    local service="$1"
    local force_kill="${2:-false}"
    
    local port="${SERVICE_PORTS[$service]}"
    local name="${SERVICE_NAMES[$service]}"
    local pid_file="$LOG_DIR/${service}.pid"
    local stopped=false
    
    # 优先通过端口停止（更可靠）
    local pids
    pids=$(lsof -ti:"$port" 2>/dev/null) || true
    
    if [ -n "$pids" ]; then
        log_info "正在停止 $name (端口: $port)..."
        
        if [ "$force_kill" = "true" ]; then
            echo "$pids" | xargs kill -9 2>/dev/null || true
        else
            # 先尝试正常终止
            echo "$pids" | xargs kill 2>/dev/null || true
            
            # 短暂等待
            sleep 2
            
            # 检查是否还在运行
            local remaining
            remaining=$(lsof -ti:"$port" 2>/dev/null) || true
            if [ -n "$remaining" ]; then
                log_warning "$name 未正常退出，强制终止..."
                echo "$remaining" | xargs kill -9 2>/dev/null || true
                sleep 1
            fi
        fi
        
        stopped=true
        log_success "$name 已停止"
    fi
    
    # 如果端口没有进程，尝试通过 PID 文件停止
    if [ "$stopped" = "false" ] && [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file")
        
        if is_process_running "$pid"; then
            log_info "正在停止 $name (PID: $pid)..."
            
            if [ "$force_kill" = "true" ]; then
                kill_process_tree "$pid" "KILL"
            else
                kill_process_tree "$pid" "TERM"
                sleep 2
                
                if is_process_running "$pid"; then
                    log_warning "$name 未正常退出，强制终止..."
                    kill_process_tree "$pid" "KILL"
                fi
            fi
            
            stopped=true
            log_success "$name 已停止"
        fi
    fi
    
    # 清理 PID 文件
    rm -f "$pid_file"
    
    if [ "$stopped" = "false" ]; then
        log_info "$name 未运行 (端口: $port)"
    fi
}

# ============================================================
# 主函数
# ============================================================
main() {
    local target="all"
    local force_kill="false"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -9|--force)
                force_kill="true"
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
    
    print_header "Wealthy Speaker - 停止服务"
    
    # 停止服务（按启动的逆序）
    case $target in
        collector)
            stop_service "collector" "$force_kill"
            ;;
        analyzer)
            stop_service "analyzer" "$force_kill"
            ;;
        web)
            stop_service "web" "$force_kill"
            ;;
        all)
            stop_service "web" "$force_kill"
            stop_service "analyzer" "$force_kill"
            stop_service "collector" "$force_kill"
            ;;
    esac
    
    echo ""
    log_success "停止操作完成"
    echo ""
}

# 运行主函数
main "$@"
