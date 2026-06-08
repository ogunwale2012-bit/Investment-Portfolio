library(readxl)
library(dplyr)
library(quantmod)
library(openxlsx)
library(httr2)
library(jsonlite)

# ============================================
# FILE PATHS
# ============================================

file_path        <- "//data3/users5/oogunwale/My Documents/Inv/investment_master_watchlist.xlsx"
fixed_income_file <- "//data3/users5/oogunwale/My Documents/Inv/Fidelity_FixedIncome_NewIssues.csv"

# ============================================
# LOAD WORKBOOK ONCE
# ============================================

print("Loading workbook now...")
wb <- loadWorkbook(file_path)
print("Workbook loaded successfully.")

# ============================================
# FIXED INCOME MASTER UPDATE
# ============================================

sheet_name <- "Fixed Income - Master Watchlist"

# ============================================
# READ EXISTING MASTER FIRST
# ============================================

if (sheet_name %in% names(wb)) {
  
  existing_master <- read.xlsx(
    file_path,
    sheet = sheet_name,
    check.names = FALSE
  )
  
  names(existing_master) <- trimws(names(existing_master))
  
} else {
  
  addWorksheet(wb, sheet_name)
  existing_master <- data.frame()
  
}

# ============================================
# STANDARDIZE EXISTING HOLDING COLUMN NAME
# ============================================

holding_col <- names(existing_master)[
  grepl("^Existing Holding\\??$", names(existing_master), ignore.case = TRUE)
]

if (length(holding_col) > 0) {
  names(existing_master)[names(existing_master) == holding_col[1]] <- "Existing Holding"
}

# ============================================
# PRESERVE EXISTING HOLDINGS
# ============================================

if (nrow(existing_master) > 0 && "Existing Holding" %in% names(existing_master)) {
  
  preserved_holdings <- existing_master %>%
    filter(grepl("^yes$", trimws(`Existing Holding`), ignore.case = TRUE))
  
} else {
  
  preserved_holdings <- data.frame()
  
}

# ============================================
# READ FIDELITY FIXED INCOME FILE
# ============================================

fixed_income_new <- read.csv(
  fixed_income_file,
  check.names = FALSE
)

names(fixed_income_new) <- trimws(names(fixed_income_new))

# ============================================
# REMOVE FOOTER / DISCLAIMER ROWS
# ============================================

footer_start <- which(
  grepl(
    "The data and information|Brokerage services|Custody and other services|Date downloaded",
    fixed_income_new$Description,
    ignore.case = TRUE
  )
)

if (length(footer_start) > 0) {
  fixed_income_new <- fixed_income_new[1:(min(footer_start) - 1), ]
}

fixed_income_new <- fixed_income_new %>%
  filter(
    !is.na(Description),
    Description != "",
    !is.na(Coupon),
    Coupon != "",
    !is.na(`Maturity Date`),
    `Maturity Date` != ""
  )

# ============================================
# CREATE SECURITY_ID
# ============================================

fixed_income_new <- fixed_income_new %>%
  mutate(
    Security_ID = paste(
      trimws(Description),
      trimws(as.character(Coupon)),
      trimws(as.character(`Coupon Frequency`)),
      trimws(as.character(`Maturity Date`)),
      sep = " | "
    ),
    Source        = "Fidelity New Issues",
    Download_Date = format(Sys.Date(), "%m/%d/%Y"),
    New_Issue_Flag = "Current Download"
  )

# ============================================
# PRESERVE MANUAL COLUMNS
# ============================================

manual_cols <- c("Existing Holding")

for (col in manual_cols) {
  if (!col %in% names(fixed_income_new)) {
    fixed_income_new[[col]] <- "No"
  }
}

if (nrow(existing_master) > 0 && "Security_ID" %in% names(existing_master)) {
  
  existing_manual <- existing_master %>%
    select(any_of(c("Security_ID", manual_cols)))
  
  fixed_income_new <- fixed_income_new %>%
    left_join(
      existing_manual,
      by = "Security_ID",
      suffix = c("", "_old")
    )
  
  for (col in manual_cols) {
    old_col <- paste0(col, "_old")
    
    if (old_col %in% names(fixed_income_new)) {
      fixed_income_new[[col]] <- ifelse(
        !is.na(fixed_income_new[[old_col]]) &
          fixed_income_new[[old_col]] != "",
        fixed_income_new[[old_col]],
        fixed_income_new[[col]]
      )
      fixed_income_new[[old_col]] <- NULL
    }
  }
}

# ============================================
# COMBINE NEW ISSUES + EXISTING HOLDINGS
# Existing Holding = Yes rows come first and are preserved
# ============================================

combined_fixed_income <- bind_rows(
  preserved_holdings,
  fixed_income_new
) %>%
  distinct(Security_ID, .keep_all = TRUE)

old_ids <- if (
  nrow(existing_master) > 0 &&
  "Security_ID" %in% names(existing_master)
) {
  existing_master$Security_ID
} else {
  character(0)
}

combined_fixed_income <- combined_fixed_income %>%
  mutate(
    Newly_Added = ifelse(Security_ID %in% old_ids, "No", "Yes")
  )

# ============================================
# DURATION BUCKETS
# ============================================

combined_fixed_income <- combined_fixed_income %>%
  mutate(
    Maturity_Date_Clean = as.Date(
      `Maturity Date`,
      format = "%m/%d/%Y"
    ),
    Years_To_Maturity = as.numeric(Maturity_Date_Clean - Sys.Date()) / 365,
    Duration_Bucket = case_when(
      Years_To_Maturity <= 1 ~ "0-1 Year",
      Years_To_Maturity <= 3 ~ "1-3 Years",
      Years_To_Maturity <= 5 ~ "3-5 Years",
      TRUE                   ~ "5+ Years"
    )
  )

# ============================================
# BENCHMARK MAPPING
# ============================================

combined_fixed_income <- combined_fixed_income %>%
  mutate(
    Benchmark_Used = case_when(
      Duration_Bucket == "0-1 Year"   ~ "1-Year Treasury Yield",
      Duration_Bucket == "1-3 Years"  ~ "2-Year Treasury Yield",
      Duration_Bucket == "3-5 Years"  ~ "5-Year Treasury Yield",
      TRUE                            ~ "10-Year Treasury Yield"
    )
  )

# ============================================
# READ FRED RATES FROM WORKBOOK
# ============================================

fred_rates <- read.xlsx(
  file_path,
  sheet = "Fixed Income Rates",
  check.names = FALSE
)

names(fred_rates) <- trimws(names(fred_rates))

# ============================================
# PULL BENCHMARK RATE FROM FRED TABLE
# ============================================

combined_fixed_income <- combined_fixed_income %>%
  left_join(
    fred_rates %>% select(Description, Latest_Value),
    by = c("Benchmark_Used" = "Description")
  ) %>%
  rename(Benchmark_Rate = Latest_Value) %>%
  mutate(Benchmark_Rate = as.numeric(Benchmark_Rate))

# ============================================
# CALCULATE SPREAD — single calculation using Coupon_Numeric
# (fixes duplicate spread bug from previous version)
# ============================================

combined_fixed_income <- combined_fixed_income %>%
  mutate(
    Coupon_Numeric = suppressWarnings(as.numeric(Coupon)),
    Yield_Spread   = Coupon_Numeric - Benchmark_Rate
  )

# ============================================
# SPREAD ASSESSMENT
# ============================================

combined_fixed_income <- combined_fixed_income %>%
  mutate(
    Spread_Assessment = case_when(
      Yield_Spread >= 1.0 ~ "Excellent",
      Yield_Spread >= 0.5 ~ "Good",
      Yield_Spread >= 0.2 ~ "Fair",
      Yield_Spread >= 0   ~ "Neutral",
      TRUE                ~ "Unattractive"
    )
  )

# ============================================
# RATING RISK LEVEL
# ============================================

combined_fixed_income <- combined_fixed_income %>%
  mutate(
    Rating_Risk_Level = case_when(
      grepl("^Aaa|^AAA",       `Moody's Rating`) ~ "Very Low",
      grepl("^Aa|^AA",         `Moody's Rating`) ~ "Low",
      grepl("^A",              `Moody's Rating`) ~ "Low-Medium",
      grepl("^Baa|^BBB",       `Moody's Rating`) ~ "Medium",
      grepl("^Ba|^BB",         `Moody's Rating`) ~ "High",
      grepl("^B|^C",           `Moody's Rating`) ~ "Very High",
      TRUE                                        ~ "Review"
    )
  )

# ============================================
# FIXED INCOME SCORECARD
# ============================================

combined_fixed_income <- combined_fixed_income %>%
  mutate(

    # --- Spread Score ---
    # Rewards yield attractiveness vs Treasury benchmark
    Spread_Score = case_when(
      Yield_Spread >= 1.0 ~  3,
      Yield_Spread >= 0.5 ~  2,
      Yield_Spread >= 0.2 ~  1,
      Yield_Spread >= 0   ~  0,
      TRUE                ~ -2
    ),

    # --- Rating Score ---
    Rating_Score = case_when(
      Rating_Risk_Level %in% c("Very Low", "Low") ~  2,
      Rating_Risk_Level == "Low-Medium"            ~  1,
      Rating_Risk_Level == "Medium"                ~  0,
      Rating_Risk_Level %in% c("High","Very High") ~ -2,
      TRUE                                         ~ -1   # unrated = slight caution
    ),

    # --- Call Protection Score ---
    # Less binary — uncallable bonds with good spreads are not penalised as harshly
    Call_Score = case_when(
      `Call Protected` == "Yes"                         ~  1,  # call protection is a positive
      `Call Protected` == "No" & Yield_Spread >= 0.5   ~  0,  # no protection but well compensated
      `Call Protected` == "No" & Yield_Spread >= 0.2   ~ -1,  # some compensation but exposed
      `Call Protected` == "No"                          ~ -2,  # no protection + poor spread
      TRUE                                              ~  0
    ),

    # --- Duration Score — rate environment aware ---
    # Short term is only good if the yield beats the benchmark
    # Long term is only penalised if the spread doesn't compensate for rate risk
    Duration_Score = case_when(

      # 0-1 Year: reward only if spread is meaningful vs 1Y Treasury
      Duration_Bucket == "0-1 Year" & Yield_Spread >= 0.2  ~  2,
      Duration_Bucket == "0-1 Year" & Yield_Spread >= 0    ~  1,
      Duration_Bucket == "0-1 Year" & Yield_Spread <  0    ~ -1,  # below benchmark = avoid

      # 1-3 Years: neutral range, spread drives the score
      Duration_Bucket == "1-3 Years" & Yield_Spread >= 0.3 ~  2,
      Duration_Bucket == "1-3 Years" & Yield_Spread >= 0   ~  1,
      Duration_Bucket == "1-3 Years" & Yield_Spread <  0   ~ -1,

      # 3-5 Years: penalise only if spread doesn't justify duration risk
      Duration_Bucket == "3-5 Years" & Yield_Spread >= 0.5 ~  1,
      Duration_Bucket == "3-5 Years" & Yield_Spread >= 0.2 ~  0,
      Duration_Bucket == "3-5 Years" & Yield_Spread <  0   ~ -2,

      # 5+ Years: must have strong spread to be worthwhile
      Duration_Bucket == "5+ Years"  & Yield_Spread >= 1.0 ~  1,
      Duration_Bucket == "5+ Years"  & Yield_Spread >= 0.5 ~  0,
      Duration_Bucket == "5+ Years"  & Yield_Spread <  0   ~ -2,

      TRUE ~ 0
    ),

    # --- Total Score ---
    Total_FI_Score = Spread_Score + Rating_Score + Call_Score + Duration_Score,

    # --- Buy Decision ---
    # Max possible score is now 8 (+3 spread +2 rating +1 call +2 duration)
    Buy_Decision = case_when(
      Total_FI_Score >= 6 ~ "Strong Buy",
      Total_FI_Score >= 4 ~ "Good Candidate",
      Total_FI_Score >= 2 ~ "Review",
      TRUE                ~ "Avoid"
    )
  )

# ============================================
# WRITE FINAL OUTPUT
# ============================================

deleteData(
  wb,
  sheet = sheet_name,
  cols = 1:200,
  rows = 1:20000,
  gridExpand = TRUE
)

writeData(
  wb,
  sheet = sheet_name,
  x = combined_fixed_income,
  startRow = 1,
  startCol = 1,
  colNames = TRUE
)

# ============================================
# HIGHLIGHT NEW ROWS
# ============================================

yellow_fill <- createStyle(fgFill = "#eebb24")

new_rows <- which(combined_fixed_income$Newly_Added == "Yes") + 1

if (length(new_rows) > 0) {
  addStyle(
    wb,
    sheet = sheet_name,
    style = yellow_fill,
    rows  = new_rows,
    cols  = 1:ncol(combined_fixed_income),
    gridExpand = TRUE,
    stack = TRUE
  )
}

# ============================================
# SAVE WORKBOOK
# ============================================

print("Saving workbook...")
saveWorkbook(wb, file_path, overwrite = TRUE)
print("Fixed Income analysis completed successfully.")