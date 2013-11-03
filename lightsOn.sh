#!/bin/bash
# lightsOn.sh
# Copyright (c) 2013 iye.cba at gmail com
# url: https://github.com/iye/lightsOn
# modified by Vincent
# This script is licensed under GNU GPL version 2.0 or above

flash_detection=0 # for firefox, chromium
mplayer_detection=0
vlc_detection=0 # VLC has build in function to disable screensaver
minitube_detection=0
gnome_mplayer_detection=0
smplayer_detection=0
totem_detection=0
chrome_detection=1
delay_progs=()

displays=""
while read id
do
    displays="$displays $id"
done < <(xvinfo | sed -n 's/^screen #\([0-9]\+\)$/\1/p')

# I think "pidof name" is better than "pgrep -lfc name |grep -wc name". It only output the PIDs when detects the process,
# but output nothing when no process.Most importantly, it is shorter.
if [ `pidof xscreensaver` ]; then       # xscreensaver
    screensaver=xscreensaver
elif [ `pidof kscreensaver` ]; then     # kscreensaver
    screensaver=kscreensaver
elif [ `pidof gnome-screensaver` ]; then        # Most desktop enviromments use gnome-screensaver
    screensaver=gnome-screensaver
else
    screensaver=None
    echo "screensaver not detected"
fi

checkDelayProgs()
{
    for prog in "${delay_progs[@]}"; do
        if [ `pidof "$prog"` ]; then
            echo "Delaying the screensaver because a program on the delay list, \"$prog\", is running..."
            delayScreensaver
            break
        fi
    done
}

checkFullscreen()
{
    for display in $displays
    do
        activ_win_id=`DISPLAY=:0.${display} xprop -root _NET_ACTIVE_WINDOW`
        activ_win_id=${activ_win_id:40:9}
        if [ "$activ_win_id" = "0x0" ]; then   # Skip invalid window ids (It returns "0x0" when ScreenSaver is actived)
         continue
        fi
        isActivWinFullscreen=`DISPLAY=:0.${display} xprop -id $activ_win_id | grep _NET_WM_STATE_FULLSCREEN`
            if [ "$isActivWinFullscreen" ];then
                isAppRunning
                var=$?
                if [[ $var -eq 1 ]];then
                    delayScreensaver
                fi
            fi
    done
}

isAppRunning()
{
    #Get PID of active window, I think it makes the code easier. 
    activ_win_pid=`xprop -id $activ_win_id | grep "_NET_WM_PID(CARDINAL)"`
    activ_win_pid=${activ_win_pid##* }
    if [ $flash_detection == 1 ]; then
        if [[ `lsof -p $activ_win_pid | grep flashplayer.so` ]]; then    #  match all browers (which use libflashplayer.so , libpepflashplayer.so & operapluginwrapper-native)  #pgrep -lf "chrome --type=ppapi" for Chrome PAPI flash (implement later)
            return 1
        fi
    fi
    if [ $mplayer_detection == 1 ];then
        if [[ `ps p $activ_win_pid o comm=` = "mplayer" ]];then    # Which is more simple and accurate.
            return 1
        fi
    fi
    if [ $vlc_detection == 1 ];then
        if [[ `ps p $activ_win_pid o comm=` = "vlc" ]];then
            return 1
        fi
    fi
    if [ $minitube_detection == 1 ];then
        if [[ `ps p $activ_win_pid o comm=` = "minitube" ]];then
            return 1
        fi
    fi    
    if [ $gnome_mplayer_detection == 1 ];then                  # It is easy to add video player detection.
        if [[ `ps p $activ_win_pid o comm=` = "gnome-mplayer" ]];then
            return 1
        fi
    fi
    if [ $smplayer_detection == 1 ];then
        if [[ `ps p $activ_win_pid o comm=` = "smplayer" ]];then
            return 1
        fi
    fi
    if [ $totem_detection == 1 ];then
        if [[ `ps p $activ_win_pid o comm=` = "totem" ]];then
            return 1
        fi
    fi
    if [ $chrome_detection == 1 ];then
        if [[ `ps p $activ_win_pid o comm=` = "chrome" ]];then # check for google chrome fullscreen
            return 1
        fi
    fi
    return 0
}

delayScreensaver()
{
    if [ "$screensaver" == "gnome-screensaver" ]; then
        dbus-send --session --dest=org.gnome.ScreenSaver --type=method_call /org/gnome/ScreenSaver org.gnome.ScreenSaver.SimulateUserActivity #check before, using d-feet (function still available on ubuntu 13.10)
    elif [ "$screensaver" == "xscreensaver" ]; then
        xscreensaver-command -deactivate > /dev/null
    elif [ "$screensaver" == "kscreensaver" ]; then
        qdbus org.freedesktop.ScreenSaver /ScreenSaver SimulateUserActivity > /dev/null
    else
    	echo "screensaver not detected"
    fi
}

delay=$1
if [ -z "$1" ];then
    delay=50
fi
if [[ $1 = *[^0-9]* ]]; then
    echo "The Argument \"$1\" is not valid, not an integer"
    echo "Please use the time in seconds you want the checks to repeat."
    echo "You want it to be ~10 seconds less than the time it takes your screensaver or DPMS to activate"
    exit 1
fi

while true
do
    checkDelayProgs
    checkFullscreen
    sleep $delay
done

exit 0
