#!/bin/bash
set -e

### Handlers
# Handle parameters
EXTRA_ARGS=()

if [ "$ENABLE_DEBUG" = "1" ]; then
  EXTRA_ARGS+=( "--debug" )
fi

if [ -n "${CLIENT_NAME}" ]; then
  EXTRA_ARGS+=( "--name" "$CLIENT_NAME" )
fi

PREFERENCES_FILE=${PREFERENCES_FILE:-"/app/configuration/preferences.json"}
if [ -n "${PREFERENCES_FILE}" ]; then
  EXTRA_ARGS+=( "--preferences-file" "$PREFERENCES_FILE" )
fi

if [ -n "${NETWORK_INTERFACE}" ]; then
  EXTRA_ARGS+=( "--network-interface" "$NETWORK_INTERFACE" )
fi

# IP-ADDRESS
if [ -n "${HOST}" ]; then
  EXTRA_ARGS+=( "--host" "$HOST" )
fi

PORT=${PORT:-6053}
if [ -n "${PORT}" ]; then
  EXTRA_ARGS+=( "--port" "$PORT" )
fi

if [ -n "${AUDIO_INPUT_DEVICE}" ]; then
  EXTRA_ARGS+=( "--audio-input-device" "$AUDIO_INPUT_DEVICE" )
fi

if [ -n "${AUDIO_OUTPUT_DEVICE}" ]; then
  EXTRA_ARGS+=( "--audio-output-device" "$AUDIO_OUTPUT_DEVICE" )
fi

if [ "$ENABLE_THINKING_SOUND" = "1" ]; then
  EXTRA_ARGS+=( "--enable-thinking-sound" )
fi

if [ -n "${WAKE_MODEL}" ]; then
  EXTRA_ARGS+=( "--wake-model" "$WAKE_MODEL" )
fi

if [ -n "${STOP_MODEL}" ]; then
  EXTRA_ARGS+=( "--stop-model" "$STOP_MODEL" )
fi

if [ -n "${REFACTORY_SECONDS}" ]; then
  EXTRA_ARGS+=( "--refractory-seconds" "$REFACTORY_SECONDS" )
fi

if [ -n "${WAKEUP_SOUND}" ]; then
  EXTRA_ARGS+=( "--wakeup-sound" "$WAKEUP_SOUND" )
fi

if [ -n "${TIMER_FINISHED_SOUND}" ]; then
  EXTRA_ARGS+=( "--timer-finished-sound" "$TIMER_FINISHED_SOUND" )
fi

if [ -n "${PROCESSING_SOUND}" ]; then
  EXTRA_ARGS+=( "--processing-sound" "$PROCESSING_SOUND" )
fi

if [ -n "${MUTE_SOUND}" ]; then
  EXTRA_ARGS+=( "--mute-sound" "$MUTE_SOUND" )
fi

if [ -n "${UNMUTE_SOUND}" ]; then
  EXTRA_ARGS+=( "--unmute-sound" "$UNMUTE_SOUND" )
fi


### Wait for audio server socket (PipeWire or PulseAudio)
# Check that the Pulse-compatible socket exists. We do NOT run pactl here:
# pactl can hang (e.g. with PipeWire when DBus/session is not ready).
# If the socket exists, the app will connect when it starts.
CP_MAX_RETRIES=30
CP_RETRY_DELAY=1
socket_path="${PULSE_SERVER#unix:}"
if [ -z "$socket_path" ]; then
  socket_path="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pulse/native"
fi
echo "Checking port $PORT and audio socket..."
for i in $(seq 1 $CP_MAX_RETRIES); do
  if [ -S "$socket_path" ]; then
    echo "✅ Audio server socket available (PipeWire or PulseAudio)"
    break
  fi

  if [ $i -eq $CP_MAX_RETRIES ]; then
      echo "❌ Audio server socket not found after $CP_MAX_RETRIES s at: $socket_path"
      echo "   Ensure PipeWire (pipewire-pulse) or PulseAudio is running on the host and XDG_RUNTIME_DIR is mounted."
      exit 2
  fi

  echo "⏳ Audio server socket not ready, retrying in $CP_RETRY_DELAY s..."
  sleep $CP_RETRY_DELAY
done


### Check port availability
# PORT variable is used from env
PA_MAX_RETRIES=30
PA_RETRY_DELAY=2
echo "Checking port $PORT..."
for i in $(seq 1 $PA_MAX_RETRIES); do
  # Wait for port to be free (in case of rapid restarts)
  if ! ss -tln | grep -q ":${PORT} "; then
      echo "Port $PORT is available"
      break
  fi

  if [ $i -eq $PA_MAX_RETRIES ]; then
      echo "ERROR: Port $PORT still in use after $((PA_MAX_RETRIES * PA_RETRY_DELAY)) seconds"
      exit 2
  fi

  echo "Attempt $i/$PA_MAX_RETRIES: Port $PORT in use, waiting ${PA_RETRY_DELAY}s..."
  sleep $PA_RETRY_DELAY
done


### Start application
if [ "$LIST_DEVICES" = "1" ]; then
  echo "list input devices"
  ./script/run "$@" "${EXTRA_ARGS[@]}" --list-input-devices
  echo "list output devices"
  ./script/run "$@" "${EXTRA_ARGS[@]}" --list-output-devices
  echo "wait 20s and then starting the application"
  sleep 20
fi

echo "starting application"
exec ./script/run "$@" "${EXTRA_ARGS[@]}"
