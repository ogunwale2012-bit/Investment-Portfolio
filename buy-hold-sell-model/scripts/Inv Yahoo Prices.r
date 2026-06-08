library(readxl)
library(dplyr)
library(quantmod)
library(openxlsx)

# ============================================
# FILE PATHS
# ============================================

file_path <- "//data3/users5/oogunwale/My Documents/Inv/investment_master_watchlist.xlsx"

# ============================================
# LOAD WORKBOOK
# ============================================

print("Loading workbook now...")
wb <- loadWorkbook(file_path)
print("Workbook loaded successfully.")

# ============================================
# READ EQUITY MASTER WATCHLIST
# ============================================

equity_master <- read_excel(
  file_path,
  sheet = "Equity - Master Watchlist"
)

# ============================================
# EXTRACT UNIQUE TICKERS
# Column A = Ticker
# ============================================

tickers <- equity_master %>%
  filter(!is.na(Ticker), Ticker != "") %>%
  mutate(Ticker = trimws(Ticker)) %>%
  distinct(Ticker) %>%
  pull(Ticker)

# ============================================
# YAHOO PRICE FUNCTION
# ============================================

get_yahoo_price <- function(ticker) {
  tryCatch({
    data <- getQuote(ticker)
    as.numeric(data$Last)
  }, error = function(e) {
    NA
  })
}

# ============================================
# PULL YAHOO PRICES
# ============================================

prices <- data.frame(
  Ticker = tickers,
  Current_Price = sapply(tickers, get_yahoo_price)
)

print(prices)

# ============================================
# WRITE CURRENT PRICES TO EQUITY MASTER WATCHLIST
# Column A = Ticker
# Column N = Current Price API
# ============================================

print("Starting price write process...")

for (i in 1:nrow(equity_master)) {
  
  ticker <- equity_master$Ticker[i]
  
  if (!is.na(ticker) && ticker != "") {
    
    ticker <- trimws(ticker)
    
    matched_price <- prices$Current_Price[
      prices$Ticker == ticker
    ]
    
    if (length(matched_price) > 0 && !is.na(matched_price[1])) {
      
      writeData(
        wb,
        sheet = "Equity - Master Watchlist",
        x = matched_price[1],
        startCol = 5,
        startRow = i + 1
      )
    }
  }
}

# ============================================
# WRITE LAST UPDATED TIMESTAMP
# Column Q = Yahoo Price Last Updated
# ============================================

writeData(
  wb,
  sheet = "Equity - Master Watchlist",
  x = format(Sys.time(), "%m/%d/%Y %I:%M %p"),
  startCol = 31,
  startRow = 2
)

print("Finished writing equity master prices.")

# ============================================
# SAVE WORKBOOK
# ============================================

print("Saving workbook...")

saveWorkbook(
  wb,
  file_path,
  overwrite = TRUE
)

print("Workbook saved successfully.")