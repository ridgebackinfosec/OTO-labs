#!/usr/bin/env bash
# verify-lab-env.sh
# Verifies lab networking per OTO VM setup:
#   - Internet connectivity via NAT (ping 8.8.8.8)
#   - Host-only subnet presence (default 192.168.56.0/24)
#   - Forge IP on host-only subnet (default expected 192.168.56.100)
#   - Connectivity to GOAD-DC02 (192.168.56.11) and GOAD-SRV02 (192.168.56.22)

set -euo pipefail

# Defaults
SUBNET_CIDR="192.168.56.0/24"
EXPECTED_IP="192.168.56.100"
DC_IP="192.168.56.11"
SRV_IP="192.168.56.22"
INTERNET_IP="8.8.8.8"

# Colors
RED="\e[1;31m"; GREEN="\e[1;32m"; YELLOW="\e[1;33m"; RESET="\e[0m"
ok()   { echo -e "${GREEN}✅ $1${RESET}"; }
warn() { echo -e "${YELLOW}⚠️  $1${RESET}"; }
fail() { echo -e "${RED}❌ $1${RESET}"; }

FAIL=0
do_ping() { ping -c 2 -W 2 "$1" >/dev/null 2>&1; }

# --- IPv4 helpers (no external deps) ---
ip2int() { IFS=. read -r a b c d <<<"$1"; echo $(( (a<<24) + (b<<16) + (c<<8) + d )); }
mask_from_prefix() { local p=$1; echo $(( 0xFFFFFFFF << (32 - p) & 0xFFFFFFFF )); }
in_subnet() {
  local ip="$1" net="$2" prefix="$3"
  local i n m
  i=$(ip2int "$ip"); n=$(ip2int "$net"); m=$(mask_from_prefix "$prefix")
  (( (i & m) == (n & m) ))
}

NET_BASE="${SUBNET_CIDR%/*}"
NET_PREF="${SUBNET_CIDR#*/}"

echo -e "\n=== OTO Lab Environment Verification ===\n"

# 1) Internet
echo "[1/5] Checking internet..."
if do_ping "$INTERNET_IP"; then ok "Internet reachable"; else fail "No internet"; FAIL=1; fi

# 2) Find an interface with an IPv4 inside SUBNET_CIDR
echo -e "\n[2/5] Checking host-only subnet $SUBNET_CIDR..."
HOSTONLY_IFACE=""
HOSTONLY_ADDR=""

# Enumerate IPv4 addrs: "iface ip/prefix"
while IFS= read -r line; do
  iface="${line%% *}"
  cidr="${line##* }"               # x.x.x.x/yy
  ip="${cidr%/*}"
  pfx="${cidr#*/}"
  if in_subnet "$ip" "$NET_BASE" "$NET_PREF"; then
    HOSTONLY_IFACE="$iface"
    HOSTONLY_ADDR="$ip"
    break
  fi
done < <(ip -4 -o addr show | awk '{print $2" "$4}')

if [[ -n "$HOSTONLY_IFACE" && -n "$HOSTONLY_ADDR" ]]; then
  ok "Found $HOSTONLY_IFACE with $HOSTONLY_ADDR in $SUBNET_CIDR"
else
  fail "No interface found in $SUBNET_CIDR"
  FAIL=1
fi

# 3) Expected Forge IP
echo -e "\n[3/5] Validating Forge IP..."
if [[ -z "${HOSTONLY_ADDR}" ]]; then
  fail "No host-only IP detected; static IP not set"
  FAIL=1
elif [[ -n "$EXPECTED_IP" && "$HOSTONLY_ADDR" != "$EXPECTED_IP" ]]; then
  warn "Forge IP is $HOSTONLY_ADDR but expected $EXPECTED_IP"
else
  ok "Forge IP looks good ($HOSTONLY_ADDR)"
fi

# 4) DC02
echo -e "\n[4/5] Pinging DC02 ($DC_IP)..."
if do_ping "$DC_IP"; then ok "DC02 reachable"; else fail "Cannot reach $DC_IP"; FAIL=1; fi

# 5) SRV02
echo -e "\n[5/5] Pinging SRV02 ($SRV_IP)..."
if do_ping "$SRV_IP"; then ok "SRV02 reachable"; else fail "Cannot reach $SRV_IP"; FAIL=1; fi

echo
if [[ $FAIL -eq 0 ]]; then
  ok "All checks passed. Lab networking looks good."
else
  fail "One or more checks failed. Please review above and fix before class."
fi

