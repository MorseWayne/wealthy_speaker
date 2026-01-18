"""金融专业词典模块 - 增强版情感分析"""

from typing import Dict, List, Tuple


class FinancialLexicon:
    """金融专业词典"""
    
    def __init__(self):
        self.positive_words = self._load_positive_words()
        self.negative_words = self._load_negative_words()
        self.neutral_words = self._load_neutral_words()
        self.industry_keywords = self._load_industry_keywords()
        self.market_indicators = self._load_market_indicators()
        self.sentiment_modifiers = self._load_sentiment_modifiers()
    
    def _load_positive_words(self) -> Dict[str, float]:
        """加载正面词汇及其权重"""
        return {
            # 强烈正面 (0.8-1.0)
            "暴涨": 0.95, "大涨": 0.9, "飙升": 0.95, "井喷": 0.9,
            "创新高": 0.85, "历史新高": 0.9, "涨停": 0.85, "连续涨停": 0.95,
            "强势": 0.8, "突破": 0.75, "反弹": 0.7, "回升": 0.65,
            
            # 正面 (0.6-0.8)
            "上涨": 0.7, "上升": 0.65, "增长": 0.7, "利好": 0.75,
            "看涨": 0.7, "买入": 0.65, "增持": 0.7, "推荐": 0.65,
            "盈利": 0.7, "获利": 0.65, "收益": 0.6, "红利": 0.65,
            "分红": 0.65, "派息": 0.6, "业绩增长": 0.75, "超预期": 0.8,
            
            # 温和正面 (0.5-0.6)
            "企稳": 0.55, "稳健": 0.55, "复苏": 0.6, "回暖": 0.6,
            "乐观": 0.6, "向好": 0.55, "改善": 0.55, "提振": 0.6,
            "利多": 0.6, "支撑": 0.55, "机会": 0.55, "潜力": 0.6,
            
            # 政策正面
            "降息": 0.7, "降准": 0.7, "宽松": 0.65, "刺激": 0.6,
            "减税": 0.7, "补贴": 0.65, "扶持": 0.65, "鼓励": 0.6,
            
            # 市场信心
            "牛市": 0.85, "多头": 0.7, "做多": 0.65, "加仓": 0.65,
            "吸筹": 0.6, "主力进场": 0.7, "资金流入": 0.7, "北向资金流入": 0.75,
        }
    
    def _load_negative_words(self) -> Dict[str, float]:
        """加载负面词汇及其权重"""
        return {
            # 强烈负面 (0.0-0.2)
            "暴跌": 0.05, "崩盘": 0.0, "跳水": 0.1, "闪崩": 0.05,
            "跌停": 0.1, "连续跌停": 0.0, "熔断": 0.05, "恐慌": 0.1,
            "爆仓": 0.05, "踩踏": 0.1, "血洗": 0.05, "腰斩": 0.1,
            
            # 负面 (0.2-0.4)
            "下跌": 0.3, "下滑": 0.35, "下行": 0.35, "利空": 0.25,
            "看跌": 0.3, "卖出": 0.35, "减持": 0.3, "抛售": 0.25,
            "亏损": 0.25, "损失": 0.3, "赔钱": 0.2, "套牢": 0.25,
            "业绩下滑": 0.25, "不及预期": 0.3, "业绩暴雷": 0.15,
            
            # 温和负面 (0.4-0.5)
            "震荡": 0.45, "调整": 0.45, "回调": 0.45, "走弱": 0.4,
            "承压": 0.4, "疲软": 0.4, "低迷": 0.35, "萎靡": 0.35,
            "谨慎": 0.45, "观望": 0.45, "风险": 0.4, "不确定": 0.45,
            
            # 政策负面
            "加息": 0.35, "收紧": 0.35, "监管": 0.4, "限制": 0.35,
            "整顿": 0.35, "打压": 0.25, "处罚": 0.3, "退市": 0.2,
            
            # 市场恐慌
            "熊市": 0.15, "空头": 0.3, "做空": 0.35, "减仓": 0.35,
            "出逃": 0.25, "资金流出": 0.3, "北向资金流出": 0.25, "外资撤离": 0.2,
        }
    
    def _load_neutral_words(self) -> List[str]:
        """加载中性词汇"""
        return [
            "横盘", "整理", "盘整", "窄幅波动", "平稳",
            "维持", "持平", "不变", "持续", "保持",
            "关注", "留意", "注意", "跟踪", "观察",
        ]
    
    def _load_industry_keywords(self) -> Dict[str, List[str]]:
        """加载行业关键词"""
        return {
            "科技": ["芯片", "半导体", "人工智能", "AI", "大数据", "云计算", "5G", "物联网", "软件", "互联网"],
            "新能源": ["光伏", "风电", "锂电池", "储能", "氢能", "电动车", "充电桩", "碳中和", "绿色能源"],
            "消费": ["白酒", "食品饮料", "家电", "零售", "电商", "旅游", "餐饮", "化妆品", "服装"],
            "医药": ["医疗器械", "创新药", "疫苗", "中药", "生物医药", "CXO", "医美", "健康"],
            "金融": ["银行", "保险", "券商", "信托", "基金", "资管", "金融科技", "支付"],
            "地产": ["房地产", "物业", "建材", "装修", "家居", "钢铁", "水泥"],
            "制造": ["汽车", "机械", "航空", "军工", "造船", "工程机械", "智能制造"],
        }
    
    def _load_market_indicators(self) -> Dict[str, str]:
        """加载市场指标"""
        return {
            "上证指数": "A股",
            "深证成指": "A股",
            "创业板指": "A股",
            "科创50": "A股",
            "沪深300": "A股",
            "中证500": "A股",
            "恒生指数": "港股",
            "恒生科技": "港股",
            "纳斯达克": "美股",
            "道琼斯": "美股",
            "标普500": "美股",
        }
    
    def _load_sentiment_modifiers(self) -> Dict[str, float]:
        """加载情感修饰词"""
        return {
            # 程度加强
            "非常": 1.3, "极其": 1.4, "极度": 1.5, "严重": 1.3,
            "大幅": 1.3, "显著": 1.2, "明显": 1.2, "持续": 1.1,
            
            # 程度减弱
            "略微": 0.7, "稍微": 0.7, "小幅": 0.8, "轻微": 0.7,
            "可能": 0.8, "或许": 0.8, "也许": 0.8, "预计": 0.9,
            
            # 否定
            "不": -1.0, "没有": -1.0, "未": -1.0, "非": -1.0,
        }
    
    def get_word_sentiment(self, word: str) -> Tuple[float, str]:
        """
        获取词汇的情感分数和类型
        返回: (分数, 类型) - 类型为 'positive', 'negative', 'neutral'
        """
        if word in self.positive_words:
            return (self.positive_words[word], "positive")
        elif word in self.negative_words:
            return (self.negative_words[word], "negative")
        elif word in self.neutral_words:
            return (0.5, "neutral")
        return (0.5, "unknown")
    
    def analyze_text_sentiment(self, text: str) -> dict:
        """
        分析文本的金融情感
        返回详细的情感分析结果
        """
        positive_count = 0
        negative_count = 0
        neutral_count = 0
        total_score = 0
        word_count = 0
        found_words = []
        
        # 检查正面词
        for word, score in self.positive_words.items():
            if word in text:
                count = text.count(word)
                positive_count += count
                total_score += score * count
                word_count += count
                found_words.append({"word": word, "score": score, "type": "positive", "count": count})
        
        # 检查负面词
        for word, score in self.negative_words.items():
            if word in text:
                count = text.count(word)
                negative_count += count
                total_score += score * count
                word_count += count
                found_words.append({"word": word, "score": score, "type": "negative", "count": count})
        
        # 检查中性词
        for word in self.neutral_words:
            if word in text:
                count = text.count(word)
                neutral_count += count
                total_score += 0.5 * count
                word_count += count
        
        # 检查修饰词对情感的影响
        modifier_effect = 1.0
        for modifier, effect in self.sentiment_modifiers.items():
            if modifier in text:
                if effect == -1.0:
                    # 否定词反转情感
                    modifier_effect *= -1
                else:
                    modifier_effect *= effect
        
        # 计算平均分数
        if word_count > 0:
            avg_score = total_score / word_count
            # 应用修饰词效果
            if modifier_effect < 0:
                avg_score = 1 - avg_score  # 反转情感
            else:
                avg_score = avg_score * (modifier_effect ** 0.3)  # 温和调整
            avg_score = max(0, min(1, avg_score))  # 限制在 0-1 范围
        else:
            avg_score = 0.5
        
        # 识别行业
        detected_industries = []
        for industry, keywords in self.industry_keywords.items():
            for keyword in keywords:
                if keyword in text:
                    if industry not in detected_industries:
                        detected_industries.append(industry)
                    break
        
        return {
            "score": avg_score,
            "positive_count": positive_count,
            "negative_count": negative_count,
            "neutral_count": neutral_count,
            "total_keywords": word_count,
            "found_words": sorted(found_words, key=lambda x: abs(x["score"] - 0.5), reverse=True)[:10],
            "detected_industries": detected_industries,
            "sentiment_label": self._get_label(avg_score),
        }
    
    def _get_label(self, score: float) -> str:
        """根据分数获取情感标签"""
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


# 全局词典实例
financial_lexicon = FinancialLexicon()
