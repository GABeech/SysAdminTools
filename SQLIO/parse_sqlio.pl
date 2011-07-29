#!/usr/bin/perl
use strict;

open RES_FILE,"results-x25-e.txt" or die $!;
open OUT_FILE,">parsed_results.csv" or die $!;

print OUT_FILE "Op Type,threads,Outstanding Reqs,rand/seq,Block Size,IO/sec,MB/sec,Min_lat,Avg_lat,Max_lat,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,0,21,22,23,24+\n";

while(<RES_FILE>)
{
# This is gonna get uuuugly
	if($_ =~ m/.*-k(.) -t(\d{1,3}).*-o(\d{1,3}) -f(.*) -b(\d{1,5}).*/){
	print OUT_FILE "$1,$2,$3,$4,$5";
	}
	
	if($_ =~ m/^IOs\/sec:\s*(\d{1,6}\.\d{2})/){
	print OUT_FILE ",$1";
	}

	if($_ =~ m/^MBs\/sec:\s*(\d{1,6}\.\d{2})/){
	print OUT_FILE ",$1";
	}

	if($_ =~ m/^Min_Latency\(ms\):\s*(\d{1,6})/){
        print OUT_FILE ",$1";
	}

	if($_ =~ m/^Avg_Latency\(ms\):\s*(\d{1,6})/){
        print OUT_FILE ",$1";
	}
	
	if($_ =~ m/^Max_Latency\(ms\):\s*(\d{1,6})/){
        print OUT_FILE ",$1";
	}

	if($_ =~ m/%:\s*(.*)/)
	{
	
		my $convert=$1;
		$convert =~ s/^\s*//;
		print "leading space removal\n";
		print "$convert\n";
		$convert =~ s/\s+/,/g;
		print "swap commas for whitespace\n";
		print "$convert\n";
		$convert =~ s/,,/,/g;
		print "remove double commas\n";
		print "$convert\n";
		$convert =~ s/,$//;
		print OUT_FILE ",$convert\n";
	}



	#print $_;
	
	#if($_ =~ m/^\n$/)
	#{
	#	print OUT_FILE "\n";
	#}
#	close RES_FILE;
#	close OUT_FILE;
	
}

close RES_FILE;
close OUT_FILE;
