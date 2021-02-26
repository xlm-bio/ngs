#!/usr/bin/perl
use strict;
use warnings;

my %hash;

open I,"$ARGV[0]" or die $!; ###DAT
while(my $line=<I>){
	chomp $line;
	my @arr=split /;/,$line;
	if($#arr==3){
		$hash{$arr[0]}=$arr[0]." \| ".$arr[3]." \| ".$arr[1];
	}
	if($#arr==2 && $arr[1] =~ /K/){
		$hash{$arr[0]}=$arr[0]." \| "."#"." \| ".$arr[1];
	}
	if($#arr==2 && $arr[1] !~ /K/){
                $hash{$arr[0]}=$arr[0]." \| ".$arr[2]." \| "."#";
        }
	if($#arr==1 && $arr[1] !~ /K/){
		$hash{$arr[0]}=$arr[0]." \| "."#"." \| "."#";
	}
	if($#arr==1 && $arr[1] =~ /K/){
                $hash{$arr[0]}=$arr[0]." \| "."#"." \| ".$arr[1];
        }
	if($#arr==0 && $arr[0] =~ /:/){
                $hash{$arr[0]}=$arr[0]." \| "."#"." \| "."#";
        }
}
close I;
my %name;
open A,"$ARGV[1]" or die $!; #####diamond_result
while (my $aline = <A>){
	chomp $aline;
	my @brr=split /\t/,$aline;
	if(exists $hash{$brr[1]}){
		$name{$brr[0]}=$brr[0]."\t".$brr[2]."\t".$hash{$brr[1]};
	}
	else {$name{$brr[0]}=$brr[0]."\t".$brr[2]."\t"."#";}
}
close A;
open S,"$ARGV[2]" or die $!; ####faa.info
open R, ">$ARGV[3]" or die $!;
while (my $bline=<S>){
	chomp $bline;
	my @crr=split /\t/,$bline;
	if(exists $name{$crr[0]}){
		print R "$name{$crr[0]}\n";
	}
	else{print R "$crr[0]\t0\tNA\n";}
}
close S;
close R;
