$soft = $ARGV[1];
@array = split (/_/,$soft);
$n=1;
open (FINB, $ARGV[0]);
do {
    $flag = defined ($str=<FINB>);
    chomp $str;
    if ($str=~/^>/ || $flag==0) {
            if ($seq ne "") {
                if (length($seq)>=500)  {
               print ">", "$array[0]", "_", $n, "\n";
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
