#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Tie::File;
my $USAGE = qq{
Usage:
	$0 -rnammer <rnammmer result> -outfile <outfile>
};
my ($rnammer,$outfile);
GetOptions(
	"rnammer=s" =>\$rnammer,
	"outfile=s" =>\$outfile,
);

die "$USAGE" unless $rnammer;
tie my @arr,'Tie::File',$rnammer or die $!;
if(@arr){
	open FILE,"$rnammer" or die $!;
	open OUT,">$outfile" or die $!;
	my %hash;
	my $id;
	while(<FILE>){
		chomp;
		if(/^>/){
			$id=$_;
		}else{
			$hash{$id}.=$_;
		}
	}
	close FILE;
	for my $k(keys %hash){
		if($k=~/16s/){
			print OUT"$k\n$hash{$k}\n";
		}
	}
}

