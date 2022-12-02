; ===============================================================================================================================
; Message ..................:  WM_UPDATEUISTATE
; Minimum supported client .:  Windows 2000 Professional
; Minimum supported server .:  Windows 2000 Server
; Links ....................:  https://docs.microsoft.com/en-us/windows/desktop/menurc/wm-updateuistate
; Description ..............:  An application sends the WM_UPDATEUISTATE message to change the UI state for the specified window
;                              and all its child windows.
; ===============================================================================================================================

HideFocusBorder(wParam, lParam := "", Msg := "", handle := "")
{
	static Affected         := []
	static WM_UPDATEUISTATE := 0x0128
	static UIS_SET          := 1
	static UISF_HIDEFOCUS   := 0x1
	static SET_HIDEFOCUS    := UIS_SET << 16 | UISF_HIDEFOCUS
	static init             := OnMessage(WM_UPDATEUISTATE, Func("HideFocusBorder"))

	if (Msg = WM_UPDATEUISTATE) {
		if (wParam = SET_HIDEFOCUS)
			Affected[handle] := true
		else if Affected[handle]
			DllCall("user32\PostMessage", "ptr", handle, "uint", WM_UPDATEUISTATE, "ptr", SET_HIDEFOCUS, "ptr", 0)
	}
	else if (DllCall("IsWindow", "ptr", wParam, "uint"))
		DllCall("user32\PostMessage", "ptr", wParam, "uint", WM_UPDATEUISTATE, "ptr", SET_HIDEFOCUS, "ptr", 0)
}

; ===============================================================================================================================