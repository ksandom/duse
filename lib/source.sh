function private_sourceName # Gives us a unique name based on a file path.
{
  local sourcePath

  sourcePath="$1"

  # shellcheck disable=SC2001
  echo "$sourcePath" | sed "s#\(/\| \)#_#g"
}

function private_sourceExists
{
  local contextName
  local sourceVanillaPath
  local sourcePath

  contextName="$1"
  sourceVanillaPath="$2"
  sourcePath="$(private_sourcePath "$contextName" "$sourceVanillaPath")"

  if ! private_contextExists "$contextName"; then
    echo "Context \"$contextName\" not found." >&2
    return 1
  fi

  if [ ! -e "$sourcePath" ]; then
    return 1
  else
    return 0
  fi
}

function private_getSources
{
  local contextName
  local sourcesPath

  contextName="$1"
  sourcesPath="$contextHome/$contextName/sources"

  if [ ! -e "$sourcesPath" ]; then
    echo "It looks like the current context doesn't have any sources defined yet." >&2
    return 1
  fi

  ls -1 "$sourcesPath"
}

function private_sourcePath
{
  local contextName
  local sourceVanillaPath
  local sourcesPath
  local sourceVanillaName
  local sourceName

  contextName="$1"
  sourceVanillaPath="$2"
  sourcesPath="$contextHome/$contextName/sources"
  sourceVanillaName="$3"

  if [ "$sourceVanillaName" == '' ]; then
    sourceName="$(private_sourceName "$sourceVanillaPath")"
  else
    sourceName="$(private_sourceName "$sourceVanillaName")"
  fi

  echo "$sourcesPath/$sourceName"
}

function addSource # 01: Add a source to a context. --addsource contextName sourcePath [sourceName]
{
  local contextName
  local contextPath
  local sourcesPath
  local sourceVanillaPath
  local fullSourcePath
  local sourceName
  local sourcePath

  contextName="$1"
  contextPath="$contextHome/$contextName"
  sourcesPath="$contextHome/$contextName/sources"
  sourceVanillaPath="$2"
  fullSourcePath="$(realpath "$2")"
  sourceName="$3"
  sourcePath="$(private_sourcePath "$contextName" "$sourceVanillaPath" "$sourceName")"

  if ! private_contextExists "$contextName"; then
    echo "Context \"$contextName\" not found." >&2
    return 1
  fi

  # TODO Test for the sourcePath existing on disk.

  if private_sourceExists "$contextName" "$sourceVanillaPath";  then
    echo "Source \"$sourceVanillaPath\" already exists within context \"$contextName\"." >&2
    return 1
  fi

  mkdir -p "$sourcesPath"
  echo "$fullSourcePath" > "$sourcePath"
}

function deleteSource # Delete a source from a context. --deleteSource contextName sourcePath
{
  local contextName
  local contextPath
  local sourcesPath
  local sourceVanillaPath
  local fullSourcePath
  local sourcePath

  contextName="$1"
  contextPath="$contextHome/$contextName"
  sourcesPath="$contextHome/$contextName/sources"
  sourceVanillaPath="$2"
  fullSourcePath="$(realpath "$2")"
  sourcePath="$(private_sourcePath "$contextName" "$sourceVanillaPath")"

  if ! private_contextExists "$contextName"; then
    echo "Context \"$contextName\" not found." >&2
    return 1
  fi

  if ! private_sourceExists "$contextName" "$sourceVanillaPath";  then
    echo "Source \"$sourceVanillaPath\" does not exist within context \"$contextName\"." >&2
    return 1
  fi

  rm "$sourcePath"
}
