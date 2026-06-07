# Replication of Peri & Yasenov (2019)

This repository replicates Column (1) of Table 3 from Peri, Giovanni and Vasil Yasenov, "The Labor Market Effects of a Refugee Wave: Synthetic Control Method Meets the Mariel Boatlift," *Journal of Human Resources* 54(2), 2019, pp. 267-309.

The specific result is the FGLS regression coefficient on Miami X (1981-1982) for log weekly wages of non-Cuban high school dropouts. The paper reports -0.015 (s.e. 0.042); we obtain 0.025 (s.e. 0.041).

## Citation

Peri, Giovanni and Vasil Yasenov. "The Labor Market Effects of a Refugee Wave: Synthetic Control Method Meets the Mariel Boatlift." *Journal of Human Resources* 54(2), 2019, pp. 267-309.

## Data

The raw data are the May CPS extracts (1973-1978) and ORG CPS (1979-1991) from the NBER:
- May CPS: https://www.nber.org/research/data/current-population-survey-cps-may-extracts-1969-1987
- ORG CPS: https://data.nber.org/morg/annual/

Download the following files into input/:
- cpsmay73.dta through cpsmay78.dta
- morg79.dta through morg91.dta

See input/README.md for full instructions.

## Prerequisites

- R 4.x with packages: haven, dplyr, Synth, nlme, ggplot2, tidyr
- GNU Make
- pdflatex (MiKTeX or TeX Live)

Install R packages:
```r
install.packages(c("haven", "dplyr", "Synth", "nlme", "ggplot2", "tidyr"))
```

## Reproducing the Paper

```bash
git clone https://github.com/Bishwa-R/peri-yasenov-2019_replication.git
cd peri-yasenov-2019_replication
# Follow data download instructions in input/README.md
make
```

The final paper will be at paper/paper.pdf.

To start from a clean state:

```bash
make clean
make
```

Or use the convenience wrapper:

```bash
bash run_all.sh
```

## Results

| | Estimate | Std. Error |
|---|---|---|
| Paper reports | -0.015 | (0.042) |
| We obtain | 0.025 | (0.041) |

Both estimates are statistically indistinguishable from zero, confirming the paper's finding of no significant wage effect from the Mariel Boatlift.

## Repository Structure

```
peri-yasenov-2019_replication/
├── input/
│   ├── README.md              # Data download instructions
│   ├── data_dictionary.md     # Variable descriptions
│   └── sample_filtered.rds    # Pre-filtered sample (committed)
├── code/
│   ├── preprocess.R           # Load, clean, and save analysis sample
│   └── analysis.R             # SCM + FGLS regression, outputs
├── output/
│   ├── figures/               # main_figure.png
│   └── tables/                # main_result.tex
├── temp/                      # Intermediate files (gitignored)
├── paper/
│   ├── paper.tex              # LaTeX source
│   └── paper.pdf              # Compiled output
├── Makefile
├── run_all.sh
├── proposal.md
└── README.md
```