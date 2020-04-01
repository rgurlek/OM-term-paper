library(sf)

us <- readRDS("gadm36_USA_1_sf.rds")
# Only the conterminous United States
us <- us[!us$NAME_1 %in% c("Alaska", "Hawaii"), ]
plot(us$geometry)
# Drop unnecessary columns
names(us)
us <- us[,-c(1:9)]
plot(us)
# Get rid of US. in State names
names(us)[1] <- "State"
us$State <- str_remove(us$State, "US.")

# import borders
adj <- read.csv("state_adjacency.csv")
borders <- adj[0,]
for(i in 1:nrow(adj)){
  cond <- sum(borders$ADJ == adj$STATE[i] & borders$STATE == adj$ADJ[i])
  if(!cond){
    borders <- rbind(borders, adj[i, ])
  }
}
length(unique(adj$STATE))
nrow(us)

# observer borders one by one, by manually looping over the code below
i <- 1

s1 <- borders[i, "STATE"]
s2 <- borders[i, "ADJ"]
s1 <- us[us$State == s1, ]
s2 <- us[us$State == s2, ]
border <- st_intersection(s1$geometry, s2$geometry)
plot(border)
i <- i +1
# AZ-CO and NM-UT have just a point. So, zero probability. The others can be
# thought of as a straight line and approximated as the maximum distance between
# any point on the multilines.

# calculate border lengths
for(i in 1:nrow(borders)){
  s1 <- borders[i, "STATE"]
  s2 <- borders[i, "ADJ"]
  s1 <- us[us$State == s1, ]
  s2 <- us[us$State == s2, ]
  border <- st_intersection(s1$geometry, s2$geometry)
  points <- st_cast(border, "POINT")
  borders[i, "b_length"] <- max(st_distance(points, points))
  # this distance is correct: https://www.daftlogic.com/projects-google-maps-distance-calculator.htm#
}

save(borders, us, file = "us_map_and_border_lengths.RData")