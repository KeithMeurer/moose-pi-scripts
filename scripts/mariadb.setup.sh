#!/bin/bash

# mariadb.setup.sh --- Install and initial configuration of mariadb-server and mariadb-client.

# Description:  Sets up mariadb server and client, and creates an initial user to use
#               instead of root. Gives this user off-server access as well based on 
#               given network.

function display_help {
echo "Usage: $0 [OPTION]...."
echo "This installs mariadb-server and mariadb-client, and creates another user to use"
echo "instead of root for off-server access."
echo ""
echo "Mandatory arguments to long options are mandatory for short options too."
echo ""
echo "  -r, --rootpass ROOTPASS   REQUIRED: use ROOTPASS for root mariadb password."
echo "  -n, --network NETWORK     OPTIONAL: network to allow user access from."
echo "                               use % for everywhere,"
echo "                               or use something like 192.168.0.% for a subnet."
echo "                               If blank, optional user only gets local access."
echo "  -u, --user USERNAME       OPTIONAL: create new user with username USERNAME."
echo "  -p, --pass PASSWORD       OPTIONAL: create new user with password PASSWORD."
echo "                               If username is not blank, password must not be blank."
echo "  -h, --help                display this help and exit"
echo ""
}

# declare variables we expect to fill with some sane defaults.

USERNAME=''
PASSWORD=''
ROOTPASS=''
NETWORK=''
OFFSERVERROOT=''

while :
do
    case "$1" in
      -h | --help)
          display_help  # Call help function
          # no shifting needed here, we're done.
          exit 0
          ;;
	  -n | --network)
          NETWORK="$2" # network to allow user to access server from.
          shift 2
          ;;
      -p | --pass)
          PASSWORD="$2" # password to use with username to create initial login.
          shift 2
          ;;
      -r | --rootpass)
          ROOTPASS="$2" # Root password to for initial mariadb install.
          shift 2
          ;;
	  -o | --offserverroot)
          OFFSERVERROOT="offserverroot" # Root gets off-server acccess defined by NETWORK
		  shift
          ;;
	  -u | --user)
          USERNAME="$2" # username to use to create initial login.
          shift 2
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

if [ -z "${ROOTPASS}" ]; then
    echo "Root Password is required. Fix that first."
	display_help
	exit 1
fi

if [ -z "${USERNAME}" ]; then
    echo "USERNAME is not set. Will not create user."
fi

if [ -z "${PASSWORD}" ] && [ -n "${USERNAME}" ]; then
    echo "PASSWORD is blank but USERNAME is not. PASSWORD must be set."
	display_help
	exit 1
fi

if [ -n "${NETWORK}" ] && [ -n "${OFFSERVERROOT}" ]; then
    echo "root user will be allowed to access server from $NETWORK network."
fi

echo ""
echo "Let's go.."
echo ""


# these may need to change if version of mariadb is different.
echo "mariadb-server-10.0 mysql-server/root_password password $ROOTPASS" | debconf-set-selections
echo "mariadb-server-10.0 mysql-server/root_password_again password $ROOTPASS" | debconf-set-selections

# Download and Install the Latest Updates for the OS
echo ""
echo "updating OS first."
echo ""
apt-get update && apt-get -y upgrade

# install mariadb
echo ""
echo "Installing mariadb."
echo ""
apt-get -y install mariadb-server mariadb-client

# is this the best way to do this? Others add it to /etc/mysql/conf.d/mariadb.cnf.
# modify /etc/mysql/my.cnf to listen on all ports
sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/my.cnf

#restart mariadb so it will listen on all ports
echo ""
echo "restarting mariadb."
/etc/init.d/mysql restart

#modify mariadb to actually allow connections from remote network for specific cases.

echo ""
echo ""

if [ -n "${USERNAME}" ]; then
    echo "Granting $USERNAME local access..."
	mysql -u root -p$ROOTPASS --execute="USE mysql; GRANT ALL PRIVILEGES ON *.* TO '$USERNAME'@'::1' IDENTIFIED BY '$PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    mysql -u root -p$ROOTPASS --execute="USE mysql; GRANT ALL PRIVILEGES ON *.* TO '$USERNAME'@'$HOSTNAME' IDENTIFIED BY '$PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    mysql -u root -p$ROOTPASS --execute="USE mysql; GRANT ALL PRIVILEGES ON *.* TO '$USERNAME'@'127.0.0.1' IDENTIFIED BY '$PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
fi

if [ -n "${NETWORK}" ] && [ -n "${USERNAME}" ]; then
	echo "Granting $USERNAME network access on $NETWORK ..."
	mysql -u root -p$ROOTPASS --execute="USE mysql; GRANT ALL PRIVILEGES ON *.* TO '$USERNAME'@'::1' IDENTIFIED BY '$PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    mysql -u root -p$ROOTPASS --execute="USE mysql; GRANT ALL PRIVILEGES ON *.* TO '$USERNAME'@'$HOSTNAME' IDENTIFIED BY '$PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    mysql -u root -p$ROOTPASS --execute="USE mysql; GRANT ALL PRIVILEGES ON *.* TO '$USERNAME'@'$NETWORK' IDENTIFIED BY '$PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
fi

if [ -n "${NETWORK}" ] && [ -n "${OFFSERVERROOT}" ]; then
	echo "Granting root network access on $NETWORK ... (scary!)"
	mysql -u root -p$ROOTPASS --execute="USE mysql; GRANT ALL PRIVILEGES ON *.* TO 'root'@'$NETWORK' IDENTIFIED BY '$ROOTPASS' WITH GRANT OPTION; FLUSH PRIVILEGES;"
fi

# finally, show us what users and access we've set up.

mysql -u root -p$ROOTPASS --execute="USE mysql; SELECT User, Host FROM mysql.user WHERE Host <> 'localhost';"

echo ""
echo "mariadb install complete."
