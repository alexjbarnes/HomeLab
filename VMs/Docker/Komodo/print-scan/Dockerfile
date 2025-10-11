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

# Create CUPS admin user (username: admin, password: admin)
# Change the password after first login for security!
RUN useradd -r -G lpadmin -M admin && \
    echo "admin:admin" | chpasswd

# Expose CUPS port and mDNS port for discovery
EXPOSE 631/tcp 5353/udp

# Create startup script to run both services
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'set -e' >> /start.sh && \
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
