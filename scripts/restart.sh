#!/bin/bash

# Wealthy Speaker - 重启脚本
# 用于重启所有服务
#
# 用法:
#   ./restart.sh              重启所有服务
#   ./restart.sh collector    只重启 Collector
#   ./restart.sh analyzer     只重启 Analyzer
#   ./restart.sh web          只重启 Web
#   ./restart.sh -h|--help    显示帮助

# 加载公共函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ============================================================
# 帮助信息
# ============================================================
show_help() {
    echo "用法: $0 [服务名称] [选项]"
    echo ""
    echo "服务名称 (可选):"
    echo "  collector    只重启 Data Collector 服务"
    echo "  analyzer     只重启 AI Analyzer 服务"
    echo "  web          只重启 Web 界面服务"
    echo "  all          重启所有服务 (默认)"
    echo ""
    echo "选项:"
    echo "  -h, --help   显示此帮助信息"
    echo "  -q, --quick  快速重启（减少等待时间）"
    echo ""
    echo "示例:"
    echo "  $0              重启所有服务"
    echo "  $0 web          只重启 Web 服务"
    echo ""
}

# ============================================================
# 主函数
# ============================================================
main() {
    local target="all"
    local quick=false
    local wait_time=2
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -q|--quick)
                quick=true
                wait_time=1
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
    
    print_header "Wealthy Speaker - 重启服务"
    
    log_info "正在重启 ${target} 服务..."
    echo ""
    
    # 停止服务
    if [ "$target" = "all" ]; then
        bash "$SCRIPT_DIR/stop.sh"
    else
        bash "$SCRIPT_DIR/stop.sh" "$target"
    fi
    
    # 等待
    log_info "等待 ${wait_time} 秒..."
    sleep "$wait_time"
    
    # 启动服务
    if [ "$target" = "all" ]; then
        bash "$SCRIPT_DIR/start.sh"
    else
        bash "$SCRIPT_DIR/start.sh" "$target"
    fi
}

# 运行主函数
main "$@"
