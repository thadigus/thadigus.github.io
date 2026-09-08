---
title: "Mango - HTB Writeup"
header: 
  teaser: /assets/images/2022-04-07-Mango-HTB-Writeup/Mango-HTB-Image.png
  header: /assets/images/2022-04-07-Mango-HTB-Writeup/Mango-HTB-Image.png
  og_image: /assets/images/2022-04-07-Mango-HTB-Writeup/Mango-HTB-Image.png
excerpt: "The login request is moved to Burp for further enumeration. Basic SQL injection tests show that the database is not SQL injectable. Testing with an `[$ne]=` (the equivalent to a `' OR 1=1-- -` for the MongoDB NoSQL back-end database) shows that user input sanitization is being performed on the login form. This returns a 302 Found instead of the 200 OK response."
tags: [htb, writeup, mango]
---
## Mango

### Information Gathering

#### Nmap Port Scan

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_204410.png)

#### Nmap Script Scan

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_204426.png)

### Service Enumeration

#### Nikto Web Scan on Port 80

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_204516.png)

#### FFuF Web Enumeration on Port 80

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_204530.png)

#### SSL Scan on Port 443

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_204600_1.png)

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_204617.png)

#### Nikto Web Scan on Port 443

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_204635.png)

#### FFuF Web Enumeration on Port 443

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_204652.png)

#### Web Enumeration on Port 80

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_204900.png)

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_205025.png)

#### Web Enumeration on Port 443

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_204935.png)

### Penetration

#### Login Page MongoDB Exploitation

The login request is moved to Burp for further enumeration. Basic SQL injection tests show that the database is not SQL injectable. Testing with an `[$ne]=` (the equivalent to a `' OR 1=1-- -` for the MongoDB NoSQL back-end database) shows that user input sanitization is being performed on the login form. This returns a 302 Found instead of the 200 OK response.

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_213514.png)

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_213603.png)

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_213715.png)

We can use this piece of information to enumerate the database and find the true administrator password. A Python script is below that shows the automated enumeration of these credentials.

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_223354.png)

This admin password is not useful for any of the other services on the target. We can try more users with the initial payload, and then the second exploit to find their passwords. Using the name of the box we can attempt the `mango` user and we find the following credentials: `mango:h3mXK8RhU~f{]f5h`

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_223615.png)

#### Mango User Shell

We can SSH in as the Mango user, but they do not have ownership of anything.

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_224833.png)

### Privilege Escalation

#### Admin User Shell

While we cannot SSH into the target server as the admin user the admin user does exist on the target machine and by using the password found in the database initially we can pivot to the admin user and read the user flag.

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_225042.png)

#### JJS SUID Binary Exploitation

Quick enumeration with automated privilege escalation enumeration scripts shows that a SUID is set on the target host for the binary at `/usr/lib/jvm/java-11-openjdk-amd64/bin/jjs` and is running with root-level permissions by all users. This is a publicly known SUID GTFO Binary which means that there is public documentation on how to utilize these permissions for privileged file reading and a privileged shell. The second screenshot below shows the process for a privileged file read, as we read `/root/root.txt` on the target server. The second screenshot shows the privileged file read that allows us to copy our public key into `/root/.ssh/authorized_keys`. After performing this exploitation we can SSH in as root on the target server.

<https://gtfobins.github.io/gtfobins/jjs>

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_225709.png)

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_230942.png)

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_231436.png)

![Screenshot](/assets/images/2022-04-07-Mango-HTB-Writeup/Screenshot_20220404_231449.png)
