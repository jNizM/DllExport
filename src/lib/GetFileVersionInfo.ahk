; ===============================================================================================================================
; Function .................:  GetFileVersionInfo
; Minimum supported client .:  Windows 2000 Professional
; Minimum supported server .:  Windows 2000 Server
; Links ....................:  https://docs.microsoft.com/en-us/windows/win32/api/winver/
; Description ..............:  Retrieves version information for the specified file.
; ===============================================================================================================================

GetFileVersionInfo(FileName)
{
    static StringTable := ["OriginalFilename", "CompanyName", "ProductVersion", "FileVersion"]

    if (size := DllCall("version\GetFileVersionInfoSize", "str", FileName, "ptr", 0, "uint")) {
        size := VarSetCapacity(data, size + A_PtrSize)
        if (DllCall("version\GetFileVersionInfo", "str", FileName, "uint", 0, "uint", size, "ptr", &data)) {
            if (DllCall("version\VerQueryValue", "ptr", &data, "str", "\VarFileInfo\Translation", "ptr*", buf, "ptr*", len)) {
                LangCP := Format("{:04X}{:04X}", NumGet(buf+0, "ushort"), NumGet(buf+2, "ushort")), FileInfo := {}
                for i, v in StringTable
                    if (DllCall("version\VerQueryValue", "ptr", &data, "str", "\StringFileInfo\" LangCP "\" v, "ptr*", buf, "ptr*", len))
                        FileInfo[v] := StrGet(buf, len)
                return FileInfo
            }
        }
    }
    return false
}

; ===============================================================================================================================