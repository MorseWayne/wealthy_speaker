# AGENTS.md - Development Guidelines for Financial Summary Service

This file contains guidelines for agentic coding agents working on the financial summary service repository.

## Build Commands

### Go Services (Data Collector)
```bash
cd services/data-collector

# Build
go build -o bin/financial-service cmd/server/main.go

# Run tests
go test ./...

# Run single test
go test -run TestSpecificFunction ./internal/collector

# Lint (requires golangci-lint)
golangci-lint run

# Format code
go fmt ./...

# Vet code
go vet ./...
```

### Python AI Engine
```bash
cd services/ai-analyzer

# Install dependencies
pip install -r requirements.txt

# Run tests
pytest

# Run single test
pytest tests/test_sentiment.py::test_sentiment_analyzer_initialization

# Run tests with coverage
pytest --cov=analyzer --cov-report=html

# Lint
flake8 analyzer/
black analyzer/
```

### Node.js Web Interface
```bash
cd services/web-admin

# Install dependencies
npm install

# Run tests
npm test

# Lint
npm run lint

# Format code
npm run format

# Build
npm run build
```

## Code Style Guidelines

### Go Code Style

#### Imports
Use standard format: stdlib, third-party, local packages. Group imports with blank lines between groups.

```go
import (
    "time"

    "github.com/gin-gonic/gin"
    "github.com/robfig/cron/v3"

    "financial-summary/data-collector/internal/models"
)
```

#### Naming Conventions
- **Packages**: lowercase, short (e.g., `collector`, `models`)
- **Constants**: `UPPER_SNAKE_CASE`
- **Variables**: `camelCase` for local, `PascalCase` for exported
- **Functions**: `camelCase` for local, `PascalCase` for exported
- **Interfaces**: `PascalCase` ending with `er`

#### Error Handling
Always handle errors explicitly. Use `fmt.Errorf` for error wrapping. Return errors as last return value.

```go
func CollectData(symbol string) (*StockData, error) {
    data, err := fetchFromAPI(symbol)
    if err != nil {
        return nil, fmt.Errorf("failed to collect data: %w", err)
    }
    return data, nil
}
```

### Python Code Style

#### Imports
Use absolute imports. Group imports: stdlib, third-party, local.

```python
import os
from datetime import datetime

import pandas as pd
import requests

from analyzer.sentiment import SentimentAnalyzer
from analyzer.models import NewsData
```

#### Naming Conventions
- **Variables/Functions**: `snake_case`
- **Classes**: `PascalCase`
- **Constants**: `UPPER_SNAKE_CASE`

#### Type Hints
Use type hints for all function signatures.

```python
from typing import Optional, List

def analyze_sentiment(text: str) -> Optional[float]:
    if not text:
        return None
    return calculate_sentiment(text)
```

### Node.js Code Style

#### Imports
Use ES6 import/export syntax.

```javascript
import express from 'express';
import axios from 'axios';

import { StockData } from '../types';
```

#### Naming Conventions
- **Variables/Functions**: `camelCase`
- **Classes/Components**: `PascalCase`
- **Constants**: `UPPER_SNAKE_CASE`
- **Files**: `kebab-case`

#### Error Handling
Use async/await with try/catch.

```javascript
async function fetchStock(symbol) {
    try {
        const response = await axios.get(`/api/stocks/${symbol}`);
        return response.data;
    } catch (error) {
        console.error(`Failed to fetch stock: ${error.message}`);
        throw error;
    }
}
```

## Testing Guidelines

### Go Testing
Use table-driven tests for multiple scenarios. Test both success and error cases.

```go
func TestCollectData(t *testing.T) {
    tests := []struct {
        name   string
        symbol string
        want   *StockData
        wantErr bool
    }{
        {"valid symbol", "AAPL", &StockData{Symbol: "AAPL"}, false},
        {"invalid symbol", "", nil, true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := CollectData(tt.symbol)
            if (err != nil) != tt.wantErr {
                t.Errorf("error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

### Python Testing
Use pytest fixtures for setup. Parametrize tests for multiple inputs.

```python
import pytest
from analyzer.sentiment import SentimentAnalyzer

def test_sentiment_analysis():
    analyzer = SentimentAnalyzer()
    text = "市场上涨，利好消息"
    score = analyzer.analyze_single_text(text)
    assert 0.5 <= score <= 1.0
```

## Docker Guidelines

### Multi-stage Builds
Use multi-stage builds for Go services to minimize image size.

```dockerfile
FROM golang:1.21-alpine AS builder
# Build stage
FROM alpine:latest
# Runtime stage
```

### Environment Variables
Use `.env` files for configuration. Never commit secrets.

## Development Workflow

1. Follow code style guidelines
2. Write tests for new functionality
3. Run tests before committing
4. Use conventional commit messages
5. Update documentation

## API Documentation

See [README.md](README.md) for API usage and deployment instructions.
