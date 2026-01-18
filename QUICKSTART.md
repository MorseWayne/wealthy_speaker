# Wealthy Speaker

完整的每日财经总结服务 - AI驱动的投资决策支持系统。

## 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+

### 一键启动

1. 复制环境变量模板：
```bash
cp .env.example .env
```

2. 编辑 `.env` 文件，配置必要参数：
```bash
nano .env
```

3. 启动所有服务：
```bash
docker-compose up -d
```

4. 查看服务状态：
```bash
docker-compose ps
```

5. 查看日志：
```bash
docker-compose logs -f
```

### 服务访问

- **Web管理界面**: http://localhost:3000
- **数据收集API**: http://localhost:8080
- **AI分析API**: http://localhost:8000
- **数据库**: localhost:5432

## 服务说明

### 1. 数据收集服务 (Go)
- **端口**: 8080
- **功能**: 定时采集股票数据和新闻
- **定时任务**:
  - 每日08:00: 执行完整财经分析
  - 每小时: 采集实时数据
  - 每周日02:00: 清理过期数据

### 2. AI分析引擎 (Python)
- **端口**: 8000
- **功能**:
  - 新闻情感分析
  - 投资建议生成
  - 技术指标计算

### 3. Web管理界面 (Node.js)
- **端口**: 3000
- **功能**:
  - 查看每日总结
  - 历史记录查询
  - 股票/新闻数据查看
  - 系统状态监控

### 4. PostgreSQL数据库
- **端口**: 5432
- **数据保留**: 1个月

## 停止服务

```bash
docker-compose down
```

## 清理数据

```bash
docker-compose down -v
```

## 重启服务

```bash
docker-compose restart
```

## 查看特定服务日志

```bash
docker-compose logs -f collector
docker-compose logs -f analyzer
docker-compose logs -f web
```

## 故障排查

### 服务无法启动

1. 检查端口占用：
```bash
netstat -tulpn | grep -E ':(8080|8000|3000|5432)'
```

2. 查看服务日志：
```bash
docker-compose logs
```

3. 检查数据库连接：
```bash
docker-compose exec postgres psql -U fin_user -d financial_db -c "SELECT version();"
```

### 数据采集失败

1. 检查网络连接：
```bash
docker-compose exec collector ping -c 3 google.com
```

2. 查看API日志：
```bash
docker-compose logs collector | tail -100
```

### AI分析失败

1. 检查Python依赖：
```bash
docker-compose exec analyzer pip list
```

2. 查看分析日志：
```bash
docker-compose logs analyzer | tail -100
```

## 开发模式

### 单独运行服务

#### 数据收集服务
```bash
cd collector
go run cmd/server/main.go
```

#### AI分析引擎
```bash
cd analyzer
pip install -r requirements.txt
uvicorn main:app --reload
```

#### Web管理界面
```bash
cd web
npm install
npm run dev
```

## 配置说明

### 数据库配置
- `DB_NAME`: 数据库名称
- `DB_USER`: 数据库用户
- `DB_PASSWORD`: 数据库密码

### 消息推送配置
- `WECHAT_WEBHOOK`: 微信企业号webhook URL
- `FEISHU_WEBHOOK`: 飞书机器人webhook URL

### 数据源配置
- `ALPHA_VANTAGE_API_KEY`: Alpha Vantage API密钥
- `YAHOO_FINANCE_ENABLED`: 启用Yahoo Finance
- `AKSHARE_ENABLED`: 启用AKShare

## 许可证

MIT License

## 支持

如有问题，请查看 [README.md](README.md) 和 [AGENTS.md](AGENTS.md)
