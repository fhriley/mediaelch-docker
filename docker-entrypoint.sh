#!/bin/bash

id -g app &>/dev/null || groupadd --gid $MEDIAELCH_GID app
id -u app &>/dev/null || useradd --home-dir /data --shell /bin/bash --uid $MEDIAELCH_UID --gid $MEDIAELCH_GID app

if [ ! -f /data/.Xresources ]; then
  touch /data/.Xresources
  chown app:app /data/.Xresources
fi

if [ ! -f /data/.local/share/kvibes/MediaElch/advancedsettings.xml ]; then
  mkdir -p /data/.local/share/kvibes/MediaElch
  cp /usr/local/share/MediaElch/advancedsettings.xml /data/.local/share/kvibes/MediaElch/advancedsettings.xml
  chown -R app:app /data/.local
fi

export QT_LOGGING_RULES="generic.debug=false
movie.debug=false"

chown app:app /dev/stdout
exec gosu app supervisord
