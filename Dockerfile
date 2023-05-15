# Building the image
#   docker build -t gauge-taiko .
# Running the image
#   docker run  --rm -it -v ${PWD}/reports:/gauge/reports gauge-taiko

# This image uses the official node base image.
FROM node

# Install chromium dependencies
RUN apt-get update \
    && apt-get install -y wget gnupg ca-certificates \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-stable

# Add the Taiko browser arguments
ENV TAIKO_BROWSER_ARGS=--no-sandbox,--start-maximized,--disable-dev-shm-usage
ENV headless_chrome=true
ENV TAIKO_SKIP_DOCUMENTATION=true

# Set working directory
WORKDIR /gauge

# Copy the local working folder
COPY . .

# Create an unprivileged user to run Taiko tests
RUN groupadd -r gauge && useradd -r -g gauge -G audio,video gauge \
    && mkdir -p /home/gauge/.npm-packages/lib \
    && chown -R gauge:gauge /home/gauge /gauge

USER gauge

# Set a custom npm install location so that Gauge, Taiko and dependencies can be
# installed without root privileges
ENV NPM_CONFIG_PREFIX=/home/gauge/.npm-packages

# Install dependencies and plugins
RUN npm install -g @getgauge/cli \
    && npm install \
    && gauge install \
    && gauge install screenshot \
    && gauge config check_updates false

# Update PATH
ENV PATH="/home/gauge/.npm-packages/bin:${PATH}"

# Default command on running the image
ENTRYPOINT ["npm", "test"]