/**
 * Financial Dashboard - Main Application
 */

class FinancialDashboard {
  constructor() {
    this.currentTab = 'today';
    this.theme = localStorage.getItem('theme') || 'light';
    this.init();
  }

  init() {
    this.applyTheme();
    this.bindEvents();
    this.loadTab('today');
    this.startHealthCheck();
  }

  // Theme Management
  applyTheme() {
    document.documentElement.setAttribute('data-theme', this.theme);
    this.updateThemeButton();
  }

  toggleTheme() {
    this.theme = this.theme === 'light' ? 'dark' : 'light';
    localStorage.setItem('theme', this.theme);
    this.applyTheme();
  }

  updateThemeButton() {
    const btn = document.getElementById('themeToggle');
    if (btn) {
      btn.innerHTML = this.theme === 'light' 
        ? '&#9790; Dark' 
        : '&#9728; Light';
    }
  }

  // Health Check
  startHealthCheck() {
    this.checkHealth();
    setInterval(() => this.checkHealth(), 30000);
  }

  async checkHealth() {
    const statusDot = document.getElementById('statusDot');
    const statusText = document.getElementById('statusText');
    
    try {
      const response = await fetch('/health');
      const data = await response.json();
      
      if (statusDot && statusText) {
        statusDot.style.background = data.status === 'healthy' ? '#10b981' : '#ef4444';
        statusText.textContent = data.status === 'healthy' ? 'Online' : 'Offline';
      }
    } catch (error) {
      if (statusDot && statusText) {
        statusDot.style.background = '#ef4444';
        statusText.textContent = 'Offline';
      }
    }
  }

  // Event Binding
  bindEvents() {
    const themeBtn = document.getElementById('themeToggle');
    if (themeBtn) {
      themeBtn.addEventListener('click', () => this.toggleTheme());
    }

    document.querySelectorAll('.nav-tab').forEach(tab => {
      tab.addEventListener('click', (e) => {
        const tabName = e.currentTarget.dataset.tab;
        this.loadTab(tabName);
      });
    });

    document.addEventListener('click', (e) => {
      if (e.target.matches('.btn-refresh') || e.target.closest('.btn-refresh')) {
        this.loadTab(this.currentTab);
      }
    });
  }

  // Tab Management
  setActiveTab(tabName) {
    document.querySelectorAll('.nav-tab').forEach(tab => {
      tab.classList.toggle('active', tab.dataset.tab === tabName);
    });
    this.currentTab = tabName;
  }

  async loadTab(tabName) {
    this.setActiveTab(tabName);
    this.showLoading();

    try {
      switch (tabName) {
        case 'today':
          await this.loadTodaySummary();
          break;
        case 'history':
          await this.loadHistory();
          break;
        case 'stocks':
          await this.loadStocks();
          break;
        case 'news':
          await this.loadNews();
          break;
        default:
          await this.loadTodaySummary();
      }
    } catch (error) {
      this.showError(error.message);
    }
  }

  // Loading & Error States
  showLoading() {
    const content = document.getElementById('content');
    content.innerHTML = `
      <div class="loading">
        <div class="loading-spinner"></div>
        <span class="loading-text">Loading...</span>
      </div>
    `;
  }

  showError(message) {
    const content = document.getElementById('content');
    content.innerHTML = `
      <div class="error">
        <span class="error-icon">&#9888;</span>
        <span>Error: ${this.escapeHtml(message)}</span>
      </div>
    `;
  }

  showEmpty(message = 'No data available') {
    const content = document.getElementById('content');
    content.innerHTML = `
      <div class="empty-state">
        <div class="icon">&#128202;</div>
        <p>${message}</p>
      </div>
    `;
  }

  // API Calls
  async fetchData(url) {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    return response.json();
  }

  // Today's Summary
  async loadTodaySummary() {
    const content = document.getElementById('content');
    
    try {
      const data = await this.fetchData('/api/latest');
      
      if (!data || data.error) {
        content.innerHTML = this.renderTodayEmpty();
        return;
      }
      content.innerHTML = this.renderTodaySummary(data);
    } catch (error) {
      content.innerHTML = this.renderTodayEmpty();
    }
  }

  renderTodayEmpty() {
    return `
      <div class="stats-grid">
        ${this.renderStatCard('Status', '--', '')}
        ${this.renderStatCard('Sentiment', '--', '')}
        ${this.renderStatCard('Risk', '--', '')}
        ${this.renderStatCard('Updated', '--', '')}
      </div>
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">&#128202; Today's Summary</h3>
          <button class="btn btn-success btn-refresh">&#8635; Refresh</button>
        </div>
        <div class="card-body">
          <div class="empty-state">
            <div class="icon">&#128202;</div>
            <p>No summary available. Data generates at 08:00 daily.</p>
          </div>
        </div>
      </div>
    `;
  }

  renderTodaySummary(data) {
    const date = data.summary_date ? new Date(data.summary_date).toLocaleDateString('zh-CN') : 'Today';
    
    return `
      <div class="stats-grid">
        ${this.renderStatCard('Status', 'Active', 'positive')}
        ${this.renderStatCard('Sentiment', this.getSentimentLabel(data), this.getSentimentClass(data))}
        ${this.renderStatCard('Risk', data.risk_level || 'Medium', this.getRiskClass(data.risk_level))}
        ${this.renderStatCard('Updated', date, '')}
      </div>
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">&#128202; Daily Summary</h3>
          <div>
            <span class="badge ${this.getRiskBadgeClass(data.risk_level)}">${data.risk_level || 'Medium'}</span>
            <button class="btn btn-success btn-refresh" style="margin-left: 12px;">&#8635; Refresh</button>
          </div>
        </div>
        <div class="card-body">
          <div class="summary-item">
            <div class="summary-date">&#128197; ${date}</div>
            <div class="summary-section">
              <h4>&#127970; Market Overview</h4>
              <p>${this.escapeHtml(data.market_overview || 'No data')}</p>
            </div>
            <div class="summary-section">
              <h4>&#128240; Key News</h4>
              <p>${this.escapeHtml(data.key_news || 'No data')}</p>
            </div>
            <div class="summary-section">
              <h4>&#128161; Investment Advice</h4>
              <p>${this.escapeHtml(data.investment_advice || 'No data')}</p>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  // History
  async loadHistory() {
    const data = await this.fetchData('/api/summaries?limit=10');
    const content = document.getElementById('content');

    if (!data || !Array.isArray(data) || data.length === 0) {
      this.showEmpty('No historical data');
      return;
    }

    let html = `
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">&#128214; History</h3>
          <button class="btn btn-success btn-refresh">&#8635; Refresh</button>
        </div>
        <div class="card-body">
    `;

    data.forEach(s => {
      const date = s.summary_date ? new Date(s.summary_date).toLocaleDateString('zh-CN') : '--';
      html += `
        <div class="summary-item">
          <div class="summary-date">${date} <span class="badge ${this.getRiskBadgeClass(s.risk_level)}">${s.risk_level || 'N/A'}</span></div>
          <p>${this.escapeHtml(s.market_overview || 'No data')}</p>
        </div>
      `;
    });

    html += '</div></div>';
    content.innerHTML = html;
  }

  // Stocks
  async loadStocks() {
    const data = await this.fetchData('/api/stocks?limit=20');
    const content = document.getElementById('content');

    if (!data || !Array.isArray(data) || data.length === 0) {
      this.showEmpty('No stock data');
      return;
    }

    let html = `
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">&#128200; Stocks</h3>
          <button class="btn btn-success btn-refresh">&#8635; Refresh</button>
        </div>
        <div class="card-body">
          <div class="table-container">
            <table class="data-table">
              <thead>
                <tr>
                  <th>Symbol</th>
                  <th>Market</th>
                  <th class="text-right">Price</th>
                  <th class="text-right">Change</th>
                  <th class="text-right">Volume</th>
                </tr>
              </thead>
              <tbody>
    `;

    data.forEach(stock => {
      const changeClass = (stock.change_percent || 0) >= 0 ? 'positive' : 'negative';
      const prefix = (stock.change_percent || 0) >= 0 ? '+' : '';
      
      html += `
        <tr>
          <td class="symbol">${this.escapeHtml(stock.symbol || 'N/A')}</td>
          <td>${this.escapeHtml(stock.market || 'N/A')}</td>
          <td class="text-right">${this.formatNumber(stock.price, 2)}</td>
          <td class="text-right ${changeClass}">${prefix}${this.formatNumber(stock.change_percent, 2)}%</td>
          <td class="text-right">${this.formatVolume(stock.volume)}</td>
        </tr>
      `;
    });

    html += '</tbody></table></div></div></div>';
    content.innerHTML = html;
  }

  // News
  async loadNews() {
    const data = await this.fetchData('/api/news?limit=15');
    const content = document.getElementById('content');

    if (!data || !Array.isArray(data) || data.length === 0) {
      this.showEmpty('No news data');
      return;
    }

    let html = `
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">&#128240; News</h3>
          <button class="btn btn-success btn-refresh">&#8635; Refresh</button>
        </div>
        <div class="card-body" style="padding: 0;">
    `;

    data.forEach(item => {
      const date = item.published_at ? new Date(item.published_at).toLocaleDateString('zh-CN') : '--';
      const sentimentClass = this.getNewsSentimentClass(item.sentiment_score);
      const summary = item.summary || (item.content ? item.content.substring(0, 150) + '...' : 'No content');
      
      html += `
        <div class="news-item">
          <div class="news-header">
            <span class="news-title">${this.escapeHtml(item.title || 'Untitled')}</span>
            <span class="sentiment-indicator ${sentimentClass}">${this.formatNumber(item.sentiment_score, 2)}</span>
          </div>
          <div class="news-content">${this.escapeHtml(summary)}</div>
          <div class="news-meta">
            <span>&#128197; ${date}</span>
            <span>&#128196; ${this.escapeHtml(item.source || 'Unknown')}</span>
          </div>
        </div>
      `;
    });

    html += '</div></div>';
    content.innerHTML = html;
  }

  // Helper Methods
  renderStatCard(label, value, changeClass) {
    return `
      <div class="stat-card">
        <span class="label">${label}</span>
        <span class="value">${value}</span>
        ${changeClass ? `<span class="change ${changeClass}"></span>` : ''}
      </div>
    `;
  }

  escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  formatNumber(num, decimals = 2) {
    if (num === null || num === undefined || isNaN(num)) return '--';
    return Number(num).toFixed(decimals);
  }

  formatVolume(vol) {
    if (!vol) return '--';
    if (vol >= 1e9) return (vol / 1e9).toFixed(2) + 'B';
    if (vol >= 1e6) return (vol / 1e6).toFixed(2) + 'M';
    if (vol >= 1e3) return (vol / 1e3).toFixed(2) + 'K';
    return vol.toString();
  }

  getSentimentLabel(data) {
    if (!data || !data.sentiment_analysis) return 'Neutral';
    const score = data.sentiment_analysis.overall_sentiment || 0.5;
    if (score >= 0.6) return 'Bullish';
    if (score <= 0.4) return 'Bearish';
    return 'Neutral';
  }

  getSentimentClass(data) {
    if (!data || !data.sentiment_analysis) return '';
    const score = data.sentiment_analysis.overall_sentiment || 0.5;
    if (score >= 0.6) return 'positive';
    if (score <= 0.4) return 'negative';
    return '';
  }

  getNewsSentimentClass(score) {
    if (score === null || score === undefined) return 'sentiment-neutral';
    if (score >= 0.6) return 'sentiment-positive';
    if (score <= 0.4) return 'sentiment-negative';
    return 'sentiment-neutral';
  }

  getRiskClass(level) {
    if (!level) return '';
    const l = level.toLowerCase();
    if (l.includes('低') || l.includes('low')) return 'positive';
    if (l.includes('高') || l.includes('high')) return 'negative';
    return '';
  }

  getRiskBadgeClass(level) {
    if (!level) return 'badge-warning';
    const l = level.toLowerCase();
    if (l.includes('低') || l.includes('low')) return 'badge-success';
    if (l.includes('高') || l.includes('high')) return 'badge-danger';
    return 'badge-warning';
  }
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
  window.dashboard = new FinancialDashboard();
});
