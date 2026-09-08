---
title: "Silo - HTB Writeup"
header: 
  teaser: /assets/images/2022-02-03-Silo-HTB-Writeup/Silo-HTB-Image.png
  header: /assets/images/2022-02-03-Silo-HTB-Writeup/Silo-HTB-Image.png
  og_image: /assets/images/2022-02-03-Silo-HTB-Writeup/Silo-HTB-Image.png
excerpt: "Silo is an Oracle database server with its services exposed to the local network. The service uses an insecure SID configuration and default/weak user credentials for the database service. The service is running as the system account so successful exploitation of the 'sysdba' permissions leads to a reverse shell as the SYSTEM-level user."
tags: [htb, writeup, silo]
---
## Silo - High Level Summary

Silo is an Oracle database server with its services exposed to the local network. The service uses an insecure SID configuration and default/weak user credentials for the database service. The service is running as the system account so successful exploitation of the 'sysdba' permissions leads to a reverse shell as the SYSTEM-level user.

### Recommendations

- Harden Oracle Implementation with secure SID and user credentials.

- Attempt to restrict access to the Oracle Database server with firewalls and user access restrictions.

---

## Silo - Methodologies

### Information Gathering

#### Nmap Port Scan

Nmap performs a port scan to identify available ports and services on the target that are exposed to the local network. The ports found to indicate that the target is a Windows host because of the SMB and NetBIOS services that are exposed. The server is also hosting an HTTP web service on port 80 and port 8080. Port 1521 is running an Oracle application and will be enumerated further.

![Screenshot](/assets/images/2022-02-03-Silo-HTB-Writeup/Screenshot_20220204_001219.png)

![Screenshot](/assets/images/2022-02-03-Silo-HTB-Writeup/Screenshot_20220204_001232.png)

#### Nikto Web Scan

Nikto performs a remote web scan to identify vulnerabilities and information on a web server. The below scan on port 8080 reveals that the service is an Oracle WebDav service.

![Screenshot](/assets/images/2022-02-03-Silo-HTB-Writeup/Screenshot_20220204_001402.png)

### Service Enumeration

#### Web Server Enumeration

The web services on port 80 appear to be the default install of IIS. Further enumeration with fuzzing and Gobuster returned nothing so this is most likely completely stock and not exploitable.

![Screenshot](/assets/images/2022-02-03-Silo-HTB-Writeup/Screenshot_20220204_001431.png)

#### ODAT Attempted Enumeration

NmapAutomator saw the Oracle port and attempted to run automated SID and password guessing using the ODAT Oracle Database Attacking Tool. We can install this to further enumerate the Oracle service.

![Screenshot](/assets/images/2022-02-03-Silo-HTB-Writeup/Screenshot_20220204_001254.png)

#### ODAT Installation

The ODAT tool is freely available on GitHub and has installation instructions in its main README file. The steps taken to install this toolkit are documented below.

<https://github.com/quentinhardy/odat>

![Screenshot](/assets/images/2022-02-03-Silo-HTB-Writeup/Screenshot_20220203_233449.png)

![Screenshot](/assets/images/2022-02-03-Silo-HTB-Writeup/Screenshot_20220203_233722.png)

![Screenshot](/assets/images/2022-02-03-Silo-HTB-Writeup/Screenshot_20220203_233903.png)

![Screenshot](/assets/images/2022-02-03-Silo-HTB-Writeup/Screenshot_20220203_234052.png)

![Screenshot](/assets/images/2022-02-03-Silo-HTB-Writeup/Screenshot_20220203_234644.png)

### Penetration

#### Using ODAT for Oracle Exploitation

Utilizing ODAT to attack an Oracle database is simple. Utilizing the most common exploit chain we can enumerate SIDs and find a valid SID for the database application. From there we can utilize a common list of credentials against the server. The server is utilizing a simple credential pair of `Scott:tiger`. This user is also able to execute administrative commands on the server including downloading files and running them as the application.

##### Finding SID

![Screenshot](/assets/images/2022-02-03-Silo-HTB-Writeup/Screenshot_20220203_234922.png)

##### Finding Password

![Screenshot](/assets/images/2022-02-03-Silo-HTB-Writeup/Screenshot_20220203_235635.png)

##### Arbitrary File Upload and Execution

Utilizing the administrative permissions of the Scott user we can download a reverse shell binary and execute it on the server. The service appears to be running as the NT AUTHORITY/SYSTEM user which is the top-level administrative user on the Windows Server. From here we can execute any commands on the target and enumerate the file system.

![Screenshot](/assets/images/2022-02-03-Silo-HTB-Writeup/Screenshot_20220204_000032.png)

![Screenshot](/assets/images/2022-02-03-Silo-HTB-Writeup/Screenshot_20220204_000050.png)

![Screenshot](/assets/images/2022-02-03-Silo-HTB-Writeup/Screenshot_20220204_000116.png)

### Vulnerability Assessments

|---+---+---+---|
| Vulnerability | Risk Rating | CVSSv3 Score | Description |
|: ----------- :|: ----------- :|: ----------- :|: ----------- |
| Insecure SID Configuration | Critical | 0 | The Oracle SID is easily enumerable and found from default wordlists. |
| Insecure Database Credentials | Critical | 0 | The Oracle server is using default/weak credentials for user logon. |
| Oracle TNS and XML DB Exposed | Informational | 0 | The Oracle services are exposed to the local network. |
| Oracle Database is running as System | Informational | 0 | The Oracle service is running as the SYSTEM account. |
