###过滤低于某长度的序列
$n=1;
open (FINB, $ARGV[0]);
do {
    $flag = defined ($str=<FINB>);
    chomp $str;
    if ($str=~/^>/ || $flag==0) {
            if ($seq ne "") {
		if (length($seq)>=300)  {
               print ">", "Scaffold", "_", $n, "\n";
			   print $seq,"\n";
			   $n++;
        	    }
		}
            $seq = "";
        } else {
            $seq = $seq.$str;
        }
} while ($flag);
close (FINB);
