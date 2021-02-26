#!/usr/bin/perl -w
use strict;
use Statistics::Descriptive;
use Tie::File;
use Getopt::Long;
my $USAGE = qq{
Usage:
	$0 -inputfile <tRNAscan.a,RNAmmer.gff2,sRNA.xls> -outfile <outfile>
Options:
	-inputfile	<string>	tRNAscan.a,RNAmmer.gff2,sRNA.xls
};
my ($inputfile,$outfile);
GetOptions(
	"inputfile=s" =>\$inputfile,
	"outfile=s" =>\$outfile,
);

die "$USAGE" unless $inputfile;

open RNA,">$outfile" or die $!;
print RNA"Type\tNum (#)\tAve length (bp) (%)\tMin length (bp)\tMax length (bp)\n";
my @file=split /,/,$inputfile;
for my $i(@file){
	my @line=split /\//,$i;
	my $sample=$line[-3];

	#######################tRNA#################
	if( $i=~/tRNA/ && -e $i){	
		open TRNA,"$i" or die $!;
		my @trna;
		while(<TRNA>){
			chomp;
			next if(/^Sequence/);
			next if(/^Name/);
			next if(/^-/);
			my @arr=split /\s+/,$_;
			my $len=abs($arr[3]-$arr[2])+1;
			push @trna,($len);
		}
		close TRNA;
		my $tr=getarr(@trna);
		print RNA"tRNA\t$tr\n";
	}
	#######################RNAmmer##############
	if( $i=~/RNAmmer/ && -e $i){
		open RNAMMER,"$i" or die $!;
		my %rnammer;
		while(<RNAMMER>){
			chomp;
			next if(/^#/);
			my @arr=split /\s+/,$_;
			my $len=$arr[4]-$arr[3]+1;
			push @{$rnammer{$arr[-1]}},($len);
		}
		close RNAMMER;
		for my $key(keys %rnammer){
			my $seq=getarr(@{$rnammer{$key}});
			print RNA"$key\t$seq\n";
		}
	}
	if($i=~/Rfam/ && -e $i){
		tie my @arr,'Tie::File',$i or die $!;
		if(@arr){
		open RFAM,"$i" or die $!;
		my @rfam;
		while(<RFAM>){
			chomp;
			my @arr=split /\t/,$_;
			my $len=abs($arr[4]-$arr[3])+1;
			push @rfam,($len);
		}
		close RFAM;
		my $s=getarr(@rfam);
		print RNA"sRNA\t$s\n";
	}
	}
}	
	
					
sub getarr{
	my @arr=@_;
	my $stat = Statistics::Descriptive::Full->new();
	$stat->add_data(\@arr);
	my $mean = $stat->mean();
	$mean=sprintf "%.2f",$mean;
	my $min=$stat->min();
	my $max=$stat->max();
	my $num=$#arr+1;
	my $seq=$num."\t".$mean."\t".$min."\t".$max;
	return $seq;
}
			
