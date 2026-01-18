package collector

import (
	"encoding/json"
	"fmt"
	"log"
	"time"

	"financial-summary/data-collector/internal/models"

	"github.com/go-resty/resty/v2"
)

// YahooCollector Yahoo Finance数据采集器
type YahooCollector struct {
	client *resty.Client
}

// NewYahooCollector 创建Yahoo Finance采集器
func NewYahooCollector() *YahooCollector {
	return &YahooCollector{
		client: resty.New().
			SetTimeout(30 * time.Second).
			SetRetryCount(3),
	}
}

// YahooResponse Yahoo Finance API响应结构
type YahooResponse struct {
	Chart struct {
		Result []struct {
			Meta struct {
				Symbol    string `json:"symbol"`
				Exchange  string `json:"exchange"`
				InstrumentType string `json:"instrumentType"`
			} `json:"meta"`
			Timestamp  []int64 `json:"timestamp"`
			Indicators struct {
				Quote []struct {
					Close []float64 `json:"close"`
					Open  []float64 `json:"open"`
					High  []float64 `json:"high"`
					Low   []float64 `json:"low"`
					Volume []int64 `json:"volume"`
				} `json:"quote"`
			} `json:"indicators"`
		} `json:"result"`
		Error interface{} `json:"error"`
	} `json:"chart"`
}

// GetStockData 获取股票数据
func (y *YahooCollector) GetStockData(symbol string, market string) (*models.StockData, error) {
	url := fmt.Sprintf("https://query1.finance.yahoo.com/v8/finance/chart/%s", symbol)

	resp, err := y.client.R().
		SetQueryParam("interval", "1d").
		SetQueryParam("range", "5d").
		SetHeader("User-Agent", "Mozilla/5.0").
		Get(url)

	if err != nil {
		return nil, fmt.Errorf("failed to fetch stock data: %w", err)
	}

	var result YahooResponse
	if err := json.Unmarshal(resp.Body(), &result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	if len(result.Chart.Result) == 0 {
		return nil, fmt.Errorf("no data found for symbol %s", symbol)
	}

	chartData := result.Chart.Result[0]
	if len(chartData.Timestamp) == 0 {
		return nil, fmt.Errorf("no timestamp data for symbol %s", symbol)
	}

	quotes := chartData.Indicators.Quote[0]
	lastIndex := len(chartData.Timestamp) - 1

	previousPrice := quotes.Close[lastIndex-1]
	currentPrice := quotes.Close[lastIndex]
	changePercent := ((currentPrice - previousPrice) / previousPrice) * 100

	stockData := &models.StockData{
		Symbol:        symbol,
		Market:        market,
		Price:         currentPrice,
		ChangePercent: changePercent,
		Volume:        quotes.Volume[lastIndex],
		Open:          quotes.Open[lastIndex],
		High:          quotes.High[lastIndex],
		Low:           quotes.Low[lastIndex],
		Close:         quotes.Close[lastIndex],
		Timestamp:     time.Unix(chartData.Timestamp[lastIndex], 0),
	}

	log.Printf("Successfully fetched stock data for %s: %.2f (%.2f%%)", symbol, currentPrice, changePercent)

	return stockData, nil
}

// GetMultipleStocks 批量获取股票数据
func (y *YahooCollector) GetMultipleStocks(symbols []string, market string) ([]*models.StockData, error) {
	var stocks []*models.StockData

	for _, symbol := range symbols {
		stock, err := y.GetStockData(symbol, market)
		if err != nil {
			log.Printf("Error fetching %s: %v", symbol, err)
			continue
		}
		stocks = append(stocks, stock)
	}

	return stocks, nil
}
