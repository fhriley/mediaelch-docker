#!/bin/bash

id -g app &>/dev/null || groupadd --gid $MEDIAELCH_GID app
id -u app &>/dev/null || useradd --home-dir /data --shell /bin/bash --uid $MEDIAELCH_UID --gid $MEDIAELCH_GID app

if [ ! -f /data/.Xresources ]; then
  touch /data/.Xresources
  chown app:app /data/.Xresources
fi

if [ ! -f /data/.vnc/Xtigervnc-session ]; then
  mkdir -p /data/.vnc
  cp /usr/local/share/xstartup /data/.vnc/Xtigervnc-session
  chown -R app:app /data/.vnc
fi

chown app:app /dev/stdout
exec gosu app supervisord
