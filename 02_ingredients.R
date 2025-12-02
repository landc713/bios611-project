########################################################################################
# Program Name:   02_standardize_ingredients
# Description:    Clean dataset for ingredients
# Author:         Lauren D'Costa
# Date Created:   2025-10-20
# Last Modified:  2025-11-27
# Notes:
# # Dependencies:   dplyr, tidyr, stringr,stringi,udpipe,striingdist
########################################################################################
# 
#
# 
# 
# 
# 
# 
# SET UP
# 
# 
# 
# 
# 
# 
########################################################################################
source("00_init.R")
########################################################################################
#UDPipe Model Download
# This is a NLP that helps automatically process raw text so we can remove adjectives from the 
# ingredients
########################################################################################
model <- udpipe_download_model(language = "english", model_dir = "data/")
udmodel <- udpipe_load_model(model$file_model)
########################################################################################
# Standardize units so we can easily remove them later
########################################################################################
unit_map <- c(
  # volume
  "cup" = "cup", "cups" = "cup",
  "tablespoon" = "tbsp", "tablespoons" = "tbsp", "tbsp" = "tbsp",
  "teaspoon" = "tsp", "teaspoons" = "tsp", "tsp" = "tsp",
  "liter" = "l", "liters" = "l", "l" = "l",
  "milliliter" = "ml", "milliliters" = "ml", "ml" = "ml",
  "quarts" = "qt", "quart" = "qt",
  "pints" = "pt", "pint" = "pt",
  
  # weight
  "gram" = "g", "grams" = "g", " g " = "g",
  "kilogram" = "kg", "kilograms" = "kg", "kg" = "kg",
  "ounce" = "oz", "ounces" = "oz", "oz" = "oz",
  "fl oz" = "oz", "fluid ounces" = "oz", "fluid ounce" = "oz",
  "pound" = "lb", "pounds" = "lb", "lb" = "lb",
  
  # containers
  "jar" = "jar", "jars" = "jar",
  "can" = "can", "cans" = "can",
  "bottle" = "bottle", "bottles" = "bottle",
  "package" = "pkg", "packages" = "pkg", "pkg" = "pkg",
  "container" = "pkg", "pkg." = "pkg",
  "box" = "box", "boxes" = "box",
  "carton" = "carton", "cartons" = "carton",
  "envelope" = "packet", "envelopes" = "packet",
  
  # pieces
  "slice" = "slice", "slices" = "slice",
  "clove" = "clove", "cloves" = "clove",
  "piece" = "piece", "pieces" = "piece",
  "loaf" = "loaf", "loaves" = "loaf",
  "roll" = "roll", "rolls" = "roll",
  "bun" = "bun", "buns" = "bun",
  "bagel" = "bagel", "bagels" = "bagel",
  "muffin" = "muffin", "muffins" = "muffin",
  
  # produce-specific
  "bunch" = "bunch", "bunches" = "bunch",
  "stalk" = "stalk", "stalks" = "stalk",
  "head" = "head", "heads" = "head",
  "leaf" = "leaf", "leaves" = "leaf",
  "sprig" = "sprig", "sprigs" = "sprig",
  "branch" = "branch", "branches" = "branch",
  "pod" = "pod", "pods" = "pod",
  "kernel" = "kernel", "kernels" = "kernel",
  
  # odd cases
  "stick" = "stick", "sticks" = "stick",
  "ear" = "ear", "ears" = "ear",
  "fillet" = "fillet", "fillets" = "fillet",
  "handful" = "handful", "handfuls" = "handful",
  "sheet" = "sheet", "sheets" = "sheet",
  "block" = "block", "blocks" = "block",
  "rib" = "rib", "ribs" = "rib",
  "bag" = "bag", "bags" = "bag",
  "bundle" = "bundle", "bundles" = "bundle",
  "cube" = "cube", "cubes" = "cube",
  "packet" = "packet", "packets" = "packet",
  "sparerib" = "sparerib", "spareribs" = "sparerib",
  "tub" = "tub", "tube" = "tube", "tubes" = "tube",
  
  # meat/protein cuts
  "steak" = "steak", "steaks" = "steak",
  "chop" = "chop", "chops" = "chop",
  "cutlet" = "cutlet", "cutlets" = "cutlet",
  "drumstick" = "drumstick", "drumsticks" = "drumstick",
  "wing" = "wing", "wings" = "wing",
  "patty" = "patty", "patties" = "patty",
  
  # recipe-specific
  "recipe pastry" = "pie crust",
  "pie crust" = "pie crust",
  
  # informal
  "pinch" = "pinch",
  "dash" = "dash", "dashes" = "dash",
  "drop" = "drop", "drops" = "drop",
  "strip" = "strip", "strips" = "strip",
  "jigger" = "jigger", "jiggers" = "jigger",
  "shot" = "shot", "shots" = "shot",
  "glass" = "glass", "glasses" = "glass",
  "cupful" = "cup", "cupfuls" = "cup",
  "knob" = "knob", "knobs" = "knob",
  "smidgen" = "smidgen", "smidgens" = "smidgen",
  "touch" = "touch", "touches" = "touch",
  "scoop" = "scoop", "scoops" = "scoop",
  "bar" = "bar", "bars" = "bar"
)
########################################################################################
# Function to convert measurement text to numeric
########################################################################################
parse_measurement <- function(x) {
  x <- str_trim(x)
  
  # Handle mixed fractions like "1 1/4"
  if (str_detect(x, "^[0-9]+\\s[0-9]+/[0-9]+$")) {
    parts <- str_split(x, "\\s")[[1]]
    whole <- as.numeric(parts[1])
    frac_parts <- str_split(parts[2], "/")[[1]]
    frac <- as.numeric(frac_parts[1]) / as.numeric(frac_parts[2])
    return(whole + frac)
  }
  
  # Handle simple fractions like "3/4"
  if (str_detect(x, "^[0-9]+/[0-9]+$")) {
    frac_parts <- str_split(x, "/")[[1]]
    return(as.numeric(frac_parts[1]) / as.numeric(frac_parts[2]))
  }
  
  # Handle decimals or integers
  if (str_detect(x, "^[0-9]+(\\.[0-9]+)?$")) {
    return(as.numeric(x))
  }
  
  # Handle common unicode fractions
  unicode_map <- c("½" = 0.5, "¼" = 0.25, "¾" = 0.75,
                   "⅓" = 1/3, "⅔" = 2/3,
                   "⅛" = 1/8, "⅜" = 3/8, "⅝" = 5/8, "⅞" = 7/8)
  if (x %in% names(unicode_map)) {
    return(unicode_map[[x]])
  }
  
  return(NA_real_) # fallback
}
########################################################################################
# Descriptors to remove bc UDPipe does not catch them all
########################################################################################
descriptors <- c(
  "small","medium","large","extralarge","jumbo","tiny","miniature","baby",
  "whole","half","quarter","fresh","frozen","canned","dried","bottled",
  "organic","natural","raw","cooked","lean","fatfree","reducedfat","lowfat","lowsodium",
  "chopped","diced","minced","sliced","shredded","grated","ground","crushed","powdered",
  "peeled","seeded","cored","trimmed","boneless","skinless","soft","firm","tender","crisp",
  "crunchy","creamy","smooth","coarse","fine","thick","thin","golden","brown","red","green",
  "yellow","white","ripe","unripe","sweet","sour","bitter","savory","spicy","tangy","zesty",
  "pungent","aromatic","smoked","roasted","toasted","uncooked","precooked","parboiled",
  "baked","fried","grilled","steamed","premium","gourmet","classic","traditional","homemade",
  "lowersodium","aged","allpurpose","asian","asianflavored","flavored","style","mix",
  "blue","bonein","bottle","breakfast","broken","chilled","chinese","chunk","chunky","classico",
  "coarsely","cold","confectioners","freshly","extravirgin","finely","thickcut","thai","thinly",
  "inches","inch","to tear serve on top","linguica","makrut","mashed","squares","lowmoisture","refrigerated",
  "hot","warm","cool","roomtemperature","lukewarm","blanched","boiled","drained","rinsed","pitted",
  "sauteed","stirfried","microwaved","dehydrated","underripe","overripe","tenderized","freshcut",
  "dayold","jarred","packaged","bagged","boxed","italian","mexican","indian","greek","french","japanese",
  "korean","mediterranean","texmex","unsweetened","sweetened","salted","unsalted","seasoned",
  "unseasoned","plain","instant","quickcooking","longgrain","shortgrain","mafalda","nonfat","fresh","and",
  "mixed","light","sugarfree","colaflavored","italianstyle","dry","sugarfree cook and serve","for dusting","sifted",
  "new","torn","splashes","splash","seedless","halved","american","any","bitesize","big","bitesized","black","roma",
  "all","purpose","melted","sharp"
)
########################################################################################
# Foods with unusual plural forms ( so we can correctly make all plurals into singles)
########################################################################################
food_irregulars <- c(
  "tomatoes" = "tomato",
  "potatoes" = "potato",
  "cherries" = "cherry",
  "berries" = "berry",
  "strawberries" = "strawberry",
  "blueberries" = "blueberry",
  "raspberries" = "raspberry",
  "cranberries" = "cranberry",
  "olives" = "olive",
  "grapes" = "grape",
  "leaves" = "leaf",
  "loaves" = "loaf",
  "sausages" = "sausage",
  "fishes" = "fish",
  "scallops" = "scallop",
  "clams" = "clam",
  "mussels" = "mussel",
  "eggs" = "egg",
  "lentils" = "lentil",
  "beans" = "bean",
  "peas" = "pea",
  "chickpeas" = "chickpea",
  "oats" = "oat",
  "noodles" = "noodle",
  "tortillas" = "tortilla",
  "cheeses" = "cheese",
  "yogurts" = "yogurt",
  "cookies" = "cookie",
  "brownies" = "brownie",
  "cupcakes" = "cupcake",
  "pies" = "pie"
)
########################################################################################
# 
#
# 
# 
# 
# 
# 
# START OF CODE
# 
# 
# 
# 
# 
# 
########################################################################################
########################################################################################
#read in data
########################################################################################
df <- read.csv("data/cuisines.csv", header = TRUE)
########################################################################################
#Clean ingredients and split
########################################################################################
df_split1 <- df %>%
             mutate(ingredients = str_squish(ingredients)) %>% 
             mutate(ingredients = str_trim(str_remove_all(ingredients, "\\b[0-9]+%\\b"))) %>% 
             mutate(ingredients = str_trim((str_replace_all(ingredients, "\\([^)]*\\)", "")))) %>%
             mutate(ingredients = str_trim((stri_trans_general(ingredients, "Latin-ASCII")))) %>%
             mutate(ingredients = str_trim(str_replace_all(ingredients, "\\([^)]*\\)", ""))) %>%
             mutate(ingredients = str_trim(ingredients)) %>%
             
  
             separate_rows(ingredients, sep = ",") %>% 
             mutate(row = row_number()) %>% 
             
             mutate(ingredients = str_replace_all(ingredients,"[^A-Za-z0-9 /.]", "")) %>% 
             mutate(ingredients = str_trim(ingredients)) %>%
  
             filter(grepl("^[0-9]", ingredients)) %>% 
             mutate(ingredients = str_squish(ingredients)) %>% 
             select(X,ingredients,row,country)
########################################################################################
#Split ingredients in amount, unit of measurement, and food(aka the actual ingredient)
########################################################################################
unit_keys <- str_replace_all(names(unit_map), "([\\W])", "\\\\\\1")
unit_pattern <- paste0("\\b(", paste((unit_keys), collapse = "|"), ")\\b")

df_units <- df_split1 %>%
            mutate(unit_raw = str_extract(str_to_lower(ingredients), regex(unit_pattern, ignore_case = TRUE)),
                   unit     = recode(unit_raw, !!!unit_map)) %>% 
            mutate(unit = case_when(
                                    !is.na(unit_raw) ~ recode(unit_raw, !!!unit_map),
                                    TRUE ~ "Item")) %>% 
            mutate(measurement = str_extract(ingredients,
                                             "^[0-9]+\\s[0-9]+/[0-9]+|^[0-9]+/[0-9]+|^[0-9]+(\\.[0-9]+)?"),
                   amount = sapply(measurement, parse_measurement)) %>% 
            mutate(food_raw = case_when(
              !is.na(unit_raw) ~ str_trim(
                str_remove(
                  str_remove(str_to_lower(ingredients), fixed(measurement, ignore_case = TRUE)),
                  regex(unit_raw, ignore_case = TRUE)
                )
              ),
              TRUE ~ str_trim(
                str_remove(str_to_lower(ingredients), fixed(measurement, ignore_case = TRUE))
              )
            )) %>% 
            mutate(food= str_squish((str_replace_all(food_raw, "[^A-Za-z ]", "")))) %>% 
            select(X,ingredients,unit,amount,food,row,country)
########################################################################################
# Remove generic descriptors and make everything singular
########################################################################################
descriptor_pattern <- paste0("\\b(", paste(descriptors, collapse="|"), ")\\b")

df_food <- df_units %>%
            mutate(food = str_squish(str_remove_all(food, regex(descriptor_pattern, ignore_case = TRUE)))) %>% 
            mutate(food = str_remove(food, "\\s+with.*")) %>% 
            mutate(food = str_remove(food, "\\s+or.*")) %>% 
            mutate(food = str_remove(food, "\\s+for.*"))%>%  
            mutate(food = str_remove(food, "\\s+from.*"))%>%  
            mutate(food = str_remove(food, "\\s+in.*"))%>%  
            mutate(food = str_remove(food, "\\s+plus.*"))%>%  
            mutate(food= case_when(
                                        str_to_lower(food) %in% names(food_irregulars) ~ food_irregulars[str_to_lower(food)],
                                        str_detect(food, "ies$") ~ str_replace(food, "ies$", "y"),
                                        str_detect(food, "oes$") ~ str_replace(food, "oes$", "o"),   
                                        str_detect(food, "ves$") ~ str_replace(food, "ves$", "f"),  
                                        str_detect(food, "s$")   ~ str_replace(food, "s$", ""),      
                                        TRUE ~ food)) %>% 
            filter(food != "") 

########################################################################################
# Use UDPipe for extra help removing adjectives
########################################################################################
table_food<- as.data.frame(table(df_food$food))

df_food$doc_id <- df_food$row

anno <- udpipe_annotate(udmodel, x = df_food$food,doc_id = df_food$doc_id)
anno <- as.data.frame(anno)

anno_no_adj <- anno %>% filter(!(upos == "ADJ" & lemma != "garlic"))
food_no_adj <- anno_no_adj %>%
                    group_by(doc_id, sentence_id) %>%
                    summarise(food = str_c(token, collapse = " "), .groups = "drop")
########################################################################################
# Use stringsdistmatrix to identify misspellings and pick the most popular one (usually the correct spelling)
########################################################################################
unique_food<- as.data.frame(table(food_no_adj$food)) %>% rename(food=Var1)

dist_mat <- stringdistmatrix(unique_food$food,unique_food$food,, method = "jw")

hc <- hclust(as.dist(dist_mat))
clusters <- cutree(hc, h = 0.10) 

clustered<- unique_food %>%
              mutate(cluster = clusters)

duplicates <- clustered %>% group_by(cluster) %>% filter(n() > 1) %>% arrange((cluster))

representatives <- duplicates %>%
                   group_by(cluster) %>%
                   arrange(desc(Freq)) %>%
                   mutate(rep = if_else(row_number() == 1, food, NA_character_)) %>%
                   fill(rep, .direction = "down") %>%
                   ungroup() %>% 
                   select(food,rep)


fixed <- merge(food_no_adj, representatives, by = "food", all.x = TRUE)  %>% 
         mutate(food2 = if_else(!is.na(rep), rep, food)) %>% 
         select(food2,doc_id) %>% 
         rename(food_fixed=food2) %>% arrange(as.numeric(doc_id))
########################################################################################
# Merge everything back in to create a final dataset
########################################################################################
final <- merge(df_food, fixed, by = "doc_id", all.x = TRUE) %>% 
         arrange(as.numeric(doc_id)) %>% 
         select(X, row, ingredients,unit,amount,food_fixed,country) %>% 
         rename(food=food_fixed)

final_count<- as.data.frame(table(final$food)) %>% rename(food=Var1) 

write.csv(final, "data/ingredients.csv", row.names = TRUE)
