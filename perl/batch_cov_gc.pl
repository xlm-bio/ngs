$window_size=$ARGV[2];	###滑框大小
$window_ms=$ARGV[3];	###移动距离

sub calGC {             ###计算GC含量
    my $str = $_[0];
    my @array = split //,$str;
    my $GC = 0;
    for ($m=0;$m<scalar(@array);$m++) {
        if (($array[$m] eq "G")||($array[$m] eq "C")) {
            $GC++;
        }
    }
    my $len = length($str);
    return $GC/$len*100;
}

open (FINA, $ARGV[0]);  ###读取depth文件
while ($line=<FINA>){
    chomp $line;
    @arr=split(/\s/,$line);
    $hash{$arr[0]}{$arr[1]}=$arr[2];
}

open (FINB, $ARGV[1]); ###读取fasta文件
$n=1;
do {
    $flag = defined ($str=<FINB>);
    chomp $str;
    if ($str=~/^>/ || $flag==0) {
            if ($seq ne "") {
                $cord{$id}=$seq;
                $n++
            }
	    $id=substr($str,1);
            $seq = "";
        } else {
            $seq = $seq.$str;
        }
} while ($flag);

@keys=sort { $a <=> $b } keys %cord;
foreach my $key (@keys){
    open (RESULT,">".$ARGV[4]."/".$key.".txt");
    for ($i=0; $i < length $cord{$key}; $i=$i+$window_ms) {
    $window=substr($cord{$key},$i,$window_size);
    $len=(length $cord{$key})-$i;
        if ($len >= 500){
            for ( $j = $i; $j < $i+$window_size;$j++){
            $avg_cov=$avg_cov+$hash{$key}{$j+1};
            }
        print RESULT $avg_cov/$window_size,"\t",calGC($window),"\n";
        }
    $avg_cov=0;
    $window="";
    $j=0;
    }
}
