###############################################################################################################
###this script is for predicting genes of single bacteria genome and for functional annotation of the genes.
### if input_type is prodigal,usage: sh database_annotation.sh -database KEGG,COG,CARD,CAZy,antiSMASH,NR,PHI,Swiss-Prot,VFDB,Pfam,MetaCyc -input /xxx/xxx/xxx/xxx -input_type prodigal 
### if input_type is faa, usage: sh database_annotation.sh -database KEGG,COG,CARD,CAZy,antiSMASH,NR,PHI,Swiss-Prot,VFDB,Pfam,MetaCyc -input /xxx/xxx/xxx/xxx.f*a -input_type faa 
###############################################################################################################
while true; do
        case "$1" in	
				-database) database=$2; shift 2;;    	 	
				-output_dir) output_dir=$2; shift 2;;  
				-threads) threads=$2; shift 2;;	
				-input) input=$2; shift 2;;
				-temp_dir) temp_dir=$2; shift 2;;
				-input_type) input_type=$2; shift 2;; 
				-input_genome) input_genome=$2; shift 2;;
                *) break;
        esac
done

############software pathway###############
diamond=/data/public_tools/diamond/bin/diamond
perlDir=/data/pipeline/pipeline1/perl
Rdir=/data/pipeline/pipeline1/R
############ functional database seclection
if [ -n "$database" ];then
	array=(${database//,/ })
else
    echo "chose at least one functional database!" && exit 1
fi

############ set threads 
if [ ! -n "$threads" ];then
	threads=30
fi

########################################################################################################################################
################################################## input_type is prodigal ##############################################################

if [[ ${input_type} = "prodigal" ]];then

######################### read input file #############################
if [[ ${input} == */ ]];then
	file0=${input%/*}
	file1=${file0##*/}
    file2=${file1%%_prodigal}
else
	file1=${input##*/}
	file2=${file1%%_prodigal}
fi

############ appoint the output dir
if [ ! -n "$output_dir" ];then
	mkdir /data/result/typestrain/faa_output/${file2}
    output_dir=/data/result/typestrain/faa_output/${file2}
fi

############ temp_dir
if [ ! -n "$temp_dir" ];then
	mkdir /data/result/typestrain/faa_tempdir/${file2}
	temp_dir=/data/result/typestrain/faa_tempdir/${file2}
fi

if [ -f "${output_dir}/${file2}_functional_annotation.log" ];then
	rm ${output_dir}/${file2}_functional_annotation.log
fi

########################prodigal#######################################
if [[ ! -d ${temp_dir}/${file2}_Prodigal ]];then
	mkdir ${temp_dir}/${file2}_Prodigal
else
	rm -rf ${temp_dir}/${file2}_Prodigal/*
fi


############## process pep/cds file ###########

perl $perlDir/change_pep_id.pl $input/${file2}.fna ${temp_dir}/${file2}_Prodigal/${file2}.fna ${temp_dir}/${file2}_Prodigal/${file2}.fna-1
perl $perlDir/change_cds_id.pl $input/${file2}.faa ${temp_dir}/${file2}_Prodigal/${file2}.faa ${temp_dir}/${file2}_Prodigal/${file2}.faa-1
perl $perlDir/extract_pep_id.pl ${temp_dir}/${file2}_Prodigal/${file2}.faa ${temp_dir}/${file2}_Prodigal/${file2}.faa.info

##############################################start database annotation 
if [[ ! -d ${temp_dir}/${file2}_diamond ]];then
	mkdir ${temp_dir}/${file2}_diamond
else 
	rm -rf ${temp_dir}/${file2}_diamond/*
fi	
#############card database##################################
!
for i in  ${array[@]}
do
	if [[ $i = "CARD" ]];then
		CARDstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		CARDstartTime_s=$(date --date="$CARDstartTime" +%s)
		if [ ! -f "${temp_dir}/${file2}_diamond/CARD_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/CARD/CARD_pro.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/CARD_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/CARD_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/CARD/CARD_pro.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/CARD_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate CARD annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/CARD_diamond.txt" ];then
			echo ${file2} "CARD annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "CARD annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		CARDendTime=`date +'%Y-%m-%d %H:%M:%S'`
		CARDendTime_s=$(date --date="$CARDendTime" +%s)
		echo "CARD run time：$CARDstartTime ---> $CARDendTime "$((CARDendTime_s-CARDstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi
########################KEGG database##################################
	if [[ $i = "KEGG" ]];then
		KEGGstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		KEGGstartTime_s=$(date --date="$KEGGstartTime" +%s)
		if [ ! -f "${temp_dir}/${file2}_diamond/KEGG_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/KEGG/kegg-prokaryotes.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/KEGG_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/KEGG_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/KEGG/kegg-prokaryotes.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/KEGG_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate KEGG annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/KEGG_diamond.txt" ];then
			echo ${file2} "KEGG annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "KEGG annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		KEGGendTime=`date +'%Y-%m-%d %H:%M:%S'`
		KEGGendTime_s=$(date --date="$KEGGendTime" +%s)
		echo "KEGG run time：$KEGGstartTime ---> $KEGGendTime "$((KEGGendTime_s-KEGGstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi
########################COG database##################################
	if [[ $i = "COG" ]];then
		COGstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		COGstartTime_s=$(date --date="$COGstartTime" +%s)
		if [ ! -f "${temp_dir}/${file2}_diamond/COG_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/cog/cog.prot2003-2014.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/COG_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/COG_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/cog/cog.prot2003-2014.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/COG_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate COG annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/COG_diamond.txt" ];then
			echo ${file2} "COG annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "COG annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		COGendTime=`date +'%Y-%m-%d %H:%M:%S'`
		COGendTime_s=$(date --date="$COGendTime" +%s)
		echo "COG run time：$COGstartTime ---> $COGendTime "$((COGendTime_s-COGstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi	
########################antiSMASH database##################################
	if [[ $i = "antiSMASH" ]];then
		antiSMASHstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		antiSMASHstartTime_s=$(date --date="$antiSMASHstartTime" +%s)
		export PATH=/home/test/lvhy/software/miniconda2/bin/:$PATH
		mkdir ${output_dir}/${file2}_antiSMASH
		mkdir ${temp_dir}/${file2}_antiSMASH
		/home/test/lvhy/software/miniconda2/bin/antismash --taxon bacteria --input-type nucl -c 48 --clusterblast ${input_genome} --outputfolder ${temp_dir}/${file2}_antiSMASH
		cp ${temp_dir}/${file2}_antiSMASH/*zip ${output_dir}/${file2}_antiSMASH

		antiSMASHendTime=`date +'%Y-%m-%d %H:%M:%S'`
		antiSMASHendTime_s=$(date --date="$antiSMASHendTime" +%s)
		echo "antiSMASH run time：$antiSMASHstartTime ---> $antiSMASHendTime "$((antiSMASHendTime_s-antiSMASHstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi	
		
########################MetaCyc database##################################
	if [[ $i = "MetaCyc" ]];then
		MetaCycstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		MetaCycstartTime_s=$(date --date="$MetaCycstartTime" +%s)
		if [ ! -f "${temp_dir}/${file2}_diamond/MetaCyc_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/metacyc/metacyc.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/MetaCyc_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/MetaCyc_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/metacyc/metacyc.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/MetaCyc_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate MetaCyc annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/MetaCyc_diamond.txt" ];then
			echo ${file2} "MetaCyc annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "MetaCyc annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		MetaCycendTime=`date +'%Y-%m-%d %H:%M:%S'`
		MetaCycendTime_s=$(date --date="$MetaCycendTime" +%s)
		echo "MetaCyc run time：$MetaCycstartTime ---> $MetaCycendTime "$((MetaCycendTime_s-MetaCycstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi	
			
########################NR database##################################
	if [[ $i = "NR" ]];then
		NRstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		NRstartTime_s=$(date --date="$NRstartTime" +%s)
		if [ ! -f "${temp_dir}/${file2}_diamond/NR_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/nr/nr.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/NR_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/NR_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/nr/nr.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/NR_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate NR annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/NR_diamond.txt" ];then
			echo ${file2} "NR annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "NR annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		NRendTime=`date +'%Y-%m-%d %H:%M:%S'`
		NRendTime_s=$(date --date="$NRendTime" +%s)
		echo "NR run time：$NRstartTime ---> $NRendTime "$((NRendTime_s-NRstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi	
	
########################CAZy database##################################
	if [[ $i = "CAZy" ]];then
		CAZystartTime=`date +'%Y-%m-%d %H:%M:%S'`
		CAZystartTime_s=$(date --date="$CAZystartTime" +%s)
		if [ ! -f "${temp_dir}/${file2}_diamond/CAZy_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/CAZy/CAZy.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/CAZy_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/CAZy_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/CAZy/CAZy.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/CAZy_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate CAZy annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/CAZy_diamond.txt" ];then
			echo ${file2} "CAZy annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "CAZy annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		CAZyendTime=`date +'%Y-%m-%d %H:%M:%S'`
		CAZyendTime_s=$(date --date="$CAZyendTime" +%s)
		echo "CAZy run time：$CAZystartTime ---> $CAZyendTime "$((CAZyendTime_s-CAZystartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi		
########################PHI database##################################
	if [[ $i = "PHI" ]];then
		PHIstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		PHIstartTime_s=$(date --date="$PHIstartTime" +%s)
		if [ ! -f "${temp_dir}/${file2}_diamond/PHI_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/PHI/phi45.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/PHI_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/PHI_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/PHI/phi45.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/PHI_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate PHI annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/PHI_diamond.txt" ];then
			echo ${file2} "PHI annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "PHI annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		PHIendTime=`date +'%Y-%m-%d %H:%M:%S'`
		PHIendTime_s=$(date --date="$PHIendTime" +%s)
		echo "PHI run time：$PHIstartTime ---> $PHIendTime "$((PHIendTime_s-PHIstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi	
########################VFDB database##################################
	if [[ $i = "VFDB" ]];then
		VFDBstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		VFDBstartTime_s=$(date --date="$VFDBstartTime" +%s)
		if [ ! -f "${temp_dir}/${file2}_diamond/VFDB_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/VFDB/VFDB_setB_pro.manul.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/VFDB_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/VFDB_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/VFDB/VFDB_setB_pro.manul.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/VFDB_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate VFDB annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/VFDB_diamond.txt" ];then
			echo ${file2} "VFDB annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "VFDB annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		VFDBendTime=`date +'%Y-%m-%d %H:%M:%S'`
		VFDBendTime_s=$(date --date="$VFDBendTime" +%s)
		echo "VFDB run time：$VFDBstartTime ---> $VFDBendTime "$((VFDBendTime_s-VFDBstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi			
########################Pfam database##################################
	if [[ $i = "Pfam" ]];then
		PfamstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		PfamstartTime_s=$(date --date="$PfamstartTime" +%s)
		if [ ! -f "${temp_dir}/${file2}_diamond/Pfam_diamond.txt" ];then
			export PATH="/data/public_tools/pfamscan/bin/":$PATH
			/data/public_tools/pfamscan/bin/pfam_scan.pl -fasta ${temp_dir}/${file2}_Prodigal/${file2}.faa -dir /data/database/functional-database/pfam/ -outfile ${temp_dir}/${file2}_diamond/Pfam_diamond.txt -cpu 48
		else
			rm ${temp_dir}/${file2}_diamond/Pfam_diamond.txt
			/data/public_tools/pfamscan/bin/pfam_scan.pl -fasta ${temp_dir}/${file2}_Prodigal/${file2}.faa -dir /data/database/functional-database/pfam/ -outfile ${temp_dir}/${file2}_diamond/Pfam_diamond.txt -cpu 48
		fi
		less ${temp_dir}/${file2}_diamond/Pfam_diamond.txt |awk -F ' ' '{if($0~/^gene/) print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10"\t"$11"\t"$12"\t"$13"\t"$14"\t"$15}' >${temp_dir}/${file2}_diamond/Pfam_diamond.txt-1;
		mv ${temp_dir}/${file2}_diamond/Pfam_diamond.txt-1 ${temp_dir}/${file2}_diamond/Pfam_diamond.txt
		############## estimate Pfam annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/Pfam_diamond.txt" ];then
			echo ${file2} "Pfam annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "Pfam annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		PfamendTime=`date +'%Y-%m-%d %H:%M:%S'`
		PfamendTime_s=$(date --date="$PfamendTime" +%s)
		echo "Pfam run time：$PfamstartTime ---> $PfamendTime "$((PfamendTime_s-PfamstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi
	
########################Swiss-Prot database##################################
	if [[ $i = "Swiss-Prot" ]];then
		Swiss_ProtstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		Swiss_ProtstartTime_s=$(date --date="$Swiss_ProtstartTime" +%s)
		if [ ! -f "${temp_dir}/${file2}_diamond/Swiss-Prot_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/uniprotkb-swiissprot/uniprot_swissprot.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/Swiss-Prot_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/Swiss-Prot_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/uniprotkb-swiissprot/uniprot_swissprot.dmnd -q ${temp_dir}/${file2}_Prodigal/${file2}.faa -o ${temp_dir}/${file2}_diamond/Swiss-Prot_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate Swiss-Prot annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/Swiss-Prot_diamond.txt" ];then
			echo ${file2} "Swiss-Prot annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "Swiss-Prot annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		Swiss_ProtendTime=`date +'%Y-%m-%d %H:%M:%S'`
		Swiss_ProtendTime_s=$(date --date="$Swiss_ProtendTime" +%s)
		echo "Swiss-Prot run time：$Swiss_ProtstartTime ---> $Swiss_ProtendTime "$((Swiss_ProtendTime_s-Swiss_ProtstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi					
done

if [[ ! -d ${temp_dir}/${file2}_tables ]];then
	mkdir ${temp_dir}/${file2}_tables
else
	rm -rf ${temp_dir}/${file2}_tables
	mkdir ${temp_dir}/${file2}_tables
fi

for i in  ${array[@]}
do
	tablestartTime=`date +'%Y-%m-%d %H:%M:%S'`
	tablestartTime_s=$(date --date="$tablestartTime" +%s)

	if [[ $i = "CARD" ]];then
	perl $perlDir/card.pl ${temp_dir}/${file2}_diamond/CARD_diamond.txt ${temp_dir}/${file2}_tables/CARD_table.txt.temp ${temp_dir}/${file2}_Prodigal/${file2}.faa.info ${temp_dir}/${file2}_tables/CARD_table.txt
	fi

	if [[ $i = "CAZy" ]];then
	perl $perlDir/cazy.pl ${temp_dir}/${file2}_diamond/CAZy_diamond.txt ${temp_dir}/${file2}_tables/CAZy_table.txt.temp ${temp_dir}/${file2}_Prodigal/${file2}.faa.info ${temp_dir}/${file2}_tables/CAZy_table.txt
	fi
	
	if [[ $i = "COG" ]];then
	perl $perlDir/cog.pl ${temp_dir}/${file2}_diamond/COG_diamond.txt ${temp_dir}/${file2}_tables/COG_table.txt.temp ${temp_dir}/${file2}_Prodigal/${file2}.faa.info ${temp_dir}/${file2}_tables/COG_table.txt
	fi

	if [[ $i = "KEGG" ]];then
	perl $perlDir/kegg.pl /data/result/typestrain/faa_script/GCM_database_annotation_perl/database_anno_info/prokaryotes.dat ${temp_dir}/${file2}_diamond/KEGG_diamond.txt ${temp_dir}/${file2}_Prodigal/${file2}.faa.info ${temp_dir}/${file2}_tables/KEGG_table.txt
	fi

	if [[ $i = "MetaCyc" ]];then
	perl $perlDir/metacyc.pl ${temp_dir}/${file2}_diamond/MetaCyc_diamond.txt ${temp_dir}/${file2}_tables/MetaCyc_table.txt.temp ${temp_dir}/${file2}_Prodigal/${file2}.faa.info ${temp_dir}/${file2}_tables/MetaCyc_table.txt
	fi
	
	if [[ $i = "NR" ]];then
	perl $perlDir/nr.pl ${temp_dir}/${file2}_diamond/NR_diamond.txt ${temp_dir}/${file2}_tables/NR_table.txt.temp ${temp_dir}/${file2}_Prodigal/${file2}.faa.info ${temp_dir}/${file2}_tables/NR_table.txt
	fi
	
	if [[ $i = "Pfam" ]];then
	perl $perlDir/pfam.pl ${temp_dir}/${file2}_diamond/Pfam_diamond.txt ${temp_dir}/${file2}_Prodigal/${file2}.faa.info ${temp_dir}/${file2}_tables/Pfam_table.txt
	fi
	
	if [[ $i = "PHI" ]];then
	perl $perlDir/phi.pl ${temp_dir}/${file2}_diamond/PHI_diamond.txt ${temp_dir}/${file2}_tables/PHI_table.txt.temp ${temp_dir}/${file2}_Prodigal/${file2}.faa.info ${temp_dir}/${file2}_tables/PHI_table.txt
	fi
	
	if [[ $i = "Swiss-Prot" ]];then
	perl $perlDir/uniprot.pl ${temp_dir}/${file2}_diamond/Swiss-Prot_diamond.txt ${temp_dir}/${file2}_tables/Swiss-Prot_table.txt.temp ${temp_dir}/${file2}_Prodigal/${file2}.faa.info ${temp_dir}/${file2}_tables/Swiss-Prot_table.txt
	fi

	if [[ $i = "VFDB" ]];then
	perl $perlDir/vfdb.pl ${temp_dir}/${file2}_diamond/VFDB_diamond.txt ${temp_dir}/${file2}_tables/VFDB_table.txt.temp ${temp_dir}/${file2}_Prodigal/${file2}.faa.info ${temp_dir}/${file2}_tables/VFDB_table.txt
	fi
	tableendTime=`date +'%Y-%m-%d %H:%M:%S'`
	tableendTime_s=$(date --date="$tableendTime" +%s)
	echo "tables run time：$tablestartTime ---> $tableendTime "$((tableendTime_s-tablestartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
done

perl $perlDir/fna_faa_html.pl ${temp_dir}/${file2}_Prodigal/${file2}.fna ${temp_dir}/${file2}_tables/fna.file ${temp_dir}/${file2}_Prodigal/${file2}.faa ${temp_dir}/${file2}_tables/faa.file ${temp_dir}/${file2}_tables/fna.file.html ${temp_dir}/${file2}_tables/faa.file.html ${temp_dir}/${file2}_tables/fna.html ${temp_dir}/${file2}_tables/faa.html

perl $perlDir/html.pl ${temp_dir}/${file2}_tables/KEGG_table.txt ${temp_dir}/${file2}_tables/COG_table.txt ${temp_dir}/${file2}_tables/antiSMASH_table.txt ${temp_dir}/${file2}_tables/CARD_table.txt ${temp_dir}/${file2}_tables/CAZy_table.txt ${temp_dir}/${file2}_tables/MetaCyc_table.txt ${temp_dir}/${file2}_tables/NR_table.txt ${temp_dir}/${file2}_tables/PHI_table.txt ${temp_dir}/${file2}_tables/Swiss-Prot_table.txt ${temp_dir}/${file2}_tables/VFDB_table.txt ${temp_dir}/${file2}_tables/Pfam_table.txt ${temp_dir}/${file2}_Prodigal/${file2}.faa.info ${temp_dir}/${file2}_tables/function_annotation.html

if [ -f "${temp_dir}/${file2}_tables/ratio.txt" ];then
	rm ${temp_dir}/${file2}_tables/ratio.txt
fi
total=`grep '>' ${temp_dir}/${file2}_Prodigal/${file2}.faa |wc -l`
echo "Total	$total">>${temp_dir}/${file2}_tables/ratio.txt

for i in  ${array[@]}
do
	if [[ $i = "CARD" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/CARD_table.txt >${temp_dir}/${file2}_tables/CARD_ratio.txt
	awk '{print "CARD""\t"$0}' ${temp_dir}/${file2}_tables/CARD_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/CARD_ratio.txt
	fi
	
	
	if [[ $i = "KEGG" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/KEGG_table.txt >${temp_dir}/${file2}_tables/KEGG_ratio.txt
	awk '{print "KEGG""\t"$0}' ${temp_dir}/${file2}_tables/KEGG_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/KEGG_ratio.txt
	fi
	
	if [[ $i = "COG" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/COG_table.txt >${temp_dir}/${file2}_tables/COG_ratio.txt
	awk '{print "COG""\t"$0}' ${temp_dir}/${file2}_tables/COG_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/COG_ratio.txt
	fi
	
	if [[ $i = "NR" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/NR_table.txt >${temp_dir}/${file2}_tables/NR_ratio.txt
	awk '{print "NR""\t"$0}' ${temp_dir}/${file2}_tables/NR_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/NR_ratio.txt
	fi
	
	if [[ $i = "PHI" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/PHI_table.txt >${temp_dir}/${file2}_tables/PHI_ratio.txt
	awk '{print "PHI""\t"$0}' ${temp_dir}/${file2}_tables/PHI_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/PHI_ratio.txt
	fi
	
	if [[ $i = "Pfam" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/Pfam_table.txt >${temp_dir}/${file2}_tables/Pfam_ratio.txt
	awk '{print "Pfam""\t"$0}' ${temp_dir}/${file2}_tables/Pfam_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/Pfam_ratio.txt
	fi

	if [[ $i = "Swiss-Prot" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/Swiss-Prot_table.txt >${temp_dir}/${file2}_tables/Swiss-Prot_ratio.txt
	awk '{print "Swiss-Prot""\t"$0}' ${temp_dir}/${file2}_tables/Swiss-Prot_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/Swiss-Prot_ratio.txt
	fi
	
	if [[ $i = "VFDB" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/VFDB_table.txt >${temp_dir}/${file2}_tables/VFDB_ratio.txt
	awk '{print "VFDB""\t"$0}' ${temp_dir}/${file2}_tables/VFDB_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/VFDB_ratio.txt
	fi
	
	if [[ $i = "MetaCyc" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/MetaCyc_table.txt >${temp_dir}/${file2}_tables/MetaCyc_ratio.txt
	awk '{print "MetaCyc""\t"$0}' ${temp_dir}/${file2}_tables/MetaCyc_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/MetaCyc_ratio.txt
	fi
	
	if [[ $i = "CAZy" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/CAZy_table.txt >${temp_dir}/${file2}_tables/CAZy_ratio.txt
	awk '{print "CAZy""\t"$0}' ${temp_dir}/${file2}_tables/CAZy_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/CAZy_ratio.txt
	fi
done

if [[ ! -d ${output_dir}/${file2}_figure ]];then
        mkdir ${output_dir}/${file2}_figure
else
        rm -rf ${output_dir}/${file2}_figure
        mkdir ${output_dir}/${file2}_figure
fi

export PATH=/data/public_tools/R/bin:$PATH
for i in  ${array[@]}
do
if [[ $i = "CARD" && -s ${temp_dir}/${file2}_diamond/CARD_diamond.txt ]];then
perl $perlDir/CARD-classification.pl ${temp_dir}/${file2}_diamond/CARD_diamond.txt >${output_dir}/${file2}_figure/CARD.txt
	card1=`grep CARD ${temp_dir}/${file2}_tables/ratio.txt |awk '{print $2}'`
	card2=`wc -l ${output_dir}/${file2}_figure/CARD.txt|awk '{print $1}'`
	Rscript /$Rdir/CARD-classification.R ${output_dir}/${file2}_figure/ CARD.txt
fi
if [[ $i = "COG" && -s ${temp_dir}/${file2}_diamond/COG_diamond.txt ]];then
perl $perlDir/cog-classification.pl ${temp_dir}/${file2}_diamond/COG_diamond.txt >${output_dir}/${file2}_figure/COG.txt
	cog1=`grep COG ${temp_dir}/${file2}_tables/ratio.txt |awk '{print $3}'`
	cog2=`wc -l ${output_dir}/${file2}_figure/COG.txt|awk '{print $1}'`
	Rscript $Rdir/cog-classification.R ${output_dir}/${file2}_figure/ COG.txt
fi
if [[ $i = "KEGG" && -s ${temp_dir}/${file2}_diamond/KEGG_diamond.txt ]];then
perl $perlDir/kegg-classification.pl ${temp_dir}/${file2}_diamond/KEGG_diamond.txt >${output_dir}/${file2}_figure/KEGG.txt
	kegg1=`grep KEGG ${temp_dir}/${file2}_tables/ratio.txt |awk '{print $3}'`
	kegg2=`wc -l ${output_dir}/${file2}_figure/KEGG.txt|awk '{print $1}'`
	Rscript $Rdir/KEGG-classification.R ${output_dir}/${file2}_figure/ KEGG.txt
fi
done

perl $perlDir/ratio_html.pl ${temp_dir}/${file2}_tables/ratio.txt ${output_dir}/${file2}_ratio.html

if [[ ! -d ${output_dir}/${file2}_diamond ]];then
        mkdir ${output_dir}/${file2}_diamond
else
        rm -rf ${output_dir}/${file2}_diamond
        mkdir ${output_dir}/${file2}_diamond
fi

if [[ ! -d ${output_dir}/${file2}_tables ]];then
        mkdir ${output_dir}/${file2}_tables
else
        rm -rf ${output_dir}/${file2}_tables
        mkdir ${output_dir}/${file2}_tables
fi

if [[ ! -d ${output_dir}/${file2}_htmls ]];then
        mkdir ${output_dir}/${file2}_htmls
else
        rm -rf ${output_dir}/${file2}_htmls
        mkdir ${output_dir}/${file2}_htmls
fi

for i in ${array[@]}
do
if [[ -s ${temp_dir}/${file2}_tables/${i}_table.txt ]];then
awk '{if($0 !~ /NA$/)print $0}'  ${temp_dir}/${file2}_tables/${i}_table.txt > ${temp_dir}/${file2}_tables/${i}_table-1.txt
mv ${temp_dir}/${file2}_tables/${i}_table-1.txt ${temp_dir}/${file2}_tables/${i}_table.txt
fi
done

cp ${temp_dir}/${file2}_tables/*.html ${output_dir}/${file2}_htmls
cp ${temp_dir}/${file2}_diamond/* ${output_dir}/${file2}_diamond
cp ${temp_dir}/${file2}_tables/*.txt ${output_dir}/${file2}_tables
cp ${temp_dir}/${file2}_Prodigal/${file2}.faa.info ${output_dir}/${file2}_tables
mv ${output_dir}/${file2}_ratio.html ${output_dir}/${file2}_htmls/ratio.html
echo "ALL processes were DONE!" >> ${output_dir}/${file2}_functional_annotation.log
fi

#############################################################################################################
############################################ input_type is faa###############################################
if [[ ${input_type} = "faa" ]];then

file1=${input##*/}
file2=${file1%_protein*}

############ appoint the output dir########################
if [ ! -n "$output_dir" ];then
#	mkdir /data/result/typestrain/faa_output/${file2}
	output_dir=/data/result/typestrain/faa_output/${file2}
fi

############ temp_dir#####################################
if [ ! -n "$temp_dir" ];then
#	mkdir /data/result/typestrain/faa_tempdir/${file2}
	temp_dir=/data/result/typestrain/faa_tempdir/${file2}
fi

if [ -s "${output_dir}/${file2}_functional_annotation.log" ];then
	rm ${output_dir}/${file2}_functional_annotation.log
fi

#######################diamond file#######################
if [[ ! -d ${temp_dir}/${file2}_diamond ]];then
	mkdir ${temp_dir}/${file2}_diamond
else 
	rm -rf ${temp_dir}/${file2}_diamond/*
fi	


for i in  ${array[@]}
do
	if [[ $i = "CARD" ]];then
		CARDstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		CARDstartTime_s=$(date --date="$CARDstartTime" +%s)
		if [ ! -e "${temp_dir}/${file2}_diamond/CARD_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/CARD/CARD_pro.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/CARD_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/CARD_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/CARD/CARD_pro.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/CARD_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate CARD annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/CARD_diamond.txt" ];then
			echo ${file2} "CARD annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "CARD annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		CARDendTime=`date +'%Y-%m-%d %H:%M:%S'`
		CARDendTime_s=$(date --date="$CARDendTime" +%s)
		echo "CARD run time：$CARDstartTime ---> $CARDendTime "$((CARDendTime_s-CARDstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi
########################KEGG database##################################
	if [[ $i = "KEGG" ]];then
		KEGGstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		KEGGstartTime_s=$(date --date="$KEGGstartTime" +%s)
		if [ ! -e "${temp_dir}/${file2}_diamond/KEGG_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/KEGG/kegg-prokaryotes.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/KEGG_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/KEGG_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/KEGG/kegg-prokaryotes.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/KEGG_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate KEGG annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/KEGG_diamond.txt" ];then
			echo ${file2} "KEGG annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "KEGG annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		KEGGendTime=`date +'%Y-%m-%d %H:%M:%S'`
		KEGGendTime_s=$(date --date="$KEGGendTime" +%s)
		echo "KEGG run time：$KEGGstartTime ---> $KEGGendTime "$((KEGGendTime_s-KEGGstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi
########################COG database##################################
	if [[ $i = "COG" ]];then
		COGstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		COGstartTime_s=$(date --date="$COGstartTime" +%s)
		if [ ! -e "${temp_dir}/${file2}_diamond/COG_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/cog/cog.prot2003-2014.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/COG_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/COG_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/cog/cog.prot2003-2014.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/COG_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate COG annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/COG_diamond.txt" ];then
			echo ${file2} "COG annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "COG annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		COGendTime=`date +'%Y-%m-%d %H:%M:%S'`
		COGendTime_s=$(date --date="$COGendTime" +%s)
		echo "COG run time：$COGstartTime ---> $COGendTime "$((COGendTime_s-COGstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi	
########################antiSMASH database##################################
	if [[ $i = "antiSMASH" ]];then
		mkdir ${output_dir}/${file2}_antiSMASH
		mkdir ${temp_dir}/${file2}_antiSMASH
		export PATH=/home/test/lvhy/software/miniconda2/bin/:$PATH
		/home/test/lvhy/software/miniconda2/bin/antismash --taxon bacteria --input-type nucl -c 48 --clusterblast ${input_genome} --outputfolder ${temp_dir}/${file2}_antiSMASH
		cp ${temp_dir}/${file2}_antiSMASH/*zip ${output_dir}/${file2}_antiSMASH
	fi

########################MetaCyc database##################################
	if [[ $i = "MetaCyc" ]];then
		MetaCycstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		MetaCycstartTime_s=$(date --date="$MetaCycstartTime" +%s)
		if [ ! -e "${temp_dir}/${file2}_diamond/MetaCyc_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/metacyc/metacyc.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/MetaCyc_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/MetaCyc_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/metacyc/metacyc.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/MetaCyc_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate MetaCyc annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/MetaCyc_diamond.txt" ];then
			echo ${file2} "MetaCyc annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "MetaCyc annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		MetaCycendTime=`date +'%Y-%m-%d %H:%M:%S'`
		MetaCycendTime_s=$(date --date="$MetaCycendTime" +%s)
		echo "MetaCyc run time：$MetaCycstartTime ---> $MetaCycendTime "$((MetaCycendTime_s-MetaCycstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi	
			
########################NR database##################################
	if [[ $i = "NR" ]];then
		NRstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		NRstartTime_s=$(date --date="$NRstartTime" +%s)
		if [ ! -e "${temp_dir}/${file2}_diamond/NR_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/nr/nr.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/NR_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/NR_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/nr/nr.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/NR_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate NR annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/NR_diamond.txt" ];then
			echo ${file2} "NR annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "NR annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		NRendTime=`date +'%Y-%m-%d %H:%M:%S'`
		NRendTime_s=$(date --date="$NRendTime" +%s)
		echo "NR run time：$NRstartTime ---> $NRendTime "$((NRendTime_s-NRstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi	
	
########################CAZy database##################################
	if [[ $i = "CAZy" ]];then
		CAZystartTime=`date +'%Y-%m-%d %H:%M:%S'`
		CAZystartTime_s=$(date --date="$CAZystartTime" +%s)
		if [ ! -e "${temp_dir}/${file2}_diamond/CAZy_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/CAZy/CAZy.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/CAZy_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/CAZy_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/CAZy/CAZy.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/CAZy_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate CAZy annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/CAZy_diamond.txt" ];then
			echo ${file2} "CAZy annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "CAZy annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		CAZyendTime=`date +'%Y-%m-%d %H:%M:%S'`
		CAZyendTime_s=$(date --date="$CAZyendTime" +%s)
		echo "CAZy run time：$CAZystartTime ---> $CAZyendTime "$((CAZyendTime_s-CAZystartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi		
########################PHI database##################################
	if [[ $i = "PHI" ]];then
		PHIstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		PHIstartTime_s=$(date --date="$PHIstartTime" +%s)
		if [ ! -e "${temp_dir}/${file2}_diamond/PHI_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/PHI/phi45.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/PHI_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/PHI_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/PHI/phi45.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/PHI_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate PHI annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/PHI_diamond.txt" ];then
			echo ${file2} "PHI annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "PHI annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		PHIendTime=`date +'%Y-%m-%d %H:%M:%S'`
		PHIendTime_s=$(date --date="$PHIendTime" +%s)
		echo "PHI run time：$PHIstartTime ---> $PHIendTime "$((PHIendTime_s-PHIstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi	
########################VFDB database##################################
	if [[ $i = "VFDB" ]];then
		VFDBstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		VFDBstartTime_s=$(date --date="$VFDBstartTime" +%s)
		if [ ! -e "${temp_dir}/${file2}_diamond/VFDB_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/VFDB/VFDB_setB_pro.manul.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/VFDB_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/VFDB_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/VFDB/VFDB_setB_pro.manul.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/VFDB_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate VFDB annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/VFDB_diamond.txt" ];then
			echo ${file2} "VFDB annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "VFDB annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		VFDBendTime=`date +'%Y-%m-%d %H:%M:%S'`
		VFDBendTime_s=$(date --date="$VFDBendTime" +%s)
		echo "VFDB run time：$VFDBstartTime ---> $VFDBendTime "$((VFDBendTime_s-VFDBstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi			
########################Pfam database##################################
	if [[ $i = "Pfam" ]];then
		PfamstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		PfamstartTime_s=$(date --date="$PfamstartTime" +%s)
		if [ ! -e "${temp_dir}/${file2}_diamond/Pfam_diamond.txt" ];then
			export PATH="/data/public_tools/pfamscan/bin/":$PATH
			/data/public_tools/pfamscan/bin/pfam_scan.pl -fasta ${input} -dir /data/database/functional-database/pfam/ -outfile ${temp_dir}/${file2}_diamond/Pfam_diamond.txt -cpu 48
		else
			rm ${temp_dir}/${file2}_diamond/Pfam_diamond.txt
			export PATH="/data/public_tools/pfamscan/bin/":$PATH
			/data/public_tools/pfamscan/bin/pfam_scan.pl -fasta ${input} -dir /data/database/functional-database/pfam/ -outfile ${temp_dir}/${file2}_diamond/Pfam_diamond.txt -cpu 48
		fi
		less ${temp_dir}/${file2}_diamond/Pfam_diamond.txt |awk -F ' ' '{if($0~/^[0-9a-zA-Z]/) print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10"\t"$11"\t"$12"\t"$13"\t"$14"\t"$15}' >${temp_dir}/${file2}_diamond/Pfam_diamond.txt-1;
		mv ${temp_dir}/${file2}_diamond/Pfam_diamond.txt-1 ${temp_dir}/${file2}_diamond/Pfam_diamond.txt
		############## estimate Pfam annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/Pfam_diamond.txt" ];then
			echo ${file2} "Pfam annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "Pfam annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		PfamendTime=`date +'%Y-%m-%d %H:%M:%S'`
		PfamendTime_s=$(date --date="$PfamendTime" +%s)
		echo "Pfam run time：$PfamstartTime ---> $PfamendTime "$((PfamendTime_s-PfamstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi

########################Swiss-Prot database##################################
	if [[ $i = "Swiss-Prot" ]];then
		Swiss_ProtstartTime=`date +'%Y-%m-%d %H:%M:%S'`
		Swiss_ProtstartTime_s=$(date --date="$Swiss_ProtstartTime" +%s)
		if [ ! -e "${temp_dir}/${file2}_diamond/Swiss-Prot_diamond.txt" ];then
			$diamond blastp -p 48 -d /data/database/functional-database/uniprotkb-swiissprot/uniprot_swissprot.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/Swiss-Prot_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		else
			rm ${temp_dir}/${file2}_diamond/Swiss-Prot_diamond.txt
			$diamond blastp -p 48 -d /data/database/functional-database/uniprotkb-swiissprot/uniprot_swissprot.dmnd -q ${input} -o ${temp_dir}/${file2}_diamond/Swiss-Prot_diamond.txt -e 1e-5 -k 1 --max-hsps 1 --id 40 --query-cover 40 --subject-cover 40
		fi
		############## estimate Swiss-Prot annotation exists or not #########
		if [ -f "${temp_dir}/${file2}_diamond/Swiss-Prot_diamond.txt" ];then
			echo ${file2} "Swiss-Prot annotation was done!" >> ${output_dir}/${file2}_functional_annotation.log
		else
			echo ${file2} "Swiss-Prot annotation was WRONG!" >> ${output_dir}/${file2}_functional_annotation.log
		fi
		Swiss_ProtendTime=`date +'%Y-%m-%d %H:%M:%S'`
		Swiss_ProtendTime_s=$(date --date="$Swiss_ProtendTime" +%s)
		echo "Swiss-Prot run time：$Swiss_ProtstartTime ---> $Swiss_ProtendTime "$((Swiss_ProtendTime_s-Swiss_ProtstartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log
	fi					
done

if [[ ! -d ${temp_dir}/${file2}_tables ]];then
	mkdir ${temp_dir}/${file2}_tables
else
	rm -rf ${temp_dir}/${file2}_tables/*
#	mkdir ${temp_dir}/${file2}_tables
fi

awk  '{if($0~/^>/)print}' ${input} | awk -F ' ' '{print $1"\t"$1}' >${temp_dir}/${file2}_tables/${file2}.faa.info
sed -i 's/>//g' ${temp_dir}/${file2}_tables/${file2}.faa.info

tablestartTime=`date +'%Y-%m-%d %H:%M:%S'`
tablestartTime_s=$(date --date="$tablestartTime" +%s)


for i in  ${array[@]}
do	





	if [[ $i = "CARD" ]];then
	perl $perlDir/card.pl ${temp_dir}/${file2}_diamond/CARD_diamond.txt ${temp_dir}/${file2}_tables/CARD_table.txt.temp ${temp_dir}/${file2}_tables/${file2}.faa.info ${temp_dir}/${file2}_tables/CARD_table.txt
	fi

	if [[ $i = "CAZy" ]];then
	perl $perlDir/cazy.pl ${temp_dir}/${file2}_diamond/CAZy_diamond.txt ${temp_dir}/${file2}_tables/CAZy_table.txt.temp ${temp_dir}/${file2}_tables/${file2}.faa.info ${temp_dir}/${file2}_tables/CAZy_table.txt
	fi
	
	if [[ $i = "COG" ]];then
	perl $perlDir/cog.pl ${temp_dir}/${file2}_diamond/COG_diamond.txt ${temp_dir}/${file2}_tables/COG_table.txt.temp ${temp_dir}/${file2}_tables/${file2}.faa.info ${temp_dir}/${file2}_tables/COG_table.txt
	fi

	if [[ $i = "KEGG" ]];then
	perl $perlDir/kegg.pl /data/result/typestrain/faa_script/GCM_database_annotation_perl/database_anno_info/prokaryotes.dat ${temp_dir}/${file2}_diamond/KEGG_diamond.txt ${temp_dir}/${file2}_tables/${file2}.faa.info ${temp_dir}/${file2}_tables/KEGG_table.txt
	fi

	if [[ $i = "MetaCyc" ]];then
	perl $perlDir/metacyc.pl ${temp_dir}/${file2}_diamond/MetaCyc_diamond.txt ${temp_dir}/${file2}_tables/MetaCyc_table.txt.temp ${temp_dir}/${file2}_tables/${file2}.faa.info ${temp_dir}/${file2}_tables/MetaCyc_table.txt
	fi
	
	if [[ $i = "NR" ]];then
	perl $perlDir/nr.pl ${temp_dir}/${file2}_diamond/NR_diamond.txt ${temp_dir}/${file2}_tables/NR_table.txt.temp ${temp_dir}/${file2}_tables/${file2}.faa.info ${temp_dir}/${file2}_tables/NR_table.txt
	fi
	
	if [[ $i = "Pfam" ]];then
	perl $perlDir/pfam.pl ${temp_dir}/${file2}_diamond/Pfam_diamond.txt ${temp_dir}/${file2}_tables/${file2}.faa.info ${temp_dir}/${file2}_tables/Pfam_table.txt
	fi
	
	if [[ $i = "PHI" ]];then
	perl $perlDir/phi.pl ${temp_dir}/${file2}_diamond/PHI_diamond.txt ${temp_dir}/${file2}_tables/PHI_table.txt.temp ${temp_dir}/${file2}_tables/${file2}.faa.info ${temp_dir}/${file2}_tables/PHI_table.txt
	fi
	
	if [[ $i = "Swiss-Prot" ]];then
	perl $perlDir/uniprot.pl ${temp_dir}/${file2}_diamond/Swiss-Prot_diamond.txt ${temp_dir}/${file2}_tables/Swiss-Prot_table.txt.temp ${temp_dir}/${file2}_tables/${file2}.faa.info ${temp_dir}/${file2}_tables/Swiss-Prot_table.txt
	fi

	if [[ $i = "VFDB" ]];then
	perl $perlDir/vfdb.pl ${temp_dir}/${file2}_diamond/VFDB_diamond.txt ${temp_dir}/${file2}_tables/VFDB_table.txt.temp ${temp_dir}/${file2}_tables/${file2}.faa.info ${temp_dir}/${file2}_tables/VFDB_table.txt
	fi
done

tableendTime=`date +'%Y-%m-%d %H:%M:%S'`
tableendTime_s=$(date --date="$tableendTime" +%s)
echo "tables run time：$tablestartTime ---> $tableendTime "$((tableendTime_s-tablestartTime_s))"s" >>${output_dir}/${file2}_functional_annotation.log

perl $perlDir/html.pl ${temp_dir}/${file2}_tables/KEGG_table.txt ${temp_dir}/${file2}_tables/COG_table.txt ${temp_dir}/${file2}_tables/antiSMASH_table.txt ${temp_dir}/${file2}_tables/CARD_table.txt ${temp_dir}/${file2}_tables/CAZy_table.txt ${temp_dir}/${file2}_tables/MetaCyc_table.txt ${temp_dir}/${file2}_tables/NR_table.txt ${temp_dir}/${file2}_tables/PHI_table.txt ${temp_dir}/${file2}_tables/Swiss-Prot_table.txt ${temp_dir}/${file2}_tables/VFDB_table.txt ${temp_dir}/${file2}_tables/Pfam_table.txt ${temp_dir}/${file2}_tables/${file2}.faa.info ${temp_dir}/${file2}_tables/function_annotation.html

if [ -s "${temp_dir}/${file2}_tables/ratio.txt" ];then
       rm ${temp_dir}/${file2}_tables/ratio.txt
fi
taotal=`grep '>' ${input} |wc -l`
echo "Total	$total">>${temp_dir}/${file2}_tables/ratio.tx
for i in  ${array[@]}
do
	if [[ $i = "CARD" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/CARD_table.txt >${temp_dir}/${file2}_tables/CARD_ratio.txt
	awk '{print "CARD""\t"$0}' ${temp_dir}/${file2}_tables/CARD_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/CARD_ratio.txt
	fi
	
	if [[ $i = "KEGG" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/KEGG_table.txt >${temp_dir}/${file2}_tables/KEGG_ratio.txt
	awk '{print "KEGG""\t"$0}' ${temp_dir}/${file2}_tables/KEGG_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/KEGG_ratio.txt
	fi
	
	if [[ $i = "COG" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/COG_table.txt >${temp_dir}/${file2}_tables/COG_ratio.txt
	awk '{print "COG""\t"$0}' ${temp_dir}/${file2}_tables/COG_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/COG_ratio.txt
	fi
	
	if [[ $i = "NR" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/NR_table.txt >${temp_dir}/${file2}_tables/NR_ratio.txt
	awk '{print "NR""\t"$0}' ${temp_dir}/${file2}_tables/NR_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/NR_ratio.txt
	fi
	
	if [[ $i = "PHI" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/PHI_table.txt >${temp_dir}/${file2}_tables/PHI_ratio.txt
	awk '{print "PHI""\t"$0}' ${temp_dir}/${file2}_tables/PHI_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/PHI_ratio.txt
	fi
	
	if [[ $i = "Pfam" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/Pfam_table.txt >${temp_dir}/${file2}_tables/Pfam_ratio.txt
	awk '{print "Pfam""\t"$0}' ${temp_dir}/${file2}_tables/Pfam_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/Pfam_ratio.txt
	fi

	if [[ $i = "Swiss-Prot" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/Swiss-Prot_table.txt >${temp_dir}/${file2}_tables/Swiss-Prot_ratio.txt
	awk '{print "Swiss-Prot""\t"$0}' ${temp_dir}/${file2}_tables/Swiss-Prot_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/Swiss-Prot_ratio.txt
	fi
	
	if [[ $i = "VFDB" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/VFDB_table.txt >${temp_dir}/${file2}_tables/VFDB_ratio.txt
	awk '{print "VFDB""\t"$0}' ${temp_dir}/${file2}_tables/VFDB_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/VFDB_ratio.txt
	fi
	
	if [[ $i = "MetaCyc" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/MetaCyc_table.txt >${temp_dir}/${file2}_tables/MetaCyc_ratio.txt
	awk '{print "MetaCyc""\t"$0}' ${temp_dir}/${file2}_tables/MetaCyc_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/MetaCyc_ratio.txt
	fi
	
	if [[ $i = "CAZy" ]];then
	perl $perlDir/statistic_all_database.pl ${temp_dir}/${file2}_tables/CAZy_table.txt >${temp_dir}/${file2}_tables/CAZy_ratio.txt
	awk '{print "CAZy""\t"$0}' ${temp_dir}/${file2}_tables/CAZy_ratio.txt >>${temp_dir}/${file2}_tables/ratio.txt
	rm ${temp_dir}/${file2}_tables/CAZy_ratio.txt
	fi
done

if [[ ! -d ${output_dir}/${file2}_figure ]];then
        mkdir ${output_dir}/${file2}_figure
else
        rm -rf ${output_dir}/${file2}_figure
        mkdir ${output_dir}/${file2}_figure
fi
export PATH=/data/public_tools/R/bin:$PATH
for i in  ${array[@]}
do
if [[ $i = "CARD" && -s ${temp_dir}/${file2}_diamond/CARD_diamond.txt ]];then
perl $perlDir/CARD-classification.pl ${temp_dir}/${file2}_diamond/CARD_diamond.txt >${output_dir}/${file2}_figure/CARD.txt
	card1=`grep CARD ${temp_dir}/${file2}_tables/ratio.txt |awk '{print $2}'`
	card2=`wc -l ${output_dir}/${file2}_figure/CARD.txt |awk '{print $1}'`
	Rscript $Rdir/CARD-classification.R ${output_dir}/${file2}_figure/ CARD.txt
fi
if [[ $i = "COG" && -s ${temp_dir}/${file2}_diamond/COG_diamond.txt ]];then
perl $perlDir/cog-classification.pl ${temp_dir}/${file2}_diamond/COG_diamond.txt >${output_dir}/${file2}_figure/COG.txt
	cog1=`grep COG ${temp_dir}/${file2}_tables/ratio.txt |awk '{print $3}'`
	cog2=`wc -l ${output_dir}/${file2}_figure/COG.txt|awk '{print $1}'`
	Rscript $Rdir/cog-classification.R ${output_dir}/${file2}_figure/ COG.txt
fi
if [[ $i = "KEGG" && -s ${temp_dir}/${file2}_diamond/KEGG_diamond.txt ]];then
perl $perlDir/kegg-classification.pl ${temp_dir}/${file2}_diamond/KEGG_diamond.txt >${output_dir}/${file2}_figure/KEGG.txt
	kegg1=`grep KEGG ${temp_dir}/${file2}_tables/ratio.txt |awk '{print $3}'`
	kegg2=`wc -l ${output_dir}/${file2}_figure/KEGG.txt|awk '{print $1}'`
	Rscript $Rdir/KEGG-classification.R ${output_dir}/${file2}_figure/ KEGG.txt
fi
done

perl $perlDir/ratio_html.pl ${temp_dir}/${file2}_tables/ratio.txt ${output_dir}/${file2}_ratio.html

if [[ ! -d ${output_dir}/${file2}_diamond ]];then
        mkdir ${output_dir}/${file2}_diamond
else
        rm -rf ${output_dir}/${file2}_diamond
        mkdir ${output_dir}/${file2}_diamond
fi

if [[ ! -d ${output_dir}/${file2}_tables ]];then
        mkdir ${output_dir}/${file2}_tables
else
        rm -rf ${output_dir}/${file2}_tables
        mkdir ${output_dir}/${file2}_tables
fi

if [[ ! -d ${output_dir}/${file2}_htmls ]];then
        mkdir ${output_dir}/${file2}_htmls
else
        rm -rf ${output_dir}/${file2}_htmls
        mkdir ${output_dir}/${file2}_htmls
fi

for i in ${array[@]}
do
if [[ -s ${temp_dir}/${file2}_tables/${i}_table.txt ]];then
awk '{if($0 !~ /NA$/)print $0}'  ${temp_dir}/${file2}_tables/${i}_table.txt > ${temp_dir}/${file2}_tables/${i}_table-1.txt
mv ${temp_dir}/${file2}_tables/${i}_table-1.txt ${temp_dir}/${file2}_tables/${i}_table.txt
fi
done

cp ${temp_dir}/${file2}_tables/*.html ${output_dir}/${file2}_htmls
cp ${temp_dir}/${file2}_diamond/* ${output_dir}/${file2}_diamond
cp ${temp_dir}/${file2}_tables/*.txt ${output_dir}/${file2}_tables
mv ${output_dir}/${file2}_ratio.html ${output_dir}/${file2}_htmls/ratio.html
echo "ALL processes were DONE!" >> ${output_dir}/${file2}_functional_annotation.log

fi
