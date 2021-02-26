#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $USAGE = qq{
Usage:
	$0 -blastinfo <blast info> -blastout <blast result> -outfile <outfile>
};
my ($blastinfo,$blastout,$outfile);
GetOptions(
	"blastinfo=s" =>\$blastinfo,
	"blastout=s" =>\$blastout,
	"outfile=s" =>\$outfile,
);

die "$USAGE" unless $blastout;

open INFO,"$blastinfo" or die $!;
my %hash;
while(<INFO>){
	chomp;
	my @arr=split /\t/,$_;
	$hash{$arr[1]}=$arr[-1];
}

open BLAST,"$blastout" or die $!;
my @line=split /\//,$blastout;
my $sample=$line[-1];
$sample=~s/\.RNAmmer\.16s\.blast\.out//g;
open OUT,">$outfile" or die $!;
print OUT"Sample\tcontig\tstart\tend\tstrand\ttarget\tidentity(%)\tAnnotation\n";
while(<BLAST>){
	chomp;
	my @arr=split /\t/,$_;
	$arr[0]=~s/rRNA_//g;
	my @crr=split /_/,$arr[0];
	my @err=split /-/,$crr[-2];######strat end
	$crr[-1]=~s/DIR//g; #########strand
	my $contig;
	for my $i(0..$#crr-2){
		$contig.="$crr[$i]_";
	}
	$contig=~s/_$//g;
	if(exists $hash{$arr[1]}){
		$arr[2]=sprintf "%.2f",$arr[2];
		print OUT"$sample\t$contig\t$err[0]\t$err[1]\t$crr[-1]\t$arr[1]\t$arr[2]\t$hash{$arr[1]}\n";
	}
}
