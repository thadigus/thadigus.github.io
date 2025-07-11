---
title: "Helpline - HTB Writeup"
header: 
  teaser: /assets/images/2022-02-10-Helpline-HTB-Writeup/Helpline-HTB-Image.png
  header: /assets/images/2022-02-10-Helpline-HTB-Writeup/Helpline-HTB-Image.png
  og_image: /assets/images/2022-02-10-Helpline-HTB-Writeup/Helpline-HTB-Image.png
excerpt: "Nmap performs automated port scanning to identify open services and ports available on the local network. A full port scan identifies ports 135, 445, and 5985 which are standard Windows ports for features such as SMB. Port 5985 is running Web Service Management (WSMan) which is a PowerShell-based service for managing web services running on the Window platform. Port 49667 is just a Windows RPC service for Remote Procedure Calls that runs on a random high port. The non-standard service being run on this target is open on port 8080 which is an HTTP server."
tags: [htb, writeup, helpline]
---

## Helpline - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs automated port scanning to identify open services and ports available on the local network. A full port scan identifies ports 135, 445, and 5985 which are standard Windows ports for features such as SMB. Port 5985 is running Web Service Management (WSMan) which is a PowerShell-based service for managing web services running on the Window platform. Port 49667 is just a Windows RPC service for Remote Procedure Calls that runs on a random high port. The non-standard service being run on this target is open on port 8080 which is an HTTP server.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_202824.png)

#### Nikto Web Scan on Port 5985

Nikto performs basic automated security scanning to identify any common vulnerabilities or configurations on the target web server. Running this against the WSMan API can identify issues that reveal exploitation of the target service. No security headers are set on the target server but these are expected since it is a remote API without GUI functionality.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_202945.png)

#### Nikto Web Scan on Port 8080

Nikto was also used to perform an automated security assessment of the HTTP service running on port 8080. Security headers such as cross-site scripting protection headers, anti-clickjacking headers, and X-Content-Type-Options. These headers do not affect the security of the site directly, but without them, end users are left vulnerable to cross-site scripting attacks and more. Nikto also identifies multiple files on the server that may contain configurations or sensitive information to be enumerated manually.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_202935.png)

### Service Enumeration

#### SMB Service Enumeration

Nmap also performs automated service enumeration in the form of a script scan against particular identified services such as SMB. Three common vulnerabilities are tested with scripts to ensure that the target is not vulnerable. Nmap finds that the target is not vulnerable to any of these common vulnerabilities.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_203018.png)

#### HTTP Service Enumeration

Browsing to the HTTP service on port 8080 returns a login page for a product called ManageEngine ServiceDesk Plus. This appears to be a service management database system to assist with an IT help desk. Doing some initial research shows that this is a full web application with a lot of functionality to possibly exploit.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_101845.png)

#### Guest Login

Using the credentials guest:guest allows for guest logon to the target service. This simple username and password combination means that end users and attackers can easily guess credentials that can allow for access to the application, which might not be intended. There can be sensitive data in a ticketing system such as vulnerabilities that are currently being patched by security teams and more. One sensitive file is identified in the service management platform that indicates a password audit.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_101932.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_102236.png)

#### Password Audit Excel Document

After downloading the attached Password Audit.xlsx we can view the contents of the spreadsheet. At an initial glance, there doesn't appear to be any sensitive information in this spreadsheet. There is a hidden sheet in the file titled 'Password Data' and opening this hidden sheet shows various passwords for the environment. The username and password combinations do not work on any of the currently accessible authentication methods such as WinRM, the service management system, and SMB.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_103305.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_103343.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_103445.png)

### Penetration

#### Privilege Escalation to Administrator on Web App

After searching publicly accessible exploit databases there are many exploits for the login and authentication system used for this web application. An authorization bypass and user enumeration vulnerability exist on a slightly older version, and the vulnerability linked below allows for privilege escalation if a user account is already in possession. Since we can log in with the guest account this means that we can escalate to a user.

<https://www.exploit-db.com/exploits/46659>

Doing this by hand is quite simple:

- Login to the main site as guest:guest (default credentials)

- Navigate to <http://10.10.10.132:8080/mc>

- Logout of MC

- Log into the MC site as administrator:anything (default username)

- Navigate to <http://10.10.10.132:8080/> you should be redirected to an administrative section.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_023548.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_023625.png)

#### In Depth

The script was super broken so I had to do it all manually. After logging in using the browser we can take our authenticated cookies. Intercepting with burp allows us to easily get all the relevant cookies.

`/j_security_check` returns a set cookie, this is the first cookie.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_213109.png)

Eventually, we are redirected to the /HomePage.do and we are given our authenticated cookie set.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_213222.png)

Then we browse to /mc in the browser by hand to get our authenticated mc cookie set and let it redirect you through to the page.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_213311.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_213451.png)

Magic Step 1 is sending a GET request to /mc/jsp/MCLogOut.jsp with the MC cookie, the first authenticated session ID as well as the authenticated JSESSIONSSO cookie (both of these were given on the main site). This can be done by clicking log out in the browser.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_213605.png)

The second magic step is to do a GET request to /mc/jsp/MCDashboard.jsp with the same cookies as above, which should return a 200 OK and return new cookies. Then new JESSIONID cookie is going to be authenticated. Clicking logout in the browser on the previous step should automatically perform these actions.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_213734.png)

Next, do a GET / and YOU WILL HAVE ADD COOKIES. Use, in order, the authenticated MC cookie from above, the first authenticated JSESSION cookie from the authenticated guest session, and the JSESSIONSSO. This will respond with a new JESSIONID cookie, this is an administrative cookie.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_214149.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_214315.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_214450.png)

Browse back to `/mc`. Login now with the username Administrator and the password of "anything" (this string doesn't matter). Intercept the JSecurity check for the administrative logon, replace the JSESSIONID cookies with the one returned after the logout request, and then the previous step that is from /, there should be no JESSIONSSO on this in the intercept. This will return the two cookies that can be used for an administrative session and might even just forward your browser into the administrative session on the site.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_220654.png)

All of this is because the cookies aren't properly sanitized when a user logs out so they are still valid after logout, bypassing the authentication on any user, we chose the administrative user.

#### Reverse Shell

Under the Admin tab, we can set up a custom trigger to run a command whenever we would like. The following will download Netcat when a new ticket is created.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_025431.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_025720.png)

The following will run a reverse shell when a ticket is created.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_025821.png)

This creates a reverse shell as NT AUTHORITY\SYSTEM.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_025919.png)

#### Shell as NT AUTHORITY\SYSTEM

The root flag is encrypted. Enumeration shows that only the administrator user can decrypt the root hash.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_030134.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_032943.png)

Since we have permissions as NT AUTHORITY\\SYSTEM we can disable the anti-virus on the target machine to allow for easier post-exploitation.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_030312.png)

The user.txt file is also stored in a user's desktop folder. The Tolu user is the only user able to decrypt it as well so this user will need to be compromised to decrypt the sensitive data.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_033317.png)

#### Enumerating Users with Mimikatz

With anti-virus disabled, we can use tools such as Mimikatz as the system-level user. With LSADUMP we can dump the NTLM hashes for all users on the box. The download and results are shown below.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_031053.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_031204.png)

```yaml

mimikatz # lsadump::sam

Domain : HELPLINE

SysKey : f684313986dcdab719c2950661809893

Local SID : S-1-5-21-3107372852-1132949149-763516304

SAMKey : 9db624e549009762ee47528b9aa6ed34

RID  : 000001f4 (500)

User : Administrator

  Hash NTLM: d5312b245d641b3fae0d07493a022622

RID  : 000001f5 (501)

User : Guest

RID  : 000001f7 (503)

User : DefaultAccount

RID  : 000001f8 (504)

User : WDAGUtilityAccount

  Hash NTLM: 52a344a6229f7bfa074d3052023f0b41

RID  : 000003e8 (1000)

User : alice

  Hash NTLM: 998a9de69e883618e987080249d20253

RID  : 000003ef (1007)

User : zachary

  Hash NTLM: eef285f4c800bcd1ae1e84c371eeb282

RID  : 000003f1 (1009)

User : leo

  Hash NTLM: 60b05a66232e2eb067b973c889b615dd

RID  : 000003f2 (1010)

User : niels

  Hash NTLM: 35a9de42e66dcdd5d512a796d03aef50

RID  : 000003f3 (1011)

User : tolu

  Hash NTLM: 03e2ec7aa7e82e479be07ecd34f1603b

```

Zachary's NTLM hash cracks on Crackstation. Zachary can read system logs.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_222931.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_031458.png)

#### System Log Enumeration

Searching through system logs with permissions of Zachary shows that there was an instance of a command that was run with the Tulo user echoing their password on the command line. Enumerating the Tolu user permissions shows that Tolu has remote management privileges on the target.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_031955.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_032134.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_032151.png)

#### User Shell as Tolu

Using Evil-WinRM we can remote into the system to finally get a user shell. We can't type user.txt because it is encrypted. Using our Windows credentials to decrypt it, we can finally get the user flag.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_110500.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220210_223733.png)

### Privilege Escalation

#### Leo User Enumeration - Meterpreter Session

Leo's desktop has a file called admin-pass.xml this is most likely a form of administrator credential that we could use to decrypt root.txt if we could take over Leo's session. To use modules for user impersonation we can move to a Meterpreter session using a Metasploit module web_delivery.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_034434.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_034920.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_034935.png)

#### Impersonating the Leo Session

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_035023.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_035057.png)

Now that we are Leo we can use the admin-pass.xml to read root.txt.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_035149.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_035342.png)

#### Reverse Shell as Administrator

Using this same line we can run a reverse shell as administrator on the target.

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_040505.png)

![Screenshot](/assets/images/2022-02-10-Helpline-HTB-Writeup/Screenshot_20220212_040455.png)
