args<-commandArgs(T) 
#$ARGV[0] = $1
setwd(args[1])
####################################################
######CARD plot
#####################################################
cog = read.table(args[2],header=FALSE,sep="\t",quote="",stringsAsFactors = F) 
library(ggplot2)
x = seq(1,nrow(cog))
cog = cbind(cog, x)
png('CARD.png',width=850,height=800,units="px",bg = "transparent")
#ggplot(data=cog,aes(x=x,y=cog$V2,fill=as.factor(cog$V3))) +
#  geom_bar(stat="identity",show.legend=TRUE)+
#  facet_wrap(~cog$V3,scales="free_y")+
#  labs(title="CARD Classification",x='', y='Numbers of Genes')+
#  scale_x_continuous(breaks=seq(1,nrow(cog)),labels=cog$V1)+
#  coord_flip()+
#  scale_y_continuous(trans="log1p")+
#  facet_grid(cog$V3 ~ ., space = "free",scales = "free") +
#  theme(legend.position="bottom",
#        legend.title = element_blank(),  ##图例小标题
#        panel.border=element_rect(size=2, color="gray75", fill="transparent"),
#        panel.background=element_blank(),
#        panel.grid.major=element_line(size=0.5, color="gray75"),
#        strip.text.x = element_blank(),strip.text.y = element_blank())  ##去掉分页的小标题
 ggplot(data=cog,aes(x=x,y=V2,fill=as.factor(V3))) +scale_x_continuous(breaks=seq(1,nrow(cog)),labels=cog$V1) +
	geom_bar(stat="identity", position="dodge")+
  labs(xlab="", ylab='Numbers of Genes')+
  coord_flip()+
  theme(legend.position="bottom",
        legend.title = element_blank(),
        panel.border=element_rect(size=2, color="gray75", fill="transparent"),
        panel.background=element_blank(),
        panel.grid.major=element_line(size=0.5, color="gray75"),
        strip.text.x = element_blank(),strip.text.y = element_blank())
dev.off()
