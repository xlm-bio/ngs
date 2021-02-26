$window_size=$ARGV[1];	###滑框大小
$window_ms=$ARGV[2];	###移动距离

sub calGC {
    my $str = $_[0];
    my @array = split //,$str;
    my $G = 0;
    my $C = 0;
    for ($m=0;$m<scalar(@array);$m++) {
        if ($array[$m] eq "G"){
		$G++;
	}elsif ($array[$m] eq "C") {
            	$C++;
        }
    }
    my $len = length($str);
    return ($G-$C)/($G+$C);
}

open (FINB, $ARGV[0]); ###读取fasta文件
$n=1;
do {
    $flag = defined ($str=<FINB>);
    chomp $str;
    if ($str=~/^>/ || $flag==0) {
            if ($seq ne "") {
                $id="Scaffold"."_".$n;
                $cord{$id}=$seq;
                $n++
            }
            $seq = "";
        } else {
            $seq = $seq.$str;
        }
} while ($flag);

@keys=sort { $a <=> $b } keys %cord;
open (RESULT,">".$ARGV[3]."/".GC_skew.".txt");
foreach my $key (@keys){
    for ($i=0; $i < length $cord{$key}; $i=$i+$window_ms) {
    	$window=substr($cord{$key},$i,$window_size);
    	$len=(length $cord{$key})-$i;
        print RESULT $key,"\t",$i,"\t",$i,"\t",calGC($window),"\t";
	if (calGC($window) > 0){
		print RESULT "fill_color=49,130,189","\n";
	}else{
		print RESULT "fill_color=198,219,239","\n";
	}
    }
    $avg_cov=0;
    $window="";
    $j=0;
}
