#taskbar2

########## STAGE 0: build wallpaper only ##########
FROM ubuntu:24.04 AS wall
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends imagemagick \
 && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /build \
 && convert -size 1280x360 gradient:'#003366-#4F81BD' -rotate 90 /build/wallpaper.png

########## STAGE 1: runtime desktop ##########
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    USER=deskuser \
    HOME=/home/deskuser \
    DISPLAY=:1 \
    SCREEN_RESOLUTION=1920x900x24

# --- Install base system and tools (NO imagemagick, NO wget) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    lxde \
    x11vnc \
    xvfb \
    dbus-x11 \
    xterm \
    curl \
    git \
    sudo \
    net-tools \
    ca-certificates \
    gnupg \
    x11-utils \
    fonts-dejavu \
    galculator \
    unzip \
    vim \
    lxsession \
    python3-minimal \
 && rm -rf /var/lib/apt/lists/*

# === security hardening: pull all Ubuntu security updates (includes libjxl fixes) ===
RUN apt-get update && apt-get -y dist-upgrade && apt-get -y autoremove && apt-get clean

# Rename Galculator to Calculator
RUN sed -i 's/^Name=Galculator/Name=Calculator/' /usr/share/applications/galculator.desktop || true

# --- Create user ---
RUN useradd -m -s /bin/bash $USER && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# --- Install Google Chrome ---
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/google-chrome.gpg && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# Add Chrome launcher entry
RUN echo '[Desktop Entry]\n\
Name=Google Chrome\n\
Comment=Access the Internet\n\
Exec=google-chrome-stable --no-sandbox --disable-gpu --disable-dev-shm-usage\n\
Icon=google-chrome\n\
Terminal=false\n\
Type=Application\n\
Categories=Network;WebBrowser;\n' \
    > /usr/share/applications/google-chrome.desktop

# --- Setup noVNC ---
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify

# Replace noVNC index.html to autoconnect + clean UI
RUN printf '<!doctype html>\n<html>\n<head>\n<meta charset="utf-8">\n<title>noVNC</title>\n<style>html,body{height:100%%;margin:0}iframe{border:0;width:100vw;height:100vh;display:block}</style>\n</head>\n<body>\n<iframe src="vnc.html?autoconnect=1&resize=scale" allow="clipboard-read; clipboard-write"></iframe>\n<noscript><p>Please enable JavaScript to use noVNC.</p></noscript>\n</body>\n</html>\n' \
    > /opt/noVNC/index.html

# --- Copy wallpaper from build stage (keeps IM/JXL/OpenJPEG out of final image) ---
COPY --from=wall /build/wallpaper.png /usr/share/backgrounds/wallpaper.png

# --- Prepare LXPanel extra plugins ---
USER root
RUN mkdir -p /etc/xdg/lxpanel/LXDE/panels && \
    touch /etc/xdg/lxpanel/LXDE/panels/panel-extra && \
    printf '\n[Plugin]\ntype=dclock\nConfig=\n\n[Plugin]\ntype=logout\nConfig=\n\n[Plugin]\ntype=launchbar\nConfig=lxlock.desktop\n' \
    >> /etc/xdg/lxpanel/LXDE/panels/panel-extra

# ===== MINIMAL ADD: neuter GUI PolicyKit agents (prevents popup) =====
RUN set -eux; \
  for bin in \
    /usr/bin/lxpolkit \
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 \
    /usr/lib/x86_64-linux-gnu/polkit-gnome/polkit-gnome-authentication-agent-1 \
    /usr/lib/mate-polkit/polkit-mate-authentication-agent-1 \
  ; do \
    if [ -e "$bin" ] && [ ! -L "$bin" ]; then \
      mv "$bin" "${bin}.disabled" || true; \
      ln -sf /bin/true "$bin"; \
    fi; \
  done

# === security hardening: drop build tools that can carry Go-embedded utilities ===
RUN rm -rf /opt/noVNC/.git /opt/noVNC/utils/websockify/.git \
 && apt-get purge -y git && apt-get -y autoremove && apt-get clean \
 && rm -rf /usr/local/go /usr/lib/go-1.* || true

# --- Configure user environment ---
USER $USER
WORKDIR $HOME

# Configure LXPanel for deskuser
RUN mkdir -p $HOME/.config/lxpanel/LXDE/panels && \
    cat > $HOME/.config/lxpanel/LXDE/panels/panel <<'EOF'
Global {
  edge=bottom
  allign=left
  margin=0
  widthtype=percent
  width=100
  height=30
  transparent=0
}

Plugin {
  type=menu
  Config {
    image=/usr/share/lxde/images/lxde-icon.png
    system {
    }
    separator {
    }
    item {
        command=run
    }
  }
}

Plugin {
  type=launchbar
  Config {
    Button {
      id=pcmanfm.desktop
    }
    
    Button {
      id=google-chrome.desktop
    }
  }
}

Plugin {
  type=taskbar
  expand=1
  Config {
    tooltips=1
    IconsOnly=0
  }
}

Plugin {
  type=dclock
  Config {
    ClockFmt=%H:%M
    TooltipFmt=%A %x
  }
}

Plugin {
  type=logout
}
EOF

# Configure desktop wallpaper
RUN mkdir -p $HOME/.config/pcmanfm/LXDE && \
    echo '[*]\nwallpaper_mode=stretch\nwallpaper_common=1\nwallpaper=/usr/share/backgrounds/wallpaper.png\n' \
    > $HOME/.config/pcmanfm/LXDE/desktop-items-0.conf

# Restore deskuser ownership
USER root
RUN chown -R $USER:$USER $HOME/.config

# --- Startup script ---
RUN printf '#!/bin/bash\n\
set -euo pipefail\n\
# Ensure no stale X locks from a previously committed container filesystem\n\
rm -f /tmp/.X*-lock || true\n\
rm -f /tmp/.X11-unix/X* || true\n\
export DISPLAY=%s\n\
# Start a fresh Xvfb on the requested display\n\
Xvfb %s -screen 0 %s &\n\
XVFB_PID=$!\n\
# Wait until the X server is accepting connections\n\
for i in $(seq 1 30); do\n\
  xdpyinfo -display "$DISPLAY" >/dev/null 2>&1 && break\n\
  sleep 1\n\
done\n\
if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then\n\
  echo "Xvfb failed to start on $DISPLAY" >&2\n\
  exit 1\n\
fi\n\
# Start the desktop session\n\
sudo -u %s env DISPLAY=$DISPLAY startlxde &\n\
sleep 3\n\
sudo -u %s env DISPLAY=$DISPLAY lxpanelctl restart >/dev/null 2>&1 || true\n\
# Start VNC server bound to the X display\n\
x11vnc -display %s -nopw -forever -shared -rfbport 5900 &\n\
# noVNC/websockify on port 80 -> 5900\n\
/opt/noVNC/utils/websockify/run --web=/opt/noVNC 80 localhost:5900\n' \
    "$DISPLAY" "$DISPLAY" "$SCREEN_RESOLUTION" "$USER" "$USER" "$DISPLAY" \
    > /startup.sh && chmod +x /startup.sh

# --- Expose noVNC port ---
EXPOSE 80

# Run startup script
ENTRYPOINT ["/startup.sh"]

# Report readiness: noVNC HTTP on :80 and VNC on :5900 must both be up
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD bash -lc 'curl -fsS http://127.0.0.1:80 >/dev/null && exec 3<>/dev/tcp/127.0.0.1/5900'
