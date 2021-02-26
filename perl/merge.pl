open (FINB,$ARGV[0]);
while ($line=<FINB>){
    chomp $line;
    @BGI=split(/\t/,$line);
    $BGI_data{$BGI[0]}=$BGI[1]."\t".$BGI[2]."\t".$BGI[3]."\t".$BGI[4]."\t".$BGI[5];
}

open (FINA,$ARGV[1]);
$tmp=0;
$n=0;
do {
    $flag = defined ($str=<FINA>);
    chomp $str;
    @WDCM=split(/\t/,$str);
    if (exists $BGI_data{$WDCM[0]} && $tmp ne $WDCM[0]){
        $tmp=$WDCM[0];
	$n++;
        print $n,"\t",$WDCM[0],"\t",$BGI_data{$WDCM[0]},"\n";
        print $n,"\t",$WDCM[1],"\t",$WDCM[2],"\t",$WDCM[3],"\t",$WDCM[4],"\t",$WDCM[5],"\t",$WDCM[6];
    }elsif (exists $BGI_data{$WDCM[0]} && $tmp eq $WDCM[0]){
        print $n,"\t",$WDCM[1],"\t",$WDCM[2],"\t",$WDCM[3],"\t",$WDCM[4],"\t",$WDCM[5],"\t",$WDCM[6];
    }
} while ($flag);
