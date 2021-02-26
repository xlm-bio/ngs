#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my $USAGE = qq{
Usage:
	$0 -fasta <assembly.fasta> -info <assembly_info.txt> -outfile <outfile>
};
my ($fasta,$info,$outfile);
GetOptions(
	"fasta=s" =>\$fasta,
	"info=s" =>\$info,
	"outfile=s" =>\$outfile,
);

die "$USAGE" unless $fasta;
open OUT,">$outfile" or die $!;
print OUT"Scaffold_ID\tlength\tGC\tsuggestCircular\n";
my %hash;
open FA,"$fasta" or die $!;
my $id;
while(my $seq=<FA>){
	chomp $seq;
	if($seq=~/^>(\S+)/){
		$id=$1;	
	}else{
		$hash{$id}.=$seq;
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
		print OUT"$line[0]\t$line[1]\t$gc\t$line[3]\n";
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

