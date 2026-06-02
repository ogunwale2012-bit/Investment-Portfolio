library(readxl)
library(dplyr)
library(quantmod)
library(openxlsx)
library(httr2)
library(jsonlite)

# ============================================
# FILE PATHS
# ============================================

file_path <- "//data3/users5/oogunwale/My Documents/Inv/investment_master_watchlist.xlsx"

# ============================================
# LOAD WORKBOOK ONCE
# ============================================

print("Loading workbook now...")
wb <- loadWorkbook(file_path)
print("Workbook loaded successfully.")

# ============================================
# FRED API KEY
# ============================================

fred_api_key <- "d0b337bec933ed52d05ac52fe73ccb6b"

# ============================================
# FRED FUNCTION
# ============================================

get_fred_latest <- function(series_id) {
  
  print(paste("Pulling FRED series:", series_id))
  
  url <- paste0(
    "https://api.stlouisfed.org/fred/series/observations?",
    "series_id=", series_id,
    "&api_key=", fred_api_key,
    "&file_type=json",
    "&sort_order=desc",
    "&limit=1"
  )
  
  tryCatch({
    response <- httr2::request(url) %>%
      httr2::req_timeout(20) %>%
      httr2::req_perform()
    
    raw_text <- httr2::resp_body_string(response)
    data <- jsonlite::fromJSON(raw_text)
    
    if (length(data$observations) == 0) return(NA)
    
    return(data$observations$value[1])
    
  }, error = function(e) {
    print(paste("FRED error for", series_id, ":", e$message))
    return(NA)
  })
}

# ============================================
# PULL FRED RATES
# ============================================

fred_rates <- data.frame(
  Series_ID = c("FEDFUNDS", "SOFR", "DGS1", "DGS2", "DGS5", "DGS10", "CPIAUCSL"),
  Description = c(
    "Federal Funds Rate",
    "Secured Overnight Financing Rate",
    "1-Year Treasury Yield",
    "2-Year Treasury Yield",
    "5-Year Treasury Yield",
    "10-Year Treasury Yield",
    "Consumer Price Index"
  )
)

print("Starting FRED pull...")

fred_rates$Latest_Value <- sapply(fred_rates$Series_ID, get_fred_latest)
fred_rates$Last_Updated <- Sys.Date()

print("FRED pull complete.")
print(fred_rates)

# ============================================
# WRITE FRED DATA TO FIXED INCOME RATES
# ============================================

if (!"Fixed Income Rates" %in% names(wb)) {
  addWorksheet(wb, "Fixed Income Rates")
}

deleteData(
  wb,
  sheet = "Fixed Income Rates",
  cols = 1:20,
  rows = 1:1000,
  gridExpand = TRUE
)

writeData(
  wb,
  sheet = "Fixed Income Rates",
  x = fred_rates,
  startRow = 1,
  startCol = 1,
  colNames = TRUE
)

print("FRED fixed income rates written to workbook.")
