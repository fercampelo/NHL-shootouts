rm(list = ls())
require(mosaic)
require(knitr)
require(lme4)
require(ggplot2); 
require(extrafont);
loadfonts()
require(dplyr)
require(broom)
require(dotwhisker)
require(RCurl)
require(mvtnorm)
require(msm)
require(EDISON)
require(MCMCpack)


###################################
# Theme for plots
###################################
theme.plots<-theme(axis.text.x = element_text(size=rel(1.6)),
                   axis.text.y = element_text(size=rel(1.6)),
                   axis.title.x = element_text(size=rel(1.6), vjust=-1),
                   axis.title.y = element_text(size=rel(1.6)),
                   plot.margin = unit(c(1,0.3,0.5,0), "cm"),legend.position = "none",
                   plot.title = element_text(vjust=2, size=rel(1.6)))

y <- getURL("https://docs.google.com/spreadsheets/d/1SAByAftxLi8ozisTwERn-IOmHxmksWNqV1tAv2KJlYo/pub?output=csv")
nhl <- read.csv(text = y)



###################################
# Descriptive stats
###################################

nrow(nhl)
table(nhl$Rd,nhl$Goal01)
chisq.test(table(nhl$Rd,nhl$Goal01))

tally(Goal01~SOStatus,data=nhl,format="proportion") 
chisq.test(table(nhl$SOStatus,nhl$Goal01))

nhl$Defense<-nhl$Pos=="D"
table(nhl$Pos=="D")
tally(Goal01~Defense,data=nhl,format="proportion") 
chisq.test(table(nhl$Pos=="D",nhl$Goal01))


#When are the best shooters taking their attempts?
temp<-filter(nhl,Shooter2=="F.NIELSEN")
table(temp$Rd)
temp<-filter(nhl,Shooter2=="J.TOEWS")
table(temp$Rd)
temp<-filter(nhl,Shooter2=="T.OSHIE")
table(temp$Rd)
temp<-filter(nhl,Shooter2=="V.KOZLOV")
table(temp$Rd)
temp<-filter(nhl,Shooter2=="E.CHRISTENSEN")
table(temp$Rd)

temp<-filter(nhl,Shooter2=="F.NIELSEN"|Shooter2=="J.TOEWS"|Shooter2=="T.OSHIE"|Shooter2=="V.KOZLOV"|Shooter2=="E.CHRISTENSEN")
table(temp$Rd)



###################################
# Reduced data frame, used later for regression models
###################################

#Here, we create a data set using only the shooters that took at least five attempts in each round
SS<-as.data.frame.matrix(table(nhl$Shooter2,nhl$Rd))
SS<-SS[,c(1:3)]
colnames(SS)<-c("R1","R2","R3")
SS$Player<-rownames(SS)
min.n<-5  #min of 5 in each round
SS$Enough<-SS$R1>=min.n&SS$R2>=min.n&SS$R3>=min.n
SS<-filter(SS,Enough=="TRUE")

nhl.new<-filter(nhl,Shooter2%in%SS$Player)
head(nhl.new)
nrow(nhl.new)



###################################
# Funnel plots, goalies
###################################

p<-mean(nhl$Goal01)
mu<-1-p
attempts<-1:325

se.fun<-function(attempts,lim){
  result.LL<-qbinom(lim, attempts, (1-p))/attempts
}

#Inverse binomial confidence limits, 2 and 3 standard deviations away
ul<-se.fun(attempts,pnorm(2))
ll<-se.fun(attempts,(1-pnorm(2)))
ul2<-se.fun(attempts,pnorm(3))
ll2<-se.fun(attempts,(1-pnorm(3)))
lin<-data.frame(attempts=attempts,LL=ll,UL=ul,LL2=ll2,UL2=ul2)

tab<-nhl %>% group_by(Goalie2) %>% summarize(save_rate = 1-mean(Goal01),size= length(Goal01))
tab<-filter(tab,size>=10)

p <- ggplot(data = tab, aes(x = size, y = save_rate)) +
  geom_point(aes(text = paste("Player:", Goalie2)), size = 4,
             position = position_jitter(width = .015,height=0.015)) +theme_bw()+theme.plots+
  scale_y_continuous("",breaks=c(0,0.25,0.5,0.75,1),labels=c("0%","25%","50%","75%","100%"),lim=c(0,1.01))+
  scale_x_continuous("Attempts")+ggtitle("Shootout save percentage, goalies")+
  geom_line(data=lin,aes(x=attempts,y=UL),col="red",lty=5)+
  geom_line(data=lin,aes(x=attempts,y=LL),col="red",lty=5)+
  geom_line(data=lin,aes(x=attempts,y=UL2),col="red",lty=3)+
  geom_line(data=lin,aes(x=attempts,y=LL2),col="red",lty=3)+
  geom_hline(yintercept=(1-0.332),col="black",lty=2)+
  geom_segment(aes(x = 200, y = 0.9, xend = 215, yend = 0.9),col="red",lty=3)+
  geom_segment(aes(x = 200, y = 0.85, xend = 215, yend = 0.85),col="red",lty=5)+
  annotate("text", x =220, y = 0.9, label = "99.8% limits",hjust = 0, size=6)+
  annotate("text", x =220, y = 0.85, label = "95% limits ",hjust = 0,size=6)
p



###################################
# Funnel plots, shooters
###################################


p<-mean(nhl$Goal01)
mu<-p
attempts<-1:100
se.fun<-function(attempts,lim){
  result.LL<-qbinom(lim, attempts, p)/attempts
}

ul<-se.fun(attempts,pnorm(2))
ll<-se.fun(attempts,(1-pnorm(2)))
ul2<-se.fun(attempts,pnorm(3))
ll2<-se.fun(attempts,(1-pnorm(3)))

lin<-data.frame(attempts=attempts,LL=ll,UL=ul,LL2=ll2,UL2=ul2)
tab<-nhl %>% group_by(Shooter2) %>% summarize(goal_rate = mean(Goal01),size= length(Goal01))

p <- ggplot(data = tab, aes(x = size, y = goal_rate)) +
  geom_point(aes(text = paste("Player:", Shooter2)), size = 4,
             position = position_jitter(width = .015,height=0.015)) +theme_bw()+theme.plots+
  scale_y_continuous("",labels=c("0%","25%","50%","75%","100%"))+
  scale_x_continuous("Attempts")+ggtitle("Shootout goal percentage, shooters")+
  geom_line(data=lin,aes(x=attempts,y=UL),col="red",lty=2)+
  geom_line(data=lin,aes(x=attempts,y=LL),col="red",lty=2)+
  geom_line(data=lin,aes(x=attempts,y=UL2),col="red",lty=3)+
  geom_line(data=lin,aes(x=attempts,y=LL2),col="red",lty=3)+
  geom_hline(yintercept=0.332,col="black",lty=2)+
  geom_segment(aes(x = 57, y = 0.88, xend = 65, yend = 0.88),col="red",lty=3)+
  geom_segment(aes(x = 57, y = 0.80, xend = 65, yend = 0.80),col="red",lty=5)+
  annotate("text", x =68, y = 0.88, label = "99.8% limits",hjust = 0,size=6)+
  annotate("text", x =68, y = 0.80, label = "95% limits ",hjust = 0,size=6)
p



###################################
# Mixed models 
###################################



M1<-"Goal01~SOStatus+ShootingTm+Defense+(1|Goalie2)+(1|Shooter2)"
M2<-"Goal01~Rd+ShootingTm+Defense+(1|Goalie2)+(1|Shooter2)"
M3<-"Goal01~ShootingTm+Defense+(1|Goalie2)+(1|Shooter2)"
M4<-"Goal01~ShootingTm+Defense+(1|Shooter2)"
M5<-"Goal01~SOStatus+ShootingTm+Defense"

#Mixed models
m1<-glmer(M1,nhl,verbose=FALSE,family=binomial())
summary(m1)
m2<-glmer(M2,nhl,verbose=FALSE,family=binomial())
summary(m2)
m3<-glmer(M3,nhl,verbose=FALSE,family=binomial())
summary(m3)
m4<-glmer(M4,nhl,verbose=FALSE,family=binomial())
summary(m4)

#Basic logistic regression
m5<-glm(M5,family=binomial(),data=nhl)
summary(m5)

AIC(m1); AIC(m2); AIC(m3); AIC(m4); AIC(m5)
BIC(m1); BIC(m2); BIC(m3); BIC(m4); AIC(m5)


#And using the reduced sample of players

#Mixed models
m1p<-glmer(M1,nhl.new,verbose=FALSE,family=binomial())
summary(m1p)
m2p<-glmer(M2,nhl.new,verbose=FALSE,family=binomial())
summary(m2p)
m3p<-glmer(M3,nhl.new,verbose=FALSE,family=binomial())
summary(m3p)
m4p<-glmer(M4,nhl.new,verbose=FALSE,family=binomial())
summary(m4p)

#Basic logistic regressions. These are flawed, but will be used as a comparison
m5p<-glm(M5,family=binomial(),data=nhl.new)
summary(m5p)

AIC(m1p); AIC(m2p); AIC(m3p); AIC(m4p); AIC(m5p)
BIC(m1p); BIC(m2p); BIC(m3p); BIC(m4p); AIC(m5p)


AIC(m1); AIC(m2); AIC(m3); AIC(m4); AIC(m5)
BIC(m1); BIC(m2); BIC(m3); BIC(m4); AIC(m5)



###################################
# Coefficient plots
###################################


m1_df <- coef(summary(m1)) %>% 
  data.frame() %>% 
  add_rownames("term") 

m1p_df <- coef(summary(m1p)) %>% 
  data.frame() %>% 
  add_rownames("term") 

colnames(m1_df)<-colnames(tidy(m5)); colnames(m1p_df)<-colnames(tidy(m5))

m5_df<-tidy(m5)
m5_df<-mutate(m5_df,model="GLM")
m1_df<-mutate(m1_df,model="GLMM (full)")
m1p_df<-mutate(m1p_df,model="GLMM (reduced)")

m<-rbind(m5_df,m1_df,m1p_df)
m<-filter(m,term != "(Intercept)",term!="DefenseTRUE")
ordered_vars <- c("SOStatusLoss imminent", "SOStatusWin imminent", "ShootingTmVisitor","DefenseTRUE")


dwplot(filter(m,model!="GLMM (full)",model!="GLMM (reduced)")) +geom_vline(xintercept = 0,color="gray")+ggtitle("Coefficient estimates (95% CI's)")+ 
  scale_y_discrete(labels=c("Visiting Team","Loss Imminent","Win Imminent"))+
  xlab("log-odds, Goal")+theme.plots+theme_bw()+
  scale_colour_grey( start=0.6,end=.6,name = "Model Type")

dwplot(m) +geom_vline(xintercept = 0,color="gray")+ggtitle("Coefficient estimates (95% CI's)")+ 
  scale_y_discrete(labels=c("Loss Imminent","Visiting Team","Win Imminent"))+
  xlab("log-odds, Goal")+theme.plots+theme_bw()+
  scale_colour_grey( start=.8,end=0,name = "Model Type")



###################################
# Resampling to visualize coaching strategy
###################################


set.seed(999)
par(mfrow=c(1,2))
par(mar=c(4,4,3,0))
nhl.order<-nhl[order(nhl$Shooter2,nhl$Year,nhl$GameNumb),]
temp<-data.frame(table(nhl.order$Shooter2))
temp<-temp[temp$Freq>5,]
nhl.order<-filter(nhl.order,Shooter2%in%temp$Var1)
plot(0,0,xlim=c(0,90),ylim=c(-0.02,1),col="white",xlab="Shootout attempt",
     ylab="Success Rate",yaxt='n',main="Observed Tracks")
axis(2,c("0%","20%","40%","60%","80%","100%"),las=1,at=c(0,0.2,0.4,0.6,0.8,1))

x<-rnorm(nrow(temp),0,0.02)
for(i in 1:nrow(temp)){
  temp.nhl<-filter(nhl.order,Shooter2==temp[i,1])
  percent.p<-cumsum(temp.nhl$Goal01)/1:nrow(temp.nhl)
  points((1:nrow(temp.nhl)+x[i]*10),(percent.p+x[i]),type="l",col="grey")}
for(i in 1:nrow(temp)){
  temp.nhl<-filter(nhl.order,Shooter2==temp[i,1])
  percent.p<-cumsum(temp.nhl$Goal01)/1:nrow(temp.nhl)
  cols<-ifelse(max(temp.nhl$Year)=="20142015","red","black")
  points((nrow(temp.nhl)+x[i]*10),(percent.p[nrow(temp.nhl)]+x[i]),pch=16)}


#Let's bootstrap using the observed data - how would it look by chance?
#First, the observed sample mean is `33.3`\%, which is `-0.6941` on the logit scale. 
#Using the GLMM from earlier, the standard deviation for shooter intercepts is 0.188.

#So, we can impute the intercept for each shooter at `-0.6941 \pm 0.188` 
#and then exponentiate to get the probabilities for each shooter. 

#We'll use the observed number of shootout attempts. 

logit.p<-logit(mean(nhl$Goal01))
sigma<-0.188
par(mar=c(4,2,3,2))
plot(0,0,xlim=c(0,90),ylim=c(-0.02,1),col="white",xlab="Shootout attempt",
     ylab="Success Rate",yaxt='n',main="Simulated Tracks")
axis(2,c("","","","","",""),las=1,at=c(0,0.2,0.4,0.6,0.8,1))

x<-rnorm(nrow(temp),0,0.02)
finalp<-NULL
for(i in 1:nrow(temp)){
  temp.nhl<-filter(nhl.order,Shooter2==temp[i,1])
  sim.logit.percent<-rnorm(1,logit.p,sigma)
  sim.percent<-exp(sim.logit.percent)/(1+exp(sim.logit.percent))
  sim.goal<-rbinom(nrow(temp.nhl), 1, sim.percent)
  percent.p<-cumsum(sim.goal)/1:nrow(temp.nhl)
  points((1:nrow(temp.nhl)+x[i]*10),(percent.p+x[i]),type="l",col="grey")
  finalp[i]<-percent.p[nrow(temp.nhl)]
}
for(i in 1:nrow(temp)){
  temp.nhl<-filter(nhl.order,Shooter2==temp[i,1])
  points((nrow(temp.nhl)+x[i]*10),(finalp[i]+x[i]),pch=16)}




###################################
# Value of best shooters and goalies
###################################


set.seed(20142015)
n.sim<-100000

#Retrospective. Imagine we had the leagues best shooters and best goalie
p.overall<-mean(nhl$Goal01)
shoot.percent<-filter(nhl,Shooter2=="F.NIELSEN"|Shooter2=="J.TOEWS"|Shooter2=="T.OSHIE")
p.off<-mean(shoot.percent$Goal01)
goal.percent<-filter(nhl,Goalie2=="H.LUNDQVIST")
p.goal<-mean(goal.percent$Goal01)

p.off
p.goal

#The league's best shooters score at a 51.6% rate
#Best goalie save rate is 73.7% (goal rate of 26.3%)


#What about signing one of the top shooters (e.g., Capitals and Oshie)

first.three.O<-rbinom(n.sim,3,c(p.off,p.overall,p.overall))
first.three.D<-rbinom(n.sim,3,p.overall)

p.post3<-0.5  #assume top shooter doesn't get to shoot again
p.post3  #probability of winning if shootout is tied after 3 rds
p.win<-mean(first.three.O>first.three.D)+mean(first.three.O==first.three.D)*p.post3
p.win


#Probability of our team winning a given shootout against a league average set 
  #of shooters and a league average goalie is `round(p.win,3)` 

#How does that translate? 

#Teams have played between 6 and 21 SO's in last two years - median is 12, mean is 11.2. 
  #Appears to follow Poisson distribution

#Let's simulate the number of shootout wins added 

so.games<-rpois(10000,11.2)   #Simulated number of games going to a shootout in a single season
so.wins.good<-rbinom(so.games,so.games,prob=p.win)
so.wins.average<-rbinom(so.games,so.games,prob=0.5)
mean(so.wins.good-so.wins.average)
histogram(so.wins.good-so.wins.average)
summary(so.wins.good-so.wins.average)
quantile(so.wins.good-so.wins.average,c(0.025,0.975))

mean((so.wins.good-so.wins.average)<=0)

#So, a top shooter is worth about 0.75 of an extra shootout win on average, 
#but on a single season basis, it'd be impossible to tell that team 
  #from a league-average team (finishes at or worse in 47% of seasons)


#What about just signing the best goalie?

first.three.O<-rbinom(n.sim,3,p.overall)
first.three.D<-rbinom(n.sim,3,p.goal)

p.extend<-p.overall*p.goal+(1-p.overall)*(1-p.goal)
p.post3<-p.overall*(1-p.goal)/(1-p.extend)

p.win<-mean(first.three.O>first.three.D)+mean(first.three.O==first.three.D)*p.post3
p.win

so.wins.good<-rbinom(so.games,so.games,prob=p.win)
so.wins.average<-rbinom(so.games,so.games,prob=0.5)
mean(so.wins.good-so.wins.average)
histogram(so.wins.good-so.wins.average)
summary(so.wins.good-so.wins.average)
quantile(so.wins.good-so.wins.average,c(0.025,0.975))

mean((so.wins.good-so.wins.average)<=0)

#So, a top goalie is worth about 1.15 of an extra shootout win on average, 
#On a single season basis, it'd be difficult to tell that team from a league-average team





###################################
# Bayesian Analysis
###################################

set.seed(20142015)
#set.seed(20122013)
options(stringsAsFactors = FALSE)
shootout <- nhl

k=nrow(shootout)
#k=1000
y=shootout$Goal01[1:k]
n1<-sum(y)                  		# Number of successes
n0<-k-n1

ngoalies=length(table(shootout$Goalie2[1:k]))
g.names=names(table(shootout$Goalie2[1:k]))
nshooter=length(table(shootout$Shooter2[1:k]))
s.names=names(table(shootout$Shooter2[1:k]))
nstatus=length(table(shootout$SOStatus[1:k]))
st.names=names(table(shootout$SOStatus[1:k]))
nteams=length(table(shootout$ShootingTm[1:k]))
t.names=names(table(shootout$ShootingTm[1:k]))
shootout$Rd=as.character(shootout$Rd)
nrounds=length(table(shootout$Rd[1:k]))
r.names=names(table(shootout$Rd[1:k]))
shootout$PosD=as.numeric(shootout$Pos=="D")

X=cbind(rep(1,k),model.matrix(~shootout$Goalie2[1:k]-1),
        model.matrix(~shootout$Shooter2[1:k]-1),
        model.matrix(~shootout$SOStatus[1:k]-1),
        model.matrix(~shootout$ShootingTm[1:k]-1),
        model.matrix(~shootout$PosD[1:k]-1))

nparam=ncol(X)

ncovars=nparam-ngoalies-nshooter-1
#prior mean and variance parameters for beta

beta0<-c(-0.25, rep(0,nparam-1))    	
#a0=10
a0=5
b0=nparam*a0
#Note Gelman, Bayesian Analysis (2006) 
# this is equivalent to inv chisq with df 2*a0 and 
# and scale b0/a0 and we assume sum of squared error for
# beta's to be roughly unity then b0/a0 should be approximately nparam

#initialize tau2 prior variance of regression coefficients
tau20=rinvgamma(1,a0,b0)
vbeta0<-tau20*diag(nparam)

nburn=1000
nsave=1000
thin=10
nsim=nburn+nsave*thin+1

z<-rep(0,k)				# Latent Normal Variable
Betamat<-matrix(0,nrow=nsave,ncol=(nparam)+4) 

#starting values for tau2
tau2 = tau20

#generate starting beta
Beta=rnorm(nparam,beta0,0.1)
Betamat[1,]=c(Beta,rep(tau2,4))



j=1
for (i in 2:nsim) {
if (i%%20==0) print(i)
 # Draw Latent Variable, z, from its full conditional, given y
  muz<-X%*%Beta			# Update Mean of Z
  z[y==0]<-rtnorm(n0,muz[y==0],1,-Inf,0)
#z[y==0]=rtmvnorm(1,mean=muz[y==0],1,lower=-Inf,upper=0)
  z[y==1]<-rtnorm(n1,muz[y==1],1,0,Inf)

  
 # Beta from of posterior of Beta|Z, Beta0
vbeta <- solve(crossprod(X,X)+1/tau2*diag(nparam))
mbeta <- vbeta%*%(crossprod(X,z)+1/tau2*beta0)
Beta=c(rmvnorm(1,mbeta,vbeta))
  
#generate tau2 | beta
#print(sum((Beta-beta0)^2))
tau2.intercept=rinvgamma(1,a0+1.5,b0+0.5*(Beta[1]-beta0[1])^2)
tau2.goalies=rinvgamma(1,a0+1+ngoalies/2,b0+0.5*sum((Beta[1:ngoalies+1]-beta0[1:ngoalies+1])^2))
tau2.shooters=rinvgamma(1,a0+1+nshooter/2,b0+0.5*sum((Beta[(ngoalies+2):(ngoalies+nshooter+1)]-beta0[(ngoalies+2):(ngoalies+nshooter+1)])^2))
tau2.covars=rinvgamma(1,a0+1+nstatus+nteams+nrounds,b0+0.5*sum((Beta[(ngoalies+nshooter+2):nparam])-beta0[(ngoalies+nshooter+2):nparam])^2)
tau2.out=c(tau2.intercept,tau2.goalies,tau2.shooters,tau2.covars)
tau2=c(tau2.intercept,rep(tau2.goalies,ngoalies),rep(tau2.shooters,nshooter),rep(tau2.covars,ncovars))


if(i>nburn & (i-nburn)%%thin==0 ) {Betamat[j,]<-c(Beta,tau2.out);j=j+1}
 

}

colnames(Betamat)=c("Interc",g.names,s.names,st.names,t.names,"PosD","tau2.interc","tau2.g","tau2.s","tau2.cov")
save.image("shootout_hier_2016_a.RData")
print("voila")

