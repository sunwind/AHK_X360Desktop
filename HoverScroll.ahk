;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; HoverScroll() v1.04
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;© 2014 Scoox
;Send scroll messages to any control without focus
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;** INCLUDE THIS FILE IN AUTUEXECUTE SECTION OF MAIN SCRIPT **

;Specify this in calling script
;#MaxHotkeysPerInterval 500 ;Avoid warning when mouse wheel turned very fast

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Constants
HoverScrollMinLines := 1 ;lines per notch
HoverScrollMaxLines := 5 ;lines per notch
HoverScrollThreshold := 70 ;Max Miliseconds between two consecutive notches (user defined)
HoverScrollCurve := 0 ;Acceleration curve: 0 = Straight line (default), 1 = Parabola

;Determine system frequency in Hz:
DllCall("QueryPerformanceFrequency", "Int64 *", Frequency)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Application exceptions

;NOTE: By default this script will use the target control HWND obtained via DLL call ast this method works in the most places. To use a different method, add to the corresponding group below.

;NOTE: The same window can be added to several different groups
;NOTE: RegEx is allowed in group definitions e.g. "ahk_class Note.?ad" etc
;NOTE: This script assumes that the same method will work with all controls of a given application. Should this limitation be a problem, flexible per-control support may be added in the future.

;Methods:
	;GroupAdd, HoverScroll_Hwnd
	;GroupAdd, HoverScroll_HwndClassNN
	;GroupAdd, HoverScroll_Window ;Post messages to whole window instead of control under mouse
	;GroupAdd, HoverScroll_HwndDll ;Default method (no need to explicitly add to this group)

GroupAdd, HoverScroll_Hwnd, Fireface Settings ahk_class #32770 ;RME Fireface settings

;Workarounds:
	;GroupAdd, HoverScroll_Loop ;Use this when unable to scroll more than one line per notch
	;GroupAdd, HoverScroll_FocusControl ;Use this for apps that refuse to scroll
	;GroupAdd, HoverScroll_HScrollAlternative ;Try this for apps that don't respond to standard HORIZONTAL scroll method

GroupAdd, HoverScroll_Loop, ahk_class TEventEditForm ;FL Studio arranger view
GroupAdd, HoverScroll_Loop, ahk_class TFruityLoopsMainForm ;FL Studio arranger view
GroupAdd, HoverScroll_Loop, ahk_class CCLWindowClass ;Studio One main window
GroupAdd, HoverScroll_Loop, ahk_class CCLShadowWindowClass ;Studio One mixer and plugins
GroupAdd, HoverScroll_Loop, Traktor ahk_class NINormalWindow00400000 ;NI Traktor faders, knobs, etc

GroupAdd, HoverScroll_FocusControl, ahk_class TFruityLoopsMainForm
GroupAdd, HoverScroll_FocusControl, ahk_class TProjectPropertiesForm

GroupAdd, HoverScroll_HScrollAlternative, ahk_class MSPaintApp
GroupAdd, HoverScroll_HScrollAlternative, ahk_class classFoxitReader
GroupAdd, HoverScroll_HScrollAlternative, ahk_classDSUI:PDFXCViewer
GroupAdd, HoverScroll_HScrollAlternative, Microsoft Visio ahk_class VISIOA

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;MS Office applications
Global HoverScroll_ControlExceptions_MSOffice
HoverScroll_ControlExceptions_MSOffice .= "EXCEL71" ;Excel
HoverScroll_ControlExceptions_MSOffice .= "|_WwG1" ;Word
HoverScroll_ControlExceptions_MSOffice .= "|paneClassDC1" ;PowerPoint
HoverScroll_ControlExceptions_MSOffice .= "|NetUIHWND1" ;Access
;HoverScroll_ControlExceptions_MSOffice .= ... add your own here e.g. Access etc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; HoverScroll()
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

/*
Lines:
Optional paramter, default value = 1.

Axis:
1 = Vertical scrolling (default if omitted)
0 (or any value other than 1) = Horizontal scrolling

Ctrl:
1 = Send Ctrl-Wheel
Else (default) = Normal scrolling

Shift:
1 - Send Shift-Wheel
Else (default) = Normal scrolling

Optional parameter, default value = 1.
The number of lines to scroll per scrollwheel notch. Negative values scroll downwards. If omitted this parameter a value of 1 will be used.

Return value:
None.
*/

HoverScroll(Lines=1, Axis=1, Ctrl=0, Shift=0)
{
	Critical
	SetTitleMatchMode RegEx
	CoordMode, Mouse, Screen ;All coords relative to screen
	SetBatchLines, -1 ;Run as fast as possible
	SetMouseDelay, -1
	SetControlDelay, 0

	MouseGetPos, m_x, m_y, WinID, ControlClassNN, 1
	MouseGetPos,,,, ControlHwnd, 2

	;ControlHwndDll := DllCall("WindowFromPoint", "int", m_x, "int", m_y) ;32-bit only (bad)
	ControlHwndDll := DllCall( "WindowFromPoint", "int64", (m_y << 32) | (m_x & 0xFFFFFFFF), "Ptr") ;both 64 and 32-bit (good)

	;Some applications require that the target control has input focus.
	;This won't necessarily activate the window containing the target control, e.g. FL Studio
	IfWinExist ahk_id %WinID% ahk_group HoverScroll_FocusControl
	{
		ControlFocus,, ahk_id %ControlHwnd%
		ControlFocus,, ahk_id %ControlHwndDll%
	}

	;Horizontal scrolling work-around using WM_HSCROLL = 0x114
	;This method gives you less control than using WM_MOUSEHWHEEL,
	;but may work in some apps where WM_MOUSEHWHEEL does not.
	If (Axis != 1) ;If horizontal scrolling
	{
		IfWinExist ahk_id %WinID% ahk_group HoverScroll_HScrollAlternative
		{
			Iterations := Abs(Lines)
			If (Lines < 0)
				Loop %Iterations%
					PostMessage, 0x114, 0, 0,, ahk_id %ControlHwnd%
			Else
				Loop %Iterations%
					PostMessage, 0x114, 1, 0,, ahk_id %ControlHwnd%
			Return
		}

		;Microsoft office applications using Office VBA's SmallScroll method
		If (ControlClassNN ~= HoverScroll_ControlExceptions_MSOffice)
		{
			Try ;Avoid weird error if MButton pressed accidentally
			{
				;Include Acc.ahk in calling script
				;See Post #6 by user "jethrow" on the following thread:
				;http://www.autohotkey.com/board/topic/35292-horizontal-scroll-in-excel-2007/

				;SmallScroll method information
				;http://msdn.microsoft.com/en-us/library/office/aa166801%28v=office.10%29.aspx
				;If Lines < 0
				;	Acc_ObjectFromWindow(ControlHwndDll, -16).SmallScroll(0,0,0,Abs(Lines))
				;Else
				;	Acc_ObjectFromWindow(ControlHwndDll, -16).SmallScroll(0,0,Abs(Lines),0)
			}
			Return
		}
	}

	;lParam := (m_y << 16) | m_x ;Does not work with -ve coords when using more than one display
	lParam := (m_y << 16) | (m_x & 0x0000FFFF) ;Works with -ve coords (recommended)

	wParam := (120 << 16) * (Lines < 0 ? -1 : 1)
	wParam |= Ctrl ? 8 : 0
	wParam |= Shift ? 4 : 0

	;All of the following available focusless scrolling methods were tested.
	;The one marked as "BEST" was found to work on the most number of control, and so was chosen as the default method.

	;SendMessage, %Axis%, wParam, lParam, %ControlClassNN%, ahk_id %WinID%
	;SendMessage, %Axis%, wParam, lParam,, ahk_id %ControlHwndDll%
	;SendMessage, %Axis%, wParam, lParam,, ahk_id %ControlHwnd%
	;PostMessage, %Axis%, wParam, lParam, %ControlClassNN%, ahk_id %WinID%
	;PostMessage, %Axis%, wParam, lParam,, ahk_id %ControlHwndDll% ;** BEST **
	;PostMessage, %Axis%, wParam, lParam,, ahk_id %ControlHwnd%
	
	;Looping to send repeated wheel events is slower but works everywhere.
	;(wParam * Lines) does not work in a few programs, in which case Loop should be used.
	Lines := Abs(Lines)
	Iterations := 1
	IfWinExist ahk_id %WinID% ahk_group HoverScroll_Loop
	{
		Iterations := Lines
		Lines := 1
	}

	;WM_MOUSEWHEEL = 0x20A
	;WM_MOUSEHWHEEL = 0x20E
	If (Axis = 1)
		Message := 0x20A ;vertical scroll
	Else	
		Message := 0x20E ;horizontal scroll


	IfWinExist ahk_id %WinID% ahk_group HoverScroll_ClassNN
		Loop %Iterations%
			PostMessage, %Message%, wParam * Lines, lParam, %ControlClassNN%, ahk_id %WinID%	
	Else IfWinExist ahk_id %WinID% ahk_group HoverScroll_Hwnd
		Loop %Iterations%
			PostMessage, %Message%, wParam * Lines, lParam,, ahk_id %ControlHwnd%
	Else IfWinExist ahk_id %WinID% ahk_group HoverScroll_Window
		Loop %Iterations%
			PostMessage, %Message%, wParam * Lines, lParam,, ahk_id %WinID%
	Else
		Loop %Iterations%
			PostMessage, %Message%, wParam * Lines, lParam,, ahk_id %ControlHwndDll%
}

