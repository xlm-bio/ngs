#!/usr/bin/perl -w
use strict;
use Statistics::Descriptive;
use Tie::File;
use Getopt::Long;
my $USAGE = qq{
Usage:
	$0 -inputdir <inputdir>
Options:
	-inputdir	<string>	A
};
my ($inputdir);
GetOptions(
	"inputdir=s" =>\$inputdir,
);

die "$USAGE" unless $inputdir;

my @line=split /\//,$inputdir;
my $sample=$line[-1];

if((-e "$inputdir/$sample\_tRNAscan/$sample\.tRNAscan.a") ||(-e "$inputdir/$sample\_RNAmmer/$sample\.RNAmmer.gff2")||(-e "$inputdir/$sample\_Rfam/$sample\.fasta.sRNA.xls")){
	open RNA,">$inputdir/RNA.xls" or die $!;
	print RNA"Type\tNum (#)\tAve length (bp) (%)\tMin length (bp)\tMax length (bp)\n";
}

#my @line=split /\//,$inputdir;
#my $sample=$line[-1];
	#######################tRNA#################
if(-e "$inputdir/$sample\_tRNAscan/$sample\.tRNAscan.a"){	
	open TRNA,"$inputdir/$sample\_tRNAscan/$sample\.tRNAscan.a" or die $!;
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
if( -e "$inputdir/$sample\_RNAmmer/$sample\.RNAmmer.gff2"){
	open RNAMMER,"$inputdir/$sample\_RNAmmer/$sample\.RNAmmer.gff2" or die $!;
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
my $rfam="$inputdir/$sample\_Rfam/$sample\.fasta.sRNA.xls";
tie my @arr,'Tie::File',$rfam or die $!;
if(@arr){
	open RFAM,"$rfam" or die $!;
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
			
