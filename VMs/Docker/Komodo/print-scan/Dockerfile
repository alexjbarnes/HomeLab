FROM debian:bookworm-slim

# Install CUPS, printer drivers, and network discovery tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    cups \
    cups-client \
    cups-bsd \
    cups-filters \
    printer-driver-all \
    printer-driver-gutenprint \
    avahi-daemon \
    avahi-utils \
    libnss-mdns \
    dbus \
    libcupsimage2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure CUPS for full network access
RUN sed -i 's/Listen localhost:631/Port 631/' /etc/cups/cupsd.conf && \
    sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
    sed -i '/<Location \/>/a\  Order allow,deny\n  Allow all' /etc/cups/cupsd.conf && \
    sed -i '/<Location \/admin>/a\  Order allow,deny\n  Allow all' /etc/cups/cupsd.conf && \
    sed -i '/<Location \/admin\/conf>/a\  Order allow,deny\n  Allow all' /etc/cups/cupsd.conf && \
    echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
    echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf && \
    echo "WebInterface Yes" >> /etc/cups/cupsd.conf && \
    echo "BrowseLocalProtocols dnssd" >> /etc/cups/cupsd.conf && \
    echo "DefaultShared Yes" >> /etc/cups/cupsd.conf

# Configure Avahi for printer discovery
RUN sed -i 's/#enable-dbus=yes/enable-dbus=yes/' /etc/avahi/avahi-daemon.conf && \
    sed -i 's/use-ipv6=yes/use-ipv6=no/' /etc/avahi/avahi-daemon.conf

# Install Canon driver dependencies first
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libxml2 \
    libcups2 \
    libcupsimage2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Canon G1020 driver (cnijfilter2 6.10)
COPY cnijfilter2-6.10-1-deb.tar.gz /tmp/
RUN cd /tmp && \
    tar -xzf cnijfilter2-6.10-1-deb.tar.gz && \
    cd cnijfilter2-6.10-1-deb/packages && \
    # Install the driver package (dependencies now satisfied)
    dpkg -i cnijfilter2_6.10-1_amd64.deb && \
    # CRITICAL: Rebuild shared library cache (this is what install.sh does)
    ldconfig && \
    # Create entry list directory that install.sh would create
    mkdir -p /usr/share/cnijfilter2 && \
    # Ensure filter has execute permissions
    chmod +x /usr/lib/cups/filter/rastertocanonij 2>/dev/null || true && \
    # Verify installation
    echo "=== Verifying Canon driver installation ===" && \
    echo "Filter binary:" && \
    ls -la /usr/lib/cups/filter/rastertocanonij && \
    echo "Canon libraries:" && \
    ldconfig -p | grep -i canon || echo "WARNING: No Canon libraries found in cache" && \
    echo "PPD files:" && \
    ls -la /usr/share/cups/model/canon* 2>/dev/null || echo "WARNING: No PPD files found" && \
    echo "Filter dependencies:" && \
    ldd /usr/lib/cups/filter/rastertocanonij || echo "WARNING: Could not check dependencies" && \
    # Clean up
    cd /tmp && \
    rm -rf cnijfilter2-6.10-1-deb cnijfilter2-6.10-1-deb.tar.gz

# Create CUPS admin user (username: admin, password: admin)
# Change the password after first login for security!
RUN useradd -r -G lpadmin -M admin && \
    echo "admin:admin" | chpasswd && \
    # Add admin to printer-related groups for USB access
    usermod -a -G lp admin && \
    usermod -a -G dialout admin

# Expose CUPS port and mDNS port for discovery
EXPOSE 631/tcp 5353/udp

# Create startup script to run both services
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo '# Set up library path for Canon drivers' >> /start.sh && \
    echo 'export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH' >> /start.sh && \
    echo '# Create D-Bus runtime directories' >> /start.sh && \
    echo 'mkdir -p /var/run/dbus /run/dbus' >> /start.sh && \
    echo '# Start D-Bus system daemon' >> /start.sh && \
    echo 'rm -f /var/run/dbus/pid /run/dbus/pid' >> /start.sh && \
    echo 'dbus-daemon --system --nofork &' >> /start.sh && \
    echo 'sleep 2' >> /start.sh && \
    echo '# Start Avahi daemon for network discovery' >> /start.sh && \
    echo 'avahi-daemon -D' >> /start.sh && \
    echo 'sleep 2' >> /start.sh && \
    echo '# Start CUPS in foreground' >> /start.sh && \
    echo 'exec cupsd -f' >> /start.sh && \
    chmod +x /start.sh

CMD ["/start.sh"]
