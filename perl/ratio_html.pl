#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
my $dir=getcwd;

open GFF,"$ARGV[0]" or die $!; #### $dir/ratio.txt
open R, ">$ARGV[1]" or die $!; ####$dir/ratio.html
print R "<!doctype html>","\n";
print R "<html lang=\"zh-CN\">","\n";
print R "<head>","\n";
print R " <meta charset=\"utf-8\">","\n";
print R " <meta name=\"renderer\" content=\"webkit|ie-comp|ie-stand\">","\n";
print R " <meta http-equiv=\"X-UA-Compatible\" content=\"IE=Edge,chrome=1\">","\n";
print R " <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, user-scalable=no\">","\n";
print R " <title>Report</title>","\n";
print R " <style type=\"text\/css\" rel=\"stylesheet\">","\n";
print R " html,body,tbody,tr,td{margin:0;padding:0;font-size: 14px;}","\n";
print R " table {border-collapse: collapse;border-spacing: 0;}","\n";
print R " .maintbody{width:1000px;margin:50px auto;}","\n";
print R " .maintbody table{width:100%;border: 1px solid #efefef;}","\n";
print R " .maintbody tbody tr td{font-family: \"Arial\",\"Helvetica\",sans-serif;padding:10px 15px;border-right: 1px solid #efefef;border-bottom: 1px solid #efefef;}","\n";
print R " .maintbody tbody tr td.tdsplist{width: 850px;line-height:20px;display: block;word-wrap: break-word; border-right: none;}","\n";
print R " .maintbody tbody tr td.tdlast{border-bottom: none;}","\n";
print R " </style>","\n";
print R "</head>\n";
print R "<div class=\"maintbody\">\n";
print R "<div class><b>Section 3: gene annotation.</b></div><br><br>\n";
print R "<div>Predicted genes in the previous step are aligned with several databases to obtain their corresponding annotations with aligners such as diamond and hmmer. To ensure the biological meaning, the highest quality alignment result is chosen as gene annotation. The statistics is shown in the following table:</div><br><br>\n";
print R "<div class align=\"center\"><b>Annotation Statistics</b></div>\n";
print R "<table>\n";
print R "<tbody>\n";
print R "<tr>\n";
print R "<td>Database</td>\n";
print R "<td>Anno_genes</td>\n";
print R "<td>Ratio</td>\n";
print R "</tr>\n";
while (my $line=<GFF>){
	chomp $line;
	my @arr=split /\t/,$line;
	print R "<tr>\n";
	print R "<td>$arr[0]</td>\n";
	print R "<td>$arr[1]</td>\n";
	print R "<td>$arr[2]</td>\n";
	print R "</tr>\n";
}
print R "</tbody>\n";
print R "</table>\n";
print R "</div>\n";
print R "<div class=\"maintbody\">\n";
print R "<div>The detail can be seen <a href=\"function_annotation.html\", target=\"_blank\">here</a>.</div><br><br>\n";
print R "</div>\n";
print R "<body>\n";
my @path=split /tables/,$ARGV[0];
my @fig=split /ratio/,$ARGV[1];
my $kegg0=$path[0]."diamond/"."KEGG_diamond.txt";
my $kegg=$fig[0]."figure/"."KEGG.txt";
my $kegg1=$fig[0]."figure/"."KEGG.png";
my $cog0=$path[0]."diamond/"."COG_diamond.txt";
my $cog=$fig[0]."figure/"."COG.txt";
my $cog1=$fig[0]."figure/"."COG.png";
my $card0=$path[0]."diamond/"."CARD_diamond.txt";
my $card=$fig[0]."figure/"."CARD.txt";
my $card1=$fig[0]."figure/"."CARD.png";
my $cazy0=$path[0]."diamond/"."CAZy_diamond.txt";
my $cazy=$fig[0]."figure/"."CAZy.txt";
my $cazy1=$fig[0]."figure/"."CAZy.png";
if(-s $kegg0){
	my @kegg_num=`cat $kegg0`;
	my $kegg_num1=@kegg_num;
	if(-s $kegg && $kegg_num1 > 30){
        	system("cp $kegg1 $path[0]");
        	print R "<div class=\"maintbody\">\n";
       		print R "<p><img src=\"KEGG.png\"></img></p>\n";
        	print R "</div>\n";
	}
}
if(-s $cog0){
	my @cog_num=`cat $cog0`;
	my $cog_num1=@cog_num;
		if(-s $cog && $cog_num1 > 30){
       		system("cp $cog1 $path[0]");
        	print R "<div class=\"maintbody\">\n";
        	print R "<p><img src=\"COG.png\"></img></p>\n";
        	print R "</div>\n";

	}	
}
if(-s $card0){
	my @card_num=`cat $card0`;
	my $card_num1=@card_num;
	if(-s $card && $card_num1 > 30){
	        system("cp $card1 $path[0]");
        	print R "<div class=\"maintbody\">\n";
	        print R "<p><img src=\"COG.png\"></img></p>\n";
        	print R "</div>\n";
	}	
}
if(-s $cazy0){
	my @cazy_num=`cat $cazy0`;
	my $cazy_num1=@cazy_num;
	if(-s $cazy && $cazy_num1 > 30){
	        system("cp $cazy1 $path[0]");
        	print R "<div class=\"maintbody\">\n";
	        print R "<p><img src=\"CAZy.png\"></img></p>\n";
        	print R "</div>\n";
	}
}
print R "</body>\n";
print R "</html>\n";
