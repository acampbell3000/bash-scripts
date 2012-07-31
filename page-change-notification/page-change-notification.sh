#!/bin/bash

# Help text
function print_help {
cat << EOF

PAGE CHANGE NOTIFICATION (OS X)
===============================

This OS X script will notify the user if the provided URL has had it's content changed.

USAGE:
   $0 options

OPTIONS:
   -u      The provided URL to retrieve using CURL.

   -s      The amount of seconds to wait between each check (default = 120).

   -v      Run the script in verbose mode.

   -h      Display this help text.

EXAMPLES:
   $0 -u "http://www.bbc.co.uk"

   Will notify the user when the user when the BBC's home page has changed.

   $0 -u "http://www.bbc.co.uk" -s 10

   Will notify the user when the user when the BBC's home page has changed. Override the delay
   between checks to 10 seconds.

   $0 -u "http://www.bbc.co.uk" -v

   Will notify the user when the user when the BBC's home page has changed, and run in verbose mode.

EOF
}

# Prepare script variables
VERBOSE=0
DELAY=120
URL=
ORIGINAL_HASH=
CURRENT_HASH=

# Validate arguments
while getopts ":u:s:vh" OPTION; do
    case $OPTION in
        u)
            URL=$OPTARG
            ;;
        s)
            DELAY=$OPTARG
            ;;
        v)
            VERBOSE=1
            ;;
        h)
            print_help
            exit
            ;;
        ?)
            print_help
            exit 1
            ;;
    esac
done

# Validate argument value
if [[ $URL != "" ]]; then
	# Begin
	echo ""
	echo "    Waiting for $URL to change..."
	echo ""
	echo "    Press [CTRL+C] to stop..."
    echo ""

    # Retrieve content
    CONTENT=
	if [[ $VERBOSE > 0 ]]; then
        CONTENT=$(curl "$URL")
    else
	    CONTENT=$(curl -silent "$URL")
	fi
	
	# Valid URL?
	if [[ $? != 0 ]]; then
		echo "    Provided URL is invalid..."
		exit 1
	fi
	
	# Prepare state
    ORIGINAL_HASH=$(md5 -q -s "$CONTENT")
    CURRENT_HASH=ORIGINAL_HASH

    # Boring part
    while true
	do
		sleep $DELAY
		if [[ $VERBOSE > 0 ]]; then
	        CONTENT=$(curl "$URL")
	        echo ""
	    else
		    CONTENT=$(curl -silent "$URL")
		fi
		
		CURRENT_HASH=$(md5 -q -s "$CONTENT")
		
		if [[ $ORIGINAL_HASH != $CURRENT_HASH ]]; then
		    echo "    Content has changed! ($ORIGINAL_HASH $CURRENT_HASH)"

			osascript -e beep
			osascript << EOF
				tell application "System Events"
					Activate
					display dialog "page-change-notification.sh: Content has changed!" buttons {"OK"} default button 1 with title "Notification" with icon caution
				end tell
EOF

			echo ""
			exit 0
		fi
	done
else
    echo ""
    echo "A URL must be provided!"
    echo "For more information view the help page with the -h option."
    echo ""
    exit 1	
fi



