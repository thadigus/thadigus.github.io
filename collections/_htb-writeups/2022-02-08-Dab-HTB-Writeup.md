---
title: "Dab - HTB Writeup"
header: 
  teaser: /assets/images/2022-01-25-Dab-HTB-Writeup/Dab-HTB-Image.png
  header: /assets/images/2022-01-25-Dab-HTB-Writeup/Dab-HTB-Image.png
  og_image: /assets/images/2022-01-25-Dab-HTB-Writeup/Dab-HTB-Image.png
excerpt: "Dab is a database and web server that uses basic authentication mechanisms to reveal a database web app that is utilizing Memcache. The exploitation of the Memcache reveals usernames and password hashes. After enumerating valid usernames SSH is utilized to create a shell on the target. The OS is running several patches behind and therefore vulnerable to exploitation of the Polkit pkexec SUID binary."
tags: [htb, writeup, dab]
---

## Dab - High Level Summary

Dab is a database and web server that uses basic authentication mechanisms to reveal a database web app that is utilizing Memcache. The exploitation of the Memcache reveals usernames and password hashes. After enumerating valid usernames SSH is utilized to create a shell on the target. The OS is running several patches behind and therefore vulnerable to exploitation of the Polkit pkexec SUID binary.

### Recommendations

- Update all packages on the target machine and enroll the machine in a patch management program.

- Integrate a Web Application Firewall or other anti-brute forcing mechanisms into the web applications.

- Configure Memcached to not cache the users table.

- Utilize strong passphrases for SSH authentication.

- Configure FTP for User level authentication.

- Do not reveal Memcached usage in the web page source.

---

## Dab - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs a port scan on the target host. Four ports are open on target and they will be manually reviewed. Nmap discovers vsFTPd 3.0.3 with anonymous login, OpenSSH 7.2p2, an HTTP service running on Nginx 1.10.3, and another running on port 8080. These identify the base operating system as Ubuntu.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_134236.png)

#### Nikto Web Scan on Port 80

Nikto performs a port scan on the HTTP service running on port 80. Not much is found other than the standard anti-clicking jacking headers that are typically not present on custom applications or APIs.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_134220.png)

#### FFuF Scan on Port 80

FFuF performs directory enumeration on the host, it finds a code 200 page called login and a code 302 page called logout. There is most likely authentication taking place on the target site.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_134159.png)

#### Niikto Port Scan on Port 8080

Nikto performs the same scan on port 8080 finding the same results as port 80.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_134147.png)

#### FFuF Scan on Port 8080

FFuF was not able to enumerate port 8080 as the port was returning 200 codes on all queries.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_134134-1.png)

#### Dirb Scan on Port 80

Dirb was utilized to spider through the website pages but only found the same pages as above.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_144500.png)

### Service Enumeration

#### FTP Service Enumeration

The FTP service is running on port 21 on the target host. Using a wget recursive search we can download all of the content on the FTP server for further offline examination.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_210636.png)

The only file on the server is a JPG file with nothing on it. After checking for hidden information in the file there appears to be a message that simply states "Nope...".

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_210659.png)

#### Login Form on Port 80

On the HTTP service running on port 80, we are simply met with a login page.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_144539.png)

#### Access Denied on Port 8080

The HTTP service running on port 8080 returns "Access denied" in reference to a password authentication cookie.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_144557.png)

#### Enumerating Users on Port 80

Back to the login page, the service appears to reveal whether or not a user exists by returning a different login failed message. If the username exists it doesn't have a period in the login failed message.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_145105.png)

If the username does not exist it has a period in the login failed message.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_145147.png)

We can use Hydra to enumerate valid users based on the returned message. It appears that the username is not case-sensitive, so multiple instances of the same user are returned.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_145853.png)

#### Admin Password Attack

Using Hyrda once again with the admin username and the "rockyou" password word list we can perform a dictionary attack and find valid credentials for the admin user.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_150459.png)

`admin:Password1`

Using the credentials found to log into SSH does not work.

#### Authorized Enumeration on Port 80

After logging into the site with the admin credentials we found a page displaying the current stock in a database. There are no other features on the site, but the source code does show a debug comment.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_150535.png)

Debug states data was loaded from MySQL.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_151334.png)

Debug states data was loaded from the cache.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_151308.png)

The debugging comment changes the page isn't refreshed for a certain amount of time. This is showing that the page has some logic on the back end that caches recent queries against the back-end database.

#### Enumerating Web Service on Port 8080

On port 8080, adding the password cookie changes the message to say "incorrect". We can use wfuzz to fuzz for the correct cookie value. Wfuzz produces requests and the only request that differs from the rest is using the value "secret" for the password cookie.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_151811.png)

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_152131.png)

Using "secret" for the cookie parameter returns a page titled TCP Socket Test. The two parameters are port and command. Testing this with 22 returns an OpenSSH header. The same OpenSSH service is running on the machine. This tool appears to simply send commands to ports on localhost.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_152203.png)

#### Fuzzing for port numbers

We utilized Wfuzz once again to test all ports through the site. 11211 is the only port that isn't exposed, this appears to be running Memcached, since we can issue commands we can see the cached data in the MySQL database.

<https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers>

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_153520.png)

### Penetration

#### Dumping Data from Memcached

Since we can dump the cached memory for the SQL database we can show all of the entries when they have been recently cached. While we don't care about the data that is being stored for the list item stock being displayed on port 80 we can assume that the user authentication queries are also being cached. Since we can read all cached data we can read the user's table.

Initially dumping the users table returns no data, but this is because the data expires after a certain amount of time. Going back to the page on port 80, logging out, and logging back into the site caches the data. Moving quickly to query this table again we are returned with usernames and password hashes from the database.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_154158.png)

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_154313.png)

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_154408.png)

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_154428.png)

#### Using Users Table to Fuzz SSH

We exported the data in the users table for offline data work. After creating a user list from the data we can utilize the SSH Enumusers module from Metasploit to find valid SSH users.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_160321.png)

#### Genevieve SSH Shell

The valid user Genevieve is found, we can extract that user's password hash from our database dump and then utilize the CrackStation rainbow table service to find the valid password.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_160528.png)

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_160929.png)

`genevieve:Princess1`

With the valid username and password combination, we can log into the target machine as the Genevieve user.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_161035.png)

### Privilege Escalation

#### Polkit Exploitation

After enumerating SUIDs we see that Polkit is installed on this box as is evident with the /usr/lib/pkexec SUID binary.

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_161234.png)

This exploit is most likely not the intended path as it was discovered very recently in November of 2021, but it is valid on this machine until patched. The other non-standard SUID binaries on the machine will have to be enumerated further. Using the exploit below, though, we can create a reverse shell on the machine as shown below.

<https://cve.mitre.org/cgi-bin/cvename.cgi?name=2021-4034>

<https://github.com/berdav/CVE-2021-4034>

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_161818.png)

![Screenshot](/assets/images/2022-01-25-Dab-HTB-Writeup/Screenshot_20220128_161917.png)

### Vulnerability Assessments

|---+---+---+---|
| Reference | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- |
| Polkit Privilege Escalation | Critical | 0 | An un-patched version of Polkit is running on the machine allowing users to escalate to root. |
| HTTP Login Form Brute Force-able | High | 0 | The login form found on Port 80 can be brute forced allowing attackers to bypass authentication. |
| HTTP Login Form User Enumeration | High | 0 | The login form on port 80 reveals valid user names through the return message. |
| Static HTTP Authentication Cookie | Medium | 0 | Attackers can brute force the authentication cookie on port 8080 allowing them to bypass authentication. |
| Weak Password - Genevieve User | Medium | 0 | The genevieve user is utilizing an easily crack-able password. |
| Memcached Access to Users Table | Low | 0 | Memcached is storing unnecessary sensitive data in the form of the username and password hash table. |
| FTP Anonymous Access | Low | 0 | The FTP service allows for anonymous access, this should be set up for user authentication. |
| Source Comments Reveal Memcached Usage | Informational | 0 | Comments in page source reveal caching of database contents.|
