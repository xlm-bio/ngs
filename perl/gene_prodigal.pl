#!/usr/bin/perl -w
use strict;

use Getopt::Long;
my $USAGE = qq{
Usage:
	$0 -gff <prodigal result> -fasta <genome fasta> -outfile <outfile>
};

my ($gff,$fasta,$outfile);
GetOptions(
	"gff=s" =>\$gff,
	"fasta=s" =>\$fasta,
	"outfile=s" =>\$outfile,
);
die "$USAGE" unless $gff;

open FASTA,"$fasta" or die $!;

my $total;
my $contig;
my %hash;
my $id;
while(<FASTA>){
	chomp;
	if(/^>(\S+)/){
		$contig++;
		$id=$1;
	}else{
	$total+=length($_);
	$hash{$id}+=length($_);
	}

}
close FASTA;
open GFF,"$gff" or die $!;
my %result;
my $num=0;
my $gene_len;
my $partial;
my %count;
while(<GFF>){
	chomp;
	next if(/^#/);
	my @arr=split /\t/,$_;
	$num++;
	$gene_len+=$arr[4]-$arr[3]+1;
	my @brr=split /;/,$arr[-1];
	my $par=$brr[1];
	$par=~s/partial=//g;
	if($par=~/1/){
		$partial++;
	}
	my @brr1=split /_/,$brr[0];
	if(! exists $count{$arr[0]}){
		$count{$arr[0]}->[0]=$arr[3];
		$count{$arr[0]}->[1]=$arr[4];
		$count{$arr[0]}->[2]=1;
		$count{$arr[0]}->[3]=$arr[4]-$arr[3]+1;
	}else{
		$count{$arr[0]}->[3]+=$arr[4]-$arr[3]+1;
		$count{$arr[0]}->[2]++;
		if($arr[3]<$count{$arr[0]}->[0]){
			$count{$arr[0]}->[0]=$arr[3];
		}
		if($arr[4]>$count{$arr[0]}->[1]){
			$count{$arr[0]}->[1]=$arr[4];
		}
	}


		
}

my $total_k=sprintf "%.2f",($total/1000);
my $cover=sprintf "%.2f",($gene_len/$total);
my $ave=sprintf "%.2f",($gene_len/$num);
my $gene_len_k=sprintf "%.2f",($gene_len/1000);
my $part=sprintf "%.2f",($partial/$num);
my $total_inter;
my $inter_len;
my $rm;
my $rm1;
my $rm2;
for my $key(keys %count){
	#print "$key\t$count{$key}->[0]\t$count{$key}->[1]\n";
	$rm1+=$count{$key}->[3];
	$rm2+=$count{$key}->[1]-$count{$key}->[0]+1;
	#$rm+=($count{$key}->[0]-1)+($hash{$key}-$count{$key}->[1]);
	$total_inter+=$count{$key}->[2]-1;
	print"$key\t$count{$key}->[0]\t$count{$key}->[1]\t$count{$key}->[3]\t$count{$key}->[2]\n";
}
$inter_len=$rm2-$rm1;
print "$inter_len	$total_inter\n";
my $ave_inter=sprintf "%.2f",($inter_len/$total_inter);
open OUT,">$outfile" or die $!;
my @c=split /\//,$fasta;
$c[-1]=~s/\.fasta//g;
print OUT"Sample\tGenome Size (Kbp)\tNum (#)\tNum of genes (#)\tTotal length (Kbp)\tCover (%)\tAverage Length (bp)\tAverage intergenic (bp)\tpartial gene ratio (%)\n";
print OUT"$c[-1]\t$total_k\t$contig\t$num\t$gene_len_k\t$cover\t$ave\t$ave_inter\t$part\n";

