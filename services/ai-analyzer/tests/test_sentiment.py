"""情感分析器测试模块"""

import pytest
from analyzer.sentiment import SentimentAnalyzer
from analyzer.models import SentimentAnalysisResult
from analyzer.financial_lexicon import FinancialLexicon, financial_lexicon


class TestFinancialLexicon:
    """金融词典测试"""

    def test_lexicon_initialization(self):
        """测试词典初始化"""
        lexicon = FinancialLexicon()
        assert len(lexicon.positive_words) > 0
        assert len(lexicon.negative_words) > 0
        assert len(lexicon.neutral_words) > 0
        assert len(lexicon.industry_keywords) > 0

    def test_positive_words_scoring(self):
        """测试正面词汇评分"""
        lexicon = FinancialLexicon()
        
        # 强烈正面词汇应该有高分
        assert lexicon.positive_words.get("暴涨", 0) >= 0.9
        assert lexicon.positive_words.get("涨停", 0) >= 0.8
        
        # 温和正面词汇应该有中等分数
        assert 0.5 <= lexicon.positive_words.get("企稳", 0.5) <= 0.7

    def test_negative_words_scoring(self):
        """测试负面词汇评分"""
        lexicon = FinancialLexicon()
        
        # 强烈负面词汇应该有低分
        assert lexicon.negative_words.get("暴跌", 0.5) <= 0.1
        assert lexicon.negative_words.get("崩盘", 0.5) <= 0.1
        
        # 温和负面词汇应该有中等分数
        assert 0.3 <= lexicon.negative_words.get("震荡", 0.5) <= 0.5

    def test_get_word_sentiment(self):
        """测试词汇情感获取"""
        lexicon = FinancialLexicon()
        
        score, sentiment_type = lexicon.get_word_sentiment("上涨")
        assert sentiment_type == "positive"
        assert score > 0.5
        
        score, sentiment_type = lexicon.get_word_sentiment("下跌")
        assert sentiment_type == "negative"
        assert score < 0.5
        
        score, sentiment_type = lexicon.get_word_sentiment("未知词汇")
        assert sentiment_type == "unknown"
        assert score == 0.5

    def test_analyze_text_sentiment(self):
        """测试文本情感分析"""
        lexicon = FinancialLexicon()
        
        # 正面文本
        positive_result = lexicon.analyze_text_sentiment("股市大涨，利好消息不断，投资者信心增强")
        assert positive_result["score"] > 0.5
        assert positive_result["positive_count"] > 0
        assert positive_result["sentiment_label"] in ["看多", "强烈看多", "偏多"]
        
        # 负面文本
        negative_result = lexicon.analyze_text_sentiment("市场暴跌，恐慌情绪蔓延，投资者纷纷抛售")
        assert negative_result["score"] < 0.5
        assert negative_result["negative_count"] > 0
        assert negative_result["sentiment_label"] in ["看空", "强烈看空", "偏空"]

    def test_industry_detection(self):
        """测试行业识别"""
        lexicon = FinancialLexicon()
        
        tech_text = "芯片和人工智能板块持续走强"
        result = lexicon.analyze_text_sentiment(tech_text)
        assert "科技" in result["detected_industries"]
        
        energy_text = "光伏和锂电池概念股大涨"
        result = lexicon.analyze_text_sentiment(energy_text)
        assert "新能源" in result["detected_industries"]


class TestSentimentAnalyzer:
    """情感分析器测试"""

    def test_analyzer_initialization(self):
        """测试情感分析器初始化"""
        analyzer = SentimentAnalyzer()
        assert analyzer.lexicon is not None
        assert hasattr(analyzer, 'clean_text')
        assert hasattr(analyzer, 'analyze_news_sentiment')

    def test_clean_text(self):
        """测试文本清理"""
        analyzer = SentimentAnalyzer()
        
        # HTML标签清理
        text = "<p>测试  文本</p>"
        cleaned = analyzer.clean_text(text)
        assert "<" not in cleaned
        assert ">" not in cleaned
        
        # 空文本处理
        assert analyzer.clean_text("") == ""

    def test_extract_keywords(self):
        """测试关键词提取"""
        analyzer = SentimentAnalyzer()
        
        text = "今日股市上涨，科技股表现强劲，利好消息不断"
        keywords = analyzer.extract_keywords(text)
        
        assert isinstance(keywords, list)
        # 应该能提取到金融相关关键词
        assert len(keywords) > 0

    def test_analyze_single_text(self):
        """测试单条文本分析"""
        analyzer = SentimentAnalyzer()
        
        # 正面文本
        positive_score = analyzer.analyze_single_text("市场大涨，利好消息不断")
        assert 0.0 <= positive_score <= 1.0
        assert positive_score > 0.5
        
        # 负面文本
        negative_score = analyzer.analyze_single_text("市场暴跌，恐慌情绪蔓延")
        assert 0.0 <= negative_score <= 1.0
        assert negative_score < 0.5

    def test_analyze_news_sentiment_empty(self):
        """测试空新闻列表分析"""
        analyzer = SentimentAnalyzer()
        
        result = analyzer.analyze_news_sentiment([])
        
        assert isinstance(result, SentimentAnalysisResult)
        assert result.overall_sentiment == 0.5
        assert result.sentiment_label == "中性"
        assert len(result.details) == 0

    def test_analyze_news_sentiment_single(self):
        """测试单条新闻分析"""
        analyzer = SentimentAnalyzer()
        
        news_list = [
            {
                'title': '科技股大涨',
                'content': '今日科技板块表现强劲，多只股票涨停，投资者信心增强'
            }
        ]
        
        result = analyzer.analyze_news_sentiment(news_list)
        
        assert isinstance(result, SentimentAnalysisResult)
        assert 0.0 <= result.overall_sentiment <= 1.0
        assert result.sentiment_label in ["强烈看多", "看多", "偏多", "中性", "偏空", "看空", "强烈看空"]
        assert len(result.details) == 1

    def test_get_sentiment_label(self):
        """测试情感标签获取"""
        analyzer = SentimentAnalyzer()
        
        assert analyzer.get_sentiment_label(0.85) == "强烈看多"
        assert analyzer.get_sentiment_label(0.65) == "看多"
        assert analyzer.get_sentiment_label(0.57) == "偏多"
        assert analyzer.get_sentiment_label(0.50) == "中性"
        assert analyzer.get_sentiment_label(0.42) == "偏空"
        assert analyzer.get_sentiment_label(0.35) == "看空"
        assert analyzer.get_sentiment_label(0.15) == "强烈看空"

    def test_get_detailed_analysis(self):
        """测试详细分析结果"""
        analyzer = SentimentAnalyzer()
        
        result = analyzer.get_detailed_analysis("科技股大涨，芯片板块利好")
        
        assert "score" in result
        assert "label" in result
        assert "keywords" in result
        assert "industries" in result
        assert "details" in result
        assert 0.0 <= result["score"] <= 1.0


class TestEdgeCases:
    """边界情况测试"""

    def test_special_characters(self):
        """测试特殊字符处理"""
        analyzer = SentimentAnalyzer()
        
        text = "股市上涨！！！利好消息"
        score = analyzer.analyze_single_text(text)
        assert 0.0 <= score <= 1.0

    def test_very_long_text(self):
        """测试长文本处理"""
        analyzer = SentimentAnalyzer()
        
        text = "股市上涨，利好消息。" * 100
        score = analyzer.analyze_single_text(text)
        assert 0.0 <= score <= 1.0

    def test_mixed_language(self):
        """测试中英混合文本"""
        analyzer = SentimentAnalyzer()
        
        text = "AAPL stock 上涨，Apple 利好消息"
        score = analyzer.analyze_single_text(text)
        assert 0.0 <= score <= 1.0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
