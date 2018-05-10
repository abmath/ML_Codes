#Put file location in setwd
setwd("~/Desktop")
#Put file name in double quotes
dat <- read.csv("Address2.csv", header = T,
                stringsAsFactors = F)

install.packages(c('sp','rgdal','geosphere'))
library(sp)
library(rgdal)
library(geosphere)
dat$Latitude <- as.numeric(dat$Latitude)

dat <- na.omit(dat)

x <- dat$Latitude
y <- dat$Longitude

xy <- SpatialPointsDataFrame(
  matrix(c(x,y), ncol=2), data.frame(ID=seq(1:length(x))),
  proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84"))

#head(xy)
#head(dat)

mdist <- distm(xy)

#head(mdist)

hc <- hclust(as.dist(mdist), method="complete")
xy$clust <- cutree(hc, h=125000)
dat$clus <- xy$clust
cluster_dets <- as.data.frame(table(dat$clus,dat$ShipSiteID))

cluster_dets2 <- cluster_dets[cluster_dets$Freq > 0,]
names(cluster_dets2) <-c("Cluster_No","ShipSiteID","Count")
write.csv(cluster_dets2, "metrics.csv", row.names = F)

write.csv(dat, "output.csv", row.names = F)

# Replace 2 with the cluster No for filtering

dat[dat$clus == 2,]

#Run Code as it is till line 58
install.packages(c('dismo','rgeos'))

library(dismo)
library(rgeos)

# expand the extent of plotting frame
xy@bbox[] <- as.matrix(extend(extent(xy),0.001))

# get the centroid coords for each cluster
cent <- matrix(ncol=2, nrow=max(xy$clust))
for (i in 1:max(xy$clust))
  # gCentroid from the rgeos package
  cent[i,] <- gCentroid(subset(xy, clust == i))@coords

# compute circles around the centroid coords using radius specified
# from the dismo package
# Mention d = radius in m to specify circles
ci <- circles(cent, d=125000, lonlat=T)

# plot
plot(ci@polygons, axes=T)
plot(xy, col=rainbow(4)[factor(xy$clust)], add=T)
