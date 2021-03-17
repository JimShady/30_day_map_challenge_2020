library(glow)
library(RPostgres)
library(tidyverse)
library(viridis)
library(sf)

config <- read_csv('../../config_files/spire-vessel-scraping.csv')

con                       <- dbConnect(RPostgres::Postgres(),
                                       dbname = config$dbname,
                                       host = config$host,
                                       port = config$port,
                                       user = config$user,
                                       password = config$password)



vessel_data <- dbGetQuery(con, 'SELECT ship_type,
                                    most_recent_voyage_destination,
                                    CASE WHEN last_known_position_latitude IS NULL THEN predicted_position_latitude
                                    ELSE last_known_position_latitude
                                    END AS latitude,
                                    CASE WHEN last_known_position_longitude IS NULL THEN predicted_position_longitude
                                    ELSE last_known_position_longitude
                                    END AS longitude
                             FROM   vessel_table 
                             WHERE  scrape_time = (SELECT max(scrape_time) FROM data_quantity_log)')


gm <- glow::GlowMapper$new(xdim=2000, ydim = 2000, blend_mode = "additive", nthreads=4)

filter <- filter(vessel_data, longitude > -12 & longitude < 6 & latitude > 50 & latitude < 60)

gm$map(x=filter$longitude,
       y=filter$latitude,
       intensity=0.5,
       radius = .1)

pd <- gm$output_dataframe(saturation = quantile(gm$output, 0.995))

countries <- st_read('ne_10m_admin_0_countries.shp')

ggplot() + 
  geom_raster(data = pd, aes(x = pd$x, y = pd$y, fill = pd$value), show.legend = F) +
  scale_fill_gradientn(colors = additive_alpha(magma(6))) + 
  geom_sf(data = countries, fill = NA, col = 'grey', size=0.2) +
  labs(x = "Longitude", y = "latitude") +
  theme(panel.grid = element_blank(),
        panel.background = element_rect(fill = 'black'),
        axis.ticks = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank()) +
  xlim(c(-12, 6)) +
  ylim(c(50,60))
