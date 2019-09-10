#!/usr/bin/env bash

#------------------------------------------------------------------------------#
# Aufgabe:
# Skript so umbauen das mkvmerge nicht mehr benötigt wird.
#------------------------------------------------------------------------------#
#
# Dieses Skript verändert NICHT die Bildwiederholrate!
#
# Das Ergebnis besteht immer aus folgendem Format:
#  - MP4:    mp4  + H.264/AVC  + AAC
#
# https://de.wikipedia.org/wiki/Containerformat
#
# Es werden folgende Programme von diesem Skript verwendet:
#  - ffmpeg
#  - ffprobe
#  - mkvmerge (aus dem Paket mkvtoolnix)
#
#------------------------------------------------------------------------------#


#VERSION="v2017102900"
#VERSION="v2018090100"
#VERSION="v2019032600"
#VERSION="v2019051700"
#VERSION="v2019082800"
#VERSION="v2019090800"
#VERSION="v2019090900"
VERSION="v2019091000"


BILDQUALIT="auto"
TONQUALIT="auto"

#set -x
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

STARTZEITPUNKT="$(date +'%s')"

#
# https://sites.google.com/site/linuxencoding/x264-ffmpeg-mapping
# -keyint <int>
#
# ffmpeg -h full 2>/dev/null | fgrep keyint
# -keyint_min        <int>        E..V.... minimum interval between IDR-frames (from INT_MIN to INT_MAX) (default 25)
IFRAME="-keyint_min 2-8"

LANG=C					# damit AWK richtig rechnet
Film2Standardformat_OPTIONEN="${@}"
ORIGINAL_PIXEL="Nein"
STOP="Nein"

AVERZ="$(dirname ${0})"		# Arbeitsverzeichnis, hier liegen diese Dateien

#==============================================================================#
### Funktionen

################################################################################
### Filmwandler_grafik.txt
#------------------------------------------------------------------------------#
VERSION="v2018071500"

### 98 Namen von Bildauflösungen, sortiert nach Qualität (aufsteigend):
BILD_FORMATNAMEN_AUFLOESUNGEN="
        -soll_xmaly SQCIF               # 128x96  - es ist ein h263-Format
        -soll_xmaly QQVGA               # 160x120
        -soll_xmaly GB                  # 160x144
        -soll_xmaly QCIF                # 176x144 - es ist ein h263-Format
        -soll_xmaly Palm_LoRes          # 160x160
        -soll_xmaly GBA                 # 240x160
        -soll_xmaly VGA8                # 240x180
        -soll_xmaly 3DS                 # 256x192
        -soll_xmaly VHS                 # 320x240
        -soll_xmaly VCD                 # 352x288 - es ist ein h263-Format
        -soll_xmaly Palm_HiRes          # 320x320
        -soll_xmaly WQVGA               # 432x240
        -soll_xmaly QSVGA               # 400x300
        -soll_xmaly PSP                 # 480x272
        -soll_xmaly PSION5              # 640x240
        -soll_xmaly HVGA                # 480x320
        -soll_xmaly 2CIF                # 704x288
        -soll_xmaly SVHS                # 533x400
        -soll_xmaly EGA                 # 640x350
        -soll_xmaly QHD_ready           # 640x360
        -soll_xmaly HSVGA               # 600x400
        -soll_xmaly HGC                 # 720x348
#------------------------------------------------------------------------------#
        -soll_xmaly MDA                 # 720x350
        -soll_xmaly Apple_Lisa          # 720x364
        -soll_xmaly SVCD                # 480x576
        -soll_xmaly WGA                 # 720x400
        -soll_xmaly VGA                 # 640x480
        -soll_xmaly NTSC                # 720x480
        -soll_xmaly WVGA3               # 800x480
        -soll_xmaly WVGA2               # 720x540
        -soll_xmaly 4CIF                # 704x576 - es ist ein h263-Format
        -soll_xmaly WVGA4               # 848x480
        -soll_xmaly WVGA5               # 852x480
        -soll_xmaly FWVGA               # 854x480 - Full Wide VGA - Nintendo Wii U GamePad, LG K3 (LGE K100, LS450)
        -soll_xmaly WVGA7               # 864x480
        -soll_xmaly PAL                 # 720x576
        -soll_xmaly WVGA6               # 858x484
        -soll_xmaly PAL-D               # 768x576
        -soll_xmaly SVGA                # 800x600
        -soll_xmaly QHD                 # 960x540
        -soll_xmaly HXGA                # 832x624
        -soll_xmaly PS_Vita             # 964x544
        -soll_xmaly iPad                # 1024x576
        -soll_xmaly WSVGA               # 1024x600
        -soll_xmaly DVGA                # 960x640
        -soll_xmaly WSVGA2              # 1072x600
        -soll_xmaly DVGA2               # 960x720
        -soll_xmaly EVGA                # 1024x768
        -soll_xmaly 9CIF                # 1056x864
        -soll_xmaly HDTV                # 1280x720
        -soll_xmaly DSVGA               # 1200x800
        -soll_xmaly WXGA                # 1280x768
        -soll_xmaly XGA2                # 1152x864
        -soll_xmaly WXGA1               # 1280x800
        -soll_xmaly WXGA2               # 1360x768
        -soll_xmaly WXGA3               # 1366x768
        -soll_xmaly WXGA4               # 1376x768
        -soll_xmaly OLPC                # 1200x900
        -soll_xmaly UWXGA               # 1600x768
        -soll_xmaly SXVGA               # 1280x960
        -soll_xmaly WXGA+               # 1400x900
        -soll_xmaly WXGA+2              # 1440x900
        -soll_xmaly SXGA                # 1280x1024
        -soll_xmaly WXGA+Apple          # 1440x960
        -soll_xmaly WSXGA               # 1600x900
        -soll_xmaly SXGA+               # 1400x1050
        -soll_xmaly 16CIF               # 1408x1152 - es ist ein h263-Format
        -soll_xmaly WSXGA2              # 1600x1024
        -soll_xmaly WSXGA+              # 1680x1050
        -soll_xmaly UXGA                # 1600x1200
        -soll_xmaly HD                  # 1920x1080
        -soll_xmaly WUXGA               # 1920x1200
        -soll_xmaly QWXGA               # 2048x1152
        -soll_xmaly TXGA                # 1920x1400
        -soll_xmaly UW-UXGA             # 2560x1080
        -soll_xmaly TXGA2               # 1920x1440
        -soll_xmaly 2K                  # 2048x1536
        -soll_xmaly WQHD                # 2560x1440
        -soll_xmaly WQXGA               # 2560x1600
        -soll_xmaly UWQHD               # 3440x1440
        -soll_xmaly QSXGA               # 2560x2048
        -soll_xmaly QHD+                # 3200x1800
        -soll_xmaly QSXGA+              # 2800x2100
        -soll_xmaly UW4k                # 3840x1600
        -soll_xmaly WQSXGA              # 3200x2048
        -soll_xmaly QUXGA               # 3200x2400
        -soll_xmaly UHD4K               # 3840x2160
        -soll_xmaly 4K2K                # 4096x2160
        -soll_xmaly WQUXGA              # 3840x2400
        -soll_xmaly Retina4K            # 4096x2304
        -soll_xmaly 4K                  # 4096x3072
        -soll_xmaly UHD+                # 5120x2880
        -soll_xmaly WHXGA               # 5120x3200
        -soll_xmaly HSXGA               # 5120x4096
        -soll_xmaly WHSXGA              # 6400x4096
        -soll_xmaly HUXGA               # 6400x4800
        -soll_xmaly FUHD                # 7680x4320
        -soll_xmaly UHXGA               # 7680x4800
        -soll_xmaly QUHD                # 15360x8640
"

#------------------------------------------------------------------------------#
### Filmwandler_grafik.txt
################################################################################


ausgabe_hilfe()
{
echo "
#==============================================================================#
"
egrep -h '^[*][* ]' ${AVERZ}/Filmwandler_Format_*.txt
echo "
#==============================================================================#
"
}


#==============================================================================#

if [ -z "$1" ] ; then
        ${0} -h
	exit 10
fi

while [ "${#}" -ne "0" ]; do
        case "${1}" in
                -q)
                        FILMDATEI="${2}"	# Name für die Quelldatei
                        shift
                        ;;
                -z)
                        ZIELPFAD="${2}"		# Name für die Zieldatei
                        shift
                        ;;
                -c|-crop)
                        CROP="${2}"		# zum entfernen der schwarzen Balken: -vf crop=width:height:x:y
                        shift
                        ;;
                -dar|-ist_dar)
                        IST_DAR="${2}"		# Display-Format
                        shift
                        ;;
                -fps|-soll_fps)
                        SOLL_FPS="${2}"		# FPS (Bilder pro Sekunde) für den neuen Film festlegen
                        shift
                        ;;
                -par|-ist_par)
                        IST_PAR="${2}"		# Pixel-Format
                        shift
                        ;;
                -in_xmaly|-ist_xmaly)
                        IST_XY="${2}"		# Bildauflösung/Rasterformat der Quelle
                        shift
                        ;;
                -out_xmaly|-soll_xmaly)
                        SOLL_XY="${2}"		# Bildauflösung/Rasterformat der Ausgabe
                        shift
                        ;;
                -aq|-soll_aq)
                        TONQUALIT="${2}"	# Audio-Qualität
                        shift
                        ;;
                -vq|-soll_vq)
                        BILDQUALIT="${2}"	# Video-Qualität
                        shift
                        ;;
                -ton)
                        # Wirddiese Option nicht verwendet, dann werden ALLE Tonspuren eingebettet
                        # "0" für die erste Tonspur
                        # "1" für die zweite Tonspur
                        # "0,1" für die erste und die zweite Tonspur
                        TONSPUR="${2}"		# -ton 0,1,2,3,4
                        shift
                        ;;
                -stereo)
                        #STEREO="-ac 2"		# Stereo-Ausgabe erzwingen
			# Stereo-Ausgabe erzwingen 
                        # 5.1 mischen auf algorithmus von Dave_750 
                        # hier werden die tiefbass spur (LFE) mit abgemischt
                        # das trifft bei -ac 2 nicht zu (ATSC standards)
                        # -ac 2 als filter:
                        # -af "pan=stereo|FL < 1.0*FL + 0.707*FC + 0.707*BL|FR < 1.0*FR + 0.707*FC + 0.707*BR"
                        # Quelle: https://superuser.com/questions/852400/properly-downmix-5-1-to-stereo-using-ffmpeg/1410620#1410620
                        STEREO="-filter_complex pan='stereo|FL=0.5*FC+0.707*FL+0.707*BL+0.5*LFE|FR=0.5*FC+0.707*FR+0.707*BR+0.5*LFE',volume='1.562500'"
                        # NighMode 
                        # The Nightmode Dialogue formula, created by Robert Collier on the Doom9 forum and sourced by Shane Harrelson in his answer, 
                        # results in a far better downmix than the ac -2 switch - instead of overly quiet dialogues, it brings them back to levels that are much closer to the source.
                        #STEREO="-filter_complex pan='stereo|FL=FC+0.30*FL+0.30*BL|FR=FC+0.30*FR+0.30*BR'"
                        shift
                        ;;
                -schnitt)
                        SCHNITTZEITEN="${2}"	# zum Beispiel zum Werbung entfernen (in Sekunden, Dezimaltrennzeichen ist der Punkt): -schnitt "10-432 520-833 1050-1280"
                        shift
                        ;;
                -test|-t)
                        ORIGINAL_PIXEL="Ja"	# um die richtigen CROP-Parameter zu ermitteln
                        shift
                        ;;
                -u)
                        # Wirddiese Option nicht verwendet, dann werden ALLE Untertitelspuren eingebettet
                        # "-1" für keinen Untertitel
                        # "0" für die erste Untertitelspur
                        # "1" für die zweite Untertitelspur
                        # "0,1" für die erste und die zweite Untertitelspur
                        UNTERTITEL="${2}"	# -u 0,1,2,3,4
                        shift
                        ;;
                -g)
			echo "${BILD_FORMATNAMEN_AUFLOESUNGEN}"
                        exit 11
                        ;;
                -h)
			ausgabe_hilfe
                        echo "HILFE:
        # Video- und Audio-Spur in ein HTML5-kompatibles Format transkodieren

        # grundsaetzlich ist der Aufbau wie folgt,
        # die Reihenfolge der Optionen ist unwichtig
        ${0} [Option] -q [Filmname] -z [Neuer_Filmname.mp4]
        ${0} -q [Filmname] -z [Neuer_Filmname.mp4] [Option]

        # ein Beispiel mit minimaler Anzahl an Parametern
        ${0} -q Film.avi -z Film.mp4

        # ein Beispiel, bei dem die erste Untertitelspur (Zählweise beginnt mit '0'!) übernommen wird
        ${0} -q Film.avi -u 0 -z Film.mp4
        # ein Beispiel, bei dem die zweite Untertitelspur übernommen wird
        ${0} -q Film.avi -u 1 -z Film.mp4
        # ein Beispiel, bei dem die erste und die zweite Untertitelspur übernommen werden
        ${0} -q Film.avi -u 0,1 -z Film.mp4

        # Es duerfen in den Dateinamen keine Leerzeichen, Sonderzeichen
        # oder Klammern enthalten sein!
        # Leerzeichen kann aber innerhalb von Klammer trotzdem verwenden
        ${0} -q \"Filmname mit Leerzeichen.avi\" -z Film.mp4

        # wenn der Film mehrer Tonspuren besitzt
        # und nicht die erste verwendet werden soll,
        # dann wird so die 2. Tonspur angegeben (die Zaehlweise beginnt mit 0)
        -ton 1

        # wenn der Film mehrer Tonspuren besitzt
        # und nicht die erste verwendet werden soll,
        # dann wird so die 3. Tonspur angegeben (die Zaehlweise beginnt mit 0)
        -ton 2

	# Stereo-Ausgabe erzwingen
	# egal wieviele Audio-Kanäle der Originalfilm hat, der neue Film wird Stereo haben
	-stereo

        # Bildwiederholrate für den neuen Film festlegen,
        # manche Geräte können nur eine begrenzte Zahl an Bildern pro Sekunde (FPS)
        -soll_fps 15
        -fps 20

        # wenn die Bildaufloesung des Originalfilmes nicht automatisch ermittelt
        # werden kann, dann muss sie manuell als Parameter uebergeben werden
        -ist_xmaly 480x270
        -in_xmaly 480x270

        # wenn das Bildformat des Originalfilmes nicht automatisch ermittelt
        # werden kann, dann muss es manuell als Parameter uebergeben werden
        -dar 16:9
        -ist_dar 16:9

        # wenn die Pixelgeometrie des Originalfilmes nicht automatisch ermittelt
        # werden kann, dann muss sie manuell als Parameter uebergeben werden
        -par 64:45
        -ist_par 64:45

        # will man eine andere Video-Qualitaet, dann sie manuell als Parameter
        # uebergeben werden
        -vq 5
        -soll_vq 5

        # will man eine andere Audio-Qualitaet, dann sie manuell als Parameter
        # uebergeben werden
        -aq 3
        -soll_aq 3

        # Man kann aus dem Film einige Teile entfernen, zum Beispiel Werbung.
        # Angaben muessen in Sekunden erfolgen,
        # Dezimaltrennzeichen ist der Punkt.
        # Die Zeit-Angaben beschreiben die Laufzeit des Filmes,
        # so wie der CLI-Video-Player 'MPlayer' sie
        # in der untersten Zeile anzeigt.
        # Hier werden zwei Teile (432-520 und 833.5-1050) aus dem vorliegenden
        # Film entfernt bzw. drei Teile (8.5-432 und 520-833.5 und 1050-1280)
        # aus dem vorliegenden Film zu einem neuen Film zusammengesetzt.
        -schnitt '8.5-432 520-833.5 1050-1280'

        # will man z.B. von einem 4/3-Film, der als 16/9-Film (720x576)
        # mit schwarzen Balken an den Seiten, diese schwarzen Balken entfernen,
        # dann könnte das zum Beispiel so gemacht werden:
        -crop '540:576:90:0'

        # die gewünschte Bildauflösung des neuen Filmes
        -soll_xmaly 720x576		# deutscher Parametername
        -out_xmaly 720x480		# englischer Parametername
        -soll_xmaly 965x543		# frei wählbares Bildformat kann angegeben werden
        -soll_xmaly VCD			# Name eines Bildformates kann angegeben werden

	mögliche Namen von Grafikauflösungen anzeigen
	=> ${0} -g
                        "
                        exit 12
                        ;;
                *)
                        if [ "$(echo "${1}"|egrep '^-')" ] ; then
                                echo "Der Parameter '${1}' wird nicht unterstützt!"
				export STOP="Ja"
                        fi
                        shift
                        ;;
        esac
done


#==============================================================================#
### Programm

PROGRAMM="$(which ffmpeg)"
if [ "x${PROGRAMM}" == "x" ] ; then
	PROGRAMM="$(which avconv)"
fi

if [ "x${PROGRAMM}" == "x" ] ; then
	echo "Weder avconv noch ffmpeg konnten gefunden werden. Abbruch!"
	exit 15
fi

REPARATUR_PARAMETER="-fflags +genpts"

#==============================================================================#
### Trivialitäts-Check

if [ "${STOP}" = "Ja" ] ; then
        echo "Bitte korrigieren sie die falschen Parameter. Abbruch!"
        exit 13
fi

#------------------------------------------------------------------------------#

if [ ! -r "${FILMDATEI}" ] ; then
        echo "Der Film '${FILMDATEI}' konnte nicht gefunden werden. Abbruch!"
        exit 14
fi

#------------------------------------------------------------------------------#
# damit die Zieldatei mit Verzeichnis angegeben werden kann

QUELL_DATEI="$(basename ${FILMDATEI})"
ZIELVERZ="$(dirname ${ZIELPFAD})"
ZIELDATEI="$(basename ${ZIELPFAD})"

#------------------------------------------------------------------------------#
# damit keine Leerzeichen im Dateinamen enthalten sind

ZIELDATEI="$(echo "${ZIELDATEI}" | rev | sed 's/[.]/ /' | rev | awk '{print $1"."$2}')"

#==============================================================================#
# Das Video-Format wird nach der Dateiendung ermittelt
# deshalb muss ermittelt werden, welche Dateiendung der Name der Ziel-Datei hat
#
# Wenn der Name der Quell-Datei und der Name der Ziel-Datei gleich sind,
# dann wird dem Namen der Ziel-Datei ein "Nr2" vor der Endung angehängt
#

QUELL_BASIS_NAME="$(echo "${QUELL_DATEI}" | awk '{print tolower($0)}')"
ZIEL_BASIS_NAME="$(echo "${ZIELDATEI}" | awk '{print tolower($0)}')"

ZIELNAME="$(echo "${ZIELDATEI}" | rev | sed 's/[ ][ ]*/_/g;s/.*[.]//' | rev)"
ENDUNG="$(echo "${ZIEL_BASIS_NAME}" | rev | sed 's/[a-zA-Z0-9\_\-\+/][a-zA-Z0-9\_\-\+/]*[.]/&"/;s/[.]".*//' | rev)"

if [ "${ENDUNG}" != "mp4" ] ; then 
	echo "Fehler: Die Endung der Zieldatei darf nur 'mp4' sein."
	exit 232
fi

if [ "${QUELL_BASIS_NAME}" = "${ZIEL_BASIS_NAME}" ] ; then
	ZIELNAME="${ZIELNAME}_Nr2"
fi

#------------------------------------------------------------------------------#
### ab hier kann in die Log-Datei geschrieben werden

#rm -f ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
echo "# $(date +'%F %T')
${0} ${Film2Standardformat_OPTIONEN}" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt

echo "
${FORMAT_BESCHREIBUNG}
" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt

#------------------------------------------------------------------------------#

###====

#==============================================================================#
#==============================================================================#
### Video
#
# IN-Daten (META-Daten) aus der Filmdatei lesen
#

#------------------------------------------------------------------------------#
### FFmpeg verwendet drei verschiedene Zeitangaben:
# http://ffmpeg-users.933282.n4.nabble.com/What-does-the-output-of-ffmpeg-mean-tbr-tbn-tbc-etc-td941538.html
# http://stackoverflow.com/questions/3199489/meaning-of-ffmpeg-output-tbc-tbn-tbr
# tbn = the time base in AVStream that has come from the container
# tbc = the time base in AVCodecContext for the codec used for a particular stream
# tbr = tbr is guessed from the video stream and is the value users want to see when they look for the video frame rate
#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
# Input #0, mov,mp4,m4a,3gp,3g2,mj2, from '79613_Fluch_der_Karibik_13.09.14_20-15_orf1_130_TVOON_DE.mpg.HQ.cut.mp4':
#     Stream #0:0(und): Video: h264 (High) (avc1 / 0x31637661), yuv420p(tv, bt470bg), 720x576 [SAR 64:45 DAR 16:9], 816 kb/s, 25 fps, 25 tbr, 100 tbn, 50 tbc (default)
#------------------------------------------------------------------------------#
# Input #0, matroska,webm, from 'Fluch_der_Karibik_1_Der_Fluch_der_Black_Pearl_-_Pirates_of_the_Caribbean_The_Curse_of_the_Black_Pearl/Fluch_der_Karibik_1.mkv':
#     Stream #0:0(eng): Video: h264 (High), yuv420p, 1920x816, SAR 1:1 DAR 40:17, 23.98 fps, 23.98 tbr, 1k tbn, 47.95 tbc (default)
#------------------------------------------------------------------------------#
# ffprobe "${FILMDATEI}" 2>&1 | fgrep Video: | tr -s '[\[,\]]' '\n' | egrep -B1 'SAR |DAR ' | tr -s '\n' ' ' ; echo ; done
#  720x576 SAR 64:45 DAR 16:9
#  1920x816 SAR 1:1 DAR 40:17
#------------------------------------------------------------------------------#
### Meta-Daten auslesen

META_DATEN_INFO="$(ffprobe "${FILMDATEI}" 2>&1 | sed -ne '/^Input /,//p')"
META_DATEN_STREAM="$(ffprobe -show_data -show_streams "${FILMDATEI}" 2>/dev/null)"

echo "${META_DATEN_INFO}"                                             | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
echo "${META_DATEN_STREAM}" | grep -E '^codec_(name|long_name|type)=' | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt

#------------------------------------------------------------------------------#
### hier wird ermittelt, wieviele Audio-Kanäle max. im Film enthalten sind

AUDIO_KANAELE="$(echo "${META_DATEN_STREAM}" | sed -e '1,/^codec_type=audio/ d' | awk -F'=' '/^channels=/{print $2}' | sort -nr | head -n1)"	# max. Anzahl der vorhandenen Audio-Kanäle
if [ "x${STEREO}" != "x" ] ; then
	AUDIO_KANAELE="2"
fi

#------------------------------------------------------------------------------#
### hier wird eine Liste externer verfügbarer Codecs erstellt

FFMPEG_LIB="$((ffmpeg -formats >/dev/null) 2>&1 | tr -s ' ' '\n' | egrep '^[-][-]enable[-]' | sed 's/^[-]*enable[-]*//;s/[-]/_/g' | egrep '^lib')"
FFMPEG_FORMATS="$(ffmpeg -formats 2>/dev/null | awk '/^[ \t]*[ ][DE]+[ ]/{print $2}')"

#------------------------------------------------------------------------------#
### alternative Methode zur Ermittlung der FPS
R_FPS="$(echo "${META_DATEN_STREAM}" | egrep '^codec_type=|^r_frame_rate=' | egrep -A1 '^codec_type=video' | awk -F'=' '/^r_frame_rate=/{print $2}' | sed 's|/| |')"
A_FPS="$(echo "${R_FPS}" | wc -w)"
if [ "${A_FPS}" -gt 1 ] ; then
	R_FPS="$(echo "${R_FPS}" | awk '{print $1 / $2}')"
fi
#------------------------------------------------------------------------------#
### hier wird ermittelt, ob der film progressiv oder im Zeilensprungverfahren vorliegt

# tbn (FPS vom Container)            = the time base in AVStream that has come from the container
# tbc (FPS vom Codec)                = the time base in AVCodecContext for the codec used for a particular stream
# tbr (FPS vom Video-Stream geraten) = tbr is guessed from the video stream and is the value users want to see when they look for the video frame rate

SCAN_TYPE="$(echo "${META_DATEN_STREAM}" | awk '/^field_order=/{print $2}' | grep -Ev '^$' | head -n1)"
echo "SCAN_TYPE='${SCAN_TYPE}'"
if [ "${SCAN_TYPE}" != "progressive" ] ; then
        ### wenn der Film im Zeilensprungverfahren vorliegt
        ZEILENSPRUNG="yadif,"
fi

#exit 17

# META_DATEN_STREAM=" width=720 "
# META_DATEN_STREAM=" height=576 "
IN_BREIT="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^width=/{print $2}' | grep -Fv 'N/A' | head -n1)"
IN_HOCH="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^height=/{print $2}' | grep -Fv 'N/A' | head -n1)"
IN_XY="${IN_BREIT}x${IN_HOCH}"
echo "
1 IN_XY='${IN_XY}'
1 IN_BREIT='${IN_BREIT}'
1 IN_HOCH='${IN_HOCH}'
" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
if [ "${IN_XY}" == "x" ] ; then
	# META_DATEN_INFO=' 720x576 SAR 64:45 DAR 16:9 25 fps '
	# META_DATEN_INFO=" 852x480 SAR 1:1 DAR 71:40 25 fps "
	# META_DATEN_INFO=' 1920x800 SAR 1:1 DAR 12:5 23.98 fps '
	IN_XY="$(echo "${META_DATEN_INFO}" | fgrep 'Video: ' | tr -s ',' '\n' | fgrep ' DAR ' | awk '{print $1}' | head -n1)"
	IN_BREIT="$(echo "${IN_XY}" | awk -F'x' '{print $1}')"
	IN_HOCH="$(echo  "${IN_XY}" | awk -F'x' '{print $2}')"
	echo "
	2 IN_XY='${IN_XY}'
	2 IN_BREIT='${IN_BREIT}'
	2 IN_HOCH='${IN_HOCH}'
	" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
	if [ "x${IN_XY}" == "x" ] ; then
		# META_DATEN_STREAM=" coded_width=0 "
		# META_DATEN_STREAM=" coded_height=0 "
		IN_BREIT="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^coded_width=/{print $2}' | grep -Fv 'N/A' | grep -Ev '^0$' | head -n1)"
		IN_HOCH="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^coded_height=/{print $2}' | grep -Fv 'N/A' | grep -Ev '^0$' | head -n1)"
		IN_XY="${IN_BREIT}x${IN_HOCH}"
		echo "
		3 IN_XY='${IN_XY}'
		3 IN_BREIT='${IN_BREIT}'
		3 IN_HOCH='${IN_HOCH}'
		" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
	fi
fi

IN_PAR="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^sample_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | head -n1)"
echo "
1 IN_PAR='${IN_PAR}'
" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
if [ "x${IN_PAR}" == "x" ] ; then
	IN_PAR="$(echo "${META_DATEN_INFO}" | fgrep 'Video: ' | tr -s ',' '\n' | fgrep ' DAR ' | tr -s '[\[\]]' ' ' | awk '{print $3}')"
	echo "
	2 IN_PAR='${IN_PAR}'
	" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
fi

IN_DAR="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^display_aspect_ratio=/{print $2}' | grep -Fv 'N/A' | head -n1)"
echo "
1 IN_DAR='${IN_DAR}'
" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
if [ "x${IN_DAR}" == "x" ] ; then
	IN_DAR="$(echo "${META_DATEN_INFO}" | fgrep 'Video: ' | tr -s ',' '\n' | fgrep ' DAR ' | tr -s '[\[\]]' ' ' | awk '{print $5}')"
	echo "
	2 IN_DAR='${IN_DAR}'
	" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
fi

# META_DATEN_STREAM=" r_frame_rate=25/1 "
# META_DATEN_STREAM=" avg_frame_rate=25/1 "
# META_DATEN_STREAM=" codec_time_base=1/25 "
IN_FPS="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^r_frame_rate=/{print $2}' | grep -Fv 'N/A' | head -n1 | awk -F'/' '{print $1}')"
echo "
1 IN_FPS='${IN_FPS}'
" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
if [ "x${IN_FPS}" == "x" ] ; then
	IN_FPS="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^avg_frame_rate=/{print $2}' | grep -Fv 'N/A' | head -n1 | awk -F'/' '{print $1}')"
	echo "
	2 IN_FPS='${IN_FPS}'
	" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
	if [ "x${IN_FPS}" == "x" ] ; then
		IN_FPS="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^codec_time_base=/{print $2}' | grep -Fv 'N/A' | head -n1 | awk -F'/' '{print $2}')"
		echo "
		3 IN_FPS='${IN_FPS}'
		" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
		if [ "x${IN_FPS}" == "x" ] ; then
			IN_FPS="$(echo "${META_DATEN_INFO}" | fgrep 'Video: ' | tr -s ',' '\n' | fgrep ' fps' | awk '{print $1}')"			# wird benötigt um den Farbraum für BluRay zu ermitteln
			echo "
			4 IN_FPS='${IN_FPS}'
			" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
		fi
	fi
fi

IN_FPS_RUND="$(echo "${IN_FPS}" | awk '{printf "%.0f\n", $1}')"			# für Vergleiche, "if" erwartet einen Integerwert

IN_BIT_RATE="$(echo "${META_DATEN_STREAM}" | sed -ne '/video/,/STREAM/ p' | awk -F'=' '/^bit_rate=/{print $2}' | grep -Fv 'N/A' | head -n1)"
echo "
1 IN_BIT_RATE='${IN_BIT_RATE}'
" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
if [ "x${IN_BIT_RATE}" == "x" ] ; then
	IN_BIT_RATE="$(echo "${META_DATEN_INFO}" | grep -F 'Video: ' | tr -s ',' '\n' | awk -F':' '/bitrate: /{print $2}' | tail -n1)"
	echo "
	2 IN_BIT_RATE='${IN_BIT_RATE}'
	" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
	if [ "x${IN_BIT_RATE}" == "x" ] ; then
		IN_BIT_RATE="$(echo "${META_DATEN_INFO}" | grep -F 'Duration: ' | tr -s ',' '\n' | awk -F':' '/bitrate: /{print $2}' | tail -n1)"
		echo "
		3 IN_BIT_RATE='${IN_BIT_RATE}'
		" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
	fi
fi

IN_BIT_EINH="$(echo "${IN_BIT_RATE}" | awk '{print $2}')"
case "${IN_BIT_EINH}" in
        [Kk]b[p/]s|[Kk]b[/]s)
                        IN_BITRATE_KB="$(echo "${IN_BIT_RATE}" | awk '{print $1}')"
                        ;;
        [Mm]b[p/]s|[Mm]b[/]s)
                        IN_BITRATE_KB="$(echo "${IN_BIT_RATE}" | awk '{print $1 * 1024}')"
                        ;;
esac

echo "
IN_XY='${IN_XY}'
IN_BREIT='${IN_BREIT}'
IN_HOCH='${IN_HOCH}'
IN_PAR='${IN_PAR}'
IN_DAR='${IN_DAR}'
IN_FPS='${IN_FPS}'
IN_FPS_RUND='${IN_FPS_RUND}'
IN_BIT_RATE='${IN_BIT_RATE}'
IN_BIT_EINH='${IN_BIT_EINH}'
IN_BITRATE_KB='${IN_BITRATE_KB}'
BILDQUALIT='${BILDQUALIT}'
TONQUALIT='${TONQUALIT}'
" | tee ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt

unset IN_BIT_RATE
unset IN_BIT_EINH

#exit 18

#==============================================================================#
### Korrektur: gelesene IN-Daten mit übergebenen IST-Daten überschreiben
###
### Es wird unbedingt das Rasterformat der Bildgröße (Breite x Höhe) benötigt!
###
### Weiterhin wird das Seitenverhältnis des Bildes (DAR) benötigt,
### dieser Wert kann aber auch aus dem Seitenverhältnis der Bildpunkte (PAR/SAR)
### errechnet werden.
###
### Sollte die Bildgröße bzw. DAR+PAR/SAR fehlen, bricht die Bearbeitung ab!
###
### zum Beispiel:
###	IN_XY  = 720 x 576 (Rasterformat der Bildgröße)
###	IN_PAR =  15 / 16  (PAR / SAR)
###	IN_DAR =   4 / 3   (DAR)
###
#------------------------------------------------------------------------------#
### Hier wird versucht dort zu interpolieren, wo es erforderlich ist.
### Es kann jedoch von den vier Werten (Breite+Höhe+DAR+PAR) nur einer
### mit Hilfe der drei vorhandenen Werte interpoliert werden.

#------------------------------------------------------------------------------#
### Rasterformat der Bildgröße

if [ -n "${IST_XY}" ] ; then
	IN_XY="${IST_XY}"
fi


if [ -z "${IN_XY}" ] ; then
	echo "Es konnte die Video-Auflösung nicht ermittelt werden."
	echo "versuchen Sie es mit diesem Parameter nocheinmal:"
	echo "-in_xmaly"
	echo "z.B. (PAL)     : -in_xmaly 720x576"
	echo "z.B. (NTSC)    : -in_xmaly 720x486"
	echo "z.B. (NTSC-DVD): -in_xmaly 720x480"
	echo "z.B. (HDTV)    : -in_xmaly 1280x720"
	echo "z.B. (FullHD)  : -in_xmaly 1920x1080"
	echo "ABBRUCH!"
	exit 19
fi


#------------------------------------------------------------------------------#
### Seitenverhältnis des Bildes (DAR)

if [ -n "${IST_DAR}" ] ; then
	IN_DAR="${IST_DAR}"
fi


#----------------------------------------------------------------------#
### Seitenverhältnis der Bildpunkte (PAR / SAR)

if [ -n "${IST_PAR}" ] ; then
	IN_PAR="${IST_PAR}"
fi


#----------------------------------------------------------------------#
### Seitenverhältnis der Bildpunkte - Arbeitswerte berechnen (PAR / SAR)

ARBEITSWERTE_PAR()
{
if [ -n "${IN_PAR}" ] ; then
	PAR="$(echo "${IN_PAR}" | egrep '[:/]')"
	if [ -n "${PAR}" ] ; then
		PAR_KOMMA="$(echo "${PAR}" | egrep '[:/]' | awk -F'[:/]' '{print $1/$2}')"
		PAR_FAKTOR="$(echo "${PAR}" | egrep '[:/]' | awk -F'[:/]' '{printf "%u\n", ($1*100000)/$2}')"
	else
		PAR="$(echo "${IN_PAR}" | fgrep '.')"
		PAR_KOMMA="${PAR}"
		PAR_FAKTOR="$(echo "${PAR}" | fgrep '.' | awk '{printf "%u\n", $1*100000}')"
	fi
fi
}

ARBEITSWERTE_PAR

echo "
PAR_FAKTOR='${PAR_FAKTOR}'
" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt


#------------------------------------------------------------------------------#
### Kontrolle Seitenverhältnis des Bildes (DAR)

if [ -z "${IN_DAR}" ] ; then
	IN_DAR="$(echo "${IN_BREIT} ${IN_HOCH} ${PAR_KOMMA}" | awk '{printf("%.16f\n",$3/($2/$1))}')"
fi


if [ -z "${IN_DAR}" ] ; then
	echo "Es konnte das Seitenverhältnis des Bildes nicht ermittelt werden."
	echo "versuchen Sie es mit einem dieser beiden Parameter nocheinmal:"
	echo "-in_dar"
	echo "z.B. (Röhre)   : -in_dar 4:3"
	echo "z.B. (Flat)    : -in_dar 16:9"
	echo "-in_par"
	echo "z.B. (PAL)     : -in_par 16:15"
	echo "z.B. (NTSC)    : -in_par  9:10"
	echo "z.B. (NTSC-DVD): -in_par  8:9"
	echo "z.B. (DVB/DVD) : -in_par 64:45"
	echo "z.B. (BluRay)  : -in_par  1:1"
	echo "ABBRUCH!"
	exit 20
fi


#----------------------------------------------------------------------#
### Seitenverhältnis des Bildes - Arbeitswerte berechnen (DAR)

DAR="$(echo "${IN_DAR}" | egrep '[:/]')"
if [ "x${DAR}" = x ] ; then
	DAR="$(echo "${IN_DAR}" | fgrep '.')"
	DAR_KOMMA="${DAR}"
	DAR_FAKTOR="$(echo "${DAR}" | fgrep '.' | awk '{printf "%u\n", $1*100000}')"
else
	DAR_KOMMA="$(echo "${DAR}" | egrep '[:/]' | awk -F'[:/]' '{print $1/$2}')"
	DAR_FAKTOR="$(echo "${DAR}" | egrep '[:/]' | awk -F'[:/]' '{printf "%u\n", ($1*100000)/$2}')"
fi


#----------------------------------------------------------------------#
### Kontrolle Seitenverhältnis der Bildpunkte (PAR / SAR)

if [ -z "${IN_PAR}" ] ; then
	IN_PAR="$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{printf "%.16f\n", ($2*$3)/$1}')"
fi


ARBEITSWERTE_PAR


#==============================================================================#
### Bildausschnitt

### CROPing
#
# oben und unten die schwarzen Balken entfernen
# crop=720:432:0:72
#
# von den Seiten die schwarzen Balken entfernen
# crop=540:576:90:0
#
if [ -n "${CROP}" ] ; then
	### CROP-Seiten-Format
	# -vf crop=width:height:x:y
	# -vf crop=in_w-100:in_h-100:100:100
	IN_BREIT="$(echo "${CROP}" | awk -F'[:/]' '{print $1}')"
	IN_HOCH="$(echo "${CROP}" | awk -F'[:/]' '{print $2}')"
	#X="$(echo "${CROP}" | awk -F'[:/]' '{print $3}')"
	#Y="$(echo "${CROP}" | awk -F'[:/]' '{print $4}')"

	### Display-Seiten-Format
	DAR_FAKTOR="$(echo "${PAR_FAKTOR} ${IN_BREIT} ${IN_HOCH}" | awk '{printf "%u\n", ($1*$2)/$3}')"
	DAR_KOMMA="$(echo "${DAR_FAKTOR}" | awk '{print $1/100000}')"

	CROP="crop=${CROP},"
fi


#------------------------------------------------------------------------------#
### Seitenverhältnis des Bildes (DAR) muss hier bekannt sein!

if [ -z "${DAR_FAKTOR}" ] ; then
	echo "Es konnte das Display-Format nicht ermittelt werden."
	echo "versuchen Sie es mit diesem Parameter nocheinmal:"
	echo "-dar"
	echo "z.B.: -dar 16:9"
	echo "ABBRUCH!"
	exit 21
fi


#------------------------------------------------------------------------------#
### ob die Pixel bereits quadratisch sind
if [ "${PAR_FAKTOR}" -ne "100000" ] ; then

	### Umrechnung in quadratische Pixel - Version 1
	#QUADR_SCALE="scale=$(echo "${DAR_KOMMA} ${IN_BREIT} ${IN_HOCH}" | awk '{b=sqrt($1*$2*$3); printf "%.0f %.0f\n", b/2, b/$1/2}' | awk '{print $1*2"x"$2*2}'),"
	#QUADR_SCALE="scale=$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{b=sqrt($1*$2*$3); printf "%.0f %.0f\n", b/2, b/$3/2}' | awk '{print $1*2"x"$2*2}'),"

	### Umrechnung in quadratische Pixel - Version 2
	#HALBE_HOEHE="$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{h=sqrt($1*$2/$3); printf "%.0f\n", h/2}')"
	#QUADR_SCALE="scale=$(echo "${HALBE_HOEHE} ${DAR_KOMMA}" | awk '{printf "%.0f %.0f\n", $1*$2, $1}' | awk '{print $1*2"x"$2*2}'),"
	#
	### [swscaler @ 0x81520d000] Warning: data is not aligned! This can lead to a speed loss
	### laut Googel müssen die Pixel durch 16 teilbar sein, beseitigt aber leider dieses Problem nicht
	#
	### die Pixel sollten wenigstens durch 2 teilbar sein! besser aber durch 8                          
	#TEILER="2"
	#TEILER="4"
	TEILER="8"
	#TEILER="16"
	TEIL_HOEHE="$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA} ${TEILER}" | awk '{h=sqrt($1*$2/$3); printf "%.0f\n", h/$4}')"
	QUADR_SCALE="scale=$(echo "${TEIL_HOEHE} ${DAR_KOMMA}" | awk '{printf "%.0f %.0f\n", $1*$2, $1}' | awk -v teiler="${TEILER}" '{print $1*teiler"x"$2*teiler}'),"

	QUADR_BREIT="$(echo "${QUADR_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $1}')"
	QUADR_HOCH="$(echo "${QUADR_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $2}')"
else
	### wenn die Pixel bereits quadratisch sind
	QUADR_BREIT="${IN_BREIT}"
	QUADR_HOCH="${IN_HOCH}"
fi


#------------------------------------------------------------------------------#
### universelle Variante
# iPad : VIDEOOPTION="-vf ${ZEILENSPRUNG}pad='max(iw\\,ih*(16/9)):ow/(16/9):(ow-iw)/2:(oh-ih)/2',scale='1024:576',setsar='1/1'"
# iPad : VIDEOOPTION="-vf ${ZEILENSPRUNG}scale='1024:576',setsar='1/1'"
# HTML5: VIDEOOPTION="-vf ${ZEILENSPRUNG}setsar='1/1'"
#
if [ "${DAR_FAKTOR}" -lt "149333" ] ; then
	HOEHE="4"
	BREITE="3"
else
	HOEHE="16"
	BREITE="9"
fi


#------------------------------------------------------------------------------#
### gewünschtes Rasterformat der Bildgröße (Auflösung)

if [ "${ORIGINAL_PIXEL}" = Ja ] ; then
	unset SOLL_SCALE
	unset SOLL_XY
else
	if [ "x${SOLL_XY}" = x ] ; then
		unset SOLL_SCALE
		unset SOLL_XY
	else
		SOLL_SCALE="scale=${SOLL_XY},"
	fi
fi

echo "
#1 SOLL_XY="${SOLL_XY}"
#2 SOLL_SCALE="${SOLL_SCALE}"
"


#------------------------------------------------------------------------------#
### Übersetzung von Bildauflösungsnamen zu Bildauflösungen
### tritt nur bei manueller Auswahl der Bildauflösung in Kraft

if [ "x${SOLL_XY}" != "x" ] ; then
	AUFLOESUNG_ODER_NAME="$(echo "${SOLL_XY}" | egrep '[0-9][0-9][0-9][x][0-9][0-9]')"
	if [ "x${AUFLOESUNG_ODER_NAME}" = "x" ] ; then
		### manuelle Auswahl der Bildauflösung per Namen
		if [ "x${BILD_FORMATNAMEN_AUFLOESUNGEN}" != "x" ] ; then
			SOLL_XY="$(echo "${BILD_FORMATNAMEN_AUFLOESUNGEN}" | egrep '[-]soll_xmaly ' | awk '{print $2,$4}' | egrep "^${SOLL_XY} " | awk '{print $2}')"
			SOLL_SCALE="scale=${SOLL_XY},"
		else
			echo "Die gewünschte Bildauflösung wurde als 'Name' angegeben: '${SOLL_XY}'"
			echo "Für die Übersetzung wird die Datei 'Filmwandler_grafik.txt' benötigt."
			echo "Leider konnte die Datei '$(dirname ${0})/Filmwandler_grafik.txt' nicht gelesen werden."
			exit 22
		fi
	fi
fi

echo "
#3 SOLL_XY="${SOLL_XY}"
#4 SOLL_SCALE="${SOLL_SCALE}"
"


#------------------------------------------------------------------------------#
### hier wird ausgerechnen wieviele Pixel der neue Film pro Bild haben wird
### und die gewünschte Breite und Höhe wird festgelegt, damit in anderen
### Funktionen weitere Berechningen für Modus, Bitrate u.a. errechnet werden
### kann

if [ "x${SOLL_XY}" = "x" ] ; then
	PIXELZAHL="$(echo "${IN_BREIT} ${IN_HOCH}" | awk '{print $1 * $2}')"
	VERGLEICH_BREIT="${IN_BREIT}"
	VERGLEICH_HOCH="${IN_HOCH}"
else
	P_BREIT="$(echo "${SOLL_XY}" | awk -F'x' '{print $1}')"
	P_HOCH="$(echo "${SOLL_XY}" | awk -F'x' '{print $2}')"
	PIXELZAHL="$(echo "${P_BREIT} ${P_HOCH}" | awk '{print $1 * $2}')"
	VERGLEICH_BREIT="${P_BREIT}"
	VERGLEICH_HOCH="${P_HOCH}"
fi


#------------------------------------------------------------------------------#

echo "
Originalauflösung   =${IN_BREIT}x${IN_HOCH}
erwünschte Auflösung=${SOLL_XY}
PIXELZAHL           =${PIXELZAHL}
"
#exit 23

#------------------------------------------------------------------------------#
### quadratische Bildpunkte sind der Standard

FORMAT_ANPASSUNG="setsar='1/1',"


#==============================================================================#

#echo "IN_FPS='${IN_FPS}'"
#exit 24
################################################################################
### Filmwandler_Format_mp4.txt
#------------------------------------------------------------------------------#

#==============================================================================#
#
# MP4
#
#==============================================================================#

VERSION="v2018083000"

###----
### Filmwandler_-_in-bit-per-pixel.txt

#==============================================================================#
#
# automatische Parameterermittlung für gleiche Qualität
#
# das geht z.Z. nur mit AVC (MP4 und MTS)
#
#==============================================================================#

VERSION="v2018082300"

#------------------------------------------------------------------------------#

# bei -c:v libx264 -profile:v high / FullHD - 1920×1080 = 2073600 Bildpunkte
# crf 15 ~ 8350 kb/s
# crf 16 ~ 7250 kb/s
# crf 17 ~ 6290 kb/s
# crf 18 ~ 5460 kb/s
# crf 19 ~ 4740 kb/s
# crf 20 ~ 4130 kb/s
# crf 21 ~ 3590 kb/s
# crf 22 ~ 3130 kb/s
# crf 23 ~ 2720 kb/s
# crf 24 ~ 2370 kb/s
# crf 25 ~ 2070 kb/s
# crf 26 ~ 1810 kb/s
# crf 27 ~ 1590 kb/s
# crf 28 ~ 1400 kb/s
# crf 29 ~ 1240 kb/s
# crf 30 ~ 1100 kb/s
# crf 31 ~ 980 kb/s
# crf 32 ~ 870 kb/s
# crf 33 ~ 780 kb/s
# crf 34 ~ 700 kb/s
# crf 35 ~ 630 kb/s

# CRF Bit/10Pixel BILDQUALIT
#  15 40
#  16 35          9
#  17 30
#  18 26          8
#  19 23
#  20 20          7
#  21 17
#  22 15          6
#  23 13
#  24 11          5
#  25 10
#  26 9           4
#  27 8
#  28 7           3
#  29 6
#  30 5           2
#  31 5
#  32 4           1
#  33 4
#  34 3           0
#  35 3

#------------------------------------------------------------------------------#

echo "1 BILDQUALIT='${BILDQUALIT}'" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
echo "IN_BITRATE_KB='${IN_BITRATE_KB}'" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt

if [ "${BILDQUALIT}" = "auto" ] ; then
	if [ "x${IN_BITRATE_KB}" != "x" ] ; then
		IN_BIT_je_BP="$(echo "${IN_BITRATE_KB} ${IN_BREIT} ${IN_HOCH}" | awk '{printf "%.0f\n", $1 * 10000 / $2 / $3}')"
		echo "IN_BIT_je_BP='${IN_BIT_je_BP}'" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt

		if   [ "${IN_BIT_je_BP}" -gt "26" ] ; then
			BILDQUALIT="9"
		elif [ "${IN_BIT_je_BP}" -gt "20" ] ; then
			BILDQUALIT="8"
		elif [ "${IN_BIT_je_BP}" -gt "15" ] ; then
			BILDQUALIT="7"
		elif [ "${IN_BIT_je_BP}" -gt "11" ] ; then
			BILDQUALIT="6"
		elif [ "${IN_BIT_je_BP}" -gt "9" ] ; then
			BILDQUALIT="5"
		elif [ "${IN_BIT_je_BP}" -gt "7" ] ; then
			BILDQUALIT="4"
		elif [ "${IN_BIT_je_BP}" -gt "5" ] ; then
			BILDQUALIT="3"
		elif [ "${IN_BIT_je_BP}" -gt "4" ] ; then
			BILDQUALIT="2"
		elif [ "${IN_BIT_je_BP}" -gt "3" ] ; then
			BILDQUALIT="1"
		else
			BILDQUALIT="0"
		fi
	fi
	echo "2 BILDQUALIT='${BILDQUALIT}'" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
fi

#------------------------------------------------------------------------------#

### Filmwandler_-_in-bit-per-pixel.txt
###----

#------------------------------------------------------------------------------#
#
# Leider kann eine MP4-Datei keinen AC3 (a52) - Codec abspielen.
#
#==============================================================================#

# Format
ENDUNG="mp4"
FORMAT="mp4"

#==============================================================================#

# Audio
###----
### Filmwandler_Codec_Audio_aac.txt
#
# AAC
#

#VERSION="v2018082900"
VERSION="v2019032200"

#------------------------------------------------------------------------------#
# https://trac.ffmpeg.org/wiki/Encode/AAC

### https://trac.ffmpeg.org/wiki/Encode/HighQualityAudio
#
#   Seit 2017 verfügt FFmpeg über einen eigenen, nativen Opus-Encoder
#   und -Decoder.
#   Die Mobil-Plattform Android unterstützt ab Version 5 (Lollipop)
#   Opus eingebettet in das Matroska-Containerformat nativ.

### libfdk_aac
###
### -b:a => funktioniert mit allen Encodern gut
### -vbr => funktioniert mit libfdk_aac nicht uneingeschränkt
### -q:a => funktioniert nur mit "aac" (libfdk_aac setzt es mit vbr gleich)
###
#
# laut Debian ist libfdk_aac "non-free"-Licenc
# laut FSF, Fedora, RedHat ist libfdk_aac "free"-Licenc
# 
# http://wiki.hydrogenaud.io/index.php?title=Fraunhofer_FDK_AAC#Recommended_Sampling_Rate_and_Bitrate_Combinations
# 
# libfdk_aac -> Note, the VBR setting is unsupported and only works with some parameter combinations.
# 
# FDK AAC kann im Modus "VBR" keine beliebige Kombination von Tonkanäle, Bit-Rate und Saple-Rate verarbeiten!
# Will man "VBR" verwenden, dann muss man explizit alle drei Parameter in erlaubter Größe angeben.

### 2018-07-15: [libfdk_aac @ 0x813af3900] Note, the VBR setting is unsupported and only works with some parameter combinations
### https://trac.ffmpeg.org/wiki/Encode/HighQualityAudio
### http://wiki.hydrogenaud.io/index.php?title=Fraunhofer_FDK_AAC#Audio_Object_Types
### http://wiki.hydrogenaud.io/index.php?title=Fraunhofer_FDK_AAC#Usage.2FExamples
#AUDIO_OPTION="-profile:a aac_he"
#AUDIO_OPTION="-profile:a aac_he_v2"
#AUDIO_QUALITAET_0="-vbr 1"                                      # 1 bis 5, 4 empfohlen / Constant (CBR): ~ 184 kb/s

#AUDIO_QUALITAET_0="-vbr 1"
#AUDIO_QUALITAET_1="-vbr 1"
#AUDIO_QUALITAET_2="-vbr 2"
#AUDIO_QUALITAET_3="-vbr 2"
#AUDIO_QUALITAET_4="-vbr 3"
#AUDIO_QUALITAET_5="-vbr 3"
#AUDIO_QUALITAET_6="-vbr 4"
#AUDIO_QUALITAET_7="-vbr 4"
#AUDIO_QUALITAET_8="-vbr 5"
#AUDIO_QUALITAET_9="-vbr 5"


#--------------------------------------------------------------
# FFmpeg-Option für "aac" (nativ/intern)
# https://slhck.info/video/2017/02/24/vbr-settings.html
# -q:a 0.12             # undokumentiert (0.1-?) / 0.12 ~ 128k
#------------------------------------------------------------------------------#

CODEC_PATTERN="aac"		# Beispiel: "h265|hevc"
AUDIOCODEC="$(echo "${FFMPEG_LIB}" | egrep "${CODEC_PATTERN}" | head -n1)"
if [ "x${AUDIOCODEC}" = "x" ] ; then
	AUDIOCODEC="$(echo "${FFMPEG_FORMATS}" | egrep "${CODEC_PATTERN}" | head -n1)"
	if [ "x${AUDIOCODEC}" = "x" ] ; then
		echo ""
		echo "${CODEC_PATTERN}"
		echo "Leider wird dieser Codec von der aktuell installierten Version"
		echo "von FFmpeg nicht unterstützt!"
		echo ""
		exit 1
	fi
fi

# libfdk_aac afterburner aktivieren für bessere audio qualität
# https://wiki.hydrogenaud.io/index.php?title=Fraunhofer_FDK_AAC#Afterburner
# Afterburner is "a type of analysis by synthesis algorithm which increases the audio quality but also the required processing power."
# Fraunhofer recommends to always activate this feature.
if [ "x${AUDIOCODEC}" = "xlibfdk_aac" ] ; then
        AUDIOCODEC="${AUDIOCODEC} -afterburner 1"
fi


# https://slhck.info/video/2017/02/24/vbr-settings.html
# undokumentiert (0.1-?) -> "-q:a 0.12" ~ 128k
#   August 2018: viel zu schlechte Qualität!
#   bei "-q:a" nimmt er immer "341 kb/s"


if [ "${AUDIO_KANAELE}" -gt 2 ] ; then
        AUDIO_QUALITAET_0="-b:a 160k"
        AUDIO_QUALITAET_1="-b:a 184k"
        AUDIO_QUALITAET_2="-b:a 216k"
        AUDIO_QUALITAET_3="-b:a 256k"
        AUDIO_QUALITAET_4="-b:a 296k"
        AUDIO_QUALITAET_5="-b:a 344k"
        AUDIO_QUALITAET_6="-b:a 400k"
        AUDIO_QUALITAET_7="-b:a 472k"
        AUDIO_QUALITAET_8="-b:a 552k"
        AUDIO_QUALITAET_9="-b:a 640k"
else
        AUDIO_QUALITAET_0="-b:a 64k"
        AUDIO_QUALITAET_1="-b:a 80k"
        AUDIO_QUALITAET_2="-b:a 88k"
        AUDIO_QUALITAET_3="-b:a 112k"
        AUDIO_QUALITAET_4="-b:a 128k"
        AUDIO_QUALITAET_5="-b:a 160k"
        AUDIO_QUALITAET_6="-b:a 184k"
        AUDIO_QUALITAET_7="-b:a 224k"
        AUDIO_QUALITAET_8="-b:a 264k"
        AUDIO_QUALITAET_9="-b:a 320k"
fi

### Filmwandler_Codec_Audio_aac.txt
###----


# Video
###----
### Filmwandler_Codec_Video_264.txt	# -> HTML5
#
# H.264 / AVC / MPEG-4 Part 10
#

VERSION="v2018082900"

CODEC_PATTERN="x264"		# Beispiel: "h264|x264" (libopenh264, libx264)
VIDEOCODEC="$(echo "${FFMPEG_LIB}" | fgrep "${CODEC_PATTERN}" | head -n1)"
if [ "x${VIDEOCODEC}" = "x" ] ; then
	VIDEOCODEC="$(echo "${FFMPEG_FORMATS}" | fgrep "${CODEC_PATTERN}" | head -n1)"
	if [ "x${VIDEOCODEC}" = "x" ] ; then
		echo ""
		echo "${CODEC_PATTERN}"
		echo "Leider wird dieser Codec von der aktuell installierten Version"
		echo "von FFmpeg nicht unterstützt!"
		echo ""
		exit 1
	fi
fi

### Bluray-kompatibele Werte errechnen
###----
### Filmwandler_-_Blu-ray-Disc_-_AVC.txt

#==============================================================================#
#
# AVC - optimiert auf Kompatibilität zur Blu-ray Disk
#
# x264opts
#           bluray-compat=1   =>   http://www.x264bluray.com/
#           b-pyramid=strict
#           nal-hrd=vbr
#
#==============================================================================#
### Video

#VERSION="v2018082900"
VERSION="v2019032200"

#------------------------------------------------------------------------------#
### Kompatibilität zur Blu-ray

#------------------------------------------------------------------------------#
### 2010-03-27 - Neuigkeiten vom x264-Team:
# x264 can now generate Blu-ray-compliant streams for authoring Blu-ray Discs!
# Compliance tested using Sony BD-ROM Verifier 1.21.
# x264 --crf 16 --preset veryslow --tune film --weightp 0 --bframes 3 \
#         --nal-hrd vbr --vbv-maxrate 40000 --vbv-bufsize 30000 --level 4.1 \
#         --keyint 24 --b-pyramid strict --slices 4 --aud --colorprim "bt709" \
#         --transfer "bt709" --colormatrix "bt709" --sar 1:1 <input> -o <output>

### https://encodingwissen.de/codecs/x264/referenz/#b-pyramid-modus
# "--b-pyramid strict" hat eine etwas schlechtere Qualität als "--b-pyramid normal",
# ist aber für Blu-Ray-kompatible B-Pyramide zwingend notwendig,
# ansonsten aber wenig nützlich.

### https://encodingwissen.de/codecs/x264/referenz/#bluray-compat
# "--bluray-compat" erzwingt ein blu-ray-kompatibles Encoding,
# der Schalter allein reicht aber für garantierte Kompatibilität zur Blu-ray
# nicht aus. => http://www.x264bluray.com/
# Mit diesem Schalter ist die Qualität etwas schlechtere.

### https://encodingwissen.de/codecs/x264/referenz/#slices-anzahl
# Legt die Anzahl an Slices fest, in jedes Bild zerlegt werden soll.
# Slices senken die Effizienz. Für ein normales Encoding sind sie unnötig
# und sollten deaktiviert bleiben.
# Lediglich wer H.264-Material für eine Video-BluRay erzeugt,
# muss mindestens vier Slices verwenden.

#------------------------------------------------------------------------------#
# http://forum.doom9.org/showthread.php?p=730001#post730001
# These are the properties listed in the levels tables in the standard, and how they should limit x264 settings:
#
# MaxMBPS >= width*height*fps. (w&h measured in macroblocks, i.e. pixels/16 round up in each dimension)
# MaxFS >= width*height
# sqrt(MaxFS*8) >= width
# sqrt(MaxFS*8) >= height
# MaxDPB >= if(pyramid) ; then MaxDPB >= (bytes in a frame) * min(16, ref + 2) ; elif(bframes) MaxDPB >= (bytes in a frame) * min(16, ref + 1) ; else MaxDPB >= (bytes in a frame) * ref ; fi
# MaxBR >= vbv_maxrate. It isn't strictly required since we don't write the VCL HRD parameters, but this satisfies the intent.
# MaxCPB >= vbv_bufsize. Likewise.
# MaxVmvR >= max_mv_range. (Not exposed in the cli, I'll add it if people care.)
# MaxMvsPer2Mb, MinLumaBiPredSize, direct_8x8_inference_flag : are not enforced by x264. The only way to ensure compliance is to disable p4x4 at level>=3.1, or at level>=3 w/ B-frames.
# MinCR : is not enforced by x264. Won't ever be an issue unless you use lossless.
# SliceRate : I don't know what this limits.

#==============================================================================#

#echo "63 IN_FPS='${IN_FPS}'"
#exit

#----------------------------------------------------------------------#

# MPEG-4 Part 10 (AVC) / x264
### funktioniert erst mit dem x264 ab Version vom 2010-04-25 (Bluray-kompatibel: --nal-hrd vbr)

#==============================================================================#
#==============================================================================#
### Funktionen

#----------------------------------------------------------------------#
### Bluray-kompatibele Werte errechnen

AVC_LEVEL()
{
        VERSION="v2014110200"
    
        # ${0} "Bildbreite in Makrobloecke" "Bildhoehe in Makobloecke" "Bilder pro Sekunde"
    
	#----------------------------------------------------------------------#
	# [libx264 @ 0x81361a100] frame MB size (120x68) > level limit (5120)
	# [libx264 @ 0x81361a100] DPB size (4 frames, 32640 mbs) > level limit (2 frames, 20480 mbs)
        #----------------------------------------------------------------------#
    

        ### frame MakroBlock size
	#echo "${1} ${2}" | awk '{print $1,"*",$2,"=",$1*$2}';

        MLEVEL="$(echo "${1} ${2}" | awk '{fmbs=$1*$2 ;\
		LEVEL=52 ;\
		if (fmbs < 36865) LEVEL=51 ;\
		if (fmbs < 22081) LEVEL=50 ;\
		if (fmbs < 8193) LEVEL=42 ;\
		if (fmbs < 5121) LEVEL=32 ;\
		if (fmbs < 3601) LEVEL=31 ;\
		if (fmbs < 1621) LEVEL=30 ;\
		if (fmbs < 793) LEVEL=21 ;\
		if (fmbs < 397) LEVEL=20 ;\
		if (fmbs < 100) LEVEL=10 ;\
		print LEVEL}')"
    

        ### MakroBlock rate
	#echo "${1} ${2} ${3}" | awk '{print $1,"*",$2,"*",$3,"=",$1*$2*$3}';

        RLEVEL="$(echo "${1} ${2} ${3}" | awk '{mbr=$1*$2*$3 ;\
		LEVEL=52 ;\
		if (mbr < 983041) LEVEL=51 ;\
		if (mbr < 589825) LEVEL=50 ;\
		if (mbr < 589825) LEVEL=42 ;\
		if (mbr < 216001) LEVEL=32 ;\
		if (mbr < 108001) LEVEL=31 ;\
		if (mbr < 40501) LEVEL=30 ;\
		if (mbr < 19801) LEVEL=21 ;\
		if (mbr < 11881) LEVEL=20 ;\
		if (mbr < 1486) LEVEL=10 ;\
		print LEVEL}')"
    
        #echo "${MLEVEL} -gt ${RLEVEL}"

        AVCLEVEL=""
        if [ "${MLEVEL}" -gt "${RLEVEL}" ] ; then
                AVCLEVEL="${MLEVEL}"
        else
                AVCLEVEL="${RLEVEL}"
        fi
    
        #----------------------------------------------------------------------#
    
        echo "${AVCLEVEL}" #| awk '{print $1 / 10}'
}

#----------------------------------------------------------------------#
BLURAY_PARAMETER()
{
        VERSION="v2014010500"
        PROFILE="high"

	# LEVEL="$(AVC_LEVEL ${IN_FPS} ${QUADR_MAKROBLOECKE})"
	# MaxFS="$(echo "${QUADR_BREIT} ${QUADR_HOCH}" | awk '{print $1 * $2}')"
	# BLURAY_PARAMETER ${LEVEL} ${QUADR_MAKROBLOECKE} ${MaxFS}
        FNKLEVEL="${1}"
        MBREITE="${2}"
        MHOEHE="${3}"
        MaxFS="${4}"

        #----------------------------------------------------------------------#
        ### Blu-ray-kompatible Parameter ermitteln

        # --bluray-compat

        echo "
	MBREITE='${MBREITE}'
	MHOEHE='${MHOEHE}'
	MaxFS='${MaxFS}'
        " | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
        BHVERH="$(echo "${MBREITE} ${MHOEHE} ${MaxFS}" | awk '{verhaeltnis="gut"; if ($1 > (sqrt($3 * 8))) verhaeltnis="schlecht" ; if ($2 > (sqrt($3 * 8))) verhaeltnis="schlecht" ; print verhaeltnis}')"

        if [ "${BHVERH}" != "gut" ] ; then
                echo "# BLURAY_PARAMETER:
                Seitenverhaeltnis wird von AVC nicht unterstuetzt!
                ABBRUCH
                " | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
                exit 1
        fi

        BIAF420="$(echo "${QUADR_BREIT} ${QUADR_HOCH}" | awk '{print $1 * $2 * 1.5}')"

        #----------------------------------------------------------------------#

        #LEVEL="$(echo "${FNKLEVEL}" | sed 's/[0-9]$/.&/')"
        LEVEL="$(echo "${FNKLEVEL}" | awk '{print $1 / 10}')"

        ### fuer 1000 bit/s !!!
        #   http://forum.doom9.org/showthread.php?t=101345
        if [ "${FNKLEVEL}" = "10" -a "${PROFILE}" = "high" ] ; then
                MaxBR="80"
                MaxCPB="175"
                MaxVmvR="-64,63.75"             # max. Vertical MV component range
                MinCR="2"
                CRF="25"
        elif [ "${FNKLEVEL}" = "20" -a "${PROFILE}" = "high" ] ; then
                MaxBR="2500"
                MaxCPB="2500"
                MaxVmvR="-128,127.75"           # max. Vertical MV component range
                MinCR="2"
                CRF="24"
        elif [ "${FNKLEVEL}" = "21" -a "${PROFILE}" = "high" ] ; then
                MaxBR="5000"
                MaxCPB="5000"
                MaxVmvR="-256,255.75"           # max. Vertical MV component range
                MinCR="2"
                CRF="24"
        elif [ "${FNKLEVEL}" = "30" -a "${PROFILE}" = "high" ] ; then
                MaxBR="12500"
                MaxCPB="12500"
                MaxVmvR="-256,255.75"           # max. Vertical MV component range
                MinCR="2"
                CRF="23"
        elif [ "${FNKLEVEL}" = "31" -a "${PROFILE}" = "high" ] ; then
                MaxBR="17500"
                MaxCPB="17500"
                MaxVmvR="-512,511.75"           # max. Vertical MV component range
                MinCR="4"
                CRF="23"
        elif [ "${FNKLEVEL}" = "32" -a "${PROFILE}" = "high" ] ; then
                MaxBR="25000"
                MaxCPB="25000"
                MaxVmvR="-512,511.75"           # max. Vertical MV component range
                MinCR="4"
                CRF="23"
        elif [ "${FNKLEVEL}" = "42" -a "${PROFILE}" = "high" ] ; then
                MaxBR="62500"
                MaxCPB="62500"
                MaxVmvR="-512,511.75"           # max. Vertical MV component range
                MinCR="2"
                CRF="22"
        elif [ "${FNKLEVEL}" = "50" -a "${PROFILE}" = "high" ] ; then
                MaxBR="168750"
                MaxCPB="168750"
                MaxVmvR="-512,511.75"           # max. Vertical MV component range
                MinCR="2"
                CRF="21"
        elif [ "${FNKLEVEL}" = "51" -a "${PROFILE}" = "high" ] ; then
                MaxBR="300000"
                MaxCPB="300000"
                MaxVmvR="-512,511.75"           # max. Vertical MV component range
                MinCR="2"
                CRF="20"
        fi

}

#==============================================================================#
#==============================================================================#
### ???

# if(pyramid)
#     MaxDPB >= (bytes in a frame) * min(16, ref + 2)
# else if(bframes)
#     MaxDPB >= (bytes in a frame) * min(16, ref + 1)
# else
#     MaxDPB >= (bytes in a frame) * ref

#----------------------------------------------------------------------#
### NTSC-, PAL- oder Blu-ray-Farbraum

#if [ "${IN_FPS}" = "10" -o "${IN_FPS}" = "15" -o "${IN_FPS}" = "20" -o "${IN_FPS}" = "24" ] ; then
#	# HDTV-Standard
#	FARBCOD="bt470"
#elif [ "${IN_FPS}" = "25" -o "${IN_FPS}" = "50" ] ; then
#	# DVD (PAL): 4/3 - 720x576
#	FARBCOD="bt470bg"
#else
#	# DVD (NTSC): 4/3 - 720x480
#	FARBCOD="smpte170m"        # SD: bt.601
#fi

#----------------------------------------------------------------------#
### Farbraum für SD oder HD

if [ "${QUADR_BREIT}" -gt "720" -o "${QUADR_HOCH}" -gt "576" ] ; then
	FARBCOD="bt709"            # HD: bt.709
else
	FARBCOD="smpte170m"        # SD: bt.601
fi

#----------------------------------------------------------------------#

KEYINT="$(echo "${IN_FPS}" | awk '{printf "%.0f\n", $1 * 2}')"	# alle 2 Sekunden ein Key-Frame
QUADR_MAKROBLOECKE="$(echo "${QUADR_BREIT} ${QUADR_HOCH}" | awk '{printf "%f %.0f %f %.0f\n",$1/16,$1/16,$2/16,$2/16}' | awk '{if ($1 > $2) $2 = $2+1 ; if ($3 > $4) $4 = $4+1 ; print $2,$4}')"
LEVEL="$(AVC_LEVEL ${QUADR_MAKROBLOECKE} ${IN_FPS})"
MaxFS="$(echo "${QUADR_BREIT} ${QUADR_HOCH}" | awk '{print $1 * $2}')"
BLURAY_PARAMETER ${LEVEL} ${QUADR_MAKROBLOECKE} ${MaxFS}

#==============================================================================#
### Qualität

# Mit CRF legt man die Bildqualität fest.
# Die Option "-crf 16" erzeugt eine sehr gute Blu Ray - Qualität.
# -crf 12-21 sind hinsichtlich Kodiergeschwindigkeit und Dateigröße "gut"
# -crf 16-21 ist ein praxistauglicher Bereich für sehr gute Qualität
# -crf 20-26 ist ein praxistauglicher Bereich für gute Qualität
# -crf 27-34 ist ein praxistauglicher Bereich für befriedigende Qualität
#
# Mit dem PRESET legt man die Dateigröße und die Kodiergeschwindigkeit fest.
# -preset ultrafast
# -preset superfast
# -preset veryfast
# -preset faster
# -preset fast
# -preset medium   (Standard)
# -preset slow     (bester Kompromiss)
# -preset slower   (nur unwesentlich besser als "slow" aber merklich langsamer)
# -preset veryslow (wenig besser aber sehr viel langsamer)

### https://encodingwissen.de/codecs/x264/referenz/#no-psy
### alle psychovisuellen Algorithmen werden abgeschaltet
### (auch interne, die keinen Schalter besitzen)
### mit diesem Parameter wird ca. 15% schneller kodiert
### und die kodierte Datei wird 10-36% kleiner sein
# --no-psy

### diese Option verbessert die Qualität
### und vergrößert die kodierte Datei um ca. 15-20%
# -tune zerolatency
# -tune fastdecode
# -tune film

#------------------------------------------------------------------------------#

#VIDEO_OPTION="-profile:v ${PROFILE} -preset veryslow -tune film -x264opts ref=4:b-pyramid=strict:bluray-compat=1:weightp=0:vbv-maxrate=${MaxBR}:vbv-bufsize=${MaxCPB}:level=${LEVEL}:slices=4:b-adapt=2:direct=auto:colorprim=${FARBCOD}:transfer=${FARBCOD}:colormatrix=${FARBCOD}:keyint=${KEYINT}:aud:subme=9"

VIDEO_OPTION="-profile:v ${PROFILE} -preset veryslow -tune film -x264opts ref=4:b-pyramid=strict:bluray-compat=1:weightp=0:vbv-maxrate=${MaxBR}:vbv-bufsize=${MaxCPB}:level=${LEVEL}:slices=4:b-adapt=2:direct=auto:colorprim=${FARBCOD}:transfer=${FARBCOD}:colormatrix=${FARBCOD}:keyint=${KEYINT}:aud:subme=9:nal-hrd=vbr"

# Stream funktion bei mp4 für SmartTV etc aktivieren
if [ "x${ENDUNG}" = "xmp4" ]; then
	VIDEO_OPTION="${VIDEO_OPTION} -movflags faststart"
fi

VIDEO_QUALITAET_0="${VIDEO_OPTION} -crf 30"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_1="${VIDEO_OPTION} -crf 28"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_2="${VIDEO_OPTION} -crf 26"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_3="${VIDEO_OPTION} -crf 24"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_4="${VIDEO_OPTION} -crf 22"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_5="${VIDEO_OPTION} -crf 20"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_6="${VIDEO_OPTION} -crf 19"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_7="${VIDEO_OPTION} -crf 18"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_8="${VIDEO_OPTION} -crf 17"		# von "0" (verlustfrei) bis "51"
VIDEO_QUALITAET_9="${VIDEO_OPTION} -crf 16"		# von "0" (verlustfrei) bis "51"

IFRAME="-keyint_min 2-8"

echo "
MLEVEL='${MLEVEL}'
RLEVEL='${RLEVEL}'
FNKLEVEL='${FNKLEVEL}'
LEVEL='${LEVEL}'

profile=${PROFILE}
rate=${MaxBR}
vbv-bufsize=${MaxCPB}
level=${LEVEL}
colormatrix='${FARBCOD}'

IN_FPS='${IN_FPS}'
VIDEO_OPTION='${VIDEO_OPTION}'
" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt

#==============================================================================#

### Filmwandler_-_Blu-ray-Disc_-_AVC.txt
###----

### Filmwandler_Codec_Video_264.txt	# -> HTML5
###----
IFRAME="-keyint_min 2-8"

#==============================================================================#

FORMAT_BESCHREIBUNG="
********************************************************************************
* Name:                 MP4                                                    *
* ENDUNG:               .mp4                                                   *
* Video-Kodierung:      H.264 (MPEG-4 Part 10 / AVC)                           *
* Audio-Kodierung:      AAC   (mehrkanalfähiger Nachfolger von MP3)            *
* Beschreibung:                                                                *
*       - HTML5-Unterstützung                                                  *
*       - auch abspielbar auf Android                                          *
********************************************************************************
"

#------------------------------------------------------------------------------#
### Filmwandler_Format_mp4.txt
################################################################################

###====

echo "
OP_QUELLE='${OP_QUELLE}'
" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
#exit 25

#==============================================================================#
### Qualität
#
# Qualitäts-Parameter-Übersetzung
# https://slhck.info/video/2017/02/24/vbr-settings.html
#

#------------------------------------------------------------------------------#
### Audio

if [ "${BILDQUALIT}" = "auto" ] ; then
        BILDQUALIT="5"
fi

if [ "${TONQUALIT}" = "auto" ] ; then
        TONQUALIT="5"
fi

case "${TONQUALIT}" in
	0)
		AUDIOQUALITAET="${AUDIO_QUALITAET_0}"
		;;
	1)
		AUDIOQUALITAET="${AUDIO_QUALITAET_1}"
		;;
	2)
		AUDIOQUALITAET="${AUDIO_QUALITAET_2}"
		;;
	3)
		AUDIOQUALITAET="${AUDIO_QUALITAET_3}"
		;;
	4)
		AUDIOQUALITAET="${AUDIO_QUALITAET_4}"
		;;
	5)
		AUDIOQUALITAET="${AUDIO_QUALITAET_5}"
		;;
	6)
		AUDIOQUALITAET="${AUDIO_QUALITAET_6}"
		;;
	7)
		AUDIOQUALITAET="${AUDIO_QUALITAET_7}"
		;;
	8)
		AUDIOQUALITAET="${AUDIO_QUALITAET_8}"
		;;
	9)
		AUDIOQUALITAET="${AUDIO_QUALITAET_9}"
		;;
esac

#------------------------------------------------------------------------------#
### Video

case "${BILDQUALIT}" in
	0)
		VIDEOQUALITAET="${VIDEO_QUALITAET_0}"
		;;
	1)
		VIDEOQUALITAET="${VIDEO_QUALITAET_1}"
		;;
	2)
		VIDEOQUALITAET="${VIDEO_QUALITAET_2}"
		;;
	3)
		VIDEOQUALITAET="${VIDEO_QUALITAET_3}"
		;;
	4)
		VIDEOQUALITAET="${VIDEO_QUALITAET_4}"
		;;
	5)
		VIDEOQUALITAET="${VIDEO_QUALITAET_5}"
		;;
	6)
		VIDEOQUALITAET="${VIDEO_QUALITAET_6}"
		;;
	7)
		VIDEOQUALITAET="${VIDEO_QUALITAET_7}"
		;;
	8)
		VIDEOQUALITAET="${VIDEO_QUALITAET_8}"
		;;
	9)
		VIDEOQUALITAET="${VIDEO_QUALITAET_9}"
		;;
esac


#------------------------------------------------------------------------------#

echo "
AUDIOCODEC=${AUDIOCODEC}
AUDIOQUALITAET=${AUDIOQUALITAET}

VIDEOCODEC=${VIDEOCODEC}
VIDEOQUALITAET=${VIDEOQUALITAET}
" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
#exit 26

#==============================================================================#
### Untertitel

# -map 0:s:0 -c:s copy -map 0:s:1 -c:s copy		# "0" für die erste Untertitelspur
# UNTERTITEL="-map 0:s:${i} -scodec copy"		# alt
# UNTERTITEL="-map 0:s:${i} -c:s copy"			# neu

if [ "${UNTERTITEL}" == "-1" ] ; then
	U_TITEL_FF=""
else
    if [ "x${UNTERTITEL}" == "x" ] ; then
	UT_LISTE="$(echo "${META_DATEN_STREAM}" | fgrep -i codec_type=subtitle | nl | awk '{print $1 - 1}' | tr -s '\n' ' ')"
    else
	UT_LISTE="$(echo "${UNTERTITEL}" | sed 's/,/ /g')"
    fi

    U_TITEL_FF="$(for DER_UT in ${UT_LISTE}
    do
	echo -n " -map 0:s:${DER_UT}? -c:s copy"
    done)"
fi

echo "
UNTERTITEL=${UNTERTITEL}
UT_LISTE=${UT_LISTE}
U_TITEL_FF=${U_TITEL_FF}
" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
#exit 16

#==============================================================================#
# Audio

if [ "x${TONSPUR}" == "x" ] ; then
        TSNAME="$(echo "${META_DATEN_STREAM}" | fgrep -i codec_type=audio | nl | awk '{print $1 - 1}' | tr -s '\n' ',' | sed 's/^,//;s/,$//')"
else
	TSNAME="${TONSPUR}"
fi

TS_LISTE="$(echo "${TSNAME}" | sed 's/,/ /g')"
TS_ANZAHL="$(echo "${TSNAME}" | sed 's/,/ /g' | wc -w | awk '{print $1}')"

if [ "${TS_ANZAHL}" -gt 0 ] ; then
	# soll Stereo-Ausgabe erzwungen werden?
	if [ "x${STEREO}" = x ] ; then
		_ST=""
	else
		# wurde die Ausgabe bereits durch die Codec-Optionen auf Stereo gesetzt?
		BEREITS_AC2="$(echo "${AUDIOCODEC} ${AUDIOQUALITAET}" | grep -E 'ac 2|stereo')"
		if [ "x${BEREITS_AC2}" = x ] ; then
			_ST="${STEREO}"
		else
			_ST=""
		fi
	fi

	AUDIO_VERARBEITUNG_01="$(for DIE_TS in ${TS_LISTE}
	do
		echo -n " -map 0:a:${DIE_TS} -c:a ${AUDIOCODEC} ${AUDIOQUALITAET} ${_ST}"
	done)"

	AUDIO_VERARBEITUNG_02="-c:a copy"
else
	AUDIO_VERARBEITUNG_01="-an"
	AUDIO_VERARBEITUNG_02="-an"
fi

#==============================================================================#
# Video

#------------------------------------------------------------------------------#
### PAD
# https://ffmpeg.org/ffmpeg-filters.html#pad-1
# pad=640:480:0:40:violet
# pad=width=640:height=480:x=0:y=40:color=violet
#
# SCHWARZ="$(echo "${HOEHE} ${BREITE} ${QUADR_BREIT} ${QUADR_HOCH}" | awk '{sw="oben"; if (($1/$2) < ($3/$4)) sw="oben"; print sw}')"
# SCHWARZ="$(echo "${HOEHE} ${BREITE} ${QUADR_BREIT} ${QUADR_HOCH}" | awk '{sw="oben"; if (($1/$2) > ($3/$4)) sw="links"; print sw}')"
#
if [ "${ORIGINAL_PIXEL}" = Ja ] ; then
	unset PAD
else
	PAD="pad='max(iw\\,ih*(${HOEHE}/${BREITE})):ow/(${HOEHE}/${BREITE}):(ow-iw)/2:(oh-ih)/2',"
fi

#------------------------------------------------------------------------------#
# vor PAD muss eine Auflösung, die der Originalauflösung entspricht, die aber
# für quadratische Pixel ist (QUADR_SCALE);
# hinter PAD muss dann die endgültig gewünschte Auflösung für quadratische
# Pixel (SOLL_SCALE)
#VIDEOOPTION="${VIDEOQUALITAET} -vf ${ZEILENSPRUNG}${CROP}${QUADR_SCALE}${PAD}${SOLL_SCALE}${FORMAT_ANPASSUNG}"
VIDEOOPTION="$(echo "${VIDEOQUALITAET} -vf ${ZEILENSPRUNG}${CROP}${QUADR_SCALE}${PAD}${FORMAT_ANPASSUNG}${SOLL_SCALE}" | sed 's/[,]$//')"

if [ "x${SOLL_FPS}" = x ] ; then
	unset FPS
else
	FPS="-r ${SOLL_FPS}"
fi

START_ZIEL_FORMAT="-f ${FORMAT}"

#==============================================================================#

echo "
TS_LISTE=${TS_LISTE}
TS_ANZAHL=${TS_ANZAHL}

AUDIO_VERARBEITUNG_01=${AUDIO_VERARBEITUNG_01}
AUDIO_VERARBEITUNG_02=${AUDIO_VERARBEITUNG_02}

VIDEOOPTION=${VIDEOOPTION}
START_ZIEL_FORMAT=${START_ZIEL_FORMAT}
" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
#exit 27


#------------------------------------------------------------------------------#
if [ -z "${SCHNITTZEITEN}" ] ; then

	###------------------------------------------------------------------###
	### hier der Film transkodiert                                       ###
	###------------------------------------------------------------------###
	echo
	echo "1: ${PROGRAMM} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${VIDEO_TAG} -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF} ${FPS} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
	echo
#>
	         ${PROGRAMM} ${REPARATUR_PARAMETER} -i  "${FILMDATEI}"  ${VIDEO_TAG} -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF} ${FPS} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG} 2>&1

else

	#----------------------------------------------------------------------#
	ZUFALL="$(head -c 100 /dev/urandom | base64 | tr -d '\n' | tr -cd '[:alnum:]' | cut -b-12)"
	NUMMER="0"
	for _SCHNITT in ${SCHNITTZEITEN}
	do
		NUMMER="$(echo "${NUMMER}" | awk '{printf "%2.0f\n", $1+1}' | tr -s ' ' '0')"
		VON="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $1}')"
		BIS="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $2}')"

		#
		# Leider können hier die einzelnen Filmteile nicht direkt in das
		# Container-Format Matroska überführt werden.
		#
		# FFmpeg füllt 'Video Format profile' für AVI aus aber für Matroska nicht.
		#
		# Deshalb wird direkt in das Ziel-Container-Format (ggf. AVI) transkodiert
		# und zum zusammenbauen wird es zwischenzeitlich in das Container-Format
		# Matroska überführt.
		#

		###----------------------------------------------------------###
		### hier werden die Teile zwischen der Werbung transkodiert  ###
		###----------------------------------------------------------###
		echo
		echo "2: ${PROGRAMM} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${VIDEO_TAG} -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF} -ss ${VON} -to ${BIS} ${FPS} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZUFALL}_${NUMMER}_${ZIELNAME}.${ENDUNG}" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
		echo
#>
		         ${PROGRAMM} ${REPARATUR_PARAMETER} -i  "${FILMDATEI}"  ${VIDEO_TAG} -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF} -ss ${VON} -to ${BIS} ${FPS} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZUFALL}_${NUMMER}_${ZIELNAME}.${ENDUNG} 2>&1

		### das ist nicht nötig, wenn das End-Container-Format bereits MKV ist
		if [ "${ENDUNG}" != "mkv" ] ; then
			ffmpeg -i ${ZIELVERZ}/${ZUFALL}_${NUMMER}_${ZIELNAME}.${ENDUNG} -c:v copy -c:a copy ${U_TITEL_FF} -f matroska -y ${ZIELVERZ}/${ZUFALL}_${NUMMER}_${ZIELNAME}.mkv && rm -f ${ZIELVERZ}/${ZUFALL}_${NUMMER}_${ZIELNAME}.${ENDUNG}
		fi

		echo "---------------------------------------------------------"
	done

	FILM_TEILE="$(ls -1 ${ZIELVERZ}/${ZUFALL}_*_${ZIELNAME}.mkv | tr -s '\n' '|' | sed 's/|/ + /g;s/ + $//')"
	echo "3: mkvmerge -o '${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv' '${FILM_TEILE}'"
#>
	mkvmerge -o ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv ${FILM_TEILE}

	# den vertigen Film aus dem MKV-Format in das MP$-Format umwandeln
	echo "4: ${PROGRAMM} ${REPARATUR_PARAMETER} -i ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv ${VIDEO_TAG} -c:v copy ${AUDIO_VERARBEITUNG_02} ${U_TITEL_FF} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}"
#>
	         ${PROGRAMM} ${REPARATUR_PARAMETER} -i ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv ${VIDEO_TAG} -c:v copy ${AUDIO_VERARBEITUNG_02} ${U_TITEL_FF} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}

	#ls -lh ${ZIELVERZ}/${ZUFALL}_*_${ZIELNAME}.mkv ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv
	#echo "rm -f ${ZIELVERZ}/${ZUFALL}_*_${ZIELNAME}.mkv ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv"
	rm -f ${ZIELVERZ}/${ZUFALL}_*_${ZIELNAME}.mkv ${ZIELVERZ}/${ZUFALL}_${ZIELNAME}.mkv

fi
#------------------------------------------------------------------------------#

echo "
5: ${PROGRAMM} ${REPARATUR_PARAMETER} -i \"${FILMDATEI}\" ${VIDEO_TAG} -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${U_TITEL_FF} ${START_ZIEL_FORMAT} -y ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}
"
#------------------------------------------------------------------------------#

ls -lh ${ZIELVERZ}/${ZIELNAME}.${ENDUNG} ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
LAUFZEIT="$(echo "${STARTZEITPUNKT} $(date +'%s')" | awk '{print $2 - $1}')"
echo "# $(date +'%F %T') (${LAUFZEIT})" | tee -a ${ZIELVERZ}/${ZIELNAME}.${ENDUNG}.txt
#exit 28
