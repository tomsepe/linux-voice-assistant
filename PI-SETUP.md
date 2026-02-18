
# AI Voice Assistant setup with Home Assistant and Pi4 wiht 7" Touchscreen

# ** AI Voice Assistant Using Pi4 with Linux Voice Assistant, ESPHome and Connect tot Home assistant OS.**

i tested this with a USB HD webcam then switched to a USB microphone
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

Plug in USB Microphone or Camera. I recomend this as using a hat or a sound card can be kernel dependent or depend on other libraries that may or not be up to date or in sync. I had a hell of a time with the Respeaker Hat for instance. USB microphones are inexpensive and plug and play.

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

### **3. Test the Mic** Run this todo alive Mic test:

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

For Linux-Voice-Assistant a Pulseaudio connection to the soundcard is required. Since PulseAudio is not installed by default on Ubuntu 22.04 we also support Pipewire. You can choose either one (A or B) of them.

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

Check that the PulseAudio-compatible layer is up (install `pulseaudio-utils` if `pactl` is not found):

``` sh
sudo apt install -y pulseaudio-utils
XDG_RUNTIME_DIR=/run/user/1000 pactl -s unix:/run/user/1000/pulse/native info
```

### Start container after PipeWire (headless reboot)

If the container shows "PulseAudio not running" after reboot, Docker likely started before your user session. The container then mounts an empty `/run/user/1000` and never sees the real Pulse socket.

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

Download the docker-compose.yml and .env.example file from the repository to a folder on your system:

```shell
mkdir linux-voice-assistant
cd linux-voice-assistant
wget https://raw.githubusercontent.com/OHF-Voice/linux-voice-assistant/refs/tags/v1.0.0/docker-compose.yml
wget https://raw.githubusercontent.com/OHF-Voice/linux-voice-assistant/refs/tags/v1.0.0/.env.example
cp .env.example .env
```

💡 **Note:** Use the latest stable version of the files from the repository. We update this documentation only regulary.

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
# This is used to set the correct permissions for the accessing the audio device and accessing the PulseAudio socket
LVA_USER_ID="1000"
LVA_USER_GROUP="1000"

### Name for the client (optional):
# by default it uses the HOSTNAME variable from the piCompose environment which includes the MAC from the network card
# CLIENT_NAME="My Voice Assistant Speaker"

### PulseAudio socket path on the host:
# PulseAudio Server:    /run/user/1000/pulse
# Pipewire Server:      /run/user/1000/pulse/native
LVA_PULSE_SERVER="unix:/run/user/${LVA_USER_ID}/pulse/native"
LVA_XDG_RUNTIME_DIR="/run/user/${LVA_USER_ID}"

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

# Wake model (optional):
# WAKE-MODEL="okay_nabu"

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

Start the application:

```shell
docker compose up -d
```

💡 **Note:** If you want to use the application with a different user, you need to change the user in the .env file. Dont forget to change the UID from the user. The docker container will run until you stop it. It will restart autiomatically after a reboot.


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

💡 **Note:** Replace `$LVA_USER_ID` with your actual user id that you want to run the voice assistant.

Alternatively you can use the following command to set the volume:

```bash
export LVA_XDG_RUNTIME_DIR=/run/user/${LVA_USER_ID}
sudo alsamixer
```

💡 **Note:** Replace `$LVA_USER_ID` with your actual user id that you want to run the voice assistant.
---





---

### 4. Verify PulseAudio setup in container:

After restarting, test inside the container:

`docker exec -it linux-voice-assistant bash pactl list sources short pactl list sinks short`

The key difference is that with PulseAudio, you should reference **PulseAudio device names** rather than ALSA device numbers. Your current setup already has the right environment variables (`LVA_PULSE_SERVER`, `LVA_XDG_RUNTIME_DIR`) so it should work with the PulseAudio device names I suggested.

It looks like your PulseAudio server currently **only** sees the onboard audio jack (the "stereo-fallback") as a valid output. Even though ALSA sees your Seeed HAT as `card 1`, PulseAudio hasn't "claimed" it yet. This is why your manual `speaker-test` (which talks to the hardware) works, but your voice assistant (which talks to PulseAudio) is silent.

Here is the fix:

### 1. Force PulseAudio to recognize the HAT

Sometimes PulseAudio needs a nudge to load the module for a specific hardware card. Run this command on your host:

Bash

```
pactl load-module module-alsa-sink device=hw:1,0 name=seeed_out
pactl load-module module-alsa-source device=hw:1,0 name=seeed_in
```

Now, run `pactl list sinks short` again. You should see a new entry named `seeed_out`.

### 2. Update your `.env` with the new names

Once the sink appears, update your Docker configuration to use these specific names you just created:

Bash

```
### Audio input device:
AUDIO_INPUT_DEVICE="seeed_in"

### Audio output device:
AUDIO_OUTPUT_DEVICE="seeed_out"
```

Based on the control list you provided, your ReSpeaker HAT is using the **TLV320AIC3x** driver (likely a clone or a specific version of the 2-Mic Pi HAT). This chip has very specific "routing" switches that must be enabled to connect the digital audio (DAC) to the output pins.

Here are the exact commands to enable the speaker output for your specific board.

### 1. Enable the Output Path (Crucial)

You need to connect the "DAC" (Digital to Analog Converter) to the "Line Out" mixer. Run these commands on the Host:

Bash

```
# Connect the Left and Right DACs to the Line Mixer (this feeds the speaker amp)
amixer -c 1 sset 'Left Line Mixer DACL1' on
amixer -c 1 sset 'Right Line Mixer DACR1' on
```

### 2. Unmute and Turn Up the Volume

Now that the path is open, turn up the actual volume controls.

Bash

```
# Set the main PCM volume to max
amixer -c 1 sset 'PCM' 100% unmute

# Set the Line Out volume (this often controls the JST speaker connector)
amixer -c 1 sset 'Line' 100% unmute

# Set the DAC volume
amixer -c 1 sset 'Line DAC' 100% unmute
```

### 3. (Optional) Check Headphone/HP

If the speaker is wired to the "Headphone" pins instead of "Line Out" on your specific board revision, you might need these instead:

Bash

```
# Connect DAC to Headphone Mixer
amixer -c 1 sset 'Left HP Mixer DACL1' on
amixer -c 1 sset 'Right HP Mixer DACR1' on

# Turn up Headphone volume
amixer -c 1 sset 'HP' 100% unmute
amixer -c 1 sset 'HP DAC' 100% unmute
```

### 4. Test Immediately

Try playing a sound from the host first to verify the hardware path is open:

Bash

```
paplay --device=seeed_out /usr/share/sounds/alsa/Front_Center.wav
```

### The Fix: Force `ao=pulse` Globally

Run this command to create a configuration file inside the container that tells `mpv` "Always use PulseAudio, no matter what."

Bash

```
docker exec -u 0 linux-voice-assistant sh -c "mkdir -p /etc/mpv && echo 'ao=pulse' > /etc/mpv/mpv.conf"
```

_Note: I changed the path to `/root/.config/mpv/mpv.conf` because the container likely runs as root or uses the root home directory for config storage._

### Restart the Container

Now restart the container so the main application picks up this new configuration:

Bash

```
docker compose restart
```












---



---
---
## Pipewire - DONT REVCOMEND HAD ISSUES

```shell
# Update package database
sudo apt update

# Install PipeWire and related packages
sudo apt install -y pipewire wireplumber pipewire-audio-client-libraries libspa-0.2-bluetooth pipewire-audio pipewire-pulse dfu-util
```

Link the PipeWire configuration for ALSA applications sudo ln -sf:

```shell
sudo ln -sf: ln -s /usr/share/alsa/alsa.conf.d/50-pipewire.conf /etc/alsa/conf.d/
```

Allow services to run without an active user session (optional, for headless setups):

```shell
sudo mkdir -p /var/lib/systemd/linger
sudo touch /var/lib/systemd/linger/$USER
```

💡 **Note:** Replace `$USER` with your actual username that you want to run the voice assistant.

### Configure PipeWire (optional):

[https://github.com/tomsepe/linux-voice-assistant/blob/pi4-trixie/docs/install_audioserver.md#configure-pipewire-optional]

Create the PipeWire configuration directory:

```shell
mkdir -p "/etc/pipewire"
```

Don't just create the file in `/etc/pipewire/`. The "cleaner" way is to copy the default config first so you don't break the system defaults:

1. **Create the directory:** 
```bash
sudo mkdir -p /etc/pipewire
```

2. **Copy the original (optional but safe):** 
```bash
sudo cp /usr/share/pipewire/pipewire.conf /etc/pipewire/
#make a backup just in case
sudo cp /etc/pipewire/pipewire.conf /etc/pipewire/pipewire.conf.backup
```

Create the PipeWire configuration directory:

```shell
mkdir -p "/etc/pipewire"
```

Create the file `/etc/pipewire/pipewire.conf` with the following content (minimal configuration for voice assistant use):



```ini
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


### Step 2: Install Application:

[](https://github.com/tomsepe/linux-voice-assistant/blob/pi4-trixie/docs/install.md#step-2-install-application)

You can run the application in two ways:

- **a) Docker Compose** (recommended): Install Docker, download compose files, configure and start. See [Install Application - Docker Compose](https://github.com/tomsepe/linux-voice-assistant/blob/pi4-trixie/docs/install_application.md)
- **b) Bare Metal** Install dependencies, clone repo, setup and create systemd service. See [Install Application - Bare Metal](https://github.com/tomsepe/linux-voice-assistant/blob/pi4-trixie/docs/install_application.md)

You can install the application in different ways. We recommend to use Docker Compose if not the prebuilt image. But if you dont want to use Docker you can also install it directly on your system.



---
---

## **DEPRECATED:**
---
## **5. Use Linux Voice Assistant (replaces Wyoming-satellite):**

   ```BASH
   # Update
   sudo apt update && sudo apt upgrade -y
   
   # Install git if needed 
   sudo apt install git -y 
   git clone https://github.com/OHF-Voice/linux-voice-assistant.git
   cd linux-voice-assistant
   script/setup
   ```

### Step 1: Enter the Virtual Environment

You need to activate the environment you just built so your commands use the libraries inside it. install the missing audio server and its development headers:
```BASH
source .venv/bin/activate
sudo apt install -y pulseaudio libpulse-dev libmpv-dev mpv
```

Since we just installed it, we need to make sure the audio server is actually running before Python tries to talk to it.


```BASH
pulseaudio --start
```

### Step 1: Install the Session Manager

On Raspberry Pi OS **Lite**, the tool that manages user services (like audio) is often missing. Without this, your services die when you log out.

Run this command:
```BASH
sudo apt install -y dbus-user-session
```

### Step 2: Enable PulseAudio as a Service

Now we tell the Pi to run PulseAudio automatically at boot, forever.
```BASH
systemctl --user enable pulseaudio
systemctl --user start pulseaudio
```


### Step 2: Find Your Microphone

We need to know exactly what name Python sees for your ReSpeaker card. This is often different from what `arecord` shows


First we need the names of the input and output devices to add to our command There is a bit of a silly design flaw in the software—it forces you to name the satellite even if you are just asking "what microphones do you have?"

**Add a dummy name to the command to force it to list the devices:**

```BASH
# List Microphones
script/run --name temp --list-input-devices

# List Speakers
script/run --name temp --list-output-devices
```

You are looking for the name that mentions

We have the exact names now.

### The Final Run Command

We will use the generic name `"Built-in Audio Stereo"` for the microphone, and the specific PulseAudio fallback path for the speakers.

**Run this command to start Wintermute:**


```BASH
script/run \
  --name 'wintermute-satellite' \
  --host 0.0.0.0 \
  --port 10700 \
  --audio-input-device "Built-in Audio Stereo" \
  --audio-output-device "pulse/alsa_output.platform-soc_sound.stereo-fallback" \
  --wake-word-dir wakewords \
  --wake-model okay_nabu
```


Here is the logic for the final command:

1. **Input:** We use `"Built-in Audio Stereo"` (PulseAudio is aliasing your ReSpeaker to this name).
2. **Output:** We use the explicit hardware path `"pulse/alsa_output.platform-soc_sound.stereo-fallback"` to ensure it goes to the HAT, not the HDMI or Headphone jack.
- **Note on `snd-command`:** I set the playback rate to `48000` because the V2 HAT (`tlv320aic3x`) supports high-quality audio, unlike the V1.
- **Note on `wake-uri`:** This points to your Base Home Assistant server (`.72`). Ensure the **openWakeWord** Add-on is running there.

### What to expect:

1. **"Connected":** You should see a log saying the server started on port 10700.
2. **Home Assistant:** Go to **Settings > Devices**. You should see a new integration discovered (Wyoming Protocol).    
3. **Configure:** Click "Configure" and assign it to your voice pipeline.

**Note on Wake Word:** Because we removed the `--wake-uri` flag (which is no longer supported), this satellite currently has **no wake word**. It is in "Push-to-Talk" mode.

- **Test it first:** In Home Assistant, you can click the "Assist" icon at the top right, select this satellite, and see if it speaks through the Pi.    
- **Next Step:** Once it connects, we will connect the `ok_nabu` model to the Pi so it can listen locally.
#### 1. Enable "Lingering" (Crucial Step)

By default, "User Services" die the moment you log out (disconnect SSH). We need to tell the Pi to keep your user's brain running even when you aren't looking.

Run this command once:

Bash

```
loginctl enable-linger $USER
```

#### 2. Create the Service File

We will create a file that tells systemd exactly how to run the satellite.

Bash

```
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/wyoming-satellite.service
```

#### 3. Paste the Configuration

Paste the following text into the file. _(Note: I have included the specific `arecord` and `aplay` flags we found that work with your ReSpeaker HAT)._

```bash
[Unit]
Description=Wintermute Satellite
After=network-online.target pulseaudio.service
Wants=network-online.target pulseaudio.service

[Service]
Type=simple
WorkingDirectory=%h/linux-voice-assistant
ExecStart=%h/linux-voice-assistant/script/run \
    --name 'wintermute-satellite' \
    --host 0.0.0.0 \
    --port 10700 \
    --audio-input-device "Built-in Audio Stereo" \
    --audio-output-device "pulse/alsa_output.platform-soc_sound.stereo-fallback" \
    --wake-word-dir wakewords \
    --wake-model okay_nabu \
    --wakeup-sound %h/linux-voice-assistant/sounds/wake_word_triggered_old.wav
    --timer-finished-sound %h/linux-voice-assistant/sounds/timer_finished_old.wav
    --enable-thinking-sound
Restart=always
RestartSec=5s

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now wyoming-satellite.service
systemctl --user status wyoming-satellite.service
```
---
### **Finish the Home Assistant Setup:**

1. **Keep "Full local processing" selected** and click **Next**.
2. **Speech-to-text:** Select **Whisper** (it should be auto-detected since the Add-on is running).
3. **Text-to-speech:** Select **Piper** (also auto-detected).
4. **Wake Word:** Select **openWakeWord**.
5. **Finish:** Name the assistant (e.g., "Wintermute").    

## **7. Create as a service:** 
### Enable "Lingering" (Crucial)

This command tells the Pi to start your User Services (`tom`) immediately at boot, even before you log in via SSH. **Do not skip this.**

```BASH
sudo loginctl enable-linger $USER
```

### Step 3: Create the User Service

1. Create the folder structure:
```BASH
mkdir -p ~/.config/systemd/user/
```

2. Create the new service file:
```BASH
nano ~/.config/systemd/user/wintermute.service
```

3. Paste this exact configuration (notice `User=` is removed because it's implied, and paths use `%h` for home):

```INI
[Unit]
Description=Wintermute Satellite
After=network-online.target pulseaudio.service
Wants=network-online.target pulseaudio.service

[Service]
Type=simple
WorkingDirectory=%h/linux-voice-assistant
ExecStart=%h/linux-voice-assistant/script/run \
    --name 'wintermute-satellite' \
    --host 0.0.0.0 \
    --port 10700 \
    --audio-input-device "Built-in Audio Stereo" \
    --audio-output-device "pulse/alsa_output.platform-soc_sound.stereo-fallback" \
    --wake-word-dir wakewords \
    --wake-model okay_nabu \
    --wakeup-sound %h/linux-voice-assistant/sounds/wake_word_triggered_old.wav
    --timer-finished-sound %h/linux-voice-assistant/sounds/timer_finished_old.wav
    --enable-thinking-sound
Restart=always
RestartSec=5s

[Install]
WantedBy=default.target
```

```BASH
# Reload user daemons
systemctl --user daemon-reload

# Enable to start at boot
systemctl --user enable wintermute.service

# Start it now
systemctl --user start wintermute.service

# Chaeck status
systemctl --user status wintermute.service
```

### Step 1: Install the Session Manager

On Raspberry Pi OS **Lite**, the tool that manages user services (like audio) is often missing. Without this, your services die when you log out.

Run this command:
```BASH
sudo apt install -y dbus-user-session
```

### Step 2: Enable PulseAudio as a Service

Now we tell the Pi to run PulseAudio automatically at boot, forever.
```BASH
systemctl --user enable pulseaudio
systemctl --user start pulseaudio
```

### Step 3: Reboot (The Clean Slate)

Since we have changed permissions, installed drivers, and moved services around, we need a full reboot to ensure everything comes up in the correct order (PulseAudio First -> Then Wintermute).
```BASH
sudo reboot
```
### Step 4: The Moment of Truth

Wait about 60 seconds after the Pi boots up. **Do not run `script/run` manually.** The background service should be doing it for you.

1. SSH back in.
2. Check the status:
```BASH
systemctl --user status pulseaudio
systemctl --user status wintermute.service
journalctl --user -u wintermute.service -b --no-pager | tail -n 20
```

**You should see `Active: active (running)`.**

If you see that green dot:
- Walk to the Pi.
- Say **"Okay Nabu"**.
- Wait for the "Bloop".

```BASH
sudo systemctl stop wintermute.service
# make your edits to the service then relaad the deamon
sudo systemctl daemon-reload
# restaer the service
sudo systemctl restart wintermute.service
```
other useful commands:
sudo systemctl disable wintermute.service
sudo rm /etc/systemd/system/wintermute.service

## **8. Setup for the "Bloop"**

### Step 1: Edit the Service File

Open the configuration file again:
```BASH
nano ~/.config/systemd/user/wintermute.service
```

### Step 2: Add the Sound Argument

Add the `--wakeup-sound` line to your command.

Your `ExecStart` block should look like this (ensure you add the backslash `\` to the line before it!):

```Ini, TOML
ExecStart=%h/linux-voice-assistant/script/run \
    --name 'wintermute-satellite' \
    --host 0.0.0.0 \
    --port 10700 \
    --audio-input-device "Built-in Audio Stereo" \
    --audio-output-device "pulse/alsa_output.platform-soc_sound.stereo-fallback" \
    --wake-word-dir wakewords \
    --wake-model okay_nabu \
    --wakeup-sound %h/linux-voice-assistant/sounds/wake_word_triggered_old.wav
    --timer-finished-sound %h/linux-voice-assistant/sounds/timer_finished_old.wav
    --enable-thinking-sound
```

```
[Unit]
Description=Wintermute Satellite
After=network-online.target pulseaudio.service
Wants=network-online.target pulseaudio.service

[Service]
Type=simple
WorkingDirectory=%h/linux-voice-assistant
ExecStart=%h/linux-voice-assistant/script/run \
    --name 'wintermute-satellite' \
    --host 0.0.0.0 \
    --port 10700 \
    --audio-input-device "Built-in Audio Stereo" \
    --audio-output-device "pulse/alsa_output.platform-soc_sound.stereo-fallback" \
    --wake-word-dir wakewords \
    --wake-model okay_nabu \
    --wakeup-sound %h/linux-voice-assistant/sounds/wake_word_triggered_old.wav
    --timer-finished-sound %h/linux-voice-assistant/sounds/timer_finished_old.wav
    --enable-thinking-sound
Restart=always
RestartSec=5s

[Install]
WantedBy=default.target


```
_(Note: Since you have other sounds there, you can also add `--timer-finished-sound %h/linux-voice-assistant/sounds/timer_finished.flac` if you plan to use timers later, but let's stick to the wake sound for now)._

### Step 3: Reload and Restart

Lock in the changes and restart the brain.
```BASH
systemctl --user daemon-reload
systemctl --user restart wintermute.service
```

### Final Test

1. Walk to the Pi.
2. Say **"Okay Nabu"**.
3. **Bloop!** (You should hear it now). 
4. Say **"What time is it?"**

Let me know if you finally get that satisfying confirmation sound!


---

OR USE PULSEMIXER
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


