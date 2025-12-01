########################################################################################
# Program Name:   01a_Clean
# Description:    Clean allrecipe datasets by removing outliers and duplicates
# Author:         Lauren D'Costa
# Date Created:   2025-10-18
# Last Modified:  2025-11-26
# Notes:          
# Dependencies: tastyR, dplyr,stringdist
########################################################################################
source("00_init.R")
########################################################################################
#Get data
########################################################################################
data("cuisines", package = "tastyR")
cu <- cuisines
########################################################################################
# Cleaning Functions
########################################################################################
#1. Remove rows that have missing values for ingredients 
rm_miss <-function(df) {na_df <- df %>% filter(!is.na(country), !is.na(ingredients),!is.na(author),!is.na(name))
                       return(na_df)}

#2. Remove exact duplicates by name
rm_exact_dupes <- function(df) {df %>%
                                arrange(desc(total_ratings)) %>%    # put highest ratings first
                                distinct(name, .keep_all = TRUE)}

#3. Remove similar duplicates by name
rm_sim_dupes <- function(df,
                         name_col = "name",
                         rating_col = "total_ratings",
                         fuzzy_threshold = 0.05) {
  
                        # Compute string distance matrix on recipe names
                        dist_mat <- stringdistmatrix(df[[name_col]], df[[name_col]], method = "jw")
                        hc <- hclust(as.dist(dist_mat))
                        clusters <- cutree(hc, h = fuzzy_threshold)
  
                        df2 <- df %>% mutate(cluster = clusters)
                        
                        # Identify duplicates (clusters with >1 recipe)
                        duplicates <- df2 %>%
                          group_by(cluster) %>%
                          filter(n() > 1) %>%
                          arrange(cluster)
                        
                        # Keep only one recipe per cluster (the one with most ratings)
                        df3 <- df2 %>%
                          group_by(cluster) %>%
                          slice_max(order_by = .data[[rating_col]], n = 1) %>%
                          ungroup()
                        
                        # Return both cleaned dataset and duplicates for inspection
                        return(list(cleaned = df3, duplicates = duplicates))
                      }


#4. Prepare for output
prepare <- function(df,vars) {
                        df2 <- df %>% 
                        { if (!is.null(vars)) select(., all_of(vars)) else . }
                        return(df2)}
########################################################################################
# Call functions for cuisines 
########################################################################################
cu1 <- rm_miss(cu)
cu2 <- rm_exact_dupes(cu1)
cu3 <- rm_sim_dupes(cu2)
# Cleaned dataset (deduplicated)
cu4 <- cu3$cleaned
# Duplicates table for inspection
cu4_dups <- cu3$duplicates

cu5 <-prepare(cu4,c("name","country","url","author","date_published",
                    "ingredients", 
                    "calories", "fat","carbs","protein", 
                    "avg_rating","total_ratings","reviews",
                    "prep_time","cook_time","total_time","servings"))
########################################################################################
# Output
########################################################################################
write.csv(cu5, "data/cuisines.csv", row.names = TRUE)