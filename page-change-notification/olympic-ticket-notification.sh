#!/bin/bash

# Help text
function print_help {
cat << EOF

OLYMPIC TICKET CHANGE NOTIFICATION (OS X)
=========================================

Slight spin-off. This OS X script will notify the user if the London 2012
olympic ticket results page has changed.

USAGE:
   $0 options

OPTIONS:
   -s      The amount of seconds to wait between each check (default = 120).

   -v      Run the script in verbose mode.

   -h      Display this help text.

EXAMPLES:

   $0 -s 10

   Will notify the user when the user when the result page has changed. Override the delay
   between checks to 10 seconds.

   $0 -v

   Will notify the user when the user when the home page has changed, and run in verbose mode.

EOF
}

# Prepare script variables
VERBOSE=0
DELAY=120
URL="http://www.tickets.london2012.com/browse?form=search&amp;tab=oly&amp;sport=&amp;venue=&amp;fromDate=2012-08-04&amp;toDate=2012-08-12&amp;morning=1&amp;afternoon=1&amp;evening=1&amp;show_available_events=1"
RESULTS_TABLE_PATTERN='(<table id="searchResults" cellpadding="0" cellspacing="0">.*</table>)'
ORIGINAL_HASH=
CURRENT_HASH=

# Validate arguments
while getopts ":s:vh" OPTION; do
    case $OPTION in
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
	RESULTS_TABLE=
	if [[ $VERBOSE > 0 ]]; then
        CONTENT=$(curl "$URL")
    else
	    CONTENT=$(curl -silent "$URL")
	fi
	
	# Valid URL?
	if [[ $? == 0 && $CONTENT =~ $RESULTS_TABLE_PATTERN ]]; then
		RESULTS_TABLE=${BASH_REMATCH[1]}
	else
		echo "    Provided URL is invalid..."
		exit 1
	fi
	
	# Prepare state
    ORIGINAL_HASH=$(md5 -q -s "$RESULTS_TABLE")
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
		
		if [[ $? == 0 && $CONTENT =~ $RESULTS_TABLE_PATTERN ]]; then
			RESULTS_TABLE=${BASH_REMATCH[1]}
			CURRENT_HASH=$(md5 -q -s "$RESULTS_TABLE")
		fi
		
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



