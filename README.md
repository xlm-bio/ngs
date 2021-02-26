# ngs

cat Demo1.config
Demo1,Demo1_NGS_1.fq,Demo1_NGS_2.fq
sh /.GCM_ngs_assembly.sh -tempdir tempdir -outputdir output -configfile Demo1.config -threads 30
sh GCM_structure_annotation.sh -structure_programs prodigal,checkM,tRNAscan,RepeatMasker,RNAmmer,piler-cr,Rfam -input_file output/Demo1/Demo1.fasta -output_dir output/Demo1 -temp_dir tempdir/Demo1
sh GCM_database_annotation.sh -database KEGG,COG,CARD,CAZy,antiSMASH,NR,PHI,Swiss-Prot,VFDB,Pfam,MetaCyc -input output/Demo1/Demo1_prodigal -input_type prodigal -output_dir output/Demo1 -temp_dir tempdir/Demo1 -input_genome output/Demo1/Demo1.fasta
