#!/bin/bash

if [ ! -f /data/.local/share/kvibes/MediaElch/advancedsettings.xml ]; then
  mkdir -p /data/.local/share/kvibes/MediaElch
  cp /usr/local/share/MediaElch/advancedsettings.xml /data/.local/share/kvibes/MediaElch/advancedsettings.xml
  chown -R app:app /data/.local
fi

export VNC_UID=${MEDIAELCH_UID}
export VNC_GID=${MEDIAELCH_GID}

export QT_LOGGING_RULES="generic.debug=false
movie.debug=false"
