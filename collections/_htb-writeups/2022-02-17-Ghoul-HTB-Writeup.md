---
title: "Ghoul - HTB Writeup"
header: 
  teaser: /assets/images/2022-02-17-Ghoul-HTB-Writeup/Ghoul-HTB-Image.png
  header: /assets/images/2022-02-17-Ghoul-HTB-Writeup/Ghoul-HTB-Image.png
  og_image: /assets/images/2022-02-17-Ghoul-HTB-Writeup/Ghoul-HTB-Image.png
excerpt: "The Tomcat page was accessible with the weak credentials of `admin:admin`.  This appears to be another basic template website with minimal features. The file upload does point to the possible RCE that was mentioned."
tags: [htb, writeup, ghoul]
---

## Ghoul - Methodologies

### Information Gathering

#### Nmap Port Scan

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220224_122708.png)

#### Nmap Script Scan

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220224_122721.png)

#### Nmap Full Port Scan

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220224_122742.png)

#### Nikto Web Scan on Port 80

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220224_122811.png)

#### FuFF Web Enumeration on Port 80

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220224_122837.png)

#### Nikto Port Scan on Port 8080

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220224_122854.png)

### Service Enumeration

#### Gobuster Directory Enumeration

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_184010.png)

#### HTTP Service Enumeration

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_163608.png)

The contact form doesn't work.

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_163651.png)

/users

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_164056.png)

/secret.php

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_164117.png)

User password revealed

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_164334.png)

`ILoveTouka`

#### Tomcat Enumeration on Port 8080

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_164416.png)

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_164442.png)

The Tomcat page was accessible with the weak credentials of `admin:admin`.  This appears to be another basic template website with minimal features. The file upload does point to the possible RCE that was mentioned.

### Penetration

#### ZipSlip Exploitation

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_164906.png)

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_165008.png)

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_165023.png)

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_165118.png)

#### User Shell As www-data

We are in a docker container, as we can see by the IP address.

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_165152.png)

#### Tomcat Credentials

Almost every installation of tomcat has a tomcat-users.xml file that holds credentials.

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_165413.png)

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_165442.png)

`admin:test@aogiri123`

#### SSH Keys in Backups

In /var/backups/backups/keys many SSH keys can be exfiltrated.

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_165822 1.png)

kaneki.backup is password protected, using the `ILoveTouka` password from earlier we can SSH into the host machine (the target) as the Kaneki user.

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_170215.png)

#### Kaneki User Shell

We're still in a docker container, there are notes on the server that points toward remote management and a vulnerability in Gogs. We also see the reference to the password request earlier on behalf of the Eto individual. Looking in authorized keys we see a user kaneki_pub@kaneki-pc which must be another computer on the docker subnet.

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_170559.png)

Performing a quick command line ping sweep shows the other computer must 172.20.0.150.

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_170859.png)

Now that we know the host we can SSH into it without the private key.

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_171039.png)

#### Kaneki_pub User Shell

We have yet another docker container on the environment and even one more docker subnet of 172.18.0.0/16 for which we are 172.18.0.200. We can run the same ping sweep to try to identify hosts on this network, possibly the Gogs server.

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_171323.png)

We see another host of 172.18.0.2, we can assume that this is the Gogs server and begin port forwarding through our SSH shells to be able to access it on our Kali host.

#### SSH Port Forwarding

Gogs runs on port 3000 by default so we can port forward those through SSH to access it directly on our Kali host.

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_172004.png)

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_172107.png)

#### Gogs Exploitation

The page shows that we are running Go 1.11 and Gogs version 0.11.66.0916.

We already have the username AogiriTest from the previous enumeration, and using that in combination with the tomcat password we found previously allows us to log in to the Gogs page.

`AogiriTest:test@aogiri123`

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_172423.png)

We see another user on the page.

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_173327 1.png)

CVE-2018-18925

<https://nvd.nist.gov/vuln/detail/CVE-2018-18925>

<https://github.com/RyouYoo/CVE-2018-18925>

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_173114.png)

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_173442.png)

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_173518.png)

By hovering over the fork we can see the repo ID

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_174403.png)

Replace the cookie and reload

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_174448.png)

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_174458.png)

We can reset the administrator password and then use a Metasploit module.

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_174542.png)

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_174613.png)

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_174757.png)

#### SUID Enumeration

Gosu is on the box, Googling it shows that it is a Go implementation of su.

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_175249.png)

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_175410.png)

Aogiri-app.7z is the only relevant file on the machine, we can download it for static analysis.

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_175549.png)

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_175555.png)

It appears to be a zipped Git repo

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_175820.png)

`git reflog -p`

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_175931.png)

We find a password that we can try.

It only works on a su to root on kaneki-pc

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_180038.png)

### Privilege Escalation

Downloading Pspy to try to figure out wtf is going on

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_180323.png)

![Screenshot](/assets/images/2022-02-17-Ghoul-HTB-Writeup/Screenshot_20220214_183743.png)
