; ===============================================================================================================================
; Function .................:  GetNumberFormatEx
; Minimum supported client .:  Windows Vista
; Minimum supported server .:  Windows Server 2008
; Links ....................:  https://docs.microsoft.com/en-us/windows/win32/api/winnls/nf-winnls-getnumberformatex
; Description ..............:  Formats a number string as a number string customized for a locale specified by name.
; ===============================================================================================================================

GetNumberFormatEx(VarIn, locale := "!x-sys-default-locale")
{
    if (size := DllCall("GetNumberFormatEx", "ptr", &locale, "uint", 0, "ptr", &VarIn, "ptr", 0, "ptr", 0, "int", 0)) {
        VarSetCapacity(buf, size << 1, 0)
        if (DllCall("GetNumberFormatEx", "ptr", &locale, "uint", 0, "ptr", &VarIn, "ptr", 0, "str", buf, "int", size))
            return SubStr(buf, 1, -3)
    }
    return false
}

; ===============================================================================================================================