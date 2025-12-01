########################################################################################
# Program Name:   03_derive_region
# Description:    
# Author:         Lauren D'Costa
# Date Created:   2025-11-27
# Last Modified:  
# Dependencies:   dplyr
######################################################################################         
source("00_init.R")
########################################################################################
#import data
########################################################################################
df <- read.csv("data/cuisines.csv", header = TRUE)
########################################################################################
#derive region - BASED ON UN GEOSCHEME
########################################################################################
df2 <- df %>%
  mutate(region = case_when(
    country %in% c("Amish and Mennonite", "Cajun and Creole", 
                   "Canadian", "Soul Food", "Southern Recipes") ~ "Northern America",
    country %in% c("Cuban", "Jamaican", "Puerto Rican", "Tex-Mex") ~ "Central America and Caribbean",
    country %in% c("Argentinian", "Brazilian", "Chilean", "Colombian", "Peruvian") ~ "South America",
    country %in% c("Australian and New Zealander", "Filipino", 
                   "Indonesian", "Malaysian", 
                   "Thai", "Vietnamese") ~ "South-eastern Asia and Oceania",
    country %in% c("Australian and New Zealander", "Chinese", "Filipino", 
                   "Japanese", "Korean", "Indonesian", "Malaysian", 
                   "Thai", "Vietnamese") ~ "Eastern Asia",
    country %in% c("Austrian", "Belgian", "Dutch", 
                   "French", "German","Swiss") ~ "Western Europe",
    country %in% c("Danish", "Finnish", "Scandinavian", 
                   "Swedish","Norwegian") ~ "Northern Europe",
    country %in% c("Polish", "Russian") ~ "Eastern Europe",
    country %in% c("Greek", "Italian","Portuguese", "Spanish") ~ "Southern Europe",
    country %in% c("Jewish") ~ "Jewish Diaspora",
    country %in% c("Israeli", "Lebanese", "Persian","Turkish") ~ "Western Asia",
    country %in% c("Indian", "Bangladeshi", "Pakistani","Persian") ~ "Southern Asia",
    country %in% c("South African") ~ "Africa (South Africa)",
    TRUE ~ NA_character_
  ))

df3 <- df2 %>%
  mutate(
    continent= case_when(
      region %in% c("Eastern Europe", "Northern Europe", "Southern Europe", "Western Europe") ~ "Europe",
      region %in% c("Eastern Asia", "Southern Asia", "Western Asia", "South-eastern Asia and Oceania") ~ "Asia + Australia",
      region %in% c("Northern America", "Central America and Caribbean", "South America") ~ "Americas",
      region %in% c("Africa (South Africa)") ~ "Africa",
      region %in% c("Jewish Diaspora") ~ "Jewish Diaspora",
      TRUE ~ "Other"   # catch-all for anything unexpected
    )
  )

df4 <- df3 %>%
  mutate(
    # Create an ordered factor so legend respects grouping
    continent = factor(continent,
                       levels = c("Europe", "Asia + Australia", "Americas", "Africa", "Jewish Diaspora")),
    region = factor(region,
                    levels = c("Eastern Europe", "Northern Europe", "Southern Europe", "Western Europe",
                               "Eastern Asia", "Southern Asia", "Western Asia", "South-eastern Asia and Oceania",
                               "Northern America", "Central America and Caribbean", "South America",
                               "Africa (South Africa)", "Jewish Diaspora"))
  )


regions <- df4 %>%
                select(country, region,continent) %>%  
                distinct()  # drop duplicates, keep unique combinations
attr(regions$region, "label") <- "Region Based on UN Geoscheme"
attr(regions$continent, "label") <- "Continent of Region"
make_desc_stats(regions,c("region","continent"))

regions$country <- factor(regions$country,
                               levels = c(
                                 "Tex-Mex",
                                 "Cuban",
                                 "Puerto Rican",
                                 "Jamaican",
                                 "Amish and Mennonite",
                                 "Southern Recipes",
                                 "Soul Food",
                                 "Canadian",
                                 "Cajun and Creole",
                                 "Chilean",
                                 "Peruvian",
                                 "Brazilian",
                                 "Argentinian",
                                 "Colombian",
                                 "Chinese",
                                 "Korean",
                                 "Japanese",
                                 "Australian and New Zealander",
                                 "Filipino",
                                 "Malaysian",
                                 "Vietnamese",
                                 "Thai",
                                 "Indonesian",
                                 "Bangladeshi",
                                 "Indian",
                                 "Pakistani",
                                 "Israeli",
                                 "Lebanese",
                                 "Turkish",
                                 "Persian",
                                 "Russian",
                                 "Polish",
                                 "Scandinavian",
                                 "Norwegian",
                                 "Swedish",
                                 "Finnish",
                                 "Danish",
                                 "Greek",
                                 "Italian",
                                 "Spanish",
                                 "Portuguese",
                                 "French",
                                 "German",
                                 "Dutch",
                                 "Belgian",
                                 "Austrian",
                                 "Swiss",
                                 "South African",
                                 "Jewish"
                               )
                               
)
########################################################################################
#output data
########################################################################################
write.csv(regions, "data/regions.csv", row.names = TRUE)

