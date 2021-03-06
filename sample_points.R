library(stringr)
library(sf)

seed <- 8234
set.seed(seed)
sample_size <- 4000

# This file is generated by calculate_border_length.R script
load("us_map_and_border_lengths.RData")
plot(us)

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
plot(st_geometrycollection(final_sample))

saveRDS(final_sample, paste0("point_sample_", seed, ".rds"))