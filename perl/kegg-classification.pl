#!/usr/bin/perl -w
#########read the relationship from prokaryotes.dat
#open Classify_file,"/data/database/functional-database/KEGG/gene_id-K_number-brite_number-classifacatiopn/prokaryotes.dat";
#my %hash;
#while(<Classify_file>){
#	chomp;
#	my @array = split /\t/,$_;
#	if($array[1]){
#		$hash{$array[0]}=$array[1];
#	}else{
#		print "$_\n";
#	}
#}
##############################################################################################################
#####read the relationship between k-number and gene-number from littler classify file which produced by under profram
##########################################################################################################################
open Littler_classify_file ,"/data/database/functional-database/KEGG/gene_id-K_number-brite_number-classifacatiopn/kegg-gene-number_k-number.list";
my %hash;
while(<Littler_classify_file>){
	chomp;
	my @array = split /\t/,$_;
	$hash{$array[0]} = $array[1];
}
#######################################################################################################
#########find the K-number of the gene-number in annotation gff file
##########################################################################################################
open KEGG_annatation_results,$ARGV[0];#"/home/wxc/10000-sequencing/NCAIMB02541_IMCAS-annotation/KEGG/genome.gff";
my %new_hash;
#open KEGG_id_K_number,"> $ARGV[1]/KEGG_id_K_number.txt";
while(<KEGG_annatation_results>){
	chomp;
		@array1 = split /\t/,$_;
		$query_cog_id = $array1[1];
		if(exists $hash{$query_cog_id}){
			#print  "$query_cog_id\tko:$hash{$query_cog_id}\n";
			my @array = split /,/, $hash{$query_cog_id};
			foreach(@array){
				$new_hash{$_}++; ###K-number unique
			}
		}else{
			#print "$query_cog_id\n";
		}
}
#foreach $key(keys %hash){
#	print "$key\t$hash{$key}\n";
#}
#########################################################################################
#######trans k-number into pathway-number
################################################################################################
open Pathway_KO_list,"/data/database/functional-database/KEGG/gene_id-K_number-brite_number-classifacatiopn/pathway_ko.list";
my %pathway_hash;
#open K_number_pathway_number,"> ./K_number_pathway_number.txt";
while(<Pathway_KO_list>){
	chomp;
	my @array = split /\t/,$_;
	$pathway_hash{$array[1]} .= $array[0] . ";"; ##very intresting usage of hash 
}
my %pathway_stats;
foreach $key(keys %new_hash){
	for ($i = 1; $i <= $new_hash{$key}; $i++){
		$query_knumber = "ko:".$key;
		if(exists $pathway_hash{$query_knumber}){
			#print K_number_pathway_number "$query_knumber\t$pathway_hash{$query_knumber}\n";
			my @array = split /;/,$pathway_hash{$query_knumber};
			foreach(@array){
				$pathway_stats{$_}++
			}
		}
	}
}
#foreach $key(keys %pathway_stats){
#	print "$key\t$pathway_stats{$key}\n";
#}
#########################################################################################
#####already got the pathway number, finding the classification of each pathway number
#############################################################################################
open Pathway_list,"/data/database/functional-database/KEGG/gene_id-K_number-brite_number-classifacatiopn/pathway.list";
my %last_hash;
my $secondary_classify;
while(<Pathway_list>){
	chomp;
	if($_ =~ /^##/){
		$secondary_classify = substr($_,2);
	}elsif($_=~/^0/){
		my @array = split /\t/,$_;
		$last_hash{$array[0]} = $secondary_classify;
#		print "$array[0]\t$secondary_classify\n";
	}
}
#foreach $key(keys %last_hash){
#	print "$key\t$last_hash{$key}\n";
#}
my %haha; ##one k-number matched two pathway-number(ko00010,and map00010), so The pathway needed to be unique 
foreach $ha(keys %pathway_stats){
	$key = substr($ha,,-5);
	if(exists $last_hash{$key}){
		$final = join "\t",($key,$last_hash{$key},$pathway_stats{$ha});
		#print "$final\n";
		$haha{$final}++;
	}else{
	#	print "$key didin't find the classification!!!\n";
	}
}
my %hei;
foreach $key(keys %haha){
	@array = split /\t/,$key;
	#print "$array[0]\n";
	for($i = 0; $i < $array[2];$i++){
		$hei{$array[1]}++;
	}
}
open Color,"/data/database/functional-database/KEGG/gene_id-K_number-brite_number-classifacatiopn/color-of-classification.list";
my %color;
while(<Color>){
	chomp;
	@array = split /\t/,$_;
	$color{$array[0]} = $array[1]; 
}
my %muyouzhongdain;
foreach $key(keys %hei){
	if(exists $color{$key}){
		#print "$key\t$hei{$key}\t$color{$key}\n"
		$muyouzhongdain{$color{$key}}{$hei{$key}} = $key;
	}else{
		print "$key!! something wrong in the color file!\n";
	}
}
foreach $father (sort {$a cmp $b} keys %muyouzhongdain){
	foreach $key ( keys %{$muyouzhongdain{$father}}){
		print "$muyouzhongdain{$father}{$key}\t$key\t$father\n";
	}	
}

close Littler_classify_file;
close KEGG_annatation_results;
close Pathway_KO_list;
close Pathway_list;












