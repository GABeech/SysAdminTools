#!/usr/bin/perl -w
#####################################################################
# Script Name: control_servers.pl (oh so needs to be changed) 
# Author: George Beech <george@stackexchange.com>
# Version: 0.0000
# This script is used to control HA proxy, most notably to give us the ability
# to easily move servers/whole back ends in and out of production. While directly accessing
# the socket is ok for occational work. When you need to move larger numbers ot of multiple back end
# pools it really starts to suck. 
# 
# This script uses the perl UNIX sockets library to access the SOCKET for HAProxy 
# and send it commands. It can pass arbitrary commands if you need it too, but it's utility lies
# in it's ability to do a pre-defined set of actions. 
#
# Revision History:
#####
# 0.5 - Base functionality for sending ha proxy commands, as well as listing, enabling and 
# 	disabling server in place.
#####
# TODO:
# 	Implement the following commands:
#		show info
#		show errors
#		get weight
#		set weight
#	Clean up code a bit
#	Add comments 
####################################################################
use strict;
use IO::Socket::UNIX;
use Getopt::Long;

my $HA_PROXY_SOCK='/var/run/haproxy.stat';
my $sock_line;

#Define variables for options
my $opt_enable_svr = '';
my $opt_disable_svr = '';
my $opt_show_servers = '';
my $opt_check_syntax = '';
my $hacmd = '';
my @opt_server_list;

# This is the core funtion, it opens a local UNIX socket to the 
# HAProxy and then writes commands to it, as well as saving the output inot
# The return value @sock_return.
sub sendHAcmd()
{
	my @sock_return;
	my $command = shift(@_) . "\n";
	print $command;
	unless (-S $HA_PROXY_SOCK)
	{
		die "Could not find HA Proxy socket, is HA Proxy running?\r\n";
	}

	my $unix_sock = IO::Socket::UNIX->new(Peer=>$HA_PROXY_SOCK,Type=> SOCK_STREAM) || die "socket: $!";
#	my $server_string = "show stat\n";
	$unix_sock->autoflush(1);

	# We need to fork the proccess here, so taht we can read and write to the 
	# socket at the same time, otherwise we miss the output. 
	die "can't fork: $!" unless defined(my $kidpid = fork());
	if($kidpid)
	{
		while (defined($sock_line=<$unix_sock>))
		{
			# Since this only feeds us one line of output at a time, we need to feed it into 
			# an array to be returned.
			push(@sock_return,$sock_line);
#			print STDOUT $sock_line;
		}

		kill("TERM" => $kidpid);
	}
	else
	{
		# This is where we run the passed command against HAProxy
		# we are really just using normal print to write to the socket
		print $unix_sock $command;
	}
	$unix_sock->close;
	return(@sock_return)
}


sub listServers
{
	my @HA_info = &sendHAcmd("show stat");
	my @return_array;
	my ($server,$backend);
	if(@opt_server_list)
	{
		while(my $pass_server = shift(@opt_server_list))
		{
			foreach my $search (@HA_info)
			{
				if($search =~ m/.*,($pass_server),.*/)
				{
					($backend,$server) = split(/,/,$search);
					push(@return_array,$backend . "/" .$server);
				}
			}
		}
		return(@return_array)
	}		
	foreach my $element (@HA_info)
	{
		if($element !~ m/.*(FRONTEND|BACKEND).*/)
		{	
			($backend,$server) = split(/,/,$element);
			print $backend . "/" .$server . "\n";
		}
	}	

}

sub disableHAServer
{
	my @to_disable = &listServers("inst1");
	foreach (@to_disable)	
	{
		&sendHAcmd("disable server " . $_);
	}
}

sub enableHAServer
{
	my @to_enable = &listServers("inst1");
	foreach (@to_enable)
	{
		&sendHAcmd("enable server " . $_);
	}

}

sub setServers
{
	print @_;
	if(defined(@_))
	{
		@opt_server_list = split(/,/,$_[1]);
	}
	else
	{
		warn "Server List not defined";
	}
}

sub dispHelp
{
	print @_;	
	if(defined(@_))
	{
		if($_[1] == 49)
		{
			print $_[0];
		}
		print <<ENDHELP;
This utility script is used to manage HAProxy servers. 
USAGE: control_servers.pl [--enable|-e ] [--disable|-d] [--show-servers] [--check|-c] [--server|-s] [--help|-h]
OPTIONS:
	--enable|-e:
		This sets the enable flag, it tells HA proxy to take a server 
		out of mainenance mode
	--disable|-d: 
		This sets the disable flag, it tells HA Proxy to put a server 
		into mainenance mode
	--show-servers:
		This prints out all backend/server pairs in the the format of 
		'backend/server' if used in combination with teh --server option, 
		then it will limit the display to the backends that the specified 
		server is part of.
	--server|-s:
		comma separated list of servers that you want to operate on.
	--hacmd:
		Send a command directly to haproxy - this is not parsed and 
		passed directly to the socket
	--check|-c:
		Do nothing, simple print out the commands that would be sent to 
		HA Proxy and exit (NOT IMPLEMENTED)
	--help|-h:
		Print the help (this page)
ENDHELP
	}

exit 0;
}
print "===========================\n";
#print &sendHAcmd("show stat");
#&listServers;
#&enableHAServer;


# First thing we want to do is parse all the options passed
my $options = GetOptions('enable|e' 		=> \$opt_enable_svr,
			 'disable|d' 		=> \$opt_disable_svr,
			 'show-servers' 	=> \$opt_show_servers,
			 'check|c' 		=> \$opt_check_syntax,
			 'servers|s=s'		=> \&setServers,
			 'help|h'		=> \&dispHelp,
			 'hacmd=s'		=> \$hacmd);

if(($opt_enable_svr) && ($opt_disable_svr))
{
	&dispHelp("Enable and Disable options are mutually exclusive, please pick one", 49);
} 

if(($opt_enable_svr) && (@opt_server_list))
{
	&enableHAServer;
}
elsif(($opt_enable_svr) && (!@opt_server_list))
{
	&dispHelp("You must specify server(s) to enable", 49);
}

if(($opt_disable_svr) && (@opt_server_list))
{
        &disableHAServer;
}
elsif(($opt_disable_svr) && (!@opt_server_list))
{
        &dispHelp("You must specify server(s) to disable", 49);
}

if($opt_show_servers)
{
	&listServers;
}

if(!$options)
{
	&dispHelp(1);
}	

if($hacmd)
{
	print &sendHAcmd($hacmd);
}		

rxit;
