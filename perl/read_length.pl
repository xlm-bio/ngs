open(FIN,$ARGV[0]);
$flag=0;
while ($line = <FIN>){
    chomp $line;
    if ($n % 4 == 1) {
            $s++;
            $length=$length+(length $line);
        }
    $n++;
    if ($s > 20000){
        print $length/$s;
	$flag=1;
        last;
    }
}
if (!$flag){
	print $length/$s;
}
close (FIN);
