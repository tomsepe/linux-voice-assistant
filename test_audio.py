import mpv
import os
import sys
import time

print("--- DIAGNOSTIC START ---")

# 1. Check if the container knows where PulseAudio is
pulse_server = os.environ.get('PULSE_SERVER')
print(f"Environment PULSE_SERVER: {pulse_server}")

if not pulse_server:
    print("WARNING: PULSE_SERVER is not set! MPV might not find the sound server.")

# 2. Try to Initialize MPV explicitly using PulseAudio
try:
    print("Initializing MPV with ao='pulse'...")
    # Initialize with verbose logging to see driver errors
    player = mpv.MPV(input_default_bindings=True, input_vo_keyboard=True)

    # Force the audio output driver to PulseAudio
    player['ao'] = 'pulse'

    # Check if we can see the property
    print(f"MPV Audio Output Driver: {player['ao']}")

    # 3. Play the Sound
    sound_file = '/app/sounds/processing.wav'
    if not os.path.exists(sound_file):
        print(f"ERROR: File {sound_file} does not exist inside container.")
    else:
        print(f"Attempting to play: {sound_file}")
        player.play(sound_file)
        player.wait_for_playback()
        print("Playback finished successfully.")

except Exception as e:
    print(f"CRASHED: {e}")

print("--- DIAGNOSTIC END ---")
