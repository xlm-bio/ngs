#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
my $dir=getcwd;
my %hash;

open ANNO,"$ARGV[0]" or die $!; ####$dir/annotation_result/CARD_result
while (my $aline=<ANNO>){
	chomp $aline;
	my @arr=split /\t/,$aline;
	$hash{$arr[1]}=$arr[0]."\t".$arr[2];
}
close ANNO;

open INFO,"/data/result/typestrain/faa_script/GCM_database_annotation_perl/database_anno_info/CARD_pro.info" or die $!;
open TEMP,">$ARGV[1]" or die $!; #####$dir/table.file/card.temp
while (my $bline=<INFO>){
	chomp $bline;
	my @brr=split /\t/,$bline;
	my @crr=split /,/,$brr[1];
	if(defined $hash{$crr[0]}){
		print TEMP "$hash{$crr[0]}\t$crr[0] \| $crr[1] \| $brr[0]\n";
	}
}
close INFO;
close TEMP;
my %ID;
open L,"$ARGV[1]" or die $!;
while (my $line=<L>){
	chomp $line;
	my @abb=split /\t/,$line;
	$ID{$abb[0]}=$line;
}
close L;

open GFF,"$ARGV[2]" or die $!; ####$dir/Prodigal/prodigal.faa.info
open R,">$ARGV[3]" or die $!; #####$dir/table.file/CARD.table
while(my $dline=<GFF>){
        chomp $dline;
        my @drr=split /\t/,$dline;
        if (defined $ID{$drr[0]}){
                print R "$ID{$drr[0]}\n"; 
        }else{print R "$drr[0]\t0\tNA\n";}
}
system("rm -r $ARGV[1]");
#system ("less $dir/table.file/CARD.table |sort -k 1.4n -k 1.5n >$dir/table.file/CARD.table-1");
#system ("mv $dir/table.file/CARD.table-1 $dir/table.file/CARD.table");

