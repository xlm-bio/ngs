##sh /data/shell/gcm_ngs_tgs_assembly.sh -configFile -tempDir -outputDir= -Instrument pacbio|nanopore -genomeSize -threads 30 -sampleName xxx
###configfie_format
#[NGS]
##***_1.fq,**_2.fq
#[TGS]
##***.fq
while true; do
	case "$1" in
			-trimProgram) trimProgram=$2; shift 2;;
			-tempDir) tempDir=$2; shift 2;;
			-outputDir) outputDir=$2; shift 2;;
			-configFile) configFile=$2; shift 2;;
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

perlDir="/data/pipeline/pipeline1/perl"
RDir="/data/pipeline/pipeline1/R"
###读取configfile
while read line
do
        if [[ $line =~ \[NGS\] ]]
        then
                reads=2
        elif [[ $reads == 2 ]]
        then
                OLD_IFS="$IFS"
                IFS=","
                tmp=($line)
                IFS="$OLD_IFS"
                pe1=${tmp[0]}
                pe2=${tmp[1]}
                reads=0
        elif [[ $line =~ \[TGS\] ]]
        then
                reads=3
        elif [[ $reads == 3 ]]
        then
                third=${line}
        fi
done < $configFile

##########estimate_sequencing_quailty_value
qual=`sh /data/pipeline/pipeline1/shell/fq_qual_type.sh $pe1`
if [[ -f $tempDir/log.txt ]]
then
	rm $tempDir/log.txt
fi
if [[ $qual == "phred33" ]]
then
	platform="sanger"
elif [[ $qual == "phred64" ]]
then
	platform="illumina"
elif [[ $qual == "solexa64" ]]
then
	platform="solexa"
fi

###trim
perl $perlDir/readStat.pl $third >$outputDir/reads_info.txt 
mkdir $tempDir/trim
if [[ $trimProgram == "sickle" ]]
then
	/data/public_tools/sickle/sickle/sickle pe -f $pe1 -r $pe2 -o $tempDir/trim/trim_1.fastq -p $tempDir/trim/trim_2.fastq -s $tempDir/trim/single.fastq -t $platform > $tempDir/trim/sickle.log
	if [[ -s $tempDir/trim/trim_1.fastq ]] && [[ -s $tempDir/trim/trim_2.fastq ]]
	then
		echo "sickle already done!" >> $tempDir/log.txt
	else 
		echo "sicke error!" >> $tempDir/log.txt
		exit
	fi
	read_length_tmp=`perl $perlDir/read_length.pl $tempDir/trim/trim_1.fastq`
	read_length=`echo $read_length_tmp | awk '{print int($0)}'`
	total=`grep Total $tempDir/trim/sickle.log |awk '{print $5}'`
	total1=`expr $total / 2`
	keep=`grep kept $tempDir/trim/sickle.log |grep paired|awk '{print $5}'`
	rm_ra=$(printf "%.2f" `echo "scale=2;($total-$keep)/$total*100"|bc`)
	if [[ ${pe1[${i}]} =~ .+fastq$ ]] || [[ ${pe1[${i}]} =~ .+fq$ ]]
	then
		Raw_Reads_Size=`du -h --block-size=M ${pe1[${i}]} | awk '{print $1}'`
	elif [[ ${pe1[${i}]} =~ .+gz$ ]]
	then
		gunzip -c ${pe1[${i}]} > $tempDir/tmp.fastq
		Raw_Reads_Size=`du -h --block-size=M $tempDir/tmp.fastq| awk '{print $1}'`
	fi
	Clean_Reads_Size=`du -h --block-size=M $tempDir/trim/trim_1.fastq | awk '{print $1}'`
	echo "Short reads	$read_length	$total1	$rm_ra	$Raw_Reads_Size	$Clean_Reads_Size">>$outputDir/reads_info.txt
elif [[ $trimProgram == "trimmomatic" ]]
then	
	/data/public_tools/trimmomatic/bin/trimmomatic PE -threads $threads -summary $tempDir/trim/summary.txt $pe1 $pe2 $tempDir/trim/trim_1.fastq $tempDir/trim/forward_unpaired.fastq $tempDir/trim/trim_2.fastq $tempDir/trim/reverse_unpaired.fastq ILLUMINACLIP:/data/public_tools/trimmomatic/share/trimmomatic-0.38-1/adapters/TruSeq3-PE.fa:2:30:10 SLIDINGWINDOW:5:20 MINLEN:20
	rm $tempDir/trim/forward_unpaired.fastq $tempDir/trim/reverse_unpaired.fastq
	if [[ -s $tempDir/trim/trim_1.fastq ]] && [[ -s $tempDir/trim/trim_2.fastq ]]
	then
		echo "trimmomatic already done!" >> $tempDir/log.txt
	else 
		echo "trimmomatic error!" >> $tempDir/log.txt
		exit
	fi
		if [[ ${pe1[${i}]} =~ .+fastq$ ]] || [[ ${pe1[${i}]} =~ .+fq$ ]]
	then
		Raw_Reads_Size=`du -h --block-size=M ${pe1[${i}]} | awk '{print $1}'`
	elif [[ ${pe1[${i}]} =~ .+gz$ ]]
	then
		gunzip -c ${pe1[${i}]} > $tempDir/tmp.fastq
		Raw_Reads_Size=`du -h --block-size=M $tempDir/tmp.fastq| awk '{print $1}'`
	fi
	read_length_tmp=`perl $perlDir/read_length.pl $tempDir/trim/trim_1.fastq`
	read_length=`echo $read_length_tmp | awk '{print int($0)}'`
	Clean_Reads_Size=`du -h --block-size=M $tempDir/trim/trim_1.fastq | awk '{print $1}'`
	total1=`grep "Input Read Pairs" $tempDir/trim/summary.txt |awk '{print $NF}'`
	rm_ra=`grep "Dropped Read Percent" $tempDir/trim/summary.txt |awk '{print $NF}'`
	echo "Short reads	$read_length	$total1	$rm_ra	$Raw_Reads_Size	$Clean_Reads_Size">>$outputDir/reads_info.txt
fi

#if [[ $assemblyProgram == "canu" ]]
#then

	mkdir $tempDir/canu
	if [[ $Instrument == "pacbio" ]]
	then
		/data/public_tools/canu/bin/canu -d $tempDir/canu -p $Prefix genomeSize=${genomeSize} maxThreads=${threads} -pacbio-raw $third  useGrid=0 
	elif [[ $Instrument == "nanopore" ]]
	then
		/data/public_tools/canu/bin/canu -d $tempDir/canu -p $Prefix genomeSize=${genomeSize} maxThreads=${threads} -nanopore-raw $third useGrid=0
	fi
	if [[ -s $tempDir/canu/${Prefix}.contigs.fasta ]]
	then
		echo "canu already done!" >> $tempDir/log.txt
	else
		echo "canu error!" >> $tempDir/log.txt
		#exit
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

	mkdir $tempDir/fasta
	cp $tempDir/canu/${Prefix}.contigs.fasta $tempDir/fasta/canu.fasta
	cp $tempDir/canu_pro/${Prefix}.contigs.fasta $tempDir/fasta/canu_pro.fasta
#	bwa index $tempDir/canu/${Prefix}.contigs.fasta
#	bwa mem $tempDir/canu/${Prefix}.contigs.fasta $tempDir/trim/trim_1.fastq $tempDir/trim/trim_2.fastq -t $threads | samtools view  -b -S -o  $tempDir/canu/${Prefix}.bam
#	samtools sort $tempDir/canu/${Prefix}.bam -o $tempDir/canu/${Prefix}_sorted.bam
#	samtools index $tempDir/canu/${Prefix}_sorted.bam
#	if [[ -s $tempDir/canu/${Prefix}_sorted.bam ]]
#	then
#		echo "alignment already done!" >> $tempDir/log.txt
#	else
#		echo "alignment error!" >> $tempDir/log.txt
#		exit
#	fi
#	mkdir $tempDir/pilon/

#	/data/public_tools/pilon/bin/java -Xmx16G -jar /data/public_tools/pilon/pilon-1.23.jar --genome $tempDir/canu/${Prefix}.contigs.fasta --frags $tempDir/canu/${Prefix}_sorted.bam --outdir $tempDir/pilon --output ${Prefix} --changes --fix all > $tempDir/pilon/${Prefix}.log
#	if [[ -s $tempDir/pilon/${Prefix}.fasta ]]
#	then
#		echo "pilon already done!" >> $tempDir/log.txt
#	else
#		echo "pilon error!" >> $tempDir/log.txt
#		exit
#	fi
#
#	cp $tempDir/pilon/${Prefix}.fasta $outputDir
#	perl $perlDir/make_table.pl $outputDir/ > $outputDir/genome_info.txt
#	awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' $third | sort -n >  $tempDir/read_length.txt
#	/data/public_tools/R/bin/Rscript $RDir/read_length.R inputfile=$tempDir/read_length.txt outputfile=$outputDir/read_length.png
#	grep "Corrected" $tempDir/pilon/${Prefix}.log > $tempDir/polish.log
#	while read line2
#	do
#			tmp1_snps=${line2#*Corrected}
#			tmp2_snps=${tmp1_snps%%snps*}
#			snp=$((snp+tmp2_snps))
#			tmp1_abi=${tmp1_snps#*;}
#			tmp2_abi=${tmp1_abi%%ambiguous*}
#			abi=$((abi+tmp2_abi))
#			tmp1_in=${tmp1_abi#*corrected}
#			tmp2_in=${tmp1_in%%small insertions*}
#			in=$((in+tmp2_in))
#			tmp1_in_base=${tmp1_in#*totaling}
#			tmp2_in_base=${tmp1_in_base%%bases*}
#			in_base=$((in_base+tmp2_in_base))
#			tmp1_del=${tmp1_in_base#*,}
#			tmp2_del=${tmp1_del%%small deletions*}
#			del=$((del+tmp2_del))
#			tmp1_del_base=${tmp1_del#*totaling}
#			tmp2_del_base=${tmp1_del_base%%bases*}
#			del_base=$((del_base+tmp2_del_base))
#	done < $tempDir/polish.log
#	echo "Corrected ${snp} snps" > $outputDir/polish.txt
#	echo "Corrected ${abi} ambiguous bases" >> $outputDir/polish.txt
#	echo "Corrected ${in} small insertions totaling ${in_base} bases" >> $outputDir/polish.txt
#	echo "Corrected ${del} small deletions totaling ${del_base} bases" >> $outputDir/polish.txt
#	
#elif [[ $assemblyProgram == "flye" ]]
#then
	mkdir $tempDir/flye
	if [[ $Instrument == "pacbio" ]]
	then
		/data/public_tools/flye/bin/flye --pacbio-raw $third --out-dir $tempDir/flye --threads $threads --genome-size ${genomeSize}
	elif [[ $Instrument == "nanopore" ]]
	then
		/data/public_tools/flye/bin/flye --nano-raw  $third --out-dir $tempDir/flye --threads $threads --genome-size ${genomeSize}
	fi
	if [[ -s $tempDir/flye/assembly.fasta ]]
	then
		echo "flye already done!" >> $tempDir/log.txt
	else
		echo "flye error!" >> $tempDir/log.txt
#		exit
	fi
	cp $tempDir/flye/assembly.fasta $tempDir/fasta/flye.fasta
	perl $perlDir/make_table.pl $tempDir/fasta > $tempDir/all_genome.txt
	best=`awk 'BEGIN {max = 0} {if ($3+0 > max+0) {max=$3 ;content=$1} } END {print content}' $tempDir/all_genome.txt`
#	cp $tempDir/fasta/$best $outputDir/${Prefix}.fasta
	mkdir $tempDir/bwa
	cp $tempDir/fasta/$best $tempDir/bwa/${Prefix}.fasta
	bwa index $tempDir/bwa/${Prefix}.fasta
	bwa mem $tempDir/bwa/${Prefix}.fasta $tempDir/trim/trim_1.fastq $tempDir/trim/trim_2.fastq -t $threads | samtools view  -b -S -o  $tempDir/bwa/${Prefix}.bam
	samtools sort $tempDir/bwa/${Prefix}.bam -o $tempDir/bwa/${Prefix}_sorted.bam
	samtools index $tempDir/bwa/${Prefix}_sorted.bam
#	samtools flagstat $tempDir/bwa/${Prefix}.bam >$outputDir/reads_match.txt
	echo "Assember and parameters">>$outputDir/best_par.txt
	echo "$best" >>$outputDir/best_par.txt
	sed -i 's#.fasta##g' $outputDir/best_par.txt
	ty=`echo "$best" |sed 's#\.fasta##g'`
	if [[ -s $tempDir/bwa/${Prefix}_sorted.bam ]]
	then
		echo "alignment already done!" >> $tempDir/log.txt
	else
		echo "alignment error!" >> $tempDir/log.txt
#		exit
	fi
	mkdir $tempDir/pilon
	/data/public_tools/pilon/bin/java -Xmx16G -jar /data/public_tools/pilon/pilon-1.23.jar --genome $tempDir/bwa/${Prefix}.fasta --frags $tempDir/bwa/${Prefix}_sorted.bam  --outdir $tempDir/pilon --output ${Prefix} --changes --fix all > $tempDir/pilon/${Prefix}.log
	if [[ -s $tempDir/pilon/${Prefix}.fasta ]]
	then
		echo "pilon already done!" >> $tempDir/log.txt
	else
		echo "pilon error!" >> $tempDir/log.txt
	fi
	cp $tempDir/pilon/${Prefix}.fasta $outputDir
	perl $perlDir/make_table.pl $outputDir/ > $outputDir/genome_info.txt
	awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' $third | sort -n >  $tempDir/read_length.txt
	/data/public_tools/R/bin/Rscript $RDir/read_length.R inputfile=$tempDir/read_length.txt outputfile=$outputDir/read_length.png
	grep "Corrected" $tempDir/pilon/${Prefix}.log > $tempDir/polish.log
	while read line2
	do
			tmp1_snps=${line2#*Corrected}
			tmp2_snps=${tmp1_snps%%snps*}
			snp=$((snp+tmp2_snps))
			tmp1_abi=${tmp1_snps#*;}
			tmp2_abi=${tmp1_abi%%ambiguous*}
			abi=$((abi+tmp2_abi))
			tmp1_in=${tmp1_abi#*corrected}
			tmp2_in=${tmp1_in%%small insertions*}
			in=$((in+tmp2_in))
			tmp1_in_base=${tmp1_in#*totaling}
			tmp2_in_base=${tmp1_in_base%%bases*}
			in_base=$((in_base+tmp2_in_base))
			tmp1_del=${tmp1_in_base#*,}
			tmp2_del=${tmp1_del%%small deletions*}
			del=$((del+tmp2_del))
			tmp1_del_base=${tmp1_del#*totaling}
			tmp2_del_base=${tmp1_del_base%%bases*}
			del_base=$((del_base+tmp2_del_base))
	done < $tempDir/polish.log
	echo "Corrected ${snp} snps" > $outputDir/polish.txt
	echo "Corrected ${abi} ambiguous bases" >> $outputDir/polish.txt
	echo "Corrected ${in} small insertions totaling ${in_base} bases" >> $outputDir/polish.txt
	echo "Corrected ${del} small deletions totaling ${del_base} bases" >> $outputDir/polish.txt
#fi	

mkdir $tempDir/alignment
cp $tempDir/pilon/${Prefix}.fasta $tempDir/alignment/
bwa index $tempDir/alignment/${Prefix}.fasta
bwa mem $tempDir/alignment/${Prefix}.fasta $tempDir/trim/trim_1.fastq $tempDir/trim/trim_2.fastq -t $threads | samtools view  -b -S -o  $tempDir/alignment/${Prefix}.bam -
samtools sort $tempDir/alignment/${Prefix}.bam -o $tempDir/alignment/${Prefix}.sorted.bam
/data/public_tools/bedtools/bin/bedtools genomecov -ibam $tempDir/alignment/${Prefix}.sorted.bam -d > $tempDir/alignment/${Prefix}.depth
samtools flagstat $tempDir/alignment/${Prefix}.bam >$outputDir/reads_match.txt
mkdir $tempDir/alignment/${Prefix}_gc_cov
perl $perlDir/batch_cov_gc.pl $tempDir/alignment/${Prefix}.depth $tempDir/alignment/${Prefix}.fasta 500 20 $tempDir/alignment/${Prefix}_gc_cov
/data/public_tools/R/bin/Rscript $RDir/gc_cov.R inputfile=$tempDir/alignment/${Prefix}_gc_cov outputfile=$outputDir/${Prefix}_gc_cov.png

perl $perlDir/scaffold_info_TGS_NGS1.pl -type $ty -tempdir $tempDir/ -depth $tempDir/alignment/${Prefix}.depth -outfile $outputDir/scaffold_info.txt
cover=`grep times $tempDir/canu/${Prefix}.report |head -1 |awk '{print $5}'|sed 's#(##g'`
echo "coverage	$cover">$outputDir/coverage.txt
