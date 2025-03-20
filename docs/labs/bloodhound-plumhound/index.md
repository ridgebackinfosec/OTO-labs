## Running BloodHound-Python with Local DNS Resolution

`bloodhound-python` is a tool used to collect Active Directory (AD) data for analysis in BloodHound, aiding in security assessments. In some cases, DNS resolution issues may arise, particularly when using a custom `/etc/hosts` file. This write-up explains how to force `bloodhound-python` to use the local resolver and provides a breakdown of the command.

Let's start off by running the below data collection command. We make use of the `brandon.stark` user, which we have either uncovered his password or the POC has provided it as a valid domain account to start from.

```bash
bloodhound-python --zip -c All -d north.sevenkingdoms.local -u brandon.stark -p iseedeadpeople -dc winterfell.north.sevenkingdoms.local -ns 127.0.0.1
```
![Bloodhound-execution](img\image.png){ width="70%" }
///caption
BloodHound Execution
///

Each argument in the command has a specific purpose:

- **`bloodhound-python`**
This is the executable used to collect AD data.

- **`--zip`**
Compresses the output files into a `.zip` archive for easy transfer and analysis.

- **`-c All`**
Specifies which data to collect. `All` collects all available information, including: Users, Computers, Sessions, Groups, & ACLs (Access Control Lists)

- **`-d north.sevenkingdoms.local`**
Sets the target Active Directory domain (`north.sevenkingdoms.local`).

- **`-u brandon.stark`**
Specifies the username (`brandon.stark`) for authentication.

- **`-p iseedeadpeople`**
Provides the password for authentication (`iseedeadpeople`).

- **`-dc winterfell.north.sevenkingdoms.local`**
Defines the Domain Controller (DC) to query (`winterfell.north.sevenkingdoms.local`).

- **`-ns 127.0.0.1`**
Forces BloodHound to use the local system's name resolver (at `127.0.0.1`). This ensures that hostname lookups use the `/etc/hosts` file instead of external DNS.

???+ note
    By default, `bloodhound-python` uses Python’s `dns.resolver`, which may bypass `/etc/hosts`. If the DC hostname is manually mapped in `/etc/hosts`, `bloodhound-python` might fail to resolve it properly. Specifying `-ns 127.0.0.1` ensures that the system's built-in resolver is used, allowing the tool to recognize the correct IP mappings.