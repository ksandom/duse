function private_doRegisterWorkspace
{
  local contextPath="$1"
  local workspacePath="$2"
  local workspaceNiceName="$3"
  local descriptorPath="$contextPath/workspaces/$workspaceNiceName"

  mkdir -p "$contextPath/workspaces"
  echo "$workspacePath" > "$descriptorPath"
  echo "$descriptorPath" > "$workspacePath/.duse/descriptorPath"
}

function private_doUnregisterWorkspace
{
  local contextPath="$1"
  local workspaceNiceName="$2"

  rm -fv "$contextPath/workspaces/$workspaceNiceName" | private_indent
  # shellcheck disable=SC2012
  if [ "$(ls -1 "$contextPath/workspaces" | wc -l)" -lt 1 ]; then
    rmdir -v "$contextPath/workspaces" | private_indent
  fi
}

function private_registerWorkspace
{
  local contextName
  local contextPath
  local workspaceName
  local workspacePath
  local workspaceNiceName
  local action

  contextName="$1"
  contextPath="$contextHome/$contextName"
  workspaceName="$2"
  workspacePath="$(pwd)/$workspaceName"
  workspaceNiceName=$(private_sourceName "$workspacePath")
  action="${3:-register}"

  case "$action" in
    "register")
      echo "Registering $workspaceName in $contextName..."
      private_doRegisterWorkspace "$contextPath" "$workspacePath" "$workspaceNiceName"
    ;;
    "unregister")
      echo "Unregistering $workspacePath from $contextName..."
      private_doUnregisterWorkspace "$contextPath" "$workspaceNiceName"
    ;;
  esac
}

function createWorkspace # 03: Create a workspace that will use the context that you have created. --createWorkspace contextName workspaceName
{
  local contextName
  local contextPath
  local workspaceName

  contextName="$1"
  contextPath="$contextHome/$contextName"
  workspaceName="$2"

  mkdir -p "$workspaceName/.duse"
  echo "$contextName" > "$workspaceName/.duse/context"
  echo "$workspaceName" > "$workspaceName/.duse/name"
  echo "$(pwd)/$workspaceName" > "$workspaceName/.duse/registeredFullPath"

  private_gentleSetType "$workspaceName" "workspace"
  private_gentleSetType "$workspaceName/.." "project"

  private_registerWorkspace "$contextName" "$workspaceName"
}

function private_emptyWorkspace
{
  local workspacePath

  workspacePath="$1"

  if cd "$workspacePath"; then
    # TODO Revisit this to see if SC2012 can be honoured and still function correctly. Solution should not:
    # * include hidden files.
    # * include ./ in front of filenames.
    # shellcheck disable=SC2012 # Suggested alternative either massively complicates things, or produces incorrect output.
    ls -1 | unuse
    cd  ..
  else
    echo "private_emptyWorkspace: Could not find $workspacePath ." >&2
    return 1
  fi
}

function deleteWorkspace # Delete a workspace. --deleteWorkspace workspaceNameOrPath
{
  local workspaceNameOrPath
  local contextName
  local contextPath
  local type

  workspaceNameOrPath="$1"
  if [ ! -e "$workspaceNameOrPath/.duse" ] || [ ! -e "$workspaceNameOrPath/.duse/type" ]; then
    echo "Could not find a valid workspace at \"$workspaceNameOrPath\"." >&2
    return 1
  fi

  type="$(cat "$workspaceNameOrPath/.duse/type")"
  if [ "$type" != 'workspace' ]; then
    echo "\"$workspaceNameOrPath\"($type) does not appear to be a workspace." >&2
    return 1
  fi

  contextName="$(cat "$workspaceNameOrPath/.duse/context")"
  contextPath="$contextHome/$contextName"

  private_emptyWorkspace "$workspaceNameOrPath"

  private_registerWorkspace "$contextName" "$workspaceNameOrPath" 'unregister'
  rm -Rvf "$workspaceNameOrPath"
}

function private_getContextNameFromDir
{
  local workspaceNameOrPath
  local contextName
  local type

  workspaceNameOrPath="${1:-.}"

  if [ ! -e "$workspaceNameOrPath/.duse" ] || [ ! -e "$workspaceNameOrPath/.duse/type" ]; then
    echo "Could not find a valid workspace at \"$workspaceNameOrPath\"." >&2
    return 1
  fi

  type="$(cat "$workspaceNameOrPath/.duse/type")"
  if [ "$type" != 'workspace' ]; then
    echo "\"$workspaceNameOrPath\"($type) does not appear to be a workspace." >&2
    return 1
  fi

  contextName="$(cat "$workspaceNameOrPath/.duse/context")"

  echo "$contextName"
}

function privateGetContextPathFromCurrentDir
{
  local contextName
  local contextPath

  if contextName="$(private_getContextNameFromDir)"; then
    contextPath="$contextHome/$contextName"
    echo "$contextPath"
  else
    return 1
  fi
}

function info # Show basic information about the current workspace.
{
  if [ ! -e '.duse/context' ]; then
    echo "This does not appear to be a workspace." >&2
    return 1
  fi

  private_showContext "$(cat '.duse/context')"
}

function private_listAllPossibleCachableThings
{
  if [ ! -e '.duse/context' ]; then
    echo "This does not appear to be a workspace." >&2
    return 1
  fi

  contextName="$(cat '.duse/context')"
  sourcesPath="$contextHome/$contextName/sources"


  while read -r source; do
    ls -1 "$(cat "$sourcesPath/$source")"
  done < <(private_getSources "$contextName")
}

function listAvailable # List out the things that you can cache in the current workspace (current directory).
{
  private_listAllPossibleCachableThings | sort -u
}

function private_repairWorkspaceEntries
{
  # Repairs entries within a workspace.

  local thing="$1"

  if [ ! -e "$thing" ]; then
    # Can not read link destination.

    type="$(private_getEntryType "$(private_getContextNameFromDir)" "$thing")"

    derivedSource="$(private_getSourceForThing "$thing")"
    if [ "$derivedSource" != '' ]; then
      echo "$thing ($type) in $(pwd) is no longer accessible. Pointing back to $derivedSource. ($?)"
      rm "$thing"
      ln -s "$derivedSource" "$thing"

      return 2
    else
      echo "$thing ($type) in $(pwd) is no longer accessible. And it can't be found in the sources. Manual intervention will be required."

      return 1
    fi
  fi
}

function private_repairWorkspace
{
  # Repairs a workspace.

  local workspaceName="$1"
  local currentFullPath
  local registeredFullPath
  local contextName
  local returnValue=0
  local descriptorPath

  currentFullPath="$(pwd)/$workspaceName"
  registeredFullPath="$(cat "$workspaceName/.duse/registeredFullPath")"
  descriptorPath="$(cat "$workspaceName/.duse/descriptorPath")"

  if [ "$currentFullPath" == "$registeredFullPath" ]; then
    echo "Healthy."
  else
    echo "Has moved. Re-registering."
    contextName="$(cat "$workspaceName/.duse/context")"
    contextPath="$contextHome/$contextName"
    workspacePath="$(pwd)/$workspaceName"
    workspaceNiceName=$(private_sourceName "$workspacePath")

    echo -e "old: $registeredFullPath\nnew: $currentFullPath" | private_indent

    if [ ! -e "$registeredFullPath" ]; then
      echo "This location does not appear to be a duplicate, un-registering the original."
      private_doUnregisterWorkspace "$contextPath" "$workspaceNiceName"

      if [ "$descriptorPath" != '' ]; then
        rm -f "$descriptorPath"
      else
        echo "This appears to be a really old workspace, so the registration can't be completely cleaned up. The only consequence of this is that duse will still think that it exists in the original location as well as the old one. If your workspace was created after 2021-08-23 with an up-to-date version of duse, then this is a bug that should be reported at https://github.com/ksandom/duse/issues ." >&2
      fi
    else
      echo "This location is a duplicate of the original ($registeredFullPath), so will not un-register it."
    fi

    private_doRegisterWorkspace "$contextPath" "$workspacePath" "$workspaceNiceName"

    echo "Updating details."
    echo "$currentFullPath" > "$workspaceName/.duse/registeredFullPath"
    echo "$workspace" > "$workspaceName/.duse/name"

    returnValue=2
  fi

  return "$returnValue"
}

function repair # Fix any symlinks that point to things that have moved to valid locations. Assumed to be run from a workspace, or the project directory containing workspaces.
{
  local returnValue=0
  local type

  private_abstractDirection "private_repairWorkspaceEntries" "$1"
  returnValue="$(private_returnMostSerious "$returnValue" "$?")"

  type="$(private_getType .)"

  echo "Begin health check of $(pwd) of type $type."

  if [ "$type" == "project" ]; then
    while read -r potentialWorkspace; do
      if [ "$(private_getType "$(pwd)/$potentialWorkspace")" == 'workspace' ]; then
        echo "Checking workspace $potentialWorkspace..."
        private_repairWorkspace "$potentialWorkspace"
        returnValue="$(private_returnMostSerious "$returnValue" "$?")"
      else
        echo "Skipping \"$potentialWorkspace\"."
      fi
    done < <(ls -1)
  else
    echo "The current directory($type) is not a project. So will not check workspaces that may have been removed."
  fi

  return "$returnValue"
}

function decommission # Decommission all workspaces within a project.
{
  local returnValue=0
  local type

  type="$(private_getType .)"

  if [ "$type" == "project" ]; then
    echo "Begin decommission of $(pwd) of type $type."

    while read -r potentialWorkspace; do
      if [ "$(private_getType "$(pwd)/$potentialWorkspace")" == 'workspace' ]; then
        echo "Unregistering and removing workspace $potentialWorkspace..."
        deleteWorkspace "$potentialWorkspace"
        returnValue="$(private_returnMostSerious "$returnValue" "$?")"
      else
        echo "Skipping \"$potentialWorkspace\"."
      fi
    done < <(ls -1)
  else
    echo "The current directory($type) is not a project. So will not check workspaces that may have been removed."
  fi

  return "$returnValue"
}
