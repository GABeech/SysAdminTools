#!/usr/bin/perl
# Author: George Beech <george@stackexchange.com>
# Purpose: To find up ports on our switches, then write out to a network socket the data needed for
# Graphite to collect the data

use strict;
use warnings;
use Net::SNMP;
use IO::Socket;

# SNMP Setting
my $snmpCom = 's3cur3';
my $host = 'ny-swstack01';

# OIDS
my $ifTable_Base_OID = '1.3.6.1.2.1.2.2.1';
my $ifTable_Interface_OID = '1.3.6.1.2.1.2.2.1.1';
my $ifTable_Interface_Desc_OID = '1.3.6.1.2.1.2.2.1.2';
my $ifTable_Interface_AdmStat_OID = '1.3.6.1.2.1.2.2.1.8';
my $ifTable_Interface_inOct_OID = '1.3.6.1.2.1.2.2.1.10';
my $ifTable_Interface_outOct_OID = '1.3.6.1.2.1.2.2.1.16';

my %result_hash = ();
my @hosts = ();
sub getHosts()
{
	open(CONFIG_FILE, 'intStat.cfg') or die $!;
	while(<CONFIG_FILE>)
	{
		chomp($_);
		print $_ . "\n";
		push(@hosts, $_);

	}
	close(CONFIG_FILE);
	


}

sub getSwitchportData()
{
	foreach(@hosts)
	{
		my @upInt = ();
		my $cur_host = $_;
		my ($snmp_session, $snmp_error) = Net::SNMP->session(
							-hostname	=>	$cur_host,
							-community	=>	$snmpCom
							);
		if(!defined($snmp_session))
		{
			printf "ERROR: %s.\n", $snmp_error;
		}

		my $ifTableResult = $snmp_session->get_table( -baseoid => $ifTable_Base_OID);
		my %ifTable_Hash = %$ifTableResult;
		$snmp_session->close();

		while(my ($key, $value) = each(%ifTable_Hash))
		{
			print "$key => $value\n";
			if($key =~ /$ifTable_Interface_OID\.\d{1,5}$/)
			{
				my $oid_key = $ifTable_Interface_AdmStat_OID . "." . $value;
				print $oid_key . "\n";
				print $ifTable_Hash{$oid_key};
				if($ifTable_Hash{$oid_key} == 1)
				{
					push(@upInt,$value);
					print "pushed: $value\n";
				}
			}
		}
		foreach(@upInt)
		{
			print $_ . "\n";
			my $desc_key = $ifTable_Interface_Desc_OID . "." . $_;
			my $in_key = $ifTable_Interface_inOct_OID . "." . $_;
			my $out_key = $ifTable_Interface_outOct_OID . "." . $_;
			my $sane_desc = $ifTable_Hash{$desc_key};
			$sane_desc =~ s/\///g;
			print $sane_desc . "\n";
			$result_hash{$cur_host}{$sane_desc}{"inOct"} = $ifTable_Hash{$in_key};
			$result_hash{$cur_host}{$sane_desc}{"outOct"} = $ifTable_Hash{$out_key};
		}
		print "upInt Size: " . @upInt;
		# clear out my BIIIG hashes
		undef(%ifTable_Hash);
		undef(%$ifTableResult);
	}
}

sub sendToGraphite()
{
	my $graphite_svr = 'dummy.server.com';
	my $graphite_port = '2003';
	my $graphite_sock = new IO::Socket::INET->new(
					PeerAddr	=>	$graphite_svr,
					PeerPort	=>	$graphite_port,
					Proto		=>	'tcp'
					);
	if(!defined($graphite_sock))
	{
		die "Could not Connect to graphite/carbon server";
	}
	while (my ($host_key, $host_value) = each(%result_hash))
	{
		while(my ($int_key, $int_value) = each(%$host_value))
		{
			print $graphite_sock "network." . $host_key . "." . $int_key . ".inOctets " . $result_hash{$host_key}{$int_key}{"inOct"} . " " . time . "\n";
			print $graphite_sock "network." . $host_key . "." . $int_key . ".outOctets " . $result_hash{$host_key}{$int_key}{"outOct"} . " " . time . "\n";
		}
	}
	close($graphite_sock);
}

&getHosts;
while(1)
{
&getSwitchportData;
&sendToGraphite;
undef(%result_hash);
sleep 60;
}
