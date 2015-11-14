#!/bin/bash

# timelapse.sh --- setup for picam timelapse, can even use sunrise/sunset

# Description:  This script runs raspistill to take timelapse images, 
#               then mencoder to encode to an AVI video.
#
#               To get location code, go to http://weather.yahoo.com/ and search for zip or city.
#               hit search and read your location code off the end of the URL it gives you.
#
#               For instance, Portland, OR gives you a URL of 
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
echo ""
echo "raspistill related options. these are passed directly through to raspistill."
echo ""
echo "-sh, --sharpness            set image sharpness (-100 to 100)"
echo "-co, --contrast             set image contrast (-100 to 100)"
echo "-br, --brightness           set image brightness (0 to 100)"
echo "-sa, --saturation           set image saturation (-100 to 100)"
echo "-ISO, --ISO                 set capture ISO"
echo "-vs, --vstab                turn on video stabilisation"
echo "-ev, --ev                   set EV compensation"
echo "-ex, --exposure             set exposure mode (see Notes)"
echo "-awb, --awb                 set AWB mode (see Notes)"
echo "-mm, --metering             set metering mode (see Notes)"
echo "-rot, --rotation            set image rotation (0-359)"
echo "-hf, --hflip                set horizontal flip"
echo "-vf, --vflip                set vertical flip"
echo "-ss, --shutter              set shutter speed in microseconds"
echo "-drc, --drc                 set DRC Level"
echo "-st, --stats                force recomputation of statistics on stills capture pass"
echo ""
echo "Notes"
echo ""
echo "Exposure mode options:"
echo "    off,auto,night,nightpreview,backlight,spotlight,sports,"
echo "    snow,beach,verylong,fixedfps,antishake,fireworks"
echo ""
echo "AWB mode options:"
echo "    off,auto,sun,cloud,shade,tungsten,fluorescent,incandescent,flash,horizon"
echo ""
echo "Metering Mode options:"
echo "    average,spot,backlit,matrix"
echo ""
echo "Dynamic Range Compression (DRC) options:"
echo "    off,low,med,high"
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

RSPISHARP=''
RSPICONTRAST=''
RSPIBRIGHT=''
RSPISAT=''
RSPIISO=''
RSPIVS=''
RSPIEV=''
RSPIEX=''
RSPIAWB=''
RSPIMM=''
RSPIROT=''
RSPIHF=''
RSPIVF=''
RSPISHUT=''
RSPIDRC=''
RSPISTATS=''

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

#raspistill specific options here.

      -sh | --sharpness)
          RSPISHARP="$2" # set image sharpness (-100 to 100)
          shift 2
          ;;
      -co | --contrast)
          RSPICONTRAST="$2" # set image contrast (-100 to 100)
          shift 2
          ;;
      -br | --brightness)
          RSPIBRIGHT="$2" # set image brightness (0 to 100)
          shift 2
          ;;
      -sa | --saturation)
          RSPISAT="$2" # set image saturation (-100 to 100)
          shift 2
          ;;
      -ISO | --ISO)
          RSPIISO="$2" # set capture ISO (100 to 800)
          shift 2
          ;;
      -vs | --vstab)
          RSPIVS="-vs" # turn on video stabilisation
          shift
          ;;
      -hf | --hflip)
          RSPIHF="-hf" # set horizontal flip
          shift
          ;;
      -vf | --vflip)
          RSPIVF="-vf" # set vertical flip
          shift
          ;;
      -st | --stats)
          RSPISTATS="-st" # force recomputation of statistics on stills capture pass
          shift
          ;;
      -ev | --ev)
          RSPIEV="$2" # set EV compensation
          shift 2
          ;;
      -ex | --exposure)
          RSPIEX="$2" # set exposure mode (see Notes)
          shift 2
          ;;
      -awb | --awb)
          RSPIAWB="$2" # set AWB mode (see Notes)
          shift 2
          ;;
      -mm | --metering)
          RSPIMM="$2" # set metering mode (see Notes)
          shift 2
          ;;
      -rot | --rotation)
          RSPIROT="$2" # set image rotation (0-359)
          shift 2
          ;;
      -ss | --shutter)
          RSPISHUT="$2" # set shutter speed in microseconds
          shift 2
          ;;
      -drc | --drc)
          RSPIDRC="$2" # set DRC Level
          shift 2
          ;;

#end raspistill  specific options

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

if [ ! -z "$RSPISHARP" ]; then
	if [[ "$RSPISHARP" =~ ^-?[0-9]+$ ]] && [ "$RSPISHARP" -ge -100 -a "$RSPISHARP" -le 100 ]; then 
	  RSPISHARP="-sh $RSPISHARP"
	else
	  RSPISHARP=''
	  echo 'Invalid raspistill sharpness. (must be -100 to 100)'
	fi
fi

if [ ! -z "$RSPICONTRAST" ]; then
	if [[ "$RSPICONTRAST" =~ ^-?[0-9]+$ ]] && [ "$RSPICONTRAST" -ge -100 -a "$RSPICONTRAST" -le 100 ]; then 
	  RSPICONTRAST="-co $RSPICONTRAST"
	else
	  RSPICONTRAST=''
	  echo 'Invalid raspistill contrast. (must be -100 to 100)'
	fi
fi

if [ ! -z "$RSPIBRIGHT" ]; then
	if [[ "$RSPIBRIGHT" =~ ^[0-9]+$ ]] && [ "$RSPIBRIGHT" -ge 0 -a "$RSPIBRIGHT" -le 100 ]; then 
	  RSPIBRIGHT="-br $RSPIBRIGHT"
	else
	  RSPIBRIGHT=''
	  echo 'Invalid raspistill brightness. (must be 0 to 100)'
	fi
fi

if [ ! -z "$RSPISAT" ]; then
	if [[ "$RSPISAT" =~ ^-?[0-9]+$ ]] && [ "$RSPISAT" -ge -100 -a "$RSPISAT" -le 100 ]; then 
	  RSPISAT="-sa $RSPISAT"
	else
	  RSPISAT=''
	  echo 'Invalid raspistill saturation. (must be -100 to 100)'
	fi
fi

if [ ! -z "$RSPIISO" ]; then
	if [[ "$RSPIISO" =~ ^[0-9]+$ ]] && [ "$RSPIISO" -ge 100 -a "$RSPIISO" -le 800 ]; then 
	  RSPIISO="-ISO $RSPIISO"
	else
	  RSPIISO=''
	  echo 'Invalid raspistill ISO. (must be 100 to 800)'
	fi
fi

if [ ! -z "$RSPIEV" ]; then
	if [[ "$RSPIEV" =~ ^-?[0-9]+$ ]] && [ "$RSPIEV" -ge -10 -a "$RSPIEV" -le 10 ]; then 
	  RSPIEV="-ev $RSPIEV"
	else
	  RSPIEV=''
	  echo 'Invalid raspistill EV compensation. (must be -10 to 10)'
	fi
fi

if [ ! -z "$RSPISHUT" ]; then
	if [[ "$RSPISHUT" =~ ^[0-9]+$ ]] && [ "$RSPISHUT" -ge 1 -a "$RSPISHUT" -le 6000000 ]; then 
	  RSPISHUT="-ss $RSPISHUT"
	else
	  RSPISHUT=''
	  echo 'Invalid raspistill shutter speed. (must be 1 to 6000000)'
	fi
fi

if [ ! -z "$RSPIEX" ]; then
	if [ "$RSPIEX" == "auto" -o "$RSPIEX" == "night" -o "$RSPIEX" == "nightpreview" -o "$RSPIEX" == "backlight" -o "$RSPIEX" == "spotlight" -o "$RSPIEX" == "sports" -o "$RSPIEX" == "snow" -o "$RSPIEX" == "beach" -o "$RSPIEX" == "verylong" -o "$RSPIEX" == "fixedfps" -o "$RSPIEX" == "antishake" -o "$RSPIEX" == "fireworks" ]; then 
	  RSPIEX="-ex $RSPIEX"
	else
	  RSPIEX=''
	  echo 'Invalid raspistill exposure mode. must be one of the following:'
	  echo '      auto | night | nightpreview | backlight | spotlight | sports | snow |'
	  echo '      beach | verylong | fixedfps | antishake | fireworks'
	fi
fi

if [ ! -z "$RSPIAWB" ]; then
	if [ "$RSPIAWB" == "off" -o "$RSPIAWB" == "auto" -o "$RSPIAWB" == "sun" -o "$RSPIAWB" == "cloud" -o "$RSPIAWB" == "shade" -o "$RSPIAWB" == "tungsten" -o "$RSPIAWB" == "fluorescent" -o "$RSPIAWB" == "incandescent" -o "$RSPIAWB" == "flash" -o "$RSPIAWB" == "horizon" ]; then 
	  RSPIAWB="-awb $RSPIAWB"
	else
	  RSPIAWB=''
	  echo 'Invalid raspistill white balance mode. must be one of the following:'
	  echo '      off | auto | sun | cloud | shade | tungsten | fluorescent |'
	  echo '      incandescent | flash | horizon '
	fi
fi

if [ ! -z "$RSPIMM" ]; then
	if [ "$RSPIMM" == "average" -o "$RSPIMM" == "spot" -o "$RSPIMM" == "backlit" -o "$RSPIMM" == "matrix" ]; then 
	  RSPIMM="-mm $RSPIMM"
	else
	  RSPIMM=''
	  echo 'Invalid raspistill metering mode. must be one of the following:'
	  echo '      average | spot | backlit | matrix'
	fi
fi

if [ ! -z "$RSPIDRC" ]; then
	if [ "$RSPIDRC" == "off" -o "$RSPIDRC" == "low" -o "$RSPIDRC" == "medium" -o "$RSPIDRC" == "high" ]; then 
	  RSPIDRC="-drc $RSPIDRC"
	else
	  RSPIDRC=''
	  echo 'Invalid raspistill dynamic range compression mode. must be one of the following:'
	  echo '      off | low | medium | high'
	fi
fi

if [ ! -z "$RSPIROT" ]; then
	if [[ "$RSPIROT" =~ ^[0-9]+$ ]] && [ "$RSPIROT" -ge 0 -a "$RSPIROT" -le 359 ]; then 
	  RSPIROT="-rot $RSPIROT"
	else
	  RSPIROT=''
	  echo 'Invalid raspistill rotation. (must be 0 to 359)'
	fi
fi


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


SLEEP_SECS=$((SUNRISE_EPOCH-CURRENT_EPOCH))

if [ "$SLEEP_SECS" -lt 0 ]; then
    MILLISECS=$((SUNSET_EPOCH-CURRENT_EPOCH))
else
    MILLISECS=$((SUNSET_EPOCH-SUNRISE_EPOCH))
fi

HOURS=$((MILLISECS/3600))
MILLISECS=$((MILLISECS*1000))

FILENAMEDATE=$(date +%Y.%m.%d)

OUTFILE="$FOLDER/$FILENAMEDATE.timelapse.avi"
LOGFILE="$FOLDER/$FILENAMEDATE.timelapse.log"

MSFRMS=$((SECSBETWEENFRAMES*1000))


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
    echo "    SUNRISE_EPOCH:     $SUNRISE_EPOCH"
    echo "    SUNSET_EPOCH:      $SUNSET_EPOCH"
    echo "    SLEEP_SECS:        $SLEEP_SECS"
    echo ""
    echo "raspistill specific settings:"
    echo "    SHARPNESS:        $RSPISHARP"
    echo "    CONTRAST:         $RSPICONTRAST"
    echo "    BRIGHTNESS:       $RSPIBRIGHT"
    echo "    SATURATION:       $RSPISAT"
    echo "    ISO:              $RSPIISO"
    echo "    STABILIZATION:    $RSPIVS"
    echo "    HORIZONTAL FLIP:  $RSPIHF"
    echo "    VERTICAL FLIP:    $RSPIVF"
    echo "    RECOMPUTE STATS:  $RSPISTATS"
    echo "    EV COMPENSATION:  $RSPIEV"
    echo "    EXPOSURE:         $RSPIEX"
    echo "    AWB:              $RSPIAWB"
    echo "    METERING:         $RSPIMM"
    echo "    ROTATION:         $RSPIROT"
    echo "    SHUTTER:          $RSPISHUT"
    echo "    DRC:              $RSPIDRC"
    echo ""
    echo "taking a sample pic with cam and then exiting."
    echo "Attempting cam test - creating $FOLDER/camtest.jpg."
    raspistill -w $VWIDTH -h $VHEIGHT -q 100 $RSPISHARP $RSPICONTRAST $RSPIBRIGHT $RSPISAT $RSPIISO $RSPIVS $RSPIHF $RSPIVF $RSPISTATS $RSPIEV $RSPIEX $RSPIAWB $RSPIMM $RSPIROT $RSPISHUT $RSPIDRC -o "$FOLDER/camtest.jpg"
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
        raspistill -w $VWIDTH -h $VHEIGHT -q 100 -o $FOLDER/tl%05d.jpg -t $MILLISECS -tl $MSFRMS $RSPISHARP $RSPICONTRAST $RSPIBRIGHT $RSPISAT $RSPIISO $RSPIVS $RSPIHF $RSPIVF $RSPISTATS $RSPIEV $RSPIEX $RSPIAWB $RSPIMM $RSPIROT $RSPISHUT $RSPIDRC
        ls $FOLDER/tl*.jpg > $FOLDER/frames.txt
        mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:aspect=16/9:vbitrate=8000000 -vf scale=$VWIDTH:$VHEIGHT -o $OUTFILE -mf type=jpeg:fps=$FPS mf://@$FOLDER/frames.txt
        rm $FOLDER/frames.txt
        if [ ! -z "$REMOVEJPEGS" ]; then
            rm $FOLDER/tl*.jpg
        fi  ) & disown
echo "Timelapse Running as pid $!" >&2
