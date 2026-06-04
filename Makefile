.PHONY: all clean

all: paper/paper.pdf

# Preprocessing — reads from input/, writes to temp/
temp/analysis_sample.rds: input/sample_filtered.rds code/preprocess.R
	Rscript code/preprocess.R

# Analysis — reads from temp/, writes to output/
output/tables/main_result.tex output/figures/main_figure.png: temp/analysis_sample.rds code/analysis.R
	Rscript code/analysis.R

# Paper compilation
paper/paper.pdf: paper/paper.tex output/tables/main_result.tex output/figures/main_figure.png
	cd paper && pdflatex paper.tex && pdflatex paper.tex

clean:
	rm -f temp/analysis_sample.rds output/tables/main_result.tex output/figures/main_figure.png paper/paper.pdf paper/paper.aux paper/paper.log
