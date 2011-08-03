#!/usr/bin/perl
###############################################################################
# Author: George Beech <george@stackexchange.com>
# Purpose: 
#	This script is ment to take SQLIO results, and convert them into a csv file
#	so that we can do usefule stuff with the information
#
# Version 1.1
#
# Changelog:
# 1.0 - Crapy hack together ... never recorded date - GAB
# 1.1 (2011-08-03 GAB)
#	  - Added help file
#	  - Added the ability to use command line options
#	  - Removed random debugging line i have no idea what it was
#
# TODO:
#	- Document REGEXes
#
###############################################################################


use strict;
use Getopt::Long;

# Default Options
my $SQLIO_Res = "sqlio-out.txt";
my $CSV_Out = "SQLIO-Out.csv";


# Proccess options


sub display_help()
{
			print <<ENDHELP;
This utility script is used to convert SQLIO output to csv format 
USAGE: parse_sqlio.pl [--infile|-i ] [--outfile|-i] [--help|-h]
OPTIONS:
	--infile|-i:
		Use this to specify an input file. The default is ./sqlio-out.txt.
	--outfile|-o: 
		Use this option to specify an output file. The default is ./SQLIO-Out.csv.
	--help|-h:
		Print the help (this page)
ENDHELP

}


sub process_results()
{
	print "$SQLIO_Res\n";
	print "$CSV_Out\n";
	open RES_FILE,$SQLIO_Res or die $!;
	open OUT_FILE,">" . $CSV_Out or die $!;

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
		
	}

	close RES_FILE;
	close OUT_FILE;
}

my $option = GetOptions(
					'infile|i=s' 		=> 		\$SQLIO_Res,
					'outfile|o=s'		=>		\$CSV_Out,
					'help|h'		=>		\&display_help,
				);

&process_results;