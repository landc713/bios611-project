########################################################################################
# Program Name:   06_pca
# Description:    pca on ingredients
# Author:         Lauren D'Costa
# Date Created:   2025-11-24
# Last Modified:  2025/12/1
# Dependencies:   dplyr, ggplot2, rtsne
# Notes: added tsne
########################################################################################
source("00_init.R")
################################################################################
# Load Data
################################################################################
cuisines <- read.csv("data/cuisines.csv", header = TRUE)
regions  <- read.csv("data/regions.csv", header = TRUE) %>% select(-X)
ingredients <- read.csv("data/ingredients.csv", header = TRUE) %>% select(-X.1)

# Crosswalk table
crosswalk <- merge(cuisines, regions, by = "country") %>%
  select(X, region, country, name,url)

# Merge ingredients with cuisines
df <- merge(ingredients, cuisines, by = "X") %>%
  select(-country.y)

################################################################################
# Create Recipe–Ingredient Matrix
################################################################################
df2 <- df %>%
  mutate(present = 1) %>%
  distinct(X, name, food, .keep_all = TRUE)

df3 <- df2 %>%
  pivot_wider(
    id_cols     = name,
    names_from  = food,
    values_from = present,
    values_fill = list(present = 0)
  ) %>%
  arrange(name) %>%
  as.data.frame()

# Set rownames = recipe IDs
rownames(df3) <- df3$name
df3$name <- NULL

# Final matrix
mat <- as.matrix(df3)
mat_scaled <- scale(mat)

################################################################################
# PCA
################################################################################
results <- prcomp(mat_scaled)
# Variance explained
var        <- results$sdev^2
var_prop   <- var / sum(var)
cumulative <- cumsum(var_prop)
#print(cumulative)
# Efficient PCA for large sparse matrices
results <- prcomp_irlba(mat_scaled,n=100)

var        <- results$sdev^2
var_prop   <- var / sum(var)
cumulative <- cumsum(var_prop)
#print(cumulative)

# Scree plot data
scree_data <- data.frame(
  component  = seq_along(var),
  eigenvalue = var_prop
)

scree_plot <- ggplot(scree_data, aes(x = component, y = eigenvalue)) +
  geom_line() +
  geom_point() +
  labs(
    title = "Scree Plot of PCA for Ingredients",
    x     = "Principal Component",
    y     = "Proportion of Variance"
  ) +
  scale_x_continuous(breaks = seq(0, length(var), 5)) +
  theme_allrecipes(base_size = 8)

################################################################################
# Names for Merging
################################################################################
names <- results$x %>%
  as.data.frame() %>%
  mutate(name = rownames(mat_scaled))
################################################################################
# t-SNE
################################################################################
tsne_res <- Rtsne(
  results$x,
  dims      = 2,
  perplexity = 40,
  verbose   = TRUE,
  check_duplicates=FALSE
)

tsne_df <- data.frame(
  name = names$name,
  X           = tsne_res$Y[, 1],
  Y           = tsne_res$Y[, 2]
)

# Merge with regions
merged_df <- merge(tsne_df, crosswalk, by.x = "name", by.y = "name") %>% 
  rename(ID=X.y,X=X.x)
merged_df$region <- factor(merged_df$region, levels = names(region_colors))


t_sne_plot <- ggplot(merged_df, aes(x = X, y = Y, color = region)) +
  geom_point(alpha = 0.7) +
  theme_minimal() +
  scale_color_manual(values = region_colors) +
  labs(title = "t-SNE of Recipes by Cuisine",
       color  = "Geographic Region:",
       x = "X",
       y = "Y")

################################################################################
# Save Plots
################################################################################
saveRDS(merged_df, "data/tsne.rds")
ggsave("results/plots/07_scree.png", plot = scree_plot, width = 8, height = 5, dpi = 300)
ggsave("results/plots/08_t_sne.png", plot = t_sne_plot, width = 8, height = 5, dpi = 300)
