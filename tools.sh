#!/bin/bash

# Customize PS4 to include color. Here, we use cyan color.
export PS4='\e[0;36m+ \e[m'

# Enable echo
set -x

# This script will install all the necessary tools for the class
cd

# Required Powershell Steps from https://learn.microsoft.com/en-us/powershell/scripting/install/install-debian?view=powershell-7.4
# Download the Microsoft repository GPG keys
if [ ! -f /etc/apt/sources.list.d/microsoft-prod.list ]; then
    wget -q https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb
    # Register & remove the Microsoft repository GPG keys
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
else
    echo "Microsoft repository already configured, skipping..."
fi

# APT method
sudo apt update
sudo apt install pipx -y
sudo apt install metasploit-framework sqlitebrowser nmap locate python3-pip python3-venv aircrack-ng burpsuite eaphammer gophish bettercap hashcat tcpdump wireshark juice-shop powershell jq john -y
# sudo apt install kismet -y

# BloodHound GUI
# https://bloodhound.readthedocs.io/en/latest/installation/linux.html
sudo apt install openjdk-11-jdk neo4j -y
cd
if [ ! -d "$HOME/BloodHound-linux-x64" ]; then
    wget https://github.com/SpecterOps/BloodHound-Legacy/releases/download/v4.3.1/BloodHound-linux-x64.zip
    unzip BloodHound-linux-x64.zip -d .
    rm BloodHound-linux-x64.zip
else
    echo "BloodHound already installed, skipping..."
fi

# pipx method
pipx install git+https://github.com/ridgebackinfosec/Coercer || pipx upgrade git+https://github.com/ridgebackinfosec/Coercer
pipx install git+https://github.com/ridgebackinfosec/kerbrute || pipx upgrade git+https://github.com/ridgebackinfosec/kerbrute
pipx install git+https://github.com/ridgebackinfosec/impacket || pipx upgrade git+https://github.com/ridgebackinfosec/impacket
pipx install git+https://github.com/ridgebackinfosec/NetExec || pipx upgrade git+https://github.com/ridgebackinfosec/NetExec
pipx install git+https://github.com/ridgebackinfosec/BloodHound.py || pipx upgrade bloodhound
pipx install git+https://github.com/ridgebackinfosec/Certipy || pipx upgrade git+https://github.com/ridgebackinfosec/Certipy
pipx install git+https://github.com/ridgebackinfosec/o365spray || pipx upgrade git+https://github.com/ridgebackinfosec/o365spray
pipx install git+https://github.com/ridgebackinfosec/auxiliary || pipx upgrade git+https://github.com/ridgebackinfosec/auxiliary
pipx install git+https://github.com/ridgebackinfosec/cerno || pipx upgrade git+https://github.com/ridgebackinfosec/cerno
pipx install git+https://github.com/ridgebackinfosec/AD_Miner || pipx upgrade git+https://github.com/ridgebackinfosec/AD_Miner
# sudo pipx install mitm6

pipx ensurepath
sudo pipx ensurepath

# GitHub method
mkdir -p ~/git-tools

# Responder
if [ ! -d "$HOME/git-tools/Responder" ]; then
    git clone https://github.com/ridgebackinfosec/Responder ~/git-tools/Responder 
    cd ~/git-tools/Responder 
    python3 -m venv venv
    source venv/bin/activate
    sudo -E -H $VIRTUAL_ENV/bin/pip install --upgrade pip
    sudo -E -H $VIRTUAL_ENV/bin/python -m pip install -r requirements.txt
    deactivate
    cd
else
    echo "Responder already cloned, skipping..."
fi

# fireprox
if [ ! -d "$HOME/git-tools/fireprox" ]; then
    git clone https://github.com/ridgebackinfosec/fireprox ~/git-tools/fireprox
    cd ~/git-tools/fireprox
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    deactivate
    cd
else
    echo "fireprox already cloned, skipping..."
fi

# jwt_tool
if [ ! -d "$HOME/git-tools/jwt_tool" ]; then
    git clone https://github.com/ridgebackinfosec/jwt_tool ~/git-tools/jwt_tool
    cd ~/git-tools/jwt_tool
    python3 -m venv venv
    source venv/bin/activate
    pip install termcolor cprint pycryptodomex requests
    deactivate
    cd
else
    echo "jwt_tool already cloned, skipping..."
fi

# PetitPotam
if [ ! -d "$HOME/git-tools/PetitPotam" ]; then
    git clone https://github.com/ridgebackinfosec/PetitPotam ~/git-tools/PetitPotam
else
    echo "PetitPotam already cloned, skipping..."
fi

# MailSniper
if [ ! -d "$HOME/git-tools/MailSniper" ]; then
    git clone https://github.com/ridgebackinfosec/MailSniper ~/git-tools/MailSniper
else
    echo "MailSniper already cloned, skipping..."
fi

# MSOLSpray
if [ ! -d "$HOME/git-tools/MSOLSpray" ]; then
    git clone https://github.com/ridgebackinfosec/MSOLSpray ~/git-tools/MSOLSpray
else
    echo "MSOLSpray already cloned, skipping..."
fi

# MFASweep
if [ ! -d "$HOME/git-tools/MFASweep" ]; then
    git clone https://github.com/ridgebackinfosec/MFASweep ~/git-tools/MFASweep
else
    echo "MFASweep already cloned, skipping..."
fi

# Nuclei
if [ ! -f "/usr/local/bin/nuclei" ]; then
    git clone https://github.com/ridgebackinfosec/nuclei.git ~/git-tools/nuclei
    cd ~/git-tools/nuclei/cmd/nuclei
    go build
    sudo mv nuclei /usr/local/bin/
    nuclei -version
    nuclei -tl
    cd
else
    echo "Nuclei already installed, skipping..."
fi

# CredMaster
if [ ! -d "$HOME/git-tools/CredMaster" ]; then
    git clone https://github.com/ridgebackinfosec/CredMaster ~/git-tools/CredMaster
    cd ~/git-tools/CredMaster
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    deactivate
    cd
else
    echo "CredMaster already cloned, skipping..."
fi

# FindMeAccess
if [ ! -d "$HOME/git-tools/FindMeAccess" ]; then
    git clone https://github.com/ridgebackinfosec/FindMeAccess ~/git-tools/FindMeAccess
    cd ~/git-tools/FindMeAccess
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    deactivate
    cd
else
    echo "FindMeAccess already cloned, skipping..."
fi

# PlumHound
if [ ! -d "$HOME/git-tools/PlumHound" ]; then
    git clone https://github.com/ridgebackinfosec/PlumHound ~/git-tools/PlumHound
    cd ~/git-tools/PlumHound
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    deactivate
    cd
else
    echo "PlumHound already cloned, skipping..."
fi

# Updated hosts for the GOAD target env
if ! grep -q "kingslanding.sevenkingdoms.local" /etc/hosts; then
    sudo bash -c 'echo -e "\
192.168.56.10   kingslanding.sevenkingdoms.local\n\
192.168.56.11   winterfell.north.sevenkingdoms.local\n\
192.168.56.22   castelblack.north.sevenkingdoms.local\n\
192.168.56.12   meereen.essos.local\n\
192.168.56.23   braavos.essos.local" >> /etc/hosts'
else
    echo "GOAD hosts already configured, skipping..."
fi

sudo apt autoremove -y
sudo updatedb

source .bashrc

# Disable echo
set +x