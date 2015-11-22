;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;X360Desktop
;Author: Ben Baginski
;Enable the Xbox 360 controller to handle desktop behavior.
;Thank you Scoov for https://autohotkey.com/board/topic/99405-hoverscroll-verticalhorizontal-scroll-without-focus-scrollwheel-acceleration/page-2
;Thank you AutoHotKey for https://www.autohotkey.com/docs/scripts/JoystickMouse.htm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#Include %A_ScriptDir%
#Include HoverScroll.ahk
#MaxHotkeysPerInterval 500
#SingleInstance

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;						ConfigurationSettings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Increase the following value to make the mouse cursor move faster; larger = faster:
; JoyMultiplier adjusts the left stick speed
; JoyMultiplier adjusts the right stick speed
JoyMultiplier = 0.5
Joy2Multiplier = 0.2

;Miscellaneous
JoyThreshold = 9 		;Joystick Deadspace, 0-10, may need adjusting
Joy2Threshold = 9		;Joystick2 Deadspace, 0-10, may need adjusting
TriggerThreshold = 5	;Trigger Deadspace, 0-10 may need adjusting
AltTabDelay = 7 		;Determines how long the alt-tab dialog stays open
InvertYAxis := false	;Inverted Y Axis Flag

;Button Assignments
;Xbox 360
;A=1, B=2, X=3, Y=4, Left Bumper = 5, Right Bumper = 6, Back = 7, Start = 8, Left Stick Click = 9, Right Stick CLick = 10
ButtonLeft = 1			
ButtonRight = 3			
ButtonMiddle = 2		
ButtonBack = 5			
ButtonForward = 6		
ButtonStart = 8
ButtonShift = 10
ButtonCtrl = 9

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Xbox360DesktopController
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Hotkeys
JoystickPrefix = %JoystickNumber%Joy
Hotkey, %JoystickPrefix%%ButtonLeft%, ButtonLeft
Hotkey, %JoystickPrefix%%ButtonRight%, ButtonRight
Hotkey, %JoystickPrefix%%ButtonMiddle%, ButtonMiddle
Hotkey, %JoystickPrefix%%ButtonBack%, ButtonBack
Hotkey, %JoystickPrefix%%ButtonForward%, ButtonForward
Hotkey, %JoystickPrefix%%ButtonStart%, ButtonStart
Hotkey, %JoystickPrefix%%ButtonShift%, ButtonShift
Hotkey, %JoystickPrefix%%ButtonCtrl%, ButtonCtrl

; Calculate the axis displacements that are needed to start moving the cursor:
JoyThresholdUpper := 50 + JoyThreshold
JoyThresholdLower := 50 - JoyThreshold
AltTabTimer = -1
if InvertYAxis
	YAxisMultiplier = -1
else 
	YAxisMultiplier = 1

;Initiate Timers for axis watch functions
SetTimer, WatchJoystick, 10 
SetTimer, WatchJoy2stick, 10
SetTimer, WatchScroll, 10
SetTimer, WatchAltTab, 100

; The subroutines below do not use KeyWait because that would sometimes trap the
; WatchJoystick quasi-thread beneath the wait-for-button-up thread, which would
; effectively prevent mouse-dragging with the joystick.
ButtonLeft:
SetMouseDelay, -1  ; Makes movement smoother.
MouseClick, left,,, 1, 0, D  ; Hold down the left mouse button.
SetTimer, WaitForLeftButtonUp, 10
return

ButtonRight:
SetMouseDelay, -1  ; Makes movement smoother.
MouseClick, right,,, 1, 0, D  ; Hold down the right mouse button.
SetTimer, WaitForRightButtonUp, 10
return

ButtonMiddle:
SetMouseDelay, -1  ; Makes movement smoother.
MouseClick, middle,,, 1, 0, D  ; Hold down the right mouse button.
SetTimer, WaitForMiddleButtonUp, 10
return

ButtonShift:
SetMouseDelay, -1  ; Makes movement smoother.
Send {Shift Down}  ; Hold down the right mouse button.
SetTimer, WaitForShiftButtonUp, 10
return

ButtonCtrl:
SetMouseDelay, -1  ; Makes movement smoother.
Send {Ctrl Down} ; Hold down the right mouse button.
SetTimer, WaitForCtrlButtonUp, 10
return

WaitForLeftButtonUp:
if GetKeyState(JoystickPrefix . ButtonLeft)
	return  ; The button is still, down, so keep waiting. Otherwise, the button has been released.
SetTimer, WaitForLeftButtonUp, off
SetMouseDelay, -1  ; Makes movement smoother.
MouseClick, left,,, 1, 0, U  ; Release the mouse button.
return

WaitForRightButtonUp:
if GetKeyState(JoystickPrefix . ButtonRight)
	return  ; The button is still, down, so keep waiting. Otherwise, the button has been released.
SetTimer, WaitForRightButtonUp, off
MouseClick, right,,, 1, 0, U  ; Release the mouse button.
return

WaitForMiddleButtonUp:
if GetKeyState(JoystickPrefix . ButtonMiddle)
	return  ; The button is still, down, so keep waiting. Otherwise, the button has been released.
SetTimer, WaitForMiddleButtonUp, off
MouseClick, middle,,, 1, 0, U  ; Release the mouse button.
return

WaitForShiftButtonUp:
if GetKeyState(JoystickPrefix . ButtonShift)
	return  ; The button is still, down, so keep waiting. Otherwise, the button has been released.
SetTimer, WaitForShiftButtonUp, off
Send {Shift Up} ; Release the mouse button.
return

WaitForCtrlButtonUp:
if GetKeyState(JoystickPrefix . ButtonCtrl)
	return  ; The button is still, down, so keep waiting. Otherwise, the button has been released.
SetTimer, WaitForCtrlButtonUp, off
Send {Ctrl Up} ; Release the mouse button.
return

;Simple button assignments
ButtonBack:
Send {Browser_Back}
return

ButtonForward:
Send {Browser_Forward}
Return

ButtonStart:
Send {LWin}
return

;Subroutie for left stick
WatchJoystick:
MouseNeedsToBeMoved := false  ; Set default.
SetFormat, float, 03
GetKeyState, joyx, %JoystickNumber%JoyX
GetKeyState, joyy, %JoystickNumber%JoyY
if joyx > %JoyThresholdUpper%
{
	MouseNeedsToBeMoved := true
	DeltaX := joyx - JoyThresholdUpper
}
else if joyx < %JoyThresholdLower%
{
	MouseNeedsToBeMoved := true
	DeltaX := joyx - JoyThresholdLower
}
else
	DeltaX = 0
if joyy > %JoyThresholdUpper%
{
	MouseNeedsToBeMoved := true
	DeltaY := joyy - JoyThresholdUpper
}
else if joyy < %JoyThresholdLower%
{
	MouseNeedsToBeMoved := true
	DeltaY := joyy - JoyThresholdLower
}
else
	DeltaY = 0
if MouseNeedsToBeMoved
{
	SetMouseDelay, -1  ; Makes movement smoother.
	MouseMove, DeltaX * JoyMultiplier, DeltaY * JoyMultiplier * YAxisMultiplier, 0, R
}
return

;Subroutine for right stick
WatchJoy2stick:
MouseNeedsToBeMoved := false  ; Set default.
SetFormat, float, 03
GetKeyState, joyr, %JoystickNumber%JoyU
GetKeyState, joyu, %JoystickNumber%JoyR
if joyr > %JoyThresholdUpper%
{
	MouseNeedsToBeMoved := true
	DeltaR := joyr - JoyThresholdUpper
}
else if joyr < %JoyThresholdLower%
{
	MouseNeedsToBeMoved := true
	DeltaR := joyr - JoyThresholdLower
}
else
	DeltaR = 0
if joyu > %JoyThresholdUpper%
{
	MouseNeedsToBeMoved := true
	DeltaU := joyu - JoyThresholdUpper
}
else if joyu < %JoyThresholdLower%
{
	MouseNeedsToBeMoved := true
	DeltaU := joyu - JoyThresholdLower
}
else
	DeltaU = 0
if MouseNeedsToBeMoved
{
	SetMouseDelay, -1  ; Makes movement smoother.
	MouseMove, DeltaR * Joy2Multiplier, DeltaU * Joy2Multiplier * YAxisMultiplier, 0, R
}
return

;Subroutine for Trigger Scrolling.
WatchScroll:
SetFormat, float, 03
GetKeyState, joyz, %JoystickNumber%joyz
if ABS(joyz-50) > TriggerThreshold
{
	scroll:=(joyz-50)/10
	HoverScroll(scroll)
}
return

;Subroutine for window switching.
WatchAltTab:
GetKeyState, JoyPOV, %JoystickNumber%JoyPOV
if 	JoyPOV = -1
{	
	if AltTabTimer = 0
	{
		Send {Alt Up}	
		AltTabTimer = -1
	}
	else if AltTabTimer > 0
	{
		AltTabTimer -= 1
	}
}
else if AltTabTimer = -1 
{
	Send {Alt Down}{Tab}
	AltTabTimer :=  AltTabDelay
}
else if JoyPOV = 9000 ;switch window right
{
	Send {Right}
	AltTabTimer := AltTabDelay
}
if JoyPOV = 27000 ;switch window left
{
	Send {Left}
	AltTabTimer := AltTabDelay
}
return



