setwd("~/Downloads")
a=read.csv("train-2.csv", stringsAsFactors = F, header = T)
#head(a)
#a = b[sample(nrow(b),1000),]

##############Converting into date time########
#a$dtm=as.POSIXct(a$pickup_datetime,tz=Sys.timezone())
a$h <- as.numeric(substr(a$pickup_datetime,11,13))
a$m <- as.numeric(substr(a$pickup_datetime,15,16))
#a$h2 <- as.numeric(substr(a$dropoff_datetime,11,13))
#a$m2 <- as.numeric(substr(a$dropoff_datetime,15,16))
a$day <- as.factor(weekdays(as.Date(a$pickup_datetime)))
a$passenger_count <- (a$passenger_count)^2
#Calculating the distance between latitude and logitude in kms
library(sp)


jlhoward <- function(dat) { dat$dist.km <- sapply(1:nrow(dat),function(i)
  spDistsN1(as.matrix(dat[i,3:4]),as.matrix(dat[i,5:6]),longlat=T)) }

rafa.pereira <- function(dat2) { setDT(dat2)[ , dist_km := distGeo(matrix(c(pro.long, pro.lat), ncol = 2), 
                                                                   matrix(c(sub.long, sub.lat), ncol = 2))/1000] }

library(data.table)
library(geosphere)

setDT(a)[ , dist_km := distGeo(matrix(c(pickup_longitude, pickup_latitude), ncol = 2), 
                               matrix(c(dropoff_longitude, dropoff_latitude), ncol = 2))/1000] 

setDT(a)[ , dist_lon := distGeo(matrix(c(pickup_longitude, pickup_latitude), ncol = 2), 
                                matrix(c(dropoff_longitude, pickup_latitude), ncol = 2))/1000] 

setDT(a)[ , dist_lat := distGeo(matrix(c(pickup_longitude, pickup_latitude), ncol = 2), 
                                matrix(c(pickup_longitude, dropoff_latitude), ncol = 2))/1000] 

a$dist_km <-(a$dist_km)^2


##########Feature Engineering for test
b=read.csv("test.csv", stringsAsFactors = F, header = T)
head(b)
#a = b[sample(nrow(b),1000),]
#b$dtm=as.POSIXct(b$pickup_datetime,tz=Sys.timezone())
b$h <- as.numeric(substr(b$pickup_datetime,11,13))
b$m <- as.numeric(substr(b$pickup_datetime,15,16))
#b$h2 <- as.numeric(substr(b$dropoff_datetime,11,13))
#b$m2 <- as.numeric(substr(b$dropoff_datetime,15,16))
b$day <- as.factor(weekdays(as.Date(b$pickup_datetime)))
b$passenger_count <- (b$passenger_count)^2
setDT(b)[ , dist_km := distGeo(matrix(c(pickup_longitude, pickup_latitude), ncol = 2), 
                               matrix(c(dropoff_longitude, dropoff_latitude), ncol = 2))/1000]
setDT(b)[ , dist_lon := distGeo(matrix(c(pickup_longitude, pickup_latitude), ncol = 2), 
                                matrix(c(dropoff_longitude, pickup_latitude), ncol = 2))/1000] 

setDT(b)[ , dist_lat := distGeo(matrix(c(pickup_longitude, pickup_latitude), ncol = 2), 
                                matrix(c(pickup_longitude, dropoff_latitude), ncol = 2))/1000] 
b$dist_km <- (b$dist_km)^2

###################### Training a GBM#######################


library(gbm)
gbm = gbm(trip_duration~dist_km+passenger_count+h+m+day+dist_lon+dist_lat, a,
          n.trees=1000,
          shrinkage=0.01,
          distribution="gaussian",
          interaction.depth=4,
          bag.fraction=0.9,
          cv.fold=0,
          n.minobsinnode = 50
)