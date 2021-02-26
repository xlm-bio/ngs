###sh *.sh -tempdir /path/to/tempdir -outputdir /path/to/outputdir -configfile /path/to/configfile -threads 30

##########configfile_format
##sample1,/path/to/sample1_pe_1,/path/to/sample1_pe_2
##sample2,/path/to/sample2_pe_1,/path/to/sample2_pe_2
##...

while true; do
        case "$1" in		
		-tempdir) tempdir=$2; shift 2;;
		-outputdir) outputdir=$2; shift 2;;
		-configfile) configfile=$2; shift 2;;
		-threads) threads=$2; shift 2;;
		*) break;
	esac
done

##########load_configFile
while read line
do
#	echo $line
	OLD_IFS="$IFS"
	IFS=","
	tmp=($line)
	IFS="$OLD_IFS"
	name=(${name[@]} ${tmp[0]})
#	echo $name
	pe1=(${pe1[@]} ${tmp[1]})
	pe2=(${pe2[@]} ${tmp[2]})
done < $configfile
perlDir="/data/pipeline/pipeline1/perl"
RDir="/data/pipeline/pipeline1/R"

for ((i=0;i<${#name[@]};i++))
do
	file2=${name[${i}]}
	echo $file2
	mkdir $tempdir/$file2
	mkdir $outputdir/$file2
	tempDir=${tempdir}/${file2}
	outputDir=${outputdir}/${file2}
	echo $tempDir	$outputDir
	##########calculate_raw_read_size

	if [[ ${pe1[${i}]} =~ .+fastq$ ]] || [[ ${pe1[${i}]} =~ .+fq$ ]]
	then
		Raw_Reads_Size=`du -h --block-size=M ${pe1[${i}]} | awk '{print $1}'`
	elif [[ ${pe1[${i}]} =~ .+gz$ ]]
	then
		gunzip -c ${pe1[${i}]} > $tempDir/tmp.fastq
		Raw_Reads_Size=`du -h --block-size=M $tempDir/tmp.fastq| awk '{print $1}'`
	fi
	
	##########estimate_sequencing_quailty_value
	qual=`sh /home/hxx/shell/fq_qual_type.sh ${pe1[${i}]}`

	if [[ -f $tempDir/log.txt ]]
	then
		rm $tempDir/log.txt
	fi
	if [[ $qual == "phred33" ]]
	then
		Instrument="sanger"
	elif [[ $qual == "phred64" ]]
	then
		Instrument="illumina"
	elif [[ $qual == "solexa64" ]]
	then
		Instrument="solexa"
	fi
	
	if [[ -d $tempDir/fastqc ]]
	then
		rm -rf $tempDir/fastqc
		mkdir $tempDir/fastqc
	else
		mkdir $tempDir/fastqc
	fi
	if [[ -d $tempDir/trim ]]
	then
		rm -rf $tempDir/trim
		mkdir $tempDir/trim
	else
		mkdir $tempDir/trim
	fi
	if [[ -d $tempDir/musket ]]
	then
		rm -rf $tempDir/musket
		mkdir $tempDir/musket
	else
		mkdir $tempDir/musket
	fi
	export PATH="/data/public_tools/fastqc/bin:$PATH"
	fastqc -o $tempDir/fastqc ${pe1[${i}]} ${pe2[${i}]} -t $threads
	fastqc=`ls $tempDir/fastqc`
	if [[ -z $fastqc ]]
	then
		echo "FastQC error!" > $tempDir/log.txt
		#exit#g
	else
		echo "FastQC already done!" >> $tempDir/log.txt
	fi
	##########trimming
	/data/public_tools/trimmomatic/bin/trimmomatic PE -threads $threads -summary $tempDir/trim/summary.txt ${pe1[${i}]} ${pe2[${i}]} $tempDir/trim/trim_1.fastq $tempDir/trim/forward_unpaired.fastq $tempDir/trim/trim_2.fastq $tempDir/trim/reverse_unpaired.fastq ILLUMINACLIP:/data/public_tools/trimmomatic/share/trimmomatic-0.38-1/adapters/TruSeq3-PE.fa:2:30:10 SLIDINGWINDOW:5:20 MINLEN:20
	rm $tempDir/trim/forward_unpaired.fastq $tempDir/trim/reverse_unpaired.fastq
	if [[ -s $tempDir/trim/trim_1.fastq ]]
	then
		echo "trimmomatic already done!" >> $tempDir/log.txt
	else 
		echo "trimmomatic error!" >> $tempDir/log.txt
		#exit#g
	fi		
	##########error_correction
	/data/public_tools/musket/musket-1.1/musket $tempDir/trim/trim_1.fastq $tempDir/trim/trim_2.fastq  -omulti $tempDir/musket/${file2}_corrected -inorder -p $threads
	mv $tempDir/musket/${file2}_corrected.0 $tempDir/musket/${file2}_corrected_1.fastq
	mv $tempDir/musket/${file2}_corrected.1 $tempDir/musket/${file2}_corrected_2.fastq

	##########evaluate_read_length
	read_length_tmp=`perl $perlDir/read_length.pl ${tempDir}/musket/${file2}_corrected_1.fastq`
    	read_length=`echo $read_length_tmp | awk '{print int($0)}'`
	echo $read_length
	
	##########genome_assembly_through_different_assembly_programs
	if [ $read_length -lt 70 ] && [ $read_length -ge 50 ]
	then
		###spades
		mkdir $tempDir/spades
		/data/public_tools/spades/bin/spades.py -1 $tempDir/musket/${file2}_corrected_1.fastq -2 $tempDir/musket/${file2}_corrected_2.fastq -k 21,27,33,39,45 -o $tempDir/spades/K_21_45 --careful --sc -t $threads --disable-gzip-output
		if [[ -s $tempDir/spades/K_21_45/scaffolds.fasta ]]
		then
			echo "spades_K_21_45 already done!" >> $tempDir/log.txt
		else 
			echo "spades_K_21_45 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/spades/bin/spades.py -1 $tempDir/musket/${file2}_corrected_1.fastq -2 $tempDir/musket/${file2}_corrected_2.fastq  -o $tempDir/spades/K_default --careful --sc -t $threads --disable-gzip-output
		if [[ -s $tempDir/spades/K_default/scaffolds.fasta ]]
		then
			echo "spades_K_default already done!" >> $tempDir/log.txt
		else 
			echo "spades_K_default error!" >> $tempDir/log.txt
			#exit#g
		fi
		for dir in $tempDir/spades/*;do cd ${dir} && ls| grep -v "scaffolds.fasta\|spades.log"|xargs rm -rf && cd ..;done

		insert_length_tmp=`grep "Insert size" $tempDir/spades/K_default/spades.log |awk '{print $13}'`
		insert_length=`echo $insert_length_tmp | awk -F ',' '{print $1}'`

		###soapdenovo
		mkdir $tempDir/soapdenovo
		##配置configfile
		echo "max_rd_len=${read_length}" > $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "[LIB]" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "avg_ins=${insert_length}" >> $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "reverse_seq=0" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "asm_flags=3" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "rank=1" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "q1=$tempDir/musket/${file2}_corrected_1.fastq" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "q2=$tempDir/musket/${file2}_corrected_2.fastq" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		for k in 21 27 33 39 45
		do
			mkdir $tempDir/soapdenovo/K_${k}
			/data/public_tools/soapdenovo2/bin/SOAPdenovo-127mer all -s $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg  -o $tempDir/soapdenovo/K_${k}/K_${k} -K ${k} -R -d 1 -M 1 -D 1 -p $threads -F 
			/data/public_tools/gapcloser/bin/GapCloser -b $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg -a $tempDir/soapdenovo/K_${k}/K_${k}.scafSeq -o $tempDir/soapdenovo/K_${k}/K_${k}_fillgap.fasta
			if [[ -s $tempDir/soapdenovo/K_${k}/K_${k}_fillgap.fasta ]]
			then
				echo "soapdenovo_K_${k} already done!" >> $tempDir/log.txt
			else 
				echo "soapdenovo_K_${k} error!" >> $tempDir/log.txt
				#exit#g
			fi
		done
		mkdir $tempDir/soapdenovo/K_default
		/data/public_tools/soapdenovo2/bin/SOAPdenovo-127mer all -s $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg  -o $tempDir/soapdenovo/K_default/K_default -R -d 1 -M 1 -D 1 -p $threads -F 
		/data/public_tools/gapcloser/bin/GapCloser -b $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg -a $tempDir/soapdenovo/K_default/K_default.scafSeq -o $tempDir/soapdenovo/K_default/K_default_fillgap.fasta
		if [[ -s $tempDir/soapdenovo/K_default/K_default_fillgap.fasta ]]
		then
			echo "soapdenovo_K_default already done!" >> $tempDir/log.txt
		else 
			echo "soapdenovo_K_default error!" >> $tempDir/log.txt
			#exit#g
		fi
		rm -rf $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		for dir in $tempDir/soapdenovo/*;do cd ${dir} && ls| grep -v ".scafSeq\|fillgap.fasta$\|log"|xargs rm -rf && cd ..;done
		
		###velvet
		mkdir $tempDir/velvet
		for k in 21 27 33 39 45
		do
			/data/public_tools/velvet/bin/velveth $tempDir/velvet/auto_${k} ${k} -fastq -shortPaired -separate $tempDir/musket/${file2}_corrected_1.fastq  $tempDir/musket/${file2}_corrected_2.fastq
			/data/public_tools/velvet/bin/velvetg $tempDir/velvet/auto_${k} -cov_cutoff auto -exp_cov auto
			if [[ -s $tempDir/velvet/auto_${k}/contigs.fa ]]
			then
				echo "velvet_K_${k} already done!" >> $tempDir/log.txt
			else 
				echo "velvet_K_${k} error!" >> $tempDir/log.txt
				#exit#g
			fi
		done
		for dir in $tempDir/velvet/*;do cd ${dir} && ls| grep -v "contigs.fa\|Log"|xargs rm -rf && cd ..;done
		
		###idba_UD
		mkdir $tempDir/idba
		/data/public_tools/idba/bin/fq2fa --merge --filter $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq $tempDir/idba/${file2}.fa
		/data/public_tools/idba/bin/idba_ud -r $tempDir/idba/${file2}.fa  --pre_correction  --num_threads $threads  --mink 21 --maxk 45 --step 6 -o $tempDir/idba/21_45_6
		if [[ -s $tempDir/idba/21_45_6/scaffold.fa ]]
		then
			echo "idba_21_45 already done!" >> $tempDir/log.txt
		else 
			echo "idba_21_45 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/idba/bin/idba_ud -r $tempDir/idba/${file2}.fa  --pre_correction  --num_threads $threads   -o $tempDir/idba/default
		if [[ -s $tempDir/idba/default/scaffold.fa ]]
		then
			echo "idba_default already done!" >> $tempDir/log.txt
		else 
			echo "idba_default error!" >> $tempDir/log.txt
			#exit#g
		fi
		rm -r $tempDir/idba/${file2}.fa
		for dir in $tempDir/idba/*;do cd ${dir} && ls| grep -v "scaffold.fa\|log"|xargs rm -rf && cd ..;done
		
		###platanus
		mkdir $tempDir/platanus
		mkdir $tempDir/platanus/K_21_45
		mkdir $tempDir/platanus/K_default
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 assemble -f $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -k 21 -K 0.3 -s 6 -t $threads -o $tempDir/platanus/K_21_45/K_21_45
		/home/hxx/tools/platanus/Platanus_v1.2.4/platanus scaffold -c $tempDir/platanus/K_21_45/K_21_45_contig.fa -b $tempDir/platanus/K_21_45/K_21_45_contigBubble.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_21_45/K_21_45 -t $threads
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 gap_close -c $tempDir/platanus/K_21_45/K_21_45_scaffold.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_default/K_default -t $threads
		if [[ -s $tempDir/platanus/K_21_45/K_21_45_gapClosed_scaffold.fa ]]
		then
			echo "platanus_K_21_45 already done!" >> $tempDir/log.txt
		else 
			echo "platanus_K_21_45 error!" >> $tempDir/log.txt
			#exit#g
		fi 
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 assemble -f $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -t $threads -o $tempDir/platanus/K_default/K_default
		/home/hxx/tools/platanus/Platanus_v1.2.4/platanus scaffold -c $tempDir/platanus/K_default/K_default_contig.fa -b $tempDir/platanus/K_default/K_default_contigBubble.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_default/K_default -t $threads
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 gap_close -c $tempDir/platanus/K_default/K_default_scaffold.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_default/K_default -t $threads
		if [[ -s $tempDir/platanus/K_default/K_default_gapClosed_scaffold.fa ]]
		then
			echo "platanus_K_default already done!" >> $tempDir/log.txt
		else 
			echo "platanus_K_default error!" >> $tempDir/log.txt
			#exit#g
		fi
	elif [ $read_length -lt 100 ] && [ $read_length -ge 70 ]
	then
		###spades
		mkdir $tempDir/spades
		/data/public_tools/spades/bin/spades.py -1 $tempDir/musket/${file2}_corrected_1.fastq -2 $tempDir/musket/${file2}_corrected_2.fastq -k 27,35,43,51,59 -o $tempDir/spades/K_27_59 --careful --sc -t $threads --disable-gzip-output
		if [[ -s $tempDir/spades/K_27_59/scaffolds.fasta ]]
		then
			echo "spades_K_27_59 already done!" >> $tempDir/log.txt
		else 
			echo "spades_K_27_59 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/spades/bin/spades.py -1 $tempDir/musket/${file2}_corrected_1.fastq -2 $tempDir/musket/${file2}_corrected_2.fastq -k 17,27,37,47,57,67 -o $tempDir/spades/K_17_67 --careful --sc -t $threads --disable-gzip-output
		if [[ -s $tempDir/spades/K_17_67/scaffolds.fasta ]]
		then
			echo "spades_K_17_67 already done!" >> $tempDir/log.txt
		else 
			echo "spades_K_17_67 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/spades/bin/spades.py -1 $tempDir/musket/${file2}_corrected_1.fastq -2 $tempDir/musket/${file2}_corrected_2.fastq  -o $tempDir/spades/K_default --careful --sc -t $threads --disable-gzip-output
		if [[ -s $tempDir/spades/K_default/scaffolds.fasta ]]
		then
			echo "spades_K_default already done!" >> $tempDir/log.txt
		else 
			echo "spades_K_default error!" >> $tempDir/log.txt
			#exit#g
		fi
		for dir in $tempDir/spades/*;do cd ${dir} && ls| grep -v "scaffolds.fasta\|spades.log"|xargs rm -rf && cd ..;done
		insert_length_tmp=`grep "Insert size" $tempDir/spades/K_default/spades.log |awk '{print $13}'`
		insert_length=`echo $insert_length_tmp | awk -F ',' '{print $1}'`
		###soapdenovo
		mkdir $tempDir/soapdenovo
		###配置configfile
		echo "max_rd_len=${read_length}" > $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "[LIB]" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "avg_ins=${insert_length}" >> $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "reverse_seq=0" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "asm_flags=3" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "rank=1" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "q1=$tempDir/musket/${file2}_corrected_1.fastq" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "q2=$tempDir/musket/${file2}_corrected_2.fastq" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		for k in 27 37 47 57 67
		do
			mkdir $tempDir/soapdenovo/K_${k}
			/data/public_tools/soapdenovo2/bin/SOAPdenovo-127mer all -s $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg  -o $tempDir/soapdenovo/K_${k}/K_${k} -K ${k} -R -d 1 -M 1 -D 1 -p $threads -F 
			/data/public_tools/gapcloser/bin/GapCloser -b $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg -a $tempDir/soapdenovo/K_${k}/K_${k}.scafSeq -o $tempDir/soapdenovo/K_${k}/K_${k}_fillgap.fasta
			if [[ -s $tempDir/soapdenovo/K_${k}/K_${k}_fillgap.fasta ]]
			then
				echo "soapdenovo_K_${k} already done!" >> $tempDir/log.txt
			else 
				echo "soapdenovo_K_${k} error!" >> $tempDir/log.txt
				#exit#g
			fi
		done
		mkdir $tempDir/soapdenovo/K_default
		/data/public_tools/soapdenovo2/bin/SOAPdenovo-127mer all -s $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg  -o $tempDir/soapdenovo/K_default/K_default -R -d 1 -M 1 -D 1 -p $threads -F 
		/data/public_tools/gapcloser/bin/GapCloser -b $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg -a $tempDir/soapdenovo/K_default/K_default.scafSeq -o $tempDir/soapdenovo/K_default/K_default_fillgap.fasta
		if [[ -s $tempDir/soapdenovo/K_default/K_default_fillgap.fasta ]]
		then
			echo "soapdenovo_K_default already done!" >> $tempDir/log.txt
		else 
			echo "soapdenovo_K_default error!" >> $tempDir/log.txt
			#exit#g
		fi
		rm -rf $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		for dir in $tempDir/soapdenovo/*;do cd ${dir} && ls| grep -v ".scafSeq\|fillgap.fasta$\|log"|xargs rm -rf && cd ..;done

		###velvet
		mkdir $tempDir/velvet
		for k in 27 37 47 57 67
		do
			/data/public_tools/velvet/bin/velveth $tempDir/velvet/auto_${k} ${k} -fastq -shortPaired -separate $tempDir/musket/${file2}_corrected_1.fastq  $tempDir/musket/${file2}_corrected_2.fastq
			/data/public_tools/velvet/bin/velvetg $tempDir/velvet/auto_${k} -cov_cutoff auto -exp_cov auto
			if [[ -s $tempDir/velvet/auto_${k}/contigs.fa ]]
			then
				echo "velvet_K_${k} already done!" >> $tempDir/log.txt
			else 
				echo "velvet_K_${k} error!" >> $tempDir/log.txt
				#exit#g
			fi
		done
		for dir in $tempDir/velvet/*;do cd ${dir} && ls| grep -v "contigs.fa\|Log"|xargs rm -rf && cd ..;done
	
		###idba_UD
		mkdir $tempDir/idba
		/data/public_tools/idba/bin/fq2fa --merge --filter $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq $tempDir/idba/${file2}.fa
		/data/public_tools/idba/bin/idba_ud -r $tempDir/idba/${file2}.fa  --pre_correction  --num_threads $threads  --mink 27 --maxk 59 --step 8 -o $tempDir/idba/27_59_8
		if [[ -s $tempDir/idba/27_59_8/scaffold.fa ]]
		then
			echo "idba_27_59 already done!" >> $tempDir/log.txt
		else 
			echo "idba_27_59 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/idba/bin/idba_ud -r $tempDir/idba/${file2}.fa  --pre_correction  --num_threads $threads  --mink 17 --maxk 67 --step 10 -o $tempDir/idba/17_67_10
		if [[ -s $tempDir/idba/17_67_10/scaffold.fa ]]
		then
			echo "idba_17_67 already done!" >> $tempDir/log.txt
		else 
			echo "idba_17_67 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/idba/bin/idba_ud -r $tempDir/idba/${file2}.fa  --pre_correction  --num_threads $threads   -o $tempDir/idba/default
		if [[ -s $tempDir/idba/default/scaffold.fa ]]
		then
			echo "idba_default already done!" >> $tempDir/log.txt
		else 
			echo "idba_default error!" >> $tempDir/log.txt
			#exit#g
		fi
		rm -rf $tempDir/idba/${file2}.fa
		for dir in $tempDir/idba/*;do cd ${dir} && ls| grep -v "scaffold.fa\|log"|xargs rm -rf && cd ..;done
	
		###platanus
		mkdir $tempDir/platanus
		mkdir $tempDir/platanus/K_27_59
		mkdir $tempDir/platanus/K_17_67
		mkdir $tempDir/platanus/K_default
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 assemble -f $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -k 27 -K 0.4 -s 8 -t $threads -o $tempDir/platanus/K_27_59/K_27_59
		/home/hxx/tools/platanus/Platanus_v1.2.4/platanus scaffold -c $tempDir/platanus/K_27_59/K_27_59_contig.fa -b $tempDir/platanus/K_27_59/K_27_59_contigBubble.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_27_59/K_27_59 -t $threads
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 gap_close -c $tempDir/platanus/K_27_59/K_27_59_scaffold.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_27_59/K_27_59 -t $threads
		if [[ -s $tempDir/platanus/K_27_59/K_27_59_gapClosed_scaffold.fa ]]
		then
			echo "platanus_K_27_59 already done!" >> $tempDir/log.txt
		else 
			echo "platanus_K_27_59 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 assemble -f $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -k 17 -K 0.45 -s 10 -t $threads -o $tempDir/platanus/K_17_67/K_17_67
		/home/hxx/tools/platanus/Platanus_v1.2.4/platanus scaffold -c $tempDir/platanus/K_17_67/K_17_67_contig.fa -b $tempDir/platanus/K_17_67/K_17_67_contigBubble.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_17_67/K_17_67 -t $threads
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 gap_close -c $tempDir/platanus/K_17_67/K_17_67_scaffold.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_17_67/K_17_67 -t $threads
		if [[ -s $tempDir/platanus/K_17_67/K_17_67_gapClosed_scaffold.fa ]]
		then
			echo "platanus_K_17_67 already done!" >> $tempDir/log.txt
		else 
			echo "platanus_K_17_67 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 assemble -f $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -t $threads -o $tempDir/platanus/K_default/K_default
		/home/hxx/tools/platanus/Platanus_v1.2.4/platanus scaffold -c $tempDir/platanus/K_default/K_default_contig.fa -b $tempDir/platanus/K_default/K_default_contigBubble.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_default/K_default -t $threads
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 gap_close -c $tempDir/platanus/K_default/K_default_scaffold.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_default/K_default -t $threads
		if [[ -s $tempDir/platanus/K_default/K_default_gapClosed_scaffold.fa ]]
		then
			echo "platanus_K_default already done!" >> $tempDir/log.txt
		else 
			echo "platanus_K_default error!" >> $tempDir/log.txt
			#exit#g
		fi
	elif [ $read_length -lt 127 ] && [ $read_length -ge 100 ]
	then
		###spades
		mkdir $tempDir/spades
		/data/public_tools/spades/bin/spades.py -1 $tempDir/musket/${file2}_corrected_1.fastq -2 $tempDir/musket/${file2}_corrected_2.fastq -k 21,29,37,45,53 -o $tempDir/spades/K_21_53 --careful --sc -t $threads --disable-gzip-output
		if [[ -s $tempDir/spades/K_21_53/scaffolds.fasta ]]
		then
			echo "spades_K_21_53 already done!" >> $tempDir/log.txt
		else 
			echo "spades_K_21_53 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/spades/bin/spades.py -1 $tempDir/musket/${file2}_corrected_1.fastq -2 $tempDir/musket/${file2}_corrected_2.fastq -k 27,39,51,63,75 -o $tempDir/spades/K_27_75 --careful --sc -t $threads --disable-gzip-output
		if [[ -s $tempDir/spades/K_27_75/scaffolds.fasta ]]
		then
			echo "spades_K_27_75 already done!" >> $tempDir/log.txt
		else 
			echo "spades_K_27_75 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/spades/bin/spades.py -1 $tempDir/musket/${file2}_corrected_1.fastq -2 $tempDir/musket/${file2}_corrected_2.fastq -k 21,35,49,63,77,91 -o $tempDir/spades/K_21_91 --careful --sc -t $threads --disable-gzip-output
		if [[ -s $tempDir/spades/K_21_91/scaffolds.fasta ]]
		then
			echo "spades_K_21_91 already done!" >> $tempDir/log.txt
		else 
			echo "spades_K_21_91 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/spades/bin/spades.py -1 $tempDir/musket/${file2}_corrected_1.fastq -2 $tempDir/musket/${file2}_corrected_2.fastq  -o $tempDir/spades/K_default --careful --sc -t $threads --disable-gzip-output
		if [[ -s $tempDir/spades/K_default/scaffolds.fasta ]]
		then
			echo "spades_K_default already done!" >> $tempDir/log.txt
		else 
			echo "spades_K_default error!" >> $tempDir/log.txt
			#exit#g
		fi
		for dir in $tempDir/spades/*;do cd ${dir} && ls| grep -v "scaffolds.fasta\|spades.log"|xargs rm -rf && cd ..;done

		insert_length_tmp=`grep "Insert size" $tempDir/spades/K_default/spades.log |awk '{print $13}'`
		insert_length=`echo $insert_length_tmp | awk -F ',' '{print $1}'`

		###soapdenovo
		mkdir $tempDir/soapdenovo
		##配置configfile
		echo "max_rd_len=${read_length}" > $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "[LIB]" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "avg_ins=${insert_length}" >> $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "reverse_seq=0" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "asm_flags=3" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "rank=1" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "q1=$tempDir/musket/${file2}_corrected_1.fastq" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "q2=$tempDir/musket/${file2}_corrected_2.fastq" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		for k in 35 49 63 77 91
		do
			mkdir $tempDir/soapdenovo/K_${k}
			/data/public_tools/soapdenovo2/bin/SOAPdenovo-127mer all -s $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg  -o $tempDir/soapdenovo/K_${k}/K_${k} -K ${k} -R -d 1 -M 1 -D 1 -p $threads -F
			/data/public_tools/gapcloser/bin/GapCloser -b $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg -a $tempDir/soapdenovo/K_${k}/K_${k}.scafSeq -o $tempDir/soapdenovo/K_${k}/K_${k}_fillgap.fasta
			if [[ -s $tempDir/soapdenovo/K_${k}/K_${k}_fillgap.fasta ]]
			then
				echo "soapdenovo_K_${k} already done!" >> $tempDir/log.txt
			else 
				echo "soapdenovo_K_${k} error!" >> $tempDir/log.txt
				#exit#g
			fi
		done
		mkdir $tempDir/soapdenovo/K_default
		/data/public_tools/soapdenovo2/bin/SOAPdenovo-127mer all -s $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg  -o $tempDir/soapdenovo/K_default/K_default -R -d 1 -M 1 -D 1 -p $threads -F
		/data/public_tools/gapcloser/bin/GapCloser -b $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg -a $tempDir/soapdenovo/K_default/K_default.scafSeq -o $tempDir/soapdenovo/K_default/K_default_fillgap.fasta
		if [[ -s $tempDir/soapdenovo/K_default/K_default_fillgap.fasta ]]
		then
			echo "soapdenovo_K_default already done!" >> $tempDir/log.txt
		else 
			echo "soapdenovo_K_default error!" >> $tempDir/log.txt
			#exit#g
		fi
		rm -rf $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		for dir in $tempDir/soapdenovo/*;do cd ${dir} && ls| grep -v ".scafSeq\|fillgap.fasta$\|log"|xargs rm -rf && cd ..;done
		
		###velvet
		mkdir $tempDir/velvet
		for k in 35 49 63 77 91
		do
			/data/public_tools/velvet/bin/velveth $tempDir/velvet/auto_${k} ${k} -fastq -shortPaired -separate $tempDir/musket/${file2}_corrected_1.fastq  $tempDir/musket/${file2}_corrected_2.fastq
			/data/public_tools/velvet/bin/velvetg $tempDir/velvet/auto_${k} -cov_cutoff auto -exp_cov auto
			if [[ -s $tempDir/velvet/auto_${k}/contigs.fa ]]
			then
				echo "velvet_K_${k} already done!" >> $tempDir/log.txt
			else 
				echo "velvet_K_${k} error!" >> $tempDir/log.txt
				#exit#g
			fi
		done
		for dir in $tempDir/velvet/*;do cd ${dir} && ls| grep -v "contigs.fa\|Log"|xargs rm -rf && cd ..;done
		
		###idba_UD
		mkdir $tempDir/idba
		/data/public_tools/idba/bin/fq2fa --merge --filter $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq $tempDir/idba/${file2}.fa
		/data/public_tools/idba/bin/idba_ud -r $tempDir/idba/${file2}.fa  --pre_correction  --num_threads $threads  --mink 21 --maxk 53 --step 8 -o $tempDir/idba/21_53_8
		if [[ -s $tempDir/idba/21_53_8/scaffold.fa ]]
		then
			echo "idba_21_53 already done!" >> $tempDir/log.txt
		else 
			echo "idba_21_53 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/idba/bin/idba_ud -r $tempDir/idba/${file2}.fa  --pre_correction  --num_threads $threads  --mink 27 --maxk 75 --step 12 -o $tempDir/idba/27_75_12
		if [[ -s $tempDir/idba/27_75_12/scaffold.fa ]]
		then
			echo "idba_27_75 already done!" >> $tempDir/log.txt
		else 
			echo "idba_27_75 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/idba/bin/idba_ud -r $tempDir/idba/${file2}.fa  --pre_correction  --num_threads $threads  --mink 21 --maxk 91 --step 14 -o $tempDir/idba/21_91_14
		if [[ -s $tempDir/idba/21_91_14/scaffold.fa ]]
		then
			echo "idba_21_91 already done!" >> $tempDir/log.txt
		else 
			echo "idba_21_91 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/idba/bin/idba_ud -r $tempDir/idba/${file2}.fa  --pre_correction  --num_threads $threads   -o $tempDir/idba/default
		if [[ -s $tempDir/idba/default/scaffold.fa ]]
		then
			echo "idba_default already done!" >> $tempDir/log.txt
		else 
			echo "idba_default error!" >> $tempDir/log.txt
			#exit#g
		fi
		rm -rf $tempDir/idba/${file2}.fa
		for dir in $tempDir/idba/*;do cd ${dir} && ls| grep -v "scaffold.fa\|log"|xargs rm -rf && cd ..;done

		###platanus
		mkdir $tempDir/platanus
		mkdir $tempDir/platanus/K_21_53
		mkdir $tempDir/platanus/K_27_75
		mkdir $tempDir/platanus/K_21_91
		mkdir $tempDir/platanus/K_default
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 assemble -f $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -k 21 -K 0.35 -s 8 -t $threads -o $tempDir/platanus/K_21_53/K_21_53
		/home/hxx/tools/platanus/Platanus_v1.2.4/platanus scaffold -c $tempDir/platanus/K_21_53/K_21_53_contig.fa -b $tempDir/platanus/K_21_53/K_21_53_contigBubble.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_21_53/K_21_53 -t $threads
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 gap_close -c $tempDir/platanus/K_21_53/K_21_53_scaffold.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_21_53/K_21_53 -t $threads
		if [[ -s $tempDir/platanus/K_21_53/K_21_53_gapClosed_scaffold.fa ]]
		then
			echo "platanus_K_21_53 already done!" >> $tempDir/log.txt
		else 
			echo "platanus_K_21_53 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 assemble -f $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -k 27 -K 0.5 -s 12 -t $threads -o $tempDir/platanus/K_27_75/K_27_75
		/home/hxx/tools/platanus/Platanus_v1.2.4/platanus scaffold -c $tempDir/platanus/K_27_75/K_27_75_contig.fa -b $tempDir/platanus/K_27_75/K_27_75_contigBubble.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_27_75/K_27_75 -t $threads
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 gap_close -c $tempDir/platanus/K_27_75/K_27_75_scaffold.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_27_75/K_27_75 -t $threads
		if [[ -s $tempDir/platanus/K_27_75/K_27_75_gapClosed_scaffold.fa ]]
		then
			echo "platanus_K_27_75 already done!" >> $tempDir/log.txt
		else 
			echo "platanus_K_27_75 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 assemble -f $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -k 21 -K 0.6 -s 14 -t $threads -o $tempDir/platanus/K_21_91/K_21_91
		/home/hxx/tools/platanus/Platanus_v1.2.4/platanus scaffold -c $tempDir/platanus/K_21_91/K_21_91_contig.fa -b $tempDir/platanus/K_21_91/K_21_91_contigBubble.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_21_91/K_21_91 -t $threads
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 gap_close -c $tempDir/platanus/K_21_91/K_21_91_scaffold.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_21_91/K_21_91 -t $threads
		if [[ -s $tempDir/platanus/K_21_91/K_21_91_gapClosed_scaffold.fa ]]
		then
			echo "platanus_K_21_91 already done!" >> $tempDir/log.txt
		else 
			echo "platanus_K_21_91 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 assemble -f $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -t $threads -o $tempDir/platanus/K_default/K_default
		/home/hxx/tools/platanus/Platanus_v1.2.4/platanus scaffold -c $tempDir/platanus/K_default/K_default_contig.fa -b $tempDir/platanus/K_default/K_default_contigBubble.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_default/K_default -t $threads
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 gap_close -c $tempDir/platanus/K_default/K_default_scaffold.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_default/K_default -t $threads
		if [[ -s $tempDir/platanus/K_default/K_default_gapClosed_scaffold.fa ]]
		then
			echo "platanus_K_default already done!" >> $tempDir/log.txt
		else 
			echo "platanus_K_default error!" >> $tempDir/log.txt
			#exit#g
		fi
	elif [ $read_length -ge 127 ]
	then
		###spades
		mkdir $tempDir/spades
		/data/public_tools/spades/bin/spades.py -1 $tempDir/musket/${file2}_corrected_1.fastq -2 $tempDir/musket/${file2}_corrected_2.fastq -k 21,35,49,63,77 -o $tempDir/spades/K_21_77 --careful --sc -t $threads --disable-gzip-output
		/data/public_tools/spades/bin/spades.py -1 $tempDir/musket/${file2}_corrected_1.fastq -2 $tempDir/musket/${file2}_corrected_2.fastq -k 25,43,61,79,97 -o $tempDir/spades/K_25_97 --careful --sc -t $threads --disable-gzip-output
		/data/public_tools/spades/bin/spades.py -1 $tempDir/musket/${file2}_corrected_1.fastq -2 $tempDir/musket/${file2}_corrected_2.fastq -k 17,39,61,83,105,127 -o $tempDir/spades/K_17_127 --careful --sc -t $threads --disable-gzip-output
		/data/public_tools/spades/bin/spades.py -1 $tempDir/musket/${file2}_corrected_1.fastq -2 $tempDir/musket/${file2}_corrected_2.fastq  -o $tempDir/spades/K_default --careful --sc -t $threads --disable-gzip-output
		for dir in $tempDir/spades/*;do cd ${dir} && ls| grep -v "scaffolds.fasta\|spades.log"|xargs rm -rf && cd ..;done
		insert_length_tmp=`grep "Insert size" $tempDir/spades/K_default/spades.log |awk '{print $13}'`
		insert_length=`echo $insert_length_tmp | awk -F ',' '{print $1}'`
		###soapdenovo
		mkdir $tempDir/soapdenovo
		##配置configfile
		echo "max_rd_len=${read_length}" > $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "[LIB]" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "avg_ins=${insert_length}" >> $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "reverse_seq=0" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "asm_flags=3" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "rank=1" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "q1=$tempDir/musket/${file2}_corrected_1.fastq" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		echo "q2=$tempDir/musket/${file2}_corrected_2.fastq" >>  $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		for k in 39 61 83 105 127
		do
			mkdir $tempDir/soapdenovo/K_${k}
			/data/public_tools/soapdenovo2/bin/SOAPdenovo-127mer all -s $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg  -o $tempDir/soapdenovo/K_${k}/K_${k} -K ${k} -R -d 1 -M 1 -D 1 -p $threads -F
			/data/public_tools/gapcloser/bin/GapCloser -b $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg -a $tempDir/soapdenovo/K_${k}/K_${k}.scafSeq -o $tempDir/soapdenovo/K_${k}/K_${k}_fillgap.fasta
			if [[ -s $tempDir/soapdenovo/K_${k}/K_${k}_fillgap.fasta ]]
			then
				echo "soapdenovo_K_${k} already done!" >> $tempDir/log.txt
			else 
				echo "soapdenovo_K_${k} error!" >> $tempDir/log.txt
				#exit#g
			fi
		done
		mkdir $tempDir/soapdenovo/K_default
		/data/public_tools/soapdenovo2/bin/SOAPdenovo-127mer all -s $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg  -o $tempDir/soapdenovo/K_default/K_default -R -d 1 -M 1 -D 1 -p $threads -F
		/data/public_tools/gapcloser/bin/GapCloser -b $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg -a $tempDir/soapdenovo/K_default/K_default.scafSeq -o $tempDir/soapdenovo/K_default/K_default_fillgap.fasta
		if [[ -s $tempDir/soapdenovo/K_default/K_default_fillgap.fasta ]]
		then
			echo "soapdenovo_K_default already done!" >> $tempDir/log.txt
		else 
			echo "soapdenovo_K_default error!" >> $tempDir/log.txt
			#exit#g
		fi
		rm -rf $tempDir/soapdenovo/${file2}_${read_length}_${insert_length}.cfg
		for dir in $tempDir/soapdenovo/*;do cd ${dir} && ls| grep -v ".scafSeq\|fillgap.fasta$\|log"|xargs rm -rf && cd ..;done
		
		###velvet
		mkdir $tempDir/velvet
		for k in 39 61 83 105 127
		do
			/data/public_tools/velvet/bin/velveth $tempDir/velvet/auto_${k} ${k} -fastq -shortPaired -separate $tempDir/musket/${file2}_corrected_1.fastq  $tempDir/musket/${file2}_corrected_2.fastq
			/data/public_tools/velvet/bin/velvetg $tempDir/velvet/auto_${k} -cov_cutoff auto -exp_cov auto
			if [[ -s $tempDir/velvet/auto_${k}/contigs.fa ]]
			then
				echo "velvet_K_${k} already done!" >> $tempDir/log.txt
			else 
				echo "velvet_K_${k} error!" >> $tempDir/log.txt
				#exit#g
			fi
		done
		for dir in $tempDir/velvet/*;do cd ${dir} && ls| grep -v "contigs.fa\|Log"|xargs rm -rf && cd ..;done
		
		###idba_UD
		mkdir $tempDir/idba
		/data/public_tools/idba/bin/fq2fa --merge --filter $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq $tempDir/idba/${file2}.fa
		/data/public_tools/idba/bin/idba_ud -r $tempDir/idba/${file2}.fa  --pre_correction  --num_threads $threads  --mink 21 --maxk 77 --step 14 -o $tempDir/idba/21_77_14
		if [[ -s $tempDir/idba/21_77_14/scaffold.fa ]]
		then
			echo "idba_21_77 already done!" >> $tempDir/log.txt
		else 
			echo "idba_21_77 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/idba/bin/idba_ud -r $tempDir/idba/${file2}.fa  --pre_correction  --num_threads $threads  --mink 25 --maxk 97 --step 18 -o $tempDir/idba/25_97_18
		if [[ -s $tempDir/idba/25_97_18/scaffold.fa ]]
		then
			echo "idba_25_97 already done!" >> $tempDir/log.txt
		else 
			echo "idba_25_97 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/idba/bin/idba_ud -r $tempDir/idba/${file2}.fa  --pre_correction  --num_threads $threads  --mink 17 --maxk 124 --step 22 -o $tempDir/idba/17_124_22
		if [[ -s $tempDir/idba/17_124_22/scaffold.fa ]]
		then
			echo "idba_17_124 already done!" >> $tempDir/log.txt
		else 
			echo "idba_17_124 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/idba/bin/idba_ud -r $tempDir/idba/${file2}.fa  --pre_correction  --num_threads $threads   -o $tempDir/idba/default
		if [[ -s $tempDir/idba/default/scaffold.fa ]]
		then
			echo "idba_default already done!" >> $tempDir/log.txt
		else 
			echo "idba_default error!" >> $tempDir/log.txt
			#exit#g
		fi
		rm -rf $tempDir/idba/${file2}.fa
		for dir in $tempDir/idba/*;do cd ${dir} && ls| grep -v "scaffold.fa\|log"|xargs rm -rf && cd ..;done
		
		###platanus
		mkdir $tempDir/platanus
		mkdir $tempDir/platanus/K_21_77
		mkdir $tempDir/platanus/K_25_97
		mkdir $tempDir/platanus/K_17_124
		mkdir $tempDir/platanus/K_default
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 assemble -f $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -k 21 -K 0.51 -s 14 -t $threads -o $tempDir/platanus/K_21_77/K_21_77
		/home/hxx/tools/platanus/Platanus_v1.2.4/platanus scaffold -c $tempDir/platanus/K_21_77/K_21_77_contig.fa -b $tempDir/platanus/K_21_77/K_21_77_contigBubble.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_21_77/K_21_77 -t $threads
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 gap_close -c $tempDir/platanus/K_21_77/K_21_77_scaffold.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_21_77/K_21_77 -t $threads
		if [[ -s $tempDir/platanus/K_21_77/K_21_77_gapClosed_scaffold.fa ]]
		then
			echo "platanus_K_21_77 already done!" >> $tempDir/log.txt
		else 
			echo "platanus_K_21_77 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 assemble -f $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -k 25 -K 0.65 -s 18 -t $threads -o $tempDir/platanus/K_25_97/K_25_97
		/home/hxx/tools/platanus/Platanus_v1.2.4/platanus scaffold -c $tempDir/platanus/K_25_97/K_25_97_contig.fa -b $tempDir/platanus/K_25_97/K_25_97_contigBubble.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_25_97/K_25_97 -t $threads
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 gap_close -c $tempDir/platanus/K_25_97/K_25_97_scaffold.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_25_97/K_25_97 -t $threads
		if [[ -s $tempDir/platanus/K_25_97/K_25_97_gapClosed_scaffold.fa ]]
		then
			echo "platanus_K_25_97 already done!" >> $tempDir/log.txt
		else 
			echo "platanus_K_25_97 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 assemble -f $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -k 17 -K 0.82 -s 22 -t $threads -o $tempDir/platanus/K_17_124/K_17_124
		/home/hxx/tools/platanus/Platanus_v1.2.4/platanus scaffold -c $tempDir/platanus/K_17_124/K_17_124_contig.fa -b $tempDir/platanus/K_17_124/K_17_124_contigBubble.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_17_124/K_17_124 -t $threads
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 gap_close -c $tempDir/platanus/K_17_124/K_17_124_scaffold.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_17_124/K_17_124 -t $threads
		if [[ -s $tempDir/platanus/K_17_124/K_17_124_gapClosed_scaffold.fa ]]
		then
			echo "platanus_K_17_124 already done!" >> $tempDir/log.txt
		else 
			echo "platanus_K_17_124 error!" >> $tempDir/log.txt
			#exit#g
		fi
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 assemble -f $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -t $threads -o $tempDir/platanus/K_default/K_default
		/home/hxx/tools/platanus/Platanus_v1.2.4/platanus scaffold -c $tempDir/platanus/K_default/K_default_contig.fa -b $tempDir/platanus/K_default/K_default_contigBubble.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_default/K_default -t $threads
		/data/public_tools/platanus/platanus_b_v1.2.0_linux_x86_64 gap_close -c $tempDir/platanus/K_default/K_default_scaffold.fa -IP $tempDir/musket/${file2}_corrected_1.fastq $tempDir/musket/${file2}_corrected_2.fastq -o $tempDir/platanus/K_default/K_default 
		if [[ -s $tempDir/platanus/K_default/K_default_gapClosed_scaffold.fa ]]
		then
			echo "platanus_K_default already done!" >> $tempDir/log.txt
		else 
			echo "platanus_K_default error!" >> $tempDir/log.txt
			#exit#g
		fi
	fi
	######汇总拼接文件
	if [[ -d $tempDir/assembly_seq ]]
	then
		rm -rf $tempDir/assembly_seq
		mkdir $tempDir/assembly_seq
	else
		mkdir $tempDir/assembly_seq
	fi

	if [[ -d $tempDir/assembly_seq_gt_500 ]]
	then
		rm -rf $tempDir/assembly_seq_gt_500
		mkdir $tempDir/assembly_seq_gt_500
	else
		mkdir $tempDir/assembly_seq_gt_500
	fi
	
	for dir in $tempDir/spades/*
	do
		var=${dir##*/}
		cp ${dir}/scaffolds.fasta $tempDir/assembly_seq/spades_${var}.fasta
	done
	for dir in $tempDir/soapdenovo/*
	do
		if [ -d ${dir} ]
		then
			var=${dir##*/}
			cp ${dir}/${var}_fillgap.fasta $tempDir/assembly_seq/soapdenovo_${var}.fasta
		fi
	done
	for dir in $tempDir/idba/[0-9]*
	do
		var=${dir##*/}
		cp ${dir}/scaffold.fa $tempDir/assembly_seq/idba_${var}.fasta
	done
	cp $tempDir/idba/default/contig.fa $tempDir/assembly_seq/idba_default.fasta
	
	for dir in $tempDir/velvet/*
	do
		if [ -d ${dir} ]
		then
			var=${dir##*/}
			cp ${dir}/contigs.fa $tempDir/assembly_seq/velvet_${var}.fasta
		fi
	done
			
	for dir in $tempDir/platanus/*
	do
		if [ -d ${dir} ]
		then
			var=${dir##*/}
			cp ${dir}/${var}_gapClosed_scaffold.fa $tempDir/assembly_seq/platanus_${var}.fasta
		fi
	done
	##########删掉低于500bp长度的contig
	for seq in $tempDir/assembly_seq/*
	do
		name=${seq##*/}
		ID=${name%.*}
		perl $perlDir/filter_less_500bp.pl $seq $ID > $tempDir/assembly_seq_gt_500/${name}
	done

	
	##########predict_genome_size
	if [[ -d $tempDir/jellyfish ]]
	then
		rm -rf $tempDir/jellyfish
		mkdir $tempDir/jellyfish
	else
		mkdir $tempDir/jellyfish
	fi
	if [[ ${pe1[${i}]} =~ .+fastq$ ]] || [[ ${pe1[${i}]} =~ .+fq$ ]]
    then
        /data/public_tools/jellyfish/bin/jellyfish count -C -m 17 -s 1000000000 -t $threads  ${pe1[$i]} -o $tempDir/jellyfish/reads.jf
		/data/public_tools/jellyfish/bin/jellyfish histo -t $threads $tempDir/jellyfish/reads.jf > $tempDir/jellyfish/reads.histo
		reads_GC=`perl $perlDir/GC_fastq.pl ${pe1[$i]}`
	elif [[ ${pe1[${i}]} =~ .+gz$ ]]
    then
		/data/public_tools/jellyfish/bin/jellyfish count -C -m 17 -s 1000000000 -t $threads   $tempDir/tmp.fastq  -o $tempDir/jellyfish/reads.jf
        /data/public_tools/jellyfish/bin/jellyfish histo -t $threads $tempDir/jellyfish/reads.jf > $tempDir/jellyfish/reads.histo
		reads_GC=`perl $perlDir/GC_fastq.pl $tempDir/tmp.fastq`
    fi

	if [[ -s $tempDir/jellyfish/reads.histo ]]
	then
		echo "jellyfish already done!" >> $tempDir/log.txt
	else 
		echo "jellyfish error!" >> $tempDir/log.txt
		#exit#g
	fi
	mkdir $tempDir/genomescope
	/data/public_tools/R/bin/Rscript /data/public_tools/genomescope/genomescope.R $tempDir/jellyfish/reads.histo 17 ${read_length} $tempDir/genomescope > $tempDir/genomescope.log
	rm -rf $tempDir/genomescope

	predict_size=`grep "len:" $tempDir/genomescope.log | sed 's/.*len:\([0-9]*\)/\1/g'`
	
	##########delete_outlier_according_to_the_assembly_infomation
	perl $perlDir/make_table.pl $tempDir/assembly_seq_gt_500/ > $tempDir/all_genome_info.txt
#	perl $perlDir/make_table_rm_outlier.pl $tempDir/assembly_seq_gt_500/ ${predict_size} ${reads_GC} > $tempDir/genome_info.txt
	perl $perlDir/genome_info.pl -inputdir $tempDir/fastqc -predictsize ${predict_size} -allgenomeinfo $tempDir/all_genome_info.txt -outfile $tempDir/genome_info.txt
	median_n50=`awk 'NR>1{a[PrefixNAME][FNR]=$3}END{for(i in a){c=asort(a[i],b);d=int(c/2);if(c%2==0){printf("%s %.7f\n",i,(b[d]+b[d+1])/2)}else{printf(b[d+1])}}}' $tempDir/genome_info.txt`
	median_tl=`awk 'NR>1{a[PrefixNAME][FNR]=$6}END{for(i in a){c=asort(a[i],b);d=int(c/2);if(c%2==0){printf("%s %.7f\n",i,(b[d]+b[d+1])/2)}else{printf(b[d+1])}}}' $tempDir/genome_info.txt`
	perl $perlDir/evaluate_assembly.pl $tempDir/genome_info.txt $median_n50 $median_tl > $tempDir/score.txt
#	perl $perlDir/make_table.pl $tempDir/assembly_seq_gt_500/ > $tempDir/all_genome_info.txt
	
	##########when the genome size predicted by genomescope is not correct, all assembly result would be deleted. When this happens, using the following method to filter assembly outliers.
	if [ ! -s $tempDir/score.txt ]
	then	
		predict_size=`awk 'NR>1{a[PrefixNAME][FNR]=$6}END{for(i in a){c=asort(a[i],b);d=int(c/2);if(c%2==0){printf("%s %.7f\n",i,(b[d]+b[d+1])/2)}else{printf(b[d+1])}}}' $tempDir/all_genome_info.txt`
#		perl $perlDir/make_table_rm_outlier.pl $tempDir/assembly_seq_gt_500/ $predict_size ${reads_GC} > $tempDir/genome_info.txt
		perl $perlDir/genome_info.pl -inputdir $tempDir/fastqc -predictsize ${predict_size} -allgenomeinfo $tempDir/all_genome_info.txt -outfile $tempDir/genome_info.txt
		median_n50=`awk 'NR>1{a[PrefixNAME][FNR]=$3}END{for(i in a){c=asort(a[i],b);d=int(c/2);if(c%2==0){printf("%s %.7f\n",i,(b[d]+b[d+1])/2)}else{printf(b[d+1])}}}' $tempDir/genome_info.txt`
		median_tl=`awk 'NR>1{a[PrefixNAME][FNR]=$6}END{for(i in a){c=asort(a[i],b);d=int(c/2);if(c%2==0){printf("%s %.7f\n",i,(b[d]+b[d+1])/2)}else{printf(b[d+1])}}}' $tempDir/genome_info.txt`
		perl $perlDir/evaluate_assembly.pl $tempDir/genome_info.txt $median_n50 $median_tl > $tempDir/score.txt
	fi
	
	##########The best assembly
	best=`awk 'BEGIN {max = 0} {if ($2+0 > max+0) {max=$2 ;content=$1} } END {print content}' $tempDir/score.txt`
	if [[ -n $best ]]
	then
		echo "Best assembly already done!" >> $tempDir/log.txt
	else 
		echo "Best assembly error!" >> $tempDir/log.txt
		#exit#g
	fi
	cp $tempDir/assembly_seq_gt_500/$best $outputDir/${file2}.fasta
	echo "ID	Scaffold_number	N50	N75	Largest_Scaffold	Total_length	GC%	N's" > $outputDir/genome_info.txt
	grep $best $tempDir/genome_info.txt >> $outputDir/genome_info.txt
	echo "Assember and parameters">$outputDir/best_par.txt
	echo "$best" >>$outputDir/best_par.txt
	sed -i 's#.fasta##g' $outputDir/best_par.txt

	#########reads map to the best assembly result
	if [[ -d $tempDir/alignment ]]
	then
		rm -rf $tempDir/alignment
		mkdir $tempDir/alignment
	else
		mkdir $tempDir/alignment
	fi
	cp $tempDir/assembly_seq_gt_500/$best $tempDir/alignment/
	bwa index $tempDir/alignment/$best
	bwa mem $tempDir/alignment/$best ${pe1[$i]} ${pe2[$i]} -t $threads | samtools view  -b -S -o  $tempDir/alignment/${file2}.bam -
	samtools sort $tempDir/alignment/${file2}.bam -o $tempDir/alignment/${file2}.sorted.bam
	/data/public_tools/bedtools/bin/bedtools genomecov -ibam $tempDir/alignment/${file2}.sorted.bam -d > $tempDir/alignment/${file2}.depth
	samtools flagstat $tempDir/alignment/${file2}.bam > $outputDir/reads_match.txt
	if [[ -s $outputDir/reads_match.txt ]]
	then
		echo "alignment already done!" >> $tempDir/log.txt
	else 
		echo "alignment error!" >> $tempDir/log.txt
#		#exit#g
	fi
	mkdir $tempDir/alignment/${file2}_gc_cov
	perl $perlDir/batch_cov_gc.pl $tempDir/alignment/${file2}.depth $tempDir/alignment/$best 500 20 $tempDir/alignment/${file2}_gc_cov
	
	###genome_info
	export PATH="/data/public_tools/picard/bin:$PATH"
	/data/public_tools/picard/bin/picard CollectInsertSizeMetrics I=$tempDir/alignment/${file2}.sorted.bam O=$tempDir/alignment/${file2}_insert_size.txt H=$tempDir/alignment/${file2}_insert_size.pdf

	###kmer_info
	kmer_num=`awk 'BEGIN{sum=0}{sum=sum+$1*$2}END{print sum}' $tempDir/jellyfish/reads.histo`
	tmp=`grep "k=" $tempDir/genomescope.log | sed 's/.*k=\([0-9]*\)/\1/g'`
	kmer_size=${tmp%read*}
	predict_size=`grep "len:" $tempDir/genomescope.log | sed 's/.*len:\([0-9]*\)/\1/g'`
	if [[ -n ${predict_size} ]]
	then
		((genome_depth=${kmer_num[$i]}/${predict_size[$i]}))		###genomescope may not have output
	else
		predict_size_tmp=`awk 'NR>1{a[PrefixNAME][FNR]=$6}END{for(i in a){c=asort(a[i],b);d=int(c/2);if(c%2==0){printf("%s %.7f\n",i,(b[d]+b[d+1])/2)}else{printf(b[d+1])}}}' $tempDir/all_genome_info.txt`
		predict_size=`echo ${predict_size_tmp} | awk '{print int($0)}'`
		((genome_depth=${kmer_num}/${predict_size}))
	fi
	
	if [[ ${kmer_size} -ne "" ]]
	then
		echo "Kmer_Size already done!" >> $tempDir/log.txt
	else 
		echo "Kmer_Size error!" >> $tempDir/log.txt
		#exit#g
	fi
	if [[ ${kmer_num} -ne "" ]]
	then
		echo "Kmer_Num already done!" >> $tempDir/log.txt
	else 
		echo "Kmer_Num error!" >> $tempDir/log.txt
		#exit#g
	fi
	if [[ ${predict_size} -ne "" ]]
	then
		echo "Predict_Size already done!" >> $tempDir/log.txt
	else 
		echo "Predict_Size error!" >> $tempDir/log.txt
		#exit#g
	fi
	if [[ ${genome_depth} -ne "" ]]
	then
		echo "Genome_Depth already done!" >> $tempDir/log.txt
	else 
		echo "Genome_Depth error!" >> $tempDir/log.txt
		#exit#g
	fi
	echo "Kmer_Size: "${kmer_size} >> $outputDir/kmer_info.txt
	echo "Kmer_Num: "${kmer_num} >> $outputDir/kmer_info.txt
	echo "Predict_Genome_Size: "${predict_size} >> $outputDir/kmer_info.txt
	echo "Genome_Depth: "${genome_depth} >> $outputDir/kmer_info.txt
	/data/public_tools/R/bin/Rscript /data/homebackup/liudongmei/GCtype/NGS/shell/gc_cov.R inputfile=$tempDir/alignment/${file2}_gc_cov outputfile=$outputDir/${file2}_gc_cov.png
	/data/public_tools/R/bin/Rscript $RDir/kmer_frequency.R inputfile=$tempDir/jellyfish/reads.histo outputfile=$outputDir/${file2}_kmer_freq.png kmer_num=${kmer_num} genome_size=${predict_size} x_Max=600
	/data/public_tools/R/bin/Rscript $RDir/insert_size.R inputfile=$tempDir/alignment/${file2}_insert_size.txt outputfile1=$outputDir/${file2}_insert_size.png outputfile2=$tempDir/${file2}_insert_size_info.txt
	
	###reads_info
	if [[ -n ${Raw_Reads_Size} ]]
	then
		echo "Raw_Reads_Size already done!" >> $tempDir/log.txt
	else 
		echo "Raw_Reads_Size error!" >> $tempDir/log.txt
		#exit#g
	fi
	Clean_Reads_Size=`du -h --block-size=M $tempDir/trim/trim_1.fastq | awk '{print $1}'`
	if [[ -n ${Clean_Reads_Size} ]]
	then
		echo "Clean_Reads_Size already done!" >> $tempDir/log.txt
	else 
		echo "Clean_Reads_Size error!" >> $tempDir/log.txt
		#exit#g
	fi
	echo "Read_Size: "${read_length} > $outputDir/reads_info.txt
	grep "Insert_size:" $tempDir/${file2}_insert_size_info.txt >> $outputDir/reads_info.txt
	###trimmomatic/sickle

	grep "Input Read Pairs" $tempDir/trim/summary.txt >> $outputDir/reads_info.txt
	grep "Dropped Read Percent" $tempDir/trim/summary.txt >> $outputDir/reads_info.txt
	
	echo "Raw_Reads_Size: "${Raw_Reads_Size} >> $outputDir/reads_info.txt
	echo "Clean_Reads_Size: "${Clean_Reads_Size} >> $outputDir/reads_info.txt
	
	###scaffold_info
	perl $perlDir/scaffold_info.pl $tempDir/alignment/${file2}.depth $outputDir/${file2}.fasta > $outputDir/scaffold_info.txt
	if [[ -s $outputDir/scaffold_info.txt ]]
	then
		echo "scaffold_info already done!" >> $tempDir/log.txt
	else 
		echo "scaffold_info error!" >> $tempDir/log.txt
		#exit#g
	fi
	if [[ -s $outputDir/scaffold_info.txt ]] && [[ -s $outputDir/reads_info.txt ]]  && [[ -s $outputDir/kmer_info.txt ]] && [[ -s $outputDir/${file2}_gc_cov.png ]] && [[ -s $outputDir/${file2}_kmer_freq.png ]] && [[ -s $outputDir/${file2}_insert_size.png ]] && [[ -s $outputDir/genome_info.txt ]] && [[ -s $outputDir/${file2}.fasta ]]
	then
		rm -rf $tempDir/tmp.fastq $tempDir/trim $tempDir/alignment/*.bam $tempDir/assembly_seq 
	fi
	
done

