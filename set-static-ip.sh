#!/usr/bin/env bash
# ParrotOS Static IP Auto-Configurator (Host-only NIC) — NetworkManager edition
# ---------------------------------------------------------------------------
# Primary path: manage the host-only NIC via NetworkManager with a manual IPv4.
# Also writes an ifupdown block to /etc/network/interfaces for parity with docs.

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
  --revert               Remove the managed static-IP block & NM profile; restart as needed.
  --no-restart           Do not restart networking services; only write changes.
  -h, --help             Show this help and exit.
EOF
}

require_root() {
  if [[ $EUID -ne 0 ]]; then
    err "Please run as root (use sudo)."
    exit 1
  fi
}

backup_interfaces() {
  local ts; ts=$(date +%F-%H%M%S)
  cp -a "${INTERFACES_FILE}" "${INTERFACES_FILE}.bak.${ts}"
  ok "Backup saved to ${INTERFACES_FILE}.bak.${ts}"
}

remove_managed_block() {
  local tmp; tmp=$(mktemp)
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

validate_ip() {
  local iface="$1" addr="$2"
  info "Verifying ${iface} has ${addr} assigned..."
  if ip -4 addr show dev "${iface}" | grep -q "${addr}/"; then
    ok "${iface} is configured with ${addr}"
  else
    err "${iface} does not show ${addr} yet."
    echo "    You can try: nmcli con up OTO-HostOnly-${iface}"
    echo "    Or reboot with: sudo reboot"
    return 1
  fi
}

is_candidate_iface() {
  local iface="$1"
  [[ "${iface}" == "lo" ]] && return 1
  if ! ip -4 addr show dev "${iface}" | grep -q "inet "; then
    echo true; return 0
  fi
  echo false; return 1
}

auto_detect_iface() {
  local i
  for i in $(ls -1 /sys/class/net); do
    [[ "${i}" == "lo" ]] && continue
    if [[ $(is_candidate_iface "${i}") == true ]]; then
      echo "${i}"; return 0
    fi
  done
  return 1
}

nm_available() { command -v nmcli >/dev/null 2>&1; }
nm_profile_exists() { nmcli -t -f NAME con show | grep -qx "OTO-HostOnly-$1"; }
nm_active_on_iface_other() {
  nmcli -t -f NAME,DEVICE,STATE con show --active \
    | awk -F: -v ifc="$1" -v our="OTO-HostOnly-$1" '$2==ifc && $1!=our{print $1}'
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

# Interface selection
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

[[ -n "${_mask}" ]] || _mask="${DEFAULT_MASK}"

if ${_detect_only}; then
  echo "${_iface}"; exit 0
fi

# Sanity
if ! ip link show "${_iface}" >/dev/null 2>&1; then
  err "Interface ${_iface} does not exist."; exit 1
fi

# Revert mode: remove ifupdown block and NM profile
if ${_revert}; then
  info "Reverting configuration for ${_iface}..."
  backup_interfaces
  remove_managed_block "${_iface}"
  if nm_available; then
    if nm_profile_exists "${_iface}"; then
      info "Deleting NM profile OTO-HostOnly-${_iface}..."
      nmcli con delete "OTO-HostOnly-${_iface}" >/dev/null 2>&1 || true
    fi
    # Try to bring up any previous connection on iface (best effort)
    prev=$(nmcli -t -f NAME,DEVICE con show | awk -F: -v ifc="${_iface}" '$2==ifc{print $1; exit}')
    if [[ -n "${prev:-}" ]]; then
      nmcli con up "${prev}" >/dev/null 2>&1 || true
    fi
  fi
  restart_networking
  ok "Reverted configuration for ${_iface}"
  exit 0
fi

# Always update /etc/network/interfaces (harmless if NM manages the device)
backup_interfaces
remove_managed_block "${_iface}"
append_managed_block "${_iface}" "${_addr}" "${_mask}"
ok "Wrote static configuration for ${_iface}: ${_addr} / ${_mask}"

# -------- NetworkManager path (Option A) --------
if nm_available; then
  info "Configuring NetworkManager profile for ${_iface}..."

  # Map common netmasks to CIDR
  case "${_mask}" in
    255.255.255.0)   _prefix=24 ;;
    255.255.0.0)     _prefix=16 ;;
    255.0.0.0)       _prefix=8  ;;
    255.255.255.128) _prefix=25 ;;
    255.255.255.192) _prefix=26 ;;
    255.255.255.224) _prefix=27 ;;
    255.255.255.240) _prefix=28 ;;
    255.255.255.248) _prefix=29 ;;
    255.255.255.252) _prefix=30 ;;
    *) # Fallback calculator (very basic)
       mask_to_prefix() { local m=$1; IFS=. read -r a b c d <<<"$m";
         printf "%d\n" "$(( ((a==255)*8 + (b==255)*8 + (c==255)*8 + (d==255)*8) ))"; }
       _prefix="$(mask_to_prefix "${_mask}")" ;;
  esac

  profile="OTO-HostOnly-${_iface}"

  # Create or modify NM profile
  if nm_profile_exists "${_iface}"; then
    info "Updating existing NM profile ${profile}..."
    nmcli con mod "${profile}" \
      ipv4.method manual ipv4.addresses "${_addr}/${_prefix}" ipv4.gateway "" ipv4.dns "" \
      connection.autoconnect yes connection.interface-name "${_iface}"
  else
    info "Creating NM profile ${profile}..."
    nmcli con add type ethernet ifname "${_iface}" con-name "${profile}" \
      ipv4.method manual ipv4.addresses "${_addr}/${_prefix}" ipv4.gateway "" ipv4.dns "" \
      connection.autoconnect yes
  fi

  # Bring down any other active connection on this iface to avoid races
  while read -r other; do
    [[ -z "${other}" ]] && continue
    info "Bringing down conflicting NM connection: ${other}"
    nmcli con down "${other}" >/dev/null 2>&1 || true
  done < <(nm_active_on_iface_other "${_iface}")

  # Activate our profile
  info "Bringing up ${profile}..."
  nmcli con up "${profile}" >/dev/null 2>&1 || true

  # Validate
  if validate_ip "${_iface}" "${_addr}"; then
    ok "NetworkManager profile applied successfully."
  else
    warn "NetworkManager profile applied, but IP not visible yet."
  fi

else
  # Fallback to legacy service bounce if NM is not available
  warn "NetworkManager not found; using legacy networking restart."
  restart_networking
  validate_ip "${_iface}" "${_addr}" || true
fi

ok "Done. You can verify with: ip -4 addr show dev ${_iface} | grep inet"
