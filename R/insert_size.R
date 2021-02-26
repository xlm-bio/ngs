args <- commandArgs()
markerx = 1
for (i in seq(1,length(args))) {
  argsplit <- unlist(strsplit(args[i], split="="))
  if (argsplit[1]=="inputfile") { if (!is.na(argsplit[2])) { inputfile = argsplit[2] } }
  if (argsplit[1]=="outputfile1") { if (!is.na(argsplit[2])) { outputfile1 = argsplit[2] } }
  if (argsplit[1]=="outputfile2") { if (!is.na(argsplit[2])) { outputfile2 = argsplit[2] } }
}
library(ggplot2)
oridata <- read.table(inputfile,skip=11)
alpha = 0.001
tempmat <- matrix(1,nrow(oridata),nrow(oridata))
tempmat[lower.tri(tempmat)] = 0
data <- oridata$V2 %*% tempmat
st = min(which(data>sum(oridata$V2)*alpha))
en = max(which(data<sum(oridata$V2)*(1-alpha)))
newdata = oridata[st:en,]
meanValue = sum(newdata$V1*newdata$V2)/sum(newdata$V2)
sdValue = sqrt(sum(newdata$V1*1.0*newdata$V1*newdata$V2)/sum(newdata$V2)-meanValue**2)
png (paste(outputfile1), width=500,height=500,res=75)
ggplot(data=newdata, aes(x=V1,y=V2)) + geom_line(size=1) +
     xlab("Insert length (bp)") + ylab("Count") +
     theme(legend.position="none",
            panel.border=element_rect(size=2, color="gray75", fill="transparent"),
            panel.background=element_blank(),
            panel.grid.major=element_line(size=0.5, color="gray75"),
            plot.title=element_text(hjust=0.5)
  )
write.table(paste("Insert_size: ",floor(meanValue),"±",floor(sdValue)),file = outputfile2,quote = FALSE,row.names = FALSE, col.names = FALSE)

dev.off()
