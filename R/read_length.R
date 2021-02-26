args <- commandArgs()
markerx = 1
for (i in seq(1,length(args))) {
  argsplit <- unlist(strsplit(args[i], split="="))
  if (argsplit[1]=="inputfile") { if (!is.na(argsplit[2])) { inputfile = argsplit[2] } }
  if (argsplit[1]=="outputfile") { if (!is.na(argsplit[2])) { outputfile = argsplit[2] } }
}
library(ggplot2)
oridata <- read.table(inputfile)
png (paste(outputfile), width=500,height=500,res=75)
ggplot(data=oridata, aes(x=V1,y=V2)) + geom_line(size=1)  +
  xlab("Read Length") + ylab("Count") + labs(title="Read Length Histogram") +
  theme(legend.position="none",
        panel.border=element_rect(size=2, color="gray75", fill="transparent"),
        panel.background=element_blank(),
        panel.grid.major=element_line(size=0.5, color="gray75"),
        plot.title=element_text(hjust=0.5)
  )
dev.off() 
 
