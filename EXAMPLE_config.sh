#!/bin/bash - 

basedir="$HOME/.nexuiz"

# Path to nexbash.cfg relatively to the game dir.
nbcfg="nexbash.cfg"

# UDP port to read from.

port=26404

# Command to use to launch Nexuiz

nexcmd="/usr/bin/nexuiz"

# Feel free to change this, but don't put it in a place where Nexuiz can
# write to, or else bad admins could hurt your $HOME or execute commands
# Safe directories are:
#  - "hidden" directories, starting with a "."
#  - anything that is not in the data directory (which is usually
#     $basedir/data/ )

nbscriptdir="$basedir/nexbash/scripts"


