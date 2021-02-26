open (FASTA, $ARGV[0]);        ###fasta原文件
do {
    $flag = defined ($str=<FASTA>);
    chomp $str;
    if ($str=~/^>/ || $flag==0) {
            if ($seq ne "" && ! exists $tag{$id}) {
                print ">".$id,"\n",$seq,"\n";
		$tag{$id}=1;
	    }
            $id = substr($str,1);
            $seq = "";
        } else {
            $seq = $seq.$str;
        }
} while ($flag);
close (FASTA);

