library(tidyr)
library(dplyr)
library(plyr)
seed <- 8234


# Plot the sampled border points ####
point_sample <- list()
for(i in seq(1234, seed, 1000)){
  point_sample <- c(point_sample, readRDS(paste0("point_sample_", seed, ".rds")))
}
plot(st_geometrycollection(point_sample))
length(point_sample)

# An example from the original data ####
library(yelpr)

key <- readLines("api_key.txt")
radius = 16000 # about 10 miles
longitude <- -85.01723
latitude <- 31.00204
bus_data <- suppressMessages(business_search(
  api_key = key,
  latitude = latitude,
  longitude = longitude,
  radius = radius,
  limit = 50 
))
bus_data <- bus_data$businesses
bus_data$categories

# Descriptive Stats From Raw Data ####
raw_data <- read.csv("raw_data.csv")
state_counts <- table(raw_data$state)
state_counts <- sort(state_counts, decreasing = T)
length(state_counts)

aggregate(raw_data[, c("review_count", "rating", "price", "CombinedRate")],
          list(raw_data$is_focal), mean, na.rm = T)
focal <- raw_data[raw_data$is_focal, ]
non_focal <- raw_data[!raw_data$is_focal, ]
t.test(focal$rating, non_focal$rating)
t.test(focal$price, non_focal$price)
t.test(focal$CombinedRate, non_focal$CombinedRate)

# Regression ####

library(AER)
model <- lm(rating ~ StateRate + CountyRate + CityRate + SpecialRate,
            data = reg_data)
summary(model)

model <- lm(rating ~ review_count + price, data = reg_data)
summary(model)

model <- ivreg(rating ~ review_count + price | review_count + StateRate +
                 CountyRate + CityRate + SpecialRate, data = reg_data)
summary(model)


library(ggeffects)
mydf <- ggpredict(model, terms = "price [all]")
plot(mydf)

ggplot(reg_data, aes(x = price, y = rating)) +
  geom_point()

model <- ivreg(rating ~ review_count + price| review_count + StateRate +
                 CountyRate + CityRate + SpecialRate, data = reg_data)
summary(model)


model <- ivreg(rating ~ review_count + price| review_count + CombinedRate,
               data = reg_data)
summary(model)

model <- lm(price ~ CombinedRate, data = reg_data)
summary(model) # How do tax and price are negatively correlated. Reconsider your
# demaining approach. Does it change the interpretation?