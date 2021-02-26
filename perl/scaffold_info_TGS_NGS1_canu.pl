#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my $USAGE = qq{
Usage:
	$0  -fasta <canu.fasta> -depth <depth >-outfile <outfile>
};
my ($fasta,$outfile,$depth);
GetOptions(
	"fasta=s" =>\$fasta,
	"outfile=s" =>\$outfile,
	"depth=s" =>\$depth,
);

die "$USAGE" unless $fasta;
open OUT,">$outfile" or die $!;
print OUT"Scaffold_ID\tlength\tGC\tReadDepth\tsuggestCircular\n";
open DEPTH,"$depth" or die $!;
my %dep;
while(<DEPTH>){
	chomp;
	my @arr=split /\s+/,$_;
	$arr[0]=~s/_pilon//g;
	$dep{$arr[0]}+=$arr[2];
}
	
open FA,"$fasta" or die $!;
my %hash;
my $id;
while(my $seq=<FA>){
	chomp $seq;
	if($seq=~/^>/){
		my @arr=split /\s+/,$seq;
		$id=$arr[0];
		$id=~s/>//g;
		$arr[1]=~s/len=//g;
		$arr[-1]=~s/suggestCircular=//g;
		$hash{$id}->[0]=$arr[1];
		$hash{$id}->[1]=$arr[-1];
	}else{
		$hash{$id}->[2].=$seq;
	}
}
for my $key(sort {$hash{$b}->[0] <=> $hash{$a}->[0]} keys %hash){
	my $gc=calGC($hash{$key}->[2]);
	if( exists $dep{$key}){
		my $cov=sprintf "%0.2f", $dep{$key}/$hash{$key}->[0];
		print OUT"$key\t$hash{$key}->[0]\t$gc\t$cov\t$hash{$key}->[1]\n";
	}
}


		
sub calGC{
	my $str = $_[0];
	my @array = split //,$str;
	my $GC = 0;
	for (my $i=0;$i<scalar(@array);$i++) {
	if (($array[$i] eq "G")||($array[$i] eq "C")) {
        	$GC++;
	        }
    	}
	    my $len = length($str);
	    my $gc=sprintf "%.2f",($GC/$len*100);
		return $gc;
}

