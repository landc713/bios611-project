#using rstudio instead of verse bc of ARM64 laptop
FROM rocker/rstudio:4.4.1

#ensure root so we can install packages
USER root

# Install required system dependencies for packages like `plotly`
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    # Clean up to reduce image size
    && rm -rf /var/lib/apt/lists/*

# Install plotly and its R dependencies
RUN R -e "install.packages('plotly', dependencies=TRUE)"

#run the necessary packages
RUN R -e "install.packages(c('dplyr','ggplot2','rmarkdown','tastyR','stringi','stringr','udpipe','stringdist','lubridate','tidyr','patchwork','cowplot','ggrepel','irlba','Rtsne'), repos='https://cloud.r-project.org')"

#revert back to rstudio user
#USER rstudio
