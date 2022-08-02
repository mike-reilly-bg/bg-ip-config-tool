#include-once
;==============================================================================
; Filename:		asyncRun.au3
; Description:	Run command 'asynchronously', then execute a callback function.
;               Chain commands to run after the previous command finishes.
; Author:       Kurtis Liggett
;==============================================================================

Global $iPID = -1, $pRuntime
Global $pRunning, $pDone, $sStdOut, $sStdErr, $pIdle = 1
Global $pQueue[1][2] = [[0, 0]]

#include <Array.au3>

Global $__asyncProcess__Data[1][5]
$__asyncProcess__Data[0][0] = -1
$__asyncProcess__Data[0][2] = 1
;[0][0] = PID
;[0][1] = PID runtime
;[0][2] = idle status
;[0][3] = timeout countdown
;
;[1][0] = command 1 command
;[1][1] = command 1 callback function
;[1][2] = command 1 description
;[1][3] = command 1 timeout
;[1][4] = status msg display bool
; ...
;[n][0] = command n command
;[n][1] = command n callback function
;[n][2] = command n description
;[n][3] = command n timeout
;[n][4] = status msg display bool

Func asyncRun($sCmd, $CallbackFunc, $sDescription = "", $iTimeout = 4000, $dontCallbackTwice=False, $StatusMsg = True)
	; check if process is already in stack
	if $sDescription <> "" and ubound( $__asyncProcess__Data) > 1 Then
		for $i = 1 to ubound($__asyncProcess__Data,1)-1
			if $__asyncProcess__Data[$i][2] = $sDescription Then
				Return
			endif
		next
	Endif
	_ArrayAdd($__asyncProcess__Data, $sCmd, Default, "!")

	;~ d("size of array at add: " & UBound($__asyncProcess__Data) & @crlf & @crlf & $sCmd)

	
	Local $size = UBound($__asyncProcess__Data)
	$__asyncProcess__Data[$size - 1][1] = $CallbackFunc
	$__asyncProcess__Data[$size - 1][2] = $sDescription
	$__asyncProcess__Data[$size - 1][3] = $iTimeout
	if $StatusMsg Then
		$__asyncProcess__Data[$size - 1][4] = True
	Else
		$__asyncProcess__Data[$size - 1][4] = False
	Endif
	$__asyncProcess__Data[0][2] = 0
	If $size = 2 Then
		;~ If not $dontCallbackTwice Then
			;$sStdOut = ""
			;_setStatus("")
			;$CallbackFunc($sDescription, $sDescription, "")
		;~ Endif
	EndIf
	AdlibRegister("_asyncRun_Process", 100)
	;~ d("queue size: " & ubound($__asyncProcess__Data,1)-1& @crlf & @crlf & $scmd)
EndFunc   ;==>asyncRun

Func _asyncRun_Execute($sCmd)

EndFunc   ;==>_asyncRun_Execute

Func _asyncRun_Clear()
	For $i = 1 To UBound($__asyncProcess__Data) - 1
		_ArrayDelete($__asyncProcess__Data, 1)
	Next
EndFunc   ;==>_asyncRun_Clear

Func _asyncRun_Process()
	;~ $str = ""
	;~ for $i = 1 to ubound($__asyncProcess__Data)-1
	;~ 	$str = $str & @CRLF & @CRLF & "command " & $i & ": " & $__asyncProcess__Data[$i][0] & @CRLF & @crlf & "description " & $i & ": " & $__asyncProcess__Data[$i][2] & @CRLF & @crlf
	;~ next
	;~ $str = $str & $last_command
	;~ if ubound($__asyncProcess__Data) > 1 Then d($str)

	Local $endingString = "__asyncRun cmd done"
	Local $pExists = ProcessExists($__asyncProcess__Data[0][0])
	If $pExists Then    ;if process exists, check if finished
		Local $pDone
		$sStdOut = $sStdOut & StdoutRead($__asyncProcess__Data[0][0])
		;~ d("pexist: " &  $sStdOut)
		$sStdErr = $sStdOut & StderrRead($__asyncProcess__Data[0][0])
		If StringInStr($sStdOut, $endingString) Then    ;look for our unique phrase to signal we're done
			$sStdOut = StringLeft($sStdOut, StringInStr($sStdOut, $endingString) - 1)
			;~ d("clipped, done: " & $sStdOut)
			$pDone = 1
		ElseIf TimerDiff($__asyncProcess__Data[0][1]) > $__asyncProcess__Data[1][3] Then    ;if timeout expired
			$sStdOut = "Command timeout"
			$pDone = 1
		Else
			Local $countdown = 10 - Round(TimerDiff($pRuntime) / 1000)
			If $countdown <= 5 Then
				$__asyncProcess__Data[0][3] = $countdown
			EndIf
		EndIf

		If $pDone Then
			Local $desc = $__asyncProcess__Data[1][2]
			Local $nextdesc = ""
			If UBound($__asyncProcess__Data) = 2 Then ;this is the last command
				$__asyncProcess__Data[0][2] = 1
			Else
				$nextdesc = $__asyncProcess__Data[2][2]
			EndIf
			ProcessClose($__asyncProcess__Data[0][0])
			$__asyncProcess__Data[0][0] = -1
			AdlibUnRegister("_asyncRun_Process")
			;Call($__asyncProcess__Data[1][1], $__asyncProcess__Data[1][2], $sStdOut)	;callback function
			Local $myFunc = $__asyncProcess__Data[1][1]
			$myFunc($desc, $nextdesc, $sStdOut)    ;callback function
			$d = $__asyncProcess__Data[1][0]
			_ArrayDelete($__asyncProcess__Data, 1)
			;~ d("size of array at finish, after deleting: " & UBound($__asyncProcess__Data)-1 & @crlf & @crlf & $d & @crlf & @crlf & "stdout: " & $sStdOut & @crlf & @crlf & "stderr: " & $sStdErr)
			AdlibRegister("_asyncRun_Process", 100)
			$last_command = ""; $__asyncProcess__Data[1][0]
		EndIf
	ElseIf UBound($__asyncProcess__Data) > 1 Then    ;if process is finished, start next command
		; check if the process failed
		if $__asyncProcess__Data[1][0] = $last_command Then
			if $__asyncProcess__Data[1][4] Then _setstatus($oLangStrings.message.ready)
			AdlibUnRegister("_asyncRun_Process")
			Local $myFunc = $__asyncProcess__Data[1][1]
			$desc = $__asyncProcess__Data[1][2]
			$nextdesc = ""
			If UBound($__asyncProcess__Data) = 2 Then ;this is the last command
				$__asyncProcess__Data[0][2] = 1
			Else
				$nextdesc = $__asyncProcess__Data[2][2]
			EndIf
			$sStdOut = $sStdOut & StdoutRead($__asyncProcess__Data[0][0])
			$sStdOut = StringLeft($sStdOut, StringInStr($sStdOut, $endingString) - 1)
			;~ d("error section: " & $sStdOut)
			$sStdErr = $sStdErr &   StderrRead($__asyncProcess__Data[0][0])
			$myFunc($desc, $nextdesc, $sstdout)    ;callback function
			$d = $__asyncProcess__Data[1][0]
			;~ d("size of array at error, before deleting: " & UBound($__asyncProcess__Data) & @crlf & @crlf & $d)
			_ArrayDelete($__asyncProcess__Data, 1)
			;~ d("size of array at error, after deleting: " & UBound($__asyncProcess__Data)-1 & @crlf & @crlf & $d & @crlf & @crlf & "stdout: " & $sStdOut & @crlf & @crlf & "stderr: " & $sStdErr)
			AdlibRegister("_asyncRun_Process", 100)
			$__asyncProcess__Data[0][0] = -1
			$last_command = ""; $__asyncProcess__Data[1][0]
			return
		EndIf
		$d = $__asyncProcess__Data[1][0]
		;~ d("size of array at call: " & UBound($__asyncProcess__Data)-1 & @crlf & @crlf & $d)
		$sStdOut = ""
		$sStdErr = ""
		;Run command and end with a unique string so we know the command is finished
		$__asyncProcess__Data[0][0] = Run(@ComSpec & " /c " & $__asyncProcess__Data[1][0] & " & echo __asyncRun cmd done", "", @SW_HIDE, $STDIN_CHILD + $STDERR_MERGED)
		$last_command = $__asyncProcess__Data[1][0]
		if $__asyncProcess__Data[1][4] Then _setstatus($__asyncProcess__Data[1][2])
		;~ d("process: " & $__asyncProcess__Data[0][0])
		$__asyncProcess__Data[0][1] =  TimerInit()    ;start runtime timer
		$__asyncProcess__Data[0][2] = 0                ;set Idle status to 0
	Else    ;done processing, no commands left
		$__asyncProcess__Data[0][2] = 1            ;idle status to 1
		AdlibUnRegister("_asyncRun_Process")    ;only run when necessary
	EndIf
EndFunc   ;==>_asyncRun_Process

Func asyncRun_isIdle()
	Return $__asyncProcess__Data[0][2]
EndFunc   ;==>asyncRun_isIdle

Func asyncRun_getNextDescription()

EndFunc   ;==>asyncRun_getNextDescription

Func asyncRun_getCountdown()
	Return $__asyncProcess__Data[0][3]
EndFunc   ;==>asyncRun_getCountdown
