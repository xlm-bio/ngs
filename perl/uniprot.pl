#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
my $dir=getcwd;
my %hash;
open ANNO,"$ARGV[0]" or die $!;  #####"$dir/annotation_result/Swiss-Prot_result"

while (my $aline=<ANNO>){
	chomp $aline;
	my @arr=split /\t/,$aline;
	$hash{$arr[1]}=$arr[0]."\t".$arr[2];
}
close ANNO;

open INFO,"/data/result/typestrain/faa_script/GCM_database_annotation_perl/database_anno_info/uniprot_swissprot.ref" or die $!;
open OUT,">$ARGV[1]" or die $!;  #### $dir/table.file/swissprot.table.temp
while (my $bline=<INFO>){
	chomp $bline;
	my @brr=split /\t/,$bline;
	if(defined $hash{$brr[0]}){
		print OUT "$hash{$brr[0]}\t$brr[0] \| $brr[1] \| $brr[2] \| $brr[5]\n";
	}
}
close OUT,
close INFO;
my %ID;
open T,"$ARGV[1]" or die $!;
while (my $cline=<T>){
        chomp $cline;
        my @crr=split /\t/,$cline;
        $ID{$crr[0]}=$cline;
}
close T;
open GFF,"$ARGV[2]" or die $!; ####$dir/Prodigal/prodigal.faa.info
open R,">$ARGV[3]" or die $!; ####$dir/table.file/Swiss-Prot.table
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
#system ("less $dir/table.file/swissprot.table |sort -k 1.4n -k 1.5n >$dir/table.file/swissprot.table-1");
#system ("mv $dir/table.file/swissprot.table-1 $dir/table.file/swissprot.table");

