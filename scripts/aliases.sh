# aliases.sh — course convenience aliases, sourced by ~/.bashrc via setup.sh.
# Each alias auto-detects the *-labs repo in $HOME, or accepts a course name arg
# (e.g., `run-labs OTO`). Do not execute this file directly; source it.

# GOAD lab target IP range (used in nmap and other lab commands as $GOAD)
export GOAD="192.168.56.10-25"

# Show local IP addresses (quick reference for The Forge's interface IPs)
alias me='ip address | grep inet'

# Activate the lab guide venv and start mkdocs serve from the *-labs repo
alias run-labs='f(){ if [ -n "$1" ]; then repo=${1^^}; d="$HOME/${repo}-labs"; else set -- "$HOME"/*-labs; [ -e "$1" ] || { echo "No *-labs repo found in $HOME"; return 1; }; [ "$#" -eq 1 ] || { echo "Multiple *-labs repos found; specify one (e.g., run-labs OTO)"; printf "%s\n" "$@"; return 1; }; d=$1; fi; [ -f "$d/venv/bin/activate" ] || { echo "No venv in $d (run setup.sh first)"; return 1; }; cd "$d" || return 1; . venv/bin/activate; trap "deactivate; cd - >/dev/null" EXIT; mkdocs serve; }; f'

# Run lab_essential_tools.sh from the *-labs repo (required class tools)
alias get-tools='f(){ if [ -n "$1" ]; then repo=${1^^}; d="$HOME/${repo}-labs"; else set -- "$HOME"/*-labs; [ -e "$1" ] || { echo "No *-labs repo found in $HOME"; return 1; }; [ "$#" -eq 1 ] || { echo "Multiple *-labs repos found; specify one (e.g., get-tools OTO)"; printf "%s\n" "$@"; return 1; }; d=$1; fi; if [ -f "$d/scripts/lab_essential_tools.sh" ]; then s="$d/scripts/lab_essential_tools.sh"; else echo "Missing lab_essential_tools.sh in $d (checked scripts/lab_essential_tools.sh)"; return 1; fi; [ -x "$s" ] || chmod 744 "$s"; ( cd "$(dirname "$s")" && ./"$(basename "$s")" ); }; f'

# Run extra_tools.sh from the *-labs repo (optional tools, not required for class)
alias get-extra-tools='f(){ if [ -n "$1" ]; then repo=${1^^}; d="$HOME/${repo}-labs"; else set -- "$HOME"/*-labs; [ -e "$1" ] || { echo "No *-labs repo found in $HOME"; return 1; }; [ "$#" -eq 1 ] || { echo "Multiple *-labs repos found; specify one (e.g., get-extra-tools OTO)"; printf "%s\n" "$@"; return 1; }; d=$1; fi; if [ -f "$d/scripts/extra_tools.sh" ]; then s="$d/scripts/extra_tools.sh"; else echo "Missing extra_tools.sh in $d (checked scripts/extra_tools.sh)"; return 1; fi; [ -x "$s" ] || chmod 744 "$s"; ( cd "$(dirname "$s")" && ./"$(basename "$s")" ); }; f'
