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

---

# Windows version

`hotspot.ps1` uses Windows 10/11's built-in Mobile Hotspot, so you don't need to install anything.

1. Open `hotspot.bat` in Notepad and change `SSID` and `PASS` (the password needs 8+ characters).
2. Double-click `hotspot.bat`. It prints the network name and password.

Or run it from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\hotspot.ps1 start -Ssid "MyHotspot" -Password "mypassword123" -Band 5
powershell -ExecutionPolicy Bypass -File .\hotspot.ps1 status
powershell -ExecutionPolicy Bypass -File .\hotspot.ps1 clients
powershell -ExecutionPolicy Bypass -File .\hotspot.ps1 stop
```

If `start` fails, try `-Band 2.4` or `-Band auto`. Many Wi-Fi cards can only host
on the same band they're connected to.

---

# Downloading a PS5 game through the PC

PS5 games are big (50–150 GB), so speed and data caps matter.

## Option A: Ethernet cable from the PC (fastest, most reliable)

Use this if the PC gets its internet over Wi-Fi and has a spare Ethernet port.

1. Connect the PC's Ethernet port to the PS5's LAN port with a cable.
2. On the PC, press `Win + R`, type `ncpa.cpl` and press Enter.
3. Right-click your **Wi-Fi** adapter, open **Properties**, then the **Sharing** tab.
4. Tick **Allow other network users to connect through this computer's Internet connection**,
   pick your **Ethernet** adapter in the dropdown, and click OK.
5. On the PS5: **Settings → Network → Settings → Set Up Internet Connection → Set Up Wired LAN → Automatic**.

## Option B: Wi-Fi hotspot (this script)

1. Run `hotspot.bat` on the PC.
2. On the PS5: **Settings → Network → Settings → Set Up Internet Connection**.
   Pick your hotspot name and enter the password.
3. Run **Test Internet Connection** to confirm it works.

## Make the download go smoothly

- **Keep the PC awake.** Go to Settings → System → Power and set "Sleep" to **Never** while downloading.
- Turn off the **auto-off** setting in Settings → Network & internet → Mobile hotspot.
- **Use 5 GHz** (`-Band 5`) and keep the PS5 within a room or two of the PC.
- On the PS5, go to **Settings → System → Power Saving → Features Available in Rest Mode**
  and turn on **Stay Connected to the Internet**. Then you can put the PS5 in rest mode
  and the download keeps going.
- **Watch your data cap.** If the PC itself is on a phone hotspot or capped plan,
  one game can use it all. Check the game's size on the PlayStation Store first.

## Faster still: plug the PS5 into the router

If the PS5 is near the router, a direct Ethernet cable to the router beats both options.
You don't need the PC at all.
