#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Statistics::Descriptive;
my $USAGE = qq{
Usage:
	$0 -trf <trf result> -outfile <outfile> -fasta <fasta>
};
my ($trf,$outfile,$fasta);
GetOptions(
	"trf=s" =>\$trf,
	"outfile=s" =>\$outfile,
	"fasta=s" =>\$fasta,
);

die "$USAGE" unless $trf;

open FA,"$fasta" or die $!;
my $total;
while(<FA>){
	chomp;
	next if(/^>/);
	$total+=length($_);
}
print "$total\n";
open TRF,"$trf" or die $!;
my %hash;
my %unit;

while(<TRF>){
	chomp;
	my @line=split /\s/,$_;
	if($#line==14){
		my $len1=length($line[13]);
		my $len2=length($line[14]);
		if($len1>=15 && $len1<=65){
			$hash{"minisatellite"}->[0]++;
			$hash{"minisatellite"}->[1]+=$len2;
			push @{$unit{"minisatellite"}},($len1);
		}
		if($len1>=2 && $len1<=10){
			$hash{"microsatellite"}->[0]++;
			$hash{"microsatellite"}->[1]+=$len2;
			push @{$unit{"microsatellite"}},($len1);
		}
	}
}

open OUT,">$outfile" or die $!;
print OUT"Type\tNum (#)\tRepeat unit (bp)\tTotal length (bp)\tCover (%)\n";


for my $k(keys %hash){
	my @arr=sort @{$unit{$k}};
#	print"@arr\n";
	my $se=getarr(@arr);
	print "$se\n";
	my $cov=sprintf "%.2f",($hash{$k}->[1]/$total*100);
	my $max=$hash{$k}->[0]-1;
	if($hash{$k}->[0]>1){
#		if($arr[0] <$arr[$max]){
#			print OUT"$k\t$hash{$k}->[0]\t$arr[0]-$arr[$max]\t$hash{$k}->[1]\t$cov\n";
		#}#elsif($arr[0]==$arr[$max]){
		#	print OUT"$k\t$hash{$k}->[0]\t$arr[1]-$arr[$max]\t$hash{$k}->[1]\t$cov\n";
		#}
#		}else{
			print OUT"$k\t$hash{$k}->[0]\t$se\t$hash{$k}->[1]\t$cov\n";
#		}
	}else{
		print OUT"$k\t$hash{$k}->[0]\t$arr[0]-$arr[0]\t$hash{$k}->[1]\t$cov\n";
	}
}

sub getarr{
	my @arr=@_;
	my $stat = Statistics::Descriptive::Full->new();
	$stat->add_data(\@arr);
	my $min=$stat->min();
	my $max=$stat->max();
	my $seq=$min."-".$max;
	return $seq;
}
	
