#!/bin/bash

# Customize PS4 to include color.
export PS4='\e[0;36m+ \e[m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_tools_lib.sh"

LOG_FILE=/tmp/oto-labs-lab-tools.log
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[$(date)] lab_essential_tools.sh started"

set -x

cd

# APT method
run_step "apt update" sudo apt-get -o DPkg::Lock::Timeout=300 update
run_step "apt: pipx" sudo apt install -y pipx
for pkg in python3-pip python3-venv nmap locate hashcat burpsuite eaphammer \
           bettercap gophish jq sqlitebrowser openjdk-11-jdk neo4j npm; do
    run_step "apt: $pkg" sudo apt install -y "$pkg"
done

# BloodHound GUI
# https://bloodhound.readthedocs.io/en/latest/installation/linux.html
cd
if [ ! -d "$HOME/BloodHound-linux-x64" ]; then
    run_step "BloodHound GUI download" bash -c '
        wget https://github.com/SpecterOps/BloodHound-Legacy/releases/download/v4.3.1/BloodHound-linux-x64.zip &&
        unzip BloodHound-linux-x64.zip -d . &&
        rm BloodHound-linux-x64.zip
    '
else
    echo "BloodHound already installed, skipping..."
fi

# pipx method
run_step "pipx: impacket"   bash -c 'pipx install git+https://github.com/ridgebackinfosec/impacket || pipx upgrade impacket'
run_step "pipx: netexec"    bash -c 'pipx install git+https://github.com/ridgebackinfosec/NetExec || pipx upgrade netexec'
run_step "pipx: bloodhound" bash -c 'pipx install git+https://github.com/ridgebackinfosec/BloodHound.py || pipx upgrade bloodhound'
run_step "pipx: certipy"    bash -c 'pipx install git+https://github.com/ridgebackinfosec/Certipy || pipx upgrade certipy-ad'
run_step "pipx: cerno"      bash -c 'pipx install git+https://github.com/ridgebackinfosec/cerno || pipx upgrade cerno'
run_step "pipx: ad-miner"   bash -c 'pipx install git+https://github.com/ridgebackinfosec/AD_Miner || pipx upgrade ad-miner'

pipx ensurepath
sudo pipx ensurepath

# GitHub method
mkdir -p ~/git-tools

# Responder
if [ ! -d "$HOME/git-tools/Responder" ]; then
    run_step "git: Responder" bash -c '
        git clone https://github.com/ridgebackinfosec/Responder ~/git-tools/Responder &&
        cd ~/git-tools/Responder &&
        python3 -m venv venv &&
        source venv/bin/activate &&
        sudo -E -H $VIRTUAL_ENV/bin/pip install --upgrade pip &&
        sudo -E -H $VIRTUAL_ENV/bin/python -m pip install -r requirements.txt &&
        deactivate
    '
else
    echo "Responder already cloned, skipping..."
fi
cd

# PlumHound
if [ ! -d "$HOME/git-tools/PlumHound" ]; then
    run_step "git: PlumHound" bash -c '
        git clone https://github.com/ridgebackinfosec/PlumHound ~/git-tools/PlumHound &&
        cd ~/git-tools/PlumHound &&
        python3 -m venv venv &&
        source venv/bin/activate &&
        pip install -r requirements.txt &&
        deactivate
    '
else
    echo "PlumHound already cloned, skipping..."
fi
cd

# Nuclei
if [ ! -f "/usr/local/bin/nuclei" ]; then
    run_step "git: nuclei" bash -c '
        git clone https://github.com/ridgebackinfosec/nuclei.git ~/git-tools/nuclei &&
        cd ~/git-tools/nuclei/cmd/nuclei &&
        go build &&
        sudo mv nuclei /usr/local/bin/
    '
else
    echo "Nuclei already installed, skipping..."
fi
cd

# Juice Shop
if [ ! -d "$HOME/git-tools/juice-shop" ]; then
    run_step "git: juice-shop" bash -c '
        git clone https://github.com/ridgebackinfosec/juice-shop ~/git-tools/juice-shop &&
        cd ~/git-tools/juice-shop &&
        npm install
    '
else
    echo "Juice Shop already cloned, skipping..."
fi
cd

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

tools_summary_and_exit
