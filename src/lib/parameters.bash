
_BASHC_current_param_id=-1
_BASHC_COMMANDLINE_ARRAY=( )
function bashc.parameters_start() {
  _BASHC_current_param_id=-1
}

function bashc.parameters_next() {
  _BASHC_current_param_id=$((_BASHC_current_param_id+1))
  if ((_BASHC_current_param_id<${#_BASHC_COMMANDLINE_ARRAY[@]})); then
    return 0
  fi
  return 1
}

function bashc.parameters_end() {
  if ((_BASHC_current_param_id<${#_BASHC_COMMANDLINE_ARRAY[@]})); then
    return 1
  fi
  return 0
}

function bashc.parameters_current() {
  printf "%s" "${_BASHC_COMMANDLINE_ARRAY[$_BASHC_current_param_id]}"
}

function bashc.parameter_parse_commandline() {
  local n=0
  local f
  while [ $# -gt 0 ]; do
      if [ "${1:0:1}" == "-" -a "${1:1:1}" != "-" -a "${1:1:1}" != "" ]; then
          for f in $(echo "${1:1}" | sed 's/\(.\)/-\1 /g' ); do
              _BASHC_COMMANDLINE_ARRAY[$n]="$f"
              n=$(($n+1))
          done
      else
          _BASHC_COMMANDLINE_ARRAY[$n]="$1"
          n=$(($n+1))
      fi
      shift
  done
  return $n
}

