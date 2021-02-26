#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
my $dir=getcwd;
my %hash;

open PFAM,"$ARGV[0]" or die $!; ####$dir/annotation_result/Pfam_result
while (my $pfam=<PFAM>){
	chomp $pfam;
#	next if ($pfam!~/^gene/);
	my @arr=split /\t/,$pfam;
	my @brr=split //,$arr[7];
	if(! exists ($hash{$arr[0]})){
		$hash{$arr[0]}=$arr[0]."\t".$arr[5].", ".$arr[6]." "."(".$brr[0].")";
	}
	else{
		$hash{$arr[0]}.=" "."\|"." ".$arr[5].", ".$arr[6]." "."(".$brr[0].")";
	}
}
close PFAM;

open GFF,"$ARGV[1]" or die $!;  ######$dir/Prodigal/prodigal.faa.info
open R,">$ARGV[2]" or die $!;  ###$dir/table.file/Pfam.table
while(my $gff=<GFF>){
	chomp $gff;
	my @crr=split /\t/,$gff;
	if(defined $hash{$crr[0]}){
		print R "$hash{$crr[0]}\n";
	}
	else{print R "$crr[0]\tNA\n";}
}
close GFF;
close R;

