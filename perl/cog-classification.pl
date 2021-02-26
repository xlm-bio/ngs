#!/usr/bin/perl -w
open Classify_file,"/data/database/functional-database/cog/cog.number.COGnumber.list";
my %hash;
my $annatation;
while(<Classify_file>){
	chomp;
	my @array = split /\t/,$_;
	$hash{$array[0]} = $array[1];
}
close Classify_file;
open Cog_annatation_results,"$ARGV[0]" or die $!;;#"/home/wxc/10000-sequencing/NCAIMB02541_IMCAS-annotation/COG/genome.gff";
my %new_hash;
while(<Cog_annatation_results>){
	chomp;
		@array3 = split /\t/,$_;
		$query_cog_id = substr($array3[1],3,8);
		if(exists $hash{$query_cog_id}){
			@new_key = $hash{$query_cog_id}; 
			$new_hash{$new_key[0]}++;
		}else{
		}
}
close Cog_annatation_results;
open Classification,"/data/database/functional-database/cog/classification_cog.txt";
my %hash3;
while(<Classification>){
	chomp;
	my @array = split / /,$_;
	$hash3{$array[1]} = $array[0];
}
close Classification;

my %hash4;
foreach my $key (keys %new_hash){
	if(exists $hash3{$key}){
		$haha = substr($hash3{$key},1,-1);
		#print "$key\n";
		$hash4{$haha}++;	
	}
}
my %hash5;
foreach my $key (keys %hash4){
	my @array = split //,$key;
	foreach(@array){
		$hash5{$_} += $hash4{$key};
	}
}
open Cog_classify_matched_list,"/data/database/functional-database/cog/cog_classify_matched.list" || die ("/data/database/functional-database/cog/classification_cog.txt");
while(<Cog_classify_matched_list>){
	chomp;
	my @array = split /\t/,$_;
	if(exists $hash5{$array[0]}){
		print  "$array[1]\t$hash5{$array[0]}\t$array[2]\n";
	}else{
	}
}
close Cog_classify_matched_list;

