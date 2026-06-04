# analysis.R
# Replicates Table 3 Column 1 from Peri & Yasenov (2019)
# Step 1: Collapse to city-year panel
# Step 2: Run synthetic control (trunit=26, trperiod=1980)
# Step 3: Run FGLS regression on 2-city panel
# All paths relative to repository root

library(dplyr)
library(Synth)
library(nlme)
library(ggplot2)
library(tidyr)

# -- 1. Load analysis sample
sample <- readRDS("temp/analysis_sample.rds")

# -- 2. Collapse to city-year panel
panel <- sample %>%
  filter(!is.na(smsarank_num), smsarank_num > 0) %>%
  group_by(smsarank_num, year) %>%
  summarise(
    logearnwke  = mean(log_weekly_wage, na.rm = TRUE),
    low_skilled = mean(as.integer(as.numeric(gradeat) < 12), na.rm = TRUE),
    hisp        = mean(as.integer(as.numeric(ethnic) != 8 & 
                                    as.numeric(ethnic) != 5), na.rm = TRUE),
    .groups = "drop"
  )

# -- 3. Check Miami and pre-treatment years
cat("Miami years in panel:\n")
print(panel %>% filter(smsarank_num == 26) %>% select(year, logearnwke))

# -- 4. Keep only cities present in all years (balanced panel)
year_counts <- panel %>% 
  group_by(smsarank_num) %>% 
  summarise(n_years = n(), .groups = "drop")

all_years <- length(unique(panel$year))
balanced_cities <- year_counts %>% 
  filter(n_years == all_years) %>% 
  pull(smsarank_num)

panel <- panel %>% filter(smsarank_num %in% balanced_cities)

cat("Cities in balanced panel:", length(unique(panel$smsarank_num)), "\n")
cat("Years in panel:", sort(unique(panel$year)), "\n")

# -- 5. Prepare for Synth
panel_df <- as.data.frame(panel)
donor_pool <- setdiff(unique(panel_df$smsarank_num), 26)
years      <- sort(unique(panel_df$year))
pre_years  <- years[years < 1980]

cat("Pre-treatment years:", pre_years, "\n")
cat("Donor pool:", length(donor_pool), "cities\n")

# -- 6. Run synthetic control
dataprep_out <- dataprep(
  foo                   = panel_df,
  predictors            = "hisp",
  predictors.op         = "mean",
  dependent             = "logearnwke",
  unit.variable         = "smsarank_num",
  time.variable         = "year",
  treatment.identifier  = 26,
  controls.identifier   = donor_pool,
  time.predictors.prior = pre_years,
  time.optimize.ssr     = pre_years,
  time.plot             = years
)

synth_out <- synth(dataprep_out)

# -- 7. Print synthetic control weights
synth_tables <- synth.tab(dataprep_out, synth_out)
cat("\nTop synthetic control weights:\n")
print(synth_tables$tab.w[synth_tables$tab.w$w.weights > 0.01, ])

# -- 8. Build path plot data
path_data <- data.frame(
  year      = years,
  miami     = as.numeric(dataprep_out$Y1plot),
  synthetic = as.numeric(dataprep_out$Y0plot %*% synth_out$solution.w)
)

cat("\nMiami vs Synthetic Control:\n")
print(path_data)

# -- 9. Build 2-city regression panel
reg_panel <- path_data %>%
  filter(year != 1980) %>%
  pivot_longer(cols = c(miami, synthetic),
               names_to = "city", values_to = "logearnwke") %>%
  mutate(
    miami_dummy  = as.integer(city == "miami"),
    d8182        = as.integer(year %in% c(1981, 1982)),
    d8385        = as.integer(year %in% c(1983, 1984, 1985)),
    d8688        = as.integer(year %in% c(1986, 1987, 1988)),
    d8991        = as.integer(year %in% c(1989, 1990, 1991)),
    miami_d8182  = miami_dummy * d8182,
    miami_d8385  = miami_dummy * d8385,
    miami_d8688  = miami_dummy * d8688,
    miami_d8991  = miami_dummy * d8991,
    city_f       = as.factor(miami_dummy),
    year_f       = as.factor(year)
  )

# -- 10. FGLS with AR1 errors
model <- gls(
  logearnwke ~ city_f + year_f + 
    miami_d8182 + miami_d8385 + miami_d8688 + miami_d8991,
  data        = reg_panel,
  correlation = corAR1(form = ~ year | city_f)
)

coefs     <- summary(model)$tTable
beta_8182 <- coefs["miami_d8182", "Value"]
se_8182   <- coefs["miami_d8182", "Std.Error"]
beta_8385 <- coefs["miami_d8385", "Value"]
se_8385   <- coefs["miami_d8385", "Std.Error"]
beta_8688 <- coefs["miami_d8688", "Value"]
se_8688   <- coefs["miami_d8688", "Std.Error"]
beta_8991 <- coefs["miami_d8991", "Value"]
se_8991   <- coefs["miami_d8991", "Std.Error"]

# -- 11. Console summary
cat("\n=== Replication Results ===\n")
cat("Paper reports: Miami X (1981-1982) = -0.015 (s.e. 0.042)\n")
cat(sprintf("We obtain:     Miami X (1981-1982) = %.3f (s.e. %.3f)\n", 
            beta_8182, se_8182))
cat(sprintf("Difference: %.3f\n", beta_8182 - (-0.015)))

# -- 12. Write LaTeX table
dir.create("output/tables", showWarnings = FALSE, recursive = TRUE)
latex <- sprintf(
  "\\begin{table}[h]
\\centering
\\caption{Replication of Table 3 Column 1, Peri \\& Yasenov (2019)}
\\begin{tabular}{lcc}
\\hline
Period & Estimate & Std. Error \\\\
\\hline
Miami $\\times$ (1981--1982) & $%.3f$ & $(%.3f)$ \\\\
Miami $\\times$ (1983--1985) & $%.3f$ & $(%.3f)$ \\\\
Miami $\\times$ (1986--1988) & $%.3f$ & $(%.3f)$ \\\\
Miami $\\times$ (1989--1991) & $%.3f$ & $(%.3f)$ \\\\
\\hline
\\multicolumn{3}{l}{\\footnotesize Paper target: $-0.015$ (s.e. $0.042$)} \\\\
\\end{tabular}
\\label{tab:main}
\\end{table}",
  beta_8182, se_8182,
  beta_8385, se_8385,
  beta_8688, se_8688,
  beta_8991, se_8991
)

writeLines(latex, "output/tables/main_result.tex")
cat("Table written to output/tables/main_result.tex\n")

# -- 13. Write figure
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

p <- ggplot(path_data, aes(x = year)) +
  geom_line(aes(y = miami, color = "Miami", linetype = "Miami")) +
  geom_line(aes(y = synthetic, color = "Synthetic Control", 
                linetype = "Synthetic Control")) +
  geom_vline(xintercept = 1979.5, linetype = "dashed", color = "gray40") +
  annotate("text", x = 1979.3, y = max(path_data$miami), 
           label = "Boatlift", hjust = 1, size = 3) +
  labs(
    title    = "Log Weekly Wages: Miami vs Synthetic Control",
    subtitle = "Non-Cuban High School Dropouts, 1973-1991 (1980 USD)",
    x = "Year", y = "Avg Log Weekly Wage",
    color = "", linetype = ""
  ) +
  theme_minimal()

ggsave("output/figures/main_figure.png", p, width = 7, height = 4, dpi = 300)
cat("Figure written to output/figures/main_figure.png\n")