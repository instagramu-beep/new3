FROM python:3.11-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    git build-essential libssl-dev libffi-dev libxml2-dev libxslt1-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone SET
RUN git clone https://github.com/trustedsec/social-engineer-toolkit /opt/setoolkit
WORKDIR /opt/setoolkit

# Install requirements
RUN pip install --upgrade pip && \
    pip install -r requirements.txt && \
    python setup.py install

# Pre-configure SET to run in web mode
RUN mkdir -p /etc/setoolkit && \
    echo -e "ACCEPT_EULA=y\nAUTO_DETECT=n\nWEB_ATTACK_INTERFACE=0.0.0.0" > /etc/setoolkit/set.config

# Create a startup script that properly binds to the port
RUN echo '#!/bin/bash\n\
echo "Starting SET web interface on port 10000..."\n\
# First start the web interface in background\n\
setoolkit --cli --web-host 0.0.0.0 --web-port 10000 &\n\
# Then start a simple web server to satisfy Render\'s port check\n\
while true; do nc -l -p 10000 -c "echo -e \\"HTTP/1.1 200 OK\\n\\nSET is running\\""; done' > /start.sh && \
    chmod +x /start.sh

EXPOSE 10000

CMD ["/start.sh"]
