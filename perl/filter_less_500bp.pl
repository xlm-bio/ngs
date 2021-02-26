$n=1;
$ID=$ARGV[1];
open (FINB, $ARGV[0]);
do {
    $flag = defined ($str=<FINB>);
    chomp $str;
    if ($str=~/^>/ || $flag==0) {
            if ($seq ne "") {
                if (length($seq)>=500)  {
               		   print ">", $ID , "_", $n, "\n";
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
