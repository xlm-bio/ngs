#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my $USAGE = qq{
Usage:
	$0 -fasta <assembly.fasta> -info <assembly_info.txt> -depth <depth >-outfile <outfile>
};
my ($fasta,$info,$outfile,$depth);
GetOptions(
	"fasta=s" =>\$fasta,
	"info=s" =>\$info,
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
my $id;
my %hash;
my %len;
while(my $seq=<FA>){
	chomp $seq;
	if($seq=~/^>(\S+)/){
		$id=$1;
		$id=~s/_pilon//g;
		print "$id\n";
	}else{
		$hash{$id}.=$seq;
		$len{$id}+=length($seq);
	}
	
}
open INFO,"$info" or die $!;
while(my $s=<INFO>){
	chomp $s;
	next if($s=~/seq_name/);
	my @line=split /\t/,$s;
	if(exists $hash{$line[0]}){
		my $gc=calGC($hash{$line[0]});
		if($line[3]=~/\+/){
			$line[3]="Yes";
		}else{
			$line[3]="No";
		}
		my $cov=sprintf "%0.2f", $dep{$line[0]}/$line[1];
		print OUT"$line[0]\t$len{$line[0]}\t$gc\t$cov\t$line[3]\n";
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

