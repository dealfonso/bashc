_MUTED_EXPRESSIONS=()

function p_mute() {
  _MUTED_EXPRESSIONS+=("${1// /[[:space:]]}")
}

function p_errfile() {
  local i
  local E
  for ((i=0;i<${#_MUTED_EXPRESSIONS[@]};i=i+1)); do
    E="${_MUTED_EXPRESSIONS[$i]}"
    if [[ "$1" =~ ^$E ]]; then
      return 0
    fi
  done

  if [ "$LOGFILE" == "" ]; then
    echo "$@" >&2
  else
    touch -f "$LOGFILE"
    if [ $? -eq 0 ]; then
      echo "$@" >> "$LOGFILE"
    fi
  fi
}

function p_error() {
  local O_STR="[ERROR] $LOGGER $(date +%Y.%m.%d-%X) $@"
  p_errfile "$O_STR"
}

function p_warning() {
  local O_STR="[WARNING] $LOGGER $(date +%Y.%m.%d-%X) $@"
  p_errfile "$O_STR"
}

function p_info() {
  if [ "$VERBOSE" == "true" -o "$DEBUG" == "true" ]; then
    local O_STR="[INFO] $LOGGER $(date +%Y.%m.%d-%X) $@"
    p_errfile "$O_STR"
  fi
}

function p_out() {
  if [ "$QUIET" != "true" ]; then
    #while read; do
      echo "$@"
    #done <<< "$@"
  fi
}

function p_debug() {
  local L
  if [ "$DEBUG" == "true" ]; then
    local TS="$(date +%Y.%m.%d-%X)"
    p_errfile "[DEBUG] $LOGGER $TS $@"
    #while read; do
    #  p_errfile "[DEBUG] $LOGGER $TS $REPLY"
    #done <<< "$@"
  fi
}

function bashc.set_logger() {
  if [ "$1" != "" ]; then
    LOGGER="[$1]"
  else
    LOGGER=
  fi
}

_OLD_LOGGER=

function bashc.push_logger() {
  _OLD_LOGGER="$LOGGER"
  LOGGER="$LOGGER[$1]"
}

function bashc.pop_logger() {
  LOGGER="$_OLD_LOGGER"
}

function bashc.finalize() {
  # Finalizes the execution of the this script and shows an error (if provided)
  local ERR=$1
  shift
  local COMMENT=$@
  [ "$ERR" == "" ] && ERR=0
  [ "$COMMENT" != "" ] && p_error "$COMMENT"
  exit $ERR
}