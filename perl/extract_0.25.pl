open (FI1, $ARGV[0]);
open (FI2, $ARGV[1]);
open (FO1, ">".$ARGV[2]);
open (FO2, ">".$ARGV[3]);
do {
	$flag = defined($file11 = <FI1>);
	$file12 = <FI1>;
	$file13 = <FI1>;
	$file14 = <FI1>;
	$file21 = <FI2>;
	$file22 = <FI2>;
	$file23 = <FI2>;
	$file24 = <FI2>;
	if (rand()<0.25) {
		print FO1 $file11;
		print FO1 $file12;
		print FO1 $file13;
		print FO1 $file14;
		print FO2 $file21;
		print FO2 $file22;
		print FO2 $file23;
		print FO2 $file24;
	}
} while ($flag);
close (FI1);
close (FI2);
close (FO1);
close (FO2);

