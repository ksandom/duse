# ./bin/duse --addContext shoots "A collection of photo/video shoots."
function addContext # 00: Add a new context that will have sources and cache associated with it. Usage: addContext shortName "Description."
{
  local contextName
  local contextDescription
  local contextPath

  contextName="$1"
  contextDescription="$2"
  contextPath="$contextHome/$contextName"

  if [ "$1" == '' ]; then
    echo "Need a name and description." >&2
    return 1
  fi

  if [ -e "$contextPath" ]; then
    echo "Context $contextName already exists." >&2
    return 1
  fi

  mkdir -pv "$contextPath"
  echo "$contextDescription" | tee "$contextPath/description"
}

function private_listContextThing
{
  local contextName
  local thingName
  local thingDirName
  local thingPath

  contextName="$1"
  thingName="$2"
  thingDirName="$3"
  thingPath="$contextHome/$context/$thingDirName"

  if [ -e "$thingPath" ]; then
    echo "  $thingName:"

    # shellcheck disable=SC2012
    if [ "$(ls -1 "$thingPath" | wc -l)" -lt 1 ]; then
      echo "    None anymore."
      rmdir "$thingPath"
    else
      for thingItem in "$thingPath"/*; do
        echo "    $(basename "$thingItem"): $(cat "$thingItem")"
      done
    fi
  else
    echo "  $thingName: None yet."
  fi
}

function private_showContext
{
  context="$1"
  echo "$context: $(cat "$contextHome/$context/description")"

  private_listContextThing "$context" "Sources" "sources"
  private_listContextThing "$context" "Cache" "cache"
  private_listContextThing "$context" "Workspaces" "workspaces"
}

function private_getContexts
{
  ls -1 "$contextHome"
}

function listContexts # List contexts and their associated data.
{
  if [ -e "$contextHome" ]; then
    while read -r context; do
      private_showContext "$context"
    done < <(private_getContexts)
  else
    echo "No contexts yet." >&2
    exit 1
  fi
}

function private_contextExists
{
  local contextName
  local contextPath

  contextName="$1"
  contextPath="$contextHome/$contextName"

  if [ ! -e "$contextPath" ]; then
    return 1
  else
    return 0
  fi
}

function deleteContext # Delete a context. --deleteContext contextName . Note that this will delete all duse workspaces and relevant cache, but will not touch the original sources.
{
  local contextName
  local contextPath
  local workspacePath
  local workspaceName

  contextName="$1"
  contextPath="$contextHome/$contextName"

  if ! private_contextExists "$contextName"; then
    echo "Context \"$contextName\" not found." >&2
    return 1
  fi

  # Delete associated workspaces.
  while read -r workspace; do
    workspacePath="$(cat "$contextPath/workspaces/$workspace")"
    if cd "$workspacePath"; then
      cd ..
      workspaceName="$(basename "$workspacePath")"
      deleteWorkspace "$workspaceName"
    fi
  done < <(ls -1 "$contextPath/workspaces")

  rm -Rfv "$contextPath"
}
