package models

import (
	"time"
)

// StockData 股票数据模型
type StockData struct {
	ID            uint      `json:"id" gorm:"primaryKey"`
	Symbol        string    `json:"symbol" gorm:"size:20;not null;index"`
	Market        string    `json:"market" gorm:"size:10;not null"`
	Price         float64   `json:"price" gorm:"type:decimal(10,2)"`
	ChangePercent float64   `json:"change_percent" gorm:"type:decimal(5,2)"`
	Volume        int64     `json:"volume"`
	Open          float64   `json:"open" gorm:"type:decimal(10,2)"`
	High          float64   `json:"high" gorm:"type:decimal(10,2)"`
	Low           float64   `json:"low" gorm:"type:decimal(10,2)"`
	Close         float64   `json:"close" gorm:"type:decimal(10,2)"`
	Timestamp     time.Time `json:"timestamp"`
	CreatedAt     time.Time `json:"created_at" gorm:"autoCreateTime"`
}

// NewsData 新闻数据模型
type NewsData struct {
	ID            uint      `json:"id" gorm:"primaryKey"`
	Title         string    `json:"title" gorm:"type:text;not null"`
	Content       string    `json:"content" gorm:"type:text"`
	Summary       string    `json:"summary" gorm:"type:text"`
	Source        string    `json:"source" gorm:"size:100"`
	URL           string    `json:"url" gorm:"type:text"`
	PublishedAt   time.Time `json:"published_at"`
	SentimentScore float64  `json:"sentiment_score" gorm:"type:decimal(3,2)"`
	Keywords      string    `json:"keywords" gorm:"type:text"`
	CreatedAt     time.Time `json:"created_at" gorm:"autoCreateTime"`
}

// DailySummary 每日总结模型
type DailySummary struct {
	ID               uint      `json:"id" gorm:"primaryKey"`
	SummaryDate      time.Time `json:"summary_date" gorm:"uniqueIndex"`
	MarketOverview   string    `json:"market_overview" gorm:"type:text"`
	KeyNews          string    `json:"key_news" gorm:"type:text"`
	InvestmentAdvice string    `json:"investment_advice" gorm:"type:text"`
	TechnicalAnalysis string   `json:"technical_analysis" gorm:"type:jsonb"`
	SentimentAnalysis string  `json:"sentiment_analysis" gorm:"type:jsonb"`
	RiskLevel       string    `json:"risk_level" gorm:"size:20"`
	ChartURL        string    `json:"chart_url" gorm:"size:500"`
	CreatedAt       time.Time `json:"created_at" gorm:"autoCreateTime"`
}

// Config 配置模型
type Config struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Key       string    `json:"key" gorm:"size:100;uniqueIndex;not null"`
	Value     string    `json:"value" gorm:"type:text"`
	CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt time.Time `json:"updated_at" gorm:"autoUpdateTime"`
}

// TableName 指定表名
func (StockData) TableName() string {
	return "stock_data"
}

func (NewsData) TableName() string {
	return "news_data"
}

func (DailySummary) TableName() string {
	return "daily_summaries"
}

func (Config) TableName() string {
	return "configs"
}
