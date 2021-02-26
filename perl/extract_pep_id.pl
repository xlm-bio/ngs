#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

my $dir=getcwd;

open PEP, "$ARGV[0]" or die $!; #####faa-1
open R, ">$ARGV[1]" or die $!; ####faa.info

while(my $line=<PEP>){
	chomp $line;
	my @chr=split /\t/,$line;
	if($line=~/>/){
		$line=~s/>//;
		my @arr=split / /,$line;
		if($arr[6]==1){
			print R "$arr[0]\t$arr[2]\t$arr[4]\t+\t$chr[1]\n";
		}
		if($arr[6]==-1){
                        print R "$arr[0]\t$arr[2]\t$arr[4]\t-\t$chr[1]\n";
                }
	}
}
