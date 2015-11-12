#/bin/bash

# timelapse.sh --- setup for picam timelapse, can even use sunrise/sunset

# Description:  This script runs raspistill to take timelapse images, 
#               then mencoder to encode to an AVI video.
#
#               To get location code, go to http://weather.yahoo.com/ and search for zip or city.
#				hit search weather and read your location code off the end of the URL it gives you.
#
#               For instance, Portland, OR give you a URL of 
#                   https://weather.yahoo.com/united-states/oregon/portland-2475687/
#                 The location code is the 2475687 at the end.

function display_help {
echo "Usage: $0 [OPTION]...."
echo "This is a sample template for BASH shell scripts here.. Replace all this with real stuff."
echo ""
echo "Mandatory arguments to long options are mandatory for short options too."
echo "  -f, --folder FOLDER       use folder FOLDER for images and video. /home/pi/timelapse is default"
echo "      --fps FRAMESPERSEC    frames per second for video, 30 is default."
echo "  -s, --secs SECONDS        seconds between frames, 30 is default."
echo "  -t, --test                test only, tests settings and cam. Not default."
echo "  -l, --location LOCATION   location code from yahoo weather. Portland, OR is default."
echo "  -b, --before SECONDS      seconds before sunrise to start. 0 is default."
echo "  -a, --after SECONDS       seconds after sunset to end. 0 is default."
echo "  -r, --remove              remove JPEG images used to build video after completion. Default is to keep images."
echo "      --start TIME          start at TIME instead of around sunrise. 24 hour format like 12:00 or 23:00. No default."
echo "      --end TIME            end at TIME instead of around sunset. 24 hour format like 12:00 or 23:00. No default."
echo "      --width WIDTH         width of video in pixels. 1920 is default."
echo "      --height HEIGHT       height of video in pixels. 1080 is default."
echo "  -h, --help                display this help and exit"
echo ""
}

# declare variables we expect to fill with some sane defaults.
FOLDER='/home/pi/timelapse'
SECSBETWEENFRAMES=30
FPS=30
BEFORESUNRISE=0
AFTERSUNSET=0
TESTONLY=''
YAHOOLOCATIONCODE=2475687 # Portland, OR, just because. Mine is 12798525
ABSSTART=''
ABSEND=''
REMOVEJPEGS=''
VWIDTH=1920
VHEIGHT=1080

while :
do
    case "$1" in
      -h | --help)
          display_help  # Call help function
          # no shifting needed here, we're done.
          exit 0
          ;;
	  -a | --after)
          AFTERSUNSET="$2" # seconds after sunset.
          shift 2
          ;;
      -b | --before)
          BEFORESUNRISE="$2" # seconds before sunrise.
          shift 2
          ;;
      -f | --folder)
          FOLDER="$2" # folder to use for images and video.
          shift 2
          ;;
	  -l | --location)
          YAHOOLOCATIONCODE="$2" # Yahoo location code for sunrise/sunset.
          shift 2
          ;;
	  -r | --remove)
          REMOVEJPEGS="removejpegs" # Remove JPEGS when done with timelapse
		  shift
          ;;
	  -s | --secs)
          SECSBETWEENFRAMES="$2" # seconds to wait between frames.
          shift 2
          ;;
	  -t | --test)
          TESTONLY="testonly" # Test Only, tests SUNRISE/SUNSET and cam.
		  shift
          ;;  
	  --fps)
          FPS="$2" # video frames per second.
          shift 2
          ;;		  
	  --start)
          ABSSTART="$2" # Start time to override sunrise
          shift 2
          ;;	
	  --end)
          ABSEND="$2" # Start time to override sunrise
          shift 2
          ;;			  
	  --width)
          VWIDTH="$2" # width of video in pixels
          shift 2
          ;;	
	  --height)
          VHEIGHT="$2" # height of video in pixels.
          shift 2
          ;;		
      --) # End of all options
          shift
          break
          ;;
      -*)
          echo "$0: invalid option: '$1'" >&2
          echo "Try '$0 --help' for more information" >&2
          exit 1
          ;;
      *)  # No more options
          break
          ;;
    esac
done

if [ ! -z "$ABSSTART" ]; then
	SUNRISE_EPOCH=$(date -d "$ABSSTART" +%s)
else
	SUNRISE=`curl -s http://weather.yahooapis.com/forecastrss?w=$YAHOOLOCATIONCODE|grep astronomy| awk -F\" '{print $2}'`
	SUNRISE_EPOCH=$(date -d "$SUNRISE" +%s)
	echo "$SUNRISE is sunrise"
	SUNRISE_EPOCH=$((SUNRISE_EPOCH-BEFORESUNRISE)) # some interval before sunrise
fi

if [ ! -z "$ABSEND" ]; then
	SUNSET_EPOCH=$(date -d "$ABSEND" +%s)
else
	SUNSET=`curl -s http://weather.yahooapis.com/forecastrss?w=$YAHOOLOCATIONCODE|grep astronomy| awk -F\" '{print $4}'`
	SUNSET_EPOCH=$(date -d "$SUNSET" +%s)
	echo "$SUNSET is sunset"
	SUNSET_EPOCH=$((SUNSET_EPOCH+AFTERSUNSET)) # some interval past sunset
fi

UNTIL=$(date -d @"$SUNRISE_EPOCH")
ENDTIME=$(date -d @"$SUNSET_EPOCH")
CURRENT_EPOCH=$(date +%s)

MILLISECS=$((SUNSET_EPOCH-SUNRISE_EPOCH))
HOURS=$((MILLISECS/3600))
MILLISECS=$((MILLISECS*1000))

FILENAMEDATE=$(date +%Y.%m.%d)

OUTFILE="$FOLDER/$FILENAMEDATE.timelapse.avi"
LOGFILE="$FOLDER/$FILENAMEDATE.timelapse.log"

MSFRMS=$((SECSBETWEENFRAMES*1000))

CURRENT_EPOCH=$(date +%s)
SLEEP_SECS=$((SUNRISE_EPOCH-CURRENT_EPOCH))

echo "Going to run about $HOURS hours, exactly $MILLISECS milliseconds"
echo "Interval: $SECSBETWEENFRAMES seconds or $MSFRMS milliseconds"

if [ ! -z "$TESTONLY" ]; then
	echo 'Running is test only mode.'
	echo ''
	echo 'Variables:'
	echo "    FOLDER:            $FOLDER"
	echo "    SECSBETWEENFRAMES: $SECSBETWEENFRAMES"
	echo "    FPS:               $FPS"
	echo "    BEFORESUNRISE:     $BEFORESUNRISE"
	echo "    AFTERSUNSET:       $AFTERSUNSET"
	echo "    TESTONLY:          $TESTONLY"
	echo "    YAHOOLOCATIONCODE: $YAHOOLOCATIONCODE"
	echo "    ABSSTART:          $ABSSTART"
	echo "    ABSEND:            $ABSEND"
	echo "    REMOVEJPEGS:       $REMOVEJPEGS"
	echo "    VWIDTH:            $VWIDTH"
	echo "    VHEIGHT:           $VHEIGHT"
	echo ""
	echo "    START:             $UNTIL"
	echo "    END:               $ENDTIME"
	echo "    OUTFILE:           $OUTFILE"
	echo "    LOGFILE:           $LOGFILE"
	echo "    CURRENT_EPOCH:     $CURRENT_EPOCH"
	echo "    SLEEP_SECS:        $SLEEP_SECS"
	echo ""
	echo "taking a sample pic with cam and then exiting."
	echo "Attempting cam test - creating $FOLDER/camtest.jpg."
	raspistill -o "$FOLDER/camtest.jpg"
	exit 0
fi



if [ -f "$LOGFILE" ]; then
	rm "$LOGFILE"
fi

if [ -f "$OUTFILE" ]; then
	rm "$OUTFILE"
fi

if [ "$SLEEP_SECS" -gt 0 ]; then
	echo "Waiting until $UNTIL"
fi

(       trap "" HUP
        exec 2> /dev/null
        exec 0< /dev/null
        exec 1>"$LOGFILE"
        if [ "$SLEEP_SECS" -gt 0 ]
        then
            sleep $SLEEP_SECS
        fi

        echo "Starting now..."
        date
        raspistill -w $VWIDTH -h $VHEIGHT -q 100 -o $FOLDER/tl%05d.jpg -t $MILLISECS -tl $MSFRMS
        ls $FOLDER/tl*.jpg > $FOLDER/frames.txt
        mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:aspect=16/9:vbitrate=8000000 -vf scale=$VWIDTH:$VHEIGHT -o $OUTFILE -mf type=jpeg:fps=$FPS mf://@$FOLDER/frames.txt
        rm $FOLDER/frames.txt
		if [ ! -z "$REMOVEJPEGS" ]; then
			rm $FOLDER/tl*.jpg
		fi 	) & disown
echo "Timelapse Running as pid $!" >&2
