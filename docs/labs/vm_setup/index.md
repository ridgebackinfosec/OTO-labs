# Setup

## Virtual Machines (VMs)

???+ warning
    These VMs are BIG! The initial zip file is ~**27GB**. You will need ~**85-100GB** of free disk space once everything is imported into VMware and setup is complete.

???+ warning
    You will NOT need to be running all the VMs at one time during the class. So, don’t unless you have plenty of resources on your host machine.

**Complete the below checklist:**

- [x]  Download the VMs
- [x]  Ensure you have the supported virtualization software (VMware) on your host machine
- [x]  Extract/Unzip the VMs
- [x]  Import the VMs into VMware
- [x]  Network Configuration
    - [x]  Setup a custom (Host-only) virtual network in VMware
    - [x]  Add the above custom network to each VM’s config
- [x]  Power on VMs
    - [x]  Complete any other specific actions in the VM’s section
- [x]  Static IP Address Assignment
- [x]  Check connectivity

---

## Network Configuration

All virtual machines should be pre-configured with at least one network interface in Network Address Translation (NAT) mode. This is required for the VMs to access the internet. After downloading and importing the VMs, students should verify each VM is indeed in NAT mode. This can be done using the steps below.

You will **ALSO** need to create a new custom network for the environment to work. The steps for this are below.

### Create Custom Virtual Network Configuration

???+ warning
    This is **REQUIRED** for the target VMs to work properly. DO NOT SKIP THIS!

1. Within VMware Workstation/Fusion/Player click Edit → Virtual Network Editor →
    
    ???+ warning
        Make sure you don’t already have a VMware network config on your host machine that is setup for the 192.168.56.x subnet. If you do, this might cause collision issues.
    
    Create a new “Host-only” type virtual network that matches the image below.
    
    ![Untitled](img\Untitled%202.png){ width="50%" }
    ///caption
    Host Only Network
    ///
    
    ???+ warning
        "Host-only Networking" is called "Private to my Mac” in VMware Fusion.
    
2. Save this configuration and note the name. In the image above this would be “VMnet9”.

### VM Network Assignment

Once the VMs are imported, click “VM” → “Settings” in VMware for each of the below listed VMs

- the-forge
- GOAD-DC02
- GOAD-SRV02

Click “Add”.

![Add Virtual Hardware](img\Untitled%203.png){ width="50%" }
///caption
Add Virtual Hardware
///

Select “Network Adapter” and click “Finish”.

![Add Network Adapter](img\Untitled%204.png){ width="50%" }
///caption
Add Network Adapter
///

You should now have a new “Network Adapter 2” (or similar) for the VM. Select it and choose the “Custom: Specific virtual network” radio button. From there, use the dropdown to select the name of the Host-only virtual network you created in a previous step.

![Untitled](img\Untitled%205.png){ width="50%" }
///caption
Select Network
///

???+ warning
    Remember to go back and do this with EACH of the VMs listed at the top of this section.

???+ warning
    KEEP the original “Network Adapter” that’s set to NAT.

    So, in the end you should have two network interfaces per VM. One in NAT mode and one in Custom (Host-only) mode.

This is how it looks in Fusion…

![Untitled](img\Untitled%206.png){ width="50%" }
///caption
Fusion Add Network
///

![Fusion GUI](img\Untitled%207.png){ width="50%" }
/// caption
Fusion GUI
///

## “The Forge” VM

???+ warning
    ***Never expose The Forge to an untrusted network, always use NAT or Host-only mode!***

???+ warning
    👤 **Credentials:**
    The Forge VM is built on top of ParrotOS and will have the username `telchar` and password `ridgeback`.

This will be the primary VM and will be used as the “attacker’s” machine.

### Tool Install Script

Once imported into VMware, turn the VM on, login, open a terminal and run the below commands to install the tools for the class. 

This is intended to reduce initial download size, make it easy for students to hit the ground running, control tool versions, and permit dynamic updating of the course material.

```bash linenums="1"
cd ~
curl -sSfL https://raw.githubusercontent.com/ridgebackinfosec/OTO-labs/refs/heads/main/install-tools.sh -o ~/install-tools.sh
chmod 744 ~/install-tools.sh
./install-tools.sh
```

???+ warning
    You will be prompted for the password when running the `install-tools.sh` script.

### Static IP Address Assignment

Make sure you have set a static IP for The Forge VM.

1. **Open a terminal.**
2. **View your current interfaces and note the name of the one that does NOT have an IP address assigned.** In the image below, this will be “ens36”.
    
    ```bash
    ip a
    ```
    
    ![Network Interfaces](img\image%201.png){ width="50%" }
    /// caption
    Network Interfaces
    ///

3. **Edit the network interfaces file:**
    
    ```bash
    sudo nano /etc/network/interfaces
    ```
    
4. **Add or modify the configuration for** `[your_interface_name]` **as follows:**
    
    ???+ warning
        Your interface name may differ. Run `ip addr` on The Forge VM and look for the one that has no IPv4 address. The replace the `[your_interface_name]` with yours (i.e. - `ens36`)
        
    ```bash
    auto [your_interface_name]
    iface [your_interface_name] inet static
        address 192.168.56.100
        netmask 255.255.255.0
    ```
    
    Replace the `address` and `netmask` values with your desired configuration.
    
5. **Save and close the file.** In `nano`, you can do this by pressing `Ctrl+x`, `y`, `Enter` to save.
    
    The file should look something like this afterwards.
    
    ![Updated Interface Config File](img\image%202.png){ width="50%" }
    /// caption
    Updated Interface Config File
    ///

6. **Restart the networking service or reboot your computer to apply the changes:**
    
    ```bash
    sudo systemctl restart networking
    ```
    
    If you see any errors with the above command, you may just have to reboot to apply the changes.
    
    ```bash
    sudo reboot
    ```
    
### OWASP Juice Shop

The Forge VM will have the `juice-shop` APT package to deploy a local instance of the Open Worldwide Application Security Project (OWASP) Juice Shop for you to play with before, during, or after the class.

> “OWASP Juice Shop is probably the most modern and sophisticated insecure web application! It can be used in security trainings, awareness demos, CTFs and as a guinea pig for security tools! Juice Shop encompasses vulnerabilities from the entire OWASP Top Ten along with many other security flaws found in real-world applications!

The application contains a vast number of hacking challenges of varying difficulty where the user is supposed to exploit the underlying vulnerabilities. The hacking progress is tracked on a score board. Finding this score board is actually one of the (easy) challenges!”
~OWASP
> 

???+ warning
    The command below will start the local instance of OWASP Juice Shop on `http://127.0.0.1:42000`. 

    It will state that, in the terminal output, that it will open a browser for you. This is a LIE. It is broken in ParrotOS currently. So, you’ll need to open a browser manually and navigate to the above address. 😢

```bash
sudo juice-shop -h
```

![Starting Juice Shop](img\Untitled%208.png){ width="50%" }
/// caption
Starting Juice Shop
///

You can now access the vulnerable web app by loading [http://127.0.0.1:42000](http://127.0.0.1:42000) in your VM’s browser.

The command below will stop the local instance of OWASP Juice Shop.

```bash
sudo juice-shop-stop -h
```

![Stopping Juice Shop](img\Untitled%209.png){ width="50%" }
/// caption
Stopping Juice Shop
///

## “GOAD” VMs

???+ warning "Credentials"
    You shouldn’t *need* to login to these, but the username in `vagrant` and password is `vagrant` if you are curious or need to troubleshoot a machine.

    Game of Active Directory (GOAD) is a pentest Active Directory LAB project. The purpose of this lab is to give pentesters a vulnerable Active directory environment ready to use to practice usual attack techniques.

???+ warning
    *This lab is extremely vulnerable, do not reuse recipe to build your [Production] environment and do not deploy this environment on internet without isolation (this is a recommendation, use it as your own risk).*

    *This lab use free windows VM only (180 days). After that timeframe enter a license on each server or rebuild all the lab (may be it's time for an update ;))
    ~* [https://github.com/Orange-Cyberdefense/GOAD](https://github.com/Orange-Cyberdefense/GOAD)

The diagram below depicts three GOAD VMs (GOAD-DC01, GOAD-DC02, and GOAD-SRV02), ***but we won’t be using GOAD-DC01 in this class***. We will be targeting the other two with our tools.

![Untitled](img\Untitled%2010.png){ width="50%" }
///caption
GOAD Environment
///

## Check Connectivity

Once all of the steps above have been completed, turn on each VM, log in to The Forge, and run the below commands to verify network connectivity.

<aside>
💡 You don’t *have* to turn on *all* the VMs at once if your host machine has lower resources. You can start/stop them as necessary.

</aside>

```bash
# Verify internet access
ping -c 4 8.8.8.8

# Verify DC02
ping -c 4 192.168.56.11

# Verify SRV02
ping -c 4 192.168.56.22
```

If everything is setup correctly, you should see `0% packet loss` following each ping command.

![Successful Pings!](img\image%203.png){ width="50%" }
/// caption
Successful Pings!
///