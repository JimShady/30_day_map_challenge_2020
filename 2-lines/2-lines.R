library(sf)
library(osrm)
library(stplanr)
library(tidyverse)

msoa_centroids <- st_read('msoa_names_centroids.geojson') %>%
                    st_transform(4326)



for (i in 3906:nrow(msoa_centroids)) {
  
  print(i)
  
  start <- c(st_coordinates(msoa_centroids[i,])[1], st_coordinates(msoa_centroids[i,])[2])
  
  route <- route(from        = start,
                to          = c(-5.196699, 49.964804),
                route_fun   = osrmRoute,
                returnclass = "sf")
  
  if (exists('result')) {result <- bind_rows(result, route)} else {result <- route}
  
  Sys.sleep(0.3)
  
}

st_write(result, 'the_road_to_housel_bay.geojson')
