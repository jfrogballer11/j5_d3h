#!/usr/bin/env bash
# Turn a Linux machine (Raspberry Pi, laptop, mini PC) into a Wi-Fi hotspot
# that shares its existing internet connection (Ethernet, USB modem, phone tether).
#
# Usage:
#   sudo ./hotspot.sh start [SSID] [PASSWORD] [WIFI_IFACE]
#   sudo ./hotspot.sh stop
#   sudo ./hotspot.sh status
#   ./hotspot.sh clients
#
# Requires NetworkManager (nmcli). Default on Raspberry Pi OS Bookworm,
# Ubuntu, Fedora, Debian desktop, etc.
set -euo pipefail

CON_NAME="j5-hotspot"
DEFAULT_SSID="J5-Hotspot"
BAND="${BAND:-bg}"        # bg = 2.4 GHz (best range/compat), a = 5 GHz (faster)
CHANNEL="${CHANNEL:-6}"   # use 36 or 44 when BAND=a

die() { echo "Error: $*" >&2; exit 1; }

need_root() { [[ $EUID -eq 0 ]] || die "run with sudo"; }

need_nmcli() {
  command -v nmcli >/dev/null || die "nmcli not found. Install NetworkManager:
  sudo apt install network-manager && sudo systemctl enable --now NetworkManager"
  systemctl is-active --quiet NetworkManager || die "NetworkManager is not running:
  sudo systemctl enable --now NetworkManager"
}

detect_wifi() {
  nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}'
}

check_ap_support() {
  command -v iw >/dev/null || return 0
  iw list 2>/dev/null | grep -A10 "Supported interface modes" | grep -q "\* AP" \
    || die "your Wi-Fi adapter does not support AP (hotspot) mode"
}

uplink() {
  ip route show default 2>/dev/null | awk '{print $5; exit}'
}

start() {
  need_root; need_nmcli
  local ssid="${1:-$DEFAULT_SSID}"
  local pass="${2:-}"
  local iface="${3:-$(detect_wifi)}"

  [[ -n "$iface" ]] || die "no Wi-Fi interface found (nmcli device)"
  check_ap_support

  if [[ -z "$pass" ]]; then
    pass="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 12)"
    echo "No password given, generated one."
  fi
  (( ${#pass} >= 8 )) || die "password must be at least 8 characters"

  local up; up="$(uplink || true)"
  if [[ -z "$up" ]]; then
    echo "Warning: no internet uplink detected. Clients will connect but have no internet."
  elif [[ "$up" == "$iface" ]]; then
    echo "Warning: $iface is also your internet connection."
    echo "Most adapters cannot be client and hotspot at once. Use Ethernet/USB for internet,"
    echo "or add a second Wi-Fi adapter and pass it as WIFI_IFACE."
  fi

  nmcli connection delete "$CON_NAME" >/dev/null 2>&1 || true

  nmcli connection add type wifi ifname "$iface" con-name "$CON_NAME" \
    autoconnect yes ssid "$ssid" \
    802-11-wireless.mode ap \
    802-11-wireless.band "$BAND" \
    802-11-wireless.channel "$CHANNEL" \
    ipv4.method shared \
    ipv6.method ignore \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.proto rsn \
    wifi-sec.pairwise ccmp \
    wifi-sec.group ccmp \
    wifi-sec.psk "$pass" >/dev/null

  nmcli connection up "$CON_NAME" >/dev/null

  echo
  echo "Hotspot is up"
  echo "  SSID:      $ssid"
  echo "  Password:  $pass"
  echo "  Interface: $iface"
  echo "  Internet:  ${up:-none}"
  echo "  Starts on boot: yes (sudo ./hotspot.sh stop to remove)"
}

stop() {
  need_root; need_nmcli
  nmcli connection down "$CON_NAME" >/dev/null 2>&1 || true
  nmcli connection delete "$CON_NAME" >/dev/null 2>&1 || true
  echo "Hotspot stopped and removed."
}

status() {
  need_nmcli
  if nmcli -t -f NAME connection show --active | grep -qx "$CON_NAME"; then
    echo "Hotspot: ON"
    nmcli -g 802-11-wireless.ssid,connection.interface-name connection show "$CON_NAME" \
      | paste -sd' ' | awk '{print "  SSID: "$1"\n  Interface: "$2}'
    echo "  Internet via: $(uplink || echo none)"
  else
    echo "Hotspot: OFF"
  fi
}

clients() {
  local iface
  iface="$(nmcli -g connection.interface-name connection show "$CON_NAME" 2>/dev/null || detect_wifi)"
  echo "Devices connected to $iface:"
  if command -v iw >/dev/null; then
    iw dev "$iface" station dump 2>/dev/null | awk '/^Station/{print "  "$2}'
  fi
  echo "DHCP leases:"
  cat /var/lib/NetworkManager/dnsmasq-"$iface".leases 2>/dev/null \
    | awk '{print "  "$3"  "$2"  "$4}' || echo "  (none)"
}

case "${1:-}" in
  start)   shift; start "$@" ;;
  stop)    stop ;;
  status)  status ;;
  clients) clients ;;
  *) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
