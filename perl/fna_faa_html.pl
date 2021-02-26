#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

my $dir=getcwd;
open CDS,"$ARGV[0]" or die $!; ####$dir/prodigal.fna-1
open FNA,">$ARGV[1]" or die $!; #####$dir/fna.file
while(my $cds=<CDS>){
	chomp $cds;
	if($cds=~/>/){
	my @arr=split / /,$cds;
		print FNA "\n$arr[0]\n";
	}else{print FNA "$cds";}
}
close CDS;
close FNA;

open PEP,"$ARGV[2]" or die $!; #####$dir/prodigal.faa-1
open FAA,">$ARGV[3]" or die $!; ######$dir/faa.file
while(my $pep=<PEP>){
        chomp $pep;
        if($pep=~/>/){
        my @brr=split / /,$pep;
                print FAA "\n$brr[0]\n";
        }else{print FAA "$pep";}
}
close PEP;
close FAA;


open FNA1,"$ARGV[1]" or die $!;
open FAA1,"$ARGV[3]" or die $!;
open FN,">$ARGV[4]" or die $!; ####$dir/fna.file.html
open FA,">$ARGV[5]" or die $!; ####$dir/faa.file.html
while(<FAA1>){
	next if($_!~/\S/);
	my $i=0;
	m{(.)(?{if((++$i)%70 == 0) {print FA "$1\n"} else {print FA "$1"}})(?!)}gs;
}
while(<FNA1>){
	next if ($_!~/\S/);
	my $i=0;
        m{(.)(?{if((++$i)%70 == 0) {print FN "$1\n"} else {print FN "$1"}})(?!)}gs;
}
close FNA1;
close FAA1;
close FN;
close FA;
open N,"$ARGV[4]" or die $!;
open A,"$ARGV[5]" or die $!;
open RN,">$ARGV[6]" or die $!; ##### $dir/fna.html
open RA,">$ARGV[7]" or die $!; #####$dir/faa.html

print RN "<html>\n";
print RA "<html>\n";
while (my $dline=<N>){
	chomp $dline;
	if($dline=~/>/){
		$dline=~s/>//g;
		print RN "<div id=\"$dline\">\n";
		print RN "<table>\n";
		print RN "<tr><td>$dline</td></tr>\n";
		my $near=<N>;
		chomp $near;
		if(length($near)==70){
			print RN "<tr><td>\n";
			print RN "<p style=\"font-family:consolas;font-size:16px;&nbsp;line-height:24px;\">\n";
			print RN "$near<br>\n";
		}
		else{	print RN "<tr><td>\n";
			print RN "<p style=\"font-family:consolas;font-size:16px;line-height:24px;\">\n";
			print RN "$near</p></td></tr>\n</table>\n</div>\n";}
	}
	elsif(length ($dline)==70){
		print RN "$dline<br>\n";
	}
	else {print RN "$dline</p>\n</td></tr>\n</table>\n</div>\n";}
}
close N;
while (my $eline=<A>){
        chomp $eline;
        if($eline=~/>/){
                $eline=~s/>//g;
                print RA "<div id=\"$eline\">\n";
		print RA "<table>\n";
                print RA "<tr><td>$eline</td></tr>\n";
        	my $near=<A>;
                chomp $near;
                if(length ($near)==70){
			print RA "<tr><td>\n";
			print RA "<p style=\"font-family:consolas;font-size:16px;&nbsp;line-height:24px;\">\n";
                        print RA "$near<br>\n";
		}
		else{	print RA "<tr><td>\n";
			print RA "<p style=\"font-family:consolas;font-size:16px;line-height:24px;\">\n";
			print RA "$near</p></td></tr>\n</table>\n</div>\n";}
	}
	elsif(length($eline)==70){
                print RA "$eline<br>\n";
        }
        else {print RA "$eline</p>\n</td></tr>\n</table>\n</div>\n";}
}
close A;
print RA "</html>\n";
print RN "</html>\n";
close RA;
close RN;
system ("rm $ARGV[1] $ARGV[3] $ARGV[4] $ARGV[5]");

