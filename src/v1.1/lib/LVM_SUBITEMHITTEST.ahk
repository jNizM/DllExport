; ===============================================================================================================================
; Message ..................:  LVM_SUBITEMHITTEST
; Minimum supported client .:  Windows Vista
; Minimum supported server .:  Windows Server 2003
; Links ....................:  https://docs.microsoft.com/en-us/windows/desktop/controls/lvm-subitemhittest
; Description ..............:  Determines which list-view item or subitem is at a given position.
; ===============================================================================================================================

LVM_SUBITEMHITTEST(handle)
{
	static LVM_FIRST          := 0x1000
	static LVM_SUBITEMHITTEST := LVM_FIRST + 57

	VarSetCapacity(POINT, 8, 0)
	DllCall("user32\GetCursorPos", "ptr", &POINT)
	DllCall("user32\ScreenToClient", "ptr", handle, "ptr", &POINT)
	VarSetCapacity(LVHITTESTINFO, 24, 0)
	NumPut(NumGet(POINT, 0, "int"), LVHITTESTINFO, 0, "int"), NumPut(NumGet(POINT, 4, "int"), LVHITTESTINFO, 4, "int")
	if (DllCall("user32\SendMessage", "ptr", handle, "uint", LVM_SUBITEMHITTEST, "ptr", 0, "ptr", &LVHITTESTINFO) = -1)
		return 0
	return NumGet(LVHITTESTINFO, 16, "Int")
}

; ===============================================================================================================================