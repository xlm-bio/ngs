args <- commandArgs()
markerx = 1
for (i in seq(1,length(args))) {
  argsplit <- unlist(strsplit(args[i], split="="))
  if (argsplit[1]=="inputfile") { if (!is.na(argsplit[2])) { inputfile = argsplit[2] } }
  if (argsplit[1]=="outputfile") { if (!is.na(argsplit[2])) { outputfile = argsplit[2] } }
  if (argsplit[1]=="kmer_num") { if (!is.na(argsplit[2])) { kmer_num = as.numeric(argsplit[2]) } }
  if (argsplit[1]=="genome_size") { if (!is.na(argsplit[2])) { genome_size = as.numeric(argsplit[2]) } }
  if (argsplit[1]=="x_Max") { if (!is.na(argsplit[2])) { x_Max = as.numeric(argsplit[2]) } }
}
library(ggplot2)
oridata <- read.table(inputfile)
df = oridata[1:x_Max,]
df[x_Max,]$V2 = sum(oridata[which(oridata$V1>=x_Max),]$V2)
png (paste(outputfile), width=500,height=500,res=75)
ggplot(data=df, aes(x=V1,y=V2)) + geom_line(size=1) + xlim(c(0,600)) +
  ylim(c(0, floor(1.5*oridata$V2[floor(kmer_num/genome_size)]/1000)*1000)) +
  theme(legend.position="none",
      panel.border=element_rect(size=2, color="gray75", fill="transparent"),
      panel.background=element_blank(),
      panel.grid.major=element_line(size=0.5, color="gray75"),
      plot.title=element_text(hjust=0.5)
)
dev.off()

