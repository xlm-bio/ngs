#!/usr/bin/perl -w
use strict;
use Getopt::Long;
my $USAGE = qq{
Usage:
	$0 -type <flye/canu/canu_pro> -tempdir <tempdir> -outfile <outfile>
};
my ($type,$tempdir,$outfile);
GetOptions(
	"type=s" =>\$type,
	"tempdir=s" =>\$tempdir,
	"outfile=s" =>\$outfile,
);

die "$USAGE" unless $type;
open OUT,">$outfile" or die $!;
print OUT"Scaffold_ID\tlength\tGC\tsuggestCircular\n";
if($type =~ "canu"){
	opendir DIR,"$tempdir/$type" or die $!;
	my @file=readdir (DIR);
	for my $i(@file){
		if($i=~/contigs\.fasta$/){
			my $fa="$tempdir/$type/$i";
			open FA,"$fa" or die $!;
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
				print OUT"$key\t$hash{$key}->[0]\t$gc\t$hash{$key}->[1]\n";
			}
		}
	}
}

if($type eq "flye"){
	opendir DIR,"$tempdir/flye" or die $!;
	my @file=readdir (DIR);
	my %hash;
	for my $i(@file){
		if($i=~/assembly\.fasta$/){
			my $fa="$tempdir/flye/$i";
			open FA,"$fa" or die $!;
			my $id;
			while(my $seq=<FA>){
				chomp $seq;
				if($seq=~/^>(\S+)/){
					$id=$1;	
				}else{
					$hash{$id}.=$seq;
				}
			}
			
		}
		if($i=~/assembly_info\.txt/){
			my $info="$tempdir/flye/$i";
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
		}
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

