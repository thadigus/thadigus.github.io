---
title: "Wall - HTB Writeup"
header: 
  teaser: /assets/images/2022-03-31-Wall-HTB-Writeup/Wall-HTB-Image.png
  header: /assets/images/2022-03-31-Wall-HTB-Writeup/Wall-HTB-Image.png
  og_image: /assets/images/2022-03-31-Wall-HTB-Writeup/Wall-HTB-Image.png
excerpt: "While we cannot access the /monitoring endpoint through the browser, moving this request into Burp Suite and simply changing the request verb allows us to bypass the basic authentication mechanism. Doing so will dump us at a Centreon login page. We now have a valid PHPSESSID from our bypassed authentication to use for further enumeration."
tags: [htb, writeup, wall]
---
## Wall

### Information Gathering

#### Nmap Port Scan

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_210455.png)

#### Nmap Script Scan

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_210510.png)

### Service Enumeration

#### Nikto Web Scan on Port 80

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_210545.png)

#### FFuF Web Enumeration

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_210609.png)

#### Gobuster Directory Enumeration

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_215629.png)

#### Web Service Enumeration

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_215543.png)

#### /monitoring Endpoint

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_215807.png)

### Penetration

#### HTTP Verb Tampering

While we cannot access the /monitoring endpoint through the browser, moving this request into Burp Suite and simply changing the request verb allows us to bypass the basic authentication mechanism. Doing so will dump us at a Centreon login page. We now have a valid PHPSESSID from our bypassed authentication to use for further enumeration.

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_220303.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_220313.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_220340.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_220416_1.png)

#### Centreon Login Enumeration

The Centreon service does not use default or common credentials. There is also a CSRF token noted in the source code titled centreon_token which will make a password brute force very difficult, as this value will change with its request each time, as is its intended purpose.

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_220648.png)

#### Centreon Admin Password Brute Forcing

A python script from GitHub can be easily modified to use the CRSF token each time the web page is loaded. The process is documented as follows:

`admin:password1`

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_221823.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_221835.png)

#### Centreon Administrator Dashboard Enumeration

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_222303.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_222327.png)

#### Centreon RCE - CVE 2019-13024

Documented in the article below is the exploitation of CVE 2019-13024. A parameter in the Centreon dashboard that allows users to run scripts on startup can be escaped to run shell-level commands on the target server. It appears that a WAF is not allowing spaces to be submitted, but we can use the special `${IFS}` variable to inject spaces and let the reverse shell one-liner run.

<https://shells.systems/centreon-v19-04-remote-code-execution-cve-2019-13024/>

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_222432.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_222504.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_223011.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_223021.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_223551.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_223715.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_223631.png)

#### Backup Python Binary

A non-standard binary in /opt/.shelby titled backup appears to be a Python2.7 byte compiled binary. We aren't given very much verbosity when running the binary so we process it into base64 to exfiltrate the binary to our attacking machine. After successful exfiltration, we can use Uncompyle6 to decompile the Python binary. Credentials are stored in the source code for the Shelby user.

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_223930.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_224258.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_225411.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_225421.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_225504.png)

`shelby:ShelbyPassw@rdIsStrong!`

#### Shelby User Shell

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_225827.png)

### Privilege Escalation

#### SUID Binary Enumeration

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_230221.png)

#### Screen 4.5.0 SUID Exploitation

The Shelby user has access to the SUID binary located at /bin/screen. This specific version of Screen 4.5.0 has a code execution exploit that will allow us to take advantage of the SUID binary and run OS commands as root on the target server.

<https://www.exploit-db.com/exploits/41154>

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_230423.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_230757.png)

![Screenshot](/assets/images/2022-03-31-Wall-HTB-Writeup/Screenshot_20220331_230745.png)
