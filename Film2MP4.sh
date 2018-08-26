#!/usr/bin/env bash

#------------------------------------------------------------------------------#
#
# Mit diesem Skript kann man einen Film in einen HTML5-kompatiblen "*.mp4"-Film
# umwandeln, der z.B. vom FireFox ab "Version 35" inline abgespielt werden kann.
#
# Das Ergebnis besteht aus folgenden Formaten:
#  - MP4-Container
#  - AVC-Video-Codec (H.264)
#  - AAC-Audio-Codec
#
# Es werden folgende Programme von diesem Skript verwendet:
#  - ffmpeg
#  - ffprobe
#  - mediainfo
#  - mkvmerge (aus dem Paket mkvtoolnix)
#
#------------------------------------------------------------------------------#

#VERSION="v2017102900"
VERSION="v2018082600"

#set -x
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

BILDQUALIT="5"
TONQUALIT="5"

#
# https://sites.google.com/site/linuxencoding/x264-ffmpeg-mapping
# -keyint <int>
#
# ffmpeg -h full 2>/dev/null | fgrep keyint
# -keyint_min        <int>        E..V.... minimum interval between IDR-frames (from INT_MIN to INT_MAX) (default 25)
IFRAME="-keyint_min 2-8"

LANG=C		# damit AWK richtig rechnet
Film2MP4_OPTIONEN="${@}"
ORIGINAL_PIXEL="Nein"

#==============================================================================#

if [ -z "$1" ] ; then
        ${0} -h
	exit 1
fi

while [ "${#}" -ne "0" ]; do
        case "${1}" in
                -q)
                        FILMDATEI="${2}"	# Name für die Quelldatei
                        shift
                        ;;
                -z)
                        MP4PFAD="${2}"		# Name für die Zieldatei
                        shift
                        ;;
                -c)
                        CROP="${2}"		# -vf crop=width:height:x:y
                        shift
                        ;;
                -dar|-ist_dar)
                        IST_DAR="${2}"		# Display-Format
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
                        TONSPUR=${2}		# "0:3" ist die 4. Tonspur; also, weil 0 die erste ist (0, 1, 2, 3), muss hier "3" stehen
                        TSNAME="${2}"
                        shift
                        ;;
                -schnitt)
                        SCHNITTZEITEN="${2}"	# zum Beispiel zum Werbung entfernen (in Sekunden, Dezimaltrennzeichen ist der Punkt): -schnitt "10-432 520-833 1050-1280"
                        shift
                        ;;
                -crop)
                        CROP="${2}"		# zum Beispiel zum entfernen der schwarzen Balken
                        shift
                        ;;
                -test)
                        ORIGINAL_PIXEL="Ja"		# um die richtigen CROP-Parameter ermitteln
                        shift
                        ;;
                -t)
                        echo '...statt "-t" bitte "-test" verwenden!'
                        exit 1
                        shift
                        ;;
                -u)
                        UNTERTITEL="-map 0:s:${2} -scodec copy"		# "0" für die erste Untertitelspur
                        shift
                        ;;
                -h)
                        echo "HILFE:
        # Video- und Audio-Spur in ein HTML5-kompatibles Format transkodieren

        # grundsaetzlich ist der Aufbau wie folgt,
        # die Reihenfolge der Optionen ist unwichtig
        ${0} [Option] -q [Filmname] -z [Neuer_Filmname.mp4]
        ${0} -q [Filmname] -z [Neuer_Filmname.mp4] [Option]

        # ein Beispiel mit minimaler Anzahl an Parametern
        ${0} -q Film.avi -z Film.mp4

        # ein Beispiel, bei dem auch die erste Untertitelspur (Zählweise beginnt mit "0"!) mit übernommen wird
        ${0} -q Film.avi -u 0 -z Film.mp4

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

        # die gewünschte Bildaufloesung des neuen Filmes
        -soll_xmaly 720x576
        -out_xmaly 720x576

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
        -schnitt \"8.5-432 520-833.5 1050-1280\"

        # will man z.B. von einem 4/3-Film, der als 16/9-Film (720x576)
        # mit schwarzen Balken an den Seiten, diese schwarzen Balken entfernen,
        # dann könnte das zum Beispiel so gemacht werden:
        -crop "540:576:90:0"
                        "
                        exit 1
                        ;;
                *)
                        if [ "$(echo "${1}"|egrep '^-')" ] ; then
                                echo "Der Parameter '${1}' wird nicht unterstützt!"
                        fi
                        shift
                        ;;
        esac
done

#==============================================================================#
### Trivialitäts-Check

#------------------------------------------------------------------------------#

if [ ! -r "${FILMDATEI}" ] ; then
        echo "Der Film '${FILMDATEI}' konnte nicht gefunden werden. Abbruch!"
        exit 1
fi

if [ -z "${TONSPUR}" ] ; then
        TONSPUR=0	# die erste Tonspur ist "0"
fi

#------------------------------------------------------------------------------#
# damit die Zieldatei mit Verzeichnis angegeben werden kann

MP4VERZ="$(dirname ${MP4PFAD})"
MP4DATEI="$(basename ${MP4PFAD})"

#------------------------------------------------------------------------------#
# damit man erkennt welche Tonspur aus dem Original verwendet wurde

if [ -z "${TSNAME}" ] ; then
        MP4DATEI="$(echo "${MP4DATEI} ${TSNAME}" | rev | sed 's/[.]/ /' | rev | awk '{print $1"."$2}')"
else
        MP4DATEI="$(echo "${MP4DATEI} ${TSNAME}" | rev | sed 's/[.]/ /' | rev | awk '{print $1"_-_Tonspur_"$3"."$2}')"
fi

#------------------------------------------------------------------------------#
# damit keine Leerzeichen im Dateinamen enthalten sind

case "${MP4DATEI}" in
        [a-zA-Z0-9\_\-\+/][a-zA-Z0-9\_\-\+/]*[.][Mm][Pp][4])
		MP4NAME="$(echo "${MP4DATEI}" | rev | sed 's/[ ][ ]*/_/g;s/[.]/ /' | rev | awk '{print $1}')"
                ENDUNG="mp4"
                FORMAT="mp4"
                shift
                ;;
        *)
                echo "Die Zieldatei darf nur die Endung '.mp4' tragen!"
                exit 1
                shift
                ;;
esac

#------------------------------------------------------------------------------#
# Test

#echo "
#MP4VERZ='${MP4VERZ}'
#MP4DATEI='${MP4DATEI}'
#MP4NAME='${MP4NAME}'
#"
#exit

#==============================================================================#
### Programm

PROGRAMM="$(which avconv)"
if [ -z "${PROGRAMM}" ] ; then
        PROGRAMM="$(which ffmpeg)"
fi

if [ -z "${PROGRAMM}" ] ; then
        echo "Weder avconv noch ffmpeg konnten gefunden werden. Abbruch!"
        exit 1
fi

#==============================================================================#
### Untertitel

unset U_TITEL_MKV
if [ -n "${UNTERTITEL}" ] ; then
        echo "${UNTERTITEL}" | egrep '0:s:[0-9]' >/dev/null || export U_TITEL=Fehler
        U_TITEL_MKV="-map 0:s:0 -scodec copy"
	if [ "${U_TITEL}" = "Fehler" ] ; then
        	echo "Für die Untertitelspur muss eine Zahl angegeben werden. Abbruch!"
        	echo "z.B.: ${0} -q Film.avi -u 0 -z Film.mp4"
        	exit 1
	fi
fi

#==============================================================================#
### Qualitäts-Parameter-Übersetzung

#==============================================================================#
### Audio
#
### https://trac.ffmpeg.org/wiki/Encode/HighQualityAudio
# sortiert nach Qualität (beste zuerst -> Stand 2017)
#	- libopus	# kann als Vorbis-Nachfolger angesehen werden - 11. September 2012 Version 1.0 veröffentlicht - internationaler Offener Standard in RFC 6716
#	- libvorbis	# als freier MP3-Ersatz entwickelt, Juli 2002 Version 1.0 veröffentlicht
#	- libfdk_aac
#	- aac		# ohne externe Bibliothek, erreicht man mit AAC die beste Qualität
#	- libmp3lame	# seit Herbst 1998 ist das Verteilen oder Verkaufen von MP3-Audio-Codec-Software lizenzrechtlich geschützt
#	- eac3/ac3
#	- libtwolame
#	- vorbis	# Hörtests ergaben transparente Ergebnisse ab 150 bis 170 kbit/s (Vorbis-Qualitätsstufe 5).
#	- mp2
#	- wmav2/wmav1
#
#   Seit 2017 verfügt FFmpeg über einen eigenen, nativen Opus-Encoder und -Decoder.
#   ...ist der vielleicht besser als der native AAC-Encoder und -Decoder?
#   Die Mobil-Plattform Android unterstützt ab Version 5 (Lollipop) Opus eingebettet in das Matroska-Containerformat nativ.

#------------------------------------------------------------------------------#
### Audio-Unterstützung pro Betriebssystem

if [ "FreeBSD" = "$(uname -s)" ] ; then
        AUDIOCODEC="libfdk_aac"  # laut Debian "non-free"-Lizenz / laut FSF,Fedora,RedHat "free"-Lizenz / 2018-05-10 FreeBSD 11 FDK-AAC Version 0.1.5
        #AUDIOCODEC="libfaac"    # "non-free"-Lizenz; funktioniert aber
        #AUDIOCODEC="aac"        # free-Lizenz; seit 05. Dez. 2015 nicht mehr experimentell
elif [ "Linux" = "$(uname -s)" ] ; then
        #AUDIOCODEC="libfaac"    # "non-free"-Lizenz; funktioniert aber (nur mit www.medibuntu.org)
        AUDIOCODEC="aac"         # free-Lizenz; seit 05. Dez. 2015 nicht mehr experimentell
fi

### Tonqualitaet entsprechend dem Audio-Encoder setzen
#
#
### https://trac.ffmpeg.org/wiki/Encode/AAC
# -> libfaac
# erlaubte VBR-Bitraten (FAAC_VBR): -q:a 10-500 (~27k bis ~264k)
# erlaubte ABR-Bitraten (FAAC_ABR): -b:a bis 152k
#
#
###
# -> aac
# erlaubte VBR-Bitraten (FF_AAC_VBR): -q:a 0.1 bis 2	# funktioniert leider noch nicht (August 2018)
#
# -c:a aac				-> Constant LC 128 Kbps (Standard)
#
#
### https://trac.ffmpeg.org/wiki/Encode/AAC
# -> fdk aac
#    1   20-32  kbps/channel    LC,HE,HEv2
#    2   32-40  kbps/channel    LC,HE,HEv2
#    3   48-56  kbps/channel    LC,HE,HEv2
#    4   64-72  kbps/channel    LC
#    5   96-112 kbps/channel    LC
#    FDK library officially supports sample rates for input of 8000, 11025, 12000, 16000, 22050, 24000, 32000, 44100, 48000, 64000, 88200 and 96000 Hz.
# erlaubte VBR-Bitraten (FDK_AAC_VBR): -vbr 1 bis 5	# libfdk_aac -> Note, the VBR setting is unsupported and only works with some parameter combinations.
# erlaubte ABR-Bitraten (FDK_AAC_ABR): -b:a 8 bis 800 kBit/s für jeden Kanal
#
# -c:a libfdk_aac -b:a 128k		-> Constant LC 128 Kbps (Standard)
# -c:a libfdk_aac			-> Constant LC 229 Kbps
# -c:a libfdk_aac -profile:a aac_low	-> Constant LC 140 Kbps
#
#
case "${TONQUALIT}" in
        0)
                FAAC_VBR="-q:a 10"
                FF_AAC_VBR="-q:a 0.1"
                FDK_AAC_VBR="-vbr 1"		# Will man "VBR" verwenden, dann muss man explizit Tonkanäle, Bit-Rate und Saple-Rate in erlaubter Kombination angeben!
                ALLE_AAC_ABR="-b:a 64k"
                ALLE_AAC_ABR_2+x="-b:a 160k"
                ;;
        1)
                FAAC_VBR="-q:a 64"
                FF_AAC_VBR="-q:a 0.3"
                FDK_AAC_VBR="-vbr 2"		# Will man "VBR" verwenden, dann muss man explizit Tonkanäle, Bit-Rate und Saple-Rate in erlaubter Kombination angeben!
                ALLE_AAC_ABR="-b:a 80k"
                ALLE_AAC_ABR_2+x="-b:a 184k"
                ;;
        2)
                FAAC_VBR="-q:a 120"
                FF_AAC_VBR="-q:a 0.5"
                FDK_AAC_VBR="-vbr 3"		# Will man "VBR" verwenden, dann muss man explizit Tonkanäle, Bit-Rate und Saple-Rate in erlaubter Kombination angeben!
                ALLE_AAC_ABR="-b:a 88k"
                ALLE_AAC_ABR_2+x="-b:a 216k"
                ;;
        3)
                FAAC_VBR="-q:a 174"
                FF_AAC_VBR="-q:a 0.7"
                FDK_AAC_VBR="-vbr 4"		# Will man "VBR" verwenden, dann muss man explizit Tonkanäle, Bit-Rate und Saple-Rate in erlaubter Kombination angeben!
                ALLE_AAC_ABR="-b:a 112k"
                ALLE_AAC_ABR_2+x="-b:a 256k"
                ;;
        4)
                FAAC_VBR="-q:a 228"
                FF_AAC_VBR="-q:a 1.0"
                FDK_AAC_VBR="-vbr 5"		# Will man "VBR" verwenden, dann muss man explizit Tonkanäle, Bit-Rate und Saple-Rate in erlaubter Kombination angeben!
                ALLE_AAC_ABR="-b:a 128k"
                ALLE_AAC_ABR_2+x="-b:a 296k"
                ;;
        5)
                FAAC_VBR="-q:a 282"
                FF_AAC_VBR="-q:a 1.2"
                FDK_AAC_VBR="-vbr 5"		# Will man "VBR" verwenden, dann muss man explizit Tonkanäle, Bit-Rate und Saple-Rate in erlaubter Kombination angeben!
                ALLE_AAC_ABR="-b:a 160k"
                ALLE_AAC_ABR_2+x="-b:a 344k"
                ;;
        6)
                FAAC_VBR="-q:a 336"
                FF_AAC_VBR="-q:a 1.4"
                FDK_AAC_VBR="-vbr 5"		# Will man "VBR" verwenden, dann muss man explizit Tonkanäle, Bit-Rate und Saple-Rate in erlaubter Kombination angeben!
                ALLE_AAC_ABR="-b:a 284k"
                ALLE_AAC_ABR_2+x="-b:a 400k"
                ;;
        7)
                FAAC_VBR="-q:a 392"
                FF_AAC_VBR="-q:a 1.6"
                FDK_AAC_VBR="-vbr 5"		# Will man "VBR" verwenden, dann muss man explizit Tonkanäle, Bit-Rate und Saple-Rate in erlaubter Kombination angeben!
                ALLE_AAC_ABR="-b:a 224k"
                ALLE_AAC_ABR_2+x="-b:a 472k"
                ;;
        8)
                FAAC_VBR="-q:a 446"
                FF_AAC_VBR="-q:a 1.8"
                FDK_AAC_VBR="-vbr 5"		# Will man "VBR" verwenden, dann muss man explizit Tonkanäle, Bit-Rate und Saple-Rate in erlaubter Kombination angeben!
                ALLE_AAC_ABR="-b:a 264k"
                ALLE_AAC_ABR_2+x="-b:a 552k"
                ;;
        9)
                FAAC_VBR="-q:a 500"
                FF_AAC_VBR="-q:a 2"
                FDK_AAC_VBR="-vbr 5"		# Will man "VBR" verwenden, dann muss man explizit Tonkanäle, Bit-Rate und Saple-Rate in erlaubter Kombination angeben!
                ALLE_AAC_ABR="-b:a 320k"
                ALLE_AAC_ABR_2+x="-b:a 640k"
                ;;
esac


# max. Anzahl der vorhandenen Audio-Kanäle ermitteln
AUDIO_KANAELE="$(ffprobe -show_data -show_streams "${FILMDATEI}" 2>/dev/null | sed -e '1,/^codec_type=audio/ d' | awk -F'=' '/^channels=/{print $2}' | sort -nr | head -n1)"

# bei mehr als 2 Audio-Kanälen wird von 5.1 ausgegangen
# Diese Änderung hat nur bei ABR (durchschnittlicher Audio-Bit-Rate) Wirkung.
if [ "${AUDIO_KANAELE}" -gt 2 ] ; then
	ALLE_AAC_ABR="${ALLE_AAC_ABR_2+x}"
fi


#AUDIO_SAMPLERATE="-ar 44100"

if [ "${AUDIOCODEC}" = "libfdk_aac" ] ; then
		#
		# http://wiki.hydrogenaud.io/index.php?title=Fraunhofer_FDK_AAC#Recommended_Sampling_Rate_and_Bitrate_Combinations
		#
		# libfdk_aac -> Note, the VBR setting is unsupported and only works with some parameter combinations.
		#
		# FDK AAC kann im Modus "VBR" keine beliebige Kombination von Tonkanäle, Bit-Rate und Saple-Rate verarbeiten!
		# Will man "VBR" verwenden, dann muss man explizit alle drei Parameter in erlaubter Größe angeben.
                #AUDIOOPTION="${FDK_AAC_VBR}"
                AUDIOOPTION="${ALLE_AAC_ABR}"
elif [ "${AUDIOCODEC}" = "libfaac" ] ; then
                AUDIOOPTION="${FAAC_VBR} ${AUDIO_SAMPLERATE}"
                #AUDIOOPTION="${ALLE_AAC_ABR} ${AUDIO_SAMPLERATE}"
elif [ "${AUDIOCODEC}" = "aac" ] ; then
                #AUDIOOPTION="${FF_AAC_VBR} ${AUDIO_SAMPLERATE}"
                AUDIOOPTION="${ALLE_AAC_ABR} ${AUDIO_SAMPLERATE}"
fi

#==============================================================================#
### Video

VIDEOCODEC="libx264"

#------------------------------------------------------------------------------#
# Bildqualität entsprechend dem Video-Encoder setzen

case "${BILDQUALIT}" in
        0)
                AVC_CRF="32"
                ;;
        1)
                AVC_CRF="30"
                ;;
        2)
                AVC_CRF="28"
                ;;
        3)
                AVC_CRF="26"
                ;;
        4)
                AVC_CRF="24"
                ;;
        5)
                AVC_CRF="23"
                ;;
        6)
                AVC_CRF="22"
                ;;
        7)
                AVC_CRF="20"
                ;;
        8)
                AVC_CRF="18"
                ;;
        9)
                AVC_CRF="16"
                ;;
esac

#------------------------------------------------------------------------------#
### IN-Daten (META-Daten) aus der Filmdatei lesen

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

### hier wird ermittelt, ob der film progressiv oder im Zeilensprungverfahren vorliegt
#echo "--------------------------------------------------------------------------------"
#probe "${FILMDATEI}" 2>&1 | fgrep Video:
#echo "--------------------------------------------------------------------------------"
#MEDIAINFO="$(ffprobe "${FILMDATEI}" 2>&1 | fgrep Video: | tr -s '[]' ' ' | tr -s ',' '\n')"
#MEDIAINFO="$(ffprobe "${FILMDATEI}" 2>&1 | fgrep Video: | tr -s '[\[,\]]' '\n' | egrep -B1 'SAR |DAR ' | tr -s '\n' ' ')"
#MEDIAINFO="$(ffprobe "${FILMDATEI}" 2>&1 | fgrep Video: | sed 's/.* Video:/Video:/' | tr -s '[\[,\]]' '\n' | egrep '[0-9]x[0-9]|SAR |DAR ' | fgrep -v 'Stream #' | tr -s '\n' ' ')"
MEDIAINFO="$(ffprobe "${FILMDATEI}" 2>&1 | fgrep Video: | sed 's/.* Video:/Video:/' | tr -s '[\[,\]]' '\n' | egrep '[0-9]x[0-9]|SAR |DAR ' | grep -Fv 'Stream #' | grep -Fv 'Video:' | tr -s '\n' ' ')"
# tbn (FPS vom Container)= the time base in AVStream that has come from the container
# tbc (FPS vom Codec) = the time base in AVCodecContext for the codec used for a particular stream
# tbr (FPS vom Video-Stream geraten) = tbr is guessed from the video stream and is the value users want to see when they look for the video frame rate

### hier wird ermittelt, ob der film progressiv oder im Zeilensprungverfahren vorliegt
#
# leider kann das z.Z. nur mit "mediainfo" einfach und zuverlässig ermittelt werden
# mit "ffprobe" ist es etwas komplizierter...
#
SCAN_TYPE="$(mediainfo --BOM -f "${FILMDATEI}" 2>/dev/null | grep -Fv pixels | awk -F':' '/Scan type[ ]+/{print $2}' | tr -s ' ' '\n' | egrep -v '^$' | head -n1)"
if [ "${SCAN_TYPE}" != "Progressive" ] ; then
        ### wenn der Film im Zeilensprungverfahren vorliegt
        ZEILENSPRUNG="yadif,"
fi

# MEDIAINFO=' 720x576 SAR 64:45 DAR 16:9 '
IN_XY="$(echo "${MEDIAINFO}" | fgrep ' DAR ' | awk '{print $1}')"
IN_PAR="$(echo "${MEDIAINFO}" | fgrep ' DAR ' | awk '{print $3}')"
IN_DAR="$(echo "${MEDIAINFO}" | fgrep ' DAR ' | awk '{print $5}')"

#echo "
#MEDIAINFO='${MEDIAINFO}'
##----
#IN_XY='${IN_XY}'
#IN_PAR='${IN_PAR}'
#IN_DAR='${IN_DAR}'
#ZEILENSPRUNG='${ZEILENSPRUNG}'
#"
#exit


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
###                     IN_XY  = 720 x 576 (Rasterformat der Bildgröße)
###                     IN_PAR =  15 / 16  (PAR / SAR)
###                     IN_DAR =   4 / 3   (DAR)
###
#------------------------------------------------------------------------------#
### Hier wird versucht dort zu interpolieren, wo es erforderlich ist.
### Es kann jedoch von den vier Werten (Breite+Höhe+DAR+PAR) nur einer
### mit Hilfe der drei vorhandenen Werte interpoliert werden.

#------------------------------------------------------------------------------#
### Rasterformat der Bildgröße

#echo "
#IST_XY='${IST_XY}'
#IN_XY='${IN_XY}'
#"

if [ -n "${IST_XY}" ] ; then
	IN_XY="${IST_XY}"
fi

#echo "
#IST_XY='${IST_XY}'
#IN_XY='${IN_XY}'
#"
#exit


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
	exit 1
fi

IN_BREIT="$(echo "${IN_XY}" | awk -F'x' '{print $1}')"
IN_HOCH="$(echo "${IN_XY}" | awk -F'x' '{print $2}')"


#------------------------------------------------------------------------------#
### gewünschtes Rasterformat der Bildgröße (Auflösung)

if [ "${ORIGINAL_PIXEL}" = Ja ] ; then
	unset SOLL_SCALE
else
	if [ -n "${SOLL_XY}" ] ; then
		SOLL_SCALE="scale=${SOLL_XY},"
	fi
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
	exit 1
fi


#----------------------------------------------------------------------#
### Seitenverhältnis der Bildes - Arbeitswerte berechnen (DAR)

DAR="$(echo "${IN_DAR}" | egrep '[:/]')"
if [ -n "${DAR}" ] ; then
	DAR_KOMMA="$(echo "${DAR}" | egrep '[:/]' | awk -F'[:/]' '{print $1/$2}')"
	DAR_FAKTOR="$(echo "${DAR}" | egrep '[:/]' | awk -F'[:/]' '{printf "%u\n", ($1*100000)/$2}')"
else
	DAR="$(echo "${IN_DAR}" | fgrep '.')"
	DAR_KOMMA="${DAR}"
	DAR_FAKTOR="$(echo "${DAR}" | fgrep '.' | awk '{printf "%u\n", $1*100000}')"
fi


#----------------------------------------------------------------------#
### Kontrolle Seitenverhältnis der Bildpunkte (PAR / SAR)

if [ -z "${IN_PAR}" ] ; then
	IN_PAR="$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{printf "%.16f\n", ($2*$3)/$1}')"
fi


ARBEITSWERTE_PAR


#echo "
#IN_XY='${IN_XY}'
#SOLL_XY='${SOLL_XY}'
#IN_BREIT='${IN_BREIT}'
#IN_HOCH='${IN_HOCH}'
#IST_XY='${IST_XY}'
#IST_DAR='${IST_DAR}'
#IST_PAR='${IST_PAR}'
#IN_DAR='${IN_DAR}'
#DAR='${DAR}'
#DAR_KOMMA='${DAR_KOMMA}'
#DAR_FAKTOR='${DAR_FAKTOR}'
#PAR='${PAR}'
#PAR_KOMMA='${PAR_KOMMA}'
#PAR_FAKTOR='${PAR_FAKTOR}'
#"
#exit


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


#
# echo "breit hoch DAR" | awk '{a=$1*$2; b=sqrt(a/$3); h=a/b; printf "%.0f %.0f %.0f %.0f\n", b/2, h/2}' | awk '{print $1*2, $2*2}'
# echo "720 576 1.3333" | awk '{a=$1*$2; b=sqrt(a/$3); h=a/b; printf "%.0f %.0f %.0f %.0f\n", $1, $2, b/2, h/2}' | awk '{b=$3*2; h=$4*2; print b"x"h, b/h, b*h, $1*$2}'
# echo "720 576 1.7778" | awk '{a=$1*$2; b=sqrt(a/$3); h=a/b; printf "%.0f %.0f %.0f %.0f\n", $1, $2, b/2, h/2}' | awk '{b=$3*2; h=$4*2; print b"x"h, b/h, b*h, $1*$2}'
# QUADR_AUFLOESUNG="$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{a=$1*$2; h=sqrt(a/$3); b=a/h; printf "%.0f %.0f\n", b/2, h/2}' | awk '{print $1*2"x"$2*2}')"
#

#echo "
#IST_XY='${IST_XY}'
#SOLL_XY='${SOLL_XY}'
#IST_DAR='${IST_DAR}'
#DAR_FAKTOR='${DAR_FAKTOR}'
#DAR_KOMMA='${DAR_KOMMA}'
#PAR_KOMMA='${PAR_KOMMA}'
#IN_BREIT='${IN_BREIT}'
#IN_HOCH='${IN_HOCH}'
#"
#exit


if [ -z "${DAR_FAKTOR}" ] ; then
	echo "Es konnte das Display-Format nicht ermittelt werden."
	echo "versuchen Sie es mit diesem Parameter nocheinmal:"
	echo "-dar"
	echo "z.B.: -dar 16:9"
	echo "ABBRUCH!"
	exit 1
fi


if [ "${PAR_FAKTOR}" -ne "100000" ] ; then

	### Umrechnung in quadratische Pixel - Version 1
	#QUADR_SCALE="scale=$(echo "${DAR_KOMMA} ${IN_BREIT} ${IN_HOCH}" | awk '{b=sqrt($1*$2*$3); printf "%.0f %.0f\n", b/2, b/$1/2}' | awk '{print $1*2"x"$2*2}'),"
	#QUADR_SCALE="scale=$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{b=sqrt($1*$2*$3); printf "%.0f %.0f\n", b/2, b/$3/2}' | awk '{print $1*2"x"$2*2}'),"

	### Umrechnung in quadratische Pixel - Version 2
	#HALBE_HOEHE="$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA}" | awk '{h=sqrt($1*$2/$3); printf "%.0f\n", h/2}')"
	#QUADR_SCALE="scale=$(echo "${HALBE_HOEHE} ${DAR_KOMMA}" | awk '{printf "%.0f %.0f\n", $1*$2, $1}' | awk '{print $1*2"x"$2*2}'),"
	#
	### [swscaler @ 0x81520d000] Warning: data is not aligned! This can lead to a speed loss
	### laut Googel müssen die Pixel durch 16 teilbar sein, beseitigt aber leider das Problem hier nicht
	#TEILER="2"
	#TEILER="8"
	TEILER="16"
	#TEILER="32"
	TEIL_HOEHE="$(echo "${IN_BREIT} ${IN_HOCH} ${DAR_KOMMA} ${TEILER}" | awk '{h=sqrt($1*$2/$3); printf "%.0f\n", h/$4}')"
	QUADR_SCALE="scale=$(echo "${TEIL_HOEHE} ${DAR_KOMMA}" | awk '{printf "%.0f %.0f\n", $1*$2, $1}' | awk -v teiler="${TEILER}" '{print $1*teiler"x"$2*teiler}'),"

	QUADR_BREITE="$(echo "${QUADR_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $1}')"
	QUADR_HOCH="$(echo "${QUADR_SCALE}" | sed 's/x/ /;s/^[^0-9][^0-9]*//;s/[^0-9][^0-9]*$//' | awk '{print $2}')"
fi


#echo "
#DAR_KOMMA='${DAR_KOMMA}'
#PAR_KOMMA='${PAR_KOMMA}'
#IN_BREIT='${IN_BREIT}'
#IN_HOCH='${IN_HOCH}'
#QUADR_SCALE='${QUADR_SCALE}'
#QUADR_BREITE='${QUADR_BREITE}'
#QUADR_HOCH='${QUADR_HOCH}'
#SOLL_SCALE='${SOLL_SCALE}'
#-------------------------------
#"
#exit


### universelle Variante
# iPad : VIDEOOPTION="-crf ${AVC_CRF} -vf ${ZEILENSPRUNG}pad='max(iw\\,ih*(16/9)):ow/(16/9):(ow-iw)/2:(oh-ih)/2',scale='1024:576',setsar='1/1'"
# iPad : VIDEOOPTION="-crf ${AVC_CRF} -vf ${ZEILENSPRUNG}scale='1024:576',setsar='1/1'"
# HTML5: VIDEOOPTION="-crf ${AVC_CRF} -vf ${ZEILENSPRUNG}setsar='1/1'"
#
if [ "${DAR_FAKTOR}" -lt "149333" ] ; then
	HOEHE="4"
	BREITE="3"
else
	HOEHE="16"
	BREITE="9"
fi


### PAD
# https://ffmpeg.org/ffmpeg-filters.html#pad-1
# pad=640:480:0:40:violet
# pad=width=640:height=480:x=0:y=40:color=violet
#
# SCHWARZ="$(echo "${HOEHE} ${BREITE} ${QUADR_BREITE} ${QUADR_HOCH}" | awk '{sw="oben"; if (($1/$2) < ($3/$4)) sw="oben"; print sw}')"
# SCHWARZ="$(echo "${HOEHE} ${BREITE} ${QUADR_BREITE} ${QUADR_HOCH}" | awk '{sw="oben"; if (($1/$2) > ($3/$4)) sw="links"; print sw}')"
#
if [ "${ORIGINAL_PIXEL}" = Ja ] ; then
	unset PAD
else
	PAD="pad='max(iw\\,ih*(${HOEHE}/${BREITE})):ow/(${HOEHE}/${BREITE}):(ow-iw)/2:(oh-ih)/2',"
fi

VIDEOOPTION="-crf ${AVC_CRF} -vf ${ZEILENSPRUNG}${CROP}${QUADR_SCALE}${PAD}${SOLL_SCALE}setsar='1/1'"

START_MP4_FORMAT="-f ${FORMAT}"


echo "
${VIDEOOPTION}
"


#echo "
#SOLL_XY='${SOLL_XY}'
#DAR_KOMMA='${DAR_KOMMA}'
#DAR_FAKTOR='${DAR_FAKTOR}'
#PAR_KOMMA='${PAR_KOMMA}'
#PAR_FAKTOR='${PAR_FAKTOR}'
#SCHWARZ='${SCHWARZ}'
#IN_BREIT='${IN_BREIT}'
#IN_HOCH='${IN_HOCH}'
#QUADR_SCALE='${QUADR_SCALE}'
#HOEHE='${HOEHE}'
#BREITE='${BREITE}'
#${PROGRAMM}
#-i \"${FILMDATEI}\"
#-map 0:v
#-c:v ${VIDEOCODEC}
#${VIDEOOPTION}
#${IFRAME}
#-map 0:a:${TONSPUR}
#-c:a ${AUDIOCODEC}
#${AUDIOOPTION}
#${START_MP4_FORMAT}
#-y ${MP4VERZ}/${MP4NAME}.${ENDUNG}
#"
#exit


#==============================================================================#

STREAM_AUDIO="$(ffprobe "${FILMDATEI}" 2>&1 | fgrep ' Stream ' | fgrep Audio:)"
STREAMAUDIO="$(echo "${STREAM_AUDIO}" | wc -w | awk '{print $1}')"

if [ "${STREAMAUDIO}" -gt 0 ] ; then
	AUDIO_VERARBEITUNG_01="-map 0:a:${TONSPUR} -c:a ${AUDIOCODEC} ${AUDIOOPTION}"
	AUDIO_VERARBEITUNG_02="-c:a copy"
else
	AUDIO_VERARBEITUNG_01="-an"
	AUDIO_VERARBEITUNG_02="-an"
fi

#echo "
#STREAM_AUDIO='${STREAM_AUDIO}'
#STREAMAUDIO='${STREAMAUDIO}'
#AUDIO_VERARBEITUNG_01='${AUDIO_VERARBEITUNG_01}'
#AUDIO_VERARBEITUNG_02='${AUDIO_VERARBEITUNG_02}'
#"
#exit

#==============================================================================#

#rm -f ${MP4VERZ}/${MP4NAME}.txt
echo "${0} ${Film2MP4_OPTIONEN}" > ${MP4VERZ}/${MP4NAME}.txt


if [ -z "${SCHNITTZEITEN}" ] ; then
	echo
	echo "${PROGRAMM} -i \"${FILMDATEI}\" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${START_MP4_FORMAT} -y ${MP4VERZ}/${MP4NAME}.${ENDUNG}" | tee -a ${MP4VERZ}/${MP4NAME}.txt
	echo
	${PROGRAMM} -i "${FILMDATEI}" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${UNTERTITEL} ${START_MP4_FORMAT} -y ${MP4VERZ}/${MP4NAME}.${ENDUNG} 2>&1
else
	#echo "SCHNITTZEITEN=${SCHNITTZEITEN}"
	#exit

	ZUFALL="$(head -c 100 /dev/urandom | base64 | tr -d '\n' | tr -cd '[:alnum:]' | cut -b-12)"
	NUMMER="0"
	for _SCHNITT in ${SCHNITTZEITEN}
	do
		NUMMER="$(echo "${NUMMER}" | awk '{printf "%2.0f\n", $1+1}' | tr -s ' ' '0')"
		VON="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $1}')"
		DAUER="$(echo "${_SCHNITT}" | tr -d '"' | awk -F'-' '{print $2 - $1}')"

		echo
		echo "${PROGRAMM} -i \"${FILMDATEI}\" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} -ss ${VON} -t ${DAUER} -f matroska -y ${MP4VERZ}/${ZUFALL}_${NUMMER}_${MP4NAME}.mkv" | tee -a ${MP4VERZ}/${MP4NAME}.txt
		echo
		${PROGRAMM} -i "${FILMDATEI}" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} ${AUDIO_VERARBEITUNG_01} ${UNTERTITEL} -ss ${VON} -t ${DAUER} -f matroska -y ${MP4VERZ}/${ZUFALL}_${NUMMER}_${MP4NAME}.mkv 2>&1
		echo "---------------------------------------------------------"
	done

	FILM_TEILE="$(ls -1 ${MP4VERZ}/${ZUFALL}_*_${MP4NAME}.mkv | tr -s '\n' '|' | sed 's/|/ + /g;s/ + $//')"
	echo "# mkvmerge -o '${MP4VERZ}/${ZUFALL}_${MP4NAME}.mkv' '${FILM_TEILE}'"
	mkvmerge -o ${MP4VERZ}/${ZUFALL}_${MP4NAME}.mkv ${FILM_TEILE}

	# den vertigen Film aus dem MKV-Format in das MP$-Format umwandeln
	echo "${PROGRAMM} -i ${MP4VERZ}/${ZUFALL}_${MP4NAME}.mkv -c:v copy ${AUDIO_VERARBEITUNG_02} ${START_MP4_FORMAT} -y ${MP4VERZ}/${MP4NAME}.${ENDUNG}"
	${PROGRAMM} -i ${MP4VERZ}/${ZUFALL}_${MP4NAME}.mkv -c:v copy ${AUDIO_VERARBEITUNG_02} ${U_TITEL_MKV} ${START_MP4_FORMAT} -y ${MP4VERZ}/${MP4NAME}.${ENDUNG}

	#ls -lh ${MP4VERZ}/${ZUFALL}_*_${MP4NAME}.mkv ${MP4VERZ}/${ZUFALL}_${MP4NAME}.mkv
	#echo "rm -f ${MP4VERZ}/${ZUFALL}_*_${MP4NAME}.mkv ${MP4VERZ}/${ZUFALL}_${MP4NAME}.mkv"
	rm -f ${MP4VERZ}/${ZUFALL}_*_${MP4NAME}.mkv ${MP4VERZ}/${ZUFALL}_${MP4NAME}.mkv
fi

#echo "
#${PROGRAMM} -i \"${FILMDATEI}\" -map 0:v -c:v ${VIDEOCODEC} ${VIDEOOPTION} ${IFRAME} -map 0:a:${TONSPUR} -c:a ${AUDIOCODEC} ${AUDIOOPTION} ${UNTERTITEL} ${START_MP4_FORMAT} -y ${MP4VERZ}/${MP4NAME}.${ENDUNG}
#"
#------------------------------------------------------------------------------#

ls -lh ${MP4VERZ}/${MP4NAME}.${ENDUNG} ${MP4VERZ}/${MP4NAME}.txt
exit
