; ===============================================================================================================================
; Function .................:  SetWindowTheme
; Minimum supported client .:  Windows Vista
; Minimum supported server .:  Windows Server 2003
; Links ....................:  https://docs.microsoft.com/en-us/windows/win32/api/uxtheme/nf-uxtheme-setwindowtheme
; Description ..............:  Causes a window to use a different set of visual style information than its class normally uses.
; ===============================================================================================================================

SetWindowTheme(handle)
{
	VarSetCapacity(ClassName, 1024, 0)
	if (DllCall("user32\GetClassName", "ptr", handle, "str", ClassName, "int", 512, "int"))
		if (ClassName = "SysListView32") || (ClassName = "SysTreeView32")
			if !(DllCall("uxtheme\SetWindowTheme", "ptr", handle, "wstr", "Explorer", "ptr", 0))
				return true
	return false
}

; ===============================================================================================================================