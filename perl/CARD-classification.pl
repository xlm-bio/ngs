#!/usr/bin/perl -w
open Aro_categories_index,"/data/database/functional-database/CARD/aro_categories_index.csv";
my %hash;
while(<Aro_categories_index>){
	chomp;
	my @array = split /\t/,$_;
	$hash{$array[0]}{$array[2]}{$array[3]} = $array[4];
}

open CARD_results,$ARGV[0];  ##genome.gff
my %AMR_gene_family;
my %Drug_class;
my %Resistance_mechanism;
while(<CARD_results>){
	chomp;
		my @array1 = split /\t/,$_;
		#print "$array1[1]\n";
		if(exists $hash{$array1[1]}){
			foreach $son (keys %{$hash{$array1[1]}}){
				foreach $sonson (keys %{$hash{$array1[1]}{$son}}){
					my @array2 = split /;/,$son;
					for($i = 0; $i < scalar(@array2); $i++){
						$AMR_gene_family{$array2[$i]}++;
					}
					my @array3 = split /;/,$sonson;
					foreach(@array3){
						$Drug_class{$_}++;
					}
					my @array4 = split /;/,$hash{$array1[1]}{$son}{$sonson};
					#print "$hash{$array1[1]}{$son}{$sonson}\n";
					foreach(@array4){
						$Resistance_mechanism{$_}++;
					}
				}
			}
		}
}
foreach $father (keys %AMR_gene_family){
	print "$father\t$AMR_gene_family{$father}\tAMR_Gene_Family\n"
}

foreach $father (keys %Drug_class){
	print "$father\t$Drug_class{$father}\tDrug_Class\n"
}
foreach $father (keys %Resistance_mechanism){
	print "$father\t$Resistance_mechanism{$father}\tResistance_Mechanism\n"
}
