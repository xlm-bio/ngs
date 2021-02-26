open (FINA,$ARGV[0]);
while ($line1=<FINA>){
    chomp $line1;
    @BGI=split(/\t/,$line1);
    $BGI_data{$BGI[0]}=$BGI[1]."\t".$BGI[2]."\t".$BGI[3]."\t".$BGI[4]."\t".$BGI[5];
}

open (FINB,$ARGV[1]);
while ($line2=<FINB>){
    chomp $line2;
    @LV=split(/\t/,$line2);
    $LV_data{$LV[0]}=$LV[1]."\t".$LV[2]."\t".$LV[3]."\t".$LV[4]."\t".$LV[5];
}

open (FINC,$ARGV[2]);
$tmp=0;
$n=0;
do {
    $flag = defined ($str=<FINC>);
    chomp $str;
    @WDCM=split(/\t/,$str);
    if (exists $BGI_data{$WDCM[0]} && exists $LV_data{$WDCM[0]}){
        if ($tmp ne $WDCM[0]){
            $tmp=$WDCM[0];
            $n++;
            print $n,"\t",$WDCM[0],"\t",$WDCM[0]."_bgi","\t","1","\t","0","\t",$BGI_data{$WDCM[0]},"\n";
            print $n,"\t",$WDCM[0],"\t",$WDCM[0]."_imcas","\t","0","\t","0","\t",$LV_data{$WDCM[0]},"\n";
            print $n,"\t",$WDCM[0],"\t",$WDCM[1],"\t","","\t","1","\t",$WDCM[2],"\t",$WDCM[3],"\t",$WDCM[4],"\t",$WDCM[5],"\t",$WDCM[6];
        }elsif ($tmp eq $WDCM[0]){
            print $n,"\t",$WDCM[0],"\t",$WDCM[1],"\t","","\t","1","\t",$WDCM[2],"\t",$WDCM[3],"\t",$WDCM[4],"\t",$WDCM[5],"\t",$WDCM[6];
        }
    }elsif(exists $BGI_data{$WDCM[0]} && ! exists $LV_data{$WDCM[0]}){
        if ($tmp ne $WDCM[0]){
            $tmp=$WDCM[0];
            $n++;
            print $n,"\t",$WDCM[0],"\t",$WDCM[0]."_bgi","\t","1","\t","0","\t",$BGI_data{$WDCM[0]},"\n";
            print $n,"\t",$WDCM[0],"\t",$WDCM[1],"\t","","\t","1","\t",$WDCM[2],"\t",$WDCM[3],"\t",$WDCM[4],"\t",$WDCM[5],"\t",$WDCM[6];
        }elsif ($tmp eq $WDCM[0]){
            print $n,"\t",$WDCM[0],"\t",$WDCM[1],"\t","","\t","1","\t",$WDCM[2],"\t",$WDCM[3],"\t",$WDCM[4],"\t",$WDCM[5],"\t",$WDCM[6];
        }
    }elsif( !exists $BGI_data{$WDCM[0]} && exists $LV_data{$WDCM[0]}){
        if ($tmp ne $WDCM[0]){
            $tmp=$WDCM[0];
            $n++;
            print $n,"\t",$WDCM[0],"\t",$WDCM[0]."_imcas","\t","0","\t","0","\t",$LV_data{$WDCM[0]},"\n";
            print $n,"\t",$WDCM[0],"\t",$WDCM[1],"\t","","\t","1","\t",$WDCM[2],"\t",$WDCM[3],"\t",$WDCM[4],"\t",$WDCM[5],"\t",$WDCM[6];
        }elsif ($tmp eq $WDCM[0]){
            print $n,"\t",$WDCM[0],"\t",$WDCM[1],"\t","","\t","1","\t",$WDCM[2],"\t",$WDCM[3],"\t",$WDCM[4],"\t",$WDCM[5],"\t",$WDCM[6];
        }
    }else{
        if ($tmp ne $WDCM[0]){
            $tmp=$WDCM[0];
            $n++;
            print $n,"\t",$WDCM[0],"\t",$WDCM[1],"\t","","\t","1","\t",$WDCM[2],"\t",$WDCM[3],"\t",$WDCM[4],"\t",$WDCM[5],"\t",$WDCM[6];
        }else {
            print $n,"\t",$WDCM[0],"\t",$WDCM[1],"\t","","\t","1","\t",$WDCM[2],"\t",$WDCM[3],"\t",$WDCM[4],"\t",$WDCM[5],"\t",$WDCM[6];
        }
    }
} while ($flag);
