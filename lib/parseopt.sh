
# parseopt gives you 9 parameter triggers.

function parseopt.match() {
  local match="$1"; shift;
  for param; do [[ "$match" == "$param" ]] && return 0; done;
  return 1;
}

function parseopt.keys() {
  eval echo \${!$1[@]}\;;
}

function parseopt.set() {
  local destination=$1 assignment; shift;
  for assignment; do
    local key="${assignment/=*/}";
    local value="${assignment/*=/}"
    printf -v ${destination}$key %s "$value"
  done;
}

function parseopt.get() {
  local source=$1 name; shift;
  for name; do
    eval echo \${$source[$name]}\;;
  done;
}

function parseopt.content() {
  eval echo \${$1[@]};
}

function parseopt.begin() {
  parseopt.set $1 [INDEX]=1 [SUBINDEX]=0;
}

function parseopt.dump() { 

  local name;
  for name in $(parseopt.keys $1); do
    printf '%s: %s\n' $name "$(parseopt.get $1 $name)";
  done

}

function parseopt() {

  # PARAMETERS: $1 and $2 are names of associative arrays.
  # the output of the function will be placed in $2
  # the state of the parsing is saved in $1.

  # the remaining parameters are parsed. the number of items parsed are
  # returned in 2[SIZE].

  # the sections on first order methods which are commented out, parse the
  # parameter as an option with a value regardless of assignment operators.
  # they are not desirable features for the maintainer.
  
  local PO_STATE=$1 RCRD_PARAMETER=$2; shift 2;

  local INDEX=$PO_STATE[INDEX] SUBINDEX=$PO_STATE[SUBINDEX];
  local PARAMETER=BASH_REMATCH[1] VALUE=BASH_REMATCH[2]
    
  parseopt.set $RCRD_PARAMETER [BRANCH]=0 [INDEX]=${!INDEX} \
    [INPUT]="$1" [SUBINDEX]=0 [VALUE]='' [SHORT]=0 [SIZE]=1;

  # 1 test for long option
  [[ "$1" =~ ^--([a-zA-Z-]*[a-zA-Z])$ ]] && {
    parseopt.set $RCRD_PARAMETER [BRANCH]=1 [PARAMETER]="${!PARAMETER}";
    parseopt.match "${!PARAMETER}" $(parseopt.get $PO_STATE LONG) || return 11;
#    parseopt.match "${!PARAMETER}" $(parseopt.get $PO_STATE SETTINGS) && {
#      parseopt.set $RCRD_PARAMETER [VALUE]="$2" [SIZE]=2;
#      let $INDEX++;
#    };
    let $INDEX++;
    return 0;
  }

  # 2 test for long option with setting specification
  [[ "$1" =~ ^--([a-zA-Z-]*[a-zA-Z]):$ ]] && {
    parseopt.set $RCRD_PARAMETER [BRANCH]=2 [PARAMETER]="${!PARAMETER}" \
      [VALUE]="$2" [SIZE]=2;
    parseopt.match "${!PARAMETER}" $(parseopt.get $PO_STATE LONG) || return 21;
    parseopt.match "${!PARAMETER}" $(parseopt.get $PO_STATE SETTINGS) || \
      return 22;
    let $INDEX+=2;
    return 0;
  }

  # 3 test for long option with setting specification and data
  [[ "$1" =~ ^--([a-zA-Z-]*[a-zA-Z])[:=](.*)$ ]] && {
    parseopt.set $RCRD_PARAMETER [BRANCH]=3 [PARAMETER]="${!PARAMETER}" \
      [VALUE]="${!VALUE}";
    parseopt.match "${!PARAMETER}" $(parseopt.get $PO_STATE LONG) || return 31;
    parseopt.match "${!PARAMETER}" $(parseopt.get $PO_STATE SETTINGS) || \
      return 32;
    let $INDEX++;
    return 0;
  }

  # 4 test for short option
  [[ "$1" =~ ^-([a-zA-Z])$ ]] && {
    parseopt.set $RCRD_PARAMETER [BRANCH]=4 [PARAMETER]="${!PARAMETER}" \
      [SHORT]=1;
    parseopt.match "${!PARAMETER}" $(parseopt.get $PO_STATE SHORT) || return 41;
#    parseopt.match "${!PARAMETER}" $(parseopt.get $PO_STATE SETTINGS) && {
#      parseopt.set $RCRD_PARAMETER [VALUE]="$2" [SIZE]=2;
#      let $INDEX++;
#    };
    let $INDEX++;
    return 0;
  }

  # 5 test for short option with setting
  [[ "$1" =~ ^-([a-zA-Z]):$ ]] && {
    parseopt.set $RCRD_PARAMETER [BRANCH]=5 [PARAMETER]="${!PARAMETER}" \
      [VALUE]="$2" [SHORT]=1 [SIZE]=2;
    parseopt.match "${!PARAMETER}" $(parseopt.get $PO_STATE SHORT) || return 51;
    parseopt.match "${!PARAMETER}" $(parseopt.get $PO_STATE SETTINGS) || \
      return 52;
    let $INDEX+=2;
    return 0;
  }

  # 6 test for short option with setting and data
  [[ "$1" =~ ^-([a-zA-Z])[:=](.+)$ ]] && {
    parseopt.set $RCRD_PARAMETER [BRANCH]=6 [PARAMETER]="${!PARAMETER}" \
      [VALUE]="${!VALUE}" [SHORT]=1;
    parseopt.match "${!PARAMETER}" $(parseopt.get $PO_STATE SHORT) || return 61;
    parseopt.match "${!PARAMETER}" $(parseopt.get $PO_STATE SETTINGS) || \
      return 62;
    let $INDEX++;
    return 0;
  }
  
  # 7 test for multiple short option
  [[ "$1" =~ ^-([a-zA-Z]+)$ ]] && {
    local match=${BASH_REMATCH[1]};
    local -i length=${#match};
    local C=${match:${!SUBINDEX}:1};
    parseopt.set $RCRD_PARAMETER [BRANCH]=7 [PARAMETER]="$C" [INDEX]=${!INDEX} \
      [SUBINDEX]=${!SUBINDEX} [SHORT]=1;
    parseopt.match "${C}" $(parseopt.get $PO_STATE SHORT) || return 71;
    let $SUBINDEX++;
    if (( $SUBINDEX == length )); then
      eval $RCRD_PARAMETER[SIZE]=1;
#      parseopt.match "${C}" $(parseopt.get $PO_STATE SETTINGS) && {
#        parseopt.set $RCRD_PARAMETER [VALUE]="$2" [SIZE]=2;
#        let $INDEX++;
#        true
#      } 
      let $INDEX++;
      let $SUBINDEX=0;
    else
      eval $RCRD_PARAMETER[SIZE]=0;
      parseopt.match "${C}" $(parseopt.get $PO_STATE SETTINGS) && {
        parseopt.match "$C" $(parseopt.get $PO_STATE HAS_DEFAULT) || return 72;
      } 
    fi;
    return 0;
  }

  # 8 test for multiple short option with setting
  [[ "$1" =~ ^-([a-zA-Z]+):$ ]] && {
    local match=${BASH_REMATCH[1]};
    local -i length=${#match};
    local C=${match:${!SUBINDEX}:1};
    parseopt.set $RCRD_PARAMETER [BRANCH]=8 [PARAMETER]="$C" [INDEX]=${!INDEX} \
      [SUBINDEX]=${!SUBINDEX} [SHORT]=1;
    parseopt.match "${C}" $(parseopt.get $PO_STATE SHORT) || return 81;
    let $SUBINDEX++;
    if (( $SUBINDEX == length )); then
      eval $RCRD_PARAMETER[VALUE]="$2";
      eval $RCRD_PARAMETER[SIZE]=2;
      parseopt.match "${C}" $(parseopt.get $PO_STATE SETTINGS) && {
        parseopt.set $RCRD_PARAMETER [VALUE]="$2" [SIZE]=2;
        let $INDEX++;
      } 
      let $INDEX++;
      let $SUBINDEX=0;
    else
      eval $RCRD_PARAMETER[SIZE]=0;
      parseopt.match "${C}" $(parseopt.get $PO_STATE SETTINGS) && {
        parseopt.match "$C" $(parseopt.get $PO_STATE HAS_DEFAULT) || return 82;
      } 
    fi;
    return 0;
  }

  # 9 test for multiple short option with setting and data
  [[ "$1" =~ ^-([a-zA-Z]+)[:=](.+)$ ]] && {
    local match=${BASH_REMATCH[1]};
    local -i length=${#match};
    local C=${match:${!SUBINDEX}:1};
    parseopt.set $RCRD_PARAMETER [BRANCH]=9 [PARAMETER]="$C" [INDEX]=${!INDEX} \
      [SUBINDEX]=${!SUBINDEX} [SHORT]=1;
    parseopt.match "${C}" $(parseopt.get $PO_STATE SHORT) || return 91;
    let $SUBINDEX++;
    if (( $SUBINDEX == length )); then
      eval $RCRD_PARAMETER[VALUE]="${BASH_REMATCH[2]}";
      eval $RCRD_PARAMETER[SIZE]=1;
      parseopt.match "${C}" $(parseopt.get $PO_STATE SETTINGS) && {
        parseopt.set $RCRD_PARAMETER [VALUE]="${!VALUE}";
      } 
      let $INDEX++;
      let $SUBINDEX=0;
    else
      eval $RCRD_PARAMETER[SIZE]=0;
      parseopt.match "${C}" $(parseopt.get $PO_STATE SETTINGS) && {
        parseopt.match "$C" $(parseopt.get $PO_STATE HAS_DEFAULT) || return 92;
      } 
    fi;
    return 0;
  }
  
  return 1;

}

# end option parsing utilities section

(( PO_DEBUG )) && {

  declare -A CONFIG;

  parseopt.set CONFIG [LONG]="get-theatre help"
  parseopt.set CONFIG [SHORT]="H T L Q R d e f h i l l p q z";
  parseopt.set CONFIG [SETTINGS]="H Q T e i l q z"
  
  # options that have a default can be specified with or without assignment
  # operators. an option listed here has no effect if it is not listed in
  # CONFIG[SETTINGS]
  parseopt.set CONFIG [HAS_DEFAULT]="H T"

  parseopt.begin CONFIG;

  while (( $# )); do
    declare -A parse;
    parseopt CONFIG parse "$@" || {
      echo "error: parameter #${parse[INDEX]} didn't parse";
      parseopt.dump parse;
      exit 1;
    }
    parseopt.dump parse;
    shift ${parse[SIZE]}
  done;

  declare -p CONFIG

}

