import pandas as pd

data = pd.read_csv("../data/stock_data.csv")

def score_stock(row):

    score = 0

    if row["PE"] < 20:
        score += 1
    elif row["PE"] > 40:
        score -= 1

    if row["ROE"] > 0.20:
        score += 1
    elif row["ROE"] < 0.10:
        score -= 1

    if row["Debt_to_Equity"] < 0.7:
        score += 1
    elif row["Debt_to_Equity"] > 1.5:
        score -= 1

    return score


data["Score"] = data.apply(score_stock, axis=1)

def recommendation(score):

    if score >= 2:
        return "BUY"
    elif score <= -2:
        return "SELL"
    else:
        return "HOLD"


data["Recommendation"] = data["Score"].apply(recommendation)

print(data)
