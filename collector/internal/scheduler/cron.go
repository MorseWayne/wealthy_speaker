package scheduler

import (
	"log"
	"time"

	"wealthy-speaker/collector/internal/collector"
	"wealthy-speaker/collector/internal/database"
	"wealthy-speaker/collector/internal/models"
	"wealthy-speaker/collector/internal/push"

	"github.com/robfig/cron/v3"
)

// Scheduler 定时任务调度器
type Scheduler struct {
	cron          *cron.Cron
	yahooCollector *collector.YahooCollector
	newsCollector  *collector.NewsCollector
	pushManager    *push.PushManager
}

// NewScheduler 创建调度器
func NewScheduler(wechatURL, feishuURL string) *Scheduler {
	return &Scheduler{
		cron:          cron.New(cron.WithSeconds()),
		yahooCollector: collector.NewYahooCollector(),
		newsCollector:  collector.NewNewsCollector(),
		pushManager:    push.NewPushManager(wechatURL, feishuURL),
	}
}

// Start 启动调度器
func (s *Scheduler) Start() error {
	// 每日早上8点执行数据采集和分析
	_, err := s.cron.AddFunc("0 0 8 * * *", func() {
		log.Println("Starting daily financial analysis...")
		s.runDailyAnalysis()
	})
	if err != nil {
		return err
	}

	// 每小时采集一次数据
	_, err = s.cron.AddFunc("0 0 * * * *", func() {
		log.Println("Starting hourly data collection...")
		s.collectHourlyData()
	})
	if err != nil {
		return err
	}

	// 每周日凌晨2点清理过期数据
	_, err = s.cron.AddFunc("0 0 2 * * 0", func() {
		log.Println("Starting data cleanup...")
		s.cleanupExpiredData()
	})
	if err != nil {
		return err
	}

	s.cron.Start()
	log.Println("Scheduler started successfully")
	return nil
}

// Stop 停止调度器
func (s *Scheduler) Stop() {
	log.Println("Stopping scheduler...")
	s.cron.Stop()
}

// runDailyAnalysis 执行每日分析
func (s *Scheduler) runDailyAnalysis() {
	db := database.GetDB()

	// 1. 采集股票数据
	log.Println("Collecting stock data...")
	symbols := []string{
		"AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", // 美股
		"000001.SZ", "000002.SZ", "600000.SH",    // A股
	}
	stocks, err := s.yahooCollector.GetMultipleStocks(symbols, "US")
	if err != nil {
		log.Printf("Error collecting stock data: %v", err)
	} else {
		for _, stock := range stocks {
			db.Create(stock)
		}
		log.Printf("Collected %d stock data items", len(stocks))
	}

	// 2. 采集新闻
	log.Println("Collecting news...")
	news, err := s.newsCollector.CollectAllNews()
	if err != nil {
		log.Printf("Error collecting news: %v", err)
	} else {
		for _, item := range news {
			db.Create(item)
		}
		log.Printf("Collected %d news items", len(news))
	}

	// 3. 生成每日总结 (简化版)
	today := time.Now()
	summary := &models.DailySummary{
		SummaryDate:      today,
		MarketOverview:   "今日市场整体表现良好，科技股领涨，新能源板块持续走强。",
		KeyNews:          "美联储维持利率不变，新能源汽车政策利好，央行发布最新货币政策报告。",
		InvestmentAdvice: "建议关注科技和新能源板块，保持谨慎乐观态度，注意风险控制。",
		RiskLevel:       "中等风险",
	}

	db.Create(summary)
	log.Println("Daily summary created")

	// 4. 推送消息
	if err := s.pushManager.SendDailyReport(summary); err != nil {
		log.Printf("Error sending push notification: %v", err)
	}

	log.Println("Daily analysis completed successfully")
}

// collectHourlyData 采集每小时数据
func (s *Scheduler) collectHourlyData() {
	db := database.GetDB()

	// 采集主要指数数据
	symbols := []string{"AAPL", "MSFT", "GOOGL"}
	stocks, err := s.yahooCollector.GetMultipleStocks(symbols, "US")
	if err != nil {
		log.Printf("Error collecting hourly data: %v", err)
		return
	}

	for _, stock := range stocks {
		db.Create(stock)
	}

	log.Printf("Hourly data collection completed: %d items", len(stocks))
}

// cleanupExpiredData 清理过期数据
func (s *Scheduler) cleanupExpiredData() {
	db := database.GetDB()

	// 清理1个月前的数据
	cutoffDate := time.Now().AddDate(0, -1, 0)

	// 清理股票数据
	result := db.Where("created_at < ?", cutoffDate).Delete(&models.StockData{})
	log.Printf("Cleaned up %d stock data records", result.RowsAffected)

	// 清理新闻数据
	result = db.Where("created_at < ?", cutoffDate).Delete(&models.NewsData{})
	log.Printf("Cleaned up %d news data records", result.RowsAffected)

	log.Println("Data cleanup completed successfully")
}
