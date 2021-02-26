$kmer = $ARGV[1];
$span = $ARGV[2];
open (FIN, $ARGV[0]);
do {
    $flagForScan = defined($str=<FIN>);
    chomp $str;
    $stpos = index ($str, ">");
    if ($stpos!=-1 || !$flagForScan) {
        if ($id ne "") {
            ## ($id, $seq)
            ## add something
			if (rand()<0.2) {
				$p = 0;
				while ($seq=~/(?=(.{$kmer}))/g) {
					$p++;
					@arr = split //, $1;
					for $i (0..$kmer-2) {
						for $j ($i+1..$kmer-1) {
							@temparr = @arr;
							$temparr[$i] = "N";
							$temparr[$j] = "N";
							$tempstr = join "", @temparr;
							$hash{$tempstr}++;
							$pos{$tempstr}{$p} = 1;
						}
					}
				}
			}
        }
        $enpos = index($str, " ");
        if ($enpos!=-1) {
            $id = substr($str, $stpos+1, $enpos-$stpos-1);
        } else {
            $id = substr($str, $stpos+1);
        }
        $seq = "";
    } else {
        chomp $str;
        $seq = $seq.$str;
    }
} while ($flagForScan);

foreach $str (sort {$hash{$b}<=>$hash{$a}} keys %hash) {
	print $str, "\t", $hash{$str}, "\t";
	@arr = sort {$a<=>$b} keys %{$pos{$str}};
	foreach (@arr) {
		print $_, " ";
	}
	print "\n";
}
