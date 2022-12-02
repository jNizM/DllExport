; ===============================================================================================================================

ChildFunctionInfo(function, rva, ordinal, module, path)
{
    Gui, Main:  +0x8000000
    Gui, FInfo: New, -MinimizeBox +LabelFInfo +OwnerMain +hWndhGuiFInfo
    Gui, FInfo: +LastFound
    Gui, FInfo: Margin, 7, 7
    Gui, FInfo: Font, s10, Segoe UI
    Gui, FInfo: Add, Text, xm ym w180 h25 0x200, % "Function Name:"
    Gui, FInfo: Add, Edit, x+1 yp w350 0x800, % function
    Gui, FInfo: Add, Text, xm y+4 w180 h25 0x200, % "Entry Point (RVA):"
    Gui, FInfo: Add, Edit, x+1 yp w350 0x800, % rva
    Gui, FInfo: Add, Text, xm y+4 w180 h25 0x200, % "Ordinal:"
    Gui, FInfo: Add, Edit, x+1 yp w173 0x800, % ordinal
	Gui, FInfo: Add, Edit, x+4 yp w173 0x800, % Format("0x{:x}", ordinal)
    Gui, FInfo: Add, Text, xm y+4 w180 h25 0x200, % "Modulename:"
    Gui, FInfo: Add, Edit, x+1 yp w350 0x800, % module
    Gui, FInfo: Add, Text, xm y+4 w180 h25 0x200, % "Full Path:"
    Gui, FInfo: Add, Edit, x+1 yp w350 0x800, % path
    Gui, FInfo: Add, Text, xm y+4 w180 h25 0x200, % "UnDecorateSymbolName:"
    Gui, FInfo: Add, Edit, xm y+4 w534 r3 0x800, % UnDecorateSymbolName(function)
    Gui, FInfo: Show, AutoSize, % "Function Info"
    WinWaitClose
    return
}

FInfoEscape:
FInfoClose:
    Gui, Main: -0x8000000
    Gui, FInfo: Destroy
return

; ===============================================================================================================================