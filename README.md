# Machine Learning Stock Recommendation Model

## Overview

This project develops a machine learning-based stock recommendation model that classifies U.S. equities into Buy, Hold, and Sell categories using historical stock market data and U.S. interest rate data.

The objective is to combine financial analysis, quantitative methods, and machine learning techniques to support data-driven investment decision-making.


## Project Objective

The model seeks to identify patterns in historical stock performance and macroeconomic conditions that may help predict future stock returns.

Predictions are translated into investment recommendations:

* Buy
* Hold
* Sell

based on expected future stock performance.


## Data Sources

### Yahoo Finance

Stock market data including:

* Historical prices
* Trading volume
* Daily returns

### Federal Reserve Economic Data (FRED)

Macroeconomic indicators including:

* Federal Funds Rate
* Treasury Yields
* Other interest rate indicators


## Features

The model incorporates both market and macroeconomic variables, including:

### Market Features

* Historical stock returns
* Moving averages
* Price momentum
* Trading volume
* Volatility measures

### Macroeconomic Features

* Federal Funds Rate
* Interest rate trends
* Treasury yield indicators


## Machine Learning Approach

The project applies supervised machine learning techniques to classify stocks into Buy, Hold, and Sell categories based on future return outcomes.

Models evaluated may include:

* Logistic Regression
* Random Forest
* Gradient Boosting


## Model Evaluation

Model performance is evaluated using:

* Accuracy
* Precision
* Recall
* F1 Score
* Confusion Matrix


## Tools & Technologies

* R
* Machine Learning
* Yahoo Finance
* Federal Reserve Economic Data (FRED)
* tidyverse
* tidyquant
* caret
* randomForest
* ggplot2
* Git & GitHub


## Repository Structure

```text
Machine-Learning-Stock-Recommendation-Model/
│
├── data/
├── scripts/
├── outputs/
└── README.md
```


## Future Enhancements

* Additional macroeconomic indicators
* Feature importance analysis
* Hyperparameter tuning
* Interactive dashboard for model outputs
* Automated model retraining


## Disclaimer

This project is intended for educational and research purposes only and does not constitute investment advice.
