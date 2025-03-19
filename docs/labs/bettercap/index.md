# Lab - BETTERCAP

???+ note
    You can stop bettercap by entering `exit` in the terminal when you’re done.

## Intro

Bettercap is a powerful, flexible, and portable tool designed for network attacks and monitoring. It's suitable for various cybersecurity tasks such as network sniffing, man-in-the-middle attacks, real-time packet manipulation, network reconnaissance, and more. Bettercap is often praised for its ease of use and the wide array of features it offers.

## Walkthrough

```bash
sudo bettercap --help
```

![Help Dialog](img\Untitled.png){ width="70%" }
///caption
Help Dialog
///

### Launching Bettercap

To start Bettercap with superuser privileges, simply run:

???+ warning
    Remember your interface name might be different. Be sure to change `ens36` from the below command to match the interface you set a static IP on at the beginning of class.

```bash
sudo bettercap -iface ens36
```

This launches the Bettercap interactive session. From here, you can execute commands directly.

```bash
?
```

![Untitled](img\Untitled%201.png){ width="70%" }

When bettercap starts up it, similarly to Responder, lists out the various services it has enabled. A list of the default start up services is shown below.

![Untitled](img\Untitled%202.png){ width="70%" }
///caption
Modules
///

### Network Discovery

One of the first steps in using Bettercap is to perform network discovery. This can be done with the `net.probe` module:

```bash
net.probe on
```

![Untitled](img\Untitled%203.png){ width="70%" }
///caption
net.probe
///

This command scans the network for active hosts. Use `net.show` to list the discovered devices:

```bash
net.show
```

![Untitled](img\Untitled%204.png){ width="70%" }
///caption
net.show
///

### Sniffing Traffic

To start sniffing network traffic, you can enable the `net.sniff` module:

```bash
net.sniff on
```

![Untitled](img\Untitled%205.png){ width="70%" }
///caption
net.sniff
///

This command captures and displays network traffic passing through the host machine. It's particularly useful for capturing unencrypted data or analyzing network protocols.

### HTTP server

It's also possible from within bettercap to start up your own HTTP server on the network without ever having to leave your bettercap interface. You can start this up by simply typing the command below.

```bash
https.server on
```

![Untitled](img\Untitled%206.png){ width="70%" }
///caption
https.server
///

### Advanced Usage

#### Caplets

A "caplet" is a script or automation file used by Bettercap to execute a series of commands within the tool. Caplets allow users to automate tasks, configure Bettercap in specific ways, or sequence various attacks and monitoring activities without having to enter each command manually in the interactive console. They are written in a straightforward syntax that closely mirrors the command-line instructions you would normally input into Bettercap's interactive shell.

```bash
caplets.update
```

![Untitled](img\Untitled%207.png){ width="70%" }
///caption
caplets.update
///

The caplets will be installed at `/usr/local/share/bettercap/caplets` on your attacker VM. In another terminal window, let’s take a quick look at a module designed to help speed up host enumeration.

```bash
cat /usr/local/share/bettercap/caplets/mitm6.cap
```

![Caplet Format](img\image.png){ width="70%" }
///caption
Caplet Format
///

As you can see from the image above the caplets are just a series of Bettercap commands collected in a `.cap` file for ease of execution. 

We can also simply list all the installed capelets from within Bettercap using the below command.

```bash
caplets.show
```

![Caplet List](img\Untitled%208.png){ width="70%" }
///caption
Caplet List
///

Running a caplet is as easy as starting Bettercap normally then executing the `include [CAPLET NAME]` command like below.

```bash
include mitm6
```

After which you can run the below command to see what the caplet activated via its script.

```bash
active
```

![Checking What’s Active](img\image%201.png){ width="70%" }
///caption
Checking What’s Active
///

#### Man-In-The-Middle (MITM) Attacks

Bettercap provides powerful capabilities for performing MITM attacks. The `arp.spoof` module can be used to intercept traffic between devices on the network:

```bash
set arp.spoof.targets [target IP address(es)]
arp.spoof on
```

![Untitled](img\Untitled%209.png){ width="70%" }

Specify the target(s) you want to intercept traffic from. This command tricks the target devices into sending their traffic through your machine, allowing you to capture and manipulate it.

#### Capturing HTTPS Traffic

???+ warning
    This requires some additional setup, including configuring Bettercap to use a self-signed SSL certificate and ensuring the target device trusts this certificate. 

    This is included for informational purposes and **may not be possible in the Lab**.

Bettercap can also capture HTTPS traffic by using the `https.proxy.sslstrip` module, which exploits HSTS (HTTP Strict Transport Security) to perform SSL stripping attacks:

```bash
set https.proxy.sslstrip true
https.proxy on
```

![Untitled](img\Untitled%2010.png){ width="70%" }

```bash
include hstshijack/hstshijack
```

![Untitled](img\Untitled%2011.png){ width="70%" }