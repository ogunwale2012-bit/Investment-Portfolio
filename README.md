# Machine Learning Equity Recommendation Model

## Overview

This project builds a machine learning model to evaluate S&P 500 stocks and generate Buy, Hold, or Sell recommendations using historical market data and macroeconomic indicators.

The model screens a subset of approximately 100–150 S&P 500 companies and combines stock price and volume data from Yahoo Finance with U.S. interest rate data from the Federal Reserve Economic Data (FRED) database. Interest rate variables are included to capture the impact of monetary policy and financing conditions on equity market performance.

The objective is to apply machine learning techniques to identify patterns associated with future stock returns and support data-driven investment decision-making.

---

## Project Objective

The model seeks to identify relationships between historical stock performance, market conditions, and future stock returns.

Predictions are translated into investment recommendations:

* **Buy**
* **Hold**
* **Sell**

based on expected future stock performance over a defined investment horizon.

---

## Data Sources

### S&P 500 Ticker List

The model uses a subset of S&P 500 companies as the investment universe.

### Yahoo Finance

Stock market data includes:

* Open, High, Low, Close, and Adjusted Close prices
* Trading volume
* Historical daily returns

### Federal Reserve Economic Data (FRED)

Macroeconomic data includes selected U.S. interest rate indicators such as:

* Federal Funds Rate
* Treasury yield indicators
* Interest rate trends

---

## Feature Engineering

The model incorporates both market-based and macroeconomic features.

### Market Features

* Historical stock returns
* Short-term and long-term moving averages
* Price momentum
* Trading volume
* Volatility measures

### Macroeconomic Features

* Federal Funds Rate
* Treasury yield indicators
* Interest rate changes and trends

---

## Machine Learning Approach

This project applies supervised machine learning techniques to classify stocks into Buy, Hold, and Sell categories based on future return outcomes.

Models evaluated include:

* Logistic Regression
* Random Forest
* Gradient Boosting

---

## Model Evaluation

Model performance is evaluated using classification metrics, including:

* Accuracy
* Precision
* Recall
* F1 Score
* Confusion Matrix

---

## Tools & Technologies

* R
* Yahoo Finance
* Federal Reserve Economic Data (FRED)
* tidyverse
* tidyquant
* caret
* randomForest
* ggplot2
* Git & GitHub

---

## Repository Structure

```text
Machine-Learning-Equity-Recommendation-Model/
│
├── data/
├── scripts/
├── outputs/
└── README.md
```

---

## Disclaimer

This project is intended for educational and research purposes only and does not constitute investment advice.

