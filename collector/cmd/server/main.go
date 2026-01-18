package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"wealthy-speaker/collector/internal/api"
	"wealthy-speaker/collector/internal/database"
	"wealthy-speaker/collector/internal/scheduler"

	"github.com/spf13/viper"
)

func main() {
	log.Println("Starting Financial Summary Data Collector Service...")

	// 加载配置
	loadConfig()

	// 初始化数据库
	if err := database.InitDatabase(
		viper.GetString("database.host"),
		viper.GetString("database.port"),
		viper.GetString("database.user"),
		viper.GetString("database.password"),
		viper.GetString("database.name"),
	); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	// 自动迁移
	if err := database.AutoMigrate(); err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	// 创建调度器
	sched := scheduler.NewScheduler(
		viper.GetString("push.wechat_webhook"),
		viper.GetString("push.feishu_webhook"),
	)

	// 启动调度器
	if err := sched.Start(); err != nil {
		log.Fatalf("Failed to start scheduler: %v", err)
	}

	// 创建 API 服务器
	apiServer := api.NewServer(viper.GetString("server.addr"))

	// 在 goroutine 中启动 API 服务器
	go func() {
		if err := apiServer.Start(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start API server: %v", err)
		}
	}()

	log.Println("Data Collector Service is running...")

	// 等待退出信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down...")

	// 优雅关闭 API 服务器
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := apiServer.Shutdown(ctx); err != nil {
		log.Printf("API server shutdown error: %v", err)
	}

	sched.Stop()
	database.CloseDatabase()

	log.Println("Data Collector Service stopped")
}

// loadConfig 加载配置
func loadConfig() {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./config")
	viper.AddConfigPath(".")

	// 设置默认值
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", "5432")
	viper.SetDefault("database.user", "fin_user")
	viper.SetDefault("database.password", "fin_password")
	viper.SetDefault("database.name", "financial_db")
	viper.SetDefault("push.wechat_webhook", "")
	viper.SetDefault("push.feishu_webhook", "")

	// 读取环境变量
	viper.AutomaticEnv()

	// 读取配置文件
	if err := viper.ReadInConfig(); err != nil {
		log.Printf("Warning: Config file not found, using defaults: %v", err)
	}
}
