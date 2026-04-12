#!/bin/sh
set -e

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [start] $1"
}

log "Starting print-scan container"

# Set up library path for Canon drivers
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

# Create D-Bus runtime directories
mkdir -p /var/run/dbus /run/dbus
rm -f /var/run/dbus/pid /run/dbus/pid

# Start D-Bus system daemon
log "Starting D-Bus daemon"
dbus-daemon --system --nofork &
DBUS_PID=$!
sleep 2

if ! kill -0 "$DBUS_PID" 2>/dev/null; then
    log "ERROR: D-Bus daemon failed to start"
    exit 1
fi
log "D-Bus daemon running (PID $DBUS_PID)"

# Start Avahi daemon for network discovery
log "Starting Avahi daemon"
avahi-daemon -D
sleep 2
log "Avahi daemon started"

# Log initial USB device state
log "USB devices at startup:"
lsusb 2>&1 | while read -r line; do log "  $line"; done

# Check for Canon printer at startup
if lsusb | grep -qi canon; then
    log "Canon USB printer detected"
else
    log "WARNING: No Canon USB printer detected at startup"
fi

# Disable USB autosuspend for all USB devices if possible
for dev in /sys/bus/usb/devices/*/power/autosuspend; do
    if [ -w "$dev" ]; then
        echo -1 > "$dev" 2>/dev/null && log "Disabled autosuspend for $dev"
    fi
done
for dev in /sys/bus/usb/devices/*/power/control; do
    if [ -w "$dev" ]; then
        echo "on" > "$dev" 2>/dev/null && log "Set power control to 'on' for $dev"
    fi
done

# Start CUPS in background so we can run the monitor alongside it
log "Starting CUPS daemon"
cupsd -f &
CUPS_PID=$!
sleep 2

if ! kill -0 "$CUPS_PID" 2>/dev/null; then
    log "ERROR: CUPS daemon failed to start"
    exit 1
fi
log "CUPS daemon running (PID $CUPS_PID)"

# Log printer status
lpstat -t 2>&1 | while read -r line; do log "  $line"; done

# Start the monitor script in background
log "Starting USB/printer monitor"
/monitor.sh &
MONITOR_PID=$!

# Wait for CUPS to exit (it's the primary process)
wait "$CUPS_PID"
CUPS_EXIT=$?
log "CUPS daemon exited with code $CUPS_EXIT"

# Clean up monitor
kill "$MONITOR_PID" 2>/dev/null
exit "$CUPS_EXIT"
