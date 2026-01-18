from typing import List, Dict
from analyzer.models import InvestmentAdvice
import numpy as np


class InvestmentAdvisor:
    """投资建议生成器"""

    def __init__(self):
        self.risk_levels = ['低风险', '中等风险', '高风险']

    def calculate_market_trend(self, stock_data: List[dict]) -> float:
        """计算市场趋势"""
        if not stock_data:
            return 0.0

        changes = [s.get('change_percent', 0) for s in stock_data]
        avg_change = np.mean(changes)

        return avg_change

    def analyze_market_outlook(self, stock_data: List[dict], sentiment_result: dict) -> str:
        """分析市场前景"""
        sentiment_score = sentiment_result.get('overall_sentiment', 0.5)
        market_trend = self.calculate_market_trend(stock_data)

        if sentiment_score > 0.6 and market_trend > 0:
            return "市场情绪积极，技术面良好，短期内可能继续上涨"
        elif sentiment_score < 0.4 and market_trend < 0:
            return "市场情绪悲观，技术面偏弱，建议谨慎操作"
        elif sentiment_score > 0.6 and market_trend < 0:
            return "市场情绪积极但技术面偏弱，可能存在反弹机会"
        elif sentiment_score < 0.4 and market_trend > 0:
            return "市场情绪悲观但技术面良好，建议观察确认"
        else:
            return "市场情绪中性，技术面震荡，建议观望为主"

    def get_sector_recommendations(self, stock_data: List[dict]) -> List[str]:
        """获取行业推荐"""
        recommendations = []

        if not stock_data:
            return ["建议均衡配置各行业，分散投资风险"]

        positive_stocks = [s for s in stock_data if s.get('change_percent', 0) > 0]
        negative_stocks = [s for s in stock_data if s.get('change_percent', 0) < 0]

        if len(positive_stocks) > len(negative_stocks):
            recommendations.append("市场整体偏强，可适当增加权益类资产配置")
            recommendations.append("科技、新能源等成长板块表现较好，可重点关注")
        elif len(negative_stocks) > len(positive_stocks):
            recommendations.append("市场偏弱，建议控制仓位，注重防御")
            recommendations.append("可关注消费、医药等防御性板块")
        else:
            recommendations.append("市场震荡，建议均衡配置")
            recommendations.append("可适当配置黄金等避险资产")

        return recommendations

    def assess_risk(self, stock_data: List[dict], sentiment_result: dict) -> str:
        """评估风险等级"""
        if not stock_data:
            return self.risk_levels[1]

        volatility = np.std([s.get('change_percent', 0) for s in stock_data])
        sentiment_score = sentiment_result.get('overall_sentiment', 0.5)

        if volatility > 3.0 or sentiment_score < 0.3:
            return self.risk_levels[2]
        elif volatility > 1.5 or sentiment_score < 0.5:
            return self.risk_levels[1]
        else:
            return self.risk_levels[0]

    def get_action_suggestions(self, stock_data: List[dict], risk_level: str) -> List[str]:
        """获取操作建议"""
        suggestions = []

        if not stock_data:
            return ["建议观望，等待更多市场信号"]

        if risk_level == "高风险":
            suggestions.append("严格控制仓位，单只股票仓位不超过总资金的10%")
            suggestions.append("设置好止损位，严格执行纪律")
            suggestions.append("避免追涨杀跌，保持理性")
        elif risk_level == "中等风险":
            suggestions.append("适度控制仓位，建议在50%-70%之间")
            suggestions.append("分批建仓，避免一次性重仓")
            suggestions.append("注意止盈止损，保护利润")
        else:
            suggestions.append("可适当提高仓位至70%-80%")
            suggestions.append("选择基本面良好的标的长期持有")
            suggestions.append("定期调整持仓，保持组合平衡")

        return suggestions

    def generate_advice(self, stock_data: List[dict], sentiment_result: dict) -> InvestmentAdvice:
        """生成投资建议"""
        market_outlook = self.analyze_market_outlook(stock_data, sentiment_result)
        sector_recommendations = self.get_sector_recommendations(stock_data)
        risk_level = self.assess_risk(stock_data, sentiment_result)
        action_suggestions = self.get_action_suggestions(stock_data, risk_level)

        return InvestmentAdvice(
            market_outlook=market_outlook,
            sector_recommendations=sector_recommendations,
            risk_assessment=f"当前市场风险等级：{risk_level}",
            action_suggestions=action_suggestions,
            disclaimer="本建议仅供参考，投资有风险，入市需谨慎。请根据自己的风险承受能力做出投资决策。"
        )
