########################################################################################
# Program Name:   06_pca
# Description:    pca on ingredients
# Author:         Lauren D'Costa
# Date Created:   2025-11-24
# Last Modified:  
# Dependencies:   dplyr, ggplot2, tidyr, stringr
# Notes: 
########################################################################################
source("00_init.R")
########################################################################################
#read in data
########################################################################################
cuisines <- read.csv("data/cuisines.csv", header = TRUE)
regions <- read.csv("data/regions.csv", header = TRUE) %>% select(-X)
ing <- read.csv("data/ingredients.csv", header = TRUE) %>% select(-X.1)

crosswalk<- merge(cuisines,regions,by="country") %>% select(X,region,country)
df <- merge(ing,crosswalk, by = "X") %>% select(-country.y)

#remove uninformative foods
uninformative <- c("sugar","onion","butter","flour","sauce","water","oil","egg","salt",
                   "garlic","milk","pepper","baking powder","cornstarch","baking soda")

df3 <- df %>% filter(!str_detect(food, str_c(uninformative, collapse = "|")))


#get top 500 foods
df4 <- df3 %>% 
       count(food) %>% 
       arrange(desc(n)) %>% 
       slice_head(n = 500) 


top500 <- as.vector(df4$food)

#filter to the recipes with the top 500 foods
df5 <- df3 %>%
       filter(food %in% top500)

#get raw counts of times food appears in the country's recipes
m1 <- (table(df5$country,df5$food)) %>% as.matrix()

#normalize
m_prop <- sweep(m1, 1, rowSums(m1), FUN = "/")

########################################################################################
# PCA
########################################################################################

results <- prcomp(m_prop, center = TRUE, scale. = TRUE)

var<- results$sdev*results$sdev
var_prop<- var/sum(var)
cumulative<- cumsum(var/sum(var))
print(cumulative)


#Get data for scree plot
scree_data<- data.frame(component = 1:length(var),
                           eigenvalue =var_prop)

#Create the plot with ggplot2
scree <- ggplot(scree_data, aes(x = component, y = eigenvalue)) +
  geom_line() +
  geom_point() +
  labs(title = "Scree Plot of PCA for Ingredients",
       x = "Principal Component",
       y = "Proportion of Variance") + 
  scale_x_continuous(breaks = seq(0,length(var),5))+
  scale_y_continuous(breaks = seq(0,1,0.025)) + 
  theme_allrecipes(base_size=8)


#add in cuisine
x_df <- as_tibble(results$x) %>%
          mutate(country = rownames(results$x))

merged_df <- merge(x_df,regions,by="country",all=TRUE)

merged_df$region <- factor(merged_df$region, levels = names(region_colors))


pca <- ggplot(merged_df  , aes(x =PC1, y =PC2,color=region)) +
       geom_point(size=1) +
       scale_color_manual(values = region_colors) + theme_minimal()+
       labs(title = "Scatterplot of Principal Component 1 and 2 ",
            color  = "Geographic Region:",
            x = "PC1",
            y = "PC2") + 
      geom_text_repel(label=merged_df$country,size=3,show.legend = FALSE) + 
      theme_allrecipes(base_size=8)



# Get loadings (which ingredients contribute most to each PC)
m_loading <-results[["rotation"]]

pc1_loading <- as.data.frame(m_loading)%>%
  mutate(ingredient= rownames(m_loading))%>% 
  select(ingredient,PC1) %>% 
  arrange(desc(PC1))

pc2_loading <- as.data.frame(m_loading)%>%
  mutate(ingredient = rownames(m_loading))%>% 
  select(ingredient,PC2)%>% 
  arrange(desc(PC2))


print(head(pc1_loading, 10))
print(head(pc2_loading, 10))

save(pc1_loading, file = "results/tables/pc1_loading.RData")
save(pc2_loading, file = "results/tables/pc2_loading.RData")

ggsave(filename="results/plots/07_scree.png",plot=scree,width=8, height=5,dpi=300)
ggsave(filename="results/plots/08_pca.png",plot=pca,width=8, height=5,dpi=300)
