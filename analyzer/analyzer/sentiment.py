"""增强版情感分析器 - 集成金融专业词典"""

import jieba
import re
from snownlp import SnowNLP
from typing import List, Dict, Optional
from analyzer.models import SentimentAnalysisResult
from analyzer.financial_lexicon import financial_lexicon


class SentimentAnalyzer:
    """增强版情感分析器 - 结合 SnowNLP 和金融专业词典"""

    def __init__(self):
        """初始化情感分析器"""
        self.lexicon = financial_lexicon
        self._init_jieba()

    def _init_jieba(self):
        """初始化 jieba 分词，添加金融词汇"""
        # 添加正面词汇
        for word in self.lexicon.positive_words.keys():
            jieba.add_word(word)
        # 添加负面词汇
        for word in self.lexicon.negative_words.keys():
            jieba.add_word(word)
        # 添加行业关键词
        for keywords in self.lexicon.industry_keywords.values():
            for word in keywords:
                jieba.add_word(word)

    def clean_text(self, text: str) -> str:
        """清理文本"""
        if not text:
            return ""

        cleaned = re.sub(r'<[^>]+>', '', text)
        cleaned = re.sub(r'\s+', ' ', cleaned)
        cleaned = re.sub(r'[^\u4e00-\u9fa5a-zA-Z0-9\s\.\,\!\?\。\，\！\？]', '', cleaned)
        cleaned = cleaned.strip()
        return cleaned

    def extract_keywords(self, text: str) -> List[str]:
        """提取金融关键词"""
        words = list(jieba.cut(text))
        keywords = []
        
        # 提取正面/负面关键词
        for word in words:
            if word in self.lexicon.positive_words or word in self.lexicon.negative_words:
                if word not in keywords:
                    keywords.append(word)
        
        # 提取行业关键词
        for industry, industry_keywords in self.lexicon.industry_keywords.items():
            for kw in industry_keywords:
                if kw in text and kw not in keywords:
                    keywords.append(kw)
        
        return keywords[:15]  # 限制最多15个关键词

    def analyze_with_lexicon(self, text: str) -> dict:
        """使用金融词典分析文本"""
        return self.lexicon.analyze_text_sentiment(text)

    def get_sentiment_label(self, score: float) -> str:
        """获取情感标签（增强版）"""
        if score >= 0.7:
            return "强烈看多"
        elif score >= 0.6:
            return "看多"
        elif score >= 0.55:
            return "偏多"
        elif score >= 0.45:
            return "中性"
        elif score >= 0.4:
            return "偏空"
        elif score >= 0.3:
            return "看空"
        else:
            return "强烈看空"

    def _combine_scores(self, snownlp_score: float, lexicon_score: float, lexicon_word_count: int) -> float:
        """
        组合 SnowNLP 和词典分数
        词典匹配越多，词典权重越高
        """
        if lexicon_word_count == 0:
            # 没有匹配金融词汇，主要依赖 SnowNLP
            return snownlp_score * 0.8 + 0.5 * 0.2
        elif lexicon_word_count <= 2:
            # 少量匹配，平衡两者
            return snownlp_score * 0.5 + lexicon_score * 0.5
        elif lexicon_word_count <= 5:
            # 中等匹配，偏向词典
            return snownlp_score * 0.3 + lexicon_score * 0.7
        else:
            # 大量匹配，主要依赖词典
            return snownlp_score * 0.2 + lexicon_score * 0.8

    def analyze_news_sentiment(self, news_list: List[dict]) -> SentimentAnalysisResult:
        """分析新闻情感（增强版）"""
        if not news_list:
            return SentimentAnalysisResult(
                overall_sentiment=0.5,
                sentiment_label="中性",
                details=[]
            )

        total_sentiment = 0
        valid_count = 0
        sentiment_details = []
        all_industries = set()

        for news in news_list:
            title = news.get('title', '')
            content = self.clean_text(news.get('content', ''))
            full_text = f"{title} {content}"
            
            if not full_text.strip():
                continue

            # SnowNLP 基础分析
            try:
                s = SnowNLP(full_text)
                snownlp_score = s.sentiments
            except Exception:
                snownlp_score = 0.5

            # 金融词典分析
            lexicon_result = self.analyze_with_lexicon(full_text)
            lexicon_score = lexicon_result['score']
            word_count = lexicon_result['total_keywords']

            # 组合分数
            final_score = self._combine_scores(snownlp_score, lexicon_score, word_count)

            # 收集行业信息
            all_industries.update(lexicon_result.get('detected_industries', []))

            sentiment_details.append({
                'title': title,
                'sentiment': round(final_score, 3),
                'sentiment_label': self.get_sentiment_label(final_score),
                'keywords': self.extract_keywords(full_text),
                'industries': lexicon_result.get('detected_industries', []),
                'snownlp_score': round(snownlp_score, 3),
                'lexicon_score': round(lexicon_score, 3),
                'keyword_count': word_count,
            })

            total_sentiment += final_score
            valid_count += 1

        avg_sentiment = total_sentiment / valid_count if valid_count > 0 else 0.5

        return SentimentAnalysisResult(
            overall_sentiment=round(avg_sentiment, 3),
            sentiment_label=self.get_sentiment_label(avg_sentiment),
            details=sentiment_details
        )

    def analyze_single_text(self, text: str) -> float:
        """分析单条文本情感"""
        cleaned = self.clean_text(text)
        if not cleaned:
            return 0.5

        # SnowNLP 基础分析
        try:
            s = SnowNLP(cleaned)
            snownlp_score = s.sentiments
        except Exception:
            snownlp_score = 0.5

        # 金融词典分析
        lexicon_result = self.analyze_with_lexicon(cleaned)
        lexicon_score = lexicon_result['score']
        word_count = lexicon_result['total_keywords']

        # 组合分数
        final_score = self._combine_scores(snownlp_score, lexicon_score, word_count)

        return round(final_score, 3)

    def get_detailed_analysis(self, text: str) -> dict:
        """获取详细的情感分析结果"""
        cleaned = self.clean_text(text)
        if not cleaned:
            return {
                "score": 0.5,
                "label": "中性",
                "keywords": [],
                "industries": [],
                "details": {}
            }

        # SnowNLP 分析
        try:
            s = SnowNLP(cleaned)
            snownlp_score = s.sentiments
        except Exception:
            snownlp_score = 0.5

        # 金融词典分析
        lexicon_result = self.analyze_with_lexicon(cleaned)

        # 组合分数
        final_score = self._combine_scores(
            snownlp_score, 
            lexicon_result['score'], 
            lexicon_result['total_keywords']
        )

        return {
            "score": round(final_score, 3),
            "label": self.get_sentiment_label(final_score),
            "keywords": self.extract_keywords(cleaned),
            "industries": lexicon_result.get('detected_industries', []),
            "details": {
                "snownlp_score": round(snownlp_score, 3),
                "lexicon_score": round(lexicon_result['score'], 3),
                "positive_words": lexicon_result['positive_count'],
                "negative_words": lexicon_result['negative_count'],
                "found_words": lexicon_result.get('found_words', [])[:5],
            }
        }
