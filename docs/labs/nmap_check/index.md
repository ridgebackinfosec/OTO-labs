# Nmap Check

???+ warning "Setup"
    - Have at least one GOAD VM running. GOAD-DC02 will respond best for the LDAP script steps. GOAD-SRV02 will give better results in the vulners portion of this Lab.
    - Run the below command to setup an environment variable on The Forge VM.

    ```bash
    export GOAD="192.168.56.10-25"
    ```

    ![Terminal Output](img\image.png){ width="50%" }
    ///caption
    Terminal Output
    ///

## Intro

???+ warning
    A full listing of Nmap’s NSE scripts can be found at [https://nmap.org/nsedoc/scripts/](https://nmap.org/nsedoc/scripts/).

Nmap is a powerful tool used for network exploration, management, and security auditing. It can help you discover hosts and services on a network, map out your network topology, and identify security risks. In this lab, you will learn how to use Nmap to scan a network, discover hosts and services, and identify security vulnerabilities.

## Walkthrough

Scan the GOAD VM(s) using Nmap on The Forge VM.

???+ warning
    ***This can take several minutes to complete depending on your setup.***

```bash
mkdir nmap
cd nmap
sudo nmap -p- -A -Pn -oA nmap_lab $GOAD
```

We’re doing a few things with this scan…

- Running as root with the elevated `sudo` This gives nmap additional abilities.
- The option `-p-` directs nmap to conduct a “full port scan” of all 65,535 TCP ports.
- Nmap is doing an “aggressive” scan by using the `-A`
    - Enables OS detection, version detection, script scanning, and traceroute
- The `-Pn` option treats all hosts as online -- skip host discovery.
- Creating output file(s) by using the `-oA nmap_lab` for other tools to consume
    - **We might use this output in later Labs!**

Review the results…

Looks like LDAP is open.

![LDAP](img\Untitled.png){ width="50%" }
///caption
LDAP
///

HTTP (web service) is also accessible.

![HTTP](img\Untitled%201.png){ width="50%" }
///caption
HTTP
///

A database also appears to be running on the target.

![Database](img\Untitled%202.png){ width="50%" }
///caption
Database
///

???+ warning
    Note how most of these open services have NSE script results displayed with them. Giving you (the attacker) additional information that could be used in later phases of our attack and helps determine where to spend our time.

## Enumerate LDAP

An attacker would want to enumerate LDAP (Lightweight Directory Access Protocol) for several reasons:

1. **User Information Gathering**: LDAP stores user details such as usernames, email addresses, and even organizational roles. By enumerating LDAP, an attacker can compile a list of valid users, which can be leveraged for further attacks, such as brute-force attempts or social engineering.
2. **Privilege Escalation**: LDAP directories often contain information about group memberships and access controls. Understanding these relationships can help an attacker identify high-privilege accounts or poorly secured accounts that could be targeted for privilege escalation.
3. **Infrastructure Mapping**: LDAP directories often contain information about the network structure, including server names, workstations, and other networked devices. This information can help an attacker map the network, identifying critical assets and potential entry points.
4. **Password Policies and Weaknesses**: LDAP often holds details about password policies, including password expiration and complexity requirements. Enumerating this data can help attackers craft more effective attacks by understanding the security posture of the organization.
5. **Reconnaissance for Further Exploits**: Information gleaned from LDAP can be used to plan and execute further attacks. For example, understanding the structure and organization of the network and its users can help in spear-phishing campaigns or targeted exploits against specific systems.

In summary, LDAP enumeration can provide an attacker with a wealth of information that can be used to compromise an organization's network more effectively.

We can start this process by executing the below Nmap command.

```bash
sudo nmap -n --script="ldap* and not brute" -p 389 $GOAD
```

Here's the breakdown of the above Nmap command:

- **`sudo`** is used to execute **`nmap`** with root privileges, which may be required for certain network interfaces or to send raw packets, thereby granting **`nmap`** enhanced capabilities.
- The `-n` option prevents **`nmap`** from performing DNS resolution. This means that **`nmap`** won't try to resolve hostnames to IP addresses, speeding up the scan when the resolution isn't necessary for the scan's purpose.
- **`--script="ldap* and not brute"`** specifies which Nmap Scripting Engine (NSE) scripts to run. In this case:
    - **`ldap*`** means run all scripts whose names start with **`ldap`**.
    - **`and not brute`** excludes any scripts that perform brute-force attacks.
    - This combination targets all LDAP-related scripts except those designed for brute-forcing credentials.
- **`-p 389`** specifies the port number for the scan, where **`389`** is the default port for LDAP (Lightweight Directory Access Protocol), a protocol used for accessing and maintaining distributed directory information services over an IP network.

![Untitled](img\Untitled%203.png){ width="50%" }

## Find Users

> **krb-enum-users NSE script:**
*”Discovers valid usernames by brute force querying likely usernames against a Kerberos service.”*
~ [https://nmap.org/nsedoc/scripts/krb5-enum-users.html](https://nmap.org/nsedoc/scripts/krb5-enum-users.html)
> 

```bash
sudo nmap -p 88 --script=krb5-enum-users --script-args="krb5-enum-users.realm='north.sevenkingdoms.local',userdb=/usr/share/seclists/Usernames/top-usernames-shortlist.txt" $GOAD
```

- **`-p 88`**: Specifies the port to scan, in this case, port 88, which is the default port for the Kerberos Key Distribution Center (KDC) service.
- **`--script=krb5-enum-users`**: Utilizes the **`krb5-enum-users`** Nmap script. This script attempts to enumerate valid usernames from a Kerberos Key Distribution Center by exploiting the Kerberos protocol's behavior of differentiating between valid and invalid usernames at login attempts.
- **`--script-args="krb5-enum-users.realm='north.sevenkingdoms.local',userdb=/usr/share/seclists/Usernames/top-usernames-shortlist.txt"`**: Passes arguments to the **`krb5-enum-users`** script with two parameters:
    - **`krb5-enum-users.realm='north.sevenkingdoms.local'`**: Specifies the realm for the Kerberos service. In this case, it's set to 'north.sevenkingdoms.local'.
    - **`userdb=/usr/share/seclists/Usernames/top-usernames-shortlist.txt`**: Specifies the path to the database of usernames to attempt enumeration with. This path points to a file containing a list of popular usernames that the script will try to validate against the Kerberos service.

???+ warning
    Try the longer `/usr/share/seclists/Usernames/xato-net-10-million-usernames.txt` list too.



![User Enumeration](img\image%201.png){ width="50%" }
///caption
User Enumeration
///

Kerberos principals are unique identities in the Kerberos authentication system, which is widely used to secure network services. A principal can represent a user, a service, or a device that participates in network communications within a Kerberos-secured environment. Principals are central to Kerberos' ability to provide strong authentication and secure communication.

A Kerberos principal typically consists of three parts:

1. **Primary**: The primary part of a principal is the name of the user or service. For a user, this could simply be their username (e.g., `john`), while for a service, it is usually the name of the service (e.g., `http`).
2. **Instance**: The instance provides additional context for the primary, making it possible to differentiate between different roles or services associated with the same primary. For user principals, the instance part is often omitted. For services, it often includes the hostname of the machine providing the service (e.g., `http/server.example.com`).
3. **Realm**: The realm is a domain of administrative autonomy, providing an additional namespace layer. It is typically in uppercase and reflects the Kerberos domain within which the principal resides (e.g., `EXAMPLE.COM`). The realm allows the same primary and instance to be distinguished across different administrative domains.

A full Kerberos principal might look like `http@server.example.com@EXAMPLE.COM`, where `http` is the primary (indicating a service), `server.example.com` is the instance (specifying the host), and `EXAMPLE.COM` is the realm.

Key aspects of Kerberos principals include:

- **Uniqueness**: Each principal in a Kerberos realm is unique. This uniqueness ensures that each identity in the system can be securely authenticated and authorized for access to resources.
- **Secure Authentication**: Kerberos uses symmetric key cryptography and a trusted third party (the Key Distribution Center, KDC) to authenticate principals without transmitting passwords over the network.
- **Tickets**: Upon successful authentication, a principal receives tickets from the KDC. These tickets, which are encrypted and can only be decrypted by the intended recipient, allow the principal to prove its identity to other services (principals) within the Kerberos realm.
- **Service Access**: Principals can be granted access to various network services securely. Service principals ensure that only authenticated users can access services, and user principals can obtain service tickets to access these resources.

In summary, Kerberos principals are fundamental to the Kerberos authentication mechanism, enabling secure identification and communication across network services by leveraging strong cryptographic techniques.

## SMB

Try scanning for SMB vulnerabilities too. This won’t return any results for our lab environment but it would if you had the full GOAD test environment setup.

???+ warning
    If you want to know how to deploy the full GOAD environment, ask the instructor for the scripts.

```bash
sudo nmap -Pn --script=smb-vuln* -p 139,445 $GOAD
```

- **`-Pn`**: This option skips the discovery phase, treating all specified hosts as online and proceeding directly to port scanning. This can be useful if the target is using methods to ignore or block ping probes, which are used by Nmap by default to check if hosts are online.
- **`--script=smb-vuln*`**: Tells Nmap to use the scripting engine with a specific set of scripts. Here, it's targeting scripts that start with **`smb-vuln`**, which are designed to detect vulnerabilities in SMB services. Nmap's scripting engine (NSE) is a powerful feature that extends Nmap's capabilities to include vulnerability detection, exploitation, and more. The **`smb-vuln*`** pattern matches all scripts designed to find common SMB vulnerabilities, potentially identifying issues like those exploited by famous malware like WannaCry or NotPetya.
- **`-p 139,445`**: Specifies the ports to scan. Ports 139 and 445 are the traditional ports associated with SMB services. Port 139 is used for SMB over NetBIOS, whereas port 445 is for SMB directly over TCP/IP without the NetBIOS layer.

![image.png](img\image%202.png){ width="50%" }

## Vulners NSE

Let’s try the vulners NSE script now and see what comes back.

```bash
sudo nmap -sV --script=vulners $GOAD
```

- **`-sV`**: This option enables version detection, allowing Nmap to determine the version of the services running on open ports. Knowing the version is crucial for identifying specific vulnerabilities associated with those versions.
- **`--script=vulners`**: Specifies the use of the **`vulners`** NSE (Nmap Scripting Engine) script. The **`vulners`** script is a script that queries the Vulners vulnerability database to find known vulnerabilities of the detected service versions. It's a powerful way to quickly assess the potential vulnerabilities present on the scanned host(s) based on the service versions detected during the scan.

![image.png](img\image%203.png){ width="50%" }
///caption
Looks like there’s potential here.
///

Do some research on your own of the CVEs listed. Do any of them have public exploits?