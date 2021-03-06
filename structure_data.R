library(dplyr)
library(sf)
library(stringr)
seed <- 8234


# rest_data contains a list of restaurant clusters around 
# a border point. It is generated by collect_rest_data.R
rest_data <- list()
for(i in seq(1234, seed, 1000)){
  rest_data <- c(rest_data, readRDS(paste0("rest_data2_", seed, ".rds")))
}

rest_data[[1]]

# drop the clusters with less than 2 states
meets_requirement <- function(cluster){
  has_price <- !is.na(cluster$price) 
  has_zip <- !is.na(cluster$zip) 
  cluster <- cluster[has_price & has_zip, ]
  states <- length(unique(cluster$state))
  return(states > 1)
}

keep_cluster <- sapply(rest_data, meets_requirement)
rest_data <- rest_data[keep_cluster]

# read tax data
tax_rates <- do.call(rbind,
                     lapply(list.files(path = "./TAXRATES_ZIP5",
                                       pattern = "*.csv",
                                       full.names = T),
                            read.csv, header = T,
                            colClasses = c(ZipCode = "character"))) 
names(tax_rates) <- str_remove(names(tax_rates), "Estimated")
tax_rates <- tax_rates[, c("ZipCode", "StateRate", "CountyRate", "CityRate",
                           "SpecialRate", "CombinedRate")]

# Decide who is focal
n_states <- sapply(rest_data, function(x)length(unique(x$state)))
table(n_states)
state_combinations <- sapply(rest_data, function(x){
  paste(sort(unique(x$state)), collapse = "_")})
state_combinations <- unique(state_combinations)
who_focal <- strsplit(state_combinations, "_")
names(who_focal) <- state_combinations
who_focal <- sapply(who_focal, sample, size = 1)

# Learn who is in which cluster
uniq_focal <- sapply(rest_data, function(x){
  focal <- who_focal[paste(sort(unique(x$state)), collapse = "_")]
  unique(x[x$state == focal, "id"])
})
uniq_focal <- unlist(uniq_focal)
uniq_focal <- unique(uniq_focal)

uniq_nonfocal <- sapply(rest_data, function(x){
  focal <- who_focal[paste(sort(unique(x$state)), collapse = "_")]
  unique(x[! x$state %in% focal, "id"])
})
uniq_nonfocal <- unlist(uniq_nonfocal)
uniq_nonfocal <- unique(uniq_nonfocal)

raw_data <- data.frame()
reg_data <- data.frame()
z <- 0
for(id in uniq_focal){
  z <- z + 1
  cat("\r", z)
  if(is.na(id)) next()
  clusters <- names(rest_data)[sapply(rest_data, function(x) id %in% x$id)]
  focal <- rest_data[[clusters[1]]][rest_data[[clusters[1]]]$id == id, ]
  if(sum(is.na(focal[, c("price", "state")]))) next()
  price_dic <- 1:4
  names(price_dic) <- c("$", "$$", "$$$", "$$$$")
  focal$price <- price_dic[focal$price]
  focal <- merge(focal, tax_rates, by.x = "zip_code", by.y = "ZipCode",
                   all.x = T)
  focal <- focal[!is.na(focal$StateRate)]
  if(nrow(focal) == 0) next
  focal$is_focal <- T
  
  nonfocal <- lapply(rest_data[clusters], function(x){
    x[x$state != focal$state, ]
  })
  nonfocal <- do.call(rbind, nonfocal)
  nonfocal <- nonfocal[!duplicated(nonfocal$id), ]
  nonfocal <- nonfocal[complete.cases(nonfocal[, c("price", "state")]), ]
  nonfocal$price <- price_dic[nonfocal$price]
  nonfocal <- merge(nonfocal, tax_rates, by.x = "zip_code", by.y = "ZipCode",
                     all.x = T)
  nonfocal <- nonfocal[!is.na(nonfocal$StateRate), ]
  if(nrow(nonfocal) == 0) next
  nonfocal$is_focal <- F
  raw_data <- rbind(raw_data, focal, nonfocal)
  
  # split the data and make both sf objects. Calculate proxy mat
  focal_coord <- focal[,c("longitude", "latitude")]
  focal <- st_as_sf(focal, coords = c("longitude", "latitude"))
  nonfocal <- st_as_sf(nonfocal, coords = c("longitude", "latitude"))
  st_crs(focal) <- 4326
  st_crs(nonfocal) <- 4326
  proxy_mat <- 1 / st_distance(focal, nonfocal) # rows: Focal, columns: nonFocal
  dimnames(proxy_mat) <- list(focal$id, nonfocal$id)
  proxy_mat <- proxy_mat / rowSums(proxy_mat, na.rm = T)
  # Subset dataframes and convert to matrix
  st_geometry(focal) <- NULL
  focal_mat <- as.matrix(focal[, c("review_count", "rating", "price", "StateRate",
                                   "CountyRate", "CityRate", "SpecialRate",
                                   "CombinedRate")])
  rownames(focal_mat) <- focal$id
  st_geometry(nonfocal) <- NULL
  nonfocal_mat <- as.matrix(nonfocal[, c("review_count", "rating", "price", "StateRate",
                                         "CountyRate", "CityRate", "SpecialRate",
                                         "CombinedRate")])
  rownames(nonfocal_mat) <- nonfocal$id
  # demean the variables
  focal_mat <- focal_mat - (proxy_mat %*% nonfocal_mat)
  focal_mat <- data.frame(focal_mat)
  focal_mat <- cbind(focal_mat, focal[,c("id", "distance", "state")], focal_coord)
  reg_data <- rbind(reg_data, focal_mat)
}
write.csv(raw_data, "raw_data2.csv")
write.csv(reg_data, "reg_data2.csv")
