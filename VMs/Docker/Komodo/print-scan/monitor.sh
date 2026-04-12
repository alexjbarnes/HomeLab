#!/bin/sh

PRINTER_NAME="Canon_G1020_series"
CHECK_INTERVAL=30
USB_VENDOR="canon"
LAST_USB_STATE=""
LAST_CUPS_STATE=""

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [monitor] $1"
}

get_usb_state() {
    lsusb 2>/dev/null | grep -qi "$USB_VENDOR" && echo "connected" || echo "disconnected"
}

get_cups_state() {
    lpstat -p "$PRINTER_NAME" 2>/dev/null | head -1 || echo "unknown"
}

restart_cups_backend() {
    log "Attempting CUPS backend restart for $PRINTER_NAME"

    # Cancel any stuck jobs
    STUCK_JOBS=$(lpstat -o 2>/dev/null | grep "$PRINTER_NAME" | awk '{print $1}')
    if [ -n "$STUCK_JOBS" ]; then
        for job in $STUCK_JOBS; do
            log "Cancelling stuck job: $job"
            cancel "$job" 2>/dev/null
        done
    fi

    # Re-enable the printer if it was disabled
    cupsenable "$PRINTER_NAME" 2>/dev/null
    cupsaccept "$PRINTER_NAME" 2>/dev/null
    log "Re-enabled printer $PRINTER_NAME"

    # Log state after recovery
    sleep 2
    CUPS_STATE=$(get_cups_state)
    log "Printer state after recovery: $CUPS_STATE"
}

log "Monitor started (checking every ${CHECK_INTERVAL}s)"
LAST_USB_STATE=$(get_usb_state)
LAST_CUPS_STATE=$(get_cups_state)
log "Initial USB state: $LAST_USB_STATE"
log "Initial CUPS state: $LAST_CUPS_STATE"

while true; do
    sleep "$CHECK_INTERVAL"

    USB_STATE=$(get_usb_state)
    CUPS_STATE=$(get_cups_state)

    # Log USB state changes
    if [ "$USB_STATE" != "$LAST_USB_STATE" ]; then
        log "USB state changed: $LAST_USB_STATE -> $USB_STATE"
        if [ "$USB_STATE" = "disconnected" ]; then
            log "WARNING: Canon USB printer disconnected"
            log "USB devices currently visible:"
            lsusb 2>&1 | while read -r line; do log "  $line"; done
        else
            log "Canon USB printer reconnected"
            lsusb 2>&1 | grep -i "$USB_VENDOR" | while read -r line; do log "  $line"; done
            # Give the device a moment to settle, then try recovery
            sleep 5
            restart_cups_backend
        fi
        LAST_USB_STATE="$USB_STATE"
    fi

    # Log CUPS state changes
    if [ "$CUPS_STATE" != "$LAST_CUPS_STATE" ]; then
        log "CUPS printer state changed: $LAST_CUPS_STATE -> $CUPS_STATE"
        LAST_CUPS_STATE="$CUPS_STATE"
    fi

    # Detect CUPS errors even if USB looks fine
    if echo "$CUPS_STATE" | grep -qi "disabled\|stopped\|not ready"; then
        if [ "$USB_STATE" = "connected" ]; then
            log "WARNING: Printer disabled/stopped but USB is connected. Attempting recovery."
            restart_cups_backend
        fi
    fi
done
