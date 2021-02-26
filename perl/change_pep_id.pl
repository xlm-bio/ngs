#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

my $dir=getcwd;
my %hash;
open (IN,$ARGV[0]);####prodigal.faa
open OUT,">$ARGV[1]" or die $!;####prodigal.faa-1
my $i=1;
while (my $aline=<IN>){
	chomp $aline;
	if ($aline=~/^>/){
		chomp $aline;
		$aline=~/>(\S+)_(\S+)(.*)/;
		my $id=$1;
		my $num=$2;
                my $str=$3;
		print OUT ">gene$i$str\t$id\n";
		$i++;
	}
	else{print OUT "$aline\n";}
}
close IN;
close OUT;

open (N,$ARGV[1]);#####faa-1
open R,">$ARGV[2]" or die $!;#####faa-2

while (my $bline=<N>){
	chomp $bline;
	if($bline=~/>/){
		$bline=~s/>//;
		my @ha=split / /,$bline;
		if(length($ha[0])==5){
			$bline=~/gene(\S+)(\s)/;
			my $num="gene0000".$1;
			$bline=~s/$ha[0]/$num/;
			print R "\>$bline\n"; 
		}
		elsif(length($ha[0])==6){
                        $bline=~/gene(\S+)(\s)/;
			my $num="gene000".$1;
                        $bline=~s/$ha[0]/$num/;
                        print R ">$bline\n";
                }
		elsif(length($ha[0])==7){
                        $bline=~/gene(\S+)(\s)/;
                	my $num="gene00".$1;
		        $bline=~s/$ha[0]/$num/;
                        print R ">$bline\n";
                }
		elsif(length($ha[0])==8){
                        $bline=~/gene(\S+)(\s)/;
			my $num="gene0".$1;
                        $bline=~s/$ha[0]/$num/;
                        print R ">$bline\n";
                }
		elsif(length($ha[0])==9){
                        $bline=~/gene(\S+)(\s)/;
			my $num="gene".$1;
                        $bline=~s/$ha[0]/$num/;
                        print R ">$bline\n";
                }else{next;}
	}
	else {print R "$bline\n";}
}
close N;
close R;
system ("mv $ARGV[2] $ARGV[1]");

