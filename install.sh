#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202210082246-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.com
# @@License          :  LICENSE.md
# @@ReadME           :  install.sh --help
# @@Copyright        :  Copyright: (c) 2022 Jason Hempstead, Casjays Developments
# @@Created          :  Tuesday, Oct 11, 2022 15:07 EDT
# @@File             :  install.sh
# @@Description      :
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  installers/dockermgr
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPNAME="cherokee"
VERSION="202210082246-git"
HOME="${USER_HOME:-$HOME}"
USER="${SUDO_USER:-$USER}"
RUN_USER="${SUDO_USER:-$USER}"
SCRIPT_SRC_DIR="${BASH_SOURCE%/*}"
SCRIPTS_PREFIX="dockermgr"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
#if [ ! -t 0 ] && { [ "$1" = --term ] || [ $# = 0 ]; }; then { [ "$1" = --term ] && shift 1 || true; } && TERMINAL_APP="TRUE" myterminal -e "$APPNAME $*" && exit || exit 1; fi
[ "$1" = "--debug" ] && set -x && export SCRIPT_OPTS="--debug" && export _DEBUG="on"
[ "$1" = "--raw" ] && export SHOW_RAW="true"
set -o pipefail
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Import functions
CASJAYSDEVDIR="${CASJAYSDEVDIR:-/usr/local/share/CasjaysDev/scripts}"
SCRIPTSFUNCTDIR="${CASJAYSDEVDIR:-/usr/local/share/CasjaysDev/scripts}/functions"
SCRIPTSFUNCTFILE="${SCRIPTSAPPFUNCTFILE:-mgr-installers.bash}"
SCRIPTSFUNCTURL="${SCRIPTSAPPFUNCTURL:-https://github.com/$SCRIPTS_PREFIX/installer/raw/main/functions}"
connect_test() { curl -q -ILSsf --retry 1 -m 1 "https://1.1.1.1" | grep -iq 'server:*.cloudflare' || return 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -f "$PWD/$SCRIPTSFUNCTFILE" ]; then
  . "$PWD/$SCRIPTSFUNCTFILE"
elif [ -f "$SCRIPTSFUNCTDIR/$SCRIPTSFUNCTFILE" ]; then
  . "$SCRIPTSFUNCTDIR/$SCRIPTSFUNCTFILE"
elif connect_test; then
  curl -q -LSsf "$SCRIPTSFUNCTURL/$SCRIPTSFUNCTFILE" -o "/tmp/$SCRIPTSFUNCTFILE" || exit 1
  . "/tmp/$SCRIPTSFUNCTFILE"
else
  echo "Can not load the functions file: $SCRIPTSFUNCTDIR/$SCRIPTSFUNCTFILE" 1>&2
  exit 90
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Define extra functions
__sudo() { sudo -n true && eval sudo "$*" || eval "$*" || return 1; }
__sudo_root() { sudo -n true && ask_for_password true && eval sudo "$*" || return 1; }
__enable_ssl() { [ "$SERVER_SSL" = "yes" ] && [ "$SERVER_SSL" = "true" ] && return 0 || return 1; }
__ssl_certs() { [ -f "${1:-$SERVER_SSL_CRT}" ] && [ -f "${2:-SERVER_SSL_KEY}" ] && return 0 || return 1; }
__port_not_in_use() { [ -d "/etc/nginx/vhosts.d" ] && grep -wRsq "${1:-$SERVER_WEB_PORT}" /etc/nginx/vhosts.d && return 0 || return 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Define pre-install scripts
run_pre_install() {

  return ${?:-0}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Define custom functions

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Make sure the scripts repo is installed
scripts_check
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Repository variables
REPO="${DOCKERMGRREPO:-https://github.com/dockermgr}/cherokee"
APPVERSION="$(__appversion "$REPO/raw/${GIT_REPO_BRANCH:-main}/version.txt")"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Defaults variables
APPNAME="cherokee"
INSTDIR="$HOME/.local/share/CasjaysDev/dockermgr/cherokee"
APPDIR="$HOME/.local/share/srv/docker/cherokee"
DATADIR="$HOME/.local/share/srv/docker/cherokee/files"
DOCKERMGR_CONFIG_DIR="${DOCKERMGR_CONFIG_DIR:-$HOME/.config/myscripts/dockermgr}"
DOCKER_HOST_IP="${DOCKER_HOST_IP:-$(ip a show 'docker0' | grep -w 'inet' | awk -F'/' '{print $1}' | awk '{print $2}' | grep '^')}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Call the main function
dockermgr_install
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# trap the cleanup function
trap_exit
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Require a higher version
dockermgr_req_version "$APPVERSION"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Define folders
SERVER_DATA_DIR="$DATADIR/data"
SERVER_CONFIG_DIR="$DATADIR/config"
LOCAL_DATA_DIR="${LOCAL_DATA_DIR:-$SERVER_DATA_DIR}"
LOCAL_CONFIG_DIR="${LOCAL_CONFIG_DIR:-$SERVER_CONFIG_DIR}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# SSL Setup
SERVER_SSL_DIR="${SERVER_SSL_DIR:-/etc/ssl/CA/CasjaysDev}"
SERVER_SSL_CA="${SERVER_SSL_CA:-$SERVER_SSL_DIR/certs/ca.crt}"
SERVER_SSL_CRT="${SERVER_SSL_CRT:-$SERVER_SSL_DIR/certs/localhost.crt}"
SERVER_SSL_KEY="${SERVER_SSL_KEY:-$SERVER_SSL_DIR/private/localhost.key}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Setup variables
TZ="America/New_York"
SERVER_HOST_NAME=""
SERVER_DOMAIN_NAME=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# URL to container image [docker pull URL]
HUB_IMAGE_URL="casjaysdevdocker/cherokee"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# image tag [docker pull HUB_IMAGE_URL:tag]
HUB_IMAGE_TAG="latest"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set to true for container SSL support and set mount point IE: [/data/ssl/ca.crt]
SSL_ENABLED="false"
SSL_CA=""
SSL_KEY=""
SSL_CERT=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set to true for container to listen on LOCAL_IP only
LOCAL_IP="127.0.0.1"
SERVER_LISTEN_LOCAL="false"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set this to 0.0.0.0 to listen on all or specify addresses
DEFINE_LISTEN=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set this to the protocol the the container will use [http]
SERVER_PROTO="http"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Define additional variables [ myvar=var ]
ADDITION_ENV=""
ADDITION_ENV+=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Define additional devices [ /dev:/dev ]
ADDITION_DEVICES=""
ADDITION_DEVICES+=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Define additional mounts [ /dir:/dir ]
ADDITIONAL_MOUNTS="$LOCAL_CONFIG_DIR:/config:z $LOCAL_DATA_DIR:/data:z "
ADDITIONAL_MOUNTS+=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Define additional docker arguments - see docker run --help
CUSTOM_ARGUMENTS="--shm-size=256MB"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Add Add main port [port] or [port:port] - LISTEN will be added
SERVER_WEB_PORT="19005:80"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Same as SERVER_WEB_PORT and do not add SERVER_WEB_PORT here as it will be added
SERVER_PORT_ADD_CUSTOM="19006:9090"
SERVER_PORT_ADD_CUSTOM+=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Mount docker socket [pathToSocket]
DOCKER_SOCKET_ENABLED="false"
DOCKER_SOCKET_MOUNT="/var/run/docker.sock"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Show user info message
SERVER_MESSAGE_USER=""
SERVER_MESSAGE_PASS=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Show post install message
SERVER_MESSAGE_POST=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Setup nginx proxy variables
NGINX_SSL="true"
NGINX_HTTP="80"
NGINX_HTTPS="443"
NGINX_PROXY=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End of configuration
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# import global variables
if [ -f "$APPDIR/env.sh" ] && [ ! -f "$APPDIR/.env" ]; then
  cp -Rf "$APPDIR/env.sh" "$APPDIR/.env"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -f "$APPDIR/.env" ] && . "$APPDIR/.env"
[ -f "$DOCKERMGR_CONFIG_DIR/.env.sh" ] && . "$DOCKERMGR_CONFIG_DIR/.env.sh"
[ -f "$DOCKERMGR_CONFIG_DIR/env/$APPNAME" ] && . "$DOCKERMGR_CONFIG_DIR/env/$APPNAME"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -z "$HUB_IMAGE_URL" ] || [ "$HUB_IMAGE_URL" = "hello-world" ]; then
  printf_exit "Please set the url to the containers image"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Script options IE: --help
show_optvars "$@"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Requires root - no point in continuing
#sudoreq "$0 $*" # sudo required
#sudorun # sudo optional
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Do not update - add --force to overwrite
#installer_noupdate "$@"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Initialize the installer
dockermgr_run_init
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Run pre-install commands
execute "run_pre_install" "Running pre-installation commands"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Ensure directories exist
ensure_dirs
ensure_perms
mkdir -p "$LOCAL_DATA_DIR"
mkdir -p "$LOCAL_CONFIG_DIR"
chmod -Rf 777 "$APPDIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Variables - Do not change
SERVER_IP="${CURRIP4:-$LOCAL_IP}"
SERVER_PORT="${SERVER_WEB_PORT//:*/}"
SERVER_PROTO="${SERVER_PROTO:-http}"
SERVER_TIMEZONE="${TZ:-$TIMEZONE}"
SERVER_MESSAGE_POST="${SERVER_MESSAGE_POST:-}"
SERVER_LISTEN_ADDR="${DEFINE_LISTEN:-$SERVER_IP}"
DEFINE_LISTEN="${DEFINE_LISTEN:-$SERVER_LISTEN_ADDR}"
SERVER_DOMAIN_NAME="${SERVER_DOMAIN_NAME:-"$(hostname -d 2>/dev/null | grep '^' || echo 'local')"}"
SERVER_HOST_NAME="${SERVER_HOST_NAME:-$APPNAME.$SERVER_DOMAIN_NAME}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ -d "$DATADIR/ssl" ] && SERVER_SSL_DIR="$DATADIR/ssl" SERVER_SSL_CA
[ "$SERVER_LISTEN_LOCAL" = "true" ] && DEFINE_LISTEN="${LOCAL_IP:-127.0.0.1}"
[ "$DOCKER_SOCKET_ENABLED" = "true" ] && ADDITIONAL_MOUNTS+="$DOCKER_SOCKET_MOUNT:/var/run/docker.sock "
[ "$NGINX_SSL" = "true" ] && [ -n "$NGINX_HTTPS" ] && NGINX_PORT="${NGINX_HTTPS:-443}" || NGINX_PORT="${NGINX_HTTP:-80}"
if [ "$SSL_ENABLED" = "true" ]; then
  [ "$SERVER_PROTO" = "http" ] && NGINX_PROXY="https://$SERVER_LISTEN_ADDR:$SERVER_PORT" && SERVER_PROTO="${SERVER_PROTO:-https}"
  [ -f "$SERVER_SSL_CA/localhost.crt" ] && SERVER_SSL_CA="$SERVER_SSL_DIR/ca.crt" && ADDITIONAL_MOUNTS+="$SERVER_SSL_DIR/localhost.crt:${SSL_CA:-/data/ca.crt} "
  [ -f "$SERVER_SSL_DIR/localhost.key" ] && SERVER_SSL_KEY="$SERVER_SSL_DIR/localhost.key" && ADDITIONAL_MOUNTS+="$SERVER_SSL_DIR/localhost.key:${SSL_KEY:-/data/ssl.key} "
  [ -f "$SERVER_SSL_DIR/localhost.crt" ] && SERVER_SSL_CRT="$SERVER_SSL_DIR/localhost.crt" && ADDITIONAL_MOUNTS+="$SERVER_SSL_DIR/localhost.crt:${SSL_CERT:-/data/ssl.crt} "
else
  SERVER_PROTO="${SERVER_PROTO:-http}"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
NGINX_PROXY="${NGINX_PROXY:-$SERVER_PROTO://$SERVER_LISTEN_ADDR:$SERVER_PORT}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SET_ENV=""
for env in $ADDITION_ENV; do
  if [ -n "$env" ]; then
    SET_ENV+="--env $env "
  fi
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SET_DEV=""
for dev in $ADDITION_DEVICES; do
  if [ -n "$dev" ]; then
    echo "$dev" | grep -q ':' || dev="$dev:$dev"
    SET_DEV+="--device $dev "
  fi
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SET_MNT=""
for mnt in $ADDITIONAL_MOUNTS; do
  if [ -n "$mnt" ]; then
    echo "$mnt" | grep -q ':' || port="$mnt:$mnt"
    SET_MNT+="--volume $mnt "
  fi
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SET_PORT=""
for port in $SERVER_WEB_PORT $SERVER_PORT_ADD_CUSTOM; do
  if [ -n "$port" ]; then
    echo "$port" | grep -q ':' || port="$port:$port"
    SET_PORT+="--publish $DEFINE_LISTEN:$port "
  fi
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Clone/update the repo
if __am_i_online; then
  if [ -d "$INSTDIR/.git" ]; then
    message="Updating $APPNAME configurations"
    execute "git_update $INSTDIR" "$message"
  else
    message="Installing $APPNAME configurations"
    execute "git_clone $REPO $INSTDIR" "$message"
  fi
  # exit on fail
  failexitcode $? "$message has failed"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copy over data files - keep the same stucture as -v dataDir/mnt:/mount
if [ -d "$INSTDIR/dataDir" ] && [ ! -f "$DATADIR/.installed" ]; then
  printf_yellow "Copying files to $DATADIR"
  cp -Rf "$INSTDIR/dataDir/." "$DATADIR/"
  find "$DATADIR" -name ".gitkeep" -type f -exec rm -rf {} \; &>/dev/null
fi
if [ -f "$DATADIR/.installed" ]; then
  date +'Updated on %Y-%m-%d at %H:%M' >"$DATADIR/.installed"
else
  date +'installed on %Y-%m-%d at %H:%M' >"$DATADIR/.installed"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Main progam
if cmd_exists docker-compose && [ -f "$INSTDIR/docker-compose.yml" ]; then
  printf_yellow "Installing containers using docker-compose"
  sed -i 's|REPLACE_DATADIR|'$DATADIR'' "$INSTDIR/docker-compose.yml"
  if cd "$INSTDIR"; then
    __sudo docker-compose pull &>/dev/null
    __sudo docker-compose up -d &>/dev/null
  fi
else
  __sudo docker stop "$APPNAME" &>/dev/null
  __sudo docker rm -f "$APPNAME" &>/dev/null
  printf_cyan "Updating the image from $HUB_IMAGE_URL"
  __sudo docker pull "$HUB_IMAGE_URL" &>/dev/null
  __sudo docker run -d \
    --privileged \
    --restart=always \
    --name="$APPNAME" \
    --hostname "$SERVER_HOST_NAME" $CUSTOM_ARGUMENTS \
    -e TZ="$SERVER_TIMEZONE" \
    -e TIMEZONE="$SERVER_TIMEZONE" $SET_ENV $SET_DEV $SET_MNT $SET_PORT \
    "$HUB_IMAGE_URL:${HUB_IMAGE_TAG:-latest}" 1>/dev/null 2>"${TMP:-/tmp}/$APPNAME.err.log" &&
    rm -Rf "${TMP:-/tmp}/$APPNAME.err.log"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Install nginx proxy
if [ ! -f "/etc/nginx/vhosts.d/$SERVER_HOST_NAME.conf" ] && [ -f "$INSTDIR/nginx/proxy.conf" ]; then
  cp -f "$INSTDIR/nginx/proxy.conf" "/tmp/$$.$SERVER_HOST_NAME.conf"
  sed -i "s|REPLACE_APPNAME|$APPNAME|g" "/tmp/$$.$SERVER_HOST_NAME.conf" &>/dev/null
  sed -i "s|REPLACE_NGINX_PORT|$NGINX_PORT|g" "/tmp/$$.$SERVER_HOST_NAME.conf" &>/dev/null
  sed -i "s|REPLACE_SERVER_PORT|$SERVER_PORT|g" "/tmp/$$.$SERVER_HOST_NAME.conf" &>/dev/null
  sed -i "s|REPLACE_SERVER_HOST|$SERVER_DOMAIN_NAME|g" "/tmp/$$.$SERVER_HOST_NAME.conf" &>/dev/null
  sed -i "s|REPLACE_SERVER_PROXY|$NGINX_PROXY|g" "/tmp/$$.$SERVER_HOST_NAME.conf" &>/dev/null
  if [ -d "/etc/nginx/vhosts.d" ]; then
    __sudo_root mv -f "/tmp/$$.$SERVER_HOST_NAME.conf" "/etc/nginx/vhosts.d/$SERVER_HOST_NAME.conf"
    [ -f "/etc/nginx/vhosts.d/$SERVER_HOST_NAME.conf" ] && printf_green "[ ??? ] Copying the nginx configuration"
    systemctl status nginx | grep -q enabled &>/dev/null && __sudo_root systemctl reload nginx &>/dev/null
  fi
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# run post install scripts
run_postinst() {
  dockermgr_run_post
  [ -w "/etc/hosts" ] || return 0
  if ! grep -sq "$SERVER_HOST_NAME" "/etc/hosts"; then
    if [ -n "$SERVER_PORT" ]; then
      if [ $(hostname -d 2>/dev/null | grep '^') = 'local' ]; then
        echo "$SERVER_LISTEN_ADDR     $APPNAME.local" | sudo tee -a "/etc/hosts" &>/dev/null
      else
        echo "$SERVER_LISTEN_ADDR     $APPNAME.local" | sudo tee -a "/etc/hosts" &>/dev/null
        echo "$SERVER_LISTEN_ADDR     $SERVER_HOST_NAME" | sudo tee -a "/etc/hosts" &>/dev/null
      fi
    fi
  fi
}
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# run post install scripts
execute "run_postinst" "Running post install scripts"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Output post install message

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# create version file
dockermgr_install_version
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# run exit function
if docker ps -a | grep -qs "$APPNAME"; then
  printf_cyan "$APPNAME has been installed to $INSTDIR"
  printf_yellow "The DATADIR is in $DATADIR"
  [ -z "$SERVER_PORT" ] && printf_yellow "This container does not have a web interface"
  [ -n "$SERVER_LISTEN_ADDR" ] && [ -n "$SERVER_PORT" ] && printf_yellow "Service is running on: $SERVER_LISTEN_ADDR:$SERVER_PORT"
  [ -n "$SERVER_LISTEN_ADDR" ] && [ -n "$SERVER_PORT" ] && printf_yellow "and should be available at: $NGINX_PROXY or $SERVER_PROTO//$SERVER_HOST_NAME:$SERVER_PORT"
  [ -n "$SERVER_MESSAGE_USER" ] && printf_cyan "Username is:  $SERVER_MESSAGE_USER"
  [ -n "$SERVER_MESSAGE_PASS" ] && printf_purple "Password is:  $SERVER_MESSAGE_PASS"
  [ -n "$SERVER_MESSAGE_POST" ] && printf_green "$SERVER_MESSAGE_POST"
else
  printf_error "Something seems to have gone wrong with the install"
  printf '\n\n'
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# exit
run_exit &>/dev/null
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# lets exit with code
exit ${exitCode:-$?}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# end
