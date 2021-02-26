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
print "ID","\t","Scaffold_number","\t","N50","\t","N75","\t","Largest_Scaffold","\t","Total_length","\t","GC%","\t","N's","\n";
foreach my $file (@pathlist) {
    $n=1;
    $full_len=0;
    if (($file =~ m/^.+.fasta$/g) || ($file =~ m/^.+.fna$/g)){
        open (FINB, "$dir/$file") or die "can't open the directory!";
        do {
            $flag = defined ($str=<FINB>);
            chomp $str;
            if ($str=~/^>/ || $flag==0) {
                    if ($seq ne "") {
                        $full_len=$full_len+length($seq);
                        $id=">"."Scaffold"."_".$n;
                        $hash{$id}=length($seq);
                        $n++;
                    }
                    $seq = "";
                } else {
                    $seq = $seq.$str;
                    $full = $full.$str;
                }
        } while ($flag);

        
        @keys=sort { $hash{$b} <=> $hash{$a} } keys %hash;
        foreach my $key (@keys) {
            $half=$half+$hash{$key};
            if ( ! grep ("$dir/$file" , @outlier) ){
                if (($half >= $full_len/2) && ($half-$hash{$key} <= $full_len/2)) {
                    $N50 = $hash{$key};
                    if (($half >= $full_len*0.75) && ($half-$hash{$key} <= $full_len*0.75)){
                        print $file,"\t", scalar(@keys),"\t",$N50,"\t",$hash{$key},"\t",$hash{$keys[0]},"\t",length $full,"\t", calGC($full),"\t",calN($full),"\n";
                        last;
                    }
                }
                elsif (($half >= $full_len*0.75) && ($half-$hash{$key} <= $full_len*0.75)) {
                    print $file,"\t", scalar(@keys),"\t",$N50,"\t",$hash{$key},"\t",$hash{$keys[0]},"\t",length $full,"\t", calGC($full),"\t",calN($full),"\n";
                    last;
                }
            }
        }
        close (FINB);
        %hash=();
        $full="";
        $seq="";
        $half=0;
        $N50=0;
    }
}

