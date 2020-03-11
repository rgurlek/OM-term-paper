library(sf)
nc <- st_read(system.file("shape/nc.shp", package="sf"))
plot(nc$geometry[1])
plot(nc, max.plot = 1)
# sample random points on the border
plot(st_sample(st_cast(nc$geometry[1],"MULTILINESTRING"), 100))
# plot the points in the object
plot(st_cast(nc$geometry[1],"MULTIPOINT"))


# distance experiments
points <- st_cast(nc$geometry, "POINT")
st_distance(points[1], points[2])
s1 <- nc[nc$NAME == "Burke", ]
s2 <- nc[nc$NAME == "Caldwell", ]
plot(s1)
border <- st_intersection(s1$geometry, s2$geometry)
plot(border)
border
points <- st_cast(border, "POINT")
st_distance(points[1], points[length(points)])

download.file("https://biogeo.ucdavis.edu/data/gadm3.6/Rsf/gadm36_USA_1_sf.rds",
              "gadm36_USA_1_sf.rds")
us_states <- readRDS("gadm36_USA_1_sf.rds")
plot(st_sample(st_cast(us_states$geometry[10],"MULTILINESTRING"), 1000,
               type = "regular"))
line_list <- st_cast(st_cast(us_states$geometry[10],"MULTILINESTRING"), "LINESTRING")
line_lengths <- st_length(line_list)
line_lengths <- line_lengths / sum(line_lengths)
# sample lines with replacement. weight them by their lengths
line_list <- sample(line_list, size = 100, replace = T, prob = line_lengths)
plot(st_sample(line_list, rep(1, 100)))
