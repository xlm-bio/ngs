open (PRODIGAL,$ARGV[0]); ###default.pep
while ($line=<PRODIGAL>){
        chomp $line;
        if ($line=~/^>/){
                @arr=split(/#/,$line);
                $pepID=substr($arr[0],1);
                $pepID =~ s/^\s+|\s+$//g;
                @tmp1=split(/_/,$arr[0]);
                $arr[1]=~ s/^\s+|\s+$//g;
                $arr[2]=~ s/^\s+|\s+$//g;
                $pos=$arr[1]."_".$arr[2]."_CDS";
                $type{substr($tmp1[0],1)}{$pos}="CDS";
                if ($arr[3]==1){
                        $strand{substr($tmp1[0],1)}{$pos}="+";
                }else{
                        $strand{substr($tmp1[0],1)}{$pos}="-";
                }
                $tmp2=split(/;/,$arr[4]);
                @tmp3=split(/=/,$tmp2[1]);
                $partial{substr($tmp1[0],1)}{$pos}=$tmp3[1];
                $chr{$pepID}=substr($tmp1[0],1);
                $pos{$pepID}=$pos;
        }
}
open (RNAMMER,$ARGV[1]); ##default_RNAmmer.gff
while ($line=<RNAMMER>){
	chomp $line;
	if ($line !~ /^#/){
		@arr=split(/\t/,$line);
		$pos=$arr[3]."_".$arr[4]."_rRNA";
		$type{$arr[0]}{$pos}=$arr[8];
		$rRNA_score{$arr[0]}{$pos}=$arr[5];
		$strand{$arr[0]}{$pos}=$arr[6];
	}
}
open (TRNA,$ARGV[2]); ##default_tRNAscan.out
<TRNA> for (1..3);	
while ($line=<TRNA>){
	chomp $line;
	@arr=split(/\s/,$line);
	@arr = grep { $_ ne "" } @arr;
	if ($arr[3] > $arr[2]){
		$pos=$arr[2]."_".$arr[3]."_tRNA";
		$strand{$arr[0]}{$pos}="+";
	}else{
		$pos=$arr[3]."_".$arr[2]."_tRNA";
        	$strand{$arr[0]}{$pos}="-";
	}
	$type{$arr[0]}{$pos}="tRNA";
	$tRNA_score{$arr[0]}{$pos}=$arr[8];
}

open (RFAMCLASS,"/data/public_tools/Rfam/rfam_anno_class.txt");
while ($line=<RFAMCLASS>){
        chomp $line;
        @arr=split(/\t/,$line);
        $arr[0] =~ s/^\s+|\s+$//g;
        $arr[-1] =~ s/^\s+|\s+$//g;
        $RFAMclass{$arr[0]}=$arr[-1];
}
close RFAMCLASS;
open (RFAM,$ARGV[3]); ###default_Rfam.tblout
while ($line=<RFAM>){
        chomp $line;
        if ($line !~ /^#/){
                @arr=split(/\s/,$line);
                @arr= grep { $_ ne "" } @arr;
                $pos=$arr[9]."_".$arr[10]."_sRNA";
                if ($RFAMclass{$arr[2]} eq "sRNA"){
                        $type{$arr[3]}{$pos}=$RFAMclass{$arr[2]};
                        $strand{$arr[3]}{$pos}=$arr[11];
                }
        }
}
###COG-NUMBER-TO-COG-ID
open (COGID,"/data/database/functional-database/cog/cog.number.COGnumber.list");
while ($line=<COGID>){
	chomp $line;
	@arr=split(/\t/,$line);
	$COGid{$arr[0]}=$arr[1];
}
close COGID;
###COG-CLASSIFICATION
open (Classification,"/data/database/functional-database/cog/classification_cog.txt");
while($line=<Classification>){
        chomp $line;
        @arr = split (/\s/,$line);
        $COGclass{$arr[1]} = $arr[0];
}
close Classification;
###COG-TO-GENE
open (COGIDTOGENE,"/data/database/functional-database/cog/cog2003-2014.csv");
while ($line=<COGIDTOGENE>){
	chomp $line;
	@arr=split(/,/,$line);
	$COGgene{$arr[6]}=$arr[0];
}
close COGIDTOGENE;
###COG-TO-GENE-TO-SPECIES
open (GENETOTAX,"/data/database/functional-database/cog/prot2003-2014.fa");
while ($line=<GENETOTAX>){
	chomp $line;
	if ($line=~/^>/){
		@arr=split(/\|/,$line);
		$COGspecies{$arr[1]}=$arr[4];
	}
}
close GENETOTAX;

open (COG,$ARGV[4]); ##default_COG.dmd
while ($line=<COG>){
	chomp $line;
	@arr=split(/\t/,$line);
	$COG{$chr{$arr[0]}}{$pos{$arr[0]}}=$COGid{$arr[1]};
}
close COG;
###KEGG-GENE-TO-K-NUMBER
open (GENETOKNUM,"/data/database/functional-database/KEGG/gene_id-K_number-brite_number-classifacatiopn/prokaryotes.dat");
while ($line=<GENETOKNUM>){
	chomp $line;
	@arr=split(/\t/,$line);
	$knum{$arr[0]}=$arr[1];
	$genedes{$arr[0]}=$arr[3];
}
close GENETOKNUM;
###KEGG-K-NUMBER-TO-PATHWAY
open (PATHWAY,"/data/database/functional-database/KEGG/gene_id-K_number-brite_number-classifacatiopn/pathway_ko.list");
while ($line=<PATHWAY>){
	chomp $line;
	if ($line=~/map/){
		@arr=split(/\s/,$line);
		@tmp1=split(/:/,$arr[0]);
		@tmp2=split(/:/,$arr[1]);
		$pathway{$tmp2[1]}=substr($tmp1[1],3);
	}
}
close PATHWAY;
###KEGG-CLASSIFICATION
open (KEGGCLASS,"/data/database/functional-database/KEGG/gene_id-K_number-brite_number-classifacatiopn/pathway.list");
while ($line=<KEGGCLASS>){
	chomp $line;	
	if ($line=~/^#[^#]/){
		$class=substr($line,1);
	}elsif ($line !~ /^#/){
		@arr=split(/\s/,$line);
		$KEGGclass{$arr[0]}=$class;
	}
}
close KEGGCLASS;
open (KEGG,$ARGV[5]); ###default_KEGG.dmd
while ($line=<KEGG>){
	chomp $line;
	@arr=split(/\t/,$line);
	$KEGG{$chr{$arr[0]}}{$pos{$arr[0]}}=$arr[1];
}
print "ChrID	Source	Type	Start_position	End_position	Score	Strand	Phase	Partial	COG	KEGG","\n";
foreach  my $chr (sort {$a<=>$b} keys  %type){
	foreach my $pos (sort {$a<=>$b} keys %{$type{$chr}}){
		@tmp=split(/_/,$pos);
		if ($type{$chr}{$pos} eq "CDS"){
			if (exists $COG{$chr}{$pos}){
				$COG_ID=$COG{$chr}{$pos};
				$COG_geneid=$COGgene{$COG_ID};
				$COG_species=$COGspecies{$COG_geneid};
				$COG_class=$COGclass{$COG_ID};
				$COG_info=$COG_geneid." | ".$COG_ID." | ".$COG_species." | ".$COG_class;
			}else{
				$COG_info="#";
			}
			if (exists $KEGG{$chr}{$pos} && $knum{$KEGG{$chr}{$pos}} ne "" && $pathway{$knum{$KEGG{$chr}{$pos}}} ne ""){
				$KEGG_geneid=$KEGG{$chr}{$pos};
				$KEGG_genedes=$genedes{$KEGG_geneid};
				$KEGG_Knum=$knum{$KEGG_geneid};
				$KEGG_pathid=$pathway{$KEGG_Knum};
				$KEGG_class=$KEGGclass{$KEGG_pathid};
				$KEGG_info=$KEGG_geneid." | ".$KEGG_genedes." | ".$KEGG_Knum." | ".$KEGG_class;
			}else{
				$KEGG_info="#";
			}
			print $chr,"\t","Prodigal","\t","CDS","\t",$tmp[0],"\t",$tmp[1],"\t","#","\t",$strand{$chr}{$pos},"\t","#","\t",$partial{$chr}{$pos},"\t",$COG_info,"\t",$KEGG_info,"\n";
		}elsif ($type{$chr}{$pos} eq "5s_rRNA"){
			print $chr,"\t","RNAmmer","\t","5s_rRNA","\t",$tmp[0],"\t",$tmp[1],"\t",$rRNA_score{$chr}{$pos},"\t",$strand{$chr}{$pos},"\t","#","\t","#","\t","#","\t","#","\n";
		}elsif ($type{$chr}{$pos} eq "23s_rRNA"){
			print $chr,"\t","RNAmmer","\t","23s_rRNA","\t",$tmp[0],"\t",$tmp[1],"\t",$rRNA_score{$chr}{$pos},"\t",$strand{$chr}{$pos},"\t","#","\t","#","\t","#","\t","#","\n";
		}elsif ($type{$chr}{$pos} eq "16s_rRNA"){
			print $chr,"\t","RNAmmer","\t","16s_rRNA","\t",$tmp[0],"\t",$tmp[1],"\t",$rRNA_score{$chr}{$pos},"\t",$strand{$chr}{$pos},"\t","#","\t","#","\t","#","\t","#","\n";
		}elsif ($type{$chr}{$pos} eq "tRNA"){
			print $chr,"\t","tRNAscanSE","\t","tRNA","\t",$tmp[0],"\t",$tmp[1],"\t",$tRNA_score{$chr}{$pos},"\t",$strand{$chr}{$pos},"\t","#","\t","#","\t","#","\t","#","\n";
		}elsif ($type{$chr}{$pos} eq "sRNA"){
			print $chr,"\t","RFAM","\t","sRNA","\t",$tmp[0],"\t",$tmp[1],"\t","#","\t",$strand{$chr}{$pos},"\t","#","\t","#","\t","#","\t","#","\n";
		}
	}
}
