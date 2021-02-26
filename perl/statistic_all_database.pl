#!/usr/bin/perl 
use strict;
use warnings;
my ($infile)=@ARGV;
open IN,"$infile" or die $!;
my $num=0;
my $total=0;
while (my $line=<IN>){
	chomp $line;
	my @arr=split /\t/,$line;
	if($#arr==2){
		if($arr[1]>0){
			$num++;
			$total++;
		}
		else {$total++;}
	}
	else {
		if($arr[1] ne "NA"){
			$num++;
			$total++;
		}
		else {$total++;}
	}
}
if($total > 0){	
	my $ratio=sprintf "%.2f",$num/$total;
	print "$num\t$ratio\n";
}
if($total == 0){
	print "0\t0.00\n";
}

