#!/bin/sh
set -e

rm -f /tmp/.X0-lock /tmp/.X11-unix/X0

Xvfb :0 -screen 0 "${RESOLUTION}x24" -ac -noreset &

until [ -e /tmp/.X11-unix/X0 ]; do
    sleep 0.5
done

fluxbox &

if [ -n "$VNC_PASSWORD" ]; then
    x11vnc -display :0 -forever -shared -rfbport 5900 -passwd "$VNC_PASSWORD" -xkb -noxrecord -noxfixes -noxdamage &
else
    x11vnc -display :0 -forever -shared -rfbport 5900 -nopw -xkb -noxrecord -noxfixes -noxdamage &
fi

/usr/share/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6900 &

socat TCP-LISTEN:9225,fork,reuseaddr TCP:127.0.0.1:9223 &

export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export LIBGL_ALWAYS_SOFTWARE=1
export QT_XCB_GL_INTEGRATION=none
export QT_QUICK_BACKEND=software
export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox --disable-gpu --disable-vulkan"

AUTH_ARG=""
if [ -n "$CDP_AUTH_TOKEN" ]; then
    AUTH_ARG="--auth-token=$CDP_AUTH_TOKEN"
fi

while true; do
    /usr/local/bin/anoa.AppImage --no-sandbox $AUTH_ARG
    sleep 2
done
