open (FIN,$ARGV[0]);
@a=split(/\//,$ARGV[0]);
@b=split(/\.txt/,$a[-1]);
print $b[0],"\t";
while ($line=<FIN>){
	chomp $line;
	if (($line=~/^  \d+/) || ($line =~ /^ \d/)){
		@tmp=split(/;/,$line);
		@arr=split(/\s/,$tmp[2]);
		my @foundlist = grep(/^[0-9]/, @arr);
		my @foundlist = grep { $_ ne "" } @foundlist;
		$tag=1;
		if ($foundlist[0]>=50){
			@arr1=split(/-/,$foundlist[6]);
			foreach my $k (keys %{$hash{$b[0]}}){
				@arr2=split (/-/,$k);
				if ($arr1[0] > $arr2[0] && $arr1[1] < $arr2[1]){
					$tag=0;	
					last;
				}
			}
			if ($tag){
				$hash{$b[0]}{$foundlist[6]}=$tmp[1];
				print $tmp[1]."(".$foundlist[6].")",";";
			}
		}
	}
}
print "\n";

