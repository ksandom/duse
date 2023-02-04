function private_doCacheViaParameter
{
  local thing
  local contextName
  local workspaceName
  local cacheDir
  local source
  local thingDir

  thing="$1"

  if [ ! -e '.duse/context' ]; then
    echo "This does not appear to be a workspace." >&2
    return 1
  fi

  contextName="$(cat '.duse/context')"
  workspaceName="$(private_sourceName "$(pwd)")"
  cacheDir="$(private_getCache "$contextName")"
  source="$(private_getSourceForThing "$thing")"
  thingDir="$cacheDir/$contextName/$thing"

  echo "$(pwd)/$thing"
  echo "Setup..." | private_indent
  mkdir -p "$thingDir/.duse/usage"
  echo "$source" > "$thingDir/.duse/source"
  echo "$(pwd)/$thing" > "$thingDir/.duse/usage/$workspaceName"
  private_gentleSetType "$thingDir" "cacheEntry"

  # TODO Remove indent to allow live progress to show.
  private_syncDir "$thingDir" | private_indent

  echo "Set symlink... $thingDir" | private_indent
  rm "$thing"
  ln -s "$thingDir" "$thing"
}

function private_cacheBackViaParameter
{
  local thing
  local contextName
  local workspaceName
  local cacheDir
  local source
  local thingDir

  thing="$1"

  if [ ! -e '.duse/context' ]; then
    echo "This does not appear to be a workspace." >&2
    return 1
  fi

  contextName="$(cat '.duse/context')"
  workspaceName="$(private_sourceName "$(pwd)")"
  cacheDir="$(private_getCache "$contextName")"
  source="$(private_getSourceForThing "$thing")"
  thingDir="$cacheDir/$contextName/$thing"

  echo "$(pwd)/$thing"

  # Test whether it is cached. Abort if not.
  thingType="$(private_getType "$thing")"
  if [ "$thingType" != 'cacheEntry' ]; then
    echo "$thing does not appear to be cached."
    return 1
  fi

  echo "cacheBack $thing"
  rsync -ruv --progress --exclude="\.duse" "$cacheDir/$contextName/$thing/"* "$source"
}
