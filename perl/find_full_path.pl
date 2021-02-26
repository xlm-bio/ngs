open (FIN,"/home/hxx/NCBI/taxonomy-20180530.txt");
while ($str=<FIN>) {
    chomp;
    @ae=split /\t/,$str;
    $taxoParent{$ae[0]} = $ae[1];
    $taxoId{$ae[4]} = $ae[0];
    $taxoLevel{$ae[0]} = $ae[2];
    $taxoname{$ae[0]} = $ae[4];
    for $i (5..7) {
        if ($ae[$i]=~/;/) {
            @subae = split /;/, $ae[$i];
            foreach (@subae) { if (!exists($taxoId{$_})) { $taxoId{$_} = $ae[0]; } }
        } elsif (!exists($taxoId{$ae[$i]})) { $taxoId{$ae[$i]} = $ae[0]; }
    }
}
close FIN;
sub findfullpath {
	my $root = shift @_;
        if ($taxoLevel{$root} =~ /no rank/){
                $t="no rank__";
        }else{
                $t=substr($taxoLevel{$root},0,1)."__";
        }
        $str="|".$t.$taxoname{$root}.$str;
        if (! exists $taxoParent{$root}) {
                return substr($str,13,length($str)-13);
        } else {
            findfullpath ($taxoParent{$root});
        }
}
print findfullpath(7);
