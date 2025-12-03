.PHONY: clean all create_dirs

# Clean target: Remove old directories and files
clean:
	@echo "Cleaning up old directories and files..."
	rm -rf data results results/plots results/tables
	@echo "Directories removed. Ready for rebuild."

# Ensure directories are created before generating any files
create_dirs:
	@echo "Creating necessary directories..."
	mkdir -p data results results/plots results/tables
	@echo "Directories created."
	
# Clean the raw data
data/cuisines.csv: 01_clean.R 00_init.R | create_dirs
	@echo "Running 01_clean.R to produce the cleaned CSV of the cuisines dataset"
	Rscript 01_clean.R
	@echo "Finished running 01_clean.R: Produced data/cuisines.csv"

# Standardize the ingredients
data/ingredients.csv: 02_ingredients.R 00_init.R data/cuisines.csv | create_dirs
	@echo "Running 02_ingredients.R to produce a dataset of ingredients by recipe for the cuisines dataset"
	Rscript 02_ingredients.R
	@echo "Finished running 02_ingredients.R: Produced data/ingredients.csv"

# Map cuisines to the general region
data/regions.csv: 03_derive_region.R 00_init.R data/cuisines.csv | create_dirs
	@echo "Running 03_derive_region.R to produce a dataset of cuisine to region"
	Rscript 03_derive_region.R
	@echo "Finished running 03_derive_region.R: Produced data/regions.csv"


# Make Exploratory Data Tables and Plots
results/plots/01_eda_recipes_by_year.png results/plots/02_eda_nutrients.png results/plots/03_eda_cuisines.png results/plots/04_eda_top25.png results/tables/contents.RData results/tables/table1.RData: data/cuisines.csv data/ingredients.csv data/regions.csv 04_eda.R 00_init.R | create_dirs
	@echo "Running 04_eda.R to produce exploratory plots and tables"
	Rscript 04_eda.R
	@echo "Finished running 04_eda.R: Produced plots and tables in results"

# Make Exploratory Data By Cuisine Plots
results/plots/05_asia.png results/plots/05_europe.png results/plots/05_americas.png results/plots/06_heatmap.png: data/cuisines.csv data/ingredients.csv data/regions.csv 05_eda_regions.R 00_init.R| create_dirs
	@echo "Running 05_eda_regions.R to produce exploratory plots by cuisine"
	Rscript 05_eda_regions.R
	@echo "Finished running 05_eda_regions.R: Produced plots in results/plots"

#PCA and tSNE
results/plots/07_scree.png results/plots/08_t_sne.png data/tsne.rds: data/cuisines.csv data/ingredients.csv data/regions.csv 05_eda_regions.R 00_init.R| create_dirs
	@echo "Running 06_pca.R"
	Rscript 06_pca.R
	@echo "Finished running 06_pca.R: Produced plots in results/plots"
	
#plotly
results/plots/tsne_recipes.html: data/tsne.rds 06_tsne_plotly.R 00_init.R | create_dirs
	@echo "Running 06_tsne_plotly.R to produce the interactive plot of the cuisines dataset"
	Rscript 06_tsne_plotly.R
	@echo "Finished running 06_tsne_plotly.R: Produced tsne_recipes.html"


#Creating the report
results/report.html: results/plots/01_eda_recipes_by_year.png results/plots/02_eda_nutrients.png results/plots/03_eda_cuisines.png results/plots/04_eda_top25.png\
 results/tables/contents.RData results/tables/table1.RData\
 results/plots/05_asia.png results/plots/05_europe.png results/plots/05_americas.png results/plots/06_heatmap.png\
 results/plots/07_scree.png results/plots/08_t_sne.png data/tsne.rds\
 results/plots/tsne_recipes.html 00_init.R 07_REPORT.Rmd | create_dirs
	Rscript -e "rmarkdown::render('07_REPORT.Rmd', output_file='results/report.html')"

# Default target, runs everything (also ensures directories are created)
all: create_dirs data/cuisines.csv data/ingredients.csv data/regions.csv\
 results/plots/01_eda_recipes_by_year.png results/plots/02_eda_nutrients.png results/plots/03_eda_cuisines.png results/plots/04_eda_top25.png\
 results/tables/contents.RData results/tables/table1.RData\
 results/plots/05_asia.png results/plots/05_europe.png results/plots/05_americas.png results/plots/06_heatmap.png\
 results/plots/07_scree.png results/plots/08_t_sne.png data/tsne.rds\
 results/plots/tsne_recipes.html\
 results/report.html
	@echo "All tasks completed - yahoo!"

		