from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime


class StockData(BaseModel):
    """股票数据模型"""
    id: int
    symbol: str
    market: str
    price: float
    change_percent: float
    volume: int
    open: float
    high: float
    low: float
    close: float
    timestamp: datetime
    created_at: datetime


class NewsData(BaseModel):
    """新闻数据模型"""
    id: int
    title: str
    content: str
    summary: str
    source: str
    url: str
    published_at: datetime
    sentiment_score: float
    keywords: str
    created_at: datetime


class DailySummary(BaseModel):
    """每日总结模型"""
    id: int
    summary_date: datetime
    market_overview: str
    key_news: str
    investment_advice: str
    technical_analysis: str
    sentiment_analysis: str
    risk_level: str
    chart_url: Optional[str] = None
    created_at: datetime


class SentimentAnalysisResult(BaseModel):
    """情感分析结果"""
    overall_sentiment: float
    sentiment_label: str
    details: List[dict]


class InvestmentAdvice(BaseModel):
    """投资建议"""
    market_outlook: str
    sector_recommendations: List[str]
    risk_assessment: str
    action_suggestions: List[str]
    disclaimer: str
