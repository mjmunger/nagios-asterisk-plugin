#!/bin/bash
DEBUG=0
if [ "$#" -eq 0 ]; then
    MSG="You must pass an extension as an argument to check its status! Config fail."
    echo $MSG
    logger $MSG
    exit 2
fi
if ["$DEBUG" == 1 ]; then
    logger Checking status of SIP $1
fi

LINE=`asterisk -rx' sip show peers' | grep "^$1"`

if ["$DEBUG" == 1 ]; then
    logger LINE: "$LINE"
fi

# Figure out the column count, and adjust the target column accordingly:
LASTCOL=`echo $LINE | awk '{print $NF}'`
case $LASTCOL in
    "ms)")
        COLUMN=`echo $LINE | awk '{ print $(NF-2) }'`
        ;;
    "UNKNOWN")
        echo "Phone appears to be offline or lagged"
        logger "exiting status 2 (Critical) for SIP $1"
        exit 2
        ;;
    "Unmonitored")
        echo "This peer is unmonitored. Try setting keepalive."
        exit 1
        ;;
esac

if ["$DEBUG" == 1 ]; then
    logger "$COLUMN"
fi

if [ "$COLUMN" == "OK" ]; then
    
    logger "SIP $1 OK, getting ping"
    #Split the line on "OK" to get the ping.
    PART2=`asterisk -rx"sip show peers" | grep $1 | awk -F "OK" '{ print $2 }'`
    logger SIP ping=$PART2
    STATUS="$PART1 $PART2"
    logger SIP $1 $STATUS
    echo "OK $STATUS"
    logger "exiting status 0 (OK)"
    exit 0
else
    echo $PART1 
    echo "Phone appears to be offline or lagged"
    logger "exiting status 2 (Critical) for SIP $1"
    exit 2
fi
