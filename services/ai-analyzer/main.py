from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic_settings import BaseSettings
from typing import List, Optional
import uvicorn
import os

from analyzer.models import StockData, NewsData, DailySummary, SentimentAnalysisResult, InvestmentAdvice
from analyzer.sentiment import SentimentAnalyzer
from analyzer.advisor import InvestmentAdvisor


class Settings(BaseSettings):
    """应用配置"""
    database_url: str = "postgresql://fin_user:fin_password@postgres:5432/financial_db"
    host: str = "0.0.0.0"
    port: int = 8000

    class Config:
        env_file = ".env"


app = FastAPI(title="Financial AI Analyzer API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

sentiment_analyzer = SentimentAnalyzer()
investment_advisor = InvestmentAdvisor()


@app.get("/")
async def root():
    return {"message": "Financial AI Analyzer API", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.post("/analyze/sentiment", response_model=SentimentAnalysisResult)
async def analyze_sentiment(news_list: List[dict]):
    """分析新闻情感"""
    if not news_list:
        raise HTTPException(status_code=400, detail="News list is empty")

    result = sentiment_analyzer.analyze_news_sentiment(news_list)
    return result


@app.post("/analyze/advice", response_model=InvestmentAdvice)
async def generate_advice(stock_data: List[dict], sentiment_result: dict):
    """生成投资建议"""
    if not stock_data:
        raise HTTPException(status_code=400, detail="Stock data is empty")

    advice = investment_advisor.generate_advice(stock_data, sentiment_result)
    return advice


@app.post("/analyze/daily", response_model=DailySummary)
async def generate_daily_summary(stock_data: List[dict], news_data: List[dict]):
    """生成每日财经总结"""
    if not stock_data and not news_data:
        raise HTTPException(status_code=400, detail="No data provided")

    sentiment_result = sentiment_analyzer.analyze_news_sentiment(news_data)
    advice = investment_advisor.generate_advice(stock_data, sentiment_result.dict())

    from datetime import datetime

    summary = DailySummary(
        id=1,
        summary_date=datetime.now(),
        market_overview=advice.market_outlook,
        key_news="基于最新财经新闻分析",
        investment_advice=f"{advice.risk_assessment}\n{chr(10).join(advice.action_suggestions)}",
        technical_analysis=str([{'trend': '上涨' if s.get('change_percent', 0) > 0 else '下跌'} for s in stock_data]),
        sentiment_analysis=sentiment_result.dict(),
        risk_level=advice.risk_assessment.split("：")[1] if "：" in advice.risk_assessment else "中等风险",
        created_at=datetime.now()
    )

    return summary


@app.get("/analyze/single")
async def analyze_single_text(text: str):
    """分析单条文本情感"""
    if not text:
        raise HTTPException(status_code=400, detail="Text is empty")

    score = sentiment_analyzer.analyze_single_text(text)
    return {
        "sentiment_score": score,
        "sentiment_label": sentiment_analyzer.get_sentiment_label(score)
    }


if __name__ == "__main__":
    settings = Settings()
    uvicorn.run(app, host=settings.host, port=settings.port)
