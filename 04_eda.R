########################################################################################
# Program Name:   04_eda
# Description:    Summarize and make basic plots  
# Author:         Lauren D'Costa
# Date Created:   2025-11-18
# Last Modified:  
# Dependencies:   dplyr, ggplot2, lubridate, tidyr
# Notes:          
########################################################################################
source("00_init.R")
########################################################################################
#read in data
########################################################################################
cuisines <- read.csv("data/cuisines.csv", header = TRUE)
regions <- read.csv("data/regions.csv", header = TRUE)
df_ing <- read.csv("data/ingredients.csv", header = TRUE)


cuisines$date_published <- as.Date(cuisines$date_published)
df<- merge(cuisines,regions,by="country") %>% select(-X.y) %>% rename(X=X.x)
df <- df[, c("X", setdiff(names(df), "X"))]
########################################################################################
#Add labels and explore data
########################################################################################
attr(df$X, "label") <- "Recipe ID"
attr(df$name, "label") <- "Name of Recipe"

attr(df$country, "label") <- "Cuisine"
attr(df$region, "label") <- "Region (Derived)"
attr(df$url, "label") <- "URL"
attr(df$author, "label") <- "Author"
attr(df$date_published, "label") <- "Date Published or Last Updated"

attr(df$ingredients, "label") <- "List of Ingredients"
attr(df$calories, "label") <- "Calories per Serving"
attr(df$carbs, "label") <- "Carbs per Serving"
attr(df$fat, "label") <- "Fat per Serving"
attr(df$protein, "label") <- "Protein per Serving"
attr(df$avg_rating, "label") <- "Average Ratings"

attr(df$total_ratings, "label") <- "Total Number of Ratings"
attr(df$reviews, "label") <- "Total Number of Reviews"
attr(df$prep_time, "label") <- "Prep Time (in minutes)"
attr(df$cook_time, "label") <- "Cook Time (in minutes)"
attr(df$total_time, "label") <- "Total Time (in minutes)"
attr(df$servings, "label") <- "Number of Servings"

get_label <- function(x) {
  lbl <- attr(x, "label")
  if (is.null(lbl)) "NA" else lbl
}


summary_table <- tibble(
  variable = names(df),
  type = sapply(df, function(x) class(x)[1]),
  label = sapply(df, get_label),
  stats = sapply(df, function(x) {
    if (is.numeric(x)) {
      paste0("min=", min(x, na.rm = TRUE),
             "; max=", max(x, na.rm = TRUE))
    } else if (inherits(x, "Date") || inherits(x, "POSIXt")) {
      paste0("oldest=", min(x, na.rm = TRUE),
             "; most recent=", max(x, na.rm = TRUE))
    } else if (is.character(x) || is.factor(x)) {
      paste0("unique values=", length(unique(x[!is.na(x)])))
    } else {
      "NA"
    }
  })
)
save(summary_table, file = "results/tables/contents.RData")
########################################################################################
#Table 1 - Characteristics of the Dataset
########################################################################################
table1<- make_desc_stats(df, c("date_published","calories","fat","carbs","protein","avg_rating","reviews","prep_time","cook_time","total_time","servings","country"))
save(table1, file = "results/tables/table1.RData")
########################################################################################
#Start with dates 
########################################################################################
recipes_by_year <- df %>%
                   mutate(year = year(date_published)) %>%
                   count(year)

plot_year <- ggplot(recipes_by_year, aes(x = year, y = n)) +
                 geom_col(fill = "#FFA500", width = 0.8) +
                 scale_x_continuous(breaks = scales::pretty_breaks(n = 10)) +
                 labs(title = paste("Total Counts of Recipes by Year (N =",nrow(df),")"),
                       x = "Year Published or Last Updated",
                       y = "Number of Recipes") +
                theme_allrecipes(base_size=8) +
                theme(panel.grid.minor = element_blank(),
                      axis.line = element_line(color = "gray40"),
                      plot.title = element_text(face = "bold"),
                      plot.subtitle = element_text(margin = margin(b = 10)))+
                geom_text(aes(label = n), vjust = -0.5, size = 3)
ggsave(filename="results/plots/01_eda_recipes_by_year.png",plot=plot_year,width=6, height=4,dpi=300)
########################################################################################
# Nutritional Value
########################################################################################
nutrients_long <- df %>%
                  select(name,calories, protein, fat, carbs) %>%
                  filter(!is.na(calories), !is.na(protein),!is.na(fat),!is.na(carbs)) %>% 
                  pivot_longer(cols = c("calories","protein","fat","carbs"), names_to = "nutrient", values_to = "value")
                  


medians <- df %>%
  select(name,calories, protein, fat, carbs) %>%
  pivot_longer(cols = c("calories","protein","fat","carbs"), names_to = "nutrient", values_to = "value") %>%
  group_by(nutrient) %>%
  summarize(median_value = median(value, na.rm = TRUE))

nutrient_labels <- c(
  calories = "Calories (cal)",
  protein = "Protein (g)",
  fat = "Fat (g)",
  carbs = "Carbohydrates (g)"
)

nutrients <- ggplot(nutrients_long, aes(x = value)) +
  geom_histogram(bins = 30, fill = "#FFA500", color = "white") +
  geom_vline(data = medians, aes(xintercept = median_value),
             color = "black", linetype = "dashed", linewidth = 0.8) +
  facet_wrap(~ nutrient, scales = "free",labeller = as_labeller(nutrient_labels)) +
  labs(
    title = "Distribution of Nutritional Variables (By Serving)",
    subtitle = "Line shows median value", 
    x = "Amount per Recipe",
    y = "Number of Recipes"
  ) +
  theme_allrecipes(base_size=8)

ggsave(filename="results/plots/02_eda_nutrients.png",plot=nutrients,width=6, height=4,dpi=300)

########################################################################################
#Histogram of cuisine
########################################################################################
region_hist <- df %>%
  distinct(X, country) %>% 
  count(country, name = "n_recipes") %>%
  mutate(prop = n_recipes / sum(n_recipes)) %>%
  arrange(desc(prop))


cuisine_histo <- ggplot(region_hist,
                        aes(x = reorder(country, prop), y = prop * 100)) +
  geom_col(fill="#FFA500") +
  geom_text(aes(label = n_recipes),
            hjust = -0.1, size = 2, color = "black") +
  coord_flip() +
  labs(title = "Percentage of Recipes By Cuisine",
       x = "Cuisine",
       y = "Percentage of Recipes") +
  scale_y_continuous(labels = percent_format(scale = 1),
                     expand = expansion(mult = c(0, 0.1))) +
  guides(fill = guide_legend(order = 1)) + theme_allrecipes(base_size=8)

ggsave(filename="results/plots/03_eda_cuisines.png",plot=cuisine_histo,width=8, height=5,dpi=300)

########################################################################################
# Top Ingredients
########################################################################################
# Select top 10 ingredients by count
ingredient_counts <- df_ing %>%  filter(!is.na(food))%>%
  distinct(X, food) %>%   # ensure each recipe counts once per ingredient
  count(food, name = "recipe_count") %>%
  mutate(prop = recipe_count / n_distinct(df$X)) %>%  # proportion of recipes
  arrange(desc(recipe_count)) %>% 
  slice_max(recipe_count, n = 25)


# Horizontal bar chart: proportions on x-axis, counts as labels
top25 <- ggplot(ingredient_counts, aes(x = reorder(food, prop), y = prop)) +
  geom_col(fill="#FFA500") +
  geom_text(aes(label = recipe_count), hjust = -0.2,size = 3) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  coord_flip() +
  labs(title = "25 Most Common Ingredients",
       x = "Ingredient",
       y = "Proportion of Recipes") +
  theme_allrecipes(base_size=8)


ggsave(filename="results/plots/04_eda_top25.png",plot=top25,width=10, height=6,dpi=300)

















