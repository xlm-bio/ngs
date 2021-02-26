###sh gcm_tgs_assembly.sh -inputFile /path/to/tgs_reads -tempDir  -outputDir  -genomeSize -Instrument -threads 30 -sampleName xxx
while true; do
	case "$1" in
			-tempDir) tempDir=$2; shift 2;;
			-outputDir) outputDir=$2; shift 2;;
			-inputFile) inputFile=$2; shift 2;;
			-Instrument) Instrument=$2; shift 2;;
			-genomeSize) genomeSize=$2; shift 2;;
			-sampleName) sampleName=$2; shift 2;;
			-threads) threads=$2; shift 2;;
			*) break;
	esac
done

if [[ -z $sampleName ]]
then
        Prefix="default"
else
        Prefix=${sampleName}
fi

perlDir="/data/pipeline/pipeline1/perl" ###修正
RDir="/data/pipeline/pipeline1/R" ###修正
#########################################################################################################
#Canu是Celera的继任者，能用于组装PacBio和Nanopore两家公司得到的测序结果                                 #
#Canu分为三个步骤，纠错，修整和组装，每一步都差不多是如下几个步骤：                                     #
#加载read到read数据库，gkpStore;对k-mer进行技术，用于计算序列间的overlap;计算overlap;                   #
#加载overlap到overlap数据库，OvlStore;根据read和overlap完成特定分析目标;                                #
#read纠错时会从overlap中挑选一致性序列替换原始的噪声read;read修整时会使用overlap确定read哪些区域是高质量#
#区域，哪些区域质量较低需要修整。最后保留单个最高质量的序列块;                                          #
#序列组装时根据一致的overlap对序列进行编排(layout), 最后得到contig。                                    #
#########################################################################################################

	mkdir $tempDir/canu
	if [[ $Instrument == "pacbio" ]]
	then
		/data/public_tools/canu/bin/canu -d $tempDir/canu -p $Prefix genomeSize=${genomeSize} maxThreads=${threads} -pacbio-raw $inputFile  useGrid=0 
	elif [[ $Instrument == "nanopore" ]]
	then
		/data/public_tools/canu/bin/canu -d $tempDir/canu -p $Prefix genomeSize=${genomeSize} maxThreads=${threads} -nanopore-raw $inputFile useGrid=0
	fi
	perl $perlDir/readStat.pl $inputFile >$outputDir/reads_info.txt
	if [[ -s $tempDir/canu/${Prefix}.contigs.fasta ]]
	then
		echo "canu already done!" >> $tempDir/log.txt
	else
		echo "canu error!" >> $tempDir/log.txt
#		exit
	fi
	mkdir $tempDir/canu_pro
	if [[ $Instrument == "pacbio" ]]
	then
		 /data/public_tools/canu/bin/canu -d $tempDir/canu_pro -p $Prefix genomeSize=${genomeSize} maxThreads=${threads} -pacbio-raw $inputFile  useGrid=0 corMhapSensitivity=high corMinCoverage=0 corOutCoverage=100 minReadLength=15000 minOverlapLength=1000
	elif [[ $Instrument == "nanopore" ]]
	then
		/data/public_tools/canu/bin/canu -d $tempDir/canu_pro -p $Prefix genomeSize=${genomeSize} maxThreads=${threads} -nanopore-raw $inputFile useGrid=0 corMhapSensitivity=high corMinCoverage=0 corOutCoverage=100 minReadLength=15000 minOverlapLength=1000
	fi
	if [[ -s $tempDir/canu_pro/${Prefix}.contigs.fasta ]]
	then
		echo "canu_pro already done!" >> $tempDir/log.txt
	else
		echo "canu_pro error!" >> $tempDir/log.txt
	fi
	mkdir -p $tempDir/fasta
	cp $tempDir/canu/${Prefix}.contigs.fasta $tempDir/fasta/canu.fasta
	cp $tempDir/canu_pro/${Prefix}.contigs.fasta $tempDir/fasta/canu_pro.fasta
	#perl $perlDir/make_table.pl $outputDir/ > $outputDir/genome_info.txt
	#awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' $inputFile | sort -n >  $tempDir/read_length.txt
	#/data/public_tools/R/bin/Rscript $RDir/read_length.R inputfile=$tempDir/read_length.txt outputfile=$outputDir/read_length.png

	mkdir $tempDir/flye
	if [[ $Instrument == "pacbio" ]]
	then
		/data/public_tools/flye/bin/flye --pacbio-raw $inputFile --out-dir $tempDir/flye --threads $threads --genome-size ${genomeSize}
	elif [[ $Instrument == "nanopore" ]]
	then
		/data/public_tools/flye/bin/flye --nano-raw  $inputFile --out-dir $tempDir/flye --threads $threads --genome-size ${genomeSize}
	fi
	if [[ -s $tempDir/flye/assembly.fasta ]]
	then
		echo "flye already done!" >> $tempDir/log.txt
		cp $tempDir/flye/assembly.fasta $tempDir/fasta/flye.fasta
	else
		echo "flye error!" >> $tempDir/log.txt
#		exit
	fi
	perl $perlDir/make_table.pl $tempDir/fasta > $tempDir/all_genome.txt
	best=`awk 'BEGIN {max = 0} {if ($3+0 > max+0) {max=$3 ;content=$1} } END {print content}' $tempDir/all_genome.txt`
	cp $tempDir/fasta/$best $outputDir/${Prefix}.fasta
	perl $perlDir/make_table.pl $outputDir/ > $outputDir/genome_info.txt
	awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' $inputFile | sort -n >  $tempDir/read_length.txt
	/data/public_tools/R/bin/Rscript $RDir/read_length.R inputfile=$tempDir/read_length.txt outputfile=$outputDir/read_length.png
	ty=`echo "$best" |sed 's#\.fasta##g'`
	echo "Assember and parameters">>$outputDir/best_par.txt
	echo "$ty" >>$outputDir/best_par.txt
	perl $perlDir/scaffold_info_TGS.pl -type $ty -tempdir $tempDir/ -outfile $outputDir/scaffold_info.txt
	cover=`grep times $tempDir/canu/${Prefix}.report |head -1 |awk '{print $5}'|sed 's#(##g'`
	echo "coverage	$cover">$outputDir/coverage.txt
