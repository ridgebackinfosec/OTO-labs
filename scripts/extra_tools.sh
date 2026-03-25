#!/bin/bash

# Customize PS4 to include color.
export PS4='\e[0;36m+ \e[m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_tools_lib.sh"

LOG_FILE=/tmp/oto-labs-extra-tools.log
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[$(date)] extra_tools.sh started"

cd

# Required PowerShell steps from https://learn.microsoft.com/en-us/powershell/scripting/install/install-debian?view=powershell-7.4
if [ ! -f /etc/apt/sources.list.d/microsoft-prod.list ]; then
    wget -q https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb
else
    echo "Microsoft repository already configured, skipping..."
fi

run_step "apt update" sudo apt-get -o DPkg::Lock::Timeout=300 update
for pkg in aircrack-ng john metasploit-framework tcpdump wireshark powershell eaphammer; do
    run_step "apt: $pkg" sudo apt install -y "$pkg"
done

# pipx method
run_step "pipx: coercer"   bash -c 'pipx install git+https://github.com/ridgebackinfosec/Coercer || pipx upgrade coercer'
run_step "pipx: kerbrute"  bash -c 'pipx install git+https://github.com/ridgebackinfosec/kerbrute || pipx upgrade kerbrute'
run_step "pipx: o365spray" bash -c 'pipx install git+https://github.com/ridgebackinfosec/o365spray || pipx upgrade o365spray'
run_step "pipx: auxiliary" bash -c 'pipx install git+https://github.com/ridgebackinfosec/auxiliary || pipx upgrade auxiliary'

pipx ensurepath
sudo pipx ensurepath

# GitHub method
mkdir -p ~/git-tools

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

sudo apt autoremove -y
sudo updatedb

source .bashrc

tools_summary_and_exit
