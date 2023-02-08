# Functionality for using/unusing an item.

function private_doUseViaParameter
{
  local thing

  thing="$1"

  if ! source="$(private_getSourceForThing "$thing")"; then
    echo "Errored while getting source \"$source\" for \"$thing\"."
    return 1
  fi

  if [ "$source" == '' ]; then
    echo "Source \"$source\" for \"$thing\" is empty."
    return 1
  fi

  if [ ! -e "$source" ]; then
    echo "Source \"$source\" for \"$thing\" does not exist." >&2
    return 1
  fi

  rm -f "$thing"
  ln -s "$source" "$thing"
}

function use # Use an item (or piped items from --listAvailable), found in --listAvailable, in the current workspace. --use [itemToUse]
{
  private_abstractDirection "private_doUseViaParameter" "$1" "noProject"
  return "$?"
}

function private_doUnUseViaParameter
{
  local thing

  thing="$1"

  private_doUncacheViaParameter "$thing"
  private_doUseViaParameter "$thing"
  rm "$thing"
}

function unuse # Uncache, and stop using an item (or piped items from --listAvailable), found in --listAvailable, in the current workspace. --unuse [itemToUnuse]
{
  private_abstractDirection "private_doUnUseViaParameter" "$1" "noProject"
  return "$?"
}
