#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

my $dir=getcwd;

open R,">$ARGV[12]" or die $!; #####
print R "<!doctype html>\n";
print R "<html lang=\"zh-CN\">\n";
print R "<head>\n";
print R "\t<meta charset=\"utf-8\">\n";
print R "\t<meta name=\"renderer\" content=\"webkit|ie-comp|ie-stand\">\n";
print R "\t<meta http-equiv=\"X-UA-Compatible\" content=\"IE=Edge,chrome=1\">\n";
print R "\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, user-scalable=no\">\n";
print R "\t<title>Function_annotation_result</title>\n";
print R "\t<style type=\"text/css\" rel=\"stylesheet\">\n";
print R "\thtml,body,tbody,tr,td{margin:0;padding:0;font-size: 14px;}\n";
print R "\ttable {border-collapse: collapse;border-spacing: 0;}\n";
print R "\t.maintbody{width:1000px;margin:50px auto;}\n";
print R "\t.maintbody table{width:100%;border: 1px solid #efefef;}\n";
print R "\t.maintbody tbody tr td{font-family: \"Arial\",\"Helvetica\",sans-serif;padding:10px 15px;border-right: 1px solid #efefef;border-bottom: 1px solid #efefef;}\n";
print R "\t.maintbody tbody tr td.tdsplist{width: 850px;line-height:20px;display: block;word-wrap: break-word; border-right: none;}\n";
print R "\t.maintbody tbody tr td.tdlast{border-bottom: none;}\n";
print R "\t</style>\n";
print R "<head>\n";
print R "<body>\n";
print R "<div class=\"maintbody\">\n";
print R "\t<table>\n";
print R "\t\t<tbody>\n";

my %hash;

if(-e $ARGV[0]){
	open KEGG,"$ARGV[0]" or die $!;
	while (my $kegg=<KEGG>){
		chomp $kegg;
		my @KE=split /\t/,$kegg;
		$hash{$KE[0]}{"KEGG"}{"ident"}=$KE[1];
		$hash{$KE[0]}{"KEGG"}{"anno"}=$KE[2];
	}
}
close KEGG;

if (-e $ARGV[1]){
	open COG,"$ARGV[1]" or die $!;
	while (my $cog=<COG>){
		chomp $cog;
		my @CO=split /\t/,$cog;
		$hash{$CO[0]}{"COG"}{"ident"}=$CO[1];
		$hash{$CO[0]}{"COG"}{"anno"}=$CO[2];
	}
}	
close COG;

if(-e $ARGV[2]){
	open ANTI,"$ARGV[2]" or die $!;
	while (my $anti=<ANTI>){
		chomp $anti;
		my @AN=split /\t/,$anti;
		$hash{$AN[0]}{"antiSMASH"}{"ident"}=$AN[1];
		$hash{$AN[0]}{"antiSMASH"}{"anno"}=$AN[2];
	}
}	
close ANTI;

if(-e $ARGV[3]){
	open CARD,"$ARGV[3]" or die $!;
	while (my $card=<CARD>){
		chomp $card;
		my @CA=split /\t/,$card;
		$hash{$CA[0]}{"CARD"}{"ident"}=$CA[1];
		$hash{$CA[0]}{"CARD"}{"anno"}=$CA[2];
	}
}
close CARD;

if(-e $ARGV[4]){
	open CAZY,"$ARGV[4]" or die $!;
	while (my $cazy=<CAZY>){
		chomp $cazy;
		my @CAZ=split /\t/,$cazy;
		$hash{$CAZ[0]}{"CAZy"}{"ident"}=$CAZ[1];
		$hash{$CAZ[0]}{"CAZy"}{"anno"}=$CAZ[2];
	}
}
close CAZY;

if(-e $ARGV[5]){
	open META,"$ARGV[5]" or die $!;
	while (my $meta=<META>){
		chomp $meta;
		my @ME=split /\t/,$meta;
		$hash{$ME[0]}{"MetaCyc"}{"ident"}=$ME[1];
		$hash{$ME[0]}{"MetaCyc"}{"anno"}=$ME[2];
	}
}
close META;

if(-e $ARGV[6]){
	open NR,"$ARGV[6]" or die $!;
	while (my $nr=<NR>){
		chomp $nr;
		my @N=split /\t/,$nr;
		$hash{$N[0]}{"NR"}{"ident"}=$N[1];
		$hash{$N[0]}{"NR"}{"anno"}=$N[2];
	}
}
close NR;

if(-e $ARGV[7]){
	open PHI,"$ARGV[7]" or die $!;
	while (my $phi=<PHI>){
		chomp $phi;
		my @PH=split /\t/,$phi;
		$hash{$PH[0]}{"PHI"}{"ident"}=$PH[1];
		$hash{$PH[0]}{"PHI"}{"anno"}=$PH[2];
	}
}
close PHI;

if(-e $ARGV[8]){
	open SW,"$ARGV[8]" or die $!;
	while (my $swp=<SW>){
		chomp $swp;
		my @SWP=split /\t/,$swp;
		$hash{$SWP[0]}{"Swiss-Prot"}{"ident"}=$SWP[1];
		$hash{$SWP[0]}{"Swiss-Prot"}{"anno"}=$SWP[2];
	}
}
close SW;

if(-e $ARGV[9]){
	open VFDB,"$ARGV[9]" or die $!;
	while (my $vfdb=<VFDB>){
		chomp $vfdb;
		my @VF=split /\t/,$vfdb;
		$hash{$VF[0]}{"VFDB"}{"ident"}=$VF[1];
		$hash{$VF[0]}{"VFDB"}{"anno"}=$VF[2];
	}
}
close VFDB;

if(-e $ARGV[10]){
	open PFAM,"$ARGV[10]" or die $!;
	while(my $pfam=<PFAM>){
		chomp $pfam;
		my @PF=split /\t/,$pfam;
		$hash{$PF[0]}{"Pfam"}{"ident"}=$PF[1];
	}
}	
close PFAM;

my @alldb=("KEGG","COG","antiSMASH","CARD","CAZy","MetaCyc","NR","PHI","Swiss-Prot","VFDB","Pfam");
my $num=0;
my %sum;
foreach my $key (keys %hash){
	$sum{$key}=1;
	foreach my $db(@alldb){
		if (defined $hash{$key}{$db}{"ident"}){
			if($db eq "Pfam"){
				if($hash{$key}{$db}{"ident"} ne "NA"){
					$sum{$key}+=1;
				}
				else{next;}	
			}
			else{
				if($hash{$key}{$db}{"ident"} >0){
					$sum{$key}+=1;
				}
				else{next;}
			}
		}
	}	
}
open GFF,"$ARGV[11]" or die $!; ####$dir/prodigal.faa.info
while(my $gff=<GFF>){
	chomp $gff;
	my @GF=split /\t/,$gff;
	if(defined $sum{$GF[0]}){
		my $total=$sum{$GF[0]};
		print R "\t\t\t<tr>\n";
		print R "\t\t\t\t<td rowspan=\"$total\"> $GF[0]</td>\n";
		print R "\t\t\t\t<td>coordinate</td>\n";
		print R "\t\t\t\t<td colspan=\"2\">$GF[4]&nbsp;&nbsp;$GF[1]..$GF[2]&nbsp;&nbsp;($GF[3])&nbsp;&nbsp;sequence:&nbsp<a href=\"faa.html#$GF[0]\" target=\"_blank\">Amino Acid</a>&nbsp;&nbsp;<a href=\"fna.html#$GF[0]\" target=\"_blank\">Nucleotide</a></td>\n";
		print R "\t\t\t</tr>\n";
		foreach my $db(@alldb){
			if (defined $hash{$GF[0]}{$db}{"ident"}) {
				if ($db eq "Pfam") {
					if($hash{$GF[0]}{$db}{"ident"} ne "NA"){
						print R "\t\t\t<tr>\n";
						print R "\t\t\t\t<td>$db</td>\n";
						print R "\t\t\t\t<td colspan=\"2\">$hash{$GF[0]}{$db}{\"ident\"}</td>\n";
						print R "\t\t\t</tr>\n";
					}
					else{next;}
				}
				else{
					if($hash{$GF[0]}{$db}{"ident"} >0){
						print R "\t\t\t<tr>\n";
						print R "\t\t\t\t<td>$db</td>\n";
						print R "\t\t\t\t<td>$hash{$GF[0]}{$db}{\"ident\"}</td>\n";
						print R "\t\t\t\t<td>$hash{$GF[0]}{$db}{\"anno\"}</td>\n";
						print R "\t\t\t</tr>\n";
					}	
				}
			}	
		}	
	}
}
close GFF;
print R "\t\t</tbody>\n";
print R "\t</table>\n";
print R "</div>\n";
print R "</body>\n";
print R "</html>\n";
