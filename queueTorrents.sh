#!/bin/sh

# *************
# Configuration
# *************

REMOTE="/usr/bin/transmission-remote"
USERNAME="username"
PASSWORD="password"
MAXDOWN="Torrents_In_Queue"
MAXACTIVE="Total_Active_Torrents"
CONFIG="/etc/transmission-daemon/settings.json"

# *****************
# Set-up variables
# *****************

CMD="$REMOTE --auth $USERNAME:$PASSWORD"
LOGCMD="/usr/bin/logger -t Transmission-queue "
STARTSCRIPT="Starting queue check..."
STOPSCRIPT="Exiting queue check..."
MAXRATIO=$(cat $CONFIG | grep \"ratio-limit\":)
MAXRATIO=${MAXRATIO#*\"ratio-limit\": }
MAXRATIO=${MAXRATIO%*, }
NAMELOG=""

# ********************
# Deal with downloads
# ********************

$LOGCMD ":: $STARTSCRIPT"

DOWNACTIVE="$($CMD -l | tail --lines=+2 | grep -v 100% | grep -v Sum | grep -v Stopped | grep -v Verifying | grep -v Will\ Verify | wc -l)"
if [ $MAXDOWN -lt $DOWNACTIVE ]; then
    DOWNTOSTOP="$($CMD -l | tail --lines=+2 | grep -v 100% | grep -v Sum | grep -v Stopped | grep -v Verifying | grep -v Will\ Verify | tail -n $(expr $DOWNACTIVE - $MAXDOWN) | awk '{ print $1; }')"
    for ID in $DOWNTOSTOP; do
        NAME="$($CMD --torrent $ID --info | grep Name:)"
        $LOGCMD "Putting in queue :: $ID: ${NAME#*Name: }"
        $CMD --torrent $ID --stop >> /dev/null 2>&1
    done
else
    [ $(expr $MAXDOWN - $DOWNACTIVE) -gt 0 ] && (
    DOWNINACTIVE="$($CMD -l | tail --lines=+2 | grep -v 100% | grep Stopped | wc -l)"
    [ $DOWNINACTIVE -gt 0 ] && (
        DOWNTOSTART="$($CMD -l | tail --lines=+2 | grep -v 100% | grep Stopped | head -n $(expr $MAXDOWN - $DOWNACTIVE) | awk '{ print $1; }')"
        for ID in $DOWNTOSTART; do
            NAME="$($CMD --torrent $ID --info | grep Name:)"
            $LOGCMD "Starting torrent :: $ID: ${NAME#*Name: }"
            $CMD --torrent $ID --start >> /dev/null 2>&1
        done
        )
    )
fi
# ****************************
# Then deal with total active
# ****************************

ACTIVE="$($CMD -l | tail --lines=+2 | grep -v Sum | grep -v Stopped | grep -v Verifying | grep -v Will\ Verify | wc -l)"
if [ $MAXACTIVE -lt $ACTIVE ]; then
    TOSTOP="$($CMD -l | tail --lines=+2 | grep 100% | grep -v Stopped | grep -v Verifying | grep -v Will\ Verify | tail -n $(expr $ACTIVE - $MAXACTIVE) | awk '{ print $1; }')"
    for ID in $TOSTOP; do
        NAME="$($CMD --torrent $ID --info | grep Name:)"
        $LOGCMD "Stop seeding :: $ID: ${NAME#*Name: }"
        $CMD --torrent $ID --stop >> /dev/null 2>&1
    done
else
    [ $(expr $MAXACTIVE - $ACTIVE) -gt 0 ] && (
    SEEDINACTIVE="$($CMD -l | tail --lines=+2 | grep 100% | grep Stopped | awk -v ratio=$MAXRATIO '{ if (strtonum(substr($0,52,4)) < ratio) print $0 ;}' | wc -l)"
    [ $SEEDINACTIVE -gt 0 ] && (
        TOSTART="$($CMD -l | tail --lines=+2 | grep 100% | grep Stopped | awk -v ratio=$MAXRATIO '{ if (strtonum(substr($0,52,4)) < ratio) print $0 ;}' | head -n $(expr $MAXACTIVE - $ACTIVE) | awk '{ print $1; }')"
        for ID in $TOSTART; do
            NAME="$($CMD --torrent $ID --info | grep Name:)"
            $LOGCMD "Seeding torrent :: $ID: ${NAME#*Name: }"
            $CMD --torrent $ID --start >> /dev/null 2>&1
        done
        )
    )
fi

# **************************
#List all torrents in queue
# **************************

INQUEUE="$($CMD -l | tail --lines=+2 | grep Stopped | awk '{ print $1; }')"
        for ID in $INQUEUE; do
                NAME="$($CMD --torrent $ID --info | grep Name:)"
                NAMELOG=$NAMELOG"$ID: ${NAME#*Name: }\n\n"
                $LOGCMD "In Queue :: $ID: ${NAME#*Name: }"
        done
$LOGCMD ":: $STOPSCRIPT"


