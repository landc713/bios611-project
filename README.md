# BIOS 611 Fall 2025 - Final Project

This repository holds all the parts of my BIOS 611 final project.

In this project, I examine allrecipes.com's recipes to analyze ingredients across cuisines. The data is available through R's tastyR package.

The final report is located within the results folder.

*Note: This project is designed to run inside a [Docker](https://docs.docker.com/get-docker/) container for reproducibility.*

## How to run

1.  Clone this repository and run the following in bash:

``` bash
git clone https://github.com/landc713/bios611-project.git

cd bios611-project

docker build -t project .

docker run -v $(pwd):/home/rstudio/work -p 8787:8787 -e PASSWORD=yourpassword project
```

Feel free to change the password and name of the image. And if you have an ARM64 like me, you can add --platform linux/arm64 to the run statement.

2.  Open RStudio in your browser at <http://localhost:8787> The username is rstudio and the password is whatever you set earlier.

3.  Click on the work folder, click on the settings icon, and then click "Set as Working Directory". You can also type

``` bash
cd work
```

into the terminal as well.

4.  To reproduce the final report, please navigate to the terminal and run `make clean` and then `make all` or `make results/report.html`.

Please note that this dockerfile runs rocker/rstudio:4.4.1 and not rocker/verse due to incompatibilities with my ARM64 laptop.

If you'd like to edit any of the code in your local copy, the Makefile is a good resource to understand how the analysis flows in addition to the outline of the folder structure below.

## General Folder Structure

-   00_init.R

-   01_clean.R

-   02_ingredients.R

-   03_derive_region.R

-   04_eda.R

-   05_eda_regions.R

-   06_pca.R

-   07_REPORT.rmd

-   Dockerfile

-   Makefile

-   README.md

-   data

-   results

    -   plots
    -   tables
    -   **report.html**
