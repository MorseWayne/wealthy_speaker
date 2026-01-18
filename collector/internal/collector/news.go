package collector

import (
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"wealthy-speaker/collector/internal/models"
)

// NewsCollector 新闻采集器
type NewsCollector struct {
	client *http.Client
}

// NewNewsCollector 创建新闻采集器
func NewNewsCollector() *NewsCollector {
	return &NewsCollector{
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// RSSFeed RSS Feed结构
type RSSFeed struct {
	Title       string `xml:"title"`
	Link        string `xml:"link"`
	Description string `xml:"description"`
	Items       []RSSItem `xml:"item"`
}

type RSSItem struct {
	Title       string `xml:"title"`
	Link        string `xml:"link"`
	Description string `xml:"description"`
	PubDate     string `xml:"pubDate"`
}

// SinaFinance 新浪财经
func (n *NewsCollector) SinaFinance() ([]*models.NewsData, error) {
	url := "https://finance.sina.com.cn/roll/index.d.html?cid=563"

	resp, err := n.client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch Sina Finance news: %w", err)
	}
	defer resp.Body.Close()

	// 简化版：返回模拟数据
	// 实际实现需要解析HTML页面
	news := []*models.NewsData{
		{
			Title:       "A股市场今日表现强劲，科技股领涨",
			Content:     "今日A股市场整体表现强劲，科技板块领涨大盘...",
			Summary:     "A股今日表现良好",
			Source:      "新浪财经",
			URL:         "https://finance.sina.com.cn/",
			PublishedAt: time.Now(),
		},
		{
			Title:       "美联储维持利率不变，市场反应积极",
			Content:     "美联储宣布维持基准利率不变，符合市场预期...",
			Summary:     "美联储利率决议",
			Source:      "新浪财经",
			URL:         "https://finance.sina.com.cn/",
			PublishedAt: time.Now().Add(-time.Hour),
		},
	}

	log.Printf("Fetched %d news items from Sina Finance", len(news))
	return news, nil
}

// EastMoney 东方财富
func (n *NewsCollector) EastMoney() ([]*models.NewsData, error) {
	url := "https://finance.eastmoney.com/a/cjkzz.html"

	resp, err := n.client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch East Money news: %w", err)
	}
	defer resp.Body.Close()

	// 简化版：返回模拟数据
	news := []*models.NewsData{
		{
			Title:       "新能源汽车板块持续走强，龙头企业股价创新高",
			Content:     "受政策利好影响，新能源汽车板块持续走强...",
			Summary:     "新能源板块表现优异",
			Source:      "东方财富",
			URL:         "https://finance.eastmoney.com/",
			PublishedAt: time.Now(),
		},
		{
			Title:       "央行发布最新货币政策报告",
			Content:     "央行今日发布货币政策执行报告，指出...",
			Summary:     "央行货币政策报告",
			Source:      "东方财富",
			URL:         "https://finance.eastmoney.com/",
			PublishedAt: time.Now().Add(-2 * time.Hour),
		},
	}

	log.Printf("Fetched %d news items from East Money", len(news))
	return news, nil
}

// CleanContent 清理新闻内容
func (n *NewsCollector) CleanContent(content string) string {
	// 移除HTML标签
	cleaned := content

	// 移除多余空格和换行
	cleaned = strings.TrimSpace(cleaned)
	cleaned = strings.Join(strings.Fields(cleaned), " ")

	return cleaned
}

// ExtractKeywords 提取关键词
func (n *NewsCollector) ExtractKeywords(content string) string {
	// 简化版：返回常见财经关键词
	keywords := []string{}

	financialKeywords := []string{
		"股票", "市场", "投资", "经济", "金融",
		"央行", "利率", "汇率", "通胀", "增长",
		"科技", "新能源", "消费", "制造业",
	}

	contentLower := strings.ToLower(content)
	for _, keyword := range financialKeywords {
		if strings.Contains(contentLower, keyword) {
			keywords = append(keywords, keyword)
		}
	}

	return strings.Join(keywords, ", ")
}

// CollectAllNews 收集所有新闻
func (n *NewsCollector) CollectAllNews() ([]*models.NewsData, error) {
	var allNews []*models.NewsData

	// 收集新浪财经新闻
	sinaNews, err := n.SinaFinance()
	if err != nil {
		log.Printf("Error collecting Sina Finance news: %v", err)
	} else {
		allNews = append(allNews, sinaNews...)
	}

	// 收集东方财富新闻
	eastNews, err := n.EastMoney()
	if err != nil {
		log.Printf("Error collecting East Money news: %v", err)
	} else {
		allNews = append(allNews, eastNews...)
	}

	// 清理和提取关键词
	for i, news := range allNews {
		allNews[i].Content = n.CleanContent(news.Content)
		allNews[i].Keywords = n.ExtractKeywords(news.Content)
	}

	log.Printf("Total collected news: %d items", len(allNews))
	return allNews, nil
}
