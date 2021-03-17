library(osmdata)
library(sf)
library(tidyverse)
library(glue)
library(rnaturalearth)

regions <- read.csv('https://gist.githubusercontent.com/radiac/d91d2ed1b971c03d49e9b7bd85e23f1c/raw/1e51ebb467b809ea8dcf1d7d429581e95ac48e3d/uk-counties-to-regions.csv') %>%
            rename_all(tolower)

rough_uk <- ne_countries(country = 'united kingdom', returnclass = 'sf')

uk_grid <- st_make_grid(rough_uk,
                        cellsize = c(diff(st_bbox(rough_uk)[c(1, 3)]), diff(st_bbox(rough_uk)[c(2, 4)]))/c(50,50),
                        offset = st_bbox(rough_uk)[c("xmin", "ymin")],
                        n = c(50, 50),
                        crs = 4326,
                        what = "polygons",
                        square = TRUE,
                        flat_topped = FALSE) %>% st_sf() %>% mutate(id = 1:nrow(.))

for (i in 1:nrow(uk_grid)) {
  
  message(glue("Downloading {i}"))
  
  temp_data <- opq(bbox = uk_grid[i,]) %>%
                  add_osm_feature(key = 'highway') %>%
                  osmdata_sf() %>%
                  .$osm_lines
  
  if (!is.null(temp_data)) {
    
  if ('name' %in% names(temp_data)) {message('name already exists')} else {temp_data <- mutate(temp_data, name = NA)}
  
  temp_data <- temp_data %>%
                select(name, geometry) %>%
                filter(grepl('north|south',name))
  
  message(glue("There are {nrow(temp_data)} rows of north or south streets"))
  
  if (nrow(temp_data) > 1) {
    
    temp_data$geometry <- st_centroid(temp_data$geometry)
    
    if (!exists('result')) {result <- temp_data} else { result <- bind_rows(result, temp_data) }
    
  }
  
  }
  
}

#https://data.london.gov.uk/dataset/local-authority-maintained-trees