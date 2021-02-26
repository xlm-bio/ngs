if (scalar(@ARGV)<1) {
    die "perl readStat.pl <read file>  \n";  
}

my $id = "";
my @lengthList = ();
my $lengthTotal = 0;
my $lengthMax = -1;
my $lengthMin = -1;
my $readsFlag = 1;
my $totCount = 0;
my $type;
if(($ARGV[0]=~/fastq/) || ($ARGV[0]=~/fq/)){
	$type="fastq";
}elsif(($ARGV[0]=~/fasta/) || ($ARGV[0]=~/fa/)){
	$type="fasta";
}

#print "$type";
if($ARGV[0]=~/\.gz/){
	open (FIN, "zcat $ARGV[0]|") || die;
}else{
	open (FIN,"$ARGV[0]") || die;
}
do {
    $flagForScan = defined($str=<FIN>);
    chomp $str;
    if ($type eq "fastq" ) { $stpos = index ($str, "@"); }
    if ($type eq "fasta" ) { $stpos = index ($str, ">"); }
    if ($stpos==0 || !$flagForScan) {
        $readsFlag = 1;
        if ($id ne "") {
            $totCount++;
            push (@lengthList, length($seq));
            $lengthTotal += length($seq);
            if (length($seq)>$lengthMax || $lengthMax==-1) {
                $lengthMax = length($seq);
            }
            if (length($seq)<$lengthMin || $lengthMin==-1) {
                $lengthMin = length($seq);
            }
        }
        $enpos = index($str, " ");
        if ($enpos!=-1) {
            $id = substr($str, $stpos+1, $enpos-$stpos-1);
        } else {
            $id = substr($str, $stpos+1);
        }
        $seq = "";
    } elsif ($str=~/^\+/) {
        $readsFlag = 0;
    } elsif ($readsFlag) {
        chomp $str;
        $seq = $seq.$str;
    }
} while ($flagForScan);

@lengthList = sort {$b<=>$a} @lengthList;

#print "contig number:\t", scalar(@lengthList), "\n";
#print "contig bases:\t", $lengthTotal, "\n";
#print "contig ave_length:\t", int($lengthTotal/scalar(@lengthList)*100)/100, "\n";
my $sum = 0;
my $n50 = 0;
my $n75 = 0;
for (my $i=0;$i<scalar(@lengthList);$i++) {
    $sum += $lengthList[$i];
    if ($sum>$lengthTotal*0.5 && $n50==0) {
 #       print "N50:\t", $lengthList[$i], "\n";
        $n50 = $lengthList[$i];
    }
    if ($sum>$lengthTotal*0.75 && $n75==0) {
#        print "N75:\t", $lengthList[$i], "\n";
        $n75 = $lengthList[$i];
    }
}
my $ave=int($lengthTotal/scalar(@lengthList)*100/100);
$lengthTotal=int($lengthTotal/1000000);
my $all=scalar(@lengthList);
print "Type\tRead length (bp)\tTotal reads\tFiltered (%)\tRaw data\tClean data\n";
print "Long reads\tAVE=$ave;N50=$n50\t$all\t-\t$lengthTotal\M\t-\n";

