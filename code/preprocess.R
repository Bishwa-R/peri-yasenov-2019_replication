# preprocess.R
# Reads raw CPS data from input/, cleans, and writes to temp/
# All paths relative to repository root

library(haven)
library(dplyr)

# -- 1. Load and combine May CPS (1973-1978)
may_files <- list.files("input", pattern = "^cpsmay.*\\.dta$", full.names = TRUE)
may_data <- lapply(may_files, read_dta) %>% bind_rows()

# -- 2. Load and combine ORG CPS (1979-1991)
org_files <- list.files("input", pattern = "^morg.*\\.dta$", full.names = TRUE)
org_data <- lapply(org_files, read_dta) %>% bind_rows()

# -- 3. Combine both sources
cps <- bind_rows(may_data, org_data)

# -- 4. Filter to paper's preferred sample
sample <- cps %>%
  filter(
    age >= 19, age <= 65,
    gradeat < 12,
    as.numeric(ethnic) != 9,
    (as.numeric(esr) <= 4 | as.numeric(lfsr89) <= 4),
    as.numeric(class) < 6,
    earnwke > 0
  ) %>%
  mutate(
    log_weekly_wage = log(earnwke),
    miami = as.integer(
      (as.numeric(smsarank) == 26 & !is.na(smsarank)) |
        (as.numeric(msafips) == 5000 & !is.na(msafips))
    ),
    post = as.integer(year >= 1980)
  ) %>%
  filter(!is.na(log_weekly_wage))

# -- 5. Write to temp/
dir.create("temp", showWarnings = FALSE)
saveRDS(sample, "temp/analysis_sample.rds")

# -- 6. Console summary
cat("=== Preprocessing Summary ===\n")
cat("N observations:", nrow(sample), "\n")
cat("Year range:", min(sample$year), "to", max(sample$year), "\n")
cat("Mean log weekly wage:", round(mean(sample$log_weekly_wage), 3), "\n")
cat("SD log weekly wage:", round(sd(sample$log_weekly_wage), 3), "\n")
cat("N Miami obs:", sum(sample$miami), "\n")
cat("Output written to temp/analysis_sample.rds\n")
