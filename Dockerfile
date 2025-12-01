#using rstudio instead of verse bc of ARM64 laptop
FROM rocker/rstudio:4.4.1

#ensure root so we can install packages
USER root

#run the necessary packages
RUN R -e "install.packages(c('dplyr','ggplot2','rmarkdown','tastyR','stringi','stringr','udpipe','stringdist','lubridate','tidyr','patchwork','cowplot','ggrepel'), repos='https://cloud.r-project.org')"

#revert back to rstudio user
#USER rstudio
