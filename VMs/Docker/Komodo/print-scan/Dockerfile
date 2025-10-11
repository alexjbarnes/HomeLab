FROM debian:bookworm-slim

# Install CUPS, SANE, and essential drivers
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    cups \
    cups-client \
    printer-driver-all \
    printer-driver-gutenprint \
    sane \
    sane-utils \
    libsane1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure CUPS for network access
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/>/<Location \/>\n  Allow all/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow all/' /etc/cups/cupsd.conf

# Configure SANE for network access
RUN echo "0.0.0.0/0" >> /etc/sane.d/saned.conf

EXPOSE 631 6566

CMD ["sh", "-c", "cupsd && saned -d && tail -f /dev/null"]
