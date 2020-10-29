setwd("C:/Users/User/Desktop/研究所/碩二下/外務. 陳醫師/0609/")
dat <- read.csv("time1_0609.csv")

# delete unused columns
dat <- dat[,!(names(dat) %in% c("M_N_I", "MGr", "KM"))]

# factor the categorical variables
dat$time <- factor(dat$time,
                   levels=c(1,2,3,4),
                   labels=c("1_f","2_h","3_i","4_ii"))
table(dat$time)

dat$gp <- ifelse(dat$Test_tooth==2,1,0)
dat$gp <- factor(dat$gp,
                   levels=c(0,1),
                   labels=c("control","test"))
table(dat$gp)

dat$BOP <- factor(dat$BOP,
                  levels=c(0,1),
                  labels=c("no_BOP","BOP"))

dat$PI <- factor(dat$PI,
                  levels=c(0,1),
                  labels=c("no_PI","PI"))

dat$tooth1 <- as.character(dat$tooth)

# data screening (missing, ouliers)
summary(dat)

# model
library(nlme)
## gls: generalized least squares
## intercept only
m0 <- gls(PD ~ 1,
          data = dat,
          method = "ML",
          na.action = "na.omit")
summary(m0)

## same as
summary(dat$PD, na.rm=T)

## random intercept model
c2 <- dat[,(names(dat) %in% c("No_", "site", "tooth", "trt", "time", "TB", "Tf", "Pg", "Pn"))]
c3 <- dat[,(names(dat) %in% c("No_", "site", "tooth", "trt", "time", "PD"))]

m1 <- lme(Pn ~ trt,
          data=na.omit(c2),
          method = "ML",
          random = ~ 1|No_/tooth,
          control=(msMaxIter=1000000))
summary(m1)
anova(m1)
O$coefficients
vcov(m1)
m2 <- lme(PD ~ time*trt,
          data=na.omit(c2),
          method = "ML",
          random = ~ 1|site)
summary(m2)

m3 <- lme(PD ~ time*trt+base_PD, 
          data=na.omit(c2),
          method = "ML",
          random = ~ 1|site)
summary(m3)

m4 <- lme(PD ~ time*trt+base_PD+min_PD, 
          data=na.omit(c3),
          method = "ML",
          random = ~ 1|site)
summary(m4)

m5 <- lme(PD ~ time*trt+base_PD+min_CAL, 
          data=na.omit(c3),
          method = "ML",
          random = ~ 1|site)
summary(m5)

m6 <- lme(PD ~ time*trt+base_PD+min_GR, 
          data=na.omit(c3),
          method = "ML",
          random = ~ 1|site)
summary(m6)