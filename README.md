Fixes a dual-boot audio issue
where **both the internal speakers and the headset play sound at the same time**.
## Problem
After booting from Windows, the audio codec may leave both output pins active:
| Pin  | Device              |
|------|---------------------|
| 0x17 | Internal speakers   | 
| 0x18 | Headset (combo jack)|
**pins may differ**

Linux sends audio to the analog output correctly, but the hardware routes it to
**both** destinations. Jack auto-detection does not switch speakers off.
## Solution
The fix uses `hda-verb` to disable the speaker pin and keep the headphone pin active:
- Pin 0x17 → OFF (speakers muted)
- Pin 0x18 → ON  (headset active)
## Requirements
- Linux with PipeWire (Kali / GNOME)
- `alsa-tools` package (provides `hda-verb`)
```bash
sudo apt install alsa-tools
