args<-commandArgs(T) 
#$ARGV[0] = $1
library(ggplot2)
setwd(args[1])
####################################################
######KEGG plot
#######################################################
cog = read.table(args[2],header=FALSE,sep="\t",quote="",stringsAsFactors = F)
cog[-which(cog$V3=="Organismal Systems" | cog$V3=="Human Diseases"),]->cog
x = seq(1,nrow(cog))
cog = cbind(cog, x)

png('KEGG.png',width=850,height=400,units="px",bg = "transparent")
ggplot(data=cog,aes(x=x,y=V2,fill=as.factor(V3))) + 
  geom_bar(stat="identity",show.legend=TRUE) + 
  scale_x_continuous(breaks=seq(1,nrow(cog)),labels=cog$V1)+
  labs(xlab="", ylab='Numbers of Genes')+
  coord_flip() + 
  theme(legend.position="bottom",
  legend.title = element_blank(),
        panel.border=element_rect(size=2, color="gray75", fill="transparent"),
        panel.background=element_blank(),
        panel.grid.major=element_line(size=0.5, color="gray75"))
dev.off()
