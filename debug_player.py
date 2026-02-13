import sys
import os
# Force the venv path
sys.path.append('/app/.venv/lib/python3.13/site-packages')
import mpv

def on_loglevel(level, component, message):
    print(f"[{level}] {component}: {message}")

print("--- MPV ENGINE DEBUG START ---")
print(f"PULSE_SERVER: {os.environ.get('PULSE_SERVER')}")

try:
    # Initialize exactly like the Linux Voice Assistant does
    player = mpv.MPV(log_handler=on_loglevel)
    player.loglevel = 'debug' # This will show us EVERYTHING
    
    # Manually set the driver
    player['ao'] = 'pulse'
    
    print("Attempting playback...")
    player.play('/app/sounds/wake_word_triggered.flac')
    player.wait_for_playback()
    print("Playback finished.")
except Exception as e:
    print(f"FAILED: {e}")
