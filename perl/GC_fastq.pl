sub calGC {
    my $str = $_[0];
    my @array = split //,$str;
    my $GC = 0;
    for ($i=0;$i<scalar(@array);$i++) {
        if (($array[$i] eq "G")||($array[$i] eq "C")) {
            $GC++;
        }
    }
    my $len = length($str);
    return $GC/$len*100;
}

$seq = "";
$n=0;
open(FIN,$ARGV[0]);
while ($line = <FIN>){
    chomp $line;
    if ($n % 4 == 1) {
            $seq = $seq.$line;
        }
    $n++;
    if ($n > 20000){
        print calGC($seq);
        last;
    }
}
close (FIN);
