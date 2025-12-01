########################################################################################
# Program Name:   05_eda_regions
# Description:    top ingredients by cuisine 
# Author:         Lauren D'Costa
# Date Created:   2025-11-26
# Last Modified:  
# Dependencies:   dplyr, ggplot2, tidyr, stringr,scales
# Notes:          
########################################################################################
source("00_init.R")
########################################################################################
#read in data
########################################################################################
cuisines <- read.csv("data/cuisines.csv", header = TRUE)
regions <- read.csv("data/regions.csv", header = TRUE) %>% select(-X)
ing <- read.csv("data/ingredients.csv", header = TRUE) %>% select(-X.1)

crosswalk<- merge(cuisines,regions,by="country") %>% select(X,region,continent,country)
df <- merge(ing,crosswalk, by = "X") %>% select(-country.y) %>% rename(country = country.x)
########################################################################################
#Top 10 Ingredients By Cuisine
########################################################################################
uninformative <- c("sugar","onion","butter","flour","sauce","water","oil","egg","salt",
                   "garlic","milk","pepper","baking powder","baking powder","cornstarch","baking soda")
df <- df %>% filter(!str_detect(food, str_c(uninformative, collapse = "|")))
df$country <- factor(df$country,
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
top5_ingredients <- df %>%
  group_by(country,food) %>%
  summarise(count = n(), .groups = "drop") %>%
  # get total number of recipes per cuisine
  left_join(
    df %>%
      distinct(country,X) %>%
      count(country, name = "total_recipes"),
    by = "country"
  ) %>%
  mutate(prop = ((count / total_recipes)*100)) %>%   # proportion out of recipes
  arrange(desc(prop)) %>%
  group_by(country) %>%
  slice_head(n = 5) %>%
  ungroup() %>%
  arrange(country, desc(prop)) %>%
  # add a label for facet titles
  mutate(country_label = paste0(country, " (N=", total_recipes, ")"))


top5_regions <- merge(top5_ingredients,regions,by="country") %>% 
                        select(food,count,total_recipes,prop,region,continent,country,country_label)

top5_regions <- top5_regions %>%
  group_by(country) %>%
  mutate(food_ordered = factor(paste(country, food, sep = "___"),
                        levels = paste(country, food[order(prop)], sep = "___")))%>%
  ungroup()

top5_regions$region <- factor(top5_regions$region, levels = names(region_colors))
df_region<- split(top5_regions, top5_regions$region)
df_asia <- rbind(df_region$`Eastern Asia`,df_region$`Western Asia`,df_region$`South-eastern Asia and Oceania`,df_region$`Southern Asia`)
df_europe <- rbind(df_region$`Southern Europe`,df_region$`Northern Europe`,df_region$`Western Europe`,df_region$`Eastern Europe`)
df_americas <-rbind(df_region$`Central America and Caribbean`,df_region$`Northern America`,df_region$`South America`,df_region$`Jewish Diaspora`,df_region$`Africa (South Africa)`)
#df_other <- rbind(df_region$`Jewish Diaspora`,df_region$`Africa (South Africa)`)



plot_top5<- function(data,title,rows) {
                        ggplot(data,
                               aes(x = food_ordered, y = prop, fill = region)) +
                          geom_col(show.legend = TRUE) +
                          scale_fill_manual(values = region_colors) +
                          coord_flip() +
                          facet_wrap(~country, scales = "free_y",labeller = labeller(country = setNames(data$country_label,data$country)),nrow=rows) +   # columns = continent, share x-axis
                          labs(title = title,fill  = "Geographic Region:",
                               x = "Top 5 Ingredients in Cuisine",
                               y = "Percentage of Recipes") +
                          scale_x_discrete(labels = function(x) sub(".*___", "", x))+
                          theme_allrecipes(base_size=8)+
                          theme(
                            legend.position   = "top",          # put legend at top
                            legend.direction  = "horizontal",   # horizontal layout
                            legend.justification = "center",    # center it
                            plot.title.position = "plot",       # align title with legend
                            legend.box        = "horizontal"    # keep legend items in one line
                          )
}

asia_p <- plot_top5(df_asia,"Asia",4)
europe_p <- plot_top5(df_europe,"Europe",5)
america_p <- plot_top5(df_americas,"Americas + South Africa + Jewish Diaspora",4)
#other_p <- plot_top5(df_other,"Africa and Jewish Diaspora",2)

ggsave(filename="results/plots/05_asia.png",plot=asia_p,width=8, height=6,dpi=300)
ggsave(filename="results/plots/05_europe.png",plot=europe_p,width=8, height=6,dpi=300)
ggsave(filename="results/plots/05_americas.png",plot=america_p ,width=8, height=6,dpi=300)
#ggsave(filename="results/plots/05_other.png",plot=other_p,width=8, height=6,dpi=300)


########################################################################################
# Heatmap of Top 100 Ingredients 
########################################################################################
total_recipes <- df %>% distinct(X) %>% nrow()

# 2. Overall proportion per ingredient
overall_prop <- df %>%
  group_by(food) %>%
  summarise(recipes_with = n_distinct(X), .groups = "drop") %>%
  mutate(global_prop = recipes_with / total_recipes) %>%
  arrange(desc(global_prop))



top50<- overall_prop%>%
        slice_head(n = 50) 

save(table1, file = "results/tables/top50_notcommon.RData")
# 3. Select top 100 ingredients globally
top100 <- overall_prop %>%
  slice_head(n = 50) %>%
  pull(food)

# 4. Per-country proportions for those top 100
country_prop <- df %>%
  group_by(country) %>%
  mutate(num_recipes= n_distinct(X)) %>%
  filter(food %in% top100) %>%
  group_by(country, food) %>%
  mutate(recipes_with = n_distinct(X)) %>%
  mutate(prop = recipes_with /num_recipes) %>%
  ungroup()

# 5. Add overall row (global proportions)
overall_row <- overall_prop %>%
  filter(food %in% top100) %>%
  transmute(country = "Overall",
            food,
            prop = global_prop)

# 6. Combine
heatmap_data <- bind_rows(country_prop, overall_row)

# 7. Order ingredients by global popularity
ingredient_order <- overall_prop %>%
  slice_head(n = 50) %>%
  pull(food)

heatmap_data <- heatmap_data %>%
  mutate(country = factor(country,
                          levels = c("Tex-Mex",
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
                                     "Jewish","Overall"
                          )
                          
  )) %>% 
    mutate(food = factor(food, levels = ingredient_order))



# 8. Plot heatmap
heatmap <- ggplot(heatmap_data, aes(x = food, y = country, fill = prop)) +
  geom_tile(color = "white") +
  scale_y_discrete(labels = function(x) {
    ifelse(x == "Overall", paste0("**", x, "**"), x)
  }) +
  scale_fill_gradient(low = "white", high = "red") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1,size=6)) + 
  theme(axis.text.y = element_text(size=6)) + # requires ggtext
  labs(title = "Proportion of Recipes with Top 50 Ingredients",
       x = "Ingredient",
       y = "Country / Overall",
       fill = "Proportion") 

ggsave(filename="results/plots/06_heatmap.png",plot=heatmap,width=10, height=6,dpi=300)





