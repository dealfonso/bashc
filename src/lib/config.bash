# Reads a configuration file and set its variables (removes comments, blank lines, trailing spaces, etc. and
# then reads KEY=VALUE settings)
function bashc.Xreadconf() {
  local _CONF_FILE=$1
  local _CURRENT_SECTION
  local _TXT_CONF
  local _CURRENT_KEY _CURRENT_VALUE

  # If the config file does not exist return failure
  if [ ! -e "$_CONF_FILE" ]; then
    return 1
  fi

  # First we read the config file
  _TXT_CONF="$(cat "$_CONF_FILE" | sed 's/#.*//g' | sed 's/^[ \t]*//g' | sed 's/[ \t]*$//g' | sed '/^$/d')"

  # Lets read the lines
  while read L; do
    if [[ "$L" =~ ^\[.*\]$ ]]; then
      # If we are reading a section, lets see if it is applicable to us
      _CURRENT_SECTION="${L:1:-1}"
    else
      IFS='=' read _CURRENT_KEY _CURRENT_VALUE <<< "$L"
      _CURRENT_VALUE="$(echo "$_CURRENT_VALUE" | envsubst)"
      read -d '\0' "$_CURRENT_KEY" <<< "${_CURRENT_VALUE}"
    fi
  done <<< "$_TXT_CONF"
  return 0
}

function bashc.readconf() {
  local _CONF_FILE=$1
  local _TXT_CONF
  local _CURRENT_KEY _CURRENT_VALUE
  local L
  local _VALID_KEYS=( )

  # Now read the valid keys
  shift
  bashc.list_append _VALID_KEYS "$@"

  # If the config file does not exist return failure
  if [ ! -e "$_CONF_FILE" ]; then
    return 255
  fi

  # First we read the config file
  _TXT_CONF="$(cat "$_CONF_FILE" | sed 's/^[ \t]*//g' | sed 's/[ \t]*$//g' | sed '/^$/d')"

  local _EXITCODE=0
  # Let's read the lines
  while read L; do
    if [[ "$L" =~ ^[[:blank:]]*[A-Za-z_][A-Za-z0-9_]*= ]]; then
      IFS='=' read _CURRENT_KEY _CURRENT_VALUE <<< "$L"
      _CURRENT_VALUE="$(bashc.cleanvalue "$_CURRENT_VALUE")"
      if [ $? -ne 0 ]; then
        p_warning "ignoring invalid value for key $_CURRENT_KEY"
        _EXITCODE=$((_EXITCODE+1))
      else
        _CURRENT_VALUE="$(echo "$_CURRENT_VALUE" | envsubst)"
        if [ ${#_VALID_KEYS[@]} -eq 0 ] || bashc.in_list _VALID_KEYS $_CURRENT_KEY; then
          p_debug "$_CURRENT_KEY value acquired"
          read -d '\0' "$_CURRENT_KEY" <<< "${_CURRENT_VALUE}"
        else
          p_warning "$_CURRENT_KEY ignored"
        fi
        p_debug "$_CURRENT_KEY=$_CURRENT_VALUE"
      fi
    else
      if [ "${L%%\#*}" != "" ]; then
        p_error "invalid configuration line '$L'"
        _EXITCODE=$((_EXITCODE+1))
      fi
    fi
    if ((_EXITCODE>=254)); then
      p_error "too errors to consider this file"
      return $_EXITCODE
    fi
  done <<< "$_TXT_CONF"
  return $_EXITCODE
}

function bashc.cleanvalue() {
  local A="$1"
  local VALUE=
  local STILL_WORKING="true"
  while [ "$STILL_WORKING" == "true" ]; do
    STILL_WORKING="false"
    if [[ "$A" =~ ^[^\#\"\'[:space:]]+ ]]; then
      VALUE="${VALUE}${BASH_REMATCH[0]}"
      A="${A:${#BASH_REMATCH[0]}}"
      STILL_WORKING="true"
    fi
    if [ "$STILL_WORKING" == "false" ] && [[ "$A" =~ ^\"([^\"\\]*(\\.[^\"\\]*)*)\" ]]; then
      VALUE="${VALUE}${BASH_REMATCH[1]}"
      A="${A:${#BASH_REMATCH[0]}}"
      STILL_WORKING="true"
    fi
    if [ "$STILL_WORKING" == "false" ] && [[ "$A" =~ ^\'([^\']*)\' ]]; then
      VALUE="${VALUE}${BASH_REMATCH[1]}"
      A="${A:${#BASH_REMATCH[0]}}"
      STILL_WORKING="true"
    fi
  done
  echo "$VALUE"
  A="$(bashc.trim "$A")"
  if [ "${A:0:1}" == "#" ]; then
    return 0
  fi
  if [ "$A" != "" ]; then
    return 1
  fi
  return 0
}