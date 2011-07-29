# Author: George Beech <george@stackexchange.com>
# Created: 05-25-2011
# Purpose:
# This script is used to push out IIS configuration files from a central source 
# to web servers as listed in active directory
# 
# TODO: 
# 
# * Add ability to get destination server from alternate sources
#   * Text file
#   * command line
# * Check for hard coded parameters and variablize them
#
###################################################################

# Global Variables
$REF_SERVER = "<YOUR_REF_SERVER>"

param([string]$ServerPool)

function push_usage()
{
    write-host "usage: copy_applicationHost.ps1 -ServerPool <Pool Identifier>"
    write-host "available pool identifiers are:"
    write-host "`tprod: All production servers"
    write-host "`tstage: All Staging Server"
    write-host "`t1: Pool 1 (Web Tier 1)"
    write-host "`t2: Pool 2 (Web Tier 2)" 
    write-host "`t3: Pool 3 (Web Tier 3)"
    write-host "`tAll: All Hosts"
    exit
   
}

# Select-FileDialog Function  #
# Created by Hugo Peeters     #
# http://www.peetersonline.nl #
###############################

# Note: store in your profile for easy use
# Example use:
# $file = Select-FileDialog -Title "Select a file" -Directory "D:\scripts" -Filter "Powershell Scripts|(*.ps1)"

function Select-FileDialog
{
	param([string]$Title,[string]$Directory,[string]$Filter="All Files (*.*)|*.*")
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	$objForm = New-Object System.Windows.Forms.OpenFileDialog
	$objForm.InitialDirectory = $Directory
	$objForm.Filter = $Filter
	$objForm.Title = $Title
	$Show = $objForm.ShowDialog()
	If ($Show -eq "OK")
	{
		Return $objForm.FileName
	}
	Else
	{
		Write-Error "Operation cancelled by user."
        exit 1
	}
}

#write-host $ServerPool

# We want to be able to over ride this, so before the switch statement we go
$ldap_filter = "(objectCategory=Computer)"

# You need to put you base DNs here 
switch($ServerPool)
{
    "all" { $BASEDN="LDAP://<YOUR_BASE_DN>";break }
    "stage" { $BASEDN="LDAP://<YOUR_BASE_DN>";break  }
    "1" { $BASEDN="LDAP://<YOUR_BASE_DN>";break  }
    "2" { $BASEDN="LDAP://<YOUR_BASE_DN>";break  }
    "3" {$BASEDN="LDAP://<YOUR_BASE_DN>";break  }
    "prod" { 
        $BASEDN="LDAP://OU=<YOUR_BASE_DN>"
        $ldap_filter="(&(objectCategory=Computer)(!name=<STAGING_SERVER>))"
        break 
        }
    default { push_usage }
}

# We need to do some basic setup for our directory search, filter, AD connection
# And yes using get-adcomputer would be easier, but you currently need RSAT installed, and i want this to be portable. 


#write-host $BASEDN
#write-host $ldap_filter


#$AD_Connection = New-Object System.DirectoryServices.DirectoryEntry($BASEDN)
$AD_Connection = [ADSI]$BASEDN
#$AD_Connection

$searcher = new-object System.DirectoryServices.DirectorySearcher
$searcher.SearchRoot = $AD_Connection
$searcher.PageSize = 1000 
$searcher.Filter = $ldap_filter
$searcher.SearchScope = "Subtree"
$searcher.PropertiesToLoad.Add("Name")

$ad_search_results = $searcher.FindAll()

#write-host $ad_search_results

# Debug, wanna see what the LDAP filter gets us
<#foreach($result in $ad_search_results)
{
    
    write-host $result.properties.name
}
#>
# Setup some checks
# 1. if we are on our reference server copy direct from the inetsrv directory 
# 2. If we arn't on our reference server see if there is a file called applicationHost.conf in the current folder


if($env:computername -eq "$REF_SERVER")
{
    $source_file = "C:\Windows\System32\inetsrv\config\applicationHost.config"
}
elseif(test-path .\applicationHost.config)
{
    $source_file = ".\applicationHost.config"
}
else
{
    write-host "Cannot find the applicationHost.config to copy, do you want to Manually specify the location?"
    
    $choice_caption = "File Select?"
    $message = "Cannot find the applicationHost.config to copy, do you want to Manually specify the location?"
    $ans_yes = new-Object System.Management.Automation.Host.ChoiceDescription "&Yes","help";
    $ans_no =  new-Object System.Management.Automation.Host.ChoiceDescription "&No","help";
    $choices = [System.Management.Automation.Host.ChoiceDescription[]]($ans_yes,$ans_no);
    $answer = $host.ui.PromptForChoice($caption,$message,$choices,0)
    
    if($answer -eq 0)
    {
        $source_file = Select-FileDialog
    }
    else
    {
        exit
    }
}

write-host $source_file

$success_fail = 0
$failed_servers = $()
foreach($result in $ad_search_results)
{
    #need to do this so that we can get the actual name
    $machine = echo $result.properties.name
    copy-item  $source_file -Destination "\\$machine\c$\Windows\System32\inetsrv\config\"
    if(!$?)
    {
        $failed_servers += $machine
        $success_fail = 1
    }
}

if ($success_fail -eq 1)
{
    echo "YOU ARE A FAILURE, Failed Servers:"
    foreach($item in $failed_servers)
    {
        echo $item
    }
}
else
{
    echo "SUCCESS BITCHES"
}

#$webservers = @("ny-web01", "ny-web02", "ny-web03", "ny-web04", "ny-web05", "ny-web06", "ny-web07", "ny-web08", "ny-web09")

#foreach ($server in $webservers) {
#    Write-Host $server
#    cp 'C:\sysadmin\ny-IISConfigs\applicationHost.config' "\\$server\c$\Windows\System32\inetsrv\config\"
#}
