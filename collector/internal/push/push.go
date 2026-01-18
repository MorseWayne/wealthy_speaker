package push

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"wealthy-speaker/collector/internal/models"
)

// WeChatPusher 微信推送服务
type WeChatPusher struct {
	WebhookURL string
}

// WeChatMessage 微信消息结构
type WeChatMessage struct {
	MsgType  string `json:"msgtype"`
	Markdown struct {
		Content string `json:"content"`
	} `json:"markdown"`
}

// NewWeChatPusher 创建微信推送器
func NewWeChatPusher(webhookURL string) *WeChatPusher {
	return &WeChatPusher{
		WebhookURL: webhookURL,
	}
}

// SendDailyReport 发送每日报告
func (w *WeChatPusher) SendDailyReport(report *models.DailySummary) error {
	if w.WebhookURL == "" {
		log.Println("WeChat webhook URL not configured, skipping push")
		return nil
	}

	message := w.formatMessage(report)

	payload, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	resp, err := http.Post(w.WebhookURL, "application/json", bytes.NewBuffer(payload))
	if err != nil {
		return fmt.Errorf("failed to send WeChat message: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("WeChat API returned status code: %d", resp.StatusCode)
	}

	log.Println("WeChat daily report sent successfully")
	return nil
}

// formatMessage 格式化消息
func (w *WeChatPusher) formatMessage(report *models.DailySummary) WeChatMessage {
	content := fmt.Sprintf(`# 📊 每日财经总结

## 🏛️ 市场概况
%s

## 📰 重要新闻
%s

## 💡 投资建议
%s

## ⚠️ 风险提示
投资有风险，入市需谨慎。本报告仅供参考，不构成任何投资建议。

---
*生成时间: %s*`,
		report.MarketOverview,
		report.KeyNews,
		report.InvestmentAdvice,
		report.CreatedAt.Format("2006-01-02 15:04:05"),
	)

	return WeChatMessage{
		MsgType: "markdown",
		Markdown: struct {
			Content string `json:"content"`
		}{Content: content},
	}
}

// FeishuPusher 飞书推送服务
type FeishuPusher struct {
	WebhookURL string
}

// FeishuMessage 飞书消息结构
type FeishuMessage struct {
	MsgType string `json:"msg_type"`
	Content struct {
		Text string `json:"text"`
	} `json:"content"`
}

// NewFeishuPusher 创建飞书推送器
func NewFeishuPusher(webhookURL string) *FeishuPusher {
	return &FeishuPusher{
		WebhookURL: webhookURL,
	}
}

// SendDailyReport 发送每日报告
func (f *FeishuPusher) SendDailyReport(report *models.DailySummary) error {
	if f.WebhookURL == "" {
		log.Println("Feishu webhook URL not configured, skipping push")
		return nil
	}

	message := FeishuMessage{
		MsgType: "text",
		Content: struct {
			Text string `json:"text"`
		}{
			Text: f.formatTextMessage(report),
		},
	}

	payload, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	resp, err := http.Post(f.WebhookURL, "application/json", bytes.NewBuffer(payload))
	if err != nil {
		return fmt.Errorf("failed to send Feishu message: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("Feishu API returned status code: %d", resp.StatusCode)
	}

	log.Println("Feishu daily report sent successfully")
	return nil
}

// formatTextMessage 格式化文本消息
func (f *FeishuPusher) formatTextMessage(report *models.DailySummary) string {
	return fmt.Sprintf(`📊 每日财经总结

🏛️ 市场概况:
%s

📰 重要新闻:
%s

💡 投资建议:
%s

⚠️ 风险提示:
投资有风险，入市需谨慎。本报告仅供参考，不构成任何投资建议。

---
生成时间: %s`,
		report.MarketOverview,
		report.KeyNews,
		report.InvestmentAdvice,
		report.CreatedAt.Format("2006-01-02 15:04:05"),
	)
}

// PushManager 推送管理器
type PushManager struct {
	wechat *WeChatPusher
	feishu *FeishuPusher
}

// NewPushManager 创建推送管理器
func NewPushManager(wechatURL, feishuURL string) *PushManager {
	return &PushManager{
		wechat: NewWeChatPusher(wechatURL),
		feishu: NewFeishuPusher(feishuURL),
	}
}

// SendDailyReport 发送每日报告到所有配置的渠道
func (p *PushManager) SendDailyReport(report *models.DailySummary) error {
	// 发送到微信
	if err := p.wechat.SendDailyReport(report); err != nil {
		log.Printf("Failed to send WeChat message: %v", err)
	}

	// 发送到飞书
	if err := p.feishu.SendDailyReport(report); err != nil {
		log.Printf("Failed to send Feishu message: %v", err)
	}

	return nil
}
