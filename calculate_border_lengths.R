library(sf)
library(dplyr)

us <- rnaturalearth::ne_states("United States of America")
us <- st_as_sf(us)
# Only the conterminous United States
us <- us %>% filter(!name %in% c("Alaska", "Hawaii"))
plot(us$geometry)
# Drop unnecessary columns
us <- us %>% select(postal)
us <- rename(us, state = postal)
us <- st_transform(us, crs = 2163)
plot(us)

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

# observe borders one by one, by manually looping over the code below
i <- 1

s1 <- borders[i, "STATE"]
s2 <- borders[i, "ADJ"]
s1 <- us[us$state == s1, ]
s2 <- us[us$state == s2, ]
border <- st_intersection(st_cast(s1$geometry, "MULTILINESTRING"),
                          st_cast(s2$geometry, "MULTILINESTRING"))
plot(border)
i <- i +1
# AZ-CO and NM-UT have just a point. So, zero probability. The others can be
# thought of as a straight line and approximated as the maximum distance between
# any point on the multilines.

# calculate border lengths
for(i in 1:nrow(borders)){
  s1 <- borders[i, "STATE"]
  s2 <- borders[i, "ADJ"]
  s1 <- us[us$state == s1, ]
  s2 <- us[us$state == s2, ]
  border <- st_intersection(st_cast(s1$geometry, "MULTILINESTRING"),
                            st_cast(s2$geometry, "MULTILINESTRING"))
  points <- st_cast(border, "POINT")
  borders[i, "b_length"] <- max(st_distance(points, points))
  # this distance is correct: https://www.daftlogic.com/projects-google-maps-distance-calculator.htm#
}

borders[borders$b_length == -Inf, "b_length"] <- 0

save(borders, us, file = "us_map_and_border_lengths.RData")
