---
title: "RedCross - HTB Writeup"
header: 
  teaser: /assets/images/2022-03-03-RedCross-HTB-Writeup/RedCross-HTB-Image.png
  header: /assets/images/2022-03-03-RedCross-HTB-Writeup/RedCross-HTB-Image.png
  og_image: /assets/images/2022-03-03-RedCross-HTB-Writeup/RedCross-HTB-Image.png
excerpt: "Nmap performs automated port scanning to identify open ports and services on the local network against the target server. An initial scan against the top 1000 most common ports shows that three common ports are being used, 22, 80, and 443. Port 22 indicates that the server is configured for remote management on the local network. Port 80 and 443 indicate that a web server is being hosted using both HTTP and HTTPS protocols."
tags: [htb, writeup, redcross]
---
## RedCross

### Information Gathering

#### Nmap Port Scan

Nmap performs automated port scanning to identify open ports and services on the local network against the target server. An initial scan against the top 1000 most common ports shows that three common ports are being used, 22, 80, and 443. Port 22 indicates that the server is configured for remote management on the local network. Port 80 and 443 indicate that a web server is being hosted using both HTTP and HTTPS protocols.

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220228_213618.png)

#### Nmap Script Scan

A script scan is run against the target to perform automated enumeration on the identified services. Port 22 is banner grabbed and returns an OpenSSH 7.4p1 header that indicates that it is running on Debian. Port 80 simply redirects to the port 443 service and reveals the intra.redcross.htb hostname. Port 443 shows some basic information about SSL and the target site behind it. The website is running on Apache 2.4.25.

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220228_213632.png)

#### SSL Scan

SSL Scan is run against port 443 to identify SSL properties and configuration and perform basic security scanning against the service. It appears that older versions of TLS are being supported which can leave end users open to cryptographic attacks.

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220228_213712.png)

### Service Enumeration

#### Nikto Scan on Port 80

Nikto performs automated web scanning against the target web service to identify common security configurations and vulnerabilities. The target web service is running on Apache 2.4.25 which is out of date and EOL.

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220228_213757.png)

#### HTTP Service Enumeration

Manual HTTP service enumeration can be performed by browsing the target service in a browser. A login page is presented that shows an Intranet messaging system titled RedCross.

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220228_204354.png)

### Penetration

#### Contact Form Cross-Site Scripting

A contact form can be found on the HTTP service. After a simple cross-site scripting attack attempt we can see that user input is not being properly sanitized and therefore text is being rendered as Javascript code.

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220228_204729.png)

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220228_204746.png)

By performing a cross-site scripting attack on the site we can see a response that shows an administrator logging in and viewing the code. Using the PHPSESSID cookie are given an administrator session on the site as shown below.

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220228_205358.png)

#### UserID Search SQL Injection

The UserID function in the administrative panel is SQL injectable. By moving the request to SQL map we can automate SQL injection exploitation and enumerate the database behind the service. Below shows the steps to reveal the usernames and password hashes.

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220228_205814.png)

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220228_213001.png)

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220228_213434.png)

#### Admin VHOST Panel

Performing a Gobuster enumeration scan on the virtual hosts of the target HTTP service shows that admin.redcross.htb is a valid virtual hostname. Entering this hostname for the target IP address in /etc/hosts allows us to resolve a subdomain for the IT administrator panel.

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220228_222418.png)

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220228_221806.png)

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220228_221832.png)

#### Password Cracking

After performing an offline password cracking using the rockyou.txt wordlist we can crack one password and the credentials are shown below.

`charles:cookiemonster`

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220228_222601.png)

#### Admin Page Cookie Use

Using the same cookies that were stolen by the cross-site scripting attack shown above, we can authenticate to the IT admin panel found under the admin.redcross.htb virtual hostname.

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220319_163603.png)

#### Network Access Adding Attacking Machine

The firewall setting on the IT administrator panel allows us to add our IP address to the allowed list for whitelisted IPs.

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220319_163641.png)

#### New Nmap Scan

Now that we are a whitelisted IP we run our port enumeration with Nmap once again. This time new ports are returned including a Haraka instance on port 1025.

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220319_163736.png)

#### Haraka on Port 1025 Exploitation

Using the Metasploit module and exploit linked below we can exploit the Haraka instance and gain a user shell as the Penelope user.

<https://www.exploit-db.com/exploits/41162>

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220319_170307.png)

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220319_170319.png)

### Privilege Escalation

#### DB Creds Found in Files

The file located at /var/www/html/admin/pages/actions.php has database credentials:

`unixusrmgr:dheu%7wjx8B&`

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220319_170742.png)

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220319_170848.png)

#### PAM DB Integration Exploitation

We can read and write to the database and it appears that it controls local users on the file system including their groups and passwords. Start by adding our user and then we can update their group to 27 (sudo group) so they have sudo permissions. After logging in over SSH we have full access to the system.

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220319_172410.png)

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220319_172420.png)

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220319_172534.png)

![Screenshot](/assets/images/2022-03-03-RedCross-HTB-Writeup/Screenshot_20220319_172640.png)
