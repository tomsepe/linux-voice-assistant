docker exec -it linux-voice-assistant python3 -c "
import mpv
import time
import os

print('--- STARTING MPV TEST ---')
# Check if Pulse socket is visible
print(f'PULSE_SERVER env var: {os.environ.get(\"PULSE_SERVER\")}')

try:
    # Initialize MPV with verbose logging
    m = mpv.MPV(input_default_bindings=True, input_vo_keyboard=True, verbose=True)
    
    # Force it to use PulseAudio explicitly
    m['ao'] = 'pulse'
    
    print('Attempting to play processing.wav...')
    m.play('/app/sounds/processing.wav')
    m.wait_for_playback()
    print('--- PLAYBACK FINISHED ---')
except Exception as e:
    print(f'--- CRASHED: {e} ---')
"
