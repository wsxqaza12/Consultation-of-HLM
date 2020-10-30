library(readxl)
library(dplyr)

setwd("C:/Users/User/Desktop/研究所/碩二下/外務. 陳醫師")
F1 <- read_xls("dat2_0513.xls")
S1 <- read_xls("d1_0513.xls")
T1 <- read_xls("d2_0513.xls")

F1 <- F1[!is.na(F1$k2), ]

# 鄰牙象限問題
attach(F1)

# 11
F1$k2[site== "DB"& tooth== "11"]  <- "12-MB"
F1$k2[site== "DP"& tooth== "11"]  <- "12-MP"
F1$k3[site== "DB"& tooth== "11"]  <- "12-MB"
F1$k3[site== "DP"& tooth== "11"]  <- "12-MP"
# 21
F1$k2[site== "DB"& tooth== "21"]  <- "22-MB"
F1$k2[site== "DP"& tooth== "21"]  <- "22-MP"
F1$k3[site== "DB"& tooth== "21"]  <- "22-MB"
F1$k3[site== "DP"& tooth== "21"]  <- "22-MP"
# 31
F1$k2[site== "DB"& tooth== "31"]  <- "32-MB"
F1$k2[site== "DP"& tooth== "31"]  <- "32-MP"
F1$k3[site== "DB"& tooth== "31"]  <- "32-MB"
F1$k3[site== "DP"& tooth== "31"]  <- "32-MP"
# 41
F1$k2[site== "DB"& tooth== "41"]  <- "42-MB"
F1$k2[site== "DP"& tooth== "41"]  <- "42-MP"
F1$k3[site== "DB"& tooth== "41"]  <- "42-MB"
F1$k3[site== "DP"& tooth== "41"]  <- "42-MP"




  # R036
F1$k2[No_== "R036" & tooth== "14" & site== "DB"]  <- "16-MB"
F1$k2[No_== "R036" & tooth== "14" & site== "DP"]  <- "16-MP"
F1$k3[No_== "R036" & tooth== "14" & site== "DB"]  <- "16-MB"
F1$k3[No_== "R036" & tooth== "14" & site== "DP"]  <- "16-MP"

F1$k2[No_== "R036" & tooth== "24" & site== "DB"]  <- "26-MB"
F1$k2[No_== "R036" & tooth== "24" & site== "DP"]  <- "26-MP"
F1$k3[No_== "R036" & tooth== "24" & site== "DB"]  <- "26-MB"
F1$k3[No_== "R036" & tooth== "24" & site== "DP"]  <- "26-MP"

F1$k2[No_== "R036" & tooth== "31" & site== "DB"]  <- "33-MB"
F1$k2[No_== "R036" & tooth== "31" & site== "DP"]  <- "33-MP"
F1$k3[No_== "R036" & tooth== "31" & site== "DB"]  <- "33-MB"
F1$k3[No_== "R036" & tooth== "31" & site== "DP"]  <- "33-MP"

F1$k2[No_== "R036" & tooth== "41" & site== "DB"]  <- "43-MB"
F1$k2[No_== "R036" & tooth== "41" & site== "DP"]  <- "43-MP"
F1$k3[No_== "R036" & tooth== "41" & site== "DB"]  <- "43-MB"
F1$k3[No_== "R036" & tooth== "41" & site== "DP"]  <- "43-MP"
  # R053
F1$k2[No_== "R053" & tooth== "14" & site== "DB"]  <- "16-MB"
F1$k2[No_== "R053" & tooth== "14" & site== "DP"]  <- "16-MP"
F1$k3[No_== "R053" & tooth== "14" & site== "DB"]  <- "16-MB"
F1$k3[No_== "R053" & tooth== "14" & site== "DP"]  <- "16-MP"
  # R055
F1$k2[No_== "R055" & tooth== "13" & site== "DB"]  <- "15-MB"
F1$k2[No_== "R055" & tooth== "13" & site== "DP"]  <- "15-MP"
F1$k3[No_== "R055" & tooth== "13" & site== "DB"]  <- "15-MB"
F1$k3[No_== "R055" & tooth== "13" & site== "DP"]  <- "15-MP"

F1$k2[No_== "R055" & tooth== "23" & site== "DB"]  <- "25-MB"
F1$k2[No_== "R055" & tooth== "23" & site== "DP"]  <- "25-MP"
F1$k3[No_== "R055" & tooth== "23" & site== "DB"]  <- "25-MB"
F1$k3[No_== "R055" & tooth== "23" & site== "DP"]  <- "25-MP"

detach(F1)

names(F1)
mergeFS <- F1 %>% left_join(S1 %>% select(No_, k2, PD11, CAL11, GR11), by= c("No_", "k2"))
mergeFT <- F1 %>% left_join(T1 %>% select(No_, k3, PD22, CAL22, GR22), by= c("No_", "k3"))

# write.csv(mergeFS, "fm2_real.csv", row.names = F)


fm66 <- read.csv("fm2.csv")
fm66$No_ <- as.character(fm66$No_)
fm66$k1 <- as.character(fm66$k1)

fm_ALL <- fm66 %>% 
  left_join(mergeFS %>% select(No_, k1, PD11, CAL11, GR11), by= c("No_", "k1")) %>% 
  left_join(mergeFT %>% select(No_, k1, PD22, CAL22, GR22), by= c("No_", "k1")) %>%
  mutate(max_PD = pmax(PD11, PD22, na.rm = T), min_PD= pmin(PD11, PD22, na.rm = T),
         max_CAL = pmax(CAL11, CAL22, na.rm = T), min_CAL= pmin(CAL11, CAL22, na.rm = T),
         max_GR = pmax(GR11, GR22, na.rm = T), min_GR= pmin(GR11, GR22, na.rm = T))
# 
# write.csv(fm_ALL, "fm_ALL_0609.csv", row.names = F, na = "")
# write.csv(mergeFS, "mergeFS.csv", row.names = F, na = "")

######################### Model2 
names(bac)

fm_model2 <- 
  fm_ALL %>% 
  filter(time== 1, PD>= 5) %>%
  select(No_, tooth, k1)

fm_model2_ALL <- 
  fm_model2 %>% left_join(fm_ALL, by= c("No_", "k1"))

colnames(fm_model2_ALL)[2] <- "tooth"

write.csv(fm_model2_ALL, "fm_model2_ALL_0609.csv", row.names = F, na = "")

########################## bac
bac <- read.csv("bac_final.csv")
bac$No_ <- as.character(bac$No_)

fm_bac <- fm_ALL %>% left_join(bac %>% select(No_, tooth, time, TB, Pg, Pn, Tf),
                               by= c("No_", "tooth", "time"))
fm_bac_model2 <- fm_model2_ALL %>% left_join(bac %>% select(No_, tooth, time, TB, Pg, Pn, Tf),
                               by= c("No_", "tooth", "time"))

write.csv(fm_bac, "fm_bac_0609.csv", row.names = F, na = "")
write.csv(fm_bac_model2, "fm_bac_model2_0609.csv", row.names = F, na = "")

  
  
  
  
  
  
  
  
  
  




