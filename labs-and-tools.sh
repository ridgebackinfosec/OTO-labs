#!/bin/bash

# Customize PS4 to include color. Here, we use cyan color.
export PS4='\e[0;36m+ \e[m'

# Enable echo
set -x

# This script will install all the necessary tools for the class
cd

# Pull down latest Lab walkthroughs
cd ~/OTO-labs
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate
cd

# Update ParrotOS package management keys
# Blog post -> https://parrotsec.org/blog/2025-01-11-parrot-gpg-keys/
# wget https://deb.parrot.sh/parrot/pool/main/p/parrot-archive-keyring/parrot-archive-keyring_2024.12_all.deb
# sudo dpkg -i parrot-archive-keyring_2024.12_all.deb

# Required Powershell Steps from https://learn.microsoft.com/en-us/powershell/scripting/install/install-debian?view=powershell-7.4
# Download the Microsoft repository GPG keys
wget -q https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb
# Register & remove the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# APT method
sudo apt update
sudo apt install pipx -y
sudo apt install nmap locate python3-pip python3-venv aircrack-ng burpsuite eaphammer gophish bettercap hashcat tcpdump wireshark juice-shop powershell seclists jq john -y
# sudo apt install kismet -y

# BloodHound GUI
# https://bloodhound.readthedocs.io/en/latest/installation/linux.html
sudo apt install openjdk-11-jdk neo4j -y
cd
wget https://github.com/SpecterOps/BloodHound-Legacy/releases/download/v4.3.1/BloodHound-linux-x64.zip
unzip BloodHound-linux-x64.zip -d .

# pipx method
pipx install git+https://github.com/ridgebackinfosec/Coercer
pipx install git+https://github.com/ridgebackinfosec/kerbrute
pipx install git+https://github.com/ridgebackinfosec/impacket
pipx install git+https://github.com/ridgebackinfosec/NetExec
pipx install git+https://github.com/ridgebackinfosec/BloodHound.py
pipx install git+https://github.com/ridgebackinfosec/Certipy
pipx install git+https://github.com/ridgebackinfosec/o365spray
# sudo pipx install mitm6

pipx ensurepath
sudo pipx ensurepath

# GitHub method
mkdir ~/git-tools

# Responder
git clone https://github.com/ridgebackinfosec/Responder ~/git-tools/Responder 
cd ~/git-tools/Responder 
python3 -m venv venv
source venv/bin/activate
sudo -E -H $VIRTUAL_ENV/bin/pip install --upgrade pip
sudo -E -H $VIRTUAL_ENV/bin/python -m pip install -r requirements.txt
deactivate
cd

# fireprox
git clone https://github.com/ridgebackinfosec/fireprox ~/git-tools/fireprox
cd ~/git-tools/fireprox
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate
cd

# jwt_tool
git clone https://github.com/ridgebackinfosec/jwt_tool ~/git-tools/jwt_tool
cd ~/git-tools/jwt_tool
python3 -m venv venv
source venv/bin/activate
pip install termcolor cprint pycryptodomex requests
deactivate
cd

# PetitPotam
git clone https://github.com/ridgebackinfosec/PetitPotam ~/git-tools/PetitPotam

# MailSniper
git clone https://github.com/ridgebackinfosec/MailSniper ~/git-tools/MailSniper

# MSOLSpray
git clone https://github.com/ridgebackinfosec/MSOLSpray ~/git-tools/MSOLSpray

# MFASweep
git clone https://github.com/ridgebackinfosec/MFASweep ~/git-tools/MFASweep

# Nuclei
git clone https://github.com/ridgebackinfosec/nuclei.git ~/git-tools/nuclei
cd ~/git-tools/nuclei/cmd/nuclei
go build
sudo mv nuclei /usr/local/bin/
nuclei -version

# CredMaster
git clone https://github.com/ridgebackinfosec/CredMaster ~/git-tools/CredMaster
cd ~/git-tools/CredMaster
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate
cd

# FindMeAccess
git clone https://github.com/ridgebackinfosec/FindMeAccess ~/git-tools/FindMeAccess
cd ~/git-tools/FindMeAccess
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate
cd

# PlumHound
git clone https://github.com/ridgebackinfosec/PlumHound ~/git-tools/PlumHound
cd ~/git-tools/PlumHound
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
deactivate
cd

# Wifi-Forge (not ready for auto-installation yet)
# git clone https://github.com/her3ticAVI/Wifi-Forge
# cd Wifi-Forge/Framework/materials
# sudo ./setup.sh
# cd
# sudo apt install wifiphisher
# sudo apt install wifite
# sudo apt install aircrack-ng
# sudo apt install iperf
# sudo apt install bettercap
# sudo apt install john
# git clone --depth 1 https://github.com/v1s1t0r1sh3r3/airgeddon.git

# ARCHIVED
# PyMeta
# git clone https://github.com/ridgebackinfosec/pymeta ~/git-tools/pymeta
# cd ~/git-tools/pymeta
# python3 -m venv venv
# source venv/bin/activate
# pip install -r requirements.txt
# python setup.py install
# deactivate
# cd

# bl-bfg
# sudo apt install docker-compose=1.29.2-3 -y
# git clone https://github.com/cstraynor/bl-bfg ~/git-tools/bl-bfg
# mkdir ~/git-tools/bl-bfg/bfg_output
# cd

# trufflehog
# curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sudo sh -s -- -b /usr/local/bin

# Updated hosts for the GOAD target env
sudo bash -c 'echo -e "\
192.168.56.10   kingslanding.sevenkingdoms.local\n\
192.168.56.11   winterfell.north.sevenkingdoms.local\n\
192.168.56.22   castelblack.north.sevenkingdoms.local\n\
192.168.56.12   meereen.essos.local\n\
192.168.56.23   braavos.essos.local" >> /etc/hosts'

sudo apt autoremove -y
sudo updatedb

source .bashrc

# Disable echo
set +x