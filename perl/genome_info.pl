#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my $USAGE = qq{
Usage:
	$0 -inputdir <fastqc outdir> -predictsize <genomesize> -allgenomeinfo <all genome info> -outfile <genome_info.tx>
Options:
	-inputdir	<string>	fastqc outdir
	-predictsize	<string>	predictsize
	-allgenomeinfo	<string>	allgenomeinfo
	-outfile	<string>	genome_info.txt
};

my ($inputdir,$predictsize,$allgenomeinfo,$outfile);
GetOptions(
	"inputdir=s" =>\$inputdir,
	"predictsize=s" =>\$predictsize,
	"allgenomeinfo=s" =>\$allgenomeinfo,
	"outfile=s" =>\$outfile,
);
die "$USAGE" unless $inputdir;

opendir DIR,"$inputdir" or die $!;
my @file=readdir(DIR);
my $gc;
for my $i(@file){
	if($i=~/1_fastqc\.zip/){
		my $file="$inputdir/$i";
#		print "$file\n";
		my $a=$i;
		$a=~s/\.zip//g;
		system("unzip $file -d $inputdir");
		my $fi=$i;
		$fi=~s/\.zip//g;
		open IN,"$inputdir/$fi/fastqc_data.txt" or die $!;
		while(<IN>){
			chomp;
			if(/^%GC/){
				my @line=split /\s+/,$_;
				$gc=$line[1];
			}
		}
		system("rm -r $inputdir/$a");
	}
}

open OUT,">$outfile" or die $!;
print OUT"ID","\t","Scaffold_number","\t","N50","\t","N75","\t","Largest_Scaffold","\t","Total_length","\t","GC%","\t","N's","\n";
open ALL,"$allgenomeinfo" or die $!;
my %hash;
while(<ALL>){
	chomp;
	next if(/^ID/);
	my @line=split /\t/,$_;
	my $len_min=$predictsize - $predictsize*4/10;
	my $len_max=$predictsize + $predictsize*4/10;
	my $gc_min=$gc - $gc*2/10;
	my $gc_max=$gc + $gc*2/10;
	if($line[-2]>$gc_min && $line[-2]<$gc_max){
		$hash{$line[0]}=$_;
	}
	if($line[-3]>$len_min && $line[-3]<$len_max){
		$hash{$line[0]}=$_;
	}
}

for my $key(sort keys %hash){
	print OUT"$hash{$key}\n";
}

