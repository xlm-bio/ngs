#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
my $dir=getcwd;
my %hash;

open IN,"$ARGV[0]" or die $!; #####$dir/annotation_result/COG_result
while (my $aline=<IN>){
	chomp $aline;
	my @arr=split /\t/,$aline;
	$arr[1]=~/gi\|(\d+)\|ref/;
	my $cog=$1;
	$hash{$cog}=$arr[0]."\t".$arr[2];
}
close IN;

open OUT,">$ARGV[1]" or die $!; #####$dir/table.file/cog.table.temp
open INN,"/data/result/typestrain/faa_script/GCM_database_annotation_perl/database_anno_info/cog.info" or die $!;
while (my $bline=<INN>){
	chomp $bline;
	my @brr=split /\|/,$bline;
	if (defined $hash{$brr[1]}){
		print OUT "$hash{$brr[1]}\t$brr[1] \| $brr[5] \|$brr[4] \| $brr[6]\n";
	}
}
close OUT;
close INN;

my %ID;
open T,"$ARGV[1]" or die $!;
while (my $cline=<T>){
	chomp $cline;
	my @crr=split /\t/,$cline;
	$ID{$crr[0]}=$cline;
}
close T;
open GFF,"$ARGV[2]" or die $!; #####$dir/Prodigal/prodigal.faa.info
open R,">$ARGV[3]" or die $!; #####$dir/table.file/COG.table
while(my $dline=<GFF>){
	chomp $dline;
	my @drr=split /\t/,$dline;
	if (defined $ID{$drr[0]}){
		print R "$ID{$drr[0]}\n"; 
	}else{print R "$drr[0]\t0\tNA\n";}
}
system ("rm $ARGV[1]");
#system ("less $dir/table.file/cog.table |sort -k 1.4n -k 1.5n >$dir/table.file/cog.table-1");
#system ("mv $dir/table.file/cog.table-1 $dir//table.file/cog.table");
