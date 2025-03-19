# OTO-labs
Welcome to Offensive Tooling for Operators!

## Pre-class VM Setup

You should have received the VM download link via email of Discord.

Please read through and complete the instructions below regarding supported virtualization software, extracting the VMs, and importing the VMs before class. 

Additional setup details for each VM (credentials, network config, etc.) will be covered during class.

<details>

<summary>Virtualization Software</summary>

### VMware

First, you will need to download and install VMware on your host machine. Both Workstation Pro (Windows/Linux) and Fusion Pro (Mac) are now FREE!

You can follow the guide in the below blog post’s URL to obtain installation file you need.
[https://blogs.vmware.com/workstation/2024/05/vmware-workstation-pro-now-available-free-for-personal-use.html](https://blogs.vmware.com/workstation/2024/05/vmware-workstation-pro-now-available-free-for-personal-use.html)

Be sure to select the “Personal Use” option to avoid needing a paid license.

![image](https://github.com/user-attachments/assets/047ea115-1852-4e73-9cd5-1b2b283e768f)

### Alternative: VirtualBox

You can use VirtualBox, but it fails about 25% of the time on either networking or USB support. If you hate yourself, use VirtualBox. Otherwise, use VMware.

**NOTE: We only officially support VMWare for class troubleshooting.**

</details>

<details>

<summary>Extracting the VMs</summary>

Next, you will want to extract the compressed files to a directory on your system. The exact process will change based on your system. Usually right-clicking and extracting the files with the 7-Zip tool (or your local decompression tool) you chose to install will do the trick.

### 7-Zip

7-Zip is a good option because it is the most consistent for decompressing large files. (Native unzipping utilities tend to choke on very large files.)

Below are some options:

- **7-ZiP:** [https://www.7-zip.org/download.html](https://www.7-zip.org/download.html)
- **7-Zip support for Linux:** [https://itsfoss.com/use-7zip-ubuntu-linux/](https://itsfoss.com/use-7zip-ubuntu-linux/)
- **7-Zip utility for Mac:** [https://www.keka.io/en/](https://www.keka.io/en/)

</details>

<details>

<summary>Importing the VMs</summary>

Next, we need to get the VMs loaded in VMWare.

To do that, Open VMWare and then select **File > Open (use “Import” on VMware Fusion) >** then navigate to where you downloaded the files.

![Untitled](https://github.com/user-attachments/assets/ce437693-2c66-4b86-9934-f0ece820ec01)

Give the VM a name and click **Import**.

![Untitled1](https://github.com/user-attachments/assets/40bbc892-7788-40ee-ac0b-ebfea0d961c8)

You may get a consistency error. If you do, do not worry. Just select **Retry** or **Try Again**. It should work.

</details>

## Waiting is hard

If you're looking for something to fill the time before class, here are some webcasts I've done on the BHIS YouTube channel.

The Illustrated Pentester - Short (True) Stories of Security

* Vol. 1 - https://www.youtube.com/watch?v=4v2lBK21sfs 
* Vol. 2 - https://www.youtube.com/watch?v=MASebPO6eHo
* Vol. 3 - https://www.youtube.com/watch?v=ir0R5GjrH5s

See y'all at the start of class!
