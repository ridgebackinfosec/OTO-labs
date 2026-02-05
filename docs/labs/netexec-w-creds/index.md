# Lab - NetExec w/ Creds

???+ warning "Prerequisites"
    You'll need the GOAD-DC02 VM running to see these results.

## Intro

Now that we have some credentials on the Domain, let's revisit NetExec and see what new possibilities await us.

## Walkthrough

Here are a few NetExec commands that can really open up doors in an environment.

### Logged On Users

Remember that `--loggedon-users` flag from the netexec lab that required a local admin's credentials to work? Give it a try now that we have some creds...

```bash
nxc smb 192.168.56.10-23 -u robb.stark -p sexywolfy --loggedon-users
```

???- note "Command Options/Arguments Explained"
    - `nxc smb 192.168.56.10-23`: NetExec targeting SMB protocol across IP range
    - `-u robb.stark -p sexywolfy`: Authenticates with domain credentials (obtained from hashcat lab)
    - `--loggedon-users`: Enumerates currently logged-on users on each target system
    - Why credentials matter: This flag requires at least local admin rights on targets to query logged-on user sessions via remote registry or WMI
    - Attack value: Identifies which high-value users (e.g., Domain Admins) are currently active on which machines, helping attackers choose lateral movement targets
    - Use case: Find where privileged users are logged in, then target those systems for credential theft (mimikatz, lsassy) or session hijacking

### Local Groups

Enumerate local groups, if a group is specified then its members are enumerated...

```bash
nxc smb 192.168.56.10-23 -u robb.stark -p sexywolfy --local-groups
```

???- note "Command Options/Arguments Explained"
    - `--local-groups`: Enumerates all local security groups on each target (e.g., Administrators, Remote Desktop Users, Backup Operators)
    - Why enumerate groups: Reveals privilege structure on each system - shows which groups exist and who has elevated access
    - Attack value: Identifies potential privilege escalation paths and lateral movement opportunities based on group memberships
    - What to look for: Non-standard groups, users in Administrators group, service accounts with excessive privileges
    - Follow-up: Can specify a specific group to enumerate its members (e.g., `--local-groups Administrators`)

![NetExec output showing enumerated local security groups including Administrators and Remote Desktop Users](img/netexec-creds-local-groups.png){ width="70%" }
///caption
Local Groups
///

### Network Interfaces

Enumerate network interfaces of targets...

```bash
nxc smb 192.168.56.10-23 -u robb.stark -p sexywolfy --interfaces
```

???- note "Command Options/Arguments Explained"
    - `--interfaces`: Enumerates network interfaces and IP configurations on each target system
    - Information gathered: Interface names, IP addresses, subnet masks, MAC addresses, gateway configurations
    - Attack value: Maps network topology and identifies multi-homed systems that could serve as pivot points between network segments
    - Use case: Discover systems bridging different VLANs or network segments, identify potential routing paths for lateral movement
    - Network segmentation bypass: Multi-homed hosts can be leveraged to tunnel traffic between isolated networks

![NetExec interface enumeration displaying network adapter details including IP addresses and subnet masks](img/netexec-creds-interfaces.png){ width="70%" }
///caption
Network Interfaces
///

### Hash Gathering

Try dumping the SAM database (Security Account Manager) to get mor hashes. Remember this requires at least local admin level access on a target system. Do so using the `--sam` flag.

```bash
nxc smb 192.168.56.10-23 -u robb.stark -p sexywolfy --sam
```

???- note "Command Options/Arguments Explained"
    - `--sam`: Dumps the Security Account Manager (SAM) database from target systems
    - Privilege requirement: Requires local Administrator access on the target to read the SAM hive
    - What SAM contains: Local user accounts and their NTLM password hashes for that specific machine (not domain accounts)
    - Attack value: Extracted hashes can be cracked offline with hashcat or used for pass-the-hash attacks against other systems using the same local admin password
    - Common finding: Many organizations reuse the same local Administrator password across multiple systems, making lateral movement easy once you crack one hash
    - Storage location: SAM database is located at `C:\Windows\System32\config\SAM` and is normally locked while the OS is running

The is a file on Windows that stores local user account information for that specific machine. It holds usernames and password hashes for local accounts (not domain accounts). It also contains details like group memberships and security identifiers (SIDs).

In short, the SAM database is like a mini version of the NTDS file, but only for local accounts on one computer.

The Local Security Authority (LSA) which holds secrets in memory on a system is also a great place to get more creds. This can be accomplished with the `--lsa` flag. Its secrets are another piece of Windows’ credential storage, tied to the LSASS process.

???- warning "Elevated Privs Required"
    Requires Domain Admin or Local Admin Priviledges on target Domain Controller.

```bash
nxc smb 192.168.56.10-23 -u robb.stark -p sexywolfy --lsa
```

???- note "Command Options/Arguments Explained"
    - `--lsa`: Dumps Local Security Authority (LSA) secrets from target systems
    - Privilege requirement: Requires Domain Admin or Local Administrator access on the target system
    - What LSA secrets contain: Cached domain credentials, service account passwords, auto-logon credentials, VPN passwords, and other sensitive data stored by Windows for authentication
    - Attack value: LSA secrets often contain plaintext or reversibly encrypted passwords for service accounts, scheduled tasks, and cached domain logons
    - Process: Extracts secrets from the LSASS (Local Security Authority Subsystem Service) process memory and registry
    - Why valuable: Can reveal credentials not found in SAM, including domain account passwords used by services running on that machine

Finally, you can try retrieving the NTDS file. The **NTDS file** (often called `ntds.dit`) is basically the heart of **Active Directory** on a Windows domain controller.

```bash
nxc smb 192.168.56.10-23 -u robb.stark -p sexywolfy --ntds
```

???- note "Command Options/Arguments Explained"
    - `--ntds`: Dumps the NTDS.dit database from Domain Controllers
    - Privilege requirement: Requires Domain Admin privileges to access the NTDS.dit file on domain controllers
    - What NTDS.dit contains: The complete Active Directory database with ALL domain user account hashes, group memberships, computer accounts, security policies, and trust relationships
    - Attack value: This is the "keys to the kingdom" - contains every domain credential including Domain Admins, Enterprise Admins, and all service accounts
    - Extraction method: Uses Volume Shadow Copy Service (VSS) to create a snapshot and extract the normally locked NTDS.dit file
    - Post-extraction: Hashes can be cracked offline or used immediately for pass-the-hash attacks to compromise the entire domain
    - Impact: Complete domain compromise - with NTDS.dit, an attacker has persistent access even if all passwords are changed (until hashes are rotated)

![NTDS](img/nxc_ntds.png){ width="70%" }
///caption
NTDS
///

Here’s the simple breakdown:

* Think of NTDS as **a giant database file**.
* It stores all the important information about your network domain:

    * **User accounts** (names, passwords — in hashed/encrypted form)
    * **Groups** (who belongs where)
    * **Computers** (machines that are joined to the domain)
    * **Security info** (permissions, trust relationships, etc.)

In other words, if Active Directory is like the phonebook and security guard for a company’s network, the `ntds.dit` file is the **actual book** where all the names, numbers, and access rules are written down.

That’s why attackers, penetration testers, and defenders pay close attention to it — if someone gets hold of the NTDS file, they essentially get the **keys to the kingdom** (because it contains all the domain’s accounts and password hashes).

Once you have more hashes, you can try cracking them to get even more accounts.

???+ note "Comparisons"
    👉 In simple terms:

    * SAM = local usernames + password hashes
    * LSA secrets = cached credentials, service passwords, and keys that Windows uses behind the scenes
    * NTDS = domain-wide usernames + password hashes (and more)

## Optional: LDAP Exploration

???+ info "Optional"
    This is an **optional** part of the lab to explore on your own. No guidance will be provided.

LDAP (Lightweight Directory Access Protocol) is just a way for computers to talk to a directory service like Active Directory.

* Think of a directory like a phonebook: it stores names, numbers, addresses, etc. In IT, the “directory” stores users, computers, printers, groups, and their relationships.
* LDAP is the language (protocol) used to look things up or make changes in that phonebook.

For example:

* If you log in to your work computer, your username + password might get checked against Active Directory using LDAP.
* If a printer wants to know who you are before letting you print, it can ask the directory via LDAP.

👉 In short: LDAP is like the "search-and-verify tool" that applications and systems use to look people up in a big network phonebook (Active Directory or other directory services).

As luck would have it, NetExec also supports the LDAP protocol! [Here](https://www.netexec.wiki/ldap-protocol/authentication) is the documentation of what can be done using NetExec. Read, adapt, and explore on your own!

## Viewing Credentials in Cerno

Now that you've gathered credentials with NetExec, Cerno can display them alongside your Nessus findings. Cerno reads directly from NetExec's database to enrich vulnerability context with the credentials you've discovered.

Start the interactive review:

```bash
cerno review
```

???- note "Command Options/Arguments Explained"
    - `cerno review`: Launches the interactive TUI for reviewing imported Nessus findings
    - Navigation: Use number selection to browse findings by severity level
    - Actions: Each finding shows contextual actions in the footer including `[N] NetExec Data`

When viewing a finding that affects hosts you've enumerated with NetExec, you'll see a **NetExec Context** panel showing the credentials gathered from your scans:

![Cerno finding view showing NetExec Context panel with discovered credentials](img/cerno-nxc-credentials-panel.png){ width="70%" }
///caption
NetExec Context with Credentials
///

The panel shows:

- **Credentials**: Domain\username pairs discovered during your NetExec scans, including credential type and admin status
- **Shares**: SMB shares with read/write access indicators
- **Security Flags**: Highlights like "SMB signing disabled" that confirm vulnerabilities

Press **`[N]`** to view the per-host breakdown, which shows exactly which credentials have access to each affected host:

![Cerno per-host NetExec detail showing credentials table with admin status for individual hosts](img/cerno-nxc-credentials-per-host.png){ width="70%" }
///caption
Per-Host Credential Detail
///

???+ info
    Cerno reads from `~/.nxc/workspaces/default/` by default. If you're using a different NetExec workspace, you can configure the path with `cerno config set nxc_workspace_path /path/to/workspace`.

This integration lets you see at a glance which credentials from your NetExec enumeration have access to systems affected by specific vulnerabilities—helping you prioritize which findings to exploit next.