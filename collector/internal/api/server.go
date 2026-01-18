package api

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"wealthy-speaker/collector/internal/database"
	"wealthy-speaker/collector/internal/models"

	"github.com/gorilla/mux"
)

// Server HTTP API 服务器
type Server struct {
	router *mux.Router
	srv    *http.Server
}

// HealthResponse 健康检查响应
type HealthResponse struct {
	Status    string `json:"status"`
	Timestamp string `json:"timestamp"`
	Database  string `json:"database"`
	Version   string `json:"version"`
}

// NewServer 创建 API 服务器
func NewServer(addr string) *Server {
	s := &Server{
		router: mux.NewRouter(),
	}

	s.setupRoutes()

	s.srv = &http.Server{
		Addr:         addr,
		Handler:      s.router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	return s
}

// setupRoutes 设置路由
func (s *Server) setupRoutes() {
	s.router.HandleFunc("/", s.handleRoot).Methods("GET")
	s.router.HandleFunc("/health", s.handleHealth).Methods("GET")
	s.router.HandleFunc("/api/summary/latest", s.handleLatestSummary).Methods("GET")
	s.router.HandleFunc("/api/summary/list", s.handleSummaryList).Methods("GET")
	s.router.HandleFunc("/api/stocks", s.handleStocks).Methods("GET")
	s.router.HandleFunc("/api/news", s.handleNews).Methods("GET")
}

// Start 启动服务器
func (s *Server) Start() error {
	log.Printf("Starting API server on %s", s.srv.Addr)
	return s.srv.ListenAndServe()
}

// Shutdown 优雅关闭服务器
func (s *Server) Shutdown(ctx context.Context) error {
	log.Println("Shutting down API server...")
	return s.srv.Shutdown(ctx)
}

// handleRoot 根路由
func (s *Server) handleRoot(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"message": "Financial Summary Data Collector API",
		"version": "1.0.0",
		"endpoints": map[string]string{
			"health": "/health",
			"latest": "/api/summary/latest",
			"list":   "/api/summary/list",
			"stocks": "/api/stocks",
			"news":   "/api/news",
		},
	}
	s.jsonResponse(w, http.StatusOK, response)
}

// handleHealth 健康检查
func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	dbStatus := "healthy"

	// 检查数据库连接
	db := database.GetDB()
	if db == nil {
		dbStatus = "disconnected"
	} else {
		sqlDB, err := db.DB()
		if err != nil || sqlDB.Ping() != nil {
			dbStatus = "unhealthy"
		}
	}

	status := "healthy"
	statusCode := http.StatusOK
	if dbStatus != "healthy" {
		status = "unhealthy"
		statusCode = http.StatusServiceUnavailable
	}

	response := HealthResponse{
		Status:    status,
		Timestamp: time.Now().Format(time.RFC3339),
		Database:  dbStatus,
		Version:   "1.0.0",
	}

	s.jsonResponse(w, statusCode, response)
}

// handleLatestSummary 获取最新总结
func (s *Server) handleLatestSummary(w http.ResponseWriter, r *http.Request) {
	db := database.GetDB()
	if db == nil {
		s.errorResponse(w, http.StatusInternalServerError, "Database not available")
		return
	}

	var summary models.DailySummary
	result := db.Order("created_at DESC").First(&summary)
	if result.Error != nil {
		s.errorResponse(w, http.StatusNotFound, "No summary found")
		return
	}

	s.jsonResponse(w, http.StatusOK, summary)
}

// handleSummaryList 获取总结列表
func (s *Server) handleSummaryList(w http.ResponseWriter, r *http.Request) {
	db := database.GetDB()
	if db == nil {
		s.errorResponse(w, http.StatusInternalServerError, "Database not available")
		return
	}

	limit := 10
	if l := r.URL.Query().Get("limit"); l != "" {
		if _, err := json.Number(l).Int64(); err == nil {
			limit = int(mustParseInt(l, 10))
		}
	}

	var summaries []models.DailySummary
	db.Order("created_at DESC").Limit(limit).Find(&summaries)

	s.jsonResponse(w, http.StatusOK, summaries)
}

// handleStocks 获取股票数据
func (s *Server) handleStocks(w http.ResponseWriter, r *http.Request) {
	db := database.GetDB()
	if db == nil {
		s.errorResponse(w, http.StatusInternalServerError, "Database not available")
		return
	}

	query := db.Model(&models.StockData{})

	if symbol := r.URL.Query().Get("symbol"); symbol != "" {
		query = query.Where("symbol = ?", symbol)
	}
	if market := r.URL.Query().Get("market"); market != "" {
		query = query.Where("market = ?", market)
	}

	limit := mustParseInt(r.URL.Query().Get("limit"), 20)

	var stocks []models.StockData
	query.Order("created_at DESC").Limit(limit).Find(&stocks)

	s.jsonResponse(w, http.StatusOK, stocks)
}

// handleNews 获取新闻数据
func (s *Server) handleNews(w http.ResponseWriter, r *http.Request) {
	db := database.GetDB()
	if db == nil {
		s.errorResponse(w, http.StatusInternalServerError, "Database not available")
		return
	}

	query := db.Model(&models.NewsData{})

	if source := r.URL.Query().Get("source"); source != "" {
		query = query.Where("source = ?", source)
	}

	limit := mustParseInt(r.URL.Query().Get("limit"), 20)

	var news []models.NewsData
	query.Order("created_at DESC").Limit(limit).Find(&news)

	s.jsonResponse(w, http.StatusOK, news)
}

// jsonResponse 发送 JSON 响应
func (s *Server) jsonResponse(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

// errorResponse 发送错误响应
func (s *Server) errorResponse(w http.ResponseWriter, status int, message string) {
	s.jsonResponse(w, status, map[string]string{"error": message})
}

// mustParseInt 解析整数，失败返回默认值
func mustParseInt(s string, defaultVal int) int {
	if s == "" {
		return defaultVal
	}
	var n int
	if _, err := json.Number(s).Int64(); err == nil {
		n64, _ := json.Number(s).Int64()
		n = int(n64)
		if n > 0 {
			return n
		}
	}
	return defaultVal
}
