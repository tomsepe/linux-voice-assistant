
# AI Voice Assistant setup with Home Assistant and Pi4 wiht 7" Touchscreen

# ** AI Voice Assistant Using Pi4 with Linux Voice Assistant, ESPHome and Connect tot Home assistant OS.**

I tested this with a USB HD webcam then switched to a USB microphone
## **Raspberry Pi Setup:**
### 1. Install OS

Start with latest 64-bit Raspberry Pi OS Trixie. Use Raspberry Pi Imager to write to SD card. Configure hostname, username and password and wifi connection, burn the SD card, plug it into the pi and boot. Check your router Then SSH into the Pi:
`ssh [username]@[hostname`

Run these for initial setup:
   ```BASH
   sudo apt update && sudo apt upgrade -y
   ```

### 2. Install Github CLI "gh" (optional):

(You may need to setup your global username and email for github too)

Github has disable password login so you can create a personal access token with your account.

1. **Add GitHub's GPG key:** This ensures the packages you download are authentic.
```BASH
sudo mkdir -p -m 755 /etc/apt/keyrings
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
```

2. **Add the GitHub CLI repository to your sources list:** The `$(dpkg --print-architecture)` command automatically detects the correct architecture for your Raspberry Pi.
```BASH
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
```

3. **Update the package lists again and install `gh`:**
```BASH
sudo apt update && sudo apt install gh -y
```

4. Create a personal access token on Github.com

5. Authorize and follow on onscreen directions
```bash
gh auth login
```

---
## **2. Setup Static IP for Networking:**
```BASH
sudo nmcli device wifi list
sudo nmcli c show
sudo nmcli dev wifi connect <SSID> password <password>
```

Get the network device name, i.e  "RR_IoT" "RR_Home"

### For static IP:
```BASH
sudo nmcli connection modify "netplan-wlan0-RR_IoT" ipv4.addresses 192.168.30.100/24
sudo nmcli connection modify "netplan-wlan0-RR_IoT" ipv4.gateway 192.168.30.1
sudo nmcli connection modify "netplan-wlan0-RR_IoT" ipv4.dns 192.168.30.1
sudo nmcli connection modify "netplan-wlan0-RR_IoT" ipv4.method manual
```

### For DHCP:
```BASH
sudo nmcli connection modify "netplan-eth0" ipv4.method auto
```

ipv4.addresses Assigns the static IP you want, with the subnet mask 255.255.255.0/24
ipv4.gateway Your router’s IP address
ipv4.dns Points to the DNS server often the same as your gateway
ipv4.method manual Tells NetworkManager to use a static config instead of DHCP

### Apply the Changes:

nmcli commands modify the config, but they don't always force the network card to "reread" them immediately. You need to restart the connection.

Run this command:
```bash
sudo nmcli connection up "RR_IoT"
```


---
## **SETUP AUDIO**

Plug in USB Microphone or Camera. I recomend this as using a hat or a sound card can be kernel dependent or depend on other libraries that may or not be up to date or in sync. I had a hell of a time with the Respeaker Hat for instance. USB microphones are inexpensive and plug and play. I did eventually get the Respeaker 2mics V2 Hat working however in a different branch

### Verify Audio:

List input and output devices:
```bash
#list speakers
aplay -l

# list microphones
arecord -l
```


```
tom@pi-tinyhouse:~/linux-voice-assistant $ aplay -l
**** List of PLAYBACK Hardware Devices ****
card 0: vc4hdmi0 [vc4-hdmi-0], device 0: MAI PCM i2s-hifi-0 [MAI PCM i2s-hifi-0]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
card 1: vc4hdmi1 [vc4-hdmi-1], device 0: MAI PCM i2s-hifi-0 [MAI PCM i2s-hifi-0]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
card 2: Headphones [bcm2835 Headphones], device 0: bcm2835 Headphones [bcm2835 Headphones]
  Subdevices: 8/8
  Subdevice #0: subdevice #0
  Subdevice #1: subdevice #1
  Subdevice #2: subdevice #2
  Subdevice #3: subdevice #3
  Subdevice #4: subdevice #4
  Subdevice #5: subdevice #5
  Subdevice #6: subdevice #6
  Subdevice #7: subdevice #7
```

```
**** List of CAPTURE Hardware Devices ****
card 3: Device [USB PnP Sound Device], device 0: USB Audio [USB Audio]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
```


Since the system _sees_ the card, we just need to verify it can actually _make noise_.

**1. Check the Mixer Settings** By default, these cards often start muted (0% volume). Run `alsamixer` to unmute it before testing.

```bash
alsamixer
```

- Press **F6** and select your device
- Look for **Speaker**, **Headphone**, or **Playback**.
- Use the **Up Arrow** to raise the volume to ~80%.
- If you see "MM" at the bottom of a bar, press **M** to unmute it (it should change to "00" or green).
- Press **Esc** to exit.

1. Press **F4** to switch to the **Capture** (Microphone) tab.
2. You will likely see a bar labeled **ADC PCM** or **Capture**.
    - **Action:** Crank it to **80-90%**.
    - **Unmute:** If it says `MM`, press `M` on your keyboard.

Save your settings:
```bash
sudo alsactl store
```

**2. Test the Speaker** Run this command to play a test noise (pink noise) through card 2 (note the 2,0 is card 2 from previous aplay -l command)
```BASH
speaker-test -D plughw:2,0 -t pink -c 2
```

_(You should hear static/hissing. Press `Ctrl+C` to stop it.)_

### Troubleshooting:

The Pi 4 often disables the analog jack by default in favor of HDMI. You need to ensure it's forced "on" in your configuration.

### 2. Enable the Audio Jack

**Update `config.txt`** 
Edit your config file: `sudo nano /boot/firmware/config.txt` (or `/boot/config.txt` on older OS versions). Ensure this line is present and **not** commented out:
```
dtparam=audio=on
```

### **3. Test the Mic** Run this to do a live Mic test:

```BASH
# live mic test with volume meter
arecord -D plughw:1,0 -c 2 -r 48000 -f S16_LE -V stereo /dev/null
```

### 4. Test record and playback:

```BASH
# record using mono usb microphone dongle
arecord -D plughw:3,0 -c 1 -r 44100 -f S16_LE -t wav -V mono -v -d 5 test.wav

# Playback
aplay -D plughw:2,0 test.wav
```

**If you hear the static and your recording playback, you are 100% done with drivers.** You can proceed directly to installing the voice assistant software.


---
## Install Audioservice:

Instructions from main repo: https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/install.md
I had a lot of struggle with audio in previous attempts we're going to try pipewire this time around

It is on your own to choose the audio service you want to use.

- **a) Existing PipeWire/PulseAudio** Use if already installed
- **b) Install PipeWire (recommended):** Install PipeWire and configure. See Install Audioservice - Pipewire

# Install Audioservice

For Linux-Voice-Assistant the app uses the **Pulse protocol** (PulseAudio API) to talk to the sound server. You can use either **PipeWire** (with its Pulse-compatible layer) or **PulseAudio**; the container works with both. PipeWire is recommended on Raspberry Pi OS.

## A) Pipewire (recommended):

PipeWire is a multimedia server that provides low-latency audio/video handling. Install it with the following commands:

``` sh
# Update package database
sudo apt update

# Install PipeWire and related packages
sudo apt install -y pipewire wireplumber pipewire-audio-client-libraries libspa-0.2-bluetooth pipewire-audio pipewire-pulse dfu-util
```

Link the PipeWire configuration for ALSA applications:

``` sh
sudo mv /etc/alsa/conf.d/50-pipewire.conf /etc/alsa/conf.d/50-pipewire.conf.backup
sudo ln -sf /usr/share/alsa/alsa.conf.d/50-pipewire.conf /etc/alsa/conf.d/50-pipewire.conf 
```

Allow services to run without an active user session (optional, for headless setups):

``` sh
sudo mkdir -p /var/lib/systemd/linger
sudo touch /var/lib/systemd/linger/$USER
```

💡 **Note:** Replace `$USER` with your actual username that you want to run the voice assistant.

Enable and start PipeWire so it runs after reboot (required for headless/Docker):

``` sh
systemctl --user enable pipewire pipewire-pulse wireplumber
systemctl --user start pipewire pipewire-pulse wireplumber
```

Verify the audio server socket exists (the container checks for this file; it does **not** run `pactl`, so it won't hang):

``` sh
ls -la /run/user/1000/pulse/native
# Should show a socket, e.g. srw-rw-rw- 1 tom tom 0 ... /run/user/1000/pulse/native
```

Optional: test from the host with `pactl` (install `pulseaudio-utils` if needed). If `pactl` hangs, that's a known PipeWire quirk; the container only checks that the socket file exists.

``` sh
sudo apt install -y pulseaudio-utils
XDG_RUNTIME_DIR=/run/user/1000 timeout 3 pactl -s unix:/run/user/1000/pulse/native info || true
```

### Start container after PipeWire (headless reboot)

If the container shows "Audio server socket not ready" or "Audio server socket not found" after reboot, Docker likely started before your user session. The container then mounts an empty `/run/user/1000` and never sees the real socket.

**Fix:** start the voice-assistant container only after the Pulse socket exists, using a systemd service.

1. Stop the container and prevent Docker from starting it at boot:

``` sh
cd ~/linux-voice-assistant
docker compose stop linux-voice-assistant
```

Edit `docker-compose.yml` and set the voice-assistant service to not restart on its own:

``` yaml
# Change this line for linux-voice-assistant service:
restart: "no"
```

2. Create a systemd user service that starts the container after the socket exists (replace `tom` with your username and adjust paths if needed):

``` sh
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/linux-voice-assistant.service
```

Paste (adjust paths and user if needed):

``` ini
[Unit]
Description=Start Linux Voice Assistant after PipeWire is ready
After=network-online.target
# Wait for Pulse socket to exist (PipeWire user session must be up)
ConditionPathExists=/run/user/1000/pulse/native

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker start linux-voice-assistant
ExecStop=/usr/bin/docker stop linux-voice-assistant
TimeoutStartSec=60

[Install]
WantedBy=default.target
```

3. Enable and start the user service (linger must be enabled so this runs at boot):

``` sh
loginctl enable-linger tom
systemctl --user daemon-reload
systemctl --user enable linux-voice-assistant.service
systemctl --user start linux-voice-assistant.service
```

4. On each boot, the user session starts → PipeWire creates the socket → systemd starts the container. To bring the stack up once without reboot:

``` sh
systemctl --user start pipewire pipewire-pulse wireplumber
# wait a second for socket
sleep 2
systemctl --user start linux-voice-assistant.service
```

### Allow container to use PipeWire (fix timeout)

If the container has the cookie and socket but **pactl** inside the container shows **"Connection failure: Timeout"**, PipeWire is not granting access to the container client. Add a PipeWire drop-in so the Pulse socket allows connections (e.g. from Docker).

On the **host** (replace `tom` with your username):

``` sh
mkdir -p ~/.config/pipewire/pipewire.conf.d
nano ~/.config/pipewire/pipewire.conf.d/50-container-access.conf
```

Paste (this gives unrestricted access so the container can connect):

``` ini
# Allow Pulse clients (e.g. from Docker) to connect; avoids "Connection failure: Timeout"
module.access.args = {
    access.legacy = true
}
```

Save, then restart PipeWire and the container:

``` sh
systemctl --user restart pipewire pipewire-pulse wireplumber
sleep 2
cd ~/linux-voice-assistant
docker compose up -d --force-recreate
docker logs -f linux-voice-assistant
```

If your distro already uses socket-based access and the above does not take effect, try instead a drop-in that forces unrestricted on the default socket (same path, different file content):

``` ini
module.access.args = {
    access.socket = {
        pipewire-0 = "unrestricted"
        pipewire-0-manager = "unrestricted"
    }
}
```

Then restart as above.

**If both access configs still don't fix the timeout**, use **Pulse over TCP** so the container connects to PipeWire over localhost TCP instead of the Unix socket:

1. **On the host**, make pipewire-pulse listen on TCP with unrestricted access:

``` sh
mkdir -p ~/.config/pipewire/pipewire-pulse.conf.d
nano ~/.config/pipewire/pipewire-pulse.conf.d/50-tcp-unrestricted.conf
```

Paste:

``` ini
# Listen on TCP so Docker can connect (unix socket often times out from container)
pulse.properties = {
    server.address = [
        "unix:native",
        { address = "tcp:127.0.0.1:4713"
          client.access = "unrestricted"
        }
    ]
}
```

Restart PipeWire:

``` sh
systemctl --user restart pipewire pipewire-pulse wireplumber
sleep 2
```

2. **In your `.env`**, switch the app to TCP (container uses `network_mode: host`, so 127.0.0.1 is the host):

``` ini
LVA_PULSE_SERVER="tcp:127.0.0.1:4713"
```

3. **Recreate the container** (no need to mount the Pulse cookie when using this TCP method):

``` sh
cd ~/linux-voice-assistant
docker compose up -d --force-recreate
docker logs -f linux-voice-assistant
```

You can leave `LVA_PULSE_CONFIG` and the cookie mount in place; the app will still use the cookie if present, or connect over TCP without it.

### Configure PipeWire (optional):

Create the PipeWire configuration directory:

``` sh
sudo mkdir -p "/etc/pipewire"
```

Create the file `/etc/pipewire/pipewire.conf` with the following content (minimal configuration for voice assistant use):

``` ini
# Daemon config file for PipeWire
context.properties = {
    link.max-buffers = 16
    mem.warn-mlock = true
    log.level = 3
    context.num-data-loops = 1
    core.daemon = true
    core.name = pipewire-0
    default.clock.rate = 16000
}

context.modules = [
    { name = libpipewire-module-rt
        args = {
            nice.level = -11
            rt.prio = 88
        }
        flags = [ ifexists nofail ]
    }
    { name = libpipewire-module-protocol-native }
    { name = libpipewire-module-profiler }
    { name = libpipewire-module-metadata }
    { name = libpipewire-module-spa-device-factory }
    { name = libpipewire-module-spa-node-factory }
    { name = libpipewire-module-client-node }
    { name = libpipewire-module-client-device }
    { name = libpipewire-module-portal
        flags = [ ifexists nofail ]
    }
    { name = libpipewire-module-access
        condition = [ { module.access = true } ]
    }
    { name = libpipewire-module-adapter }
    { name = libpipewire-module-link-factory }
    { name = libpipewire-module-session-manager }
]
```


## B) PulseAudio:

Make sure that you only run Pulseaudio and there is no Pipewire installed.

``` sh
sudo apt remove --purge pipewire pipewire-pulse wireplumber
sudo apt autoremove
```

Install Pulseaudio

``` sh
sudo apt install pulseaudio pulseaudio-utils dfu-util
```

Enable and start Pulseaudio

``` sh
systemctl --user enable pulseaudio
systemctl --user start pulseaudio
```

Check if Pulseaudio is running

``` sh
pulseaudio --check
pactl info
```



---
## A) Docker Compose (recommended):

[](https://github.com/tomsepe/linux-voice-assistant/blob/pi4-trixie/docs/install_application.md#a-docker-compose-recommended)

Install packages:

```shell
sudo apt-get install -y ca-certificates curl wget gnupg lsb-release git jq vim
```

Download and add Docker's official GPG key:

```shell
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

Set up the Docker repository:

```BASH
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Install Docker and Docker Compose:

```shell
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

**Option 1 – Clone the full repo (recommended for PipeWire):** Builds the image from source so the container uses a **socket check** instead of `pactl`, avoiding hangs with PipeWire.

```shell
git clone https://github.com/OHF-Voice/linux-voice-assistant.git
cd linux-voice-assistant
cp .env.example .env
# Edit .env (LVA_USER_ID, LVA_PULSE_SERVER, LVA_XDG_RUNTIME_DIR, WAKE_MODEL, etc.)
docker compose build --no-cache linux-voice-assistant
docker compose up -d
```

**Option 2 – Download only compose and env:** Uses the prebuilt image (container runs `pactl` in the entrypoint; can hang with PipeWire until the socket is ready).

```shell
mkdir linux-voice-assistant
cd linux-voice-assistant
wget https://raw.githubusercontent.com/OHF-Voice/linux-voice-assistant/refs/tags/v1.0.0/docker-compose.yml
wget https://raw.githubusercontent.com/OHF-Voice/linux-voice-assistant/refs/tags/v1.0.0/.env.example
cp .env.example .env
# If you use the repo's docker-compose.yml with build: ., run: docker compose build --no-cache linux-voice-assistant
docker compose up -d
```

💡 **Note:** Use the latest stable version of the files from the repository. We update this documentation only regularly.

| Tag        | Description                   | Example                                             |
| ---------- | ----------------------------- | --------------------------------------------------- |
| `latest`   | Latest stable release         | `ghcr.io/ohf-voice/linux-voice-assistant:latest`    |
| `nightly`  | Latest development build      | `ghcr.io/ohf-voice/linux-voice-assistant:nightly`   |
| `x.y.z`    | Specific version release      | `ghcr.io/ohf-voice/linux-voice-assistant:1.0.0`     |
| `x.y`      | Major.Minor with auto updates | `ghcr.io/ohf-voice/linux-voice-assistant:1.0`       |
| `<branch>` | Branch-specific build         | `ghcr.io/ohf-voice/linux-voice-assistant:my-branch` |

Edit the .env file and change the values to your needs:

```shell
nano .env
```

```ini
# Linux-Voice-Assistant - Docker Environment Configuration
# Copy this file to .env and customize for your setup by 'cp .env.example .env'

### Enable debug mode (optional):
# ENABLE_DEBUG="1"

### List audio devices (optional):
# if enabled normal startup is disabled
# LIST_DEVICES="1"

### User ID:
# This is used to set the correct permissions for the audio device and the Pulse/PipeWire socket
LVA_USER_ID="1000"
LVA_USER_GROUP="1000"

### Name for the client (optional):
# by default it uses the HOSTNAME variable from the piCompose environment which includes the MAC from the network card
# CLIENT_NAME="My Voice Assistant Speaker"

### Audio server socket (Pulse protocol). Works with PipeWire or PulseAudio:
# PulseAudio:  unix:/run/user/1000/pulse
# PipeWire:   unix:/run/user/1000/pulse/native  (use this with pipewire-pulse)
LVA_PULSE_SERVER="unix:/run/user/${LVA_USER_ID}/pulse/native"
LVA_XDG_RUNTIME_DIR="/run/user/${LVA_USER_ID}"
# Pulse cookie (required for container auth). Replace tom with your username.
LVA_PULSE_CONFIG="/home/tom/.config/pulse"

### Path to the preferences file (optional):
# PREFERENCES_FILE="/app/configuration/preferences.json"

### Port for the api (optional):
# PORT="6053"

### Audio input device (optional):
# AUDIO_INPUT_DEVICE="default"

### Audio output device (optional):
# AUDIO_OUTPUT_DEVICE="default"

# Enable thinking sound (optional):
# ENABLE_THINKING_SOUND="1"

# Wake model (optional). Must match a wake word id (e.g. hey_jarvis, okay_nabu):
# WAKE_MODEL="hey_jarvis"

# Refactory seconds (optional):
# REFACTORY_SECONDS="2"

# Sound files (optional):
# WAKEUP_SOUND="sounds/wake_word_triggered.flac"
# TIMER_FINISHED_SOUND="sounds/timer_finished.flac"
# PROCESSING_SOUND="sounds/processing.wav"
# MUTE_SOUND="sounds/mute_switch_on.flac"
# UNMUTE_SOUND="sounds/mute_switch_off.flac"
```

You can change various settings here, for example the audio sounds which are played when the wake word is detected or when the timer is finished.


### Option 1: The Permanent Fix (Recommended)

To run Docker commands without using `sudo` every time, add your user to the `docker` group.

1. **Add your user to the group:**
```bash
sudo usermod -aG docker $USER
```

1. **Activate the changes:** You usually need to log out and log back in for this to take effect. However, you can apply the changes to your current terminal session immediately by running:

```bash
newgrp docker
```

Start the application (if you built from the repo, the image is already built):

```shell
docker compose up -d
```

If you see "Audio server socket not ready" in the logs, ensure PipeWire is running and the socket exists (`ls -la /run/user/1000/pulse/native`), or use the [Start container after PipeWire (headless reboot)](#start-container-after-pipewire-headless-reboot) steps.

If the container starts but then crashes with `AssertionError` or `PA_CONTEXT_READY` (soundcard/Pulse auth), set **LVA_PULSE_CONFIG** in `.env` to your host Pulse config dir (e.g. `/home/tom/.config/pulse`) so the container can use the cookie. Ensure that dir exists and contains `cookie` (PipeWire creates it when you first use audio).

If **pactl** from inside the container shows **"Connection failure: Timeout"** (cookie and socket are correct), PipeWire's access control is suspending the container's connection and never granting permission. Apply [Allow container to use PipeWire (fix timeout)](#allow-container-to-use-pipewire-fix-timeout) below.

💡 **Note:** If you want to use the application with a different user, change the user in the .env file and the UID. The container will restart automatically after a reboot unless you use the "Start container after PipeWire" systemd flow.


```shell
docker compose ps
```

Check the logs:

```shell
docker compose logs -f
```

Stop the service:

```shell
docker-compose down
```

Download the latest image:

```shell
docker-compose pull
```


---
## Additional Information:

### Set audio volume:

If your driver or audiodevice is loaded and you can see the device with `aplay -L` then
set the audio volume from 0 to 100:
THIS IS FOR TEH RESPEAKER DEVICE NOT THE USB MICROPHONE
```bash
export LVA_XDG_RUNTIME_DIR=/run/user/${LVA_USER_ID}
sudo amixer -c seeed2micvoicec set Headphone 100%
sudo amixer -c seeed2micvoicec set Speaker 100%
sudo amixer -c Lite set Headphone 100%
sudo amixer -c Lite set Speaker 100%
sudo alsactl store
```

Alternatively you can use the following command to set the volume:

```bash
export LVA_XDG_RUNTIME_DIR=/run/user/${LVA_USER_ID}
sudo alsamixer
```

💡 **Note:** Replace `$LVA_USER_ID` with your actual user id that you want to run the voice assistant.


---

## USE PULSEMIXER instead of ALSAMIXER
```
sudo apt install pulsemixer
```
## **9. Configure sound settings and adjust the volume with alsamixer**

`alsamixer` is a terminal user interface mixer program for the Advanced Linux Sound Architecture (ALSA) that is used to configure sound settings and adjust the volume.

```
alsamixer
```

![](https://files.seeedstudio.com/wiki/MIC_HATv1.0_for_raspberrypi/img/alsamixer.png)

The Left and right arrow keys are used to select the channel or device and the Up and Down Arrows control the volume for the currently selected device. Quit the program with ALT+Q, or by hitting the Esc key. [More information](https://en.wikipedia.org/wiki/Alsamixer)


