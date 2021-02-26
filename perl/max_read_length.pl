open(FIN,$ARGV[0]);
$max=0;
while ($line = <FIN>){
    chomp $line;
    if ($n % 4 == 0) {
	$ID=$line;
    }
    if ($n % 4 == 1) {
	    if (length $line > $max){
		$id = $ID;
       		$max=length $line;
		$seq=$line;
	    }
    }
    $n++;
}
print $id,"\n";
print $max;
close (FIN);

