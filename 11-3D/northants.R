library(rayshader)
library(raster)
library(tidyverse)
library(sf)
library(gdalUtils)
library(rgdal)
library(geoviz)
library(magick)

# EPSG strings
latlong = "+init=epsg:4326"
ukgrid = "+init=epsg:27700"
google = "+init=epsg:3857"


raster_list         <- list.files('rasters/', pattern='.asc$', full.names = T)

gdalbuildvrt(gdalfile = raster_list, # uses all tiffs in the current folder
             output.vrt = "rasters/temp.vrt")

gdal_translate(src_dataset = "rasters/temp.vrt", 
               dst_dataset = "merged.tif", 
               output_Raster = TRUE,
               options = c("BIGTIFF=YES", "COMPRESSION=LZW"))

data              <- raster('merged.tif')
raster::crs(data) <- ukgrid
data              <- aggregate(data, fact=10)
data              <- raster::projectRaster(data, crs=latlong)

data             <- raster_to_matrix(data)

overlay_image <-
  slippy_overlay(
    data,
    image_source = "stamen",
    image_type = "watercolor",
    png_opacity = 0.3
  )

data %>%
  sphere_shade(texture = "bw") %>%
  add_overlay(overlay_image) %>%
  plot_3d(data, zscale = 3, fov = 0, theta = 135, zoom = 0.75, phi = 45, windowsize = c(1000, 800))

filename_movie = 'northants'

data %>%
  sphere_shade(texture = "bw") %>%
  add_overlay(overlay_image) %>%
  plot_3d(data, zscale = 3, fov = 0, theta = 135, zoom = 0.75, phi = 45, windowsize = c(1000, 800))

render_movie(filename = filename_movie)
