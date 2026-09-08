---
title: "Carrier - HTB Writeup"
header: 
  teaser: /assets/images/2022-02-24-Carrier-HTB-Writeup/Carrier-HTB-Image.png
  header: /assets/images/2022-02-24-Carrier-HTB-Writeup/Carrier-HTB-Image.png
  og_image: /assets/images/2022-02-24-Carrier-HTB-Writeup/Carrier-HTB-Image.png
excerpt: "Nmap performs an automated port scan against the target server to identify open ports and services that may be vulnerable to exploitation. A quick scan of the top 1000 most commonly used ports shows that ports 22 and port 80 are open. Port 22 indicates that SSH is being used for remote management on this Linux server and port 80 shows that the target server is hosting a web server on the local network."
tags: [htb, writeup, carrier]
---
## Carrier

### Information Gathering

#### Nmap Port Scan

Nmap performs an automated port scan against the target server to identify open ports and services that may be vulnerable to exploitation. A quick scan of the top 1000 most commonly used ports shows that ports 22 and port 80 are open. Port 22 indicates that SSH is being used for remote management on this Linux server and port 80 shows that the target server is hosting a web server on the local network.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_150242.png)

#### Nmap Script Scan

Nmap also performs an automated script scan by running default scripts against particular services for further automated enumeration. Enumerating SSH shows that OpenSSH 7.6p1 is being used on an Ubuntu Linux server.  Port 80 is hosting an Apache HTTP 2.4.18 service with some basic cookies such as PHPSESSID. This indicates that PHP is most likely running on the site.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_150312.png)

#### Nmap UDP Scan

Nmap also can be run in a UDP mode to identify ports and services that are open on the local network using UDP. It appears that UDP port 161 is open which is used for Simple Network Management Protocol. This service is often not hardened and can leave the target server vulnerable to configuration enumeration and editing. A basic script can show that there is some basic SNMP info on the service. While it supports the more secure SNMPv3 the server is also running in an SNMPv1 mode and the default community string 'public' is used to authenticate against the service.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_150335.png)

### Service Enumeration

#### HTTP Service Enumeration

Browsing to the target server on the Apache service running on port 80 shows a basic login screen for a Lyghtspeed system. Two errors are given but since the service requires authentication no further enumeration can be done on this system. Basic SQL injection attacks do not appear to work on the target web service.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_150453.png)

#### Gobuster Directory Enumeration

Gobuster is used to identify more endpoints on the server and several files are found that include documentation and more. Enumerating these endpoints by hand reveals more about the target service and points to the possible vulnerabilities of the site.

#### /doc

Documentation on the target service is found at the /doc endpoint on the server. A network diagram and a manual of error codes are given and readable on the local network to unauthenticated users. Default credentials are the chassis serial number and the error codes are indicating that the defaults are being used.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_150704.png)

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_150648.png)

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_150717.png)

#### /debug

The /debug endpoint shows the standard PHP version information page, confirming the use of PHP on the target server. While no vulnerabilities are identified on the target service we can further enumerate version information and configuration information of the target web service.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_150801.png)

#### /tools/remote.php

The /tools/remote.php endpoint is executing some code but it only returns the text that a license is expired and exits. The previous error codes have indicated at a license is out of date and a default password is set.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_150839.png)

### Penetration

#### SNMP Enumeration

Further SNMP enumeration using the default 'public' community string shows some basic information. When using SNMPv2 two MIBs are returned and one of which does not render any information. The single MIB given to the user using default credentials is the serial number for the target server.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_151129.png)

#### HTTP Admin Login

Since SNMP disclosed the serial number of the chassis, the error code indicated that a default administrator password was being used and it is the serial number of the chassis, we can log into the previously shown administrative web portal by using the default credentials. When logging in we are immediately met with the 'license invalid' message that was being indicated toward on /tools/remote.php.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_151210.png)

#### Ticketing System Enumeration

The web application appears to be a ticketing system and enumerating the currently open tickets shows that there is an issue of route filtering and that there have been previous issues of BGP re-advertising on the network.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_153212.png)

#### HTTP Service Diagnostics

The diagnostics tab on the administrative web app shows a verify status button that, when clicked, will refresh an output that appears to be a UNIX command output.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_153238.png)

#### Command Injection - Diagnostics

Moving the diagnostics web request to BurpSuite we can see that there is user input being taken that is in base64 encoding. Attempting a basic command injection with a `;` and then base64 encoding the payload appears to execute arbitrary bash commands on the target server. Doing this while injecting a reverse shell command allows us to spawn a reverse shell on the target machine.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_154024.png)

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_154157.png)

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_154223.png)

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_154310.png)

#### Reverse Shell as User

The command below was base64 encoded and then requested against the authenticated service. This resulted in a bash reverse shell on the attacking machine, providing us with a root-level shell on the target.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_154601.png)

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_154618.png)

### Privilege Escalation

We're on R1 as indicated by our shell. Going back to the diagram shows that we're on R1 and we know that there is an FTP server on CastCom within the network 10.120.15.0/24. We know that three networks are attempting to connect to it but are having issues with routes. All of this is indicated in the ticket that was found below on the administrative ticket panel.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_155321.png)

We also know that BGP is being advertised on these networks to try to update routes. There are indications that BGP wasn't configured properly and routes could be injected into the network. It appears that we are on Router 1 due to our hostname on the network.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_155447.png)

#### FTP Server Location

An FTP server was mentioned on the 10.120.15.0/24 network. The bash one-liner below performs an automated ping sweep to locate servers on the network. As we can see from the output, 10.120.15.10 was the only other computer on the network and basic testing with ncat shows that the server is running vsFTPd 3.0.3 on the standard port 21.

`for i in {1..254} ;do (ping -c 1 10.120.15.$i | grep "bytes from" &) ;done`

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_160622.png)

#### BGP Configuration Files

Below shows the basic enumeration of the BGP configuration files on the target server. The presence of these files means that this router is in control of the BGP configuration being advertised on the network. Since we have root access on the router server we can edit these BGP configurations and re-write Layer 3 routing on the network.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_160800.png)

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_160837.png)

#### Router Interface

After some enumeration, the vtysh binary on the target server allows us to interface with the router and perform the enumeration and configuration of the router. Launching this interface shows that the router is a Quagga 0.99.24.1 router.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_160912.png)

#### BGP Attack

We can reroute the FTP traffic by performing the following steps in the router configuration. This will force the VIP logging into FTP to go through our router to get to it. We can then intercept and steal the password being used. By using TCPdump to monitor the network traffic we can intercept the FTP login as it is occurring through our router.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_164332.png)

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_164349.png)

#### PCAP Analysis - Root Credentials

After loading the PCAP into Wireshark we can perform a static analysis of the traffic that took place. The username and password for FTP were used which is `root:BGPtelc0rout1ng`.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_164513.png)

#### SSH Shell as Root

Using the found credentials on the SSH port that is exposed to the local network provides a shell as root.

![Screenshot](/assets/images/2022-02-24-Carrier-HTB-Writeup/Screenshot_20220225_164654.png)
