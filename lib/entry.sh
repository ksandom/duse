# For managing entries within a workspace.

function private_whichSource
{
  local contextName
  local contextPath
  local linkSource

  contextName="$1"
  contextPath="$contextHome/$contextName"
  linkSource="$2"

  for source in "$contextPath/sources"/*; do
    resolvedSource="$(cat "$source")"
    if [ "$resolvedSource" == "$linkSource" ]; then
      basename "$source"
      return 0
    fi
  done
  return 1
}

function private_getEntryType
{
  local contextName
  local contextPath
  local entry
  local linkSource

  contextName="$1"
  contextPath="$contextHome/$contextName"
  entry="$2"
  linkSource="$(dirname "$(readlink "$entry")")"


  if [ -L "$entry" ]; then
    if [ "$linkSource" == "$(private_getCache "$contextName")/$contextName" ]; then
      echo "Cached"
    elif private_whichSource "$contextName" "$linkSource" >/dev/null; then
      echo "Uncached"
    else
      echo "Invalid link"
      return 1
    fi
  elif [ -f "$entry" ]; then # Directly placed files are not managed by duse.
    echo "Invalid file"
    return 1
  elif [ -d "$entry" ]; then # Directly placed directories are not managed by duse.
    echo "Invalid directory"
    return 1
  fi
}

# function private_entryInCache
# {
#   local context
#   local entry
#
#   context="$1"
#   entry="$2"
#
#   # TODO This isn't finished.
#   # Currently unused.
#   if [ -e "" ]; then
#     true
#   else
#     return 1
#   fi
# }

function private_entryInSource
{
  local context
  local entry

  context="$1"
  entry="$2"

  if sources="$(private_getSourcesForThing "$entry" 2>/dev/null)"; then
    if [ "$(echo "$sources" | wc -l)" -gt 1 ]; then
      echo "$sources"
    fi
  else
    return 1
  fi
}

function private_isAvailable
{
  local thing
  local origin

  thing="$1"
  origin="$(readlink "$thing")"

  if [ -e "$origin" ]; then
    echo "Yes"
    return 0
  else
    echo "No"
    return 1
  fi
}

function list # List the items in the current workspace (current directory), and their state.
{
  if [ ! -e '.duse/context' ]; then
    echo "This does not appear to be a workspace." >&2
    return 1
  fi

  context="$(cat '.duse/context')"
  if private_stdoutIsTerminal; then
    separator='^'
  else
    separator=','
  fi
  headings="Entry${separator}Accessible${separator}Type${separator}Location"

  {
    # Compile together the output.
    echo "$headings"
    while read -r entry; do
      entryType="$(private_getEntryType "$context" "$entry")"

      if [ "${entryType::7}" != 'Invalid' ]; then
        entryAccessible="$(private_isAvailable "$entry")"
        entryLocation="$(private_whichSource "$context" "$(dirname "$(readlink "$entry")")")"
      else
        entryAccessible='Yes?'
        entryLocation='Not managed by duse.'
      fi

      echo "$entry$separator$entryAccessible$separator$entryType$separator$entryLocation"
    done < <(ls -1)
  } | column -t -s '^'
}

function private_getSourcesForThing
{
  local thing

  thing="$1"

  if [ ! -e '.duse/context' ]; then
    echo "This does not appear to be a workspace." >&2
    return 1
  fi

  contextName="$(cat '.duse/context')"
  sourcesPath="$contextHome/$contextName/sources"


  while read -r source; do
    thingPath="$(cat "$sourcesPath/$source")/$thing"
    if [ -e "$thingPath" ]; then
      echo "$thingPath"
    fi
  done < <(private_getSources "$contextName")
}

function private_getSourceForThing
{
  local thing

  thing="$1"

  if ! sources="$(private_getSourcesForThing "$thing")"; then
    return 1
  fi

  numberOfSources="$(echo "$sources" | wc -l)"

  if [ "$numberOfSources" -eq 0 ]; then
    echo "There don't appear to be any sources for this item. Typo?" >&2
    return 1
  elif [ "$numberOfSources" -gt 1 ]; then
    echo "There appear to be multiple sources for \"$thing\" in \"$(pwd)\":" >&2
    # shellcheck disable=SC2001
    echo "$sources" | sed 's/^/  /g' >&2
    echo -e "\nWill assume the first. But you should definitely fix this. You don't have a single source of truth." >&2
    echo "$sources" | head -n 1
    return "$warnExitCode"
  else
    echo "$sources"
  fi
}
