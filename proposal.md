# Replication Proposal

**Paper:** Peri, Giovanni and Vasil Yasenov. "The Labor Market Effects of a Refugee Wave:
Synthetic Control Method Meets the Mariel Boatlift." Journal of Human Resources 54(2), 2019, pp. 267-309.

**Paper URL:** https://www.jstor.org/stable/26627853

**Data URL:** https://www.openicpsr.org/openicpsr/project/157121/version/V1/view
May CPS: https://www.nber.org/research/data/current-population-survey-cps-may-extracts-1969-1987
ORG CPS: https://data.nber.org/morg/annual/

**Result to replicate:** Column (1) of Table 3 — the FGLS regression estimates
for log weekly wages of high school dropouts (Miami vs. synthetic control), 1973–1991.
Specifically, the post-Boatlift coefficient Miami X (1981–1982) = -0.015 (s.e. 0.042).

**Toolchain:** R (haven, dplyr, Synth, sandwich)

**Why this paper:** The economic impact of sudden migration waves has long fueled political discourse. As climate change accelerates, such waves are likely to become more frequent, making the their labor market effects increasingly relevant. 
