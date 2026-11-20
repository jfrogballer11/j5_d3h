# Wi-Fi Hotspot

Turns a Linux machine (Raspberry Pi, old laptop, mini PC) into a Wi-Fi hotspot
that shares the internet connection the machine already has.

```
[Internet] --Ethernet / USB modem / phone tether--> [Linux box] ))) Wi-Fi ))) [your devices]
```

The hotspot sets no data cap of its own. You can use as much as your internet
source allows, so plug it into home cable or fiber for truly unlimited use.

## What you need

- A Linux machine with Wi-Fi whose adapter supports AP mode. Every Raspberry Pi 3, 4, 5 and Zero 2 W does.
- An internet source that is **not** the same Wi-Fi adapter: Ethernet, a USB cellular modem,
  a USB-tethered phone, or a second USB Wi-Fi adapter.
- NetworkManager. It's already on Raspberry Pi OS Bookworm and Ubuntu. On other systems:
  `sudo apt install network-manager && sudo systemctl enable --now NetworkManager`

## Use

```bash
cd hotspot
sudo ./hotspot.sh start "MyHotspot" "mypassword123"   # start (and auto-start on boot)
sudo ./hotspot.sh status                               # is it on?
./hotspot.sh clients                                   # who's connected
sudo ./hotspot.sh stop                                 # turn off and remove
```

If you skip the password, the script generates a random 12-character one and prints it.

### 5 GHz (faster, shorter range)

```bash
sudo BAND=a CHANNEL=36 ./hotspot.sh start "MyHotspot5G" "mypassword123"
```

## Troubleshooting

| Problem | Fix |
|---|---|
| `adapter does not support AP mode` | Use a USB Wi-Fi adapter that supports AP mode (e.g. MT7612U or RT5370 chipsets) |
| Clients connect but get no internet | Make sure the box itself is online (`ping 1.1.1.1`) over Ethernet, a modem or a tether, not over the same Wi-Fi |
| SSID doesn't show up on 5 GHz | Set your country: `sudo raspi-config` → Localisation → WLAN Country |
| Hotspot gone after reboot | Run `sudo systemctl enable NetworkManager`. The connection is saved with autoconnect |
