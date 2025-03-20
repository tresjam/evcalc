		 #cs ----------------------------------------------------------------------------

		 AutoIt Version: 3.3.10.2
		 Author:         a.kappmeier

		 Script Function:

		 berechnen der Reise Dauer eines Elektro-KFZ inkl. Ladevorgaenge.

		 Berechnungsfaktoren:
			- Anfahrt zum Ladepunkt : 5 Min.
			- Laden von 10 % bis 90 %
			- max. Leistung beim Schnelladen






			Ideen / Verbesserungen :
			- - - - - - - - - - - - - - - - - -
			   - Update moeglichkeit
			   - KFZ Vorschlagen und per FTP hochladen
			   - Vorgabe des optimalen Ladebereiches je Fahrzeit
			   - unteren und oberen Ladestand in Prozent selber festlegen und in die Berechnung nehmen



			to Do / Fehler :
			- - - - - - - - - - -
			   - beim Bearbeiten die geänderten Werte in die Scala übernehmen
			   - beim Bearbeiten als Scala anzeigen und die Punkte per Klick verschieben
			   - 'bearbeiten' button verlagern, ev. in 'Optionen' ueberführen
			   - neu anlegen über "kopieren" eines vorhandenen KFZ



			in Arbeit :
			- - - - - - -
			   - Ladebereich festlegen 10-80 % mit einfluss in die Berechnung
                - 1.6 beta : font aendern, für bessere Darstellung unter Linux//wine, über $Debug-Flag



			erledigt :
			- - - - - - -
			   - $count wurde doppelt verwendet, in der Grafikroutine und als absoluter EV Zähler. Getrennt in $Scalacount und $EVcount
			   -  übernehmen Button in "Bearbeiten" ohne Funktion, d.h. die Werte werden nicht gespeichert
                - Nutzkapazitaet = 80% des Brutto >> 10 bis 90 %
                - intern umstellen der Fahrzeugdaten
                - ev.dat neu angeordnet in [CONFIG] und [DATA]
                - Anfahrt zum Ladepunkt mit pauschal 5 Min. berechnen (INI : WAY2CHARGE=5,Variable : $AnfahrtLadepunkt)
                - Data unabhaengig von COUNT einlesen, =alles bis nichts mehr da ist
                - Anfahrt Ladepunkt wird als "WAY2CHARGE" in der INI unter "CONFIG" gesichert
                - Tesla Verbraeuche nach Video von H. Luening angepasst
                - Anpassung der Darstellung für 125% Anzeige ab Win 8
                - Ueberarbeiten der feld-neu-berechnung, alle felder in einem lesen und buffern
                - Liste selber bearbeiten ueber Programmfunktion
                - $Debug Flag eingeführt, z.Zt. nur Fontwchsel
				- neues EV anlegen, bearbeiten
				- ToDo : beim uebernehmen der Werte die Scala neu zeichnen
				- eingaben der SOC Werte prüfen (zu groß zu klein) via $SOCfalseFlag

		 #ce ----------------------------------------------------------------------------


		 #include <ButtonConstants.au3>
		 #include <EditConstants.au3>
		 #include <GUIConstants.au3>
		 #include <GUIConstantsEx.au3>
		 #include <ProgressConstants.au3>

		 #include <StaticConstants.au3>
		 #include <WindowsConstants.au3>
		 #include <file.au3>
		 #include <ListViewConstants.au3>
		 #include <FontConstants.au3>

		 #include <Date.au3>
		 #include <GDIPlus.au3>
		 #include <ScreenCapture.au3>
		 #include <MsgBoxConstants.au3>

		 #include <Misc.au3>

		 ; doppelten Start verhindern
		 ; If UBound(ProcessList(@ScriptName)) > 2 Then Exit

		 Global $GUI1id, $GUI1button1, $GUI1button2, $GUI1button3, $GUI1button4, $GUI1button5, $GUI1ButtonExit, $GUI1ButtonEditmodel, $GUI1FontList
		 Global $GUI1EVmodel, $GUI1Ladeleistung, $GUI1ChangeFontButton, $GUI2ButtonSelect

		 Global $GUI2id, $GUI2flag, $GUI2ButtonNew, $GUI2ButtonSave, $GUI2ButtonOK, $GUI2ButtonCancel, $GUI2ChangeFlag=0

		 Global $GUI1Version, $GUI1ladedauer, $GUI1kapazitaet, $GUI1Strecke,  $GUI1LadedauerLabel, $GUI1kapazitaetLabel;$GUI1unten,  $GUI1SOCoben

		 Global $GUI1LabelVerbrauch80, $GUI1LabelReichweite80, $GUI1LabelLadenAnzahl80, $GUI1LabelFahrzeit80, $GUI1LabelLadezeit80, $GUI1LabelReisezeit80
		 Global $GUI1LabelVerbrauch90, $GUI1LabelReichweite90, $GUI1LabelLadenAnzahl90, $GUI1LabelFahrzeit90, $GUI1LabelLadezeit90, $GUI1LabelReisezeit90
		 Global $GUI1LabelVerbrauch100, $GUI1LabelReichweite100, $GUI1LabelLadenAnzahl100, $GUI1LabelFahrzeit100, $GUI1LabelLadezeit100, $GUI1LabelReisezeit100
		 Global $GUI1LabelVerbrauch110, $GUI1LabelReichweite110, $GUI1LabelLadenAnzahl110, $GUI1LabelFahrzeit110, $GUI1LabelLadezeit110, $GUI1LabelReisezeit110
		 Global $GUI1LabelVerbrauch120, $GUI1LabelReichweite120, $GUI1LabelLadenAnzahl120, $GUI1LabelFahrzeit120, $GUI1LabelLadezeit120, $GUI1LabelReisezeit120
		 Global $GUI1LabelVerbrauch130, $GUI1LabelReichweite130, $GUI1LabelLadenAnzahl130, $GUI1LabelFahrzeit130, $GUI1LabelLadezeit130, $GUI1LabelReisezeit130
		 Global $GUI1LabelVerbrauch140, $GUI1LabelReichweite140, $GUI1LabelLadenAnzahl140, $GUI1LabelFahrzeit140, $GUI1LabelLadezeit140, $GUI1LabelReisezeit140
		 Global $GUI1LabelVerbrauch150, $GUI1LabelReichweite150, $GUI1LabelLadenAnzahl150, $GUI1LabelFahrzeit150, $GUI1LabelLadezeit150, $GUI1LabelReisezeit150

		 Global $Buffer, $BufferRC, $BufferEV, $Bufferladedauer, $BufferladeLeistung, $ProgramTitle, $EVmodels, $Verbrauch, $Kapazitaet, $Ladeleistung
		 Global $EVcount, $AnfahrtLadepunkt, $Ladedauer, $Strecke, $KapazitaetNetto, $SOCunten, $SOCoben
		 Global $Verbrauch80, $Verbrauch90, $Verbrauch100, $Verbrauch110, $Verbrauch120, $Verbrauch130, $Verbrauch140, $Verbrauch150
		 Global $Reichweite80, $Reichweite90, $Reichweite100, $Reichweite110, $Reichweite120,$Reichweite130, $Reichweite140,$Reichweite150
		 Global $LadenAnzahl80, $LadenAnzahl90, $LadenAnzahl100, $LadenAnzahl110, $LadenAnzahl120, $LadenAnzahl130, $LadenAnzahl140, $LadenAnzahl150
		 Global $Min80, $Min90, $Min100, $Min110, $Min120, $Min130, $Min140, $Min150
		 Global $Ladezeit80, $Ladezeit90, $Ladezeit100, $Ladezeit110, $Ladezeit120, $Ladezeit130, $Ladezeit140, $Ladezeit150
		 Global $Reisezeit80, $Reisezeit90, $Reisezeit100, $Reisezeit110, $Reisezeit120, $Reisezeit130, $Reisezeit140, $Reisezeit150


		 Global $iHours, $iMins, $iSecs, $TC_converted, $TC_source,$LASTmodel, $LASTkm, $fontsize, $version, $DataEndFlag=0, $VersionsHistorie
		 Global $FontTemp, $FontCurrent, $FontChangeFlag=0, $GUIInfoFlag=0, $Debug=0, $InputBufferTemp, $InputBuffer, $hPen, $hGraphic, $ScalaFile

		 DIM $EVdata[1000][30], $GUI2Input[30], $FontArray[100], $GUI2ScalaButton[20],  $GrafikTempEVdata[30]

		 $ScalaFile=@TempDir & "\scala500.bmp"
		 ;FileInstall(@ScriptDir & "\scala500.bmp", @TempDir & "\scala500.bmp", 1)
		 FileInstall("scala500.bmp", "scala500.bmp", 1)


		 ; Debug über INI Eintrag aktivieren
		 $version="0.1.7"
		 $ProgramTitle="EVcalc"
		 $GUI1x=800
		 $GUI1y=500
		 $fontsize=10
		 $fontname=""
		 $FontCount=5000

		 $AnfahrtLadepunkt=5																								; Anfahrt zum Ladepnunkt in Minuten

		 $DBFile=@Scriptdir & "\EV.dat"																				; festlgen des Datenbanknamens

		 If not FileExists($DBFile) Then																				; Wenn Datenbankdatei nicht vorhanden
			EVdataCreate()																										; eine neue anlegen
		 EndIf																															;

        EVdataRead()																											; Datenbank einlesen

        $EVmodels=$EVdata[1][1] & " " & $EVdata[1][2]													; werte aus der Datenbank auf die Variablen
        For $t=2 to $EVcount																										; verteilen zur Darstellung im Fenster
                $EVmodels=$EVmodels & "|" & $EVdata[$t][1] & " " & $EVdata[$t][2]			;
        Next																			;

        FontEval()

        GUI()																															; Fenster bauen lassen


        #Region main routine
        While 1
				  $msg=GUIGetMsg()
				  Select
				  Case $GUIInfoFlag=0 and ($msg=$GUI_EVENT_CLOSE or $msg=$GUI1ButtonExit)			; Programm beenden
                        SaveEVdata()
                        Exit
				  Case $GUIInfoFlag=1 and ($msg=$GUI_EVENT_CLOSE or $msg=$GUI1ButtonExit)			; Programm beenden
                        $GUIInfoFlag=0
                        GUIDelete($GUIinfo)
				  Case $msg=$GUI1Version																												; Infofenster anzeigen
                        ;$VersionsHistorie = "Übersicht der Versionen" & @CRLF & @CRLF
                        $VersionsHistorie = 									"0.1.7 alpha" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- Anzeige der Werte als Grafik im Bearbeiten-Fenster" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- Ladebereich in % festlegen je Fahrzeug" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- " & @CRLF
                        ;$VersionsHistorie = $VersionsHistorie &	"- Font ändern über DEBUG - Flag in der EV.DAT" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"" & @CRLF
                        $VersionsHistorie = $VersionsHistorie & "0.1.6" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- Verbräuche angepasst nach weiterem Video von HL" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- Aufgenommen: Tesla Model 3 & Jaguar I-PACE & Kiao Soul EV" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- Ändern der Schriftart über DEBUG=1 in der EV.DAT" & @CRLF
                        ;$VersionsHistorie = $VersionsHistorie &	"- Font ändern über DEBUG - Flag in der EV.DAT" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"0.1.5" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- Fahrzeugangaben bearbeiten/neue Fahrzeuge anlegen" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"0.1.4" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- Überarbeiten der Werteberechnung" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- Fehler Ladezeitberechnung beseitigt" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"0.1.3" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- Tesla-Verbräuche angepasst nach Video von HL" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"0.1.2" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- Zeiten formatiert anzeigen" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- Nissan Leaf und Renault Zoe hinzugefügt" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- Anfahrt fließt mit 5 min. in die Berechnung ein" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"0.1.1" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- Eingaben werden in der ev.dat gespeichert." & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- Einige Fahrzeuge mit vorläufigen Werten aufgenommen" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- 80% Kapazität für Reise-Abschnitt verwenden" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"0.1.0" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"- erster Entwurf" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"" & @CRLF
                        $VersionsHistorie = $VersionsHistorie &	"(P)(C)2019 tresjam" & @CRLF
                        ;msgbox(0,"Verisons-Historie", $VersionsHistorie)
                        $GUIinfo=GUICreate("Info", 400, 200, -1, -1, -1, -1, $GUI1id)
                        GUICtrlCreateEdit($VersionsHistorie, 10, 10, 380, 180)
                        GUICtrlSetBkColor(-1, 0xFFFFFF)
                        GUISetBkColor(0xFFFFFF, $GUIinfo)
                        $GUIInfoFlag=1
                        GUISetState()
                        Send("{PGUP}")
                        Send("{PGUP}")
                        Send("{PGUP}")
				  Case $msg=$GUI1ButtonEditmodel and $GUI2flag=0															; bearbeiten Button
                        Editmodels()
				  Case $msg=$GUI1ChangeFontButton and $FontChangeFlag
                        $FontCurrent=GUICtrlRead($GUI1FontList)
                        GUISetFont($fontsize, -1, -1, $FontCurrent)

                        GUIDelete($GUI1id)
                        GUI()
                        DisplayData()
                        $FontChangeFlag=0
                        GUICtrlSetState($GUI1ChangeFontButton, $GUI_DISable)
				  EndSelect

                If $BufferEV<>GUICtrlRead($GUI1EVmodel) and  GUICtrlRead($GUI1EVmodel)<>"" Then				; Änderung des modeles üerwachen
                        $BufferEV=GUICtrlRead($GUI1EVmodel)
                        ChangeEV()
			DisplayEVmodel()
                EndIf

                If $Buffer<>BufferRead() Then																													; Änderung der Eingabe-Felder überwachen
                        $Buffer=BufferRead()																															;
                        If GUICtrlRead($GUI1Strecke)>"" and GUICtrlRead($GUI1ladeleistung)>"" Then							; bei Änderug neu berechnen
                                Calc()
                                DisplayData()
                        EndIf
                EndIf

                If GUICtrlRead($GUI1FontList)<>$FontCurrent and $FontChangeFlag=0 Then										; ändern des font überwachen
                        $FontChangeFlag=1
                        GUICtrlSetState($GUI1ChangeFontButton, $GUI_ENable)
                EndIf

   WEnd
   #EndRegion

   #Region actualize GUI when EV is changed
   Func ChangeEV()
        For $t=1 to $EVcount
                If $BufferEV=$EVdata[$t][1] & " " & $EVdata[$t][2] Then
                        ;$Verbrauch="9,10,12,14,16,18,21,23"
                        $Verbrauch=$EVdata[$t][3] & "," &$EVdata[$t][4] & "," & $EVdata[$t][5] & "," & $EVdata[$t][6] & "," & $EVdata[$t][7] & "," & $EVdata[$t][8] & "," & $EVdata[$t][9] & "," & $EVdata[$t][10]
                        $Kapazitaet=$EVdata[$t][11]
                        $Ladeleistung=$EVdata[$t][12]
						$SOCunten=$EVdata[$t][13]
						$SOCoben=$EVdata[$t][14]
                        DisplayEVmodel()
                        $LASTmodel=$t
                        INIwrite($DBFile, "CONFIG", "LASTmodel", $LASTmodel)
                        INIwrite($DBFile, "CONFIG", "LASTkm", GUICtrlRead($GUI1Strecke))
                EndIf
        Next

   EndFunc
   #EndRegion

   #Region Save EV Data
   Func SaveEVdata()
        INIwrite($DBFile, "CONFIG", "LASTmodel", $LASTmodel)										; das aktuelle model in der INI sichern
        INIwrite($DBFile, "CONFIG", "LASTkm", GUICtrlRead($GUI1Strecke))				; aktuelle km Angabe in der INI sichern
        INIwrite($DBFile, "CONFIG", "WAY2CHARGE", $AnfahrtLadepunkt)						; sichern des Anfahrt zum Ladepunkt (z.Zt. noch nicht in der der GUI verfügbar)
        INIwrite($DBFile, "CONFIG", "FONT", $FontCurrent)												; aktuellen font sichern
        INIwrite($DBFile, "CONFIG", "DEBUG", $Debug)

        ; SYNTAX=Hersteller,model,80,90,100,110,120,130,140,150,Kapazitaet, Schnellladeleistung, SOCunten, SOCoben

        $tmp=$EVdata[$LASTmodel][1] & "," & $EVdata[$LASTmodel][2] & "," & $EVdata[$LASTmodel][3] & "," & $EVdata[$LASTmodel][4] & "," & $EVdata[$LASTmodel][5] & "," & $EVdata[$LASTmodel][6] & "," & $EVdata[$LASTmodel][7] & "," & $EVdata[$LASTmodel][8] & "," & $EVdata[$LASTmodel][9] & "," & $EVdata[$LASTmodel][10] & "," & $EVdata[$LASTmodel][11] & "," & $EVdata[$LASTmodel][12] & "," & $EVdata[$LASTmodel][13] & "," & $EVdata[$LASTmodel][14]
        INIwrite($DBFile, "DATA", $LASTmodel, $tmp)
   EndFunc
   #EndRegion

   #Region create new EV data base
   Func EVdataCreate()																														;
				  INIwrite($DBFile, "CONFIG", "LASTmodel", 1)
				  INIwrite($DBFile, "CONFIG", "WAY2CHARGE", $AnfahrtLadepunkt)
				  INIwrite($DBFile, "CONFIG", "FONT", $FontArray[1])
				  INIwrite($DBFile, "CONFIG", "DEBUG", 0)

				  INIwrite($DBFile, "DATA", "SYNTAX", stringreplace("Hersteller ,Model								,80,90,100,110,120,130,140,150	,Kapazitaet	,Schnellladeleistung"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "1"		, stringreplace("Hyundai	,Ioniq Elektro (28 kWh)				,9,10,11,13,14,17,21,23			,28			,70							, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "2"		, stringreplace("Hyundai	,Ioniq Elektro (Facelift) (39 kWh)	,9,10,11,13,14,17,21,23			,39			,56							, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "3"		, stringreplace("Hyundai	,Kona (64 kWh)						,10,12,15,17,19,22,24,26		,64			,56							, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "4"		, stringreplace("Kia		,Soul EV (33 kWh)					,12,13,14,16,18,21,24,26		,30			,50							, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "5"		, stringreplace("VW			,e-Golf (21 kWh)					,10,12,15,17,19,22,24,26		,21			,43							, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "6"		, stringreplace("VW			,e-Golf (35 kWh)					,10,12,15,17,19,22,24,26		,35			,43							, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "7"		, stringreplace("Renault	,Zoe (40 kWh)						,9,10,12,14,16,18,21,23			,40			,43							, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "8"		, stringreplace("Tesla		,Model S (60 kWh)					,13,14,15,16,17,19,23,26		,60			,96							, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "9"		, stringreplace("Tesla		,Model S (75 kWh)					,13,14,15,16,17,19,23,26		,75			,96							, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "10"	, stringreplace("Tesla		,Model S (85 kWh)					,13,14,15,16,17,19,23,26		,85			,120						, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "11"	, stringreplace("Tesla		,Model S (90 kWh)					,13,14,15,16,17,19,23,26		,90			,120						, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "12"	, stringreplace("Tesla		,Model S (100 kWh)					,13,14,15,16,17,19,23,26		,100		,120						, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "13"	, stringreplace("Tesla		,Model X (100 kWh)					,15,16,17,18,19,21,25,28		,100		,120						, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "14"	, stringreplace("Tesla		,Model 3 (75 kWh)					,10,11,12,13,14,16,18,22		,75			,120						, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "15"	, stringreplace("Tesla		,Model Y (77 kWh)					,12,13,14,16,18,21,23,25		,77			,120						, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "16"	, stringreplace("Nissan		,Leaf (30 kWh)						,11,12,14,16,18,20,23,25		,30			,70							, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "17"	, stringreplace("Opel		,Ampera-e (60 kWh)					,10,12,15,17,19,22,24,26		,60			,60							, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "18"	, stringreplace("Jaguar		,I-PACE (90 kWh)					,14,15,16,17,18,20,24,27		,90			,80							, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "19"	, stringreplace("Volvo		,XC40 Recharged P8 AWD (75 kWh)		,11,13,15,17,19,22,25,27		,75			,150						, 20, 80"		, @TAB, ""))
				  INIwrite($DBFile, "DATA", "20"	, stringreplace("Hyundai	,Ioniq Elektro (fiktive 64 kWh)		,9,10,12,14,16,18,21,23			,64			,70							, 20, 80"		, @TAB, ""))
                ;INIwrite($DBFile, "DATA", "21"		, stringreplace("Hyundai	,Ioniq Elektro (fiktive 100 kWh)	,9,10,12,14,16,18,21,23			,100		,70							, 20, 80"		, @TAB, ""))
                ; 				20=Volvo,XC40 Recharged P8,12,15,18,21,25,28,31,35,75,150, 10, 90
		;INIwrite($DBFile, "DATA", "18"		, stringreplace("Hyundai			,Kia soulEV (33 kWh)	,11,13,15,17,19,22,25,27					,100		,70					, @TAB, ""))
				  INIwrite($DBFile, "DATA", "21"	, stringreplace("Audi		,Audi e-tron Q5-50 (82 kWh)			,14,16,18,20,22,24,27,30		,76			,125						, 20, 80"		, @TAB, ""))

        EndFunc
        #EndRegion

        #Region read EV-database
        Func EVdataRead()
                $timer=TimerInit()
                $AnfahrtLadepunkt=INIRead($DBFile, "CONFIG", "WAY2CHARGE", 5)
                $Debug=INIRead($DBFile, "CONFIG", "DEBUG", 0)
                $FontCurrent=INIRead($DBFile, "CONFIG", "FONT", "ARIAL")
                $FontTemp=$FontCurrent
                $tempCount=1
                while $DataEndFlag=0
                        $temp=INIRead($DBFile, "DATA", $tempCount, "")
                        If $temp="" then
                                $DataEndFlag=1
                                $EVcount=$tempCount-1
                        Else
                                $EVdataReadTempArray=StringSplit($temp, ",")
                        If $EVdataReadTempArray[0]=14 Then
                                For $x=1 to 14
                                        $EVdata[$tempCount][$x]=$EVdataReadTempArray[$x]
                                Next
                        EndIf
                                $tempCount=$tempCount+1
                        Endif
                Wend
        EndFunc
        #EndRegion

        #Region set GUI controls with EV data
        Func DisplayEVmodel()
                $TempVerbrauch=StringSplit($Verbrauch, ",")
                $Verbrauch80=$TempVerbrauch[1]
                GUICtrlSetData($GUI1LabelVerbrauch80, $Verbrauch80)
                $Verbrauch90=$TempVerbrauch[2]
                GUICtrlSetData($GUI1LabelVerbrauch90, $Verbrauch90)
                $Verbrauch100=$TempVerbrauch[3]
                GUICtrlSetData($GUI1LabelVerbrauch100, $Verbrauch100)
                $Verbrauch110=$TempVerbrauch[4]
                GUICtrlSetData($GUI1LabelVerbrauch110, $Verbrauch110)
                $Verbrauch120=$TempVerbrauch[5]
                GUICtrlSetData($GUI1LabelVerbrauch120, $Verbrauch120)
                $Verbrauch130=$TempVerbrauch[6]
                GUICtrlSetData($GUI1LabelVerbrauch130, $Verbrauch130)
                $Verbrauch140=$TempVerbrauch[7]
                GUICtrlSetData($GUI1LabelVerbrauch140, $Verbrauch140)
                $Verbrauch150=$TempVerbrauch[8]
                GUICtrlSetData($GUI1LabelVerbrauch150, $Verbrauch150)
                $KapazitaetNetto=$Kapazitaet * (($SOCoben - $SOCunten) / 100)
				;msgbox(0, "", $SOCoben - $SOCunten, 1)
				GUICtrlSetData($GUI1LadedauerLabel, "Ladezeit bei SOC" & $SOCunten & " -" &  $SOCoben & "%")
                GUICtrlSetData($GUI1kapazitaet, $KapazitaetNetto)
				GUICtrlSetData($GUI1kapazitaetLabel, "Nutz-Kapazität bei" & $SOCunten & " -" &  $SOCoben & "%")
                GUICtrlSetData($GUI1Ladeleistung, $Ladeleistung)
        EndFunc
        #EndRegion

        #Region refresh GUI input-change-buffer
        Func BufferRead()
                $BufferRC=GUICtrlRead($GUI1Strecke) & GUICtrlRead($GUI1kapazitaet) & GUICtrlRead($GUI1ladedauer) & GUICtrlRead($GUI1ladeleistung); & GUICtrlRead($GUI1unten) &  GUICtrlRead($GUI1SOCoben)
                ;$BufferRC=$Strecke & $kapazitaet & $ladedauer & $Ladeleistung & GUICtrlRead($GUI1EVmodel)
                Return $BufferRC
        EndFunc
        #EndRegion

        #Region clear GUI Controls
        Func ClearDisplay()

                GUICtrlSetData($GUI1LabelVerbrauch80, "")
                GUICtrlSetData($GUI1LabelVerbrauch90, "")
                GUICtrlSetData($GUI1LabelVerbrauch100, "")
                GUICtrlSetData($GUI1LabelVerbrauch110, "")
                GUICtrlSetData($GUI1LabelVerbrauch120, "")
                GUICtrlSetData($GUI1LabelVerbrauch130, "")
                GUICtrlSetData($GUI1LabelVerbrauch140, "")
                GUICtrlSetData($GUI1LabelVerbrauch150, "")

                GUICtrlSetData($GUI1LabelReichweite80, "")
                GUICtrlSetData($GUI1LabelReichweite90, "")
                GUICtrlSetData($GUI1LabelReichweite100, "")
                GUICtrlSetData($GUI1LabelReichweite110, "")
                GUICtrlSetData($GUI1LabelReichweite120, "")
                GUICtrlSetData($GUI1LabelReichweite130, "")
                GUICtrlSetData($GUI1LabelReichweite140, "")
                GUICtrlSetData($GUI1LabelReichweite150, "")

                GUICtrlSetData($GUI1LabelLadenAnzahl80, "")
                GUICtrlSetData($GUI1LabelLadenAnzahl90, "")
                GUICtrlSetData($GUI1LabelLadenAnzahl100, "")
                GUICtrlSetData($GUI1LabelLadenAnzahl110, "")
                GUICtrlSetData($GUI1LabelLadenAnzahl120, "")
                GUICtrlSetData($GUI1LabelLadenAnzahl130, "")
                GUICtrlSetData($GUI1LabelLadenAnzahl140, "")
                GUICtrlSetData($GUI1LabelLadenAnzahl150, "")

                GUICtrlSetData($GUI1LabelFahrzeit80, "")
                GUICtrlSetData($GUI1LabelFahrzeit90, "")
                GUICtrlSetData($GUI1LabelFahrzeit100, "")
                GUICtrlSetData($GUI1LabelFahrzeit110, "")
                GUICtrlSetData($GUI1LabelFahrzeit120, "")
                GUICtrlSetData($GUI1LabelFahrzeit130, "")
                GUICtrlSetData($GUI1LabelFahrzeit140, "")
                GUICtrlSetData($GUI1LabelFahrzeit150, "")

                GUICtrlSetData($GUI1LabelLadezeit80, GUICtrlRead($GUI1ladedauer) * GUICtrlRead($GUI1LabelLadenAnzahl80))
                GUICtrlSetData($GUI1LabelLadezeit90, GUICtrlRead($GUI1ladedauer) * GUICtrlRead($GUI1LabelLadenAnzahl90))
                GUICtrlSetData($GUI1LabelLadezeit100, GUICtrlRead($GUI1ladedauer) * GUICtrlRead($GUI1LabelLadenAnzahl100))
                GUICtrlSetData($GUI1LabelLadezeit110, GUICtrlRead($GUI1ladedauer) * GUICtrlRead($GUI1LabelLadenAnzahl110))
                GUICtrlSetData($GUI1LabelLadezeit120, GUICtrlRead($GUI1ladedauer) * GUICtrlRead($GUI1LabelLadenAnzahl120))
                GUICtrlSetData($GUI1LabelLadezeit130, GUICtrlRead($GUI1ladedauer) * GUICtrlRead($GUI1LabelLadenAnzahl130))
                GUICtrlSetData($GUI1LabelLadezeit140, GUICtrlRead($GUI1ladedauer) * GUICtrlRead($GUI1LabelLadenAnzahl140))
                GUICtrlSetData($GUI1LabelLadezeit150, GUICtrlRead($GUI1ladedauer) * GUICtrlRead($GUI1LabelLadenAnzahl150))

                GUICtrlSetData($GUI1LabelReisezeit80, round(GUICtrlRead($GUI1LabelLadezeit80)/60 + GUICtrlRead($GUI1LabelFahrzeit80),1))
                GUICtrlSetData($GUI1LabelReisezeit90,  round(GUICtrlRead($GUI1LabelLadezeit90)/60 + GUICtrlRead($GUI1LabelFahrzeit90),1))
                GUICtrlSetData($GUI1LabelReisezeit100,  round(GUICtrlRead($GUI1LabelLadezeit100)/60 + GUICtrlRead($GUI1LabelFahrzeit100),1))
                GUICtrlSetData($GUI1LabelReisezeit110,  round(GUICtrlRead($GUI1LabelLadezeit110)/60 + GUICtrlRead($GUI1LabelFahrzeit110),1))
                GUICtrlSetData($GUI1LabelReisezeit120,  round(GUICtrlRead($GUI1LabelLadezeit120)/60 + GUICtrlRead($GUI1LabelFahrzeit120),1))
                GUICtrlSetData($GUI1LabelReisezeit130,  round(GUICtrlRead($GUI1LabelLadezeit130)/60 + GUICtrlRead($GUI1LabelFahrzeit130),1))
                GUICtrlSetData($GUI1LabelReisezeit140,  round(GUICtrlRead($GUI1LabelLadezeit140)/60 + GUICtrlRead($GUI1LabelFahrzeit140),1))
                GUICtrlSetData($GUI1LabelReisezeit150,  round(GUICtrlRead($GUI1LabelLadezeit150)/60 + GUICtrlRead($GUI1LabelFahrzeit150),1))
        EndFunc
        #EndRegion

        #Region Re-calculate GUI data
        Func Calc()

                $Ladedauer=round(60/GUICtrlRead($GUI1ladeleistung))* $KapazitaetNetto;GUICtrlRead($GUI1kapazitaet)
                $Ladedauer=(60/GUICtrlRead($GUI1ladeleistung))* $KapazitaetNetto

                ;msgbox(0,"$Ladedauer", $Ladedauer & "-" & GUICtrlRead($GUI1ladeleistung))

                $Strecke=GUICtrlRead($GUI1Strecke)

                $Reichweite80=($KapazitaetNetto/$Verbrauch80)*100
                $Reichweite90=($KapazitaetNetto/$Verbrauch90)*100
                $Reichweite100=($KapazitaetNetto/$Verbrauch100)*100
                $Reichweite110=($KapazitaetNetto/$Verbrauch110)*100
                $Reichweite120=($KapazitaetNetto/$Verbrauch120)*100
                $Reichweite130=($KapazitaetNetto/$Verbrauch130)*100
                $Reichweite140=($KapazitaetNetto/$Verbrauch140)*100
                $Reichweite150=($KapazitaetNetto/$Verbrauch150)*100

                $LadenAnzahl80=INT($Strecke / $Reichweite80)
                $LadenAnzahl90=INT($Strecke / $Reichweite90)
                $LadenAnzahl100=INT($Strecke / $Reichweite100)
                $LadenAnzahl110=INT($Strecke / $Reichweite110)
                $LadenAnzahl120=INT($Strecke / $Reichweite120)
                $LadenAnzahl130=INT($Strecke / $Reichweite130)
                $LadenAnzahl140=INT($Strecke / $Reichweite140)
                $LadenAnzahl150=INT($Strecke / $Reichweite150)

                $Min80 =$Strecke / 80*60
                $Min90 =$Strecke / 90*60
                $Min100=$Strecke /100*60
                $Min110=$Strecke /110*60
                $Min120=$Strecke /120*60
                $Min130=$Strecke /130*60
                $Min140=$Strecke /140*60
                $Min150=$Strecke /150*60

                If $LadenAnzahl80<1 Then
                        $Ladezeit80=0
                Else
                        $Ladezeit80=($Ladedauer + $AnfahrtLadepunkt) * $LadenAnzahl80
                EndIf

                If $LadenAnzahl90<1 Then
                        $Ladezeit90=0
                Else
                        $Ladezeit90=($Ladedauer + $AnfahrtLadepunkt) * $LadenAnzahl90
                EndIf
                If $LadenAnzahl100<1 Then
                        $Ladezeit100=0
                Else
                        $Ladezeit100=($Ladedauer + $AnfahrtLadepunkt) * $LadenAnzahl100
                EndIf
                If $LadenAnzahl110<1 Then
                        $Ladezeit110=0
                Else
                        $Ladezeit110=($Ladedauer + $AnfahrtLadepunkt) * $LadenAnzahl110
                EndIf
                If $LadenAnzahl120<1 Then
                        $Ladezeit120=0
                Else
                        $Ladezeit120=($Ladedauer + $AnfahrtLadepunkt) * $LadenAnzahl120
                EndIf
                If $LadenAnzahl130<1 Then
                        $Ladezeit130=0
                Else
                 $Ladezeit130=($Ladedauer + $AnfahrtLadepunkt) * $LadenAnzahl130
          EndIf
          If $LadenAnzahl140<1 Then
                 $Ladezeit140=0
          Else
                        $Ladezeit140=($Ladedauer + $AnfahrtLadepunkt) * $LadenAnzahl140
                EndIf
                If $LadenAnzahl150<1 Then
                        $Ladezeit150=0
                Else
                        $Ladezeit150=($Ladedauer + $AnfahrtLadepunkt) * $LadenAnzahl150
                EndIf

                $Reisezeit80=$Ladezeit80 + $Min80
                $Reisezeit90=$Ladezeit90 + $Min90
                $Reisezeit100=$Ladezeit100 + $Min100
                $Reisezeit110=$Ladezeit110 + $Min110
                $Reisezeit120=$Ladezeit120 + $Min120
                $Reisezeit130=$Ladezeit130 + $Min130
                $Reisezeit140=$Ladezeit140 + $Min140
                $Reisezeit150=$Ladezeit150 + $Min150

        EndFunc
        #EndRegion

        #Region display GUI data
		 Func DisplayData()

			GUICtrlSetData($GUI1Ladedauer, 				TimeConv($Ladedauer))
			GUICtrlSetData($GUI1Ladeleistung, 				$ladeleistung)

			GUICtrlSetData($GUI1LabelVerbrauch80,	$Verbrauch80)
			GUICtrlSetData($GUI1LabelVerbrauch90,	$Verbrauch90)
			GUICtrlSetData($GUI1LabelVerbrauch100,	$Verbrauch100)
			GUICtrlSetData($GUI1LabelVerbrauch110,	$Verbrauch110)
			GUICtrlSetData($GUI1LabelVerbrauch120,	$Verbrauch120)
			GUICtrlSetData($GUI1LabelVerbrauch130,	$Verbrauch130)
			GUICtrlSetData($GUI1LabelVerbrauch140,	$Verbrauch140)
			GUICtrlSetData($GUI1LabelVerbrauch150,	$Verbrauch150)

			GUICtrlSetData($GUI1LabelReichweite80,	Int($Reichweite80))
			GUICtrlSetData($GUI1LabelReichweite90,	Int($Reichweite90))
			GUICtrlSetData($GUI1LabelReichweite100,	Int($Reichweite100))
			GUICtrlSetData($GUI1LabelReichweite110,	Int($Reichweite110))
			GUICtrlSetData($GUI1LabelReichweite120,	Int($Reichweite120))
			GUICtrlSetData($GUI1LabelReichweite130,	Int($Reichweite130))
			GUICtrlSetData($GUI1LabelReichweite140,	Int($Reichweite140))
			GUICtrlSetData($GUI1LabelReichweite150,	Int($Reichweite150))

			GUICtrlSetData($GUI1LabelLadenAnzahl80,	Floor($LadenAnzahl80))
			GUICtrlSetData($GUI1LabelLadenAnzahl90,	Floor($LadenAnzahl90))
			GUICtrlSetData($GUI1LabelLadenAnzahl100,	Floor($LadenAnzahl100))
			GUICtrlSetData($GUI1LabelLadenAnzahl110,	Floor($LadenAnzahl110))
			GUICtrlSetData($GUI1LabelLadenAnzahl120,	Floor($LadenAnzahl120))
			GUICtrlSetData($GUI1LabelLadenAnzahl130,	Floor($LadenAnzahl130))
			GUICtrlSetData($GUI1LabelLadenAnzahl140,	Floor($LadenAnzahl140))
			GUICtrlSetData($GUI1LabelLadenAnzahl150,	Floor($LadenAnzahl150))

			GUICtrlSetData($GUI1LabelFahrzeit80, 	TimeConv($Min80))
			GUICtrlSetData($GUI1LabelFahrzeit90,	TimeConv($Min90))
			GUICtrlSetData($GUI1LabelFahrzeit100,	TimeConv($Min100))
			GUICtrlSetData($GUI1LabelFahrzeit110,	TimeConv($Min110))
			GUICtrlSetData($GUI1LabelFahrzeit120,	TimeConv($Min120))
			GUICtrlSetData($GUI1LabelFahrzeit130,	TimeConv($Min130))
			GUICtrlSetData($GUI1LabelFahrzeit140,	TimeConv($Min140))
			GUICtrlSetData($GUI1LabelFahrzeit150,	TimeConv($Min150))

			GUICtrlSetData($GUI1LabelLadezeit80,	TimeConv($Ladezeit80))
			GUICtrlSetData($GUI1LabelLadezeit90,	TimeConv($Ladezeit90))
			GUICtrlSetData($GUI1LabelLadezeit100,	TimeConv($Ladezeit100))
			GUICtrlSetData($GUI1LabelLadezeit110,	TimeConv($Ladezeit110))
			GUICtrlSetData($GUI1LabelLadezeit120,	TimeConv($Ladezeit120))
			GUICtrlSetData($GUI1LabelLadezeit130,	TimeConv($Ladezeit130))
			GUICtrlSetData($GUI1LabelLadezeit140,	TimeConv($Ladezeit140))
			GUICtrlSetData($GUI1LabelLadezeit150,	TimeConv($Ladezeit150))

			GUICtrlSetData($GUI1LabelReisezeit80,	TimeConv($Reisezeit80))
			GUICtrlSetData($GUI1LabelReisezeit90,	TimeConv($Reisezeit90))
			GUICtrlSetData($GUI1LabelReisezeit100,TimeConv($Reisezeit100))
			GUICtrlSetData($GUI1LabelReisezeit110,TimeConv($Reisezeit110))
			GUICtrlSetData($GUI1LabelReisezeit120,TimeConv($Reisezeit120))
			GUICtrlSetData($GUI1LabelReisezeit130,TimeConv($Reisezeit130))
			GUICtrlSetData($GUI1LabelReisezeit140,TimeConv($Reisezeit140))
			GUICtrlSetData($GUI1LabelReisezeit150,TimeConv($Reisezeit150))

		 EndFunc
		 #EndRegion

        #Region GUI2 Change Buffer
        Func GUI2ChangeBuffer()
                Return GUICtrlRead($GUI2Input[1]) & GUICtrlRead($GUI2Input[2]) & GUICtrlRead($GUI2Input[3]) & GUICtrlRead($GUI2Input[4]) & GUICtrlRead($GUI2Input[5]) & GUICtrlRead($GUI2Input[6]) & GUICtrlRead($GUI2Input[7]) & GUICtrlRead($GUI2Input[8]) & GUICtrlRead($GUI2Input[9]) & GUICtrlRead($GUI2Input[10]) & GUICtrlRead($GUI2Input[11]) & GUICtrlRead($GUI2Input[12]) & GUICtrlRead($GUI2Input[13]) & GUICtrlRead($GUI2Input[14])
        EndFunc
        #EndRegion

        #Region Edit EV-models
        Func  Editmodels()

			   local $SOCfalseFlag

			   #Region Create GUI
			   $GUI2id=GUICreate("Fahrzeug bearbeiten"						,  900, 460, (@DesktopWidth/2)-450, (@DesktopHeight/2)-250, $WS_CAPTION, -1					, $GUI1id)

                GUICtrlCreateLabel("Hersteller :"													,  10,  15, 110, 18)
				GUICtrlSetFont(-1, $Fontsize)
                $GUI2Input[1]=GUICtrlCreateInput($EVdata[$LASTmodel][1]		, 135,  10, 200, 20)
                GUICtrlSetFont(-1, $Fontsize)

                GUICtrlCreateLabel("Modell :"															,  10,  45, 110, 18)
				GUICtrlSetFont(-1, $Fontsize)
                $GUI2Input[2]=GUICtrlCreateInput($EVdata[$LASTmodel][2]		, 135,  40, 200, 20)
                GUICtrlSetFont(-1, $Fontsize)

                GUICtrlCreateLabel("Akku-Kapazität :"												,  10,  75, 110, 18)
				GUICtrlSetFont(-1, $Fontsize)
                $GUI2Input[11]=	GUICtrlCreateInput($EVdata[$LASTmodel][11]	, 135,  70,  40, 20)
				GUICtrlSetFont(-1, $Fontsize)
												GUICtrlCreateLabel("Kwh"									, 180,  73,  40, 20)
                GUICtrlSetFont(-1, $Fontsize)

                GUICtrlCreateLabel("max. Ladeleistung :"											,  10, 105, 140, 18)
				GUICtrlSetFont(-1, $Fontsize)
                $GUI2Input[12]=	GUICtrlCreateInput($EVdata[$LASTmodel][12]	, 135, 100,  40, 20)
				GUICtrlSetFont(-1, $Fontsize)
												GUICtrlCreateLabel("Kw"										, 180,  103,  40, 20)
                GUICtrlSetFont(-1, $Fontsize)

				GUICtrlCreateLabel("SOC unten :"														,  10, 135, 140, 18)
				GUICtrlSetTip(-1, "Unterer Ladestand bei dem der Ladevorgang begonnen wird")
				GUICtrlSetFont(-1, $Fontsize)
                $GUI2Input[13]=GUICtrlCreateInput($EVdata[$LASTmodel][13]	, 135, 130,  40, 20)
				GUICtrlSetFont(-1, $Fontsize)
												GUICtrlCreateLabel("%"										, 180, 133,  40, 20)
                GUICtrlSetFont(-1, $Fontsize)

				GUICtrlCreateLabel("SOC oben :"														,  10, 165, 140, 18)
				GUICtrlSetFont(-1, $Fontsize)
				 GUICtrlSetTip(-1, "Oberer Ladestand bei dem der Ladevorgang abgeschlossen wird")
                $GUI2Input[14]=GUICtrlCreateInput($EVdata[$LASTmodel][14]	, 135, 160,  40, 20)
				GUICtrlSetFont(-1, $Fontsize)
												GUICtrlCreateLabel("%"										, 180, 163,  40, 20)
                GUICtrlSetFont(-1, $Fontsize)


                GUICtrlCreateLabel("Verbrauch :"													,  10, 200, 100, 18)
				GUICtrlSetFont(-1, $Fontsize)

                GUICtrlCreateLabel("80 km/h :"														,  10, 225, 100, 18)
				GUICtrlSetFont(-1, $Fontsize)
                $GUI2Input[3]=GUICtrlCreateInput($EVdata[$LASTmodel][3]		, 135, 220,  40, 20)
                GUICtrlSetFont(-1, $Fontsize)
				GUICtrlCreateLabel("Kwh"																, 180,  223,  40, 20)
				GUICtrlSetFont(-1, $Fontsize)

                GUICtrlCreateLabel("90 km/h :"														,  10, 245, 100, 18)
				GUICtrlSetFont(-1, $Fontsize)
                $GUI2Input[4]= GUICtrlCreateInput($EVdata[$LASTmodel][4]	, 135, 240,  40, 20)
                GUICtrlSetFont(-1, $Fontsize)
				GUICtrlCreateLabel("Kwh"																, 180,  243,  40, 20)
				GUICtrlSetFont(-1, $Fontsize)

                GUICtrlCreateLabel("100 km/h :"													,  10, 265, 100, 18)
				GUICtrlSetFont(-1, $Fontsize)
                $GUI2Input[5]=GUICtrlCreateInput($EVdata[$LASTmodel][5]		, 135, 260,  40, 20)
                GUICtrlSetFont(-1, $Fontsize)
				GUICtrlCreateLabel("Kwh"																, 180,  263,  40, 20)
				GUICtrlSetFont(-1, $Fontsize)

                GUICtrlCreateLabel("110 km/h :"													,  10, 285, 100, 18)
				GUICtrlSetFont(-1, $Fontsize)
                $GUI2Input[6]=GUICtrlCreateInput($EVdata[$LASTmodel][6]		, 135, 280,  40, 20)
                GUICtrlSetFont(-1, $Fontsize)
				GUICtrlCreateLabel("Kwh"																, 180,  283,  40, 20)
				GUICtrlSetFont(-1, $Fontsize)

                GUICtrlCreateLabel("120 km/h :"													,  10, 305, 100, 18)
				GUICtrlSetFont(-1, $Fontsize)
                $GUI2Input[7]=GUICtrlCreateInput($EVdata[$LASTmodel][7]		, 135, 300,  40, 20)
                GUICtrlSetFont(-1, $Fontsize)
				GUICtrlCreateLabel("Kwh"																, 180,  303,  40, 20)
				GUICtrlSetFont(-1, $Fontsize)

                GUICtrlCreateLabel("130 km/h :"													,  10, 325, 100, 18)
				GUICtrlSetFont(-1, $Fontsize)
                $GUI2Input[8]=GUICtrlCreateInput($EVdata[$LASTmodel][8]		, 135, 320,  40, 20)
                GUICtrlSetFont(-1, $Fontsize)
				GUICtrlCreateLabel("Kwh"																, 180,  323,  40, 20)
				GUICtrlSetFont(-1, $Fontsize)

                GUICtrlCreateLabel("140 km/h :"													,  10, 345, 100, 18)
				GUICtrlSetFont(-1, $Fontsize)
                $GUI2Input[9]=GUICtrlCreateInput($EVdata[$LASTmodel][9]		, 135, 340,  40, 20)
                GUICtrlSetFont(-1, $Fontsize)
				GUICtrlCreateLabel("Kwh"																, 180,  343,  40, 20)
				GUICtrlSetFont(-1, $Fontsize)

                GUICtrlCreateLabel("150 km/h :"													,  10, 365, 100, 18)
				GUICtrlSetFont(-1, $Fontsize)
                $GUI2Input[10]=GUICtrlCreateInput($EVdata[$LASTmodel][10], 135, 360,  40, 20)
                GUICtrlSetFont(-1, $Fontsize)
				GUICtrlCreateLabel("Kwh"																, 180,  363,  40, 20)
				GUICtrlSetFont(-1, $Fontsize)

                $GUI2ButtonNew=GUICtrlCreateButton(" Neu "						,  10, 420)
                GUICtrlSetFont(-1, $Fontsize)
				GUICtrlSetTip(-1, "Neues Fahrezeug anlegen")
                $GUI2ButtonSave=GUICtrlCreateButton(" Übernehmen "		, 60, 420, 100)
                GUICtrlSetFont(-1, $Fontsize)
                GUICtrlSetState(-1, $GUI_DISable)
				GUICtrlSetTip(-1, "Übernehmen der Werte und sichern in der Datenbank")
                $GUI2ButtonCancel=GUICtrlCreateButton(" Abbruch "			, 170, 420,  80)
                GUICtrlSetFont(-1, $Fontsize)
				GUICtrlSetTip(-1, "Änderungen verwerfen und Eingabefenster schliessen")
                $GUI2ButtonOK=GUICtrlCreateButton("  OK  "						, 260, 420,  80)
                GUICtrlSetFont(-1, $Fontsize)
				GUICtrlSetTip(-1, "Sichern der Werte und Eingabefenster schliessen")


                 GUISetState()
			   #EndRegion

			   For $t=1 to 12
				  $GrafikTempEVdata[$t] = $EVdata[$LASTmodel][$t]
			   Next

			   GrafikZeichnen()

                $GUI2ChangeBuffer = GUI2ChangeBuffer()
				$GUI2ChangeFlag = 0
				$GUI2SaveFlag=0
                $GUI2flag=1

                While $GUI2flag=1
                        $msg=GUIGetMsg()
                        Select
                        Case $msg=$GUI2ButtonNew
                                $EVcount=$EVcount+1
                                $LASTmodel=$EVcount
                                $GUI2ChangeFlag=1
                                GUICtrlSetState($GUI2ButtonSelect, $GUI_ENable)
                                For $t=1 to 12
									GUICtrlSetData($GUI2Input[$t],"")
                                Next
						Case $msg=$GUI2ButtonSave
								$GUI2ChangeBuffer = GUI2ChangeBuffer()
								$GUI2SaveFlag=1
								 $GUI2ChangeFlag=1
								;$GUI2flag=2
								 For $t=1 to 12
									   $GrafikTempEVdata[$t] = GUICtrlRead($GUI2Input[$t] ) ;$EVdata[$LASTmodel][$t]
								 Next
								 ; SaveEVdata()
								 ; IniWrite($DBFile, "CONFIG", "LASTmodel", $LASTmodel)

								GrafikZeichnen()
						Case $msg=$GUI2ButtonOK
							If $GUI2SaveFlag=1 or $GUI2ChangeFlag=1 Then
							  $GUI2flag=2
						   Else
							  $GUI2flag=0
						   EndIf
                        Case $msg=$GUI2ButtonCancel
                                $GUI2flag=0
						EndSelect

						If GUICtrlRead($GUI2Input[14]) < GUICtrlRead($GUI2Input[13] ) and  $SOCfalseFlag=0 Then		; eingegebeneSOC werte prüfen
						   GUICtrlSetBkColor($GUI2Input[13], 0xFF0000)																						; und betroffene Felder auf rot setzen
						   GUICtrlSetBkColor($GUI2Input[14], 0xFF0000)																						;
						   $SOCfalseFlag=1																																		;
						EndIf																																								;
						If GUICtrlRead($GUI2Input[14]) > GUICtrlRead($GUI2Input[13] ) and  $SOCfalseFlag=1 Then		; wenn werte gueltig, Felder wieder weissen
						   GUICtrlSetBkColor($GUI2Input[14], 0xFFFFFF)																					;
						   GUICtrlSetBkColor($GUI2Input[13], 0xFFFFFF)																					;
						   $SOCfalseFlag=0																																		;
						EndIf

						For $t=1 to 8
						   ; geplante button abfrage zum verchieben
						   If $msg=$GUI2ScalaButton[$t] and _IsPressed("01") Then
							  msgbox(0,$t, $GrafikTempEVdata[$t+2])
						   EndIf
						Next

                        If $GUI2ChangeBuffer <> GUI2ChangeBuffer() and  $GUI2ChangeFlag=0 Then							;aktivieren des Übernahme Buttons wenn sich die Eingaben ändern
                                $GUI2ChangeFlag=1
                                GUICtrlSetState($GUI2ButtonSave, $GUI_ENable)
							 EndIf
						If $GUI2ChangeBuffer = GUI2ChangeBuffer() and  $GUI2ChangeFlag=1 Then								; de-aktivieren des Übernahme Buttons wenn die Eingaben sich nicht ändern
                                $GUI2ChangeFlag=0
                                GUICtrlSetState($GUI2ButtonSave, $GUI_DISable)
                        EndIf
						#cs
                        If $GUI2ChangeBuffer = GUI2ChangeBuffer() and  $GUI2ChangeFlag=1 and  $SOCfalseFlag=0 Then
						   $GUI2ChangeFlag=0
						   GUICtrlSetState($GUI2ButtonSave, $GUI_DISable)
						   For $t=1 to 14
							  $GrafikTempEVdata[$t]=GUICtrlRead($GUI2Input[$t])
							  $EVdata[$LASTmodel][$t]=GUICtrlRead($GUI2Input[$t])
						   Next
						   _GDIPlus_PenDispose($hPen)
						   _GDIPlus_GraphicsDispose($hGraphic)
						   GrafikZeichnen()
						EndIf
						#ce
					 WEnd

					 ;MsgBox(0,"Flags", "$GUI2ChangeFlag : " & $GUI2ChangeFlag & @CRLF & "$GUI2SaveFlag : " & $GUI2SaveFlag & @CRLF & "$GUI2flag:  " &  $GUI2flag)


                 If $GUI2flag=2 Then
                        For $t=1 to 14
                                $EVdata[$LASTmodel][$t]=GUICtrlRead($GUI2Input[$t])
                        Next
                        SaveEVdata()
                        IniWrite($DBFile, "CONFIG", "LASTmodel", $LASTmodel)
                 EndIf

          ; Clean up resources
          _GDIPlus_PenDispose($hPen)
          _GDIPlus_GraphicsDispose($hGraphic)
          _GDIPlus_Shutdown()
          GUIDelete($GUI2id)
          if $GUI2flag>0 Then
                GUIDelete($GUI1id)
                EVdataRead()																													; Datenbank einlesen
                $EVmodels=$EVdata[1][1] & " " & $EVdata[1][2]															; werte aus der Datenbank auf die Variablen
                For $t=2 to $EVcount																												; verteilen zur Darstellung im Fenster
                        $EVmodels=$EVmodels & "|" & $EVdata[$t][1] & " " & $EVdata[$t][2]					;
                Next
                $GUI2flag=0
                GUI()
          EndIf

		  ChangeEV()
          BufferRead()
          Calc()

   EndFunc
        #EndRegion



		#Region GrafikZeichen
		Func GrafikZeichnen()
			$hGUI=$GUI2id
			#Region Scala anlegen
			$ScalaX=500
                 $ScalaY=300
                 $ScalaStartX=380
                 $ScalaStartY=50+$ScalaY
                GUICtrlCreatePic(@ScriptDir & "\scala500.bmp", $ScalaStartX, $ScalaStartY-$ScalaY, $ScalaX,$ScalaY, $SS_BITMAP)
                $ScalaCount = 80
                For $x = $ScalaStartX+40 to $ScalaStartX+440 Step 50
                   GUICtrlCreateLabel($Scalacount, $x, $ScalaStartY+10, 50, 20)
                   $ScalaCount +=10
                Next
                $ScalaCount = 10
                For $y = $ScalaStartY-55 to $ScalaStartY-255 Step -50
                   GUICtrlCreateLabel($Scalacount, 350, $y, 30, 20)
                   $ScalaCount +=10
                Next
				GUICtrlCreateLabel("Km/h", $ScalaStartX+$ScalaX-25, $ScalaStartY+10, 30, 20)
				GUICtrlCreateLabel("Kwh", $ScalaStartX-30, $ScalaStartY-$ScalaY, 30, 20)
				#EndRegion

				  $x=1
				 $Lastx=1
				 $Lasty=1
				 ;GUICtrlCreateButton("O", $ScalaStartX, $ScalaStartY,10, 10)
				 #Region Scalen Werte anlegen und verbinden

                 For $t=1 to 8
                        $Wert=$GrafikTempEVdata[$t+2]   ; $EVdata[$LASTmodel][$t+2]
						; Draw line
						_GDIPlus_Startup()
						$hGraphic = _GDIPlus_GraphicsCreateFromHWND($hGUI)
						$hPen = _GDIPlus_PenCreate()
						_GDIPlus_PenSetColor($hPen, 0xFFFF0000)

						;_GDIPlus_GraphicsDrawLine ( $hGraphic, $ScalaStartX, $ScalaStartY, $ScalaStartX+$ScalaX, $ScalaStartY+$ScalaY , $hPen)
						; $x=$ScalaStartX+($t*50)
						$x=$ScalaStartX + ($t*50)
						$y=$ScalaStartY-($wert * 5)
						If $Lastx=1 Then
						   GUICtrlDelete( $GUI2ScalaButton[$t])
						   $GUI2ScalaButton[$t]=GUICtrlCreateButton("", $x, $y,10, 10)
						   $Lastx=$x
						   $Lasty=$y
						Else
						   $GUI2ScalaButton[$t]=GUICtrlCreateButton("", $x, $y,10, 10)
						   _GDIPlus_GraphicsDrawLine ( $hGraphic, $x, $y, $Lastx, $Lasty, $hPen)
						   $Lastx=$x
						   $Lasty=$y
						EndIf
                 Next
				  #EndRegion
		EndFunc
		 #EndRegion

        #Region TimeConvert   Min > hh:mm
        Func TimeConv($TC_source)
                _TicksToTime ( $TC_source * 60 * 1000, $iHours, $iMins, $iSecs )
                ;If $iHours="0" Then $iHours="00"
                ;If $iMins="0" Then $iMins="00"
                If $iMins<10 Then $iMins="0" & $iMins
                If $iSecs="0" Then $iSecs="00"
                $TC_converted = $iHours & ":" & $iMins   ; & ":" & $iSecs
                Return $TC_converted
        EndFunc
        #EndRegion

        #Region create GUI
        Func GUI()

                $hPOS=290																						; vertikale Pos. der Wertetabelle
                $vPOS=180																						; horizontale Pos. der Wertetabelle

                Global $GUI1id			= GUICreate($ProgramTitle		, $GUI1x	, $GUI1y)					;
                GUISetFont($fontsize, 0, 0, $FontCurrent)																			;
                ;GUISetFont ( size [, weight [, attribute [, fontname [, winhandle [, quality]]]]] )




                GUICtrlCreateLabel("Fahrzeug Modell :"															,  50			,  27	, 150, 18)
                Global $GUI1EVmodel	= GUICtrlCreateCombo(""											,230			,  25	, 300, 20)
                $LASTmodel=INIread($DBFile, "CONFIG", "LASTmodel", 1)
                GUICtrlSetData(-1, $EVmodels, $EVdata[$LASTmodel][1] & " " & $EVdata[$LASTmodel][2] )

                $GUI1ButtonEditmodel=GUICtrlCreateButton(" bearbeiten "							,540			, 25	, 80, 24)
                GUICtrlSetTip(-1, "Fahrzeugdaten bearbeiten oder ein neues Fahrzeug anlegen")
                GUICtrlSetFont(-1, $Fontsize)


                GUICtrlCreateLabel("Schnell-Lade-Leistung :"													,  50			,  55	, 150, 18)
                Global $GUI1Ladeleistung		= GUICtrlCreateInput(""									,230			,  55	,  70, 20)
                GUICtrlSetState(-1, $GUI_DISable)
                GUICtrlSetFont(-1, $Fontsize)
                GUICtrlSetTip(-1, "max. mögliche Ladeleistung an einer Schnelladesäule")
                GUICtrlCreateLabel("kW"																					,310			,  55			, 50, 18)

                $GUI1kapazitaetLabel =	GUICtrlCreateLabel("Kapazität SOC Differenz:"	,  50			,  82			,180, 18)
                Global $GUI1kapazitaet =	GUICtrlCreateInput(""											,230			,  80			,  70, 20)
                GUICtrlSetTip(-1, "nutzbare Kapazität zwischen unterem und oberen SOC")
                GUICtrlSetState(-1, $GUI_DISable)
                GUICtrlCreateLabel("kWh"																					,310			,  80			, 50, 18)

                $GUI1LadedauerLabel =	GUICtrlCreateLabel("Ladezeit :"								,  50			, 107		,180, 18)
                Global $GUI1Ladedauer	= GUICtrlCreateInput(""											,230			, 105		,  70, 20)
                GUICtrlSetState(-1, $GUI_DISable)
                GUICtrlCreateLabel("hh:mm"																				,310			, 105		, 50, 18)

                GUICtrlCreateLabel("Reisestrecke :"																	,  50			, 132		,150, 18)
                $Strecke=IniRead($DBFile, "CONFIG", "LASTkm", "600")
                Global $GUI1Strecke		= GUICtrlCreateInput($Strecke								,230			, 130		,  70, 20)
                GUICtrlSetTip(-1, "zurückzulegende Reisestrecke")
                GUICtrlCreateLabel("Km"																					,310			, 132		,150, 18)

                GUICtrlCreateLabel("Geschwindigkeit (Km/h) :"												,  50			, $vPOS		, $hPOS-20, 18)
                GUICtrlCreateLabel("Verbrauch je 100 Km (kWh) :"										,  50			, $vPOS+30	, $hPOS-20, 18)
                GUICtrlCreateLabel("Reichweite je Ladung (Km) :"									,  50			, $vPOS+60	, $hPOS-20, 18)

                GUICtrlCreateLabel("Anzahl Ladevorgänge :"													,  50			, $vPOS+90	, 200, 18)
                GUICtrlSetTip(-1, "je Ladevorgang wird eine Anfahrtpauschale von " & $AnfahrtLadepunkt & " Minuten berechnet")

                GUICtrlCreateLabel("Fahrzeit (hh:mm) :"															,  50			, $vPOS+120	, 150, 18)
                GUICtrlCreateLabel("Ladezeit (hh:mm) :"															,  50			, $vPOS+150	, 150, 18)
                GUICtrlSetTip(-1, "= Dauer eines Ladevorganges + einer Pauschale von " & $AnfahrtLadepunkt & " Min. für die Anfahrt zum Ladepunkt multipliziert mit der Anzahl der Ladevorgänge")

                GUICtrlCreateLabel("Gesamtreisezeit (hh:mm) :"												,  50		, $vPOS+210	, 170, 18)
                GUICtrlSetTip(-1, "= Fahrzeit + Ladezeit + Anfahrt zum Ladepunkt")
                GUICtrlSetFont(-1, $Fontsize+1, $FW_BOLD)


                GUICtrlCreateLabel("80"															, $hPOS		, $vPOS	, 150, 18)
                GUICtrlCreateLabel("90"															, $hPOS+60	, $vPOS	, 150, 18)
                GUICtrlCreateLabel("100"														, $hPOS+120	, $vPOS	, 150, 18)
                GUICtrlCreateLabel("110"														, $hPOS+180	, $vPOS	, 150, 18)
                GUICtrlCreateLabel("120"														, $hPOS+240	, $vPOS	, 150, 18)
                GUICtrlCreateLabel("130"														, $hPOS+300	, $vPOS	, 150, 18)
                GUICtrlCreateLabel("140"														, $hPOS+360	, $vPOS	, 150, 18)
                GUICtrlCreateLabel("150"														, $hPOS+420	, $vPOS	, 150, 18)

                $GUI1LabelVerbrauch80=GUICtrlCreateLabel(""					,  $hPOS	, $vPOS+30	, 150, 18)
                $GUI1LabelVerbrauch90=GUICtrlCreateLabel(""					,  $hPOS+60	, $vPOS+30	, 150, 18)
                $GUI1LabelVerbrauch100=GUICtrlCreateLabel(""				,  $hPOS+120, $vPOS+30	, 150, 18)
                $GUI1LabelVerbrauch110=GUICtrlCreateLabel(""				,  $hPOS+180, $vPOS+30	, 150, 18)
                $GUI1LabelVerbrauch120=GUICtrlCreateLabel(""				,  $hPOS+240, $vPOS+30	, 150, 18)
                $GUI1LabelVerbrauch130=GUICtrlCreateLabel(""				,  $hPOS+300, $vPOS+30	, 150, 18)
                $GUI1LabelVerbrauch140=GUICtrlCreateLabel(""				,  $hPOS+360, $vPOS+30	, 150, 18)
                $GUI1LabelVerbrauch150=GUICtrlCreateLabel(""				,  $hPOS+420, $vPOS+30	, 150, 18)

                $GUI1LabelReichweite80=GUICtrlCreateLabel(""				,  $hPOS	, $vPOS+60	, 150, 18)
                $GUI1LabelReichweite90=GUICtrlCreateLabel(""				,  $hPOS+60	, $vPOS+60	, 150, 18)
                $GUI1LabelReichweite100=GUICtrlCreateLabel(""				,  $hPOS+120, $vPOS+60	, 150, 18)
                $GUI1LabelReichweite110=GUICtrlCreateLabel(""				,  $hPOS+180, $vPOS+60	, 150, 18)
                $GUI1LabelReichweite120=GUICtrlCreateLabel(""				,  $hPOS+240, $vPOS+60	, 150, 18)
                $GUI1LabelReichweite130=GUICtrlCreateLabel(""				,  $hPOS+300, $vPOS+60	, 150, 18)
                $GUI1LabelReichweite140=GUICtrlCreateLabel(""				,  $hPOS+360, $vPOS+60	, 150, 18)
                $GUI1LabelReichweite150=GUICtrlCreateLabel(""				,  $hPOS+420, $vPOS+60	, 150, 18)

                $GUI1LabelLadenAnzahl80=GUICtrlCreateLabel(""			,  $hPOS	, $vPOS+90	, 150, 18)
                $GUI1LabelLadenAnzahl90=GUICtrlCreateLabel(""			,  $hPOS+60	, $vPOS+90	, 150, 18)
                $GUI1LabelLadenAnzahl100=GUICtrlCreateLabel(""			,  $hPOS+120, $vPOS+90	, 150, 18)
                $GUI1LabelLadenAnzahl110=GUICtrlCreateLabel(""			,  $hPOS+180, $vPOS+90	, 150, 18)
                $GUI1LabelLadenAnzahl120=GUICtrlCreateLabel(""			,  $hPOS+240, $vPOS+90	, 150, 18)
                $GUI1LabelLadenAnzahl130=GUICtrlCreateLabel(""			,  $hPOS+300, $vPOS+90	, 150, 18)
                $GUI1LabelLadenAnzahl140=GUICtrlCreateLabel(""			,  $hPOS+360, $vPOS+90	, 150, 18)
                $GUI1LabelLadenAnzahl150=GUICtrlCreateLabel(""			,  $hPOS+420, $vPOS+90	, 150, 18)

                $GUI1LabelFahrzeit80=GUICtrlCreateLabel(""						,  $hPOS	, $vPOS+120	, 150, 18)
                $GUI1LabelFahrzeit90=GUICtrlCreateLabel(""						,  $hPOS+60	, $vPOS+120	, 150, 18)
                $GUI1LabelFahrzeit100=GUICtrlCreateLabel(""					,  $hPOS+120, $vPOS+120	, 150, 18)
                $GUI1LabelFahrzeit110=GUICtrlCreateLabel(""					,  $hPOS+180, $vPOS+120	, 150, 18)
                $GUI1LabelFahrzeit120=GUICtrlCreateLabel(""					,  $hPOS+240, $vPOS+120	, 150, 18)
                $GUI1LabelFahrzeit130=GUICtrlCreateLabel(""					,  $hPOS+300, $vPOS+120	, 150, 18)
                $GUI1LabelFahrzeit140=GUICtrlCreateLabel(""					,  $hPOS+360, $vPOS+120	, 150, 18)
                $GUI1LabelFahrzeit150=GUICtrlCreateLabel(""					,  $hPOS+420, $vPOS+120	, 150, 18)

                $GUI1LabelLadezeit80=GUICtrlCreateLabel(""					,  $hPOS	, $vPOS+150	, 150, 18)
                $GUI1LabelLadezeit90=GUICtrlCreateLabel(""					,  $hPOS+60	, $vPOS+150	, 150, 18)
                $GUI1LabelLadezeit100=GUICtrlCreateLabel(""					,  $hPOS+120, $vPOS+150	, 150, 18)
                $GUI1LabelLadezeit110=GUICtrlCreateLabel(""					,  $hPOS+180, $vPOS+150	, 150, 18)
                $GUI1LabelLadezeit120=GUICtrlCreateLabel(""					,  $hPOS+240, $vPOS+150	, 150, 18)
                $GUI1LabelLadezeit130=GUICtrlCreateLabel(""					,  $hPOS+300, $vPOS+150	, 150, 18)
                $GUI1LabelLadezeit140=GUICtrlCreateLabel(""					,  $hPOS+360, $vPOS+150	, 150, 18)
                $GUI1LabelLadezeit150=GUICtrlCreateLabel(""					,  $hPOS+420, $vPOS+150	, 150, 18)

                $GUI1LabelReisezeit80=GUICtrlCreateLabel(""					,  $hPOS	, $vPOS+210	, 150, 20)
                GUICtrlSetFont(-1, $Fontsize+1, $FW_BOLD)
                $GUI1LabelReisezeit90=GUICtrlCreateLabel(""					,  $hPOS+60	, $vPOS+210	, 150, 20)
                GUICtrlSetFont(-1, $Fontsize+1, $FW_BOLD)
                $GUI1LabelReisezeit100=GUICtrlCreateLabel(""					,  $hPOS+120, $vPOS+210	, 150, 20)
                GUICtrlSetFont(-1, $Fontsize+1, $FW_BOLD)
                $GUI1LabelReisezeit110=GUICtrlCreateLabel(""					,  $hPOS+180, $vPOS+210	, 150, 20)
                GUICtrlSetFont(-1, $Fontsize+1, $FW_BOLD)
                $GUI1LabelReisezeit120=GUICtrlCreateLabel(""					,  $hPOS+240, $vPOS+210	, 150, 20)
                GUICtrlSetFont(-1, $Fontsize+1, $FW_BOLD)
                $GUI1LabelReisezeit130=GUICtrlCreateLabel(""					,  $hPOS+300, $vPOS+210	, 150, 20)
                GUICtrlSetFont(-1, $Fontsize+1, $FW_BOLD)
                $GUI1LabelReisezeit140=GUICtrlCreateLabel(""					,  $hPOS+360, $vPOS+210	, 150, 20)
                GUICtrlSetFont(-1, $Fontsize+1, $FW_BOLD)
                $GUI1LabelReisezeit150=GUICtrlCreateLabel(""					,  $hPOS+420, $vPOS+210	, 150, 20)
                GUICtrlSetFont(-1, $Fontsize+1, $FW_BOLD)

                $GUI1Version=GUICtrlCreateLabel("Version " & $version					, 20		, $GUI1y-30, 200, 24)
                GUICtrlSetTip(-1, "Hier klicken um Programmhistorie anzuzeigen")
                If $Debug=1 Then
                        GUICtrlCreateLabel("Font (current:" & $FontCurrent & ")"			, $GUI1x-450, $GUI1y-60, 200, 20)
                        $GUI1FontList=GUICtrlCreateCombo(""										, $GUI1x-450, $GUI1y-40, 200, 24)
                        $GUI1ChangeFontButton=GUICtrlCreateButton(" set "				, $GUI1x-240, $GUI1y-40, 50, 24)
                        GUICtrlSetTip(-1, "Schriftart übernehmen")
                        GUICtrlSetState($GUI1ChangeFontButton, $GUI_DISable)
                EndIf
                $GUI1ButtonExit=GUICtrlCreateButton(" Ende "									, $GUI1x-120, $GUI1y-40, 100, 24)
                GUICtrlSetTip(-1, $ProgramTitle & " beenden")

                $FontTemp=$FontArray[1]
                For $t=2 to $FontCount-1
                        ;$FontArray[$FontCount]=$var
                        $FontTemp=$FontTemp & "|" & $FontArray[$t]
                        ;
                Next
                $FontTemp=$FontTemp & "|" &  $FontArray[$FontCount]

                GUICtrlSetData($GUI1FontList, $FontTemp ,  $FontCurrent)
                GUISetState()

        EndFunc
        #EndRegion

        #Region Fontdetect
        Func FontEval()
                $FontTemp=""
                $FontCount=0

                While @error=0
                        $FontCount=$FontCount+1
                        $var = RegEnumVal("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts", $FontCount)
                        $temp = StringInStr($var, "(")
                        If $temp Then
                                $var = StringLeft($var, $temp-2)
                        EndIf
                        If StringInStr($var, "Es sind ") or $FontCount>99 Then ExitLoop
                        $FontArray[$FontCount]=$var
                WEnd
                $Fontcount=$Fontcount-1
        EndFunc
        #EndRegion





