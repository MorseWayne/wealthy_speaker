const express = require('express');
const axios = require('axios');
const cors = require('cors');
const path = require('path');

// 优先使用 ENV_FILE 指定；默认加载仓库根目录 .env（本地运行）
// Docker 场景通常通过环境变量注入，这里加载失败也不影响运行
require('dotenv').config({
  path: process.env.ENV_FILE || path.resolve(__dirname, '..', '..', '.env')
});

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

const DATA_COLLECTOR_URL = process.env.DATA_COLLECTOR_URL || 'http://collector:8080';
const AI_ANALYZER_URL = process.env.AI_ANALYZER_URL || 'http://analyzer:8000';

app.get('/', (req, res) => {
  res.json({
    message: 'Financial Summary Web Admin',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      summaries: '/api/summaries',
      latest: '/api/latest',
      stocks: '/api/stocks',
      news: '/api/news'
    }
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/api/latest', async (req, res) => {
  try {
    const response = await axios.get(`${DATA_COLLECTOR_URL}/api/summary/latest`);
    res.json(response.data);
  } catch (error) {
    console.error('Error fetching latest summary:', error.message);
    res.status(500).json({ error: 'Failed to fetch latest summary' });
  }
});

app.get('/api/summaries', async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    const response = await axios.get(`${DATA_COLLECTOR_URL}/api/summary/list`, {
      params: { limit }
    });
    res.json(response.data);
  } catch (error) {
    console.error('Error fetching summaries:', error.message);
    res.status(500).json({ error: 'Failed to fetch summaries' });
  }
});

app.get('/api/stocks', async (req, res) => {
  try {
    const { symbol, market, limit = 20 } = req.query;
    const response = await axios.get(`${DATA_COLLECTOR_URL}/api/stocks`, {
      params: { symbol, market, limit }
    });
    res.json(response.data);
  } catch (error) {
    console.error('Error fetching stocks:', error.message);
    res.status(500).json({ error: 'Failed to fetch stocks' });
  }
});

app.get('/api/news', async (req, res) => {
  try {
    const { source, limit = 20 } = req.query;
    const response = await axios.get(`${DATA_COLLECTOR_URL}/api/news`, {
      params: { source, limit }
    });
    res.json(response.data);
  } catch (error) {
    console.error('Error fetching news:', error.message);
    res.status(500).json({ error: 'Failed to fetch news' });
  }
});

app.post('/api/analyze', async (req, res) => {
  try {
    const { stockData, newsData } = req.body;

    if (!stockData && !newsData) {
      return res.status(400).json({ error: 'No data provided' });
    }

    const response = await axios.post(`${AI_ANALYZER_URL}/analyze/daily`, {
      stock_data: stockData,
      news_data: newsData
    });
    res.json(response.data);
  } catch (error) {
    console.error('Error analyzing data:', error.message);
    res.status(500).json({ error: 'Failed to analyze data' });
  }
});

app.listen(PORT, () => {
  console.log(`Web Admin server running on port ${PORT}`);
  console.log(`Data Collector URL: ${DATA_COLLECTOR_URL}`);
  console.log(`AI Analyzer URL: ${AI_ANALYZER_URL}`);
});
