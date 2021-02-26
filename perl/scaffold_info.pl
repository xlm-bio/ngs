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
    $G = sprintf "%0.2f",$GC/$len;
    return $G;
}

open (FINA, $ARGV[0]);  ###读取depth文件
while ($line=<FINA>){
    chomp $line;
    @arr=split(/\s/,$line);
    $hash{$arr[0]}=$hash{$arr[0]}+$arr[2];
}

open (FINB, $ARGV[1]); ###读取fasta文件
print "Scaffold_ID","\t","Length","\t","GC","\t","ReadDepth","\n";
do {
    $flag = defined ($str=<FINB>);
    chomp $str;
    if ($str=~/^>/ || $flag==0) {
            $str =~ s/>//g;
            if ($seq ne "") {
		$COV = sprintf "%0.2f", $hash{$ID}/length $seq;
                print $ID,"\t",length $seq,"\t",calGC($seq),"\t",$COV,"\n";
            }
            $seq = "";
            $ID = $str;
        } else {
            $seq = $seq.$str;
        }
} while ($flag);

