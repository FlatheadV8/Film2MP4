# Film2MP4
Filme in ein HTML5-kompatibles MP4-Format umrechnen, die Video-Daten werden hier BluRay-kompatibel erzeugt.

Video- und Audio-Spur in ein HTML5-kompatibles Format transkodieren

hier ein paar Beispiele:

    Film2MP4.sh -q "Der_brave_Soldat_Schwejk.avi" -z Der_brave_Soldat_Schwejk.mp4

    Film2MP4.sh -q "Der_brave_Soldat_Schwejk.avi" -z Der_brave_Soldat_Schwejk.mp4 -ton 0

    Film2MP4.sh -q "Der_brave_Soldat_Schwejk.avi" -z Der_brave_Soldat_Schwejk.mp4 -ton 0 -aq 6

    Film2MP4.sh -q "Der_brave_Soldat_Schwejk.avi" -z Der_brave_Soldat_Schwejk.mp4 -ton 0 -aq 6 -vq 6

    Film2MP4.sh -q "Der_brave_Soldat_Schwejk.avi" -z Der_brave_Soldat_Schwejk.mp4 -ton 0 -aq 6 -vq 6 -schnitt "450-500"

    Film2MP4.sh -q "Der_brave_Soldat_Schwejk.avi" -z Der_brave_Soldat_Schwejk.mp4 -ton 0 -aq 6 -vq 6 -schnitt "450-500" -crop "540:576:90:0"

    Film2MP4.sh -q "Der_brave_Soldat_Schwejk.avi" -z Der_brave_Soldat_Schwejk.mp4 -ton 0 -aq 6 -vq 6 -schnitt "450-500" -crop "540:576:90:0" -out_xmaly 640x540

    Film2MP4.sh -q "Der_brave_Soldat_Schwejk.avi" -z Der_brave_Soldat_Schwejk.mp4 -ton 0 -aq 6 -vq 6 -schnitt "450-500" -crop "540:576:90:0" -out_xmaly 640x540 -in_xmaly 720x576


grundsaetzlich ist der Aufbau wie folgt,
die Reihenfolge der Optionen ist unwichtig

    /home/bin/Film2MP4.sh [Option] -q [Filmname] -z [Neuer_Filmname.mp4]
    /home/bin/Film2MP4.sh -q [Filmname] -z [Neuer_Filmname.mp4] [Option]

ein Beispiel mit minimaler Anzahl an Parametern

    /home/bin/Film2MP4.sh -q Film.avi -z Film.mp4

Es duerfen in den Dateinamen keine Leerzeichen, Sonderzeichen
oder Klammern enthalten sein!
Leerzeichen kann aber innerhalb von Klammer trotzdem verwenden

    /home/bin/Film2MP4.sh -q "Filmname mit Leerzeichen.avi" -z Film.mp4

wenn der Film mehrer Tonspuren besitzt
und nicht die erste verwendet werden soll,
dann wird so die 2. Tonspur angegeben (die Zaehlweise beginnt mit 0)

    -ton 1

wenn der Film mehrer Tonspuren besitzt
und nicht die erste verwendet werden soll,
dann wird so die 3. Tonspur angegeben (die Zaehlweise beginnt mit 0)

    -ton 2

die gewünschte Bildaufloesung des neuen Filmes

    -out_xmaly 720x576

wenn die Bildaufloesung des Originalfilmes nicht automatisch ermittelt
werden kann, dann muss sie manuell als Parameter uebergeben werden

    -in_xmaly 480x270

wenn das Bildformat des Originalfilmes nicht automatisch ermittelt
werden kann, dann muss es manuell als Parameter uebergeben werden

    -dar 16:9

wenn die Pixelgeometrie des Originalfilmes nicht automatisch ermittelt
werden kann, dann muss sie manuell als Parameter uebergeben werden

    -par 64:45

will man eine andere Video-Qualitaet, dann sie manuell als Parameter
uebergeben werden

    -vq 5

will man eine andere Audio-Qualitaet, dann sie manuell als Parameter
uebergeben werden

    -aq 3

Man kann aus dem Film einige Teile entfernen, zum Beispiel Werbung.
Angaben muessen in Sekunden erfolgen,
Dezimaltrennzeichen ist der Punkt.
Die Zeit-Angaben beschreiben die Laufzeit des Filmes,
so wie der CLI-Video-Player 'MPlayer' sie
in der untersten Zeile anzeigt.
Hier werden zwei Teile (432-520 und 833.5-1050) aus dem vorliegenden
Film entfernt bzw. drei Teile (8.5-432 und 520-833.5 und 1050-1280)
aus dem vorliegenden Film zu einem neuen Film zusammengesetzt.

    -schnitt "8.5-432 520-833.5 1050-1280"

will man z.B. von einem 4/3-Film, der als 16/9-Film (720x576)
mit schwarzen Balken an den Seiten, diese schwarzen Balken entfernen,
dann könnte das zum Beispiel so gemacht werden:

    -crop 540:576:90:0
