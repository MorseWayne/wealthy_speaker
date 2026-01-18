# 📊 Wealthy Speaker

一个每日自动化财经总结服务，为投资决策提供智能分析和建议。系统通过AI分析全球财经新闻、股票市场数据，生成个性化的投资参考报告。

## ✨ 核心功能

- 📰 **每日财经总结**: 自动收集和分析每日财经新闻
- 🤖 **AI智能分析**: 使用NLP技术进行情感分析和投资建议生成
- 📈 **技术分析**: 计算多种技术指标和趋势图表
- 📱 **多渠道推送**: 支持微信、飞书等即时消息推送
- 🌍 **全球市场覆盖**: 支持美股、A股、港股等多个市场
- 💾 **智能数据管理**: 自动数据清理和存储优化

## 🏗️ 技术架构

### 系统组成

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   数据采集服务   │────│   AI分析引擎    │────│   消息推送服务   │
│     (Go)       │    │   (Python)     │    │     (Go)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   PostgreSQL    │
                    │      +         │
                    │      Redis     │
                    └─────────────────┘
```

### 技术栈

| 组件 | 技术 | 说明 |
|------|------|------|
| **后端核心** | Go 1.21+ | 数据采集、API网关、消息推送 |
| **AI分析引擎** | Python 3.11+ | NLP处理、情感分析、投资建议 |
| **Web管理** | Node.js 18+ | 管理后台、数据可视化 |
| **数据库** | PostgreSQL 15 | 关系型数据存储 |
| **缓存** | Redis 7 | 缓存和任务队列 |
| **容器化** | Docker + Compose | 容器编排和部署 |
| **云平台** | 阿里云/腾讯云 | 云服务器和托管 |

## 🚀 快速开始

### 前置要求

- Docker 和 Docker Compose
- Go 1.21+ (本地开发)
- Python 3.11+ (本地开发)
- Node.js 18+ (本地开发)

### 一键启动 (推荐)

```bash
# 克隆仓库
git clone https://github.com/MorseWayne/wealthy_speaker.git
cd wealthy_speaker

# 创建环境变量文件
cp .env.example .env
# 编辑 .env 文件，填入必要的配置信息

# 启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f
```

### 本地开发环境

#### 1. 数据库初始化

```bash
# 启动数据库服务
docker-compose up -d postgres redis

# 运行数据库迁移
cd collector
go run cmd/migrate/main.go
```

#### 2. 启动数据采集服务 (Go)

```bash
cd collector

# 安装依赖
go mod download

# 运行服务
go run cmd/server/main.go

# 或者构建后运行
go build -o bin/collector cmd/server/main.go
./bin/collector
```

#### 3. 启动AI分析引擎 (Python)

```bash
cd analyzer

# 安装依赖
pip install -r requirements.txt

# 启动服务
uvicorn main:app --reload --port 8000
```

#### 4. 启动Web管理界面 (Node.js)

```bash
cd web

# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 构建生产版本
npm run build
npm run start
```

## 📖 使用指南

### 配置说明

创建 `.env` 文件并配置以下参数：

```env
# 数据库配置
DB_HOST=postgres
DB_PORT=5432
DB_NAME=financial_db
DB_USER=fin_user
DB_PASSWORD=your_secure_password

# Redis配置
REDIS_HOST=redis
REDIS_PORT=6379

# 消息推送配置
WECHAT_WEBHOOK=https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=your_key
FEISHU_WEBHOOK=https://open.feishu.cn/open-apis/bot/v2/hook/your_hook_id

# 数据源配置 (可选)
YAHOO_FINANCE_ENABLED=true
ALPHA_VANTAGE_API_KEY=your_api_key
TUSHARE_TOKEN=your_tushare_token

# 定时任务配置
DAILY_SUMMARY_TIME=08:00
DATA_CLEANUP_INTERVAL=24h
```

### 定时任务

系统默认配置以下定时任务：

- **每日08:00**: 执行财经分析和总结
- **每小时**: 数据采集和更新
- **每周**: 清理过期数据

### 查看财经总结

#### 通过Web界面

访问 `http://localhost:3000` 查看管理后台

#### 通过API接口

```bash
# 获取最新财经总结
curl http://localhost:8080/api/summary/latest

# 获取特定日期的总结
curl http://localhost:8080/api/summary/2024-01-16

# 查看历史总结列表
curl http://localhost:8080/api/summary/list?limit=10
```

#### 消息推送

系统会自动通过配置的微信或飞书webhook推送每日财经总结。

## 🧪 测试

### Go服务测试

```bash
cd collector

# 运行所有测试
go test ./...

# 运行单个测试
go test -run TestCollectData ./internal/collector

# 运行测试并生成覆盖率报告
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

### Python AI引擎测试

```bash
cd analyzer

# 运行所有测试
pytest

# 运行单个测试
pytest tests/test_analyzer.py::test_sentiment_analysis

# 运行测试并生成覆盖率报告
pytest --cov=analyzer --cov-report=html
```

### Web前端测试

```bash
cd web

# 运行所有测试
npm test

# 运行测试并生成覆盖率报告
npm run test:coverage
```

## 📊 数据源说明

### 免费数据源

| 数据源 | 支持市场 | 数据类型 | 限制 |
|--------|---------|---------|------|
| Yahoo Finance | 全球 | 股票、指数、外汇 | 每分钟2,000次请求 |
| AKShare | 中国A股 | 股票、基金、期货 | 基于爬虫，需合理使用 |
| Tushare | 中国 | 股票、基金、宏观数据 | 每天限制请求次数 |
| Alpha Vantage | 全球 | 股票、外汇、加密货币 | 每天25次免费请求 |

### 付费数据源 (后续支持)

- Bloomberg Terminal
- Wind金融终端
- 东方财富Choice
- 同花顺iFinD

## 🚀 部署指南

### Docker部署

```bash
# 构建所有服务镜像
docker-compose build

# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f [service_name]

# 停止服务
docker-compose down
```

### 云平台部署

#### 阿里云部署

1. 购买轻量应用服务器 (2核4G)
2. 安装Docker和Docker Compose
3. 克隆代码仓库
4. 配置环境变量
5. 运行 `docker-compose up -d`

#### 腾讯云部署

1. 使用云函数 (Serverless)
2. 配置API网关
3. 部署容器服务
4. 配置定时触发器

### 监控和日志

```bash
# 查看实时日志
docker-compose logs -f collector

# 查看特定服务的日志
docker-compose logs analyzer

# 导出日志
docker-compose logs > app.log
```

## 💰 成本估算

### 个人使用 (每月)

| 项目 | 本地部署 | 云部署 (2核2G) |
|------|---------|----------------|
| 服务器 | ¥0 | ¥95-100 |
| 数据库 | ¥0 | ¥0 (PostgreSQL) |
| 数据源 | ¥0 | ¥0 (免费API) |
| 域名 | ¥0 | ¥50 (可选) |
| **总计** | **¥0** | **¥145-150** |

### 企业使用 (每月)

| 项目 | 配置 | 预估成本 |
|------|------|---------|
| 服务器 | 4核8G × 2 | ¥400-600 |
| 数据库 | RDS高可用 | ¥500-800 |
| 负载均衡 | ALB | ¥200-300 |
| CDN | 流量费用 | ¥100-300 |
| 数据源 | 高级API | ¥1000-3000 |
| **总计** | - | **¥2200-5000** |

## ⚠️ 免责声明

- 本服务提供的财经分析和投资建议仅供参考
- 不构成任何投资建议或买卖依据
- 市场有风险，投资需谨慎
- 本服务不对任何投资损失负责
- 请根据自己的风险承受能力做出投资决策

## 📝 开发指南

### 代码规范

详细的代码规范和开发指南请参考 [AGENTS.md](AGENTS.md) 文件。

### 提交规范

使用 Conventional Commits 规范：

```
feat: 添加新功能
fix: 修复bug
docs: 文档更新
style: 代码格式调整
refactor: 代码重构
test: 测试相关
chore: 构建/工具相关
```

## 🤝 贡献指南

欢迎贡献代码、报告问题或提出建议！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: 添加某个特性'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 📞 联系方式

- **项目地址**: [https://github.com/MorseWayne/wealthy_speaker](https://github.com/MorseWayne/wealthy_speaker)
- **问题反馈**: [Issues](https://github.com/MorseWayne/wealthy_speaker/issues)
- **邮箱**: <your.email@example.com>

## 🔗 相关资源

- [项目实施计划](.sisyphus/plans/wealthy-speaker.md)
- [开发指南](AGENTS.md)
- [API文档](docs/API.md) (待完善)
- [部署文档](docs/DEPLOYMENT.md) (待完善)

## 🙏 致谢

感谢所有为本项目做出贡献的开发者和开源项目！

---

**⭐ 如果这个项目对你有帮助，请给个Star！**
