###perl html.pl /path/to/assembly_outputdir > **.html
$dir=$ARGV[0];
opendir (DIR, $dir) or die "can't open the directory!";
@pathlist=readdir DIR;
foreach my $file (@pathlist) {
    if (($file =~ /fasta/) && ($file !~ /16s/)){
        @tmp=split(/.fasta/,$file);
        $sample_name=$tmp[0];
    }
    if ($file =~ /genome_info/){
        $genome_info=$file;
    }
    if ($file =~ /reads_info/){
        push @reads_info,$file;
    }
}
open (FINA,"$dir/$genome_info");
for (1..1){$line=<FINA>}
while ($line=<FINA>){
    chomp $line;
    @arr=split(/\t/,$line);
    $scaf_num=$arr[1];
    $N50=$arr[2];
    $N75=$arr[3];
    $largest_scaf=$arr[4];
    $total_len=$arr[5];
    $GC=$arr[6];
    $N=$arr[7];
}
print "<!doctype html>","\n";
print "<html lang=\"zh-CN\">","\n";
print "<head>","\n";
print "	<meta charset=\"utf-8\">","\n";
print "	<meta name=\"renderer\" content=\"webkit|ie-comp|ie-stand\">","\n";
print "	<meta http-equiv=\"X-UA-Compatible\" content=\"IE=Edge,chrome=1\">","\n";
print "	<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, user-scalable=no\">","\n";
print "	<title>Report</title>","\n";
print "	<style type=\"text\/css\" rel=\"stylesheet\">","\n";
print "	html,body,tbody,tr,td{margin:0;padding:0;font-size: 14px;}","\n";
print "	table {border-collapse: collapse;border-spacing: 0;}","\n";
print "	.maintbody{width:1000px;margin:50px auto;}","\n";
print "	.maintbody table{width:100%;border: 1px solid #efefef;}","\n";
print "	.maintbody tbody tr td{font-family: \"Arial\",\"Helvetica\",sans-serif;padding:10px 15px;border-right: 1px solid #efefef;border-bottom: 1px solid #efefef;}","\n";
print "	.maintbody tbody tr td.tdsplist{width: 850px;line-height:20px;display: block;word-wrap: break-word; border-right: none;}","\n";
print "	.maintbody tbody tr td.tdlast{border-bottom: none;}","\n";
print "	</style>","\n";
print "</head>","\n";
print "<body>","\n";
print "<div class=\"maintbody\">","\n";
print "	<div><b>Pipeline overview:</b></div><br><br>","\n\n";
print "	<div>WDCM pipeline is composed of <b>THREE</b> bioinformatics analysis procedure: <b>(1) raw reads trimming and assembly, (2) genomic component analysis and (3) gene annotation.</b></div><br><br>","\n";
print "	<div><b>(1.1)</b>&emsp;If long reads (PacBio reads, Nanopore reads or Illumina TruSeq reads) is provided as input, raw sequencing reads are trimmed and assembled into contigs/scaffolds with Canu [Genome research, 2017] or Flye [Nature Biotechnology, 2019]. If NGS short reads is provided additionally, NGS short reads will be used to polish contigs/scaffolds with pilon [PLoS One, 2014].</div><br><br>","\n";
print "	<div><b>(1.2)</b>&emsp;If NGS short reads are provided only, raw reads are trimmed into clean reads with sickle or Trimmomatic [Bioinformatics, 2014], corrected with Musket [Bioinformatics, 2012], and assembled into contigs/scaffolds with multiple assembler (SOAPdenovo2 [Gigascience, 2012], SPAdes [Journal of computational biology, 2012], Velvet [Genome research, 2008] and Platanus [Genome research, 2014]). Then, best assembly result is obtained based on pair-wise alignment among the contigs/scaffolds from different assembler. After that, reads are mapped to the best assembly result to check misassembly and count reads coverage.</div><br><br>","\n";
print "	<div><b>(1.3)</b>&emsp;The final assembly result is used to estimate genome completeness and containation with checkM [Genome research, 2015] and to perform further genomic component analysis.</div><br><br>","\n";
print "	<div><b>(2)</b>&emsp;Genomic component analysis including CRISPR recognition with PILER-CR [BMC Bioinformatics, 2007] and CRT [BMC bioinformatics, 2007], repetitive structure detection with RepeatMasker, RNA prediction with tRNAscan-SE [Nucleic acids research, 2016] and RNAmmer [Nucleic acids research, 2007], and gene prediction with Prodigal [BMC Bioinformatics, 2010]. After that, predicted 16S rRNA sequences are aligned to WDCM type strain 16S rRNA database and best alignment result will be reported.</div><br><br>","\n";
print "	<div><b>(3)</b>&emsp;Predicted gene are annotated by several databases including KEGG, GO, COG, NR, Swiss-Prot, AntiSMASH, MetaCyc, PHI, Pfam, CARD and VFDB.</div><br><br>","\n";
print "	<div><b>Section 1: Trimming and assembly.</b></div><br><br>","\n";
print " <div align=\"center\"><b>Assembly Statistics</b></div>","\n";
print " <table>","\n";
print "         <tbody>","\n";
print "                 <tr>","\n";
print "                         <td>Sample Name (#)</td>","\n";
print "                         <td>Scaffold Number (#)</td>","\n";
print "                         <td>Genome Size (bp)</td>","\n";
print "                         <td>N50 (bp)</td>","\n";
print "                         <td>N75 (bp)</td>","\n";
print "                 </tr>","\n";
print "                 <tr>","\n";
print "                         <td>$sample_name</td>","\n";
print "                         <td>$scaf_num</td>","\n";
print "                         <td>$total_len</td>","\n";
print "                         <td>$N50</td>","\n";
print "                         <td>$N75</td>","\n";
print "                 </tr>","\n";
print " </table>","\n";
print " <br />","\n";

print "	<br><div>In order to obtain more accurate result, adapters, PCR primers and low-quality bases, which affect downstream analysis, are trimmed with reads trimming software. Library information, sequencing reads statistics and trimming result is shown in the following table:</div><br>","\n";
$num=scalar(@reads_info);
for ($i=0;$i<$num;$i++){
    open (FINB,"$dir/reads_info_${i}.txt");
    while ($line=<FINB>){
        chomp $line;
        if ($line =~ /^Read/) {
            @tmp=split(/:/,$line);
            $read_len=$tmp[1];
        }
        if ($line =~ /^Insert/) {
            @tmp=split(/:/,$line);
            $insert_size=$tmp[1];
        }
        if ($line =~ /^Input/) {
            @tmp=split(/:/,$line);
            $total_reads=$tmp[1];
        }
        if ($line =~ /^Dropped/) {
            @tmp=split(/:/,$line);
            $filter_ratio=$tmp[1];
        }
        if ($line =~ /^Raw/) {
            @tmp=split(/:/,$line);
            $raw_size=$tmp[1];
        }
        if ($line =~ /^Clean/) {
            @tmp=split(/:/,$line);
            $clean_size=$tmp[1];
        } 
    }
    $l=$i+1;
    print "	<div class align=\"center\"><b>Illumina Statistics (library $l)</b></div>","\n";
    print "	<table>","\n";
    print "		<tbody>","\n";
    print "			<tr>","\n";
    print "				<td>Sample Name (#)</td>","\n";
    print "				<td>Insert Size (bp)</td>","\n";
    print "				<td>Reads Length (bp)</td>","\n";
    print "				<td>Total Reads (#)</td>","\n";
    print "				<td>Filtered Reads (%)</td>","\n";
    print "				<td>Raw Data Size</td>","\n";
    print "				<td>Clean Data Size</td>","\n";
    print "			</tr>","\n";
    print "			<tr>","\n";
    print "				<td>$sample_name</td>","\n";
    print "				<td>$insert_size</td>","\n";
    print "				<td>$read_len</td>","\n";
    print "				<td>$total_reads</td>","\n";
    print "				<td>$filter_ratio</td>","\n";
    print "				<td>$raw_size</td>","\n";
    print "				<td>$clean_size</td>","\n";
    print "			</tr>","\n";
    print "	</table>","\n";
    print "	<br />","\n";
}

print "	<br><div>Before assembly, kmer histogram is used estimated genome contamination, heterozygosis and duplication roughly. The result is shown in the following figure:</div><br>","\n";
for ($i=0;$i<$num;$i++){
    $l=$i+1;
    print "	<div align=\"center\"><img src=\"${sample_name}_${i}_kmer_freq.png\"/></div>","\n";
    print "	<div class align=\"center\"><b>17-mer analysis on sample (library $l)</b></div>","\n";
    print "	<br />","\n";
}

print "	<br><div>Assembly process are performed based on cleaned reads which generated in the previous step. The result of genome assembly statistics is shown in the following table and figure:</div><br>","\n";
print "	<table>","\n";
print "		<tbody>","\n";
print "			<tr>","\n";
print "				<td>Sample Name (#)</td>","\n";
print "				<td>Seq Type (#)</td>","\n";
print "				<td>Scaffold Number (#)</td>","\n";
print "				<td>Genome Size (bp)</td>","\n";
print "				<td>N50 Length (bp)</td>","\n";
print "				<td>N75 Length (bp)</td>","\n";
print "				<td>Max Length</td>","\n";
print "				<td>N’s Number</td>","\n";
print "				<td>GC Content (%)</td>","\n";
print "			</tr>","\n";
print "			<tr>","\n";
print "				<td>$sample_name</td>","\n";
print "				<td>Scaffold</td>","\n";
print "				<td>$scaf_num</td>","\n";
print "				<td>$total_len</td>","\n";
print "				<td>$N50</td>","\n";
print "				<td>$N75</td>","\n";
print "				<td>$largest_scaf</td>","\n";
print "				<td>$N</td>","\n";
print "				<td>$GC</td>","\n";
print "			</tr>","\n";
print "	</table>","\n";
print "	<br />","\n";

for ($i=0;$i<$num;$i++){
    $l=$i+1;
    print "	<div align=\"center\"><img src=\"${sample_name}_${i}_gc_cov.png\"/></div>","\n";
    print "	<div class align=\"center\"><b> GC content and Depth correlative analysis (library $l)</b></div>","\n";
    print "	<br />","\n";
}

