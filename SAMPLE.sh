#!/bin/bash

# SAMPLE.sh --- Sample script for stuff in here.

# Description:  This is a good start for anything that goes in here. Not canon or required,
#               but doesn't hurt to have something standardized.
#
#               The options handling is a first stab and subject to modifications.
#               It's also just a sample. Change it up at will.

function display_help {
echo "Usage: $0 [OPTION]...."
echo "This is a sample template for BASH shell scripts here.. Replace all this with real stuff."
echo ""
echo "Mandatory arguments to long options are mandatory for short options too."
echo "  -f, --file FILENAME   use file FILENAME"
echo "  -u, --user USERNAME   use username USERNAME"
echo "  -p, --pass PASSWORD   use password PASSWORD"
echo "  -v, --verbose         do verbose messages"
echo "  -h, --help            display this help and exit"
echo ""
}

# declare variables we expect to fill with some sane defaults.

FILENAME=''
USERNAME=''
PASSWORD=''
VERBOSE=''

while :
do
    case "$1" in
      -f | --file)
          FILENAME="$2"   # You may want to check validity of $2
          shift 2
          ;;
      -h | --help)
          display_help  # Call your function
          # no shifting needed here, we're done.
          exit 0
          ;;
      -p | --pass)
          PASSWORD="$2" # You may want to check validity of $2
          shift 2
          ;;
      -u | --user)
          USERNAME="$2" # You may want to check validity of $2
          shift 2
          ;;
      -v | --verbose)
      VERBOSE="verbose"
          shift
          ;;
      --) # End of all options
          shift
          break
          ;;
      -*)
          echo "$0: invalid option: '$1'" >&2
          echo "Try '$0 --help' for more information" >&2
          exit 1
          ;;
      *)  # No more options
          break
          ;;
    esac
done

# sample stuff to do with variables snagged above.

if [ -z "${FILENAME}" ]; then
    echo "FILENAME is blank."
fi

if [ -z "${USERNAME}" ]; then
    echo "USERNAME is blank."
fi

if [ -z "${PASSWORD}" ]; then
    echo "PASSWORD is blank."
fi


echo "FILENAME: $FILENAME
USERNAME: $USERNAME
PASSWORD: $PASSWORD
VERBOSE: $VERBOSE"
