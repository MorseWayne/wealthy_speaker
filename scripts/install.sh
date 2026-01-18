#!/bin/bash

# Wealthy Speaker - 依赖安装脚本
# 用于安装所有服务的依赖
#
# 用法:
#   ./install.sh              安装所有依赖
#   ./install.sh collector    只安装 Go 依赖
#   ./install.sh analyzer     只安装 Python 依赖
#   ./install.sh web          只安装 Node.js 依赖
#   ./install.sh check        只检查系统依赖
#   ./install.sh -h|--help    显示帮助

set -e

# 加载公共函数库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ============================================================
# 帮助信息
# ============================================================
show_help() {
    echo "用法: $0 [组件] [选项]"
    echo ""
    echo "组件 (可选):"
    echo "  collector    只安装 Go 依赖 (Data Collector)"
    echo "  analyzer     只安装 Python 依赖 (AI Analyzer)"
    echo "  web          只安装 Node.js 依赖 (Web Interface)"
    echo "  check        只检查系统依赖，不安装"
    echo "  all          安装所有依赖 (默认)"
    echo ""
    echo "选项:"
    echo "  -h, --help      显示此帮助信息"
    echo "  -y, --yes       自动确认所有提示"
    echo "  --skip-check    跳过系统依赖检查"
    echo ""
    echo "示例:"
    echo "  $0              安装所有依赖"
    echo "  $0 analyzer     只安装 Python 依赖"
    echo "  $0 check        检查系统依赖"
    echo ""
}

# ============================================================
# 系统依赖检查
# ============================================================
check_system_dependencies() {
    print_section "检查系统依赖"
    
    local missing_deps=0
    local missing_db_deps=0
    
    # 定义需要检查的命令
    declare -A deps=(
        ["go"]="Go 1.25+ : https://golang.org/dl/"
        ["python3"]="Python 3.11+ : https://www.python.org/downloads/"
        ["node"]="Node.js 18+ : https://nodejs.org/"
        ["npm"]="npm (通常随 Node.js 安装)"
    )
    
    # 检查开发工具依赖
    log_info "开发工具:"
    for cmd in go python3 node npm; do
        if check_command "$cmd"; then
            log_success "$cmd 已安装"
            show_version "$cmd" "${cmd^}"
        else
            log_error "$cmd 未安装"
            log_warning "请安装 ${deps[$cmd]}"
            missing_deps=1
        fi
    done
    
    # 检查 pip
    if check_command pip3; then
        log_success "pip3 已安装"
        show_version pip3 "pip"
    elif python3 -m pip --version &> /dev/null; then
        log_success "pip 已安装 (通过 python3 -m pip)"
    else
        log_warning "pip 未安装，将尝试使用 python3 -m pip"
    fi
    
    echo ""
    
    # 检查数据库依赖
    log_info "数据库服务:"
    if check_command psql; then
        log_success "psql 已安装"
        show_version psql "PostgreSQL"
    else
        log_error "psql 未安装"
        missing_db_deps=1
    fi
    
    if check_command redis-cli; then
        log_success "redis-cli 已安装"
        show_version redis-cli "Redis"
    else
        log_error "redis-cli 未安装"
        missing_db_deps=1
    fi
    
    echo ""
    
    # 如果缺少数据库依赖，询问是否安装
    if [ $missing_db_deps -eq 1 ]; then
        log_warning "缺少数据库依赖 (PostgreSQL/Redis)"
        
        if [ "$AUTO_YES" = "true" ]; then
            install_database_dependencies
        else
            echo -n "是否自动安装缺失的数据库依赖? (y/n): "
            read -r response
            if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                install_database_dependencies
            else
                log_error "请手动安装数据库依赖后重试"
                return 1
            fi
        fi
    fi
    
    if [ $missing_deps -eq 1 ]; then
        log_error "缺少必要的系统依赖，请先安装后再运行此脚本"
        return 1
    fi
    
    log_success "所有必要的系统依赖检查通过"
    return 0
}

# ============================================================
# 安装数据库依赖
# ============================================================
install_database_dependencies() {
    print_section "安装数据库依赖"
    
    # 检测包管理器
    if check_command apt-get; then
        install_db_deps_apt
    elif check_command yum; then
        install_db_deps_yum
    elif check_command dnf; then
        install_db_deps_dnf
    else
        log_error "不支持的包管理器，请手动安装 PostgreSQL 和 Redis"
        return 1
    fi
}

# Debian/Ubuntu 系统安装
install_db_deps_apt() {
    log_info "使用 apt 安装数据库依赖..."
    
    # 更新包列表
    log_info "更新包列表..."
    sudo apt-get update -qq
    
    # 安装 PostgreSQL
    if ! check_command psql; then
        log_info "安装 PostgreSQL..."
        if sudo apt-get install -y postgresql postgresql-contrib; then
            log_success "PostgreSQL 安装成功"
            
            # 启动服务
            sudo systemctl enable postgresql
            sudo systemctl start postgresql
            log_success "PostgreSQL 服务已启动"
        else
            log_error "PostgreSQL 安装失败"
            return 1
        fi
    fi
    
    # 安装 Redis
    if ! check_command redis-cli; then
        log_info "安装 Redis..."
        if sudo apt-get install -y redis-server; then
            log_success "Redis 安装成功"
            
            # 启动服务
            sudo systemctl enable redis-server
            sudo systemctl start redis-server
            log_success "Redis 服务已启动"
        else
            log_error "Redis 安装失败"
            return 1
        fi
    fi
    
    log_success "数据库依赖安装完成"
}

# RHEL/CentOS 系统安装 (yum)
install_db_deps_yum() {
    log_info "使用 yum 安装数据库依赖..."
    
    # 安装 PostgreSQL
    if ! check_command psql; then
        log_info "安装 PostgreSQL..."
        if sudo yum install -y postgresql-server postgresql; then
            sudo postgresql-setup --initdb 2>/dev/null || true
            sudo systemctl enable postgresql
            sudo systemctl start postgresql
            log_success "PostgreSQL 安装成功"
        else
            log_error "PostgreSQL 安装失败"
            return 1
        fi
    fi
    
    # 安装 Redis
    if ! check_command redis-cli; then
        log_info "安装 Redis..."
        if sudo yum install -y redis; then
            sudo systemctl enable redis
            sudo systemctl start redis
            log_success "Redis 安装成功"
        else
            log_error "Redis 安装失败"
            return 1
        fi
    fi
    
    log_success "数据库依赖安装完成"
}

# Fedora 系统安装 (dnf)
install_db_deps_dnf() {
    log_info "使用 dnf 安装数据库依赖..."
    
    # 安装 PostgreSQL
    if ! check_command psql; then
        log_info "安装 PostgreSQL..."
        if sudo dnf install -y postgresql-server postgresql; then
            sudo postgresql-setup --initdb 2>/dev/null || true
            sudo systemctl enable postgresql
            sudo systemctl start postgresql
            log_success "PostgreSQL 安装成功"
        else
            log_error "PostgreSQL 安装失败"
            return 1
        fi
    fi
    
    # 安装 Redis
    if ! check_command redis-cli; then
        log_info "安装 Redis..."
        if sudo dnf install -y redis; then
            sudo systemctl enable redis
            sudo systemctl start redis
            log_success "Redis 安装成功"
        else
            log_error "Redis 安装失败"
            return 1
        fi
    fi
    
    log_success "数据库依赖安装完成"
}

# ============================================================
# Go 依赖安装
# ============================================================
install_go_dependencies() {
    print_section "安装 Go 依赖 (Data Collector)"
    
    cd "$PROJECT_ROOT/collector"
    
    if [ ! -f "go.mod" ]; then
        log_error "go.mod 文件不存在"
        return 1
    fi
    
    log_info "下载 Go 模块..."
    if go mod download; then
        log_success "Go 模块下载成功"
    else
        log_error "Go 模块下载失败"
        return 1
    fi
    
    log_info "整理 Go 依赖..."
    if go mod tidy; then
        log_success "Go 依赖整理完成"
    else
        log_error "Go 依赖整理失败"
        return 1
    fi
    
    log_info "验证 Go 依赖..."
    if go mod verify; then
        log_success "Go 依赖验证通过"
    else
        log_warning "Go 依赖验证失败，但可能不影响使用"
    fi
    
    # 尝试构建以确保依赖完整
    log_info "测试编译 Go 项目..."
    mkdir -p bin
    if go build -o bin/wealthy-service cmd/server/main.go; then
        log_success "Go 项目编译成功"
        rm -f bin/wealthy-service
    else
        log_error "Go 项目编译失败，请检查代码"
        return 1
    fi
    
    echo ""
    log_success "✓ Go 依赖安装完成"
    return 0
}

# ============================================================
# Python 依赖安装
# ============================================================
install_python_dependencies() {
    print_section "安装 Python 依赖 (AI Analyzer)"
    
    cd "$PROJECT_ROOT/analyzer"
    
    if [ ! -f "requirements.txt" ]; then
        log_error "requirements.txt 文件不存在"
        return 1
    fi
    
    # 检查/创建虚拟环境
    if [ -d "venv" ] && [ -f "venv/bin/activate" ]; then
        log_warning "虚拟环境已存在，将使用现有环境"
    else
        # 如果 venv 目录存在但不完整，先删除
        if [ -d "venv" ]; then
            log_warning "虚拟环境不完整，正在重新创建..."
            rm -rf venv
        fi
        
        log_info "创建 Python 虚拟环境..."
        if python3 -m venv venv; then
            log_success "虚拟环境创建成功"
        else
            log_error "虚拟环境创建失败"
            return 1
        fi
    fi
    
    # 激活虚拟环境
    log_info "激活虚拟环境..."
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    else
        log_error "无法激活虚拟环境，activate 文件不存在"
        return 1
    fi
    
    # 升级 pip
    log_info "升级 pip..."
    if python -m pip install --upgrade pip -q; then
        log_success "pip 升级成功"
    else
        log_warning "pip 升级失败，继续使用当前版本"
    fi
    
    # 安装依赖
    log_info "安装 Python 包..."
    if python -m pip install -r requirements.txt; then
        log_success "Python 包安装成功"
    else
        log_error "Python 包安装失败"
        deactivate
        return 1
    fi
    
    # 显示已安装的关键包
    log_info "已安装的关键包:"
    python -m pip list 2>/dev/null | grep -iE 'fastapi|uvicorn|psycopg|redis|snownlp|pydantic' || true
    
    deactivate
    
    echo ""
    log_success "✓ Python 依赖安装完成"
    return 0
}

# ============================================================
# Node.js 依赖安装
# ============================================================
install_nodejs_dependencies() {
    print_section "安装 Node.js 依赖 (Web Interface)"
    
    cd "$PROJECT_ROOT/web"
    
    if [ ! -f "package.json" ]; then
        log_error "package.json 文件不存在"
        return 1
    fi
    
    # 检查 node_modules
    if [ -d "node_modules" ]; then
        log_warning "node_modules 已存在，将重新安装"
        rm -rf node_modules
    fi
    
    # 安装依赖
    log_info "安装 npm 包..."
    if npm install; then
        log_success "npm 包安装成功"
    else
        log_error "npm 包安装失败"
        return 1
    fi
    
    # 显示已安装的包
    log_info "已安装的包:"
    npm list --depth=0 2>/dev/null | head -10 || true
    
    echo ""
    log_success "✓ Node.js 依赖安装完成"
    return 0
}

# ============================================================
# 环境配置
# ============================================================
check_environment() {
    print_section "检查环境配置"
    
    cd "$PROJECT_ROOT"
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            log_warning ".env 文件不存在"
            
            if [ "$AUTO_YES" = "true" ]; then
                cp .env.example .env
                log_success ".env 文件已创建"
                log_warning "请编辑 .env 文件配置数据库密码等信息"
            else
                echo -n "是否从 .env.example 创建 .env 文件? (y/n): "
                read -r response
                if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                    cp .env.example .env
                    log_success ".env 文件已创建"
                    log_warning "请编辑 .env 文件配置数据库密码等信息"
                else
                    log_warning "跳过 .env 文件创建"
                fi
            fi
        else
            log_warning ".env.example 文件不存在，跳过环境配置"
        fi
    else
        log_success ".env 文件已存在"
    fi
}

# ============================================================
# 创建目录
# ============================================================
create_directories() {
    print_section "创建必要的目录"
    
    cd "$PROJECT_ROOT"
    
    # 需要创建的目录列表
    local dirs=("logs" "collector/bin")
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_success "创建目录: $dir/"
        else
            log_info "目录已存在: $dir/"
        fi
    done
}

# ============================================================
# 安装摘要
# ============================================================
show_summary() {
    echo ""
    print_section "安装完成摘要"
    
    log_success "所有依赖安装完成！"
    echo ""
    
    echo "已安装的组件:"
    echo "   ✓ PostgreSQL 数据库"
    echo "   ✓ Redis 缓存"
    echo "   ✓ Go 依赖 (Data Collector)"
    echo "   ✓ Python 依赖 (AI Analyzer)"
    echo "   ✓ Node.js 依赖 (Web Interface)"
    echo ""
    
    echo "下一步:"
    echo "   1. 配置环境变量 (如果还未配置):"
    echo "      编辑 .env 文件，设置 DB_PASSWORD 等配置"
    echo ""
    echo "   2. 启动所有服务:"
    echo "      ./start.sh"
    echo ""
    echo "      start.sh 会自动:"
    echo "      - 启动 PostgreSQL 和 Redis"
    echo "      - 创建数据库和用户"
    echo "      - 启动所有应用服务"
    echo ""
    echo "相关文档:"
    echo "   - 快速开始: QUICKSTART.md"
    echo "   - 脚本说明: scripts/README.md"
    echo "   - 开发指南: AGENTS.md"
    echo ""
}

# ============================================================
# 主函数
# ============================================================
main() {
    local target="all"
    AUTO_YES=false
    local skip_check=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -y|--yes)
                AUTO_YES=true
                shift
                ;;
            --skip-check)
                skip_check=true
                shift
                ;;
            collector|analyzer|web|check|all)
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
    
    print_header "Wealthy Speaker - 依赖安装脚本"
    
    # 只检查模式
    if [ "$target" = "check" ]; then
        check_system_dependencies
        exit $?
    fi
    
    # 检查系统依赖
    if [ "$skip_check" = "false" ]; then
        if ! check_system_dependencies; then
            exit 1
        fi
    fi
    
    # 创建目录
    create_directories
    
    # 检查环境配置
    check_environment
    
    # 安装依赖
    case $target in
        collector)
            install_go_dependencies
            ;;
        analyzer)
            install_python_dependencies
            ;;
        web)
            install_nodejs_dependencies
            ;;
        all)
            install_go_dependencies
            install_python_dependencies
            install_nodejs_dependencies
            show_summary
            ;;
    esac
    
    log_success "安装过程完成！"
    echo ""
}

# 运行主函数
main "$@"
