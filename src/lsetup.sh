# Author: Theodore Zacharia
# V0.1 - 23/09/2021 - Initial Release, extend lsetup to take json config file input
# V0.2 - 07/07/2022 - Add options for which config file to process
# V0.3 - 12/06/2023 - Change top level structure in cfg file to an array form
#
# Execute instructions in the json config file
# Config files are in order of preference: Machine name specific, o/s specific, default.
#
# MANDATORY: This script uses the excellent 'jq' utility,
#            which MUST be available for the script to work

# Globals
LSETUPCFG=lsetup.cfg	# the default lsetup config file
MNTFILTR=""
FORCEIT=0
TRACE=0
TRUNSTEPS=/tmp/lsetup.$$.tmp
FINDCONFIGFILE=1
LSETUPCFGFORCE=""

# Functions
_beginswith() { case $2 in "$1"*) true;; *) false;; esac; }

# Mainline

# Look for a specific lsetup config file before going for the default
# You can ALSO do this in the config file, so it only does things depending
# where you run it


while getopts hftTdc: AOPT
do
case $AOPT in
	t) TRACE=1 ;;
	T) TRACE=2 ;;
	f) FORCEIT=1 ;;					# force execution of command, even if one is already running
	c) LSETUPCFGFORCE=$OPTARG ;;	# specify a config we would not normally process
	d) FINDCONFIGFILE=0 ;;			# switch off finding of config file, only use default
	h) echo "usage: $0 [-t|-T] [-f] [-d] [-c configfile] features..."
	echo "-t to switch on trace mode, -T for more trace"
	echo "-f is force an action if appropriate (e.g. starting up apps even if already running)"
	echo "-d to force the use of the default config file only, ignores all other options"
	echo "-c config to specify a specific config file rather than the ones we already look for"
	echo "   We look for the following config files, it uses the most local one:"
	echo "   * lsetup.cfg             (this is the default)"
	echo "   * lsetup.$(uname -s).cfg (this is one based on your o/s)"
	echo "   * lsetup.$(uname -n).cfg (this is one based on your machine name, highest priority)"
	echo " "
	echo "The following features are supported:"
	#jq -r ' [].service + " " + [].type + "\t\t- " + [].description ' $LSETUPCFG
	jq -r '.[] | (.service + " " +  .type + "\t\t- " + .description)' $LSETUPCFG
	EL=$?
	if [ $EL -gt 1 ] ; then echo "Looks like the config file $LSETUPCFG has errors" ; fi
	exit $EL ;;
	*) echo "$AOPT is an invalid option"
	exit 2 ;;
esac
done

shift $((OPTIND-1))


if [ $# -lt 1 ]
then
	echo "see option -h for help"
	exit 1
fi

# find which config file to use
if [ $FINDCONFIGFILE -eq 1 ]
then
	if [ -n "$LSETUPCFGFORCE" ]
	then
		LSETUPCFG=$LSETUPCFGFORCE
	else
		# Look for Linux/Windows/Mac etc
		CHKLSETUP=lsetup.$(uname -s).cfg
		if [ -f "$CHKLSETUP" ]
		then
			LSETUPCFG=$CHKLSETUP
		fi

		# Look for a machine name specific file
		CHKLSETUP=lsetup.$(uname -n).cfg
		if [ -f "$CHKLSETUP" ]
		then
			LSETUPCFG=$CHKLSETUP
		fi
	fi
fi

if [ $TRACE -gt 0 ] ; then echo "using LSETUPCFG=$LSETUPCFG" ; fi

# handle 1 parameter, 2 linked (requires type in the cfg) or 2 where 2nd is just data (type is empty in this case in the cfg)
if [ -n "$2" ]
then
	# if TWO parameters provided, need to handle ones where 2nd param may be something to pass into script
	# this is the case if the type in config is EMPTY
	TRUN=$(jq ' .[] | select ( .service == "'$1'" ) | select ( .type == "'$2'" ) ' $LSETUPCFG)
	if [ ! -n "$TRUN" ]
	then
		TRUN=$(jq ' .[] | select ( .service == "'$1'" ) | select ( .type == "" ) ' $LSETUPCFG)
	fi
else
	# if ONE parameter passed, need to only select ones with no type
	TRUN=$(jq ' .[] | select ( .service == "'$1'" ) | select ( .type == "" ) ' $LSETUPCFG)
fi

if [ $TRACE -gt 1 ] ; then echo "$TRUN" ; fi
echo "$TRUN" | jq -r ' .steps[] ' > $TRUNSTEPS


while read ASTEP
do
	if [ $TRACE -gt 0 ] ; then echo "$ASTEP" ; fi
	# force to get input from terminal
	eval $ASTEP </dev/tty
done<$TRUNSTEPS


rm -f $TRUNSTEPS
