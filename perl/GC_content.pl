$window_size=$ARGV[1];	###滑框大小
$window_ms=$ARGV[2];	###移动距离

sub calGC {
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

open (FINB, $ARGV[0]); ###读取fasta文件
$n=1;
do {
    $flag = defined ($str=<FINB>);
    chomp $str;
    if ($str=~/^>/ || $flag==0) {
            if ($seq ne "") {
                $id="Scaffold"."_".$n;
                $cord{$id}=$seq;
                $n++;
		$full_seq=$full_seq.$seq;
            }
            $seq = "";
        } else {
            $seq = $seq.$str;
        }
} while ($flag);
$avr_GC=calGC($full_seq);
print $avr_GC,"\n";
@keys=sort { $a <=> $b } keys %cord;
open (RESULT,">".$ARGV[3]."/".GC_content.".txt");
foreach my $key (@keys){
    for ($i=0; $i < length $cord{$key}; $i=$i+$window_ms) {
    	$window=substr($cord{$key},$i,$window_size);
    	$len=(length $cord{$key})-$i;
        print RESULT $key,"\t",$i,"\t",$i,"\t",calGC($window)-$avr_GC,"\t";
	if (calGC($window)-$avr_GC >= 0 ){
		print RESULT "fill_color=105,105,105","\n";
	}else {
		print RESULT "fill_color=181,181,181","\n";
	}
    }
    $avg_cov=0;
    $window="";
    $j=0;
}

