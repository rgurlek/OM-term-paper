library(stringr)
library(sf)

sample_size <- 150

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

# calculate border lengths
for(i in 1:nrow(borders)){
  s1 <- borders[i, "STATE"]
  s2 <- borders[i, "ADJ"]
  s1 <- us[us$State == s1, ]
  s2 <- us[us$State == s2, ]
  border <- st_intersection(s1$geometry, s2$geometry)
  borders[i, "b_length"] <- sum(st_length(border))
}

# Sample indices from the borders
borders$prob <- borders$b_length / sum(borders$b_length)
border_sample <- sample(1:nrow(borders), sample_size,
                        replace = T, prob = borders$prob)
border_sample <- borders[border_sample, c("STATE", "ADJ")]
border_sample <- table(border_sample$STATE, border_sample$ADJ) %>% data.frame()
border_sample <- border_sample[border_sample$Freq != 0, ]
sum(border_sample$Freq)
borders <- merge(borders, border_sample, all.x = F,
# If not in the sample, will not be used anyway
                 by.x = c("STATE", "ADJ"), by.y = c("Var1", "Var2"))

point_sample <- function(b_row){
  s1 <- b_row["STATE"]
  s2 <- b_row["ADJ"]
  s1 <- us[us$State == s1, ]
  s2 <- us[us$State == s2, ]
  border <- st_intersection(s1$geometry, s2$geometry)
  plot(border)
  my_sample <- st_sample(border, as.numeric(b_row["Freq"]))
  my_sample <- my_sample[!is.na(st_dimension(my_sample))]
  return(my_sample)
}

final_sample <- suppressMessages(apply(borders, 1, point_sample))
# final_sample[[2]] # a list of multipoints
temp <- list()
for(i in final_sample){
  temp <- c(temp, st_cast(i,"POINT"))
}
final_sample <- temp

