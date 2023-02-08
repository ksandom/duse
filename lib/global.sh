# Stuff that doesn't belong elsewhere.

function private_getType
{
  local dirPath

  dirPath="$1"

  if [ ! -e "$dirPath/.duse/type" ]; then
    echo "Unknown"
    return 1
  else
    cat "$dirPath/.duse/type"
  fi
}

function private_gentleSetType
{
  local dirPath
  local type

  dirPath="$1"
  type="$2"

  if [ ! -e "$dirPath/.duse/type" ]; then
    mkdir -p "$dirPath/.duse"
    echo "$type" > "$dirPath/.duse/type"
  else
    return 1
  fi
}
