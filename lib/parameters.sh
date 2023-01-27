# Take parameters and direct them to functionality without explicit bindings.

function private_returnMostSerious
{
  local currentValue="$1"
  local newValue="$2"

  # This looks a little conveluted, but it's pretty simple. The premise is that 0 is success, 1 is the worst error you can have. And the larger the number, the less fatal it is. This assumption may not hold up across different tools, but it's easy to adhere to internally.

  if [ "$currentValue"  == '1' ]; then
    echo 1
  elif [ "$newValue" -gt 0 ]; then
    if [ "$currentValue" -gt 0 ]; then
      if [ "$newValue" -lt "$currentValue" ]; then
        echo "$newValue"
      else
        echo "$currentValue"
      fi
    else
      echo "$newValue"
    fi
  else
    echo "$currentValue"
  fi
}

function private_abstractDirection_projectWide
{
  local functionName
  local input
  local returnValue=0

  functionName="$1"
  input="$2"

  while read -r potentialWorkspace; do
    if [ "$(private_getType "$(pwd)/$potentialWorkspace")" == 'workspace' ]; then
      echo "Entering workspace $potentialWorkspace..."

      if cd "$potentialWorkspace"; then
        # shellcheck disable=SC2012
        ls -1 | private_abstractDirection "$functionName" "$input"

        returnValue="$(private_returnMostSerious "$returnValue" "$?")"
        cd ..
      fi
    else
      echo "Skipping \"$potentialWorkspace\"."
    fi
  done < <(ls -1)

  return "$returnValue"
}

function private_abstractDirection
{
  local functionName
  local input
  local extraOptions
  local type

  functionName="$1"
  input="$2"
  extraOptions="$3"
  type="$(private_getType "$(pwd)")"

  case "$type" in
    "project")
      if [ "$extraOptions" == 'noProject' ]; then
        echo "This feature doesn't make sense in a project directory. Try an individual workspace." >&2
        return 1
      else
        private_abstractDirection_projectWide "$functionName" "$input"
        return "$?"
      fi
    ;;
    "workspace")
      if [ "$input" != '' ]; then
        "$functionName" "$input"
        return "$?"
      else
        if private_stdinIsTerminal; then
          # shellcheck disable=SC2012
          ls -1 | private_abstractDirection "$functionName" "$input"
          return "$?"
        else
          returnValue=0
          while read -r entry; do
            "$functionName" "$entry"

            returnValue="$(private_returnMostSerious "$returnValue" "$?")"
          done

          return "$returnValue"
        fi
      fi
    ;;
    *)
      echo "$(pwd)($type) doesn't appear to be a project, or workspace. Can't continue." >&2
      return 1
    ;;
  esac
}


function private_indent
{
  indentString='  '

  sed "s/^/$indentString/g"
}

function private_isTerminal
{
  channel="$1"

  [ -t "$channel" ]
  return "$?"
}

function private_stdinIsTerminal
{
  private_isTerminal 0
  return "$?"
}

function private_stdoutIsTerminal
{
  private_isTerminal 1
  return "$?"
}

function private_stderrIsTerminal
{
  private_isTerminal 2
  return "$?"
}


function help # Show this help.
{
  echo "Valid commands are"
  echo
  grep "^function" "$duseLib/"*sh | grep -v '\(private_\)' | sed 's/^.*:function *//g; s/ # /\^/g; s/^/--/g' | column -t -s '^'
}

##### Stuff for handling parameters.
function private_showCommands
{
  grep "^function" "$duseLib/"*sh | awk '{ print $2 }' | grep -v '\(private_\)'
}

function private_isValidCommand
{
  private_showCommands | grep -q "^$1$"
  return "$?"
}

function private_getCommandFromArg
{
  if [ "${1::2}" == '--' ]; then
    command="${1:2}"
    if private_isValidCommand "$command"; then
      echo "$command"
    else
      return 1
    fi
  else
    return 1
  fi
}

