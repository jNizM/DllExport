; ===============================================================================================================================

ChildModuleInfo(ModulePath)
{
    FileInfo := GetFileVersionInfo(ModulePath)
    SplitPath, ModulePath, ModuleName,,
    Gui, Main:  +0x8000000
    Gui, MInfo: New, -MinimizeBox +LabelMInfo +OwnerMain +hWndhGuiMInfo
    Gui, MInfo: +LastFound
    Gui, MInfo: Margin, 7, 7
    Gui, MInfo: Font, s10, Segoe UI
    Gui, MInfo: Add, Text, xm ym w180 h25 0x200, % "ModuleName:"
    Gui, MInfo: Add, Edit, x+1 yp w350 0x800, % ModuleName
    Gui, MInfo: Add, Text, xm y+4 w180 h25 0x200, % "OriginalFilename:"
    Gui, MInfo: Add, Edit, x+1 yp w350 0x800, % FileInfo.OriginalFilename
    Gui, MInfo: Add, Text, xm y+4 w180 h25 0x200, % "CompanyName:"
    Gui, MInfo: Add, Edit, x+1 yp w350 0x800, % FileInfo.CompanyName
    Gui, MInfo: Add, Text, xm y+4 w180 h25 0x200, % "ProductVersion:"
    Gui, MInfo: Add, Edit, x+1 yp w350 0x800, % FileInfo.ProductVersion
    Gui, MInfo: Add, Text, xm y+4 w180 h25 0x200, % "FileVersion:"
    Gui, MInfo: Add, Edit, x+1 yp w350 0x800, % FileInfo.FileVersion
    Gui, MInfo: Show, AutoSize, % "Module Info"
    WinWaitClose
    return
}

MInfoEscape:
MInfoClose:
    Gui, Main: -0x8000000
    Gui, MInfo: Destroy
return

; ===============================================================================================================================