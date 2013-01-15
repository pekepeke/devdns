#!/bin/bash

LAUNCHD_NAME="com.github.pekepeke.devdns"
PLIST_PATH="/Library/LaunchDaemons/$LAUNCHD_NAME.plist"
PY_NAME=devdns.py

INSTALL_PATH=/usr/local/bin/$PY_NAME

opt_uninstall=0

usage() {
  prg_name=`basename $0`
  cat <<EOM
  Usage: $prg_name [option] [domain suffix...]

  -h : Show this message
  -u : Uninstall
EOM
  exit 1
}

launchd_plist() {
  cat <<EOM
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LAUNCHD_NAME</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/python</string>
    <string>$INSTALL_PATH</string>
EOM
  for DOMAIN in $* ; do
    echo "    <string>$DOMAIN</string>"
  done
  cat <<EOM
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>OnDemand</key>
  <false/>
</dict>
</plist>
EOM
  return 0

}

exec_install() {
  if [ x"$1" = x ]; then
    echo invalid arguments
    return 1
  fi

  local PLIST_FNAME=$LAUNCHD_NAME.plist

  [ -e $PLIST_PATH ]
  installed=$?
  launchd_plist $* > $PLIST_FNAME
  sudo chown root $PLIST_FNAME
  sudo chgrp wheel $PLIST_FNAME
  sudo cp -irp $(dirname $0)/$PY_NAME $INSTALL_PATH
  sudo cp -irp $PLIST_FNAME $PLIST_PATH

  sudo rm $PLIST_FNAME
  echo load daemons...
  [ $installed -eq 0 ] && sudo launchctl unload $PLIST_PATH
  sudo launchctl load $PLIST_PATH
  # sudo launchctl start $LAUNCHD_NAME

  echo "Installation is complete."
}

exec_uninstall() {
  echo stop daemons...
  sudo launchctl unload $PLIST_PATH
  sudo rm $INSTALL_PATH
  sudo rm $PLIST_PATH

  echo "Uninstallation is complete."
}

main() {
  if [ $opt_uninstall -eq 1 ]; then
    exec_uninstall "$@"
  else
    exec_install "$@"
  fi
}

OPTIND_OLD=$OPTIND
OPTIND=1
while getopts "hvu" opt; do
  case $opt in
    h)
      usage ;;
    v) ;;
    u)
      opt_uninstall=1
      ;;
  esac
done
shift `expr $OPTIND - 1`
OPTIND=$OPTIND_OLD
if [ $OPT_ERROR ]; then
  usage
fi

main "$@"

