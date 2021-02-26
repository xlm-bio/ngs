open (FIN, $ARGV[0]);
$n=0;
while ($line=<FIN>){
    chomp $line;
    if ($n > 0){
        @arr=split(/\t/,$line);
        $CN{$arr[0]}=$arr[1];
        $N50{$arr[0]}=$arr[2];
        $N75{$arr[0]}=$arr[3];
        $LC{$arr[0]}=$arr[4];
        $TL{$arr[0]}=$arr[5];
        $N{$arr[0]}=$arr[7];
    }
    $n++;
}
$min_CN = 1000000;
@CN_keys=sort { $CN{$b} <=> $CN{$a} } keys %CN;
foreach my $key (@CN_keys){
    if ($N50{$key} >= $ARGV[1] && $TL{$key} >= $ARGV[2]){
        if ($CN{$key} < $min_CN){
            $min_CN = $CN{$key};
        }
    }
}

$CN_cw= (($min_CN*3 - $min_CN)/100);
foreach my $key (@CN_keys){
    if ($CN{$key} <= $min_CN){
        $CN_score{$key}=100;
    }elsif($CN{$key} >= $min_CN*3){
        $CN_score{$key}=0;
    }else{
    $CN_score{$key}=(100 - int (($CN{$key}-$min_CN)/$CN_cw));
    }
}

@N50_keys=sort { $N50{$b} <=> $N50{$a} } keys %N50;
$N50_cw = (($N50{$N50_keys[0]} - $N50_keys{$N50_keys[-1]})/100000); 
foreach my $key (@N50_keys){
    $N50_score{$key}=(int(($N50{$key}-$N50_keys{$N50_keys[-1]})/$N50_cw) + 1);
    if ($N50_score{$key} > 100000) {
        $N50_score{$key}=$N50_score{$key}-1;
    } 
}

@N75_keys=sort { $N75{$b} <=> $N75{$a} } keys %N75;
$N75_cw = (($N75{$N75_keys[0]} - $N75_keys{$N75_keys[-1]})/100000); 
foreach my $key (@N75_keys){
    $N75_score{$key}=(int(($N75{$key}-$N75_keys{$N75_keys[-1]})/$N75_cw) + 1);
    if ($N75_score{$key} > 100000) {
        $N75_score{$key}=$N75_score{$key}-1;
    }
}

@LC_keys=sort { $LC{$b} <=> $LC{$a} } keys %LC;
$LC_cw = (($LC{$LC_keys[0]} - $LC_keys{$LC_keys[-1]})/100000); 
foreach my $key (@LC_keys){
    $LC_score{$key}=(int(($LC{$key}-$LC_keys{$LC_keys[-1]})/$LC_cw) + 1);
    if ($LC_score{$key} > 100000) {
         $LC_score{$key}=$LC_score{$key}-1;
    } 
}

@TL_keys=sort { $TL{$b} <=> $TL{$a} } keys %TL;
$TL_cw =  (0.2*$ARGV[2]/100000); 
foreach my $key (@TL_keys){
    if ($TL{$key} <= 0.8*$ARGV[2]){
        $TL_score{$key}=0;
    }elsif($TL{$key} >= 1.2*$ARGV[2]){
        $TL_score{$key}=0;
    }else{
        $TL_score{$key} = (100000 - int (abs($TL{$key}-$ARGV[2])/$TL_cw));
    }
}
    
@N_keys=sort { $N{$b} <=> $N{$a} } keys %N;
$N_cw= (($N{$N_keys[0]} - $N_keys{$N_keys[-1]})/1000);
foreach my $key (@N_keys){
    $N_score{$key}=(1000 - int (($N{$key}-$N_keys{$N_keys[-1]})/$N_cw)); 
}

foreach my $key (@CN_keys){
    $score{$key}=($N50_score{$key}*0.0002 + $N75_score{$key}*0.00015 + $CN_score{$key}*0.35 + $LC_score{$key}*0.00015 + $N_score{$key}*0.005 + $TL_score{$key}*0.0001);
    print $key,"\t",$score{$key},"\n";
}
