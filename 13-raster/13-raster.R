library(tidyverse)
library(glue)
library(sf)
library(raster)
library(ggplot2)

rough_uk <- st_read('Counties_and_Unitary_Authorities__December_2016__Boundaries.geojson') %>%
  st_transform(27700)

years <- 2010:2019

plot_list <- list()

for (i in 1:length(years)) {
  
  message(years[[i]])
  
  pm25_data <- read_csv(glue("https://uk-air.defra.gov.uk/datastore/pcm/mappm25{years[[i]]}g.csv"),
                        skip=5) %>%
    dplyr::select(-ukgridcode) %>%
    rename(pm25 = glue("pm25{years[[i]]}g")) %>%
    mutate(pm25 = as.numeric(pm25),
           year = years[[i]]) %>%
    filter(pm25 > 10)
  
  plot_list[[i]] <- ggplot() +
    geom_sf(data=rough_uk, fill = "white") +
    geom_raster(data = filter(pm25_data, !is.na(pm25) & pm25 > 10),
                aes(x = x, y = y), na.rm=T,alpha=0.5, fill="red") + 
    coord_sf(ylim = c(0,650000),xlim=c(120000,655000)) +
    theme(axis.text        = element_blank(),
          axis.ticks       = element_blank(),
          axis.title       = element_blank(),
          panel.background = element_rect(fill="lightblue"),
          panel.grid       = element_blank(),
          panel.border     = element_rect(colour = "black", fill=NA, size=1),
          plot.title       = element_text(size = 50, vjust = -4),
          plot.margin=grid::unit(c(0,0,0,0), "mm")) +
    labs(title = years[[i]])
  
  png(glue("gifs/{years[[i]]}.png"))
  print(plot_list[[i]])
  dev.off()
  
  system("cmd.exe", input = glue('cd {getwd()}/gifs && "C:\\Program Files\\ImageMagick-7.0.10-Q16-HDRI\\magick" convert {years[[i]]}.png {years[[i]]}.gif'))
  unlink(glue("gifs/{years[[i]]}.png"))
  
}

system("cmd.exe", 
       input = glue('cd {getwd()}/gifs && "C:\\Program Files\\ImageMagick-7.0.10-Q16-HDRI\\magick" convert -delay 80 *.gif -loop 0 pm25_over_10.gif'))
