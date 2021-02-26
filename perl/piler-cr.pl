#!/usr/bin/perl -w
use strict;

use Getopt::Long;
my $USAGE = qq{
Usage:
	$0 -piler <piler result> -outfile <outfile>
};
my ($piler,$outfile);
GetOptions(
	"piler=s" =>\$piler,
	"outfile=s" =>\$outfile,
);

die "$USAGE" unless $piler;
open PILER,"$piler" or die $!;
my %hash;
my $n=0;
my $array;
my %result;
my $similarity;
my $pos;
open OUT,">$outfile" or die $!;
print OUT"ID\tContig\tPosition\tLength (bp)\tCopies (#)\tRepeat length (bp)\tSpacer length (bp)\tStrand\tConsensus sequence of repeat\n";
while(<PILER>){
	chomp;
	$n++;
	if(/Array\s([0-9]*)/){
		$array=$1;
		$hash{$n}=$1;
	}
	for my $k(sort keys %hash){
		if($n-$k==1){
			$_=~/^>(\S+)/;
			$result{$hash{$k}}=$1;
		}
	}
	if(/SUMMARY\sBY\sSIMILARITY/){
		$similarity=$n;
	}
	if(/SUMMARY\sBY\sPOSITION/){
		$pos=$n;
	}
		
}
close PILER;
open PILER,"$piler" or die $!;
my $c=0;
while(<PILER>){
	chomp;
	$c++;
	if($c>=$similarity+6 && $c<=$pos-4){
		$_=~s/^\s+//g;
		next if(/\*/);
		next if(/^$/);
		my @arr=split /\s+/,$_;
		if($#arr==8){
			if((exists $result{$arr[0]}) && ($arr[0])){
				$arr[1]=$result{$arr[0]};
				my $seq=join("\t",@arr);
				print OUT"$seq\n";
			}
		}else{
			if(exists $result{$arr[0]}){
				print OUT"$arr[0]\t$result{$arr[0]}\t$arr[-7]\t$arr[-6]\t$arr[-5]\t$arr[-4]\t$arr[-3]\t$arr[-2]\t$arr[-1]\n"
			}
		}
	}
}
		
