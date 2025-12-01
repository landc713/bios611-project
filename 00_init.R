########################################################################################
#Dependencies
########################################################################################
library(tastyR)
library(dplyr)
library(stringdist)
library(tidyr)
library(udpipe)
library(stringr)
library(stringi)
library(ggplot2)
library(lubridate)
library(scales)
library(patchwork)
library(cowplot)
library(knitr)
library(ggrepel)
########################################################################################
#theme for graphs
########################################################################################
theme_allrecipes <- function(base_size = 14, base_family = "sans") {
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      plot.title = element_text(
        face = "bold",
        size = base_size + 6,
        color = "#FF914D",
        hjust = 0,
        margin = margin(b = 10)
      ),
      plot.subtitle = element_text(
        size = base_size + 2,
        color = "#444444",
        hjust = 0,  
        margin = margin(b = 10)
      )
    )
}
# Define a named color palette
# Your named vector of colors
region_colors <- c(
  "Eastern Europe"              = "#08306B",
  "Northern Europe"             = "#2171B5",
  "Southern Europe"             = "#6BAED6",
  "Western Europe"              = "#C6DBEF",
  "Eastern Asia"                = "#A50F15",
  "Southern Asia"               = "#E6550D",
  "Western Asia"                = "#FB6A4A",
  "South-eastern Asia and Oceania" = "#FD8D3C",
  "Northern America"            =  "#00441B",
  "Central America and Caribbean" ="#238B45",
  "South America"               = "#74C476",
  "Africa (South Africa)"       = "#6A51A3",
  "Jewish Diaspora"             = "#969696"
)

# Create a factor with levels in the order of region_colors
region_factor <- factor(names(region_colors), levels = names(region_colors))


                            
########################################################################################
#reusable functions
########################################################################################
get_label <- function(x) {
  lbl <- attr(x, "label")
  if (is.null(lbl)) "NA" else lbl
}

make_desc_stats <- function(data, vars) {
  results <- list()
  
  # First row: total number of observations
  total_n <- nrow(data)
  results[["N"]] <- data.frame(
    variable = "Number of Records",
    level = NA,
    statistics = as.character(total_n)
  )
  
  for (v in vars) {
    x <- data[[v]]
    var_label <- get_label(x)
    
    # Header row: "<variable name>: <variable label>"
    header_row <- data.frame(
      variable = paste0(var_label),
      level = NA,
      statistics = NA
    )
    
    if (is.character(x) || is.factor(x)) {
      # Frequency counts with percentages, sorted by frequency
      freq <- table(x, useNA = "ifany")
      freq_df <- as.data.frame(freq)
      colnames(freq_df) <- c("level", "count")
      freq_df$percent <- round(100 * freq_df$count / sum(freq_df$count), 2)
      freq_df <- freq_df %>%
        arrange(desc(count)) %>%
        mutate(variable = v,
               statistics = paste0(count, " (", percent, "%)")) %>%
        select(variable, level, statistics)
      results[[v]] <- bind_rows(header_row, freq_df)
      
    } else if (inherits(x, "Date") || inherits(x, "POSIXt")) {
      # Frequency by 5-year intervals (include empty intervals as 0 (0%))
      years <- as.numeric(format(x, "%Y"))
      min_year <- min(years, na.rm = TRUE)
      max_year <- max(years, na.rm = TRUE)
      breaks <- seq(floor(min_year/5)*5, ceiling(max_year/5)*5, by = 5)
      intervals <- cut(years, breaks = breaks, right = FALSE, include.lowest = TRUE)
      
      freq <- table(intervals, useNA = "no")
      freq_df <- data.frame(
        level = levels(intervals),
        count = as.integer(freq[levels(intervals)])
      )
      freq_df$count[is.na(freq_df$count)] <- 0
      freq_df$percent <- round(100 * freq_df$count / sum(freq_df$count), 2)
      freq_df <- freq_df %>%
        mutate(variable = v,
               statistics = paste0(count, " (", percent, "%)")) %>%
        select(variable, level, statistics)
      results[[v]] <- bind_rows(header_row, freq_df)
      
    } else if (is.numeric(x)) {
      # Mean (SD)
      mean_val <- round(mean(x, na.rm = TRUE), 2)
      sd_val <- round(sd(x, na.rm = TRUE), 2)
      mean_row <- data.frame(
        variable = v,
        level = "mean(sd)",
        statistics = paste0(mean_val, " (", sd_val, ")")
      )
      
      # Median (Q1, Q3)
      med_val <- round(median(x, na.rm = TRUE), 2)
      q1_val <- round(quantile(x, 0.25, na.rm = TRUE), 2)
      q3_val <- round(quantile(x, 0.75, na.rm = TRUE), 2)
      median_row <- data.frame(
        variable = v,
        level = "median(q1,q3)",
        statistics = paste0(med_val, " (", q1_val, ", ", q3_val, ")")
      )
      
      results[[v]] <- bind_rows(header_row, mean_row, median_row)
      
    } else {
      results[[v]] <- bind_rows(
        header_row,
        data.frame(variable = v, level = NA, statistics = "Unsupported type")
      )
    }
  }
  
  # Bind all results into one long table
  final_table <- bind_rows(results)
  return(final_table)
}