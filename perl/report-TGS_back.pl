#!/usr/bin/perl -w
use strict;
use Statistics::Descriptive;
use Getopt::Long;
my $USAGE = qq{
Usage:
	$0 -inputdir <inputdir> -additional_file <additional_file>
Options:
	-inputdir	<string>	A
	-additional_file	<string>	additional_file dir
};
my ($inputdir,$additional_file);
GetOptions(
	"inputdir=s" =>\$inputdir,
	"additional_file=s" =>\$additional_file,
);

die "$USAGE" unless $inputdir;


#######################################html#####################
my @a=split /\//,$inputdir;
my $sample=$a[-1];
system("mkdir -p $inputdir/$sample\_html");
open HTML,">$inputdir/$sample\_html/$sample\_main.html" or die $!;
system("mkdir -p $inputdir/$sample\_html/additional_file");
system("cp $additional_file/* $inputdir/$sample\_html/additional_file");
open HEAD,">$inputdir/$sample\_html/header.html" or die $!;
print HEAD"<html>\n
<script async=\"\" src=\"additional_file/theme.js\"></script>\n
<script type=\"text/javascript\" src=\"additional_file/jquery-3.2.1.min.js\"></script>\n
<script type=\"text/javascript\" src=\"additional_file/toggle.js\"></script>\n
<link rel=\"stylesheet\" href=\"additional_file/theme.css\" type=\"text/css\">\n
<link rel=\"stylesheet\" href=\"additional_file/header.css\" type=\"text/css\">\n
<body class=\"wy-body-for-nav\">\n
<div class=\"wy-grid-for-nav\">\n
\t<div class=\"topmenu\">\n
\t\t<h1 id=\"report_title\">Genome Assembly and Annotation Pipeline Report</h1>\n
\t\t<HR>\n
\t\t<ul id=\"menu\" style=\"display:none;\">\n
\t\t\t<li><a href=\"#status\">Project status</a></li> |\n
\t\t\t<li><a href=\"#overview\">Pipeline overview</a></li> |\n";

my $head;
print HTML"\t\t\t<HR>\n
	\t\t\t<div id=\"\" class=\"section\">\n
	\t\t\t\t<h1><center>Genome assembly and annotation pipeline overview</center></h1>\n
	\t\t\t\t<p>Genome assembly and annotation pipeline is composed of three analysis procedure: <b>(1) raw reads trimming and assembly</b>, <b>(2) genomic component analysis</b> and <b>(3) gene annotation</b>.</p>\n
	\t\t\t\t<ul class=\"simple\">\n
	\t\t\t\t<li><p>(1.1) If long reads (PacBio reads or Nanopore reads) are provided as input, raw sequencing reads are trimmed and assembled into contigs/scaffolds with Canu [Genome research, 2017] or Flye [Nature Biotechnology, 2019]. If NGS short reads (Illumina paired-end reads) are provided additionally, NGS short reads will be used to polish contigs/scaffolds with pilon [PLoS One, 2014].</p></li>\n
	\t\t\t\t<li><p>(1.2) If NGS short reads are provided only, raw reads are trimmed into clean reads with sickle or Trimmomatic [Bioinformatics, 2014], corrected with Musket [Bioinformatics, 2012], and assembled into contigs/scaffolds with multiple assembler (SOAPdenovo2 [Gigascience, 2012], SPAdes [Journal of computational biology, 2012], Velvet [Genome research, 2008] and Platanus [Genome research, 2014]). Then, best assembly result is obtained based on several widely used metric in genome assembly. After that, reads are mapped to the best assembly result to check misassembly and count reads coverage.</p></li>\n
	\t\t\t\t<li><p>(1.2) If NGS short reads are provided only, raw reads are trimmed into clean reads with sickle or Trimmomatic [Bioinformatics, 2014], corrected with Musket [Bioinformatics, 2012], and assembled into contigs/scaffolds with multiple assembler (SOAPdenovo2 [Gigascience, 2012], SPAdes [Journal of computational biology, 2012], Velvet [Genome research, 2008] and Platanus [Genome research, 2014]). Then, best assembly result is obtained based on several widely used metric in genome assembly. After that, reads are mapped to the best assembly result to check misassembly and count reads coverage.</p></li>\n
	\t\t\t\t</p></li>\n
	\t\t\t\t<li><p>(2) Genomic component analysis including CRISPR array recognition with PILER-CR [BMC Bioinformatics, 2007], repetitive structure detection with TRF [Nucleic acids research, 1999], non-coding RNA prediction with tRNAscanSE [Nucleic acids research, 2016] and RNAmmer [Nucleic acids research, 2007], and gene prediction with Prodigal [BMC Bioinformatics, 2010].</p></li>\n
	\t\t\t\t<li><p>(3) Predicted genes in the previous step are annotated by several databases including KEGG, GO, COG, NR, SwissProt, AntiSMASH, MetaCyc, PHI, Pfam, CARD and VFDB.</p></li>\n
	\t\t\t\t</ul>\n
	\t\t\t</div>\n";
###################################################################


#my @a=split /\//,$inputdir;
#my $sample=$a[-1];
if(( -e "$inputdir/reads_info.txt") || ( -e "$inputdir/read_length.png")){
	print HEAD"\t\t\t<li><a href=\"#sequencing\">Sequencing status</a></li> |\n";
	print HTML"\t\t\t<HR>\n
		\t\t\t<div id=\"\" class=\"section\">\n
		\t\t\t\t<h1><center>Sequencing data quality control summary</center></h1>\n
		\t\t\t\t<p>For NGS paired-end reads, insert length, read length after trimming and correction ratio could be the evidence of sequencing quality. For TGS long reads, correction ratio and read length could be the evidence of sequencing quality. The statistics of raw reads and trimmed reads is shown below:</p>\n";
	if(-e "$inputdir/reads_info.txt"){
		print HTML"\t\t\t\t<p align=\"center\"><b>TABLE:</b> Reads statistics.</p>\n
		\t\t\t\t<div class=\"wy-table-responsive\"><table class=\"docutils\" border=\"1\">\n
		\t\t\t\t<thead>\n
		\t\t\t\t\t<tr><th>Sample</th><th>Type</th><th>Read length (bp)</th><th>Total reads</th><th>Filtered (%)</th><th>Raw data</th><th>Clean data</th></tr>\n
		\t\t\t\t</thead>\n
		\t\t\t\t<tbody>\n";

		open INFO,"$inputdir/reads_info.txt" or die $!;
		while(<INFO>){
			chomp;
			next if(/Type/);
			my @arr=split /\t/,$_;
			print HTML"\t\t\t\t\t<tr><td>$sample</td><td>$arr[0]</td><td>$arr[1]</td><td>$arr[2]</td><td>$arr[3]</td><td>$arr[4]</td><td>-</td></tr>\n";
		}
		close INFO;
		print HTML"	\t\t\t\t</tbody>\n
			\t\t\t\t</table></div>\n";
	}
	if( -e "$inputdir/read_length.png"){
		print HTML"\t\t\t\t<div align=\"center\"><img src=../read_length.png></img></div>\n
				\t\t\t\t<p align=\"center\"><b>FIGURE:</b> Read length distribution.</p>\n";
	}
	print HTML"\t\t\t</div>\n";
}	
#################################html#####################
if((-e "$inputdir/$sample\_kmer_freq.png") || (-e "$inputdir/genome_info.txt" ) ||(-e "$inputdir/$sample\_gc_cov.png") ||( -e "$inputdir/$sample\_checkM/$sample\_checkM.log")){
	
	print HTML"\t\t\t<HR>\n
		\t\t\t<div id=\"\" class=\"section\">\n
		\t\t\t\t<h1><center>Genome assembly summary</center></h1>\n";
	print HEAD"\t\t\t\<li><a href=\"#assembly\">Genome assembly</a></li> |\n";

###############################

if( -e "$inputdir/$sample\_kmer_freq.png"){
	##############################################html#####################
	print HTML"\t\t\t\t<h3>K-mer counting</h3>\n
			\t\t\t\t<p>Before assembly process, clean reads are chopped into k-mers (k=17 here), and then, all k-mers are counted with Jellyfish [Bioinformatics, 2011]. Sequencing error rate, average sequencing depth, genome size, genome duplication ratio, heterozygosis ratio and contamination ratio can be estimated roughly. The frequency distribution of k-mer depth is shown below:</p>\n
			\t\t\t\t<div align=\"center\"><img src=../$sample\_kmer_freq.png></img></div>\n
			\t\t\t\t<p align=\"center\"><b>FIGURE:</b> k-mer depth distribution.</p>\n
			\t\t\t\t<p><b>NOTE:</b> Regardless of the sequence error, genome duplication, heterozygosis and contamination k-mer depth distribution should be subject to Poisson. Main peak is closely related to sequencing depth. Several peaks located at two and three times of the main peak is caused by the duplicated sequence in genome. A sharp peak located at extremely low depth is caused by the sequencing error. Lower peaks compared with the main peak which appears at the left of main peak is cause by heterozygous sequence or contamination.</p>\n";
}

if( (-e "$inputdir/genome_info.txt" ) && ( -e "$inputdir/reads_match.txt") && ( -e "inputdir/best_par.txt")){
	
	print HTML"\t\t\t\t<h3>Assembly</h3>\n
			\t\t\t\t<p>Clean reads are assembled with several <i>de Bruijn</i> graph based assemblers under several set of parameters. Best assembly result is selected based on N50, N75, contig number, length of largest contig, total bases and ambiguous bases. Statistics is shown below:</p>\n
			\t\t\t\t<p align=\"center\"><b>TABLE:</b> Assembly statistics.</p>\n
			\t\t\t\t<div class=\"wy-table-responsive\"><table class=\"docutils\" border=\"1\">\n
			\t\t\t\t<thead>\n
			\t\t\t\t\t<tr><th>Sample</th><th>Num (#)</th><th>Genome size (Kbp)</th><th>N50 (kbp)</th><th>N75 (kbp)</th><th>Max  (Kbp)</th><th>Ns (bp)</th><th>GC (%)</th><th>cover (%)</th><th>Assember and parameters</th></tr>\n
			\t\t\t\t</thead>\n
			\t\t\t\t<tbody>\n
			\t\t\t\t\t";
	
	#####################Assembly statistics####################		
	open GENOMEINFO,"$inputdir/genome_info.txt" or die $!;
	while(<GENOMEINFO>){
		chomp;
		next if(/Largest_Scaffold/);
		my @arr=split /\t/,$_;
		$arr[-2]=sprintf "%.2f",$arr[-2];
		#print ASSEMBLY"$sample\t$arr[1]\t$arr[5]\t$arr[2]\t$arr[3]\t$arr[4]\t$arr[-1]\t$arr[-2]\t";
		print HTML"<tr><td>$sample</td><td>$arr[1]</td><td>$arr[5]</td><td>$arr[2]</td><td>$arr[3]</td><td>$arr[4]</td><td>$arr[-1]</td><td>$arr[-2]</td><td>";
	}

	open MATCH,"$inputdir/reads_match.txt" or die $!;
	my $co=0;
	while(<MATCH>){
		chomp;
		$co++;
		if($co==5){
			my @ar=split /\s/,$_;
			$ar[4]=~s/\(//g;
			$ar[4]=~s/%//g;
			#print ASSEMBLY"$ar[4]\t";
			print HTML"$ar[4]</td><td>";
		}
	}
	close MATCH;
	


	open BEST,"$inputdir/best_par.txt" or die $!;
		while(<BEST>){
			chomp;
			next if(/^Assember/);
			$_=~s/\.fasta//g;
	#		print ASSEMBLY"$_\n";
			print HTML"$_</td></tr>\n";
	}
	close BEST;
	print HTML"\t\t\t\t</tbody>\n
			\t\t\t\t</table></div>\n";
}

if( (-e "$inputdir/genome_info.txt" ) && ( !-e "$inputdir/reads_match.txt") && ( !-e "inputdir/best_par.txt")){
	
	print HTML"\t\t\t\t<h3>Assembly</h3>\n
			\t\t\t\t<p>Clean reads are assembled with several <i>de Bruijn</i> graph based assemblers under several set of parameters. Best assembly result is selected based on N50, N75, contig number, length of largest contig, total bases and ambiguous bases. Statistics is shown below:</p>\n
			\t\t\t\t<p align=\"center\"><b>TABLE:</b> Assembly statistics.</p>\n
			\t\t\t\t<div class=\"wy-table-responsive\"><table class=\"docutils\" border=\"1\">\n
			\t\t\t\t<thead>\n
			\t\t\t\t\t<tr><th>Sample</th><th>Num (#)</th><th>Genome size (Kbp)</th><th>N50 (kbp)</th><th>N75 (kbp)</th><th>Max  (Kbp)</th><th>Ns (bp)</th><th>GC (%)</th></tr>\n
			\t\t\t\t</thead>\n
			\t\t\t\t<tbody>\n
			\t\t\t\t\t";
	
	#####################Assembly statistics####################		
	open GENOMEINFO,"$inputdir/genome_info.txt" or die $!;
	while(<GENOMEINFO>){
		chomp;
		next if(/Largest_Scaffold/);
		my @arr=split /\t/,$_;
		$arr[-2]=sprintf "%.2f",$arr[-2];
		#print ASSEMBLY"$sample\t$arr[1]\t$arr[5]\t$arr[2]\t$arr[3]\t$arr[4]\t$arr[-1]\t$arr[-2]\t";
		print HTML"<tr><td>$sample</td><td>$arr[1]</td><td>$arr[5]</td><td>$arr[2]</td><td>$arr[3]</td><td>$arr[4]</td><td>$arr[-1]</td><td>$arr[-2]</td></tr>\n";
	}
		print HTML"\t\t\t\t</tbody>\n
			\t\t\t\t</table></div>\n";
}
if( (-e "$inputdir/genome_info.txt" ) && ( !-e "$inputdir/reads_match.txt") && ( -e "inputdir/best_par.txt")){
	
	print HTML"\t\t\t\t<h3>Assembly</h3>\n
			\t\t\t\t<p>Clean reads are assembled with several <i>de Bruijn</i> graph based assemblers under several set of parameters. Best assembly result is selected based on N50, N75, contig number, length of largest contig, total bases and ambiguous bases. Statistics is shown below:</p>\n
			\t\t\t\t<p align=\"center\"><b>TABLE:</b> Assembly statistics.</p>\n
			\t\t\t\t<div class=\"wy-table-responsive\"><table class=\"docutils\" border=\"1\">\n
			\t\t\t\t<thead>\n
			\t\t\t\t\t<tr><th>Sample</th><th>Num (#)</th><th>Genome size (Kbp)</th><th>N50 (kbp)</th><th>N75 (kbp)</th><th>Max  (Kbp)</th><th>Ns (bp)</th><th>GC (%)</th><th>Assember and parameters</th></tr>\n
			\t\t\t\t</thead>\n
			\t\t\t\t<tbody>\n
			\t\t\t\t\t";
	
	#####################Assembly statistics####################		
	open GENOMEINFO,"$inputdir/genome_info.txt" or die $!;
	while(<GENOMEINFO>){
		chomp;
		next if(/Largest_Scaffold/);
		my @arr=split /\t/,$_;
		$arr[-2]=sprintf "%.2f",$arr[-2];
		#print ASSEMBLY"$sample\t$arr[1]\t$arr[5]\t$arr[2]\t$arr[3]\t$arr[4]\t$arr[-1]\t$arr[-2]\t";
		print HTML"<tr><td>$sample</td><td>$arr[1]</td><td>$arr[5]</td><td>$arr[2]</td><td>$arr[3]</td><td>$arr[4]</td><td>$arr[-1]</td><td>$arr[-2]</td><td>\n";
	}
		open BEST,"$inputdir/best_par.txt" or die $!;
		while(<BEST>){
			chomp;
			next if(/^Assember/);
			$_=~s/\.fasta//g;
	#		print ASSEMBLY"$_\n";
			print HTML"$_</td></tr>\n";
	}
	close BEST;
		print HTML"\t\t\t\t</tbody>\n
			\t\t\t\t</table></div>\n";
}

if( -e "$inputdir/$sample\_gc_cov.png"){
	print HTML"\t\t\t\t<h3>GC content and sequencing depth</h3>\n
			\t\t\t\t<p>After assembly, NGS paired-end reads are mapped to assmebled contigs/scaffolds to count base depth. Then, assembled contigs/scaffolds are chopped into fragments (windowsize= and stepsize= here). Thus, GC content and average sequencing depth for each slides are counted. As in prokaryotic genome sequencing, GC content and sequencing depth are highly uniform in all genome region (except some species region such as 16S rDNA gene region), GC content and  sequencing depth distribution could be the evidence of sample contamination and degradation. Here is the frequency distribution of GC content and sequence depth (the darker the color, the more the fragments are counted):</p>\n
			\t\t\t\t<div align=\"center\"><img src=../$sample\_gc_cov.png></img></div>\n
			\t\t\t\t<p align=\"center\"><b>FIGURE:</b> GC content and sequencing depth distribution.</p>\n";
}


	#####################checkM############################
if( -e "$inputdir/$sample\_checkM/$sample\_checkM.log"){
	open CHECKM,"$inputdir/$sample\_checkM/$sample\_checkM.log" or die $!;
	print HTML"\t\t\t\t<h3>Genome completeness, contamination and heterogeneity</h3>\n
			\t\t\t\t<p>Genome completeness, contamination and heterogeneity is evaluated with checkM [Genome research, 2015]. Result is shown below:</p>\n
			\t\t\t\t<p align=\"center\"><b>TABLE:</b> Genome completeness, contamination and heterogeneity evaluation.</p>\n
			\t\t\t\t<div class=\"wy-table-responsive\"><table class=\"docutils\" border=\"1\">\n
			\t\t\t\t<thead>\n
			\t\t\t\t\t<tr><th>Sample</th><th>Marker lineage</th><th>Completeness (%)</th><th>Contamination (%)</th><th>Heterogeneity (%)</th></tr>\n
			\t\t\t\t</thead>\n
			\t\t\t\t<tbody>\n
			\t\t\t\t\t";
				
	while(<CHECKM>){
		chomp;
		next if(/^-/);
		next if(/Bin/);
		my @arr=split /\s+/,$_;
		#print CHECKMOUT"$sample\t$arr[1]\t$arr[-3]\t$arr[-2]\t$arr[-1]\n";
		print HTML"<tr><td>$sample</td><td>$arr[1]</td><td>$arr[-3]</td><td>$arr[-2]</td><td>$arr[-1]</td></tr>\n";
	}
	close CHECKM;
	print HTML"\t\t\t\t</tbody>\n
			\t\t\t\t</table></div>\n";
}
	print HTML"\t\t\t</div>\n";
}

######################Genomic component summary#######################
if ( (-e "$inputdir/RNA.xls") || ( -e "$inputdir/16s_blast.result.xls") || ( -e "$inputdir/$sample\_RepeatMasker/$sample\.trf.txt") || (-e "$inputdir/$sample\_piler-cr/$sample\.pilercr.result") || ( -e "$inputdir/$sample\.gene.xls")){
	print HTML"\t\t\t<HR>\n
			\t\t\t<div id=\"\" class=\"section\">\n
			\t\t\t\t<h1><center>Genomic component summary</center></h1>\n";
	print HEAD"\t\t\t<li><a href=\"#component\">Genomic components</a></li> |\n";		
	if( -e "$inputdir/RNA.xls"){
		print HTML"\t\t\t\t<h3>Non-coding RNA</h3>\n
					\t\t\t\t<p>Non-coding RNA widely exists in prokaryote. Ribosome RNA (rRNA) including 5S rRNA, 16S rRNA and 23S rRNA is annotated with RNAmmer [Nucleic acids research, 2007]. transfer RNA (tRNA) is annotated with tRNAscanSE [Nucleic acids research, 2016]. Small RNA (sRNA) is annotated with infernal [Bioinformatics, 2013] using the complete Rfam database. Statistics is shown below:</p>\n
					\t\t\t\t<p align=\"center\"><b>TABLE:</b> Non-coding RNA statistics.</p>\n
					\t\t\t\t<div class=\"wy-table-responsive\"><table class=\"docutils\" border=\"1\">\n
					\t\t\t\t<thead>\n
					\t\t\t\t\t<tr><th>Sample</th><th>Type</th><th>Num (#)</th><th>Ave length (bp) (%)</th><th>Min length (bp)</th><th>Max length (bp)</th></tr>\n
					\t\t\t\t</thead>\n
					\t\t\t\t<tbody>\n";
		open RNA,"$inputdir/RNA.xls" or die $!;
		while(<RNA>){
			chomp;
			next if(/Type/);
			my @line=split /\t/,$_;
			print HTML"\t\t\t\t\t<tr><td>$sample</td><td>$line[0]</td><td>$line[1]</td><td>$line[2]</td><td>$line[3]</td><td>$line[4]</td></tr>\n";
		}
		close RNA;
		print HTML"\t\t\t\t</tbody>\n
				\t\t\t\t</table></div>\n";
	}
	if( -e "$inputdir/16s_blast.result.xls"){
		print HTML"\t\t\t\t<p align=\"center\"><b>TABLE:</b> 16S rRNA alignment report.</p>\n
				\t\t\t\t<div class=\"wy-table-responsive\"><table class=\"docutils\" border=\"1\">\n
				\t\t\t\t<thead>\n
				\t\t\t\t\t<tr><th>Sample</th><th>contigs</th><th>start</th><th>end</th><th>strand</th><th>target</th><th>identity (%)</th><th>Annotation</th></tr>\n
				\t\t\t\t</thead>\n
				\t\t\t\t<tbody>\n";
		open BLAST,"$inputdir/16s_blast.result.xls" or die $!;
		while(<BLAST>){
			chomp;
			next if(/Sample/);
			my @arr=split /\t/,$_;
			print HTML"\t\t\t\t\t<tr><td>$sample</td><td>$arr[1]</td><td>$arr[2]</td><td>$arr[3]</td><td>$arr[4]</td><td>$arr[5]</td><td>$arr[6]</td><td>$arr[7]</td></tr>\n";
		}
		close BLAST;
		print HTML"\t\t\t\t</tbody>\n
				\t\t\t\t</table></div>\n";
	}
	if( -e "$inputdir/$sample\_RepeatMasker/$sample\.trf.txt"){
		print HTML"\t\t\t\t<h3>Tandem repeat</h3>\n
				\t\t\t\t<p>Genomic region with several contiguous repeat units are detected as repetitive region. Repetitive region is detected with TRF [Nucleic acids research, 1999]. Region with repeat unit ranged from 15 to 65 bp is defined as minisatellite region and region with repeat unit ranged from 2 to 10 bp is defined as microsatellite region. Statistics is shown below:</p>\n
				\t\t\t\t<p align=\"center\"><b>TABLE:</b> Tandem repeat statistics.</p>\n
				\t\t\t\t<div class=\"wy-table-responsive\"><table class=\"docutils\" border=\"1\">\n
				\t\t\t\t<thead>\n
				\t\t\t\t\t<tr><th>Sample</th><th>Type</th><th>Num (#)</th><th>Repeat unit (bp)</th><th>Total length (bp)</th><th>Cover (%</th></tr>\n
				\t\t\t\t</thead>\n
				\t\t\t\t<tbody>\n";
		open TRF,"$inputdir/$sample\_RepeatMasker/$sample\.trf.txt" or die $!;
		while(<TRF>){
			chomp;
			next if(/Type/);
			my @arr=split /\t/,$_;
			print HTML"\t\t\t\t\t<tr><td>$sample</td><td>$arr[0]</td><td>$arr[1]</td><td>$arr[2]</td><td>$arr[3]</td><td>$arr[4]</td></tr>\n";
		}
		close TRF;
		print HTML"\t\t\t\t</tbody>\n
				\t\t\t\t</table></div>\n";
	}
	
	if(-e "$inputdir/$sample\_piler-cr/$sample\.pilercr.result"){
		print HTML"\t\t\t\t<h3>CRISPR array</h3>\n
				\t\t\t\t<p>CRISPR array, which comprises alternating conserved repeats and spacers, is a special structure in prokaryotic genome. It can be detected with PILER-CR [BMC Bioinformatics, 2007] by recognizing the pattern of CRISPR array. The detail of CRISPR arrays are shown below:</p>\n
				\t\t\t\t<p align=\"center\"><b>TABLE:</b> CRISPR arrays.</p>\n
				\t\t\t\t<div class=\"wy-table-responsive\"><table class=\"docutils\" border=\"1\">\n
				\t\t\t\t<thead>\n
				\t\t\t\t\t<tr><th>Sample</th><th>ID</th><th>Contig/Scaffold</th><th>Position</th><th>Length (bp)</th><th>Copies (#)</th><th>Repeat length (bp)</th><th>Spacer length (bp)</th><th>Strand</th><th>Consensus sequence of repeat</th></tr>\n
				\t\t\t\t</thead>\n
				\t\t\t\t<tbody>\n";
		open PILER,"$inputdir/$sample\_piler-cr/$sample\.pilercr.result" or die $!;
		while(<PILER>){
			chomp;
			next if(/ID/);
			my @arr=split /\t/,$_;
			print HTML"\t\t\t\t\t<tr><td>$sample</td><td>$arr[0]</td><td>$arr[1]</td><td>$arr[2]</td><td>$arr[3]</td><td>$arr[4]</td><td>$arr[5]</td><td>$arr[6]</td><td>$arr[7]</td><td>$arr[8]</td></tr>\n";
		}
		close PILER;
		print  HTML"\t\t\t\t</tbody>\n
				\t\t\t\t</table></div>\n";
	}
	if( -e "$inputdir/$sample\.gene.xls"){
		print HTML"\t\t\t\t<h3>Coding gene</h3>\n
				\t\t\t\t<p>Coding genes take a large proportion in prokaryotic genome. Compared with eukaryotic genome, the average length of intergenic regions is shorter and there is no intron sequence in prokaryotic gene. Coding genes are predicted with Prodigal [BMC Bioinformatics, 2010]. Statistics is shown below:</p>\n
				\t\t\t\t<p align=\"center\"><b>TABLE:</b> Gene prediction statistics.</p>\n
				\t\t\t\t<div class=\"wy-table-responsive\"><table class=\"docutils\" border=\"1\">\n
				\t\t\t\t<thead>\n
				\t\t\t\t\t<tr><th>Sample</th><th>Genome Size (Kbp)</th><th>Num (#)</th><th>Num of genes (#)</th><th>Total length (Kbp)</th><th>Cover (%)</th><th>Average Length (bp)</th><th>Average intergenic (bp)</th><th>partial gene ratio (%)</th></tr>\n
				\t\t\t\t</thead>\n
				\t\t\t\t<tbody>\n";
		open GENE,"$inputdir/$sample\.gene.xls" or die $!;
		while(<GENE>){
			chomp;
			next if(/Sample/);
			my @arr=split /\t/,$_;
			print HTML"\t\t\t\t\t<tr><td>$sample</td><td>$arr[1]</td><td>$arr[2]</td><td>$arr[3]</td><td>$arr[4]</td><td>$arr[5]</td><td>$arr[6]</td><td>$arr[7]</td><td>$arr[8]</td></tr>\n";
		}
	}
	if( -e "$inputdir/$sample\.gene.png"){
		print  HTML"\t\t\t\t</tbody>\n
				\t\t\t\t</table></div>\n
				\t\t\t\t<div align=\"center\"><img src=../$sample\.gene.png></img></div>\n
				\t\t\t\t<p align=\"center\"><b>FIGURE:</b> Gene length distribution.</p>\n"
	}
	print HTML"\t\t\t</div>\n";
}

if(-e "$inputdir/$sample\_tables/ratio.txt"){
	print HTML"\t\t\t<HR>\n
			\t\t\t<div id=\"\" class=\"section\">\n
			\t\t\t\t<h1><center>Gene annotation summary</center></h1>\n
			\t\t\t\t<p>Gene function annotation is performed by align gene sequences to serveral databases. The alignment result of highest similarity is chosen as annotation result. The summary of annotation result is shown below:</p>\n
			\t\t\t\t<div class=\"wy-table-responsive\"><table class=\"docutils\" border=\"1\">\n
			\t\t\t\t<thead>\n
			\t\t\t\t\t<tbody>\n";
	print HEAD"\t\t\t<li><a href=\"#annotation\">Gene annotation</a></li>\n";
			
	open RATIO,"$inputdir/$sample\_tables/ratio.txt" or die $!;
	my ($seq1,$seq2);
	my $total;
	while(<RATIO>){
		chomp;
		my @arr=split /\t/,$_;
		if(/Total/){
			$seq1.="</th><th>Num of genes (#)";
			$seq2.="</td><td>$arr[1]";
			$total=$arr[1];
		}
		if(/NR/){
			$seq1.="</th><th>NR";
			my $ra=sprintf "%.2f",($arr[1]/$total*100);
			$seq2.="</td><td>$arr[1]($ra%)";
		}
		if(/KEGG/){
			$seq1.="</th><th>KEGG";
			my $ra=sprintf "%.2f",($arr[1]/$total*100);
			$seq2.="</td><td>$arr[1]($ra%)";
		}
		if(/COG/){
			$seq1.="</th><th>COG";
			my $ra=sprintf "%.2f",($arr[1]/$total*100);
			$seq2.="</td><td>$arr[1]($ra%)";
		}
		if(/Pfam/){
			$seq1.="</th><th>Pfam";
			my $ra=sprintf "%.2f",($arr[1]/$total*100);
			$seq2.="</td><td>$arr[1]($ra%)";
		}
		if(/CAZy/){
			$seq1.="</th><th>CAZy";
			my $ra=sprintf "%.2f",($arr[1]/$total*100);
			$seq2.="</td><td>$arr[1]($ra%)";
		}
		if(/MetaCyc/){
			$seq1.="</th><th>MetaCyc";
			my $ra=sprintf "%.2f",($arr[1]/$total*100);
			$seq2.="</td><td>$arr[1]($ra%)";	
		}
		if(/SwissProt/){
			$seq1.="</th><th>SwissProt";
			my $ra=sprintf "%.2f",($arr[1]/$total*100);
			$seq2.="</td><td>$arr[1]($ra%)";	
		}
		if(/PHI/){
			$seq1.="</th><th>PHI";
			my $ra=sprintf "%.2f",($arr[1]/$total*100);
			$seq2.="</td><td>$arr[1]($ra%)";	
		}
		if(/CARD/){
			$seq1.="</th><th>CARD";
			my $ra=sprintf "%.2f",($arr[1]/$total*100);
			$seq2.="</td><td>$arr[1]($ra%)";	
		}
	}
	close RATIO;
	print HTML"\t\t\t\t\t<tr><th>Sample$seq1</th></tr>\n";
	print HTML"\t\t\t\t</thead>\n
				\t\t\t\t<tbody>\n
				\t\t\t\t\t<tr><td>$sample$seq2</td></tr>\n
				\t\t\t\t</tbody>\n
				\t\t\t\t</table></div>\n";
}

if(( -e "$inputdir/$sample\_figure/CARD.png") || ( -e "$inputdir/$sample\_figure/KEGG.png") || ( -e "$inputdir/$sample\_figure/COG.png")){
	print HTML"\t\t\t\t<p>All the detailed annotation result can be see <a href=\"../$sample\_htmls/function_annotation.html\">here.</a></p>\n";
	if( -e "$inputdir/$sample\_figure/KEGG.png"){
		print HTML"\t\t\t\t<h3>KEGG</h3>\n
				\t\t\t\t<p>Genes are annotated with KEGG protein ID. And then, genes with entry can be mapped to the KO entry and then mapped to KEGG pathway. Detail information of KEGG database can be see <a href=\"https://www.kegg.jp/\">here</a>. The number of genes in each category is shown below: </p>\n
				\t\t\t\t<div align=\"center\"><img src=../$sample\_figure/KEGG.png></img></div>\n
				\t\t\t\t<p align=\"center\"><b>FIGURE:</b> KEGG annotation.</p>\n";
	}
	
	if( -e "$inputdir/$sample\_figure/COG.png"){
		print HTML"\t\t\t\t<h3>COG</h3>\n
				\t\t\t\t<p>Genes are annotated with COG protein ID. And then, genes with entry can be mapped to the 26 COG categories and 4 clusters. Detail information of COG database can be see <a href=\"https://www.ncbi.nlm.nih.gov/COG/\">here</a>. The number of genes in each category is shown below: </p>\n
				\t\t\t\t<div align=\"center\"><img src=../$sample\_figure/COG.png></img></div>\n
				\t\t\t\t<p align=\"center\"><b>FIGURE:</b> COG annotation.</p>\n";
	}
	
	if( -e "$inputdir/$sample\_figure/CARD.png"){
		print HTML"\t\t\t\t<h3>CARD</h3>\n
				\t\t\t\t<p>Genes are annotated with CARD protein ID. And then, gene with entry can be group by Drug Class, Resistance Mechanism and AMR gene family. Detail information of CARD database can be see <a href=\"https://card.mcmaster.ca/\">here</a>. The number of genes in each category is shown below: </p>\n
				\t\t\t\t<div align=\"center\"><img src=../$sample\_figure/CARD.png></img></div>\n
				\t\t\t\t<p align=\"center\"><b>FIGURE:</b> CARD annotation.</p>\n";
	}
}
print HTML"\t\t\t</div>\n
		\t\t</div>\n
		\t</div>\n
		</div>\n</body>\n</html>\n";
	
print HEAD"\t\t<HR>\n\t\t</ul>\n\t</div>\n";
