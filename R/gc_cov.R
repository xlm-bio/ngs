args <- commandArgs()
markerx = 1
for (i in seq(1,length(args))) {
  argsplit <- unlist(strsplit(args[i], split="="))
  if (argsplit[1]=="inputfile") { if (!is.na(argsplit[2])) { inputfile = argsplit[2] } }
  if (argsplit[1]=="outputfile") { if (!is.na(argsplit[2])) { outputfile = argsplit[2] } }
}
png (paste(outputfile), width=500,height=500,res=75)
fileDir = inputfile
data_cutoff = 0.025
plot_cutoff = 0.1
bin_num = 50
fileList <- list.files(fileDir)
data <- c()
for (i in fileList) {
  data <- rbind(data, read.table(paste(fileDir, "/", i, sep="")))
}
covLB <- as.numeric(quantile(data$V1,data_cutoff))
covUB <- as.numeric(quantile(data$V1,1-data_cutoff))
gcLB <- as.numeric(quantile(data$V2,data_cutoff))
gcUB <- as.numeric(quantile(data$V2,1-data_cutoff))
covLB <- max(floor(covLB*(1-plot_cutoff)/100-1)*100,0)
covUB <- floor(covUB*(1+plot_cutoff)/100+1)*100
gcLB <- max(floor(gcLB*(1-plot_cutoff)/5-1)*5,0)
gcUB <- min(floor(gcUB*(1+plot_cutoff)/5+1)*5,100)

library(ggplot2)
require(gridExtra)
library(ggpubr)
p_main <- ggplot(data=data, aes(x=V2,y=V1)) + geom_hex(bins=bin_num) + 
  scale_fill_gradient(low="#d9d9d9", high="#252525") + 
  xlab("GC content (%)") + ylab("Sequencing depth (x)") + xlim(c(gcLB, gcUB)) + ylim(c(covLB, covUB)) + 
  #scale_y_continuous(labels=function(x) { t = ""; for (i in 1:6-floor(log(x,10))) { t = paste(" ", t, sep="")}; paste(t, as.character(x), sep="")}) +
  theme(legend.position="none",
        panel.border=element_rect(size=2, color="gray75", fill="transparent"),
        panel.background=element_blank(),
        panel.grid.major=element_line(size=0.5, color="gray75")
        )
p_gc <- ggplot(data=data, aes(x=V2)) + geom_histogram(bins=bin_num*2) + xlim(c(gcLB, gcUB)) +
  theme(legend.position="none",
        axis.title.x = element_blank(),
        axis.text.y = element_blank(),
        axis.title.y = element_blank(),
        axis.ticks.y = element_blank(),
        panel.border=element_rect(size=2, color="gray75", fill="transparent"),
        panel.background=element_blank(),
        panel.grid.major=element_line(size=0.5, color="gray75"),
        panel.grid.major.y = element_blank(),
        panel.grid.minor=element_blank())
p_cov <- ggplot(data=data, aes(x=V1)) + geom_histogram(bins=bin_num*2) + xlim(c(covLB, covUB)) +
  theme(legend.position="none",
        axis.title.y = element_blank(),
        axis.text.x = element_blank(),
        axis.title.x = element_blank(),
        axis.ticks.x = element_blank(),
        panel.border=element_rect(size=2, color="gray75", fill="transparent"),
        panel.background=element_blank(),
        panel.grid.major=element_line(size=0.5, color="gray75"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor=element_blank())+ coord_flip()

ggarrange(p_gc, NULL, p_main, p_cov, ncol = 2, nrow = 2, align = "hv", widths = c(4, 1), heights = c(1, 4))
dev.off()
