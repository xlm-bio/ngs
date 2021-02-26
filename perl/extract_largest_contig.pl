###提取最大的contig；perl *.pl $dir $file2
$name=$ARGV[1];
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

sub calN {
    my $str = $_[0];
    my @array = split //,$str;
    my $N = 0;
    for ($i=0;$i<scalar(@array);$i++) {
        if (($array[$i] eq "N")||($array[$i] eq "n")) {
            $N++;
        }
    }
    return $N;
}

$dir=$ARGV[0];
opendir (DIR, $dir) or die "can't open the directory!";
@pathlist=readdir DIR;
foreach my $file (@pathlist) {
    $n=1;
    $full_len=0;
    if ($file =~ m/^.*.fasta/g){
        open (FINB, "$dir/$file") or die "can't open the directory!";
        do {
            $flag = defined ($str=<FINB>);
            chomp $str;
            if ($str=~/^>/ || $flag==0) {
                    if ($seq ne "") {
                        $full_len=$full_len+length($seq);
                        $id=">"."Scaffold"."_".$n;
                        $s{$id}=$seq;
                        $hash{$id}=length($seq);
                        $n++
                    }
                    $seq = "";
                } else {
                    $seq = $seq.$str;
                    $full = $full.$str;
                }
        } while ($flag);

        
        @keys=sort { $hash{$b} <=> $hash{$a} } keys %hash;
        if ($hash{$keys[0]} > 1000){
	    @tmp=split (/\./,$file);
            print $keys[0],"_",$name,"_",$tmp[0]," ",$hash{$keys[0]},"\n",$s{$keys[0]},"\n";
        }
        
        close (FINB);
        %hash=();
        $full="";
        $seq="";
        %s=();
	@tmp=();
    }
}


