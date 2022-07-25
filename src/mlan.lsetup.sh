# Author: Theodore Zacharia
# V0.1 - 23/09/2021 - Initial Release, support lsetup to mount disk to network mount points
#

# Globals

# Functions
_beginswith() { case $2 in "$1"*) true;; *) false;; esac; }

# Mainline
if [ $# -lt 1 ]
then
	echo "usage: $0 mount_list_file <filter>"
	exit 1
fi

MOUNTLIST=$1

if [ $# -gt 1 ] ; then MNTFILTR=$2 ; echo "using filter $MNTFILTR" ; else MNTFILTR="" ; fi

read -s -p "mount password: " LAN_PASSWORD </dev/tty

while read AMNT
do
	if _beginswith "#" "$AMNT" ; then continue ; fi
	CHECKIT=0
	if [ -n "$MNTFILTR" ]
	then
		if [ -z "${AMNT##*$MNTFILTR*}" ] ; then
			CHECKIT=1
		fi
	else
		CHECKIT=1
	fi
	if [ $CHECKIT -eq 1 ]
	then
		TDIR=$(echo $AMNT | cut -d' ' -f 7)
		if [ -d $TDIR ]
		then
			echo "Mounting $TDIR"
			# the following applies the variable to the expression
			BMNT=$(eval echo "$AMNT")
			sudo $BMNT
		fi
	fi
done<$MOUNTLIST

