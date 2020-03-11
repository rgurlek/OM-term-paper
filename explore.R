library("jsonlite")
library("geosphere")
# Read the yelp business dataset
my_data <- readLines("C:/Users/rgurlek/Desktop/yelp/business.json")
my_data <- stream_in(textConnection(gsub("\\n", "", my_data)))
my_data <- my_data[, c("business_id", "state", "latitude", "longitude")]
# A few lines to see the necessary restrictions for search
# coordinates for the neighbors
max_latitude <- max(my_data$latitude) #as we go north 10 km means more longitude
distm(c(1/5,max_latitude),
      c(0,max_latitude),
      fun = distHaversine)/1000 #1/5 longitude dif would mean at least 13 km at most 18 km
distm(c(0,0.1),
      c(0,0),
      fun = distHaversine)/1000 #0.1 latitude dif means 11 km regardless of longitude
# small prepretion of data
state_list <- unique(my_data$state)
data_list <- lapply(state_list, function(x){
  my_data[my_data$state == x, ]
})
names(data_list) <- state_list
remove(my_data)
state_adj <- read.csv("state_adjacency.csv")
state_adj <- lapply(state_list, function(x){
  state_adj[state_adj$STATE == x, "ADJ"]
})
names(state_adj) <- state_list
adj_count <- sapply(state_adj, length)
count_table <- sapply(data_list, nrow)
data_list <- data_list[count_table > 100]

state_list <- names(data_list)
state_adj <- read.csv("state_adjacency.csv")
state_adj <- lapply(state_list, function(x){
  x <- as.character(state_adj[state_adj$STATE == x, "ADJ"])
  x[x %in% state_list]
})
names(state_adj) <- state_list
adj_count <- sapply(state_adj, length)
data_list <- data_list[adj_count > 0]
state_adj <- state_adj[adj_count > 0]
count_table <- sapply(data_list, nrow)
# for (i in 1:length(state_adj)){ # With this one, the neighbors include own state
#   state_adj[[i]] <- c(state_adj[[i]], names(state_adj)[i])
# }
fun_apply1 <- function(x){
  fun_apply2 <- function(y){
    distm(c(x_long, x_lat),
          as.numeric(comp_data[comp_data$business_id == y,
                               4:3]),
          fun = distHaversine)
  }
  state_data <- data_list[[i]][data_list[[i]] == x, ]
  dist_vec <- NA
  for (j in state_adj[[i]]){
    x_lat <- state_data[, "latitude"]
    x_long <- state_data[, "longitude"]
    comp_data <- data_list[[j]]
    comp_vec <- comp_data$business_id[abs(comp_data$latitude - x_lat) < 1 &
                                      abs(comp_data$longitude - x_long) < 1]
    if(length(comp_vec) == 0) return(NA)
    # subset max 10 km distance
    dist_vec <- c(dist_vec, sapply(comp_vec, fun_apply2) / 1000)
    dist_vec <- dist_vec[dist_vec<10]
  }
  return(dist_vec)
}
library(parallel)
no_cores <- detectCores() - 1
cl <- makeCluster(no_cores)

state_list <- names(data_list)
distances <- list() # States - Businesses - Paired Bus.
for (i in c("NC", "SC")) { # More efficient way is to compare two states
  #only once
  clusterExport(cl, c("i","data_list", "state_adj"))
  clusterEvalQ(cl, library(geosphere))
  a <- Sys.time()
  dist_list <- parLapply(cl, data_list[[i]]$business_id,
                         fun_apply1)
  names(dist_list) <- data_list[[i]]$business_id
  distances[[i]] <- dist_list
  print(Sys.time() - a)
}
stopCluster(cl)
remove(dist_list)
distances <- lapply(distances, function(x){
  x <- lapply(x, function(y){
    if (length(y[!is.na(y)]) > 0){
      return(y[!is.na(y)])
    } else {
      return(NULL)
    }
  })
  x[sapply(x, is.null)] <- NULL
  return(x)
})
distance_matrix <- matrix(NA, nrow = length(distances$NC),
                          ncol = length(distances$SC),
                          dimnames = list(names(distances$NC),
                                          names(distances$SC)))
for(i in 1:length(distances$SC)){# neigh. is reflective relation. Only SC is enough
  x <- names(distances$SC[[i]])
  y <- names(distances$SC)[[i]]
  distance_matrix[x,y] <- distances$SC[[i]]
}
remove(distances)
save(distance_matrix, file = "distance_matrix.RData")

# Demean ####
# Feature setlerini olustur iki veri icin de. Neler olsun karar ver.
# Zipcode'dan degisik vergi cesitlerini cek.
# Orjinal datada olan otopark gibi seyleri de koy
library("jsonlite")
load(file = "distance_matrix.RData")
my_data <- readLines("C:/Users/rgurlek/Desktop/yelp/business.json")
my_data <- stream_in(textConnection(gsub("\\n", "", my_data)))
my_data <- my_data[my_data$business_id %in% c(rownames(distance_matrix),
                                              colnames(distance_matrix)), ]
my_data <- data.frame(my_data[, ! colnames(my_data) %in% c("attributes", "hours")],
                      my_data$attributes, my_data$hours)
col_NAs <- lapply(my_data, function(x){
  sum(is.na(x))
  })
col_NAs[col_NAs < 1000]
my_data <- my_data[, 1:11]
my_data <- lapply(my_data, function(col){
  if (is.character(col))
    return(as.factor(col))
  else
    return(col)
})
my_data <- data.frame(my_data)
tax_rates <- read.csv("tax_rates.csv")
library(stringr)
names(tax_rates) <- str_remove(names(tax_rates), "Estimated")
my_data <- merge(my_data, tax_rates, by.x = "postal_code", by.y = "ZipCode",
             all.x = T)
my_data <- my_data[!is.na(my_data$StateRate), ] # some observations do not have postal code
# or tax_rates data does not have info for their zipcode. Deal with this later
NC_data <- my_data[my_data$state == "NC", ]
SC_data <- my_data[my_data$state == "SC", ]
# Some observations have zipcodes that conflicts with their State. Drop them.
# For example, yau0HbUmuSkmRoHORKum0w is Le Méridien Charlotte and its zipcode is
# 28204 not 29204. Latitude and longitude seem correct. Correct these zipcodes,
# instead of droping them?
table(NC_data$state, NC_data$StateRate)
table(SC_data$state, SC_data$StateRate)
NC_data <- NC_data[NC_data$StateRate == 0.0475, ]
SC_data <- SC_data[SC_data$StateRate == 0.06, ]
# Distance matrix is NC by SC
hist(rowSums(!is.na(distance_matrix)))
table(rowSums(!is.na(distance_matrix)))
distance_matrix <- distance_matrix[as.character(NC_data$business_id), 
                                   as.character(SC_data$business_id)]
distance_matrix <- distance_matrix / rowSums(distance_matrix, na.rm = T)
table(rowSums(!is.na(distance_matrix)))
# It seems droping those miscoded zipcodes above causes a significant number of
# observations from the other side of the border to have zero neighbors.
distance_matrix[is.na(distance_matrix)] <- 0 # treat NAs as zero for matrix mult.
z_NC <- distance_matrix %*% as.matrix(SC_data[,c("StateRate","CountyRate",
                                                 "CityRate", "SpecialRate", "stars")])
# Drop guys with zero neighbors and correct staterates which are slightly
# different than 0.06 due to numerical precision in matrix mult.
z_NC <- z_NC[!z_NC[,"StateRate"] == 0, ]
z_NC[,"StateRate"] <-  0.06
x_bar_NC <- as.matrix(NC_data[as.character(NC_data$business_id) %in%
                                rownames(z_NC), c("StateRate","CountyRate",
                                                  "CityRate", "SpecialRate", "stars")]) -
  z_NC
rownames(x_bar_NC) <- rownames(z_NC)

dim(x_bar_NC)
unique(x_bar_NC[,1]) # this is constant as expected
hist(x_bar_NC[,2])
unique(x_bar_NC[,3]) # No city rate. Drop this
x_bar_NC <- x_bar_NC[,-3]
hist(x_bar_NC[,4]) # small variance. 0.01 and 0.005 are the only values

reg_model <- lm(formula = stars ~ . -1, data.frame(x_bar_NC))
summary(reg_model)
# increased state rate -> decreased star
lapply(SC_data[, c("StateRate", "stars", "CombinedRate")], mean)
lapply(NC_data[, c("StateRate", "stars", "CombinedRate")], mean)
# SC has higher state rate. NC has higher combined rate and stars.



# Reviews ####
library("jsonlite")
my_data <- readLines("C:/Users/rgurlek/Desktop/yelp/review.json")
my_data <- stream_in(textConnection(gsub("\\n", "", my_data)))
min(my_data$date)
table(format(as.Date(my_data$date),"%Y"))
# oldest review is from 2004. I can discard the old ones and calculate average rating
# for the restaurants I will use. First, compare rating of a business with what you
# calculate for the full data (all years). Reviews may lack the ratings without review.
bus_subsample <- my_data$business_id[seq(10000,nrow(my_data), 10000)]
rev_subsample <- qwe[qwe$business_id %in% bus_subsample, ]
calc_star <- aggregate(rev_subsample$stars, by = list(rev_subsample$business_id), mean)
names(calc_star)[1] <- "business_id"
merge(calc_star, my_data[my_data$business_id %in% bus_subsample,
                         c("business_id", "stars")])
