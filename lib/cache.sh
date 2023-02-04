function setCache # 02: Set the location where you want cache to be stored. --setCache contextName /path/to/cache/location
{
  local contextName
  local contextPath
  local cachePath

  contextName="$1"
  contextPath="$contextHome/$contextName"
  cachePath="$(realpath "$2")"

  if ! private_contextExists "$contextName"; then
    echo "Context \"$contextName\" not found." >&2
    return 1
  fi

  if [ ! -e "$cachePath" ]; then
    echo "The path \"$cachePath\" doesn't appear to exist." >&2
    return 1
  fi

  mkdir -p "$contextPath/cache"
  echo "$cachePath" > "$contextPath/cache/location"
}

function private_getCache
{
  local contextName
  local contextPath

  contextName="$1"
  contextPath="$contextHome/$contextName"

  cat "$contextPath/cache/location"
}

function private_syncDir
{
  local cacheDir
  local source

  cacheDir="$1"
  sourceDescriptor="$cacheDir/.duse/source"

  if [ ! -e "$sourceDescriptor" ]; then
    echo "Failed to look up the source for $cacheDir. Perhaps it no longer exists?" >&2
    return 1
  fi

  source="$(cat "$sourceDescriptor")"

  if [ "$source" == '' ]; then
    echo "Source for $cacheDir appears to be empty. Perhaps it no longer existed in the past? I suggest doing duse --uncache $cacheDir , and then duse --use $cacheDir ." >&2
    return 1
  fi

  echo "Sync $cacheDir..."
  rsync -ruv --progress "$source/"* "$cacheDir"
  echo
}

function cache # Switch an item( or piped items from --listAvailable) to using cache. --cache itemToCache
{
  private_abstractDirection "private_doCacheViaParameter" "$1"
  return "$?"
}

function private_cacheUsageForThing
{
  local contextName
  local thing
  local cacheDir
  local thingDir

  contextName="$1"
  thing="$2"
  cacheDir="$(private_getCache "$contextName")"
  thingDir="$cacheDir/$contextName/$thing"

  private_cacheUsage "$thingDir"
}

function private_cacheUsage
{
  local thingDir

  thingDir="$1"

  # shellcheck disable=SC2012 # Overkill, and not relevant to what it's doing.
  ls -1 "$thingDir/.duse/usage" 2>/dev/null | wc -l
}

function private_removeFromCache
{
  local contextName
  local thing
  local cacheUsage
  local cacheDir
  local thingDir

  contextName="$1"
  thing="$2"
  cacheUsage="$(private_cacheUsageForThing "$contextName" "$thing")"
  cacheDir="$(private_getCache "$contextName")"
  thingDir="$cacheDir/$contextName/$thing"

  if [ ! -e "$thingDir" ]; then
    echo "private_removeFromCache: cache for $thing does not exist. No need to clean." >&2
  fi

  if [ "$cacheUsage" -eq 0 ]; then
    rm -Rf "$thingDir"
  else
    echo "private_removeFromCache: cache for $thing is not unused. No need to clean." >&2
    return 1
  fi
}

function private_doUncacheViaParameter
{
  local thing
  local contextName
  local workspaceName
  local cacheDir
  local thingDir
  local originalSource
  local derivedSource
  local cacheUsage
  local thingDirSource

  thing="$1"
  contextName="$(cat '.duse/context')"
  workspaceName="$(private_sourceName "$(pwd)")"
  cacheDir="$(private_getCache "$contextName")"
  thingDir="$cacheDir/$contextName/$thing"
  thingDirSource="$thingDir/.duse/source"

  derivedSource="$(private_getSourceForThing "$thing")"
  if [ "$derivedSource" == '' ] ; then
    echo "We don't appear to have a source for \"$thing\". Review any previous error/warning messages." >&2
    return 1
  fi

  if [ -e "$thingDirSource" ]; then
    originalSource="$(cat "$thingDirSource" 2>/dev/null)"
  else
    originalSource="$derivedSource"
  fi

  echo "$(pwd)/$thing"

  if [ "$originalSource" != "$derivedSource" ]; then
    echo "WARN: The source appears to have changed. Updating:
    Was: $originalSource
    Now: $derivedSource" | private_indent >&2
  fi

  echo "Set symlink... $derivedSource" | private_indent
  rm "$thing"
  ln -s "$derivedSource" "$thing"

  echo "Unregister from cache... $thingDir" | private_indent
  rm -f "$thingDir/.duse/usage/$workspaceName"

  cacheUsage="$(private_cacheUsageForThing "$contextName" "$thing")"
  if [ "$cacheUsage" -eq 0 ]; then
    echo "Clean cache... $thingDir" | private_indent
    private_removeFromCache "$contextName" "$thing"
  else
    echo "No need to clean cache for $thingDir."
  fi
}

function uncache # Switch an item( or piped items from --listAvailable) back to using cache. --uncache itemToUncache
{
  private_abstractDirection "private_doUncacheViaParameter" "$1"
  return "$?"
}

function cacheBack # Take changes made to the cache, and sync them back to the source. This should be a rare task in your workflow, and is intended for when you make a mistake. --cacheBack itemToSyncBack
{
  private_abstractDirection "private_cacheBackViaParameter" "$1"
  return "$?"
}

function private_checkUsage
{
  cacheEntryDir="$1"
  while read -r workspaceName; do
    workspaceDescriptor="$cacheEntryDir/.duse/usage/$workspaceName"
    if [ ! -e  "$(cat "$workspaceDescriptor")" ]; then
      rm "$workspaceDescriptor"
    fi
  done < <(ls -1 "$cacheEntryDir/.duse/usage")
}

function sync # Sync cache to make sure it is up-to-date. Also remove orphaned entries.
{
  while read -r contextName; do
    contextCache="$(private_getCache "$contextName")/$contextName"
    if cd "$contextCache"; then
      while read -r cacheEntry; do
        private_checkUsage "$cacheEntry"
        cacheUsage="$(private_cacheUsage "$cacheEntry")"

        if [ "$cacheUsage" -gt 0 ]; then
          private_syncDir "$cacheEntry"
        else
          echo "Removing $cacheEntry..."
          rm -Rf "$cacheEntry"
        fi

      done < <(ls -1)
    fi
  done < <(private_getContexts)
}
