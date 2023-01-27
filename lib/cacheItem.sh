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

  private_syncDir "$thingDir" | private_indent

  echo "Set symlink... $thingDir" | private_indent
  rm "$thing"
  ln -s "$thingDir" "$thing"
}
