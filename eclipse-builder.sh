#!/bin/bash

# Locations
BASEDIR=`cd $(dirname $0); pwd`
WORKINGDIR=`pwd`
SCRIPT_NAME=`basename $0`

# Commandline options (long and short)
OPTIONS_SHORT="c:lp:d:n:h"
OPTIONS_LONG="p2command:,local,platform:,destination:,name:,help"

# Configuration parameters and defaults
USE_LOCAL_REPOSITORIES="false"
PLATFORMS=()
DESTINATION="$WORKINGDIR"
DISTRO_NAME="custom-eclipse"

# P2 Parameters
P2_START_CMD="$BASEDIR/eclipse/eclipse"
P2_BASE_OPTS="-application org.eclipse.equinox.p2.director \
-profile SDKProfile \
-profileProperties org.eclipse.update.install.features=true \
-roaming"
declare -A P2_PLATFORM_OPTS
P2_PLATFORM_OPTS[linux]="-p2.os linux -p2.ws gtk -p2.arch x86_64"
P2_PLATFORM_OPTS[macosx]="-p2.os macosx -p2.ws cocoa -p2.arch x86_64"
P2_PLATFORM_OPTS[windows]="-p2.os win32 -p2.ws win32 -p2.arch x86_64"

declare -A P2_DEST_SUFFIX
P2_DEST_SUFFIX[linux]="linux-gtk-x86_64"
P2_DEST_SUFFIX[macosx]="macosx-cocoa-x86_64"
P2_DEST_SUFFIX[windows]="win32-x86_64"


# #############################################################################
# Usage and command line parsing
# #############################################################################

print_help() {
 cat << EOF
Usage: $SCRIPT_NAME <options> <configs>
  <options>:
    -c --p2command    Command to start the P2 director
                      (default: \$BASEDIR/eclipse/eclipse)
    -l --local        Use local (on-site) repositories to download installable
                      units.
    -p --platform     Distribution platform. The currently supported platforms
                      are "linux", "macosx", "windows" (all 64bit)
    -d --destination  Destination directory (must be a fully qualifed name!)
                      for the created distributions
    -n --name         Name of the created distribution
                      (default: custom-eclipse)
    -h --help         Print this help message

  <configs>: Configuration files containing installation information

EOF
}

tmp=`getopt -o $OPTIONS_SHORT -l $OPTIONS_LONG -- "$@"`

if [ $? != 0 ]; then
  echo "Terminating" >&2
  exit 1
fi

eval set -- "$tmp"
while true; do
  case "$1" in
    -c|--p2command)
      P2_START_CMD="$2"
      shift 2
      ;;

    -l|--local)
      USE_LOCAL_REPOSITORIES="true"
      shift
      ;;

    -p|--platform)
      # Check if we support the platform
      if [ -z "${P2_PLATFORM_OPTS[$2]}" ]; then
        echo "Unsupported platform: $2. Terminating..."
        exit 1
      fi
      PLATFORMS+=("$2")
      shift 2
      ;;

    -d|--destination)
      DESTINATION="$2"
      shift 2
      ;;

    -n|--name)
      DISTRO_NAME="$2"
      shift 2
      ;;

    -h|--help)
      print_help
      exit 0;
      ;;

    --)
      shift
      break
      ;;

    *)
      echo "Internal error while parsing options!";
      exit 1
      ;;

  esac
done

# #############################################################################
# Functions
# #############################################################################

# Join all arguments to a comma-separated string
join() {
  tmp_ifs="$IFS"
  IFS=","

  array=($@)
  joined="${array[*]}"
  
  IFS="$tmp_ifs"
  echo $joined
}


# #############################################################################
# Gets exactly one configuration entry.
# $1: configuration file
# $2: configuration tag
# #############################################################################
get_configuration() {
  config_file="$1"
  config_tag="$2"
  config=`grep -m 1 "^$config_tag" "$config_file"`

  echo "${config#*:}"
}


# #############################################################################
# Gets multiline configuration entries as comma-separated string.
# $1: configuration file
# $2: configuration tag
# #############################################################################
get_multiline_configuration() {
  config_file="$1"
  config_tag="$2"

  config=()
  config_lines=(`grep "^$config_tag" "$config_file"`)
  for line in ${config_lines[*]}; do
   config+=(${line#*:})
  done

  join ${config[*]}
}


# #############################################################################
# Gets the repository urls from a configuration file
# $1: configuration file
# #############################################################################
get_repository_urls() {
  config_file="$1"
  config_tag="remote-url:"
  if [[ "$USE_LOCAL_REPOSITORIES" == "true" ]]; then
    config_tag="local-url:"
  fi

  echo "`get_multiline_configuration "$config_file" "$config_tag"`"
}


# #############################################################################
# Gets all installable units from a configuration file
# $1: configuration file
# #############################################################################
get_installable_units() {
  config_file="$1"
  config_tag="iu"

  echo "`get_multiline_configuration "$config_file" "$config_tag"`"
}


# #############################################################################
# Gets the installation tag from a configuration file
# $1: configuration file
# #############################################################################
get_installation_tag() {
  config_file="$1"
  config_tag="tag"

  echo "`get_configuration "$config_file" "$config_tag"`"
}


# #############################################################################
# Installs installable units as specified in the configuration file
# $1: configuration file
# $2: platform (one of linux, macosx, windows)
# #############################################################################
install() {
  config_file="$1"
  platform="$2"

  if [ ! -e "$config_file" ]; then
    echo "Configuration file '$config_file' does not exist. Terminating..."
    exit 1;
  fi

  repository_urls=`get_repository_urls "$config_file"`
  installable_units=`get_installable_units "$config_file"`
  installation_tag=`get_installation_tag "$config_file"`
  destination="$DESTINATION/$DISTRO_NAME-${P2_DEST_SUFFIX[$platform]}/$DISTRO_NAME"

  install_cmd="$P2_START_CMD"
  install_cmd+=" $P2_BASE_OPTS"
  install_cmd+=" ${P2_PLATFORM_OPTS[$platform]}"
  install_cmd+=" -destination $destination" 
  install_cmd+=" -bundlepool $destination" 
  [ ! -z installation_tag ] && install_cmd+=" -tag \"$installation_tag\""
  install_cmd+=" -repository $repository_urls"
  install_cmd+=" -installIU $installable_units"

  # start the installation
  eval $install_cmd

  if [ $? != 0 ]; then
    "An error occurred while installing the eclipse distribution. Terminating..."
    exit 1
  fi
}


# #############################################################################
# Main
# #############################################################################
if [ ${#PLATFORMS[*]} == 0 ]; then
  echo "No platforms defined. Terminating..."
  exit 1
fi

for platform in ${PLATFORMS[*]}; do
  if [ $# == 0 ]; then
    echo "No configuration files defined. Terminating..."
    exit 1
  fi

  echo "Creating eclipse distribution for platform '$platform'"

  for config_file in $@; do
    echo "Processing configuration file '$config_file'..."
    install "$config_file" $platform
    echo "Configuration file '$config_file' successfully processed."
    echo
  done

  echo "Eclipse distribution for platform '$platform' successfully created!"
  echo "**************************************************"
  echo
  echo
done

