####
#download the data
#for publication:  https://doi.org/10.1371/journal.pone.0185195
#####
library(tidyverse)
library(readxl)
library(knitr)
library(kableExtra)
library(stringr)
#download the publication data from Figshare
url1<-'https://ndownloader.figshare.com/files/9422038'
p1f <- tempfile()
download.file(url1, p1f, mode="wb")
#read in data. Note that we need to define the NA
my_data<-read_excel(path = p1f, sheet = 1, na="NA")
#the data set contains mortaility of patients after burns depending on
#whether and where they had inhalation burns
#first create a new variable that is a 
#factor (0=normal, 1=subjective, 2=upper, and 3=lower)
my_data<-
  my_data %>% 
  mutate(INHdiv_fac=factor(INHdiv,labels=c("normal","subjective","upper","lower"))) 
#create a data frame for a barplot
#group by the new inhalation severity variable and the PFdivide 
#("We also divided the patients into four groups depending on the PF ratio (>300, 200-300, 100-200, and <100)") 
#you will need the mean and sd of mortality (look out for spelling mistake) for each level of inhalation injury (INHdiv)
#from this calculate the upper (ymax) and lower (ymin) bounds of the error bars (S.E.M.:mean +- sd/sqrt(n))
plot_data<-
  my_data %>% 
  group_by(INHdiv_fac,Pfdivide) %>% 
  summarise(mean_mort=mean(mortaltiy),
            sd_mort=sd(mortaltiy),
            sem_mort=sd_mort/sqrt(n()),
            ymax=mean_mort+sem_mort,
            ymin=mean_mort-sem_mort)

#create a barplot from this with mean mortality on y axis and Pfdivide on x axis
#create a facet for each severity level
#add error bars
#make nice axis labels
p.1<-ggplot(aes(y=mean_mort,x=Pfdivide),data=plot_data)+geom_bar(stat="identity")+
  geom_errorbar(aes(ymax=ymax,ymin=ymin),width=.1)+
  facet_wrap(~INHdiv_fac)+
  theme_classic()+
  ylab("Mean mortality")+
  xlab(expression("PaO"[2]*"/FiO"[2]*" (PF) ratio"))
p.1

#problem is we transformed a continuous variable to a factorial variable
#is there a way to plot a continuous variable 
#if the dependent variable is 0 and 1?
names(my_data)[8]<-c("PFratio")
hist_data<-
  my_data %>% 
  #first add new variable that codes breaks
  mutate(breaks = findInterval(PFratio, seq(20,935,10))) %>%
  #then group by dead/alive and the breaks
  group_by(mortaltiy, breaks) %>% 
  #count
  summarise(n = n()) %>%
  #if patients are dead, we want them to show on top with histogram on top so you need to 
  #calculate in this case the percentage as 1-percentage
  mutate(pct = ifelse(mortaltiy==0, n/sum(n), 1 - n/sum(n)),breaks=seq(20,935,10)[breaks]) 
######
#
#####
ggplot() + #this just sets an empty frame to build upon
  #first add a histopgram with geom_segment use the help of geom_segment
  geom_segment(data=hist_data, size=2, show.legend=FALSE,
               aes(x=breaks, xend=breaks, y=mortaltiy, yend=pct, colour=factor(mortaltiy)))+
  #then predict a logistic regression via stat_smooth and the glm method (we will cover the details in the next session)
  stat_smooth(data=my_data,aes(y=mortaltiy,x=PFratio),method="glm", method.args = list(family = "binomial"))+
  #some cosmetics 
  scale_y_continuous(limits=c(-0.02,1.02)) +
  scale_x_continuous(limits=c(10,950)) +
  theme_bw(base_size=12)+
  ylab("Patient Alive=0/Dead=1")+xlab(expression("PaO"[2]*"/FiO"[2]*" (PF) ratio"))
######
#do the same thing for the four inhale burns groups separately
#####
hist_data<-
  my_data %>% 
  #first add new variable that codes breaks
  mutate(breaks = findInterval(PFratio, seq(20,935,10))) %>%
  #then group by dead/alive and the breaks
  group_by(INHdiv_fac,mortaltiy, breaks) %>% 
  #count
  summarise(n = n()) %>%
  #if patients are dead, we want them to show on top with histogram on top so you need to 
  #calculate in this case the percentage as 1-percentage
  mutate(pct = ifelse(mortaltiy==0, n/sum(n), 1 - n/sum(n)),breaks=seq(20,935,10)[breaks]) 
######
#
#####
ggplot() + #this just sets an empty frame to build upon
  facet_wrap(~INHdiv_fac)+
  #first add a histopgram with geom_segment use the help of geom_segment
  geom_segment(data=hist_data, size=2, show.legend=FALSE,
               aes(x=breaks, xend=breaks, y=mortaltiy, yend=pct, colour=factor(mortaltiy)))+
  #then predict a logistic regression via stat_smooth and the glm method 
  #(we will cover the details in the next session)
  stat_smooth(data=my_data,aes(y=mortaltiy,x=PFratio),method="glm", method.args = list(family = "binomial"))+
  #some cosmetics 
  scale_y_continuous(limits=c(-0.02,1.02)) +
  scale_x_continuous(limits=c(10,950)) +
  theme_bw(base_size=12)+
  ylab("Patient Alive=0/Dead=1")+xlab(expression("PaO"[2]*"/FiO"[2]*" (PF) ratio"))

