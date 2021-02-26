#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
my $dir=getcwd;
my %hash;

open INFO,"/data/result/typestrain/faa_script/GCM_database_annotation_perl/database_anno_info/VFDB.info" or die $!;
while (my $bline=<INFO>){
        chomp $bline;
        $bline=~s/>//g;
        my @brr=split / /,$bline;
        my @ha=split /\[/,$bline;
        $hash{$brr[0]}=$ha[0];
}
close INFO;
open ANNO,"$ARGV[0]" or die $!;  #####$dir/annotation_result/VFDB_result
open OUT,">$ARGV[1]" or die $!; #####$dir/table.file/vfdb.table.temp
while (my $aline=<ANNO>){
	chomp $aline;
	my @arr=split /\t/,$aline;
	if(exists $hash{$arr[1]}){
		print OUT "$arr[0]\t$arr[2]\t$hash{$arr[1]}\n";
	}
	else {print OUT "$arr[0]\t$arr[2]\t#\n";}
}
close ANNO;
close OUT;

my %ID;
open T,"$ARGV[1]" or die $!; ####$dir/table.file/vfdb.table.temp
while (my $cline=<T>){
        chomp $cline;
        my @crr=split /\t/,$cline;
        $ID{$crr[0]}=$cline;
}
close T;
open GFF,"$ARGV[2]" or die $!; #####$dir/Prodigal/prodigal.faa.info
open R,">$ARGV[3]" or die $!;  ######$dir/table.file/VFDB.table
while(my $dline=<GFF>){
        chomp $dline;
        my @drr=split /\t/,$dline;
        if (defined $ID{$drr[0]}){
                print R "$ID{$drr[0]}\n"; 
        }else{print R "$drr[0]\t0\tNA\n";}
}
close GFF;
close R;
system ("rm $ARGV[1]");
#system ("less $dir/table.file/vfdb.table |sort -k 1.4n -k 1.5n >$dir/table.file/vfdb.table-1");
