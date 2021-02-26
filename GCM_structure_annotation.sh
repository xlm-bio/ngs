###############################################################################################################
###this script is for structure annotation of single bacteria genome
###usage: sh $0 -structure_programs prodigal,checkM,tRNAscan,RepeatMasker,RNAmmer,piler-cr \ (RNAmemr must behind RepeatMasker)
### -input_file xxxx.fasta
###############################################################################################################
while true; do
	case "$1" in
	-structure_programs) str_pro=$2; shift 2;; ##checkM,RNAmmer,tRNAscan,RepeatMasker,piler-cr
	-output_dir) output_dir=$2; shift 2;;
	-threads) threads=$2; shift 2;;
	-RNAmmer_S) RNAmmer_S=$2; shift 2;;
	-input_file) input=$2; shift 2;;
	-temp_dir) temp_dir=$2; shift 2;;
	-state) state=$2; shift 2;;
	*) break ;;
	esac
done

tRNAscan_conf="/data/public_tools/tRNAscan/bin/tRNAscan-SE.conf"
RNAmmer_m="lsu,tsu,ssu"
#input_dir=/home/genomemap/input_dir
#####temp_dir=/home/genomemap/temp_dir
###########RNAmmer_S bac arc euk
if [ ! -n "$RNAmmer_S" ]; then
	RNAmmer_S="bac"
fi
if [ ! -n "$state" ]; then
	state="0"
fi
#############which program do you want
if [ -n "$str_pro" ]; then
	array=(${str_pro//,/ })
else
	echo "chose the structural annotation program!" && exit 1
fi
############input file
if [ ! -s "$input" ]; then
	echo "lose the input file !" && exit 1
fi
###########point the output dir
if [ ! -n "$output_dir" ]; then
	output_dir=/home/genomemap/output_dir
fi
###########point the temp dir
if [ ! -n "$temp_dir" ]; then
        temp_dir=/home/genomemap/temp_dir
fi
##########Specify the threads
if [ ! -n "$threads" ]; then
	threads=30
fi
##########which kind of ending of the fasta file
input1=${input##*.} ####this will filter the file, and only fasta/fa/fna file could be the input file
if [[ $input1 == "fasta" ]]; then
	checkM_x="fasta"
elif [[ $input1 == "fa" ]]; then
	checkM_x="fa"
elif [[ $input1 == "fna" ]]; then
	checkM_x="fna"
else
	echo "input your ending of you input file!" && exit 1
fi
#########get the output file name
file1=${input##*/}
out_file_name=${file1%%.f*a}
perlDir="/data/pipeline/pipeline1/perl"
Rdir="/data/pipeline/pipeline1/R"

#if false ; then
cp $input $output_dir/${out_file_name}.fasta
##########start to run the programs
for i in ${array[@]}  ################## RNAmmer,tRNAscan,ReapetMasker,piler-cr
do
###########################run checkM ##############################################################################################
	if [[ $i == "checkM" ]]; then
		######build a new dir for checkM or delete or file in input dir
		if [[ ! -d ${temp_dir}/checkM-today ]]; then
			mkdir ${temp_dir}/checkM-today
		else
			rm -rf ${temp_dir}/checkM-today/*
		fi
		######check the output file empty or not
		if [[ -d ${temp_dir}/${out_file_name}_checkM ]]; then
			rm -rf ${temp_dir}/${out_file_name}_checkM
		fi
		#####copy input file into input dir
		cp $input ${temp_dir}/checkM-today/
		####run checkm
		/home/test/lvhy/software/checkM/checkm lineage_wf -t $threads -x $checkM_x -f ${temp_dir}/${out_file_name}_checkM/${out_file_name}_checkM.log ${temp_dir}/checkM-today ${temp_dir}/${out_file_name}_checkM
		#####check out_dir
		rm -rf ${output_dir}/${out_file_name}_checkM
		mv ${temp_dir}/${out_file_name}_checkM ${output_dir}
		###check the out.log og checkM exists or not
		if [ -f "${output_dir}/${out_file_name}_checkM/${out_file_name}_checkM.log" ]; then
			echo "CheckM successfully done."
		else
			echo "Errors was reported while running CheckM."
		fi
	fi
	############################################run rnammer#############################################################################
	if [[ $i == "RNAmmer" ]]; then
		if [[ ! -d ${temp_dir}/${out_file_name}_RNAmmer ]]; then
			mkdir ${temp_dir}/${out_file_name}_RNAmmer
		else
			rm -rf ${temp_dir}/${out_file_name}_RNAmmer/*
		fi
		rnammer -S $RNAmmer_S -multi -m $RNAmmer_m -xml ${temp_dir}/${out_file_name}_RNAmmer/${out_file_name}.RNAmmer.xml -f ${temp_dir}/${out_file_name}_RNAmmer/${out_file_name}.RNAmmer.fasta -h ${temp_dir}/${out_file_name}_RNAmmer/${out_file_name}.RNAmmer.hmmreport -gff ${temp_dir}/${out_file_name}_RNAmmer/${out_file_name}.RNAmmer.gff2 $input
		#blastn -db /data/database/16SrRNA-database/EZBioCloud/ezbiocloud_16srRNA_database -query ${output_dir}/RNAmmer/${out_file_name}.RNAmmer.fasta  -out ${output_dir}/RNAmmer/${out_file_name}.ezbiocloud.txt -evalue 1e-5 -max_target_seqs 1  -num_threads $threads -outfmt 6
		#perl /home/wxc/10000-sequencing/script/taxonomy.pl /data/database/16SrRNA-database/EZBioCloud/ezbiocloud_id_taxonomy.txt ${output_dir}/RNAmmer/${out_file_name}.ezbiocloud.txt > ${output_dir}/RNAmmer/${out_file_name}.ezbiocloud.taxonomy.txt
		rm -rf ${output_dir}/${out_file_name}_RNAmmer
		mv ${temp_dir}/${out_file_name}_RNAmmer ${output_dir}
		if [ -f "${output_dir}/${out_file_name}_RNAmmer/${out_file_name}.RNAmmer.gff2" ]; then
			echo "RNAmmer successfully done."
		else
			echo "Errors was reported while running RNAmmer."
		fi

if [ -s $outputDir/${file2}_RNAmmer/${file2}.RNAmmer.16s ]
then
	blastn -query $outputDir/${file2}_RNAmmer/${file2}.RNAmmer.16s -db $blastdb -outfmt 6 -num_threads 10 -evalue 1e-5 -max_hsps 1 -max_target_seqs 1 -out $outputDir/${file2}_RNAmmer/${file2}.RNAmmer.16s.blast.out
	perl $perlDir/get16s_anno.pl -blastinfo $blastdbinfo -blastout $outputDir/${file2}_RNAmmer/${file2}.RNAmmer.16s.blast.out -outfile $outputDir/16s_blast.result.xls
fi
	fi
	# @Deprecated
	############################################run RepeatMasker#####################################################################
	# 由于RepeatMaske使用的是真核参考序列，这里deprecated.
	# if [[ $i = "RepeatMasker" ]];then
	# 	if [[ ! -d ${temp_dir}/${out_file_name}_RNAmmer ]];then
	# 		mkdir ${temp_dir}/${out_file_name}_RepeatMasker
	# 	else
	# 		rm -rf ${temp_dir}/${out_file_name}_RepeatMasker/*
	# 	fi
	# 	#RepeatMasker -pa $threads -q -html ${temp_dir}/${out_file_name}_RepeatMasker/${out_file_name}.repeatmasker.html -gff ${temp_dir}/${out_file_name}.repeatmasker.gff  -dir ${temp_dir}/${out_file_name}_RepeatMasker/ $input
	# 	RepeatMasker -pa $threads -q -html /home/genomemap/script/${out_file_name}.repeatmasker.html -gff /home/genomemap/script/${out_file_name}.repeatmasker.gff  -dir ${temp_dir}/${out_file_name}_RepeatMasker/ $input
	# 	rm -rf ${output_dir}/${out_file_name}_RepeatMasker
	# 	mv ${temp_dir}/${out_file_name}_RepeatMasker $output_dir
	# 	if [ -f "${output_dir}/${out_file_name}_RepeatMasker/${out_file_name}.${checkM_x}.out.gff" ];then
	#                     echo "RepeatMasker successfully done."
	#             else
	#                     echo "Errors was reported while running RepeatMasker."
	#             fi
	# fi
	############################################TRF (Tandem Repeat Finder)#####################################################################
	if [[ $i == "RepeatMasker" ]]; then
		if [[ ! -d ${temp_dir}/${out_file_name}_RNAmmer ]]; then
			mkdir ${temp_dir}/${out_file_name}_RepeatMasker
		else
			rm -rf ${temp_dir}/${out_file_name}_RepeatMasker/*
		fi
		# TRF Recommended usage: /data/publictools/TRF/trf409.linux64 yoursequence.txt 2 7 7 80 10 50 500 -f -d -m -h
		# 由于TRF运行结果在执行目录下，所以需要change directory到结果目录
		cd ${temp_dir}/${out_file_name}_RepeatMasker && /data/public_tools/TRF/trf409.linux64 $input 2 7 7 80 10 50 500 -f -d -m -h && cd -
		rm -rf ${output_dir}/${out_file_name}_RepeatMasker
		mv ${temp_dir}/${out_file_name}_RepeatMasker $output_dir
		if [ -f "${output_dir}/${out_file_name}_RepeatMasker/${file1}.2.7.7.80.10.50.500.dat" ]; then
			echo "RepeatMasker successfully done."
		else
			echo "Errors was reported while running RepeatMasker."
		fi
	fi
	######################################run piler-cr##############################################################################
	if [[ $i == "piler-cr" ]]; then
		if [[ ! -d ${temp_dir}/${out_file_name}_piler-cr ]]; then
			mkdir ${temp_dir}/${out_file_name}_piler-cr
		else
			rm -rf ${temp_dir}/${out_file_name}_piler-cr/*
		fi
		pilercr -in $input -out ${temp_dir}/${out_file_name}_piler-cr/${out_file_name}.pilercr.txt
		rm -rf $output_dir/${out_file_name}_piler-cr
		mv ${temp_dir}/${out_file_name}_piler-cr $output_dir
		if [ -f "${output_dir}/${out_file_name}_piler-cr/${out_file_name}.pilercr.txt" ]; then
			echo "piler-cr successfully done."
		else
			echo "Errors was reported while running piler-cr."
		fi
	fi
	###############################tRNAscan############################################################################################
	if [[ $i == "tRNAscan" ]]; then
		if [[ ! -d ${temp_dir}/${out_file_name}_tRNAscan ]]; then
			mkdir ${temp_dir}/${out_file_name}_tRNAscan
		else
			rm -rf ${temp_dir}/${out_file_name}_tRNAscan/*
		fi
		if [[ ! -d ${temp_dir}/${out_file_name}_tRNAscan_genome ]]; then
			mkdir ${temp_dir}/${out_file_name}_tRNAscan_genome
		else
			rm -rf ${temp_dir}/${out_file_name}_tRNAscan_genome/*
		fi
		cp $input ${temp_dir}/${out_file_name}_tRNAscan_genome
		tRNAscan-SE -qQ -Y -o ${temp_dir}/${out_file_name}_tRNAscan/${out_file_name}.tRNAscan.a -m ${temp_dir}/${out_file_name}_tRNAscan/${out_file_name}.tRNAscan.b -c $tRNAscan_conf -B ${temp_dir}/${out_file_name}_tRNAscan_genome/${out_file_name}.f*a

		rm -rf $output_dir/${out_file_name}_tRNAscan
		mv ${temp_dir}/${out_file_name}_tRNAscan $output_dir
		if [ -f "${output_dir}/${out_file_name}_tRNAscan/${out_file_name}.tRNAscan.b" ]; then
			echo "tRNAscan successfully done."
		else
			echo "Errors was reported while running tRNAscan."
		fi
	fi
	###############################Rfam############################################################################################
	if [[ $i == "Rfam" ]]; then
		if [[ ! -d ${temp_dir}/${out_file_name}_Rfam ]]; then
			mkdir ${temp_dir}/${out_file_name}_Rfam
		else
			rm -rf ${temp_dir}/${out_file_name}_Rfam/*
		fi
		# 这里还要统计下RNA的类型，使用的方法是Rfam数据库
		# ----------------统计RNA类型：Begin---------------------------
		size=$(esl-seqstat $input | awk -F ':' '/Total.*residues.*/{print $2}' | sed 's/^[ \t]*//g')
		num=$(echo "scale=4;$size*2.0/1000000" | bc) #scale表示小数位数
		/data/public_tools/Infernal/infernal-1.1.2/bin/cmscan -Z $num --cut_ga --rfam --nohmmonly --tblout ${temp_dir}/${out_file_name}_Rfam/${file1}.tblout --fmt 2 --clanin /data/database/functional-database/Rfam/Rfam.clanin /data/database/functional-database/Rfam/Rfam.cm $input >${temp_dir}/${out_file_name}_Rfam/${file1}.cmscan
		awk 'BEGIN{OFS="\t";}{if(FNR==1) print "target_name\taccession\tquery_name\tquery_start\tquery_end\tstrand\tscore\tEvalue"; if(FNR>2 && $20!="=" && $0!~/^#/) print $2,$3,$4,$10,$11,$12,$17,$18; }' ${temp_dir}/${out_file_name}_Rfam/${file1}.tblout >${temp_dir}/${out_file_name}_Rfam/${file1}.tblout.final.xls
		awk 'NR==FNR{a[$1]=$1} NR>FNR{if($2 in a){print $0}}' /data/database/functional-database/Rfam/sRAN.list ${temp_dir}/${out_file_name}_Rfam/${file1}.tblout.final.xls >${temp_dir}/${out_file_name}_Rfam/${file1}.sRNA.xls
		# awk 'BEGIN{OFS=FS="\t"}ARGIND==1{a[$2]=$5;}ARGIND==2{type=a[$1]; if(type=="") type="Others"; count[type]+=1;}END{for(type in count) print type, count[type];}' /data/database/Rfam/Rfam_anno.txt ${temp_dir}/${out_file_name}_Rfam/${file1}.tblout.final.xls >${temp_dir}/${out_file_name}_Rfam/${file1}.RNATypes.txt
		# ----------------统计RNA类型：End---------------------------
		rm -rf $output_dir/${out_file_name}_Rfam
		mv ${temp_dir}/${out_file_name}_Rfam $output_dir
		if [ -f "${output_dir}/${out_file_name}_Rfam/${file1}.cmscan" ]; then
			echo "Rfam successfully done."
		else
			echo "Errors was reported while running Rfam."
		fi
	fi
	##########################prodigal################################################################################################
	if [[ $i == "prodigal" ]]; then
		if [[ ! -d ${temp_dir}/${out_file_name}_prodigal ]]; then
			mkdir ${temp_dir}/${out_file_name}_prodigal
		else
			rm -rf ${temp_dir}/${out_file_name}_prodigal/*
		fi
		/data/public_tools/prodigal/bin/prodigal -a ${temp_dir}/${out_file_name}_prodigal/${out_file_name}.faa -d ${temp_dir}/${out_file_name}_prodigal/${out_file_name}.fna -f gff -g 11 -p single -i $input -o ${temp_dir}/${out_file_name}_prodigal/${out_file_name}.gff -m
		rm -rf $output_dir/${out_file_name}_prodigal
		mv ${temp_dir}/${out_file_name}_prodigal $output_dir
		if [ -f "${output_dir}/${out_file_name}_prodigal/${out_file_name}.faa" ]; then
			echo "prodigal successfully done."
		else
			echo "Errors was reported while running prodigal."
		fi

	fi
	if [[ $i == "prodigal" ]]; then
		perl $perlDir/make_table.pl ${output_dir}  >${output_dir}/genome_info.txt
	fi
	#########################done#######################################################################################################
done
#############################about html#####################################################
#if [[ -s /home/wxc/161data_DSxxIMXXZXxx/script/structure_html.pl ]]; then
#	rm -rf /home/wxc/161data_DSxxIMXXZXxx/script/structure_html.pl
#fi

##################################whrite the html file######################################
#if [[ -d ${output_dir}/${out_file_name}_html/ ]]; then
#	rm -rf ${output_dir}/${out_file_name}_html/*
#else
#	mkdir ${output_dir}/${out_file_name}_html
#fi
#perl /home/wxc/161data_DSxxIMXXZXxx/script/structure_htm.pl $input ${output_dir}/${out_file_name} ${out_file_name} >${output_dir}/${out_file_name}_html/${out_file_name}.html
######################16s###########	
blastdb="/data/pipeline/database/16sdb/new/best.16s" #######need change
blastdbinfo="/data/pipeline/database/16sdb/new/species_stat.best.info" ##need change
perl $perlDir/get16sfasta.pl -rnammer ${output_dir}/${out_file_name}_RNAmmer/${out_file_name}.RNAmmer.fasta -outfile $output_dir/${out_file_name}_RNAmmer/${out_file_name}.RNAmmer.16s
if [ -s "$output_dir/${out_file_name}_RNAmmer/${out_file_name}.RNAmmer.16s" ]
then
	blastn -query $output_dir/${out_file_name}_RNAmmer/${out_file_name}.RNAmmer.16s -db $blastdb -outfmt 6 -num_threads 10 -evalue 1e-5 -max_hsps 1 -max_target_seqs 1 -out $output_dir/${out_file_name}_RNAmmer/${out_file_name}.RNAmmer.16s.blast.out
	perl $perlDir/get16s_anno.pl -blastinfo $blastdbinfo -blastout $output_dir/${out_file_name}_RNAmmer/${out_file_name}.RNAmmer.16s.blast.out -outfile $output_dir/16s_blast.result.xls
fi
##############################piper-cr##############################################################################
judge=`tail -2 $output_dir/${out_file_name}_piler-cr/${out_file_name}.pilercr.txt |grep 'putative'`
if [[ ! ${judge} =~ putative ]]
then
	perl $perlDir/piler-cr.pl -piler $output_dir/${out_file_name}_piler-cr/${out_file_name}.pilercr.txt -outfile $output_dir/${out_file_name}_piler-cr/${out_file_name}.pilercr.result
fi

##############################RNAmmer结果和tRNAscan结果和Rfam结果整理##########
perl $perlDir/rna.pl -inputdir $output_dir

################prodigal################################################################################################
perl $perlDir/gene_prodigal1.pl -gff $output_dir/${out_file_name}_prodigal/${out_file_name}.gff -fasta $output_dir/${out_file_name}.fasta -outfile $output_dir/${out_file_name}.gene.xls
Rscript $Rdir/gene_count.R inputfile=$output_dir/${out_file_name}_prodigal/${out_file_name}.gff outputfile=$output_dir/${out_file_name}.gene.png
################TRF##################
perl $perlDir/trf.pl -trf $output_dir/${out_file_name}_RepeatMasker/${file1}.2.7.7.80.10.50.500.dat  -fasta $output_dir/${out_file_name}.fasta -outfile $output_dir/${out_file_name}_RepeatMasker/${out_file_name}.trf.txt
