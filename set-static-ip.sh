#!/usr/bin/env bash
# ParrotOS Static IP Auto-Configurator (Host-only NIC)
# ---------------------------------------------------
# Automates the "Static IP Address Assignment" step for The Forge (ParrotOS).
# Writes a managed block to /etc/network/interfaces to configure a host-only NIC
# with a static IPv4 and no gateway.

set -euo pipefail

DEFAULT_ADDR="192.168.56.100"
DEFAULT_MASK="255.255.255.0"
MANAGED_TAG="OTO_STATIC"
INTERFACES_FILE="/etc/network/interfaces"

_iface=""
_addr="${DEFAULT_ADDR}"
_mask="${DEFAULT_MASK}"
_detect_only=false
_revert=false
_no_restart=false

# ---------- Color helpers ----------
if [[ -t 1 ]]; then
  RED="\e[1;31m"; GREEN="\e[1;32m"; YELLOW="\e[1;33m"; CYAN="\e[1;36m"; RESET="\e[0m"
else
  RED=""; GREEN=""; YELLOW=""; CYAN=""; RESET=""
fi

ok()   { echo -e "${GREEN}✅ $*${RESET}"; }
info() { echo -e "${CYAN}➜  $*${RESET}"; }
warn() { echo -e "${YELLOW}⚠️  $*${RESET}"; }
err()  { echo -e "${RED}❌ $*${RESET}"; }

usage() {
  cat <<EOF
ParrotOS Static IP Auto-Configurator (Host-only NIC)

Options:
  --iface IFACE          Interface to configure (e.g., ens36). If omitted, auto-detects
                         the first non-loopback interface with no IPv4 address.
  --addr ADDRESS         IPv4 address to assign (default: ${DEFAULT_ADDR}).
  --mask NETMASK         Netmask to use (default: ${DEFAULT_MASK}).
  --detect-only          Only detect and print the candidate host-only interface; exit.
  --revert               Remove the managed static-IP block for IFACE and restart networking.
  --no-restart           Do not restart networking; only write changes.
  -h, --help             Show this help and exit.

Examples:
  sudo ./set-static-ip.sh                       # auto-detect IFACE, set 192.168.56.100/24
  sudo ./set-static-ip.sh --addr 192.168.56.50  # pick a different IP
  sudo ./set-static-ip.sh --iface ens36         # specify interface explicitly
  sudo ./set-static-ip.sh --revert --iface ens36
EOF
}

require_root() {
  if [[ $EUID -ne 0 ]]; then
    err "Please run as root (use sudo)."
    exit 1
  fi
}

backup_interfaces() {
  local ts
  ts=$(date +%F-%H%M%S)
  cp -a "${INTERFACES_FILE}" "${INTERFACES_FILE}.bak.${ts}"
  ok "Backup saved to ${INTERFACES_FILE}.bak.${ts}"
}

# Remove our managed block (if present) for the given interface
remove_managed_block() {
  local tmp
  tmp=$(mktemp)
  awk -v tag="${MANAGED_TAG}" -v iface="$1" '
    BEGIN {skip=0}
    {
      if ($0 ~ "# BEGIN " tag " " iface) {skip=1; next}
      if ($0 ~ "# END " tag " " iface) {skip=0; next}
      if (skip==0) print $0
    }
  ' "${INTERFACES_FILE}" >"${tmp}"
  cat "${tmp}" > "${INTERFACES_FILE}"
  rm -f "${tmp}"
}

append_managed_block() {
  local iface="$1" addr="$2" mask="$3"
  cat <<BLOCK >>"${INTERFACES_FILE}"
# BEGIN ${MANAGED_TAG} ${iface}
auto ${iface}
allow-hotplug ${iface}
iface ${iface} inet static
  address ${addr}
  netmask ${mask}
# (intentionally no gateway for host-only network)
# END ${MANAGED_TAG} ${iface}

BLOCK
}

restart_networking() {
  if ${_no_restart}; then
    warn "Skipping networking restart due to --no-restart"
    return 0
  fi
  info "Restarting networking..."
  if systemctl list-unit-files | grep -q '^networking.service'; then
    systemctl restart networking || true
  else
    service networking restart || true
  fi
}

validate_applied() {
  local iface="$1" addr="$2"
  info "Verifying ${iface} has ${addr} assigned..."
  if ip -4 addr show dev "${iface}" | grep -q "${addr}/"; then
    ok "${iface} is configured with ${addr}"
  else
    err "${iface} does not show ${addr} yet. A reboot may be required."
    echo    "    You can reboot with: sudo reboot"
  fi
}

is_candidate_iface() {
  local iface="$1"
  [[ "${iface}" == "lo" ]] && return 1
  # Consider interfaces that currently have no IPv4 address as host-only candidates
  if ! ip -4 addr show dev "${iface}" | grep -q "inet "; then
    echo true; return 0
  fi
  echo false; return 1
}

auto_detect_iface() {
  local iface
  for iface in $(ls -1 /sys/class/net); do
    [[ "${iface}" == "lo" ]] && continue
    if [[ $(is_candidate_iface "${iface}") == true ]]; then
      echo "${iface}"
      return 0
    fi
  done
  return 1
}

# --------------------
# Parse arguments
# --------------------
while (( "$#" )); do
  case "$1" in
    --iface) _iface="${2:-}"; shift 2 ;;
    --addr)  _addr="${2:-}"; shift 2 ;;
    --mask)  _mask="${2:-}"; shift 2 ;;
    --detect-only) _detect_only=true; shift ;;
    --revert) _revert=true; shift ;;
    --no-restart) _no_restart=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# --------------------
# Main logic
# --------------------
require_root

if [[ -z "${_iface}" ]]; then
  if ! _iface=$(auto_detect_iface); then
    err "Could not auto-detect a host-only interface. Please specify with --iface."
    echo "    Available interfaces:" >&2
    ls -1 /sys/class/net | grep -v '^lo$' >&2
    exit 1
  fi
  ok "Auto-detected host-only candidate interface: ${_iface}"
else
  info "Using specified interface: ${_iface}"
fi

if ${_detect_only}; then
  echo "${_iface}"
  exit 0
fi

if ${_revert}; then
  info "Reverting managed static-IP block for ${_iface}..."
  backup_interfaces
  remove_managed_block "${_iface}"
  restart_networking
  ok "Reverted configuration for ${_iface}"
  exit 0
fi

# Sanity checks
if ! ip link show "${_iface}" >/dev/null 2>&1; then
  err "Interface ${_iface} does not exist."
  exit 1
fi

# Write configuration
backup_interfaces
remove_managed_block "${_iface}"
append_managed_block "${_iface}" "${_addr}" "${_mask}"

ok "Wrote static configuration for ${_iface}: ${_addr} / ${_mask}"

restart_networking
validate_applied "${_iface}" "${_addr}"

ok "Done. You can verify with: ip -4 addr show dev ${_iface} | grep inet"
