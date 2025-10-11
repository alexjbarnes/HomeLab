FROM debian:bookworm-slim

# Install CUPS and printer drivers
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    cups \
    cups-client \
    printer-driver-all \
    printer-driver-gutenprint \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure CUPS for network access
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/>/<Location \/>\n  Allow all/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow all/' /etc/cups/cupsd.conf

# Create CUPS admin user (username: admin, password: admin)
RUN useradd -r -G lpadmin -M admin && \
    echo "admin:admin" | chpasswd

EXPOSE 631

CMD ["cupsd", "-f"]
