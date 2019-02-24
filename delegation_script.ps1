
Function New-CsnRoute53Forwarder {

<#
.Description

This will deploy all the necessesary DNS records to allow client teams in AWS VCD to self manage a subzone hosted in the CSN.

.PARAMETER master_servers

Array of client resolvers created in Route53.

.PARAMETER creds

Credential object with accesss to run CIM commands

.EXAMPLE

New-CsnRoute53Forwarder -master_servers 10.22.33.4, 10.22.33.5 -creds
	  
#>


    [cmdletBinding()]
        param(
        
            
            [Parameter(Mandatory=$true)]
            [string[]]$master_servers,

            [Parameter(Mandatory=$true)]
            [string]$zone,

            [Parameter(Mandatory=$true)]
            [string]$childzone,

            [Parameter(Mandatory=$true)]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]$creds

        )


#Use DCOM since remoting doesn't work in our env
$opt = New-CimSessionOption -Protocol Dcom

#CIM connection to VPN servers
$vpn = New-CimSession -Credential $creds -ComputerName 10.128.188.11,10.128.79.11 -SessionOption $opt

#CIM to Core DNS
$core = New-CimSession -Credential $creds -ComputerName 10.224.0.10,10.224.0.11 -SessionOption $opt

#CIM for AWS DNS1
$aws = New-CimSession -Credential $creds -ComputerName 10.209.97.136 -SessionOption $opt


#Add Delegation to Top level domain DC6  Run this as many times as NS records required
foreach ($server in $master_servers) { 
    Add-DnsServerZoneDelegation -Name $zone -ChildZoneName $childzone -NameServer $server -IPAddress $server -Verbose
}

#Remove Delegation Top Level domain DC6
#Remove-DnsServerZoneDelegation -Name "boozallencsn.com" -ChildZoneName "test-sky"

#Connect to 10.128.188.11 ASHBRN and NBP3 VPN 10.128.79.11 and add forwarders permissions issue
Add-DnsServerConditionalForwarderZone -Name $zone -MasterServers 10.224.0.10,10.224.0.11 -CimSession $vpn -Verbose 

#add forwarder for Core DNS
Add-DnsServerConditionalForwarderZone -Name $zone -MasterServers 10.209.97.136,10.209.97.137 -CimSession $core -Verbose


#2/15/19 Can CIM to .137 from .136 if needed
#add forwarder for USE1 DNS and maybe USE1 DNS2 $master_server must be type <ipaddress[]>
Add-DnsServerConditionalForwarderZone -Name $zone -MasterServers $master_servers -CimSession $aws -Verbose
}