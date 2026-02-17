Since we solved this through a mix of Docker environment variables, host-side PulseAudio configuration, and a system-level `mpv` override, it's definitely worth documenting.

Here is a structured `README-satellite.md` you can add to your repo. It focuses on the "Gotchas" we hit—specifically the `$HOME` path and the need to force the `mpv` driver.

---

### `README-satellite.md`

# 🛰️ Satellite Setup: Pi Zero + ReSpeaker HAT + Docker

This guide explains how to get the Linux Voice Assistant running on a Raspberry Pi Zero with a ReSpeaker 2-Mics HAT using a PulseAudio-to-Docker bridge.

## 🛠️ The Core Issue

By default, the application's internal `mpv` player tries to guess the audio driver (often failing on ALSA because PulseAudio has the hardware locked). We solve this by forcing the `pulse` driver through Docker environment variables and a system-wide configuration override.

## 1. Host Configuration (Raspberry Pi)

The host must have PulseAudio running in user mode and the ReSpeaker HAT drivers installed.

### PulseAudio Socket

Ensure PulseAudio is listening on a Unix socket. Check your `~/.config/pulse/default.pa` (or the system-wide one) for:

```bash
load-module module-native-protocol-unix auth-anonymous=1 socket=/run/user/1000/pulse/native

```

### Hardware Mixers

The ReSpeaker HAT often has muted DAC mixers by default. Run these to open the pipe:

```bash
amixer -c 1 sset 'Output Left From Left DAC' on
amixer -c 1 sset 'Output Right From Right DAC' on
amixer -c 1 sset 'Line DAC' 100% unmute

```

---

## 2. Docker Configuration

The `docker-compose.yml` must bridge the host's PulseAudio socket and force the environment variables.

### Key Environment Variables

These are critical to bypass the application's default "guessing" logic:

* `PULSE_SERVER`: Points to the mounted socket.
* `MPV_AO=pulse`: Forces the `mpv` library to use PulseAudio.
* `HOME=/home/tom`: Ensures `mpv` has a writable directory for state/config.

### Volume Mounts

```yaml
volumes:
  - /run/user/1000/pulse/native:/run/user/1000/pulse/native
  - /home/tom/container_home:/home/tom

```

---

## 3. The "Global Hammer" Override

Some versions of `libmpv` ignore environment variables. We force the driver at the system level inside the container:

```bash
docker exec -u 0 linux-voice-assistant sh -c "mkdir -p /etc/mpv && echo 'ao=pulse' > /etc/mpv/mpv.conf"

```

---

## 🔍 Troubleshooting

If the logs say `Playing media` but there is silence:

1. **Check the Pipe:** Run `pactl list sink-inputs` on the host **while** the assistant is playing.
* *If no stream appears:* The app isn't talking to PulseAudio. Check `MPV_AO` settings.
* *If a stream appears:* The issue is volume. Run `pactl set-sink-volume seeed_out 100%`.


2. **Verify Driver:** Use the `debug_player.py` script to test the `mpv` initialization independently of the main app.

---

### How to add this to your repo:

You can create the file directly from the terminal:

```bash
nano README-satellite.md
# Paste the content above, then Save/Exit
git add README-satellite.md
git commit -m "docs: add satellite setup guide for pulse audio"
git push origin pi-satellite

```

**Would you like me to help you refine the "Microphone Gain" section in this README, or are you happy with the playback documentation for now?**