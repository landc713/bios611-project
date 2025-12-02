source("00_init.R")
df <- readRDS("data/tsne.rds")
fig <- plot_ly()

for(r in unique(df$region)){
  df_r <- subset(df, region == r)
  
  for(c in unique(df_r$country)){
    df_c <- subset(df_r, country == c)
    
    fig <- fig %>%
      add_trace(
        data = df_c,
        x = ~X, y = ~Y,
        type = "scatter", mode = "markers",
        name = c,
        legendgroup = r,
        legendgrouptitle = if(c == unique(df_r$country)[1]) list(text = r) else NULL,
        marker = list(size = 4, opacity = 0.7),
        hoverinfo = "text",
        text = ~paste("Recipe:", name, "<br>Cuisine:", country),
        color = ~region,            
        colors = region_colors,  
        customdata = ~url
      )
  }
}

fig2 <- fig %>%
  layout(
    title = "t-SNE of Recipes in 2D<br><sup>Click a point to open its recipe page</sup>",
    legend = list(
      title = list(text = "Geographic Region / Country"),
      itemclick = "toggle",
      itemdoubleclick = "toggleothers"
    ),
    xaxis = list(title = "X"),
    yaxis = list(title = "Y")
  )

# Add JavaScript click handler
fig3 <- htmlwidgets::onRender(fig2, "
function(el, x){
  el.on('plotly_click', function(d){
    var url = d.points[0].customdata;
    if(url){ window.open(url, '_blank'); }
  });
}")


saveWidget(fig3, "results/plots/tsne_recipes.html", selfcontained = TRUE)









