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
pipx_install "coercer"   "https://github.com/ridgebackinfosec/Coercer"    "coercer"
pipx_install "kerbrute"  "https://github.com/ridgebackinfosec/kerbrute"   "kerbrute"
pipx_install "o365spray" "https://github.com/ridgebackinfosec/o365spray"  "o365spray"
pipx_install "auxiliary" "https://github.com/ridgebackinfosec/auxiliary"  "auxiliary"

pipx ensurepath
sudo pipx ensurepath

# GitHub method
mkdir -p ~/git-tools

# fireprox
clone_tool_venv "fireprox" "https://github.com/ridgebackinfosec/fireprox"
cd

# jwt_tool (custom: explicit pip packages, no requirements.txt)
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
    echo "  jwt_tool already cloned, skipping..."
fi
cd

clone_tool "PetitPotam" "https://github.com/ridgebackinfosec/PetitPotam"
clone_tool "MailSniper" "https://github.com/ridgebackinfosec/MailSniper"
clone_tool "MSOLSpray"  "https://github.com/ridgebackinfosec/MSOLSpray"
clone_tool "MFASweep"   "https://github.com/ridgebackinfosec/MFASweep"

clone_tool_venv "CredMaster"   "https://github.com/ridgebackinfosec/CredMaster"
clone_tool_venv "FindMeAccess" "https://github.com/ridgebackinfosec/FindMeAccess"

tools_summary_and_exit
