#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
my $dir=getcwd;
my %hash;

open ANNO,"$ARGV[0]" or die $!;  ####$dir/annotation_result/PHI_result
while (my $aline=<ANNO>){
	chomp $aline;
	my @arr=split /\t/,$aline;
	$hash{$arr[1]}=$arr[0]."\t".$arr[2];
}
close ANNO;

open INFO,"/data/result/typestrain/faa_script/GCM_database_annotation_perl/database_anno_info/phi45.info" or die $!;
open OUT,">$ARGV[1]" or die $!; ####>$dir/table.file/phi.table.temp
while (my $bline=<INFO>){
	chomp $bline;
	$bline=~s/#/\|/g;
	my @brr=split /\|/,$bline;
	if(defined $hash{$brr[1]}){
		$bline=~s/\|/ \| /g;
		print OUT "$hash{$brr[1]}\t$bline\n";
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
open GFF,"$ARGV[2]" or die $!;   #####$dir/Prodigal/prodigal.faa.info
open R,">$ARGV[3]" or die $!;  ####$dir/table.file/PHI.table
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
#system ("less $dir/table.file/phi.table |sort -k 1.4n -k 5.5n|sed \'s/#/\|/g' >$dir/table.file/phi.table-1");
#system ("mv $dir/table.file/phi.table-1 $dir/table.file/phi.table");

