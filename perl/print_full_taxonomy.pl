use strict;
use warnings;

my $help = "";
$help = $help."Command: perl parse_full_lineage.pl <taxonomy file> <name list> <id/name> <column> <f/7/7n/7i> [filter] [quoter] [separator]\n";
$help = $help."Example: perl parse_full_lineage.pl /data/database/taxonomy-20180530.txt names.txt id 1 a\n";
$help = $help."taxonomy file includes several columns, ID[1] PARENT_ID[2] RANK[3] several names[5-8] will be used in this script;\n";
$help = $help."<f/7/7n/7i> 'f' means full lineage, '7' means k-p-c-o-f-g-s lineage, '7n' means seven levels lineage with null value, '7i' means seven levels lineage with id inserted;\n";
$help = $help."[filter] default='none', or set as 'superkingdom=Bacteria|superkingdom=Archaea|superkingdom=Viruses|kingdom=Fungi';\n";
$help = $help."[quoter] default='__';\n";
$help = $help."[separator] default='|';\n";
$help = $help."\n";
$help = $help."sed -i 's/|[pcofgs]__/\t/g'\n";
$help = $help."\n";

if (scalar(@ARGV)<5) {
    die $help;
}

my $inputType = $ARGV[2];
my $inputColumn = $ARGV[3];
my $outputType = $ARGV[4];
my $filter = $ARGV[5];
my $quoter = $ARGV[6];
my $separator = $ARGV[7];

if ($inputType ne "id" && $inputType ne "name") {
    die "Type <id/name> error!\n";
}

if ($inputColumn==0) { $inputColumn = 0; }

if (($outputType ne "f") && ($outputType ne "7") && ($outputType ne "7n") && ($outputType ne "7i")) {
    die "Type <f/7/7n/7i> error!\n";
}
if (!defined($filter)) {
    $filter = "none";
}
if (!defined($quoter)) {
    $quoter = "__";
}
if (!defined($separator)) {
    $separator = "|";
}

my @ae;
my @subae;
my @filterKey = ();
my @filterValue = ();
if ($filter ne "none") {
    @ae = split /\,/, $filter;
    foreach (@ae) {
        @subae = split /=/;
        push @filterKey, $subae[0];
        push @filterValue, $subae[1];
    }
}

my @seven = ("kingdom", "phylum", "class", "order", "family", "genus", "species");

open FIN, $ARGV[0] || die "Can not open taxonomy file!\n"; # taxonomy file

my $i;
my $j;
my %taxoParent;
my %taxoId;
my %taxoLevel;
my %taxoName;
while (<FIN>) {
    chomp;
    @ae = split /\t/;
    $taxoParent{$ae[0]} = $ae[1];
    $taxoId{$ae[4]} = $ae[0];
    $taxoLevel{$ae[0]} = $ae[2];
    $taxoName{$ae[0]} = $ae[4];
    for $i (5..7) {
        if ($ae[$i]=~/;/) {
            @subae = split /;/, $ae[$i];
            foreach (@subae) { if (!exists($taxoId{$_})) { $taxoId{$_} = $ae[0]; } }
        } elsif (!exists($taxoId{$ae[$i]})) { $taxoId{$ae[$i]} = $ae[0]; }
    }
}
close FIN;

my $l;
my $str;
my $query;
my $pointer;
my $flagDispWhole;
my $flagFirst;
my @lineage;
my @level;
my %tempHash;
open FIN, $ARGV[1] || die "Can not open name list file!\n";
while (defined($str=<FIN>)) {
    chomp $str;
    @ae = split /\t/, $str;
    if ($inputType eq "id") {
        $query = $ae[$inputColumn-1];
    } else {
        if (exists($taxoId{$ae[$inputColumn-1]})) {
            $query = $taxoId{$ae[$inputColumn-1]};
        } else {
            $query = "";
        }
    }
    if ($inputType eq "id") {
        $query =~s/\s//g;
        print $query, "\t";
    }
    if ($inputType eq "name") {
        print $taxoName{$query}, "\t";
    }
    @lineage = ();
    @level = ();
    if (exists($taxoLevel{$query})) {
        $pointer = $query;
        while ($taxoParent{$pointer}!=$pointer) {
            push @lineage, $pointer;
            $pointer = $taxoParent{$pointer};
        }
    }
    $flagDispWhole = 1;
    if (scalar(@lineage)) {
        if (scalar(@filterKey)) {
            $flagDispWhole = 0;
            for ($i=scalar(@lineage)-1;$i>=0;$i--) {
                for ($j=0;$j<=scalar(@filterKey)-1;$j++) {
                    if (index($taxoLevel{$lineage[$i]},$filterKey[$j])!=-1) {
                        if ($filterValue[$j] eq $taxoName{$lineage[$i]}) {
                            $flagDispWhole = 1;
                        }
                    }
                }
            }
        }
        if ($flagDispWhole) {
            $flagFirst = 1;
            if ($outputType eq "7" || $outputType eq "7n" || $outputType eq "7i") {
                %tempHash = ();
                foreach $l (0..scalar(@seven)-1) { if (!exists($tempHash{$seven[$l]})) {
                    for ($i=scalar(@lineage)-1;$i>=0;$i--) {
                        if ($taxoLevel{$lineage[$i]} eq $seven[$l]) {
                            $tempHash{$seven[$l]} = $lineage[$i];
                        } elsif (index($taxoLevel{$lineage[$i]}, $seven[$l])!=-1) {
                            if (index($taxoLevel{$lineage[$i]}, "super")!=-1) { if (!exists($tempHash{$seven[$l]})) {
                                $tempHash{$seven[$l]} = $lineage[$i];
                            } }
                            if (index($taxoLevel{$lineage[$i]}, "sub")!=-1) { if (!exists($tempHash{$seven[$l]})) {
                                $tempHash{$seven[$l]} = $lineage[$i];
                            } }
                        }
                    }
                } }
                if ($outputType eq "7") {
                    foreach (@seven) {
                        if (exists($tempHash{$_})) {
                            if (!$flagFirst) {
                                print $separator;  
                            }
                            $flagFirst = 0;
                            print substr($_, 0, 1);
                            print $quoter;
                            print $taxoName{$tempHash{$_}};
                        }
                    }
                } elsif (($outputType eq "7n") || ($outputType eq "7i")) {
                    foreach (@seven) {
                        if (exists($tempHash{$_})) {
                            if (!$flagFirst) {
                                print $separator;  
                            }
                            $flagFirst = 0;
                            print substr($_, 0, 1);
                            print $quoter;
                            print $taxoName{$tempHash{$_}};
                        } else {
                            if (!$flagFirst) {
                                print $separator;  
                            }
                            $flagFirst = 0;
                            print substr($_, 0, 1);
                            print $quoter;
                            if ($outputType eq "7i") {
                                print "[".uc(substr($_, 0, 1)).$query."]";
                            } else {
                                print "";
                            }
                        }
                    }
                }
            }
            if ($outputType eq "f") {
                for ($i=scalar(@lineage)-1;$i>=0;$i--) {
                    if (!$flagFirst) {
                        print $separator;  
                    }
                    $flagFirst = 0;
                    print $taxoLevel{$lineage[$i]};
                    print $quoter;
                    print $taxoName{$lineage[$i]};
                }
            }
            print "\n";
        } else {
            print "-\n";
        }
    } else {
        print "-\n";
    }
}
