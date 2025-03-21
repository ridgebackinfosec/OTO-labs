# Lab - NETEXEC

???+ warning "Setup" 
    You will need at least the `GOAD-SRV02` (`192.168.56.22`) target VM and The Forge VM up and running for this Lab.

## Intro

NetExec (formerly CrackMapExec) is a toolkit that consolidates and simplifies the use of post-exploitation tools such as Mimikatz and includes modules for discovering weaknesses in databases and file shares.

The results of SMB relay often land us SAM tables and credential material. The NTLM hashes that dump on successful remote authentication through relay can be used with lots of tools, one of which is described below.

## Walkthrough

```bash
netexec --help
```

![First time use](img\Untitled.png){ width="70%" }
///caption
First time use
///

![Help Dialog](img\Untitled%201.png){ width="70%" }
///caption
Help Dialog
///

### SMB Protocol

With the SMB (Server Message Block) protocol, and the **`--help`** flag is asking for the help or usage information about the SMB module of NetExec.

```bash
netexec smb --help
```

![SMB module specific dialog](img\Untitled%202.png){ width="70%" }
///caption
SMB module specific dialog
///

### SMB Scanning & Targeting

Let’s do some SMB scanning! Run the command below. First, with Nmap.

We can check which of our targets have SMB signing both enabled AND required by running the below nmap command.

```bash
sudo nmap -Pn -sV --script=smb2-security-mode 192.168.56.11,22
```

![Nmap Results](img\image.png){ width="70%" }
///caption
Nmap Results
///

It looks like 192.168.56.11 has SMB signing enabled AND required, but 192.168.56.22 has SMB signing enabled but NOT required. This will matter for our relay attacks later in class.

We can also use the below NetExec command to accomplish the same check that Nmap just did but with much less noise in the output.

```bash
netexec smb 192.168.56.10-23
```

- **`smb`**: Specifies that the SMB module of CrackMapExec is to be used. This module focuses on actions and enumeration tasks that can be performed over the SMB protocol.
- **`192.168.56.10-23`**: This defines the target range for the command. It tells CME to operate on a range of IP addresses starting from 192.168.56.10 through 192.168.56.23. The tool will attempt to connect to each IP address in this range and perform its SMB protocol-based operations.

![SMB Signing is not required](img\Untitled%203.png){ width="70%" }
///caption
SMB Signing is not required
///

???+ note
    This lack of SMB Signing on `192.168.56.22` is what makes it possible for us to relay hashes with ntlmrelayx later on.

    There's a good BHIS blog post on this very topic [here](https://www.blackhillsinfosec.com/an-smb-relay-race-how-to-exploit-llmnr-and-smb-message-signing-for-fun-and-profit/).

Additional options and flags can be added to the command to specify credentials (if known), perform more specific enumeration tasks, or execute certain actions on the target hosts. Examples of such options include:

- **`u`** or **`-user`**: Specify a username for authentication.
- **`p`** or **`-pass`**: Specify a password or NTLM hash for authentication.
- **`-shares`**: Enumerate SMB shares.
- **`-rid-brute`**: Perform RID (Relative Identifier) brute force to enumerate users.

You may have asked yourself then “what if I have a LOT of in-scope systems”. I *need* automation to identify which systems have SMB signing required!! Well you’re in luck, NetExec can use `--gen-relay-list` to automatically build a file listing all systems that don’t have SMB signing required. 

???+ warning
    The output from the below command will be used in another Lab. So be sure to run this!

```bash
netexec smb 192.168.56.10-23 --gen-relay-list ~/smb_relay.txt
```

## More to find without needing creds…

### Users

In some cases, it’s possible to list out the users of a system via SMB. Let’s try it out with the below command.

```bash
netexec smb 192.168.56.10-23 --users
```

**`--users`**: This flag is attempting to list or retrieve information about domain users on the target systems or SMB shares. If a user is specified, then only its information is queried.

![User Enumeration](img\image%201.png){ width="70%" }
///caption
User Enumeration
///

???+ warning
    Note how all the users printed out in the above image are from `192.168.56.11` (GOAD-DC02). So, you will need that VM running to get results from this command.

### Password Policy

Next, let’s obtain the password policy of users on these systems?

???+ warning
    This will also require you to have `192.168.56.11` (GOAD-DC02) running to get results.

```bash
netexec smb 192.168.56.10-23 --pass-pol
```

Why do you think getting this policy would be useful?

Well, it can really save time during password cracking if we can eliminate passwords from our list that don’t meet the requirements. And efficiency matters *greatly* when you’re trying to crack password hashes.

It can also be beneficial to learn the lockout policy of a target so you can properly throttle any password attacks to not inadvertently lockout accounts during an engagement.

![Password Policy](img\image%202.png){ width="70%" }
///caption
Password Policy
///

The image above shows a minimum length requirement of only 5 characters, which isn’t awesome. Human beings tend to not get overly complex or lengthy with their passwords unless forced to be.

We also see that the account lockout duration is minimal. Only 5 minutes. So, if we do accidently lock an account the impact would be minimal. The threshold is set to 5 incorrect guess, which allows us a handful of attempts before hitting that lockout duration timer.