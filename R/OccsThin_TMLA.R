OccsThin <- function(occ,
                     envT,
                     ThinMethod,
                     VarColin,
                     DirR,
                     pred_dir,
                     distance = NULL) {
  #Function to thin occurrence data for ENM_TMLA
  #Parameters:
  #occ: Species list of occurrence data
  #envT: Predictors
  #ThinMethod: Methods chosen by user to thin occurrences
  #VarColin: Method chosen to deal with Variables Colinearity
  #DirR: Directory to save TXT with thinned occuurences
  
  #Convert from decimals to km
  spN <- names(occ)
  occDF <-
    lapply(occ, function(x)
      cbind(SpatialEpi::latlong2grid(x[, 1:2]), x[, 4]))
  
  if (ThinMethod == "MORAN") {
    #1.Defined by variogram----
    #Check if there is a PC
    if (!is.null(VarColin)) {
      if (VarColin != "PCA" && names(envT)[1] != "PC1") {
        pc1 <- PCA_env_TMLA(env = envT, Dir = pred_dir)[[1]]
      } else{
        pc1 <- envT[[1]]
      }
    }
    
    #Optimal distance for each species
    ocsD <- lapply(occDF, function(x)
      dist(x[, 1:2]))
    maxD <- lapply(ocsD, function(x)
      max(x))
    breaksD <- lapply(maxD, function(x)
      seq(0, x, l = 10))
    v1 <- vector("list", length = length(breaksD))
    for (i in 1:length(breaksD)) {
      v1[[i]] <-
        geoR::variog(coords = occDF[[i]][, 1:2],
                     data = occDF[[i]][, 3],
                     uvec = breaksD[[i]])
      v1[[i]] <- v1[[i]]$u[which(v1[[i]]$v == min(v1[[i]]$v[-1]))]
    }
    
    #Data Frame for thining
    occDF <- ldply(occDF, data.frame)
    
    #Thinning
    occPOS <- vector("list", length = length(breaksD))
    for (i in 1:length(v1)) {
      invisible(utils::capture.output(
        occT <-
          spThin::thin(
            occDF[occDF$.id == spN[i],],
            lat.col = "y",
            long.col = "x",
            spec.col = ".id",
            thin.par = v1[[i]],
            reps = 20,
            write.files = F,
            locs.thinned.list.return = T,
            write.log.file = F
          )
      ))
      occT <-
        occT[[which(sapply(occT, function(x)
          nrow(x)) == max(sapply(occT, function(x)
            nrow(x))))[1]]]
      occPOS[[i]] <- as.integer(row.names(occT))
    }
    
    #Select Thinned Occurrences
    for (i in 1:length(occPOS)) {
      occ[[i]] <- occ[[i]][occPOS[[i]], ]
    }
    
    #Number of occurrences after Thining
    uni <-
      data.frame(Species = spN,
                 UniqueOcc = sapply(occ, function(x)
                   nrow(x)))
    utils::write.table(
      uni,
      file.path(DirR, "N_Occ_Thinned.txt"),
      sep = "\t",
      row.names = F
    )
    return(occ)
    
  } else if (ThinMethod == "USER-DEFINED") {
    #2.Defined by user----
    # cat("Select distance for thining(in km):")
    # distance <- as.integer(readLines(n=1))
    
    #Data Frame for thining
    occDF <- ldply(occDF, data.frame)
    
    #Thinning
    occPOS <- vector("list", length = length(occ))
    for (i in 1:length(occPOS)) {
      invisible(utils::capture.output(
        occT <-
          spThin::thin(
            occDF[occDF$.id == spN[i], ],
            lat.col = "y",
            long.col = "x",
            spec.col = ".id",
            thin.par = distance,
            reps = 20,
            write.files = F,
            locs.thinned.list.return = T,
            write.log.file = F
          )
      ))
      occT <-
        occT[[which(sapply(occT, function(x)
          nrow(x)) == max(sapply(occT, function(x)
            nrow(x))))[1]]]
      occPOS[[i]] <- as.integer(row.names(occT))
    }
    
    #Select Thinned Occurrences
    for (i in 1:length(occPOS)) {
      occ[[i]] <- occ[[i]][occPOS[[i]], ]
    }
    
    #Number of occurrences after Thining
    uni <-
      data.frame(Species = spN,
                 UniqueOcc = sapply(occ, function(x)
                   nrow(x)))
    utils::write.table(
      uni,
      file.path(DirR, "N_Occ_Thinned.txt"),
      sep = "\t",
      row.names = F
    )
    
    return(occ)
    
  } else if (ThinMethod == "CELLSIZE") {
    #3.Based on cellsize----
    #Haversine Transformation
    distance <-
      raster::xyFromCell(envT[[1]], 1:raster::ncell(envT[[1]]))
    df <-
      data.frame(x = c(distance[1, c(2, 1)]), y = c(distance[2, c(2, 1)]))
    distance <- pracma::haversine(df$x, df$y) * 2
    
    #Data Frame for thining
    occDF <- ldply(occDF, data.frame)
    
    #Thinning
    occPOS <- vector("list", length = length(occ))
    for (i in 1:length(occPOS)) {
      invisible(utils::capture.output(
        occT <-
          spThin::thin(
            occDF[occDF$.id == spN[i],],
            lat.col = "y",
            long.col = "x",
            spec.col = ".id",
            thin.par = distance,
            reps = 20,
            write.files = F,
            locs.thinned.list.return = T,
            write.log.file = F
          )
      ))
      occT <-
        occT[[which(sapply(occT, function(x)
          nrow(x)) == max(sapply(occT, function(x)
            nrow(x))))[1]]]
      occPOS[[i]] <- as.integer(row.names(occT))
    }
    
    #Select Thinned Occurrences
    for (i in 1:length(occPOS)) {
      occ[[i]] <- occ[[i]][occPOS[[i]], ]
    }
    
    #Number of occurrences after Thining
    uni <-
      data.frame(Species = spN,
                 UniqueOcc = sapply(occ, function(x)
                   nrow(x)))
    utils::write.table(
      uni,
      file.path(DirR, "N_Occ_Thinned.txt"),
      sep = "\t",
      row.names = F
    )
    
    return(occ)
  }
}
