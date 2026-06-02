## Machine Learning Stock Recommendation Model
Overview
This project builds a machine learning model to evaluate S&P 500 stocks and generate Buy, Hold, or Sell recommendations using historical market data and macroeconomic indicators.
The model screens the top 100–150 S&P 500 stocks, combining price and volume data from Yahoo Finance with U.S. interest rate data from FRED to support data-driven investment decision-making.

## Project Objective
The model seeks to identify patterns in historical stock performance and macroeconomic conditions that may help predict future stock returns.
Predictions are translated into investment recommendations:

Buy
Hold
Sell

based on expected future stock performance.
## Data Sources
This project pulls data from four sources: S&P 500 Ticker List using R's tidyquant

Yahoo Finance - Stock market data including:
Historical prices (Open, High, Low, Close, Adjusted Close)
Trading volume
Daily returns

Calculated Market Features derived from Yahoo Finance data including:
Moving averages (short-term and long-term)
Price momentum
Volatility measures

Federal Reserve Economic Data (FRED) - Macroeconomic indicators including:
Federal Funds Rate
Treasury Yields
Other interest rate indicators

# Features
The model incorporates both market and macroeconomic variables, including:
Market Features:
Historical stock returns
Moving averages
Price momentum
Trading volume
Volatility measures

Macroeconomic Features:
Federal Funds Rate
Interest rate trends
Treasury yield indicators

## Machine Learning Approach
The project applies supervised machine learning techniques to classify stocks into Buy, Hold, and Sell categories based on future return outcomes.
Models evaluated may include:

Logistic Regression
Random Forest
Gradient Boosting

## Model Evaluation
Model performance is evaluated using:

Accuracy
Precision
Recall
F1 Score
Confusion Matrix

## Tools & Technologies

R
Yahoo Finance
Federal Reserve Economic Data (FRED)
tidyverse
tidyquant
caret
randomForest
ggplot2
Git & GitHub



## Disclaimer
This project is intended for educational and research purposes only and does not constitute investment advice.
