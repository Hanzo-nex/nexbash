#!/bin/bash

# Nexuiz-Bash scripting! By Mr. Bougo
# 
# This script will launch Nexuiz itself, and run in a rather
# transparent way. Use the scrpt command from inside the game.
# Syntax:
#                    scrpt <shname> <parameters>
# Where <shname> is the name of the script (minus the .sh) and
# <parameters> the parameters passed as commandline arguments to the
# script.
#
# There is an example script, with two commands, yes and time.
# Just try it out:
#                       scrpt example time

function error
{
    echo "Error: $*" >&2
    exit 1
}


[ -e config.sh ] || error "No configuration found. Please run \`cp EXAMPLE_confg.sh config.sh', edit config.sh and try again"
. config.sh || error "Failed to read configuration"

######################
# Script starts here #
######################

checkdep() {
	if ! hash "$1" &> /dev/null; then
		echo "$1 not found. Please install it."
		exit 1
	fi
}

checkdep socat
checkdep mktemp

terminate() {
	kill -0 $socatpid &> /dev/null && { echo "Killing socat (PID $socatpid)..."; kill $socatpid > /dev/null; }
	kill -0 $nexpid &> /dev/null   && { echo "quit" > "$fifo"; sleep 0.5; }
	kill -0 $nexpid &> /dev/null   && { echo "Killing nexuiz (PID $nexpid)..."; kill $nexpid > /dev/null; }
	rm -r "$nbtempdir"
	exit
}

trap terminate SIGINT SIGQUIT SIGTERM

nbtempdir=$(mktemp -dt nexbash.XXXXXXXXXX) || exit 1
fifo="$nbtempdir/fifo"
mkfifo "$fifo" || exit 1

echo "Made fifo $fifo"

"$nexcmd" +exec $nbcfg $* < "$fifo"& nexpid=$!
echo > "$fifo" # why?

export fifo nbscriptdir

readmsg() {
	local regex='/' input script args
	cd "$nbscriptdir"
	while read input; do
		input=${input/$'\xFF\xFF\xFF\xFF'}
		set -- $input
		if [[ "$1" == "scrpt" ]]; then
			script=$2
			args="${*:3}"
			if [[ $script =~ $regex ]]; then
				echo "echo ^1You can only use scripts from the script directory." > "$fifo"
			elif [[ -x ./$script.sh ]]; then
				 ./$script.sh $args > "$fifo"
			else
				echo "echo ^1File $nbscriptdir/$script.sh not found." > "$fifo"
			fi
#		elif [[ "$input" == "info" ]]; then
#			echo "Script path: $PWD"
		elif [[ "$1" == "export" ]]; then  #export variables to the children scripts (for persistent settings set from the .cfg file instead of editing the script themselves
			export $2="${*:3}"
		elif [[ "$1" == "quit" ]]; then
			echo "quit" > "$fifo"
			return
		fi
	done
	echo
}
export -f readmsg

socat -u UDP-LISTEN:$port EXEC:"bash -c readmsg"& socatpid=$!

(
	while true; do
		sleep 1
		kill -0 $nexpid &> /dev/null || kill 0 &> /dev/null
	done&

	cat > "$fifo"
)

terminate
