```BASH
tom@pi-tinyhouse:~/linux-voice-assistant $ aplay -l
```
```**** List of PLAYBACK Hardware Devices ****
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

```BASH
tom@pi-tinyhouse:~/linux-voice-assistant $ arecord -l
```
```**** List of CAPTURE Hardware Devices ****
card 3: Device [USB PnP Sound Device], device 0: USB Audio [USB Audio]
  Subdevices: 1/1
  Subdevice #0: subdevice #0
```

First run of Docker with debug on and list devices on:
```tom@pi-tinyhouse:~ $ docker logs -f linux-voice-assistant
Checking port 6053...
✅ PulseAudio is running
Checking port 6053...
Port 6053 is available
list input devices
Failed to load cookie file from cookie: No such file or directory
Input devices
=============
[0] PCM2902 Audio Codec Analog Mono
list output devices
Failed to load cookie file from cookie: No such file or directory
Output devices
==============
Failed to load cookie file from cookie: No such file or directory
auto: Autoselect device
pipewire: Default (pipewire)
pipewire/alsa_output.platform-fe00b840.mailbox.stereo-fallback: Built-in Audio Stereo
pulse/alsa_output.platform-fe00b840.mailbox.stereo-fallback: Built-in Audio Stereo
alsa: Default (alsa)
alsa/lavrate: Rate Converter Plugin Using Libav/FFmpeg Library
alsa/samplerate: Rate Converter Plugin Using Samplerate Library
alsa/speexrate: Rate Converter Plugin Using Speex Resampler
alsa/jack: JACK Audio Connection Kit
alsa/oss: Open Sound System
alsa/pipewire: PipeWire Sound Server
alsa/speex: Plugin using Speex DSP (resample, agc, denoise, echo, dereverb)
alsa/upmix: Plugin for channel upmix (4,6,8)
```