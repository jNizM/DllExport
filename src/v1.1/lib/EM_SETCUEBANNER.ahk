; ===============================================================================================================================
; Message ..................:  EM_SETCUEBANNER
; Minimum supported client .:  Windows Vista
; Minimum supported server .:  Windows Server 2003
; Links ....................:  https://docs.microsoft.com/en-us/windows/win32/controls/em-setcuebanner
; Description ..............:  Sets the textual cue, or tip, that is displayed by the edit control to prompt the user for information.
; Options ..................:  True  -> if the cue banner should show even when the edit control has focus
;                              False -> if the cue banner disappears when the user clicks in the control
; ===============================================================================================================================

EM_SETCUEBANNER(handle, string, option := true)
{
	static ECM_FIRST       := 0x1500 
	static EM_SETCUEBANNER := ECM_FIRST + 1
	if (DllCall("user32\SendMessage", "ptr", handle, "uint", EM_SETCUEBANNER, "int", option, "str", string, "int"))
		return true
	return false
}

; ===============================================================================================================================