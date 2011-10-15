#!/bin/bash

# Help text
function print_help {
cat << EOF

FILE DATE UPDATER
=================

This script will apply the provided time adjustment to the selected file or directory. If a directory
is provided as the file path, then all of the directory's children will have their creation dates
updated.

USAGE:
   $0 options

OPTIONS:
   -a      Adjust the second, minute, hour, month day, week day, month or year according to val.
           If val is preceded with a plus or minus sign, the date is adjusted forwards or backwards
           according to the remaining string, otherwise the relevant part of the date is set. The
           date can be adjusted as many times as required using these flags. Flags are processed in
           the order given.

           When setting values (rather than adjusting them), seconds are in the range 0-59, minutes
           are in the range 0-59, hours are in the range 0-23, month days are in the range 1-31, week
           days are in the range 0-6 (Sun-Sat), months are in the range 1-12 (Jan-Dec) and years are
           in the range 80-38 or 1980-2038.
           
           If val is numeric, one of either y, m, w, d, H, M or S must be used to specify which part of
           the date is to be adjusted.

           For more information take a look at the date command and its val option.

   -p      Path to file or directory where time adjustment will be applied. If the path is
           not provided, then the current directory will be used.

   -v      Run the script in verbose mode.

   -h      Display this help text.

EXAMPLES:
   $0 -p /path/to/update -a -8H

   Will update all of the directory's children by reducing their creation date by eight hours.

   $0 -p /path/to/file -a +8H

   Will update the selected file by increasing its creation date by eight hours.

   $0 -a -2M

   Will update the current directory's children by reducing their creation date by two minutes.

EOF
}

# Prepare script variables
FILEPATH=.
ADJUSTMENT=
VERBOSE=0

# Validate arguments
while getopts ":a:p:vh" OPTION; do
    case $OPTION in
        a)
            ADJUSTMENT=$OPTARG
            ;;
        p)
            if [[ -f $OPTARG ]] || [[ -d $OPTARG ]]; then
                FILEPATH=$OPTARG
            else
                echo "Provided file path argument is invalid!" >&2
                exit 1
            fi
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

# Validate adjustment
if [[ -z $ADJUSTMENT ]]; then
    echo "A date adjustment must be provided!" >&2
    echo "For more information view the help page with the -h option."
    exit 1
fi

# Validate path
if [[ -f $FILEPATH ]]; then
    # Begin
    echo "Applying $ADJUSTMENT adjustment to file..."
    
    STATVAL=$(stat -f "%B" $FILEPATH)
    STARTDATE=$(date -j -f %s $STATVAL "+%Y%m%d%H%M")
    NEWDATE=$(date -j -v$ADJUSTMENT -f %s $STATVAL "+%Y%m%d%H%M")

    if [[ $VERBOSE == 1 ]]; then
        echo ""
        echo "  Stat value: $STATVAL"
        echo "  Start date: $STARTDATE"
        echo "  New date:   $NEWDATE"
    fi

    # Apply time change to file
    touch -t $NEWDATE $FILEPATH

    # End
    echo "  $FILEPATH <-- $NEWDATE"
    echo ""
    echo "Adjustment complete"

elif [[ -d $FILEPATH ]]; then    
    # Begin
    echo "Applying $ADJUSTMENT adjustment to directory..."

    # Iterate through files and apply time change
    #for FILE in "$(find $FILEPATH -iname "*")"
    for FILE in *
    do
        STATVAL=$(stat -f "%B" $FILE)
        STARTDATE=$(date -j -f %s $STATVAL "+%Y%m%d%H%M")
        NEWDATE=$(date -j -v$ADJUSTMENT -f %s $STATVAL "+%Y%m%d%H%M")

        if [[ $VERBOSE == 1 ]]; then
            echo ""
            echo "  Stat value: $STATVAL"
            echo "  Start date: $STARTDATE"
            echo "  New date:   $NEWDATE"
        fi

        # Apply time change to file
        touch -t $NEWDATE $FILE

        echo "  $FILE <-- $NEWDATE"
    done

    # End
    echo ""
    echo "Adjustment complete"    
fi

