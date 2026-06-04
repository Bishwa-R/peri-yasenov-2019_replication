# preprocess.R
# Reads raw CPS data from input/, cleans, and writes to temp/
# All paths relative to repository root

library(haven)
library(dplyr)

# -- 1. Load and combine May CPS (1973-1978)
may_files <- list.files("input", pattern = "^cpsmay.*\\.dta$", full.names = TRUE)
may_data <- lapply(may_files, read_dta) %>% bind_rows()

# -- 1b. Rename May CPS columns using codebook
may_data <- may_data %>%
  rename(
    smsarank = x11,
    age      = x67,
    sex      = x70,
    gradeat  = x72,
    gradecp  = x73,
    esr      = x75,
    weight   = x80,
    ethnic   = x85,
    class    = x62,
    earnwke  = x186,
    year     = x200
  ) %>%
  mutate(weight = weight / 100)

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
    infl_factor = case_when(
      year == 1979 ~ 1.135017842,
      year == 1980 ~ 1.000000000,
      year == 1981 ~ 0.905974729,
      year == 1982 ~ 0.853418002,
      year == 1983 ~ 0.827279757,
      year == 1984 ~ 0.792654883,
      year == 1985 ~ 0.765641264,
      year == 1986 ~ 0.751039274,
      year == 1987 ~ 0.725093956,
      year == 1988 ~ 0.696537730,
      year == 1989 ~ 0.664689936,
      year == 1990 ~ 0.630523963,
      year == 1991 ~ 0.605014431,
      TRUE ~ 1.0
    ),
    earnwke_real = earnwke * infl_factor,
    log_weekly_wage = log(earnwke_real),
    miami = as.integer(
      (as.numeric(smsarank) == 26 & !is.na(smsarank)) |
        (as.numeric(msafips) == 5000 & !is.na(msafips))
    ),
    post = as.integer(year >= 1980)
  ) %>%
  filter(!is.na(log_weekly_wage))

# -- 4b. Add smsarank_num using crosswalk for 1986+ observations
# msafips to smsarank crosswalk (built from CPS variable labels)
crosswalk <- data.frame(
  smsarank_num = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
                   16, 17, 18, 19, 20, 21, 22, 24, 25, 26, 27, 28, 29,
                   30, 31, 32, 33, 34, 36, 38, 42, 44, 45, 46, 48, 49,
                   53, 57),
  msafips_num  = c(5600, 4480, 1600, 6160, 2160, 7360, 8840, 1120, 5380,
                   6280, 7040, 720, 1680, 3360, 5640, 5120, 1920, 360,
                   7320, 8280, 520, 1640, 1280, 3760, 5000, 2080, 6780,
                   3480, 7400, 5560, 6440, 1840, 2800, 1000, 5720, 80,
                   2960, 3120, 160, 6840, 6920, 4480, 875)
)

# cmsarank to smsarank crosswalk (built from CPS variable labels)
cmsarank_cross <- data.frame(
  cmsarank_num = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
                   16, 17, 18, 19, 20, 21, 22, 24, 25, 27, 28, 29, 30,
                   31, 32, 38, 43, 45, 46),
  smsarank_num = c(1, 2, 3, 4, 6, 5, 8, 14, 7, 17, 13, 26, 10, 11, 21,
                   16, 18, 19, 24, 33, 28, 22, 20, 27, 32, 36, 29, 30,
                   31, 34, 38, 45, 48, 46)
)

sample <- sample %>%
  mutate(
    msafips_num  = as.numeric(msafips),
    cmsarank_num = as.numeric(cmsarank)
  ) %>%
  left_join(crosswalk, by = "msafips_num") %>%
  rename(smsarank_from_fips = smsarank_num) %>%
  left_join(cmsarank_cross, by = "cmsarank_num") %>%
  rename(smsarank_from_cmsa = smsarank_num) %>%
  mutate(
    smsarank_num = case_when(
      !is.na(as.numeric(smsarank)) & as.numeric(smsarank) > 0 ~ as.numeric(smsarank),
      !is.na(smsarank_from_fips) ~ smsarank_from_fips,
      !is.na(smsarank_from_cmsa) ~ smsarank_from_cmsa,
      TRUE ~ NA_real_
    )
  ) %>%
  select(-smsarank_from_fips, -smsarank_from_cmsa)

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
cat("N obs with city ID:", sum(!is.na(sample$smsarank_num)), "\n")
