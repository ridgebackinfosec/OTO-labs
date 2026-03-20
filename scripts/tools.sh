#!/bin/bash

# Customize PS4 to include color. Here, we use cyan color.
export PS4='\e[0;36m+ \e[m'

LOG_FILE=/tmp/oto-labs-tools.log
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[$(date)] tools.sh started"

FAILURES=()
FAILURE_OUTPUTS=()
run_step() {
    local label="$1"; shift
    local tmpfile exit_code
    tmpfile=$(mktemp)
    "$@" 2>&1 | tee "$tmpfile"
    exit_code=${PIPESTATUS[0]}
    if [ $exit_code -eq 0 ]; then
        rm -f "$tmpfile"
        return 0
    else
        echo -e "\e[0;31m[FAILED] $label\e[m"
        FAILURES+=("$label")
        FAILURE_OUTPUTS+=("$(tail -10 "$tmpfile")")
        rm -f "$tmpfile"
    fi
}

# Enable echo
set -x

# This script will install all the necessary tools for the class
cd

# Required Powershell Steps from https://learn.microsoft.com/en-us/powershell/scripting/install/install-debian?view=powershell-7.4
# Download the Microsoft repository GPG keys
if [ ! -f /etc/apt/sources.list.d/microsoft-prod.list ]; then
    wget -q https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb
    # Register & remove the Microsoft repository GPG keys
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
else
    echo "Microsoft repository already configured, skipping..."
fi

# APT method
run_step "apt update" sudo apt update
run_step "apt: pipx" sudo apt install -y pipx
for pkg in metasploit-framework sqlitebrowser nmap locate python3-pip python3-venv \
           aircrack-ng burpsuite eaphammer gophish bettercap hashcat tcpdump \
           wireshark juice-shop powershell jq john; do
    run_step "apt: $pkg" sudo apt install -y "$pkg"
done
# sudo apt install kismet -y

# BloodHound GUI
# https://bloodhound.readthedocs.io/en/latest/installation/linux.html
run_step "apt: openjdk-11-jdk" sudo apt install -y openjdk-11-jdk
run_step "apt: neo4j" sudo apt install -y neo4j
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
run_step "pipx: coercer"    bash -c 'pipx install git+https://github.com/ridgebackinfosec/Coercer || pipx upgrade coercer'
run_step "pipx: kerbrute"   bash -c 'pipx install git+https://github.com/ridgebackinfosec/kerbrute || pipx upgrade kerbrute'
run_step "pipx: impacket"   bash -c 'pipx install git+https://github.com/ridgebackinfosec/impacket || pipx upgrade impacket'
run_step "pipx: netexec"    bash -c 'pipx install git+https://github.com/ridgebackinfosec/NetExec || pipx upgrade netexec'
run_step "pipx: bloodhound" bash -c 'pipx install git+https://github.com/ridgebackinfosec/BloodHound.py || pipx upgrade bloodhound'
run_step "pipx: certipy"    bash -c 'pipx install git+https://github.com/ridgebackinfosec/Certipy || pipx upgrade certipy-ad'
run_step "pipx: o365spray"  bash -c 'pipx install git+https://github.com/ridgebackinfosec/o365spray || pipx upgrade o365spray'
run_step "pipx: auxiliary"  bash -c 'pipx install git+https://github.com/ridgebackinfosec/auxiliary || pipx upgrade auxiliary'
run_step "pipx: cerno"      bash -c 'pipx install git+https://github.com/ridgebackinfosec/cerno || pipx upgrade cerno'
run_step "pipx: ad-miner"   bash -c 'pipx install git+https://github.com/ridgebackinfosec/AD_Miner || pipx upgrade ad-miner'
# sudo pipx install mitm6

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

# fireprox
if [ ! -d "$HOME/git-tools/fireprox" ]; then
    run_step "git: fireprox" bash -c '
        git clone https://github.com/ridgebackinfosec/fireprox ~/git-tools/fireprox &&
        cd ~/git-tools/fireprox &&
        python3 -m venv venv &&
        source venv/bin/activate &&
        pip install -r requirements.txt &&
        deactivate
    '
else
    echo "fireprox already cloned, skipping..."
fi
cd

# jwt_tool
if [ ! -d "$HOME/git-tools/jwt_tool" ]; then
    run_step "git: jwt_tool" bash -c '
        git clone https://github.com/ridgebackinfosec/jwt_tool ~/git-tools/jwt_tool &&
        cd ~/git-tools/jwt_tool &&
        python3 -m venv venv &&
        source venv/bin/activate &&
        pip install termcolor cprint pycryptodomex requests &&
        deactivate
    '
else
    echo "jwt_tool already cloned, skipping..."
fi
cd

# PetitPotam
if [ ! -d "$HOME/git-tools/PetitPotam" ]; then
    run_step "git: PetitPotam" bash -c 'git clone https://github.com/ridgebackinfosec/PetitPotam ~/git-tools/PetitPotam'
else
    echo "PetitPotam already cloned, skipping..."
fi

# MailSniper
if [ ! -d "$HOME/git-tools/MailSniper" ]; then
    run_step "git: MailSniper" bash -c 'git clone https://github.com/ridgebackinfosec/MailSniper ~/git-tools/MailSniper'
else
    echo "MailSniper already cloned, skipping..."
fi

# MSOLSpray
if [ ! -d "$HOME/git-tools/MSOLSpray" ]; then
    run_step "git: MSOLSpray" bash -c 'git clone https://github.com/ridgebackinfosec/MSOLSpray ~/git-tools/MSOLSpray'
else
    echo "MSOLSpray already cloned, skipping..."
fi

# MFASweep
if [ ! -d "$HOME/git-tools/MFASweep" ]; then
    run_step "git: MFASweep" bash -c 'git clone https://github.com/ridgebackinfosec/MFASweep ~/git-tools/MFASweep'
else
    echo "MFASweep already cloned, skipping..."
fi

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

# CredMaster
if [ ! -d "$HOME/git-tools/CredMaster" ]; then
    run_step "git: CredMaster" bash -c '
        git clone https://github.com/ridgebackinfosec/CredMaster ~/git-tools/CredMaster &&
        cd ~/git-tools/CredMaster &&
        python3 -m venv venv &&
        source venv/bin/activate &&
        pip install -r requirements.txt &&
        deactivate
    '
else
    echo "CredMaster already cloned, skipping..."
fi
cd

# FindMeAccess
if [ ! -d "$HOME/git-tools/FindMeAccess" ]; then
    run_step "git: FindMeAccess" bash -c '
        git clone https://github.com/ridgebackinfosec/FindMeAccess ~/git-tools/FindMeAccess &&
        cd ~/git-tools/FindMeAccess &&
        python3 -m venv venv &&
        source venv/bin/activate &&
        pip install -r requirements.txt &&
        deactivate
    '
else
    echo "FindMeAccess already cloned, skipping..."
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

set +x

echo ""
echo "=================================================="
if [ ${#FAILURES[@]} -eq 0 ]; then
    echo -e "\e[0;32m[tools.sh] All steps completed successfully.\e[m"
else
    echo -e "\e[0;31m[tools.sh] ${#FAILURES[@]} step(s) failed:\e[m"
    for i in "${!FAILURES[@]}"; do
        echo -e "  \e[0;31m- ${FAILURES[$i]}\e[m"
        if [ -n "${FAILURE_OUTPUTS[$i]:-}" ]; then
            echo "${FAILURE_OUTPUTS[$i]}" | sed 's/^/    /'
        fi
    done
    echo ""
    echo "Full output: $LOG_FILE"
fi
echo "=================================================="
echo "[$(date)] tools.sh finished"

exit ${#FAILURES[@]}
