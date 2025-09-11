FROM rocker/rstudio:latest
#ensure root
USER root
#run the necessary packages
RUN R -e "install.packages(c('dplyr','ggplot2'), repos='https://cloud.r-project.org')"
