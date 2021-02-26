args <- commandArgs()
for (i in seq(1,length(args))) {
  argsplit <- unlist(strsplit(args[i], split="="))
  if (argsplit[1]=="inputfile") { if (!is.na(argsplit[2])) { inputfile = argsplit[2] } }
  if (argsplit[1]=="outputfile") { if (!is.na(argsplit[2])) { outputfile = argsplit[2] } }
}
oridata <- read.table(inputfile, stringsAsFactors=F)
tmp <- c()
for (i in seq(1, nrow(oridata))) {
  if (unlist(strsplit(oridata$V9[i], ";"))[2]=="partial=00") { tmp[i] = 1 } else { tmp[i] = 0 }
}
oridata$V10 <- tmp
oridata$V11 <- as.numeric(oridata$V5)-as.numeric(oridata$V4)
oridata$V11[which(oridata$V11>3000)] = 3000
library(ggplot2)
png (paste(outputfile), width=500,height=300,res=75)
ggplot(oridata, aes(x=V11, fill=as.factor(V10)))+geom_histogram(bins=60) + 
  scale_fill_manual(values = c("black","gray50")) + xlab("Gene length") + ylab("Count") +
theme(legend.position="none",
      panel.border=element_rect(size=2, color="gray75", fill="transparent"),
      panel.background=element_blank(),
      panel.grid.major=element_line(size=0.5, color="gray75"),
      plot.title=element_text(hjust=0.5))
dev.off()
