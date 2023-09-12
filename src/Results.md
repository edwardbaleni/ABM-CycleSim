---
title: "Results"
author: "Edward Baleni"
date: "2023-09-11"
output: 
  html_document:
    keep_md: true
---


```r
require(ggplot2)
```

```
## Loading required package: ggplot2
```

```r
library(viridis)
```

```
## Loading required package: viridisLite
```

```r
library(dplyr)
```

```
## 
## Attaching package: 'dplyr'
```

```
## The following objects are masked from 'package:stats':
## 
##     filter, lag
```

```
## The following objects are masked from 'package:base':
## 
##     intersect, setdiff, setequal, union
```

```r
options(dplyr.summarise.inform = FALSE)
```



```r
data <- read.table("CycleSim_Results_Table.csv",
                   header = T,
                   sep = ",",
                   skip = 6,
                   quote = "\"", 
                   fill = TRUE )

colnames(data) <- c("Run", "Lead Power", "Lead Energy", "Lead Weight", "teamAbility", "Lead Coop", "tick", "meanEnergyNotTeam", "meanEnergyTeamLead", "meanEnergyTeam", "CFdraftNotTeam", "CFdraftTeamLead", "CFdraftTeam", "powerPropNotTeam","powerPropTeamLead","powerPropTeam", "Exhausted", "ExtrExhausted", "Position")

# Need to remove observations that are 100000
data <- data[which(data[,"meanEnergyNotTeam"] != 100000),]
data <- data[which(data[,"meanEnergyTeamLead"] != 100000),]
data <- data[which(data[,"meanEnergyTeam"] != 100000),]

data <- data[which(data[,"CFdraftTeam"] != 100000),]
data <- data[which(data[,"CFdraftTeamLead"] != 100000),]
data <- data[which(data[,"CFdraftTeam"] != 100000),]


data <- data[which(data[,"powerPropNotTeam"] != 100000),]
data <- data[which(data[,"powerPropTeamLead"] != 100000),]
data <- data[which(data[,"powerPropTeam"] != 100000),]
```



```r
# Remove repeat Positions
# We are interested in what configurations result in better positioning
pos <- data[which(data[,19] != 0),c(1:6, 19)]
pos <- unique(pos)
holder <- data.frame()

for (i in unique(pos$Run)) {
  hold <- pos[which( pos$Run == i ), ]
  holder <- rbind(holder, hold[ which.max( hold$Position ),  ] )
}

holder$`Lead Power` <- as.factor(holder$`Lead Power`)
holder$`Lead Energy` <- as.factor(holder$`Lead Energy`)
holder$`Lead Coop` <- as.factor(holder$`Lead Coop`)
```


```r
# This is the sensitivity analysis. Put it in 
ggplot(data = holder, aes(x = `Lead Coop`, y = Position, fill = `Lead Power`)) +
  geom_boxplot() +
        scale_fill_viridis(discrete = TRUE, alpha=0.6) +
  xlab("Lead Cooperation")
```

![](Results_files/figure-html/Sensitivity Analysis-1.png)<!-- -->

```r
ggplot(data = holder, aes(x = `Lead Coop`, y = Position, fill = `Lead Energy`)) +
  geom_boxplot() +
      scale_fill_viridis(discrete = TRUE, alpha=0.6) +
  xlab( "Lead Cooperation" )+
  facet_wrap(~ `Lead Power`)
```

![](Results_files/figure-html/Sensitivity Analysis-2.png)<!-- -->

```r
ggplot(data = holder, aes(x = `Lead Coop`, y = Position, fill = `Lead Power`)) +
  geom_boxplot()+
        scale_fill_viridis(discrete = TRUE, alpha=0.6) +
  xlab("Lead Cooperation") + 
  facet_wrap(~ `Lead Energy`)
```

![](Results_files/figure-html/Sensitivity Analysis-3.png)<!-- -->




```r
energy1 <- data[,1:8] ; names(energy1)[names(energy1) == "meanEnergyNotTeam" ] <- 'energy'
energy1$Group <- rep("Adversary", nrow(energy1))
energy2 <- data[, c(1:7, 9)]; names(energy2)[names(energy2) == "meanEnergyTeamLead" ] <- 'energy'
energy2$Group <- rep("Team Lead", nrow(energy2))
energy3 <- data[, c(1:7, 10)]; names(energy3)[names(energy3) == "meanEnergyTeam" ] <- 'energy'
energy3$Group <- rep("Team", nrow(energy3))
Energy <- rbind(energy1, energy2, energy3)

#powerP <- data[,c(1:7, 14:16)]
#exh    <- data[,c(1:7, 17:18)]
```



```r
# Sort by multiple columns
Energy <- Energy[order(Energy$Run),]
eng <- Energy

newEnergy <- list()
keepResultsEng <- list()
 # In multiples of 5s are the runs repeated
 # Need to take average of ticks over the 5 runs and plot this mean of means
 #  

k=5

for (i in 1:80) {
  newEng <- data.frame()
  for (j in k:k+5) {
    newEng <- rbind(newEng, eng[which(eng$Run == j),])
  }
  
  newEng <- newEng[,-1]
  # Average out runs at same ticks for same label
  
  a <- newEng %>%
    group_by(tick, Group) %>%
    summarize(AvgEnergy = mean(energy, na.rm = T))
  
  keepResultsEng[[i]] <- a
  newEnergy[[i]] <- newEng
  k <- k+5
}
```


```r
Draft  <- data[,c(1:7, 11:13)]

draft1 <- data[,c(1:7, 11)] ; names(draft1)[names(draft1) == "CFdraftNotTeam" ] <- 'Draft'
draft1$Group <- rep("Adversary", nrow(draft1))

draft2 <- data[, c(1:7, 12)]; names(draft2)[names(draft2) == "CFdraftTeamLead" ] <- 'Draft'
draft2$Group <- rep("Team Lead", nrow(draft2))

draft3 <- data[, c(1:7, 13)]; names(draft3)[names(draft3) == "CFdraftTeam" ] <- 'Draft'
draft3$Group <- rep("Team", nrow(draft3))

Draft <- rbind(draft1, draft2, draft3)
```



```r
# Sort by multiple columns
Draft <- Draft[order(Draft$Run),]
eng <- Draft

newDraft <- list()
keepResultsDraft <- list()
 # In multiples of 5s are the runs repeated
 # Need to take average of ticks over the 5 runs and plot this mean of means
 #  

k=5

for (i in 1:80) {
  newEng <- data.frame()
  for (j in k:k+5) {
    newEng <- rbind(newEng, eng[which(eng$Run == j),])
  }
  
  newEng <- newEng[,-1]
  # Average out runs at same ticks for same label
  
  a <- newEng %>%
    group_by(tick, Group) %>%
    summarize(AvgDraft = mean(Draft, na.rm = T))
  
  keepResultsDraft[[i]] <- a
  newDraft[[i]] <- newEng
  k <- k+5
}
```


```r
# Power is indirectly and perfectly correlated with Draft, so it is not necessary to plot
powerP <- data[,c(1:7, 14:16)]
```


```r
exh    <- data[,c(1:7, 17:18)]

exh1 <- data[,c(1:7, 17)] ; names(exh1)[names(exh1) == "Exhausted" ] <- 'State'
exh1$Group <- rep("Exhausted", nrow(exh1))

exh2 <- data[, c(1:7, 18)]; names(exh2)[names(exh2) == "ExtrExhausted" ] <- 'State'
exh2$Group <- rep("Extreme Exhausted", nrow(exh2))

Exh <- rbind(exh1, exh2)
```


```r
# Sort by multiple columns
Exh <- Exh[order(Exh$Run),]
eng <- Exh

newExh <- list()
keepResultsExh <- list()
 # In multiples of 5s are the runs repeated
 # Need to take average of ticks over the 5 runs and plot this mean of means
 #  

k=5

for (i in 1:80) {
  newEng <- data.frame()
  for (j in k:k+5) {
    newEng <- rbind(newEng, eng[which(eng$Run == j),])
  }
  
  newEng <- newEng[,-1]
  # Average out runs at same ticks for same label
  
  a <- newEng %>%
    group_by(tick, Group) %>%
    summarize(AvgExh = mean(State, na.rm = T))
  
  keepResultsExh[[i]] <- a
  newExh[[i]] <- newEng
  k <- k+5
}
```





```r
finEng <- data.frame()
s <- c(9, 11, 15, 17, 63, 65, 69, 71)

for (i in s){
  finEng <- rbind(finEng, cbind( keepResultsEng[[i]], i))
}
```

```
## New names:
## New names:
## New names:
## New names:
## New names:
## New names:
## New names:
## New names:
## • `` -> `...4`
```

```r
colnames(finEng) <- c("tick", "Group", "AvgEnergy", "Setting")

ggplot(finEng, aes(x=tick, y = AvgEnergy, color = Group)) +
  geom_line() +
  facet_wrap(~ Setting) +
  xlab ("Time (Minutes)")+
  ylab ("Average Energy (kJ)")
```

![](Results_files/figure-html/Obtain Results and plot-1.png)<!-- -->



```r
finDraft <- data.frame()
s <- c(9, 11, 15, 17, 63, 65, 69, 71)

for (i in s){
  finDraft <- rbind(finDraft, cbind( keepResultsDraft[[i]], i))
}
```

```
## New names:
## New names:
## New names:
## New names:
## New names:
## New names:
## New names:
## New names:
## • `` -> `...4`
```

```r
colnames(finDraft) <- c("tick", "Group", "Draft", "Setting")

ggplot(finDraft, aes(x=tick, y = Draft, color = Group)) +
  geom_line() +
  facet_wrap(~ Setting) +
  xlab ("Time (Minutes)") +
  ylab ("Drafting Coefficient")
```

![](Results_files/figure-html/Draft Sensitivity-1.png)<!-- -->


```r
fin <- data.frame()
s <- c(9, 11, 15, 17, 63, 65, 69, 71)

for (i in s){
  fin <- rbind(fin, cbind( keepResultsExh[[i]], i))
}
```

```
## New names:
## New names:
## New names:
## New names:
## New names:
## New names:
## New names:
## New names:
## • `` -> `...4`
```

```r
colnames(fin) <- c("tick", "Group", "Fatigue", "Setting")

ggplot(fin, aes(x=tick, y = Fatigue, color = Group)) +
  geom_line() +
  facet_wrap(~ Setting) +
  xlab ("Time (Minutes)") +
  ylab ("Count of Fatigued Riders")
```

![](Results_files/figure-html/Exh Sensitivity-1.png)<!-- -->

