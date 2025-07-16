; script by Aynekko
; credits:
; https://github.com/gmh4589/Cube-map-creator
; https://autoit-script.ru/threads/avtomatizacija-vypolnenie-parametrov-vstroennoj-programmy-ne-rabotaet.20920/

#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>
#include <Constants.au3>
#Include <File.au3>

; currently processes only 100 cubemaps, hope that's enough
Global $MAX_CUBEMAPS = 100
Global $WINDOW_NAME = "Xash3D DDS cubemap creator"

Global $cubemap = 0
Global $sNvdxt = @ScriptDir & '\nvdxt.exe'
Global $delete_nvdxt = 1 ; delete the extracted file unless it wasn't already there!

; ----------------- THE SCRIPT -----------------
GUICreate ( $WINDOW_NAME,500,100)
GUISetState (@SW_SHOW)
; generic text
$maintext = GUICtrlCreateLabel("Working...", 10, 10, 480, 60, $SS_CENTER)
GUICtrlSetFont($maintext, 25)
; text which will show progress
$updtexta = GUICtrlCreateLabel("", 10, 50, 480, 20, $SS_CENTER )
GUICtrlSetFont($updtexta, 12)
$updtextb = GUICtrlCreateLabel("", 10, 70, 480, 20, $SS_CENTER )
GUICtrlSetFont($updtextb, 10)
; cancel functions
Opt("GUIOnEventMode", 1)
HotKeySet("{ESC}", "ExitProgram")
GUISetOnEvent($GUI_EVENT_CLOSE, "ExitProgram")

; check if first cubemap exists
If Not FileExists (@ScriptDir & "\cube#0px.tga") Then
	IntroFunc()
	Sleep(10000)
Else ; NO CUBEMAPS
	; install the converter
	if Not FileExists(@ScriptDir & "\nvdxt.exe") Then
		If Not FileInstall('nvdxt.exe', $sNvdxt, 1) Then
			Exit MsgBox(16, $WINDOW_NAME, 'Error: Can''t extract [nvdxt.exe]')
		EndIf
	Else
		; nvdxt already existed - do not delete it after!
		$delete_nvdxt = 0
	EndIf

	; convert all tga files
	TGAtoDDS()

	; wait a little bit!
	Sleep(2000)
	; delete extracted converter
	if FileExists(@ScriptDir & "\nvdxt.exe") And $delete_nvdxt = 1 Then
		FileDelete(@ScriptDir & "\nvdxt.exe")
	EndIf

	; at least one cubemap should exist
	If FileExists (@ScriptDir & "\cube#0px.dds") and FileExists (@ScriptDir & "\cube#0nx.dds") and FileExists (@ScriptDir & "\cube#0py.dds") and FileExists (@ScriptDir & "\cube#0ny.dds") and FileExists (@ScriptDir & "\cube#0pz.dds") and FileExists (@ScriptDir & "\cube#0nz.dds") then
		MakeDDSCubemaps()
	Else
		IntroFunc()
	EndIf
EndIf ; / NO CUBEMAPS

; ----------------- FUNCTIONS -----------------
Func TGAtoDDS()
	$files_done = 0
	$currentfile = 0
	GUICtrlSetData( $updtexta, "TGA -> DDS:" )
	
	$default_cmap = 1
	If Not FileExists (@ScriptDir & "\defaultpx.tga") Then
		$default_cmap = 0
	EndIf
	
	While $files_done <= $MAX_CUBEMAPS
		$cnt = 0
		$cmap_name = "cube#" & $files_done
		; convert default cubemap first
		If $default_cmap = 1 Then
			$cmap_name = "default"
		EndIf
		While $cnt < 6
			If $cnt=0 Then
				$currentfile = $cmap_name & "px"
			ElseIf $cnt=1 Then
				$currentfile = $cmap_name & "nx"
			ElseIf $cnt=2 Then
				$currentfile = $cmap_name & "py"
			ElseIf $cnt=3 Then
				$currentfile = $cmap_name & "ny"
			ElseIf $cnt=4 Then
				$currentfile = $cmap_name & "pz"
			ElseIf $cnt=5 Then
				$currentfile = $cmap_name & "nz"
			EndIf
			$cnt = $cnt+1
			
			$commandline = "nvdxt.exe -file " & $currentfile & ".tga -dxt1a -Sinc -quality_highest -outsamedir -output " & $currentfile & ".dds"
			If FileExists (@ScriptDir & "\" & $currentfile & ".tga" ) Then
				; do convert
				GUICtrlSetData( $updtextb, $currentfile )
				RunWait($commandline, @ScriptDir, @SW_HIDE)
			Else
				; stop converting
				$files_done = -1
				ExitLoop
			EndIf
		WEnd
		
		If $files_done = -1 Then
			ExitLoop
		EndIf
		
		If $default_cmap = 0 Then
			$files_done += 1
		Else
			$default_cmap = 0
		EndIf
	WEnd
EndFunc

Func MakeDDSCubemaps()
	Local $filepath[6] = [0]
	
	$add_default_to_total = 0
	$default_cmap = 1
	If Not FileExists (@ScriptDir & "\defaultpx.dds") Then
		$default_cmap = 0
	EndIf
	
	While $cubemap <= $MAX_CUBEMAPS
		$cmap_name = "cube#" & $cubemap
		; convert default cubemap first
		If $default_cmap = 1 Then
			$cmap_name = "default"
		EndIf
		
		If $default_cmap = 0 Then
			$hFile = FileOpen(@ScriptDir & "\cube#" & $cubemap & "px.dds", 16)
			$hOutFile = FileOpen(@ScriptDir & "\cube#" & $cubemap & ".dds", 26)
		Else
			$hFile = FileOpen(@ScriptDir & "\default" & "px.dds", 16)
			$hOutFile = FileOpen(@ScriptDir & "\default.dds", 26)
		EndIf
		$hText = FileRead($hFile, 112)
		FileWrite($hOutFile, $hText)
		FileWrite($hOutFile, "0x00FE0000000000000000000000000000")
		FileClose($hFile)
		
		$a = 0
		While $a < 6
			If $a=0 Then
				$filepath[$a] = @ScriptDir & "\" & $cmap_name & "px" & ".dds"
			ElseIf $a=1 Then
				$filepath[$a] = @ScriptDir & "\" & $cmap_name & "nx" & ".dds"
			ElseIf $a=2 Then
				$filepath[$a] = @ScriptDir & "\" & $cmap_name & "py" & ".dds"
			ElseIf $a=3 Then
				$filepath[$a] = @ScriptDir & "\" & $cmap_name & "ny" & ".dds"
			ElseIf $a=4 Then
				$filepath[$a] = @ScriptDir & "\" & $cmap_name & "pz" & ".dds"
			ElseIf $a=5 Then
				$filepath[$a] = @ScriptDir & "\" & $cmap_name & "nz" & ".dds"
			EndIf
			
			$hFile = FileOpen($filepath[$a], 16)
			FileSetPos ($hFile, 128, 0)
			$sSourceCode = FileRead($hFile)
			FileWrite($hOutFile, $sSourceCode)
			FileClose($hFile)
			$a = $a+1
		WEnd
		FileClose($hOutFile)
		
		GUICtrlSetData( $updtexta, "Saving single DDS cubemap:" )
		GUICtrlSetData( $updtextb, $cmap_name & ".dds" )
		Sleep( 750 )
		
		$b = 0
		While $b < 6
			if FileExists($filepath[$b]) Then
				FileDelete($filepath[$b])
			EndIf
			$b += 1
		WEnd
		
		; check for next cubemap
		If $default_cmap = 0 Then
			$cubemap += 1
			If Not FileExists (@ScriptDir & "\cube#" & $cubemap & "px.dds") Then
				If $add_default_to_total = 1 Then
					$cubemap += 1
				EndIf
				ConvertEnd()
				ExitLoop
			EndIf
		Else
			$default_cmap = 0
			$add_default_to_total = 1
		EndIf
	WEnd
EndFunc


Func IntroFunc()
	GUICtrlDelete( $maintext )
	GUICtrlDelete( $updtexta )
	GUICtrlDelete( $updtextb )
	$introtext = GUICtrlCreateLabel("", 20, 10, 480, 50, $SS_LEFT)
	GUICtrlSetFont($introtext, 10)
	GUICtrlSetData( $introtext,  "How to use:" & @CRLF & "1. Put this EXE in the folder with Xash3D cubemaps (cube#0px,py,pz... TGA files)" & @CRLF & "2. Run the program and wait" )
	$github = GUICtrlCreateButton( "GitHub", 20, 65, 50, 25 )
	GUICtrlSetFont($github, 10)
	
	; run until closed
	Opt("GUIOnEventMode", 0)
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitProgram()
			Case $github
				ShellExecute("https://github.com/Aynekko/Xash3D-DDS-cubemap-converter")
		EndSwitch
	WEnd
EndFunc

Func ConvertEnd()
	GUICtrlSetData( $updtexta, "" )
	GUICtrlSetData( $updtextb, "" )
	GUICtrlSetData( $maintext, "Converted " & $cubemap & " cubemaps." )
	Sleep( 1000 )
	GUICtrlSetData( $updtexta, "Closing in 3..." )
	Sleep( 1000 )
	GUICtrlSetData( $updtexta, "Closing in 2..." )
	Sleep( 1000 )
	GUICtrlSetData( $updtexta, "Closing in 1..." )
	Sleep( 1000 )
	Exit( 0 )
EndFunc

Func ExitProgram()
    Exit( 0 )
EndFunc