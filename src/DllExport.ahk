; GLOBAL SETTINGS ===============================================================================================================

#NoEnv
#SingleInstance Force
#NoTrayIcon

SetBatchLines -1

global app          := { name: "DLL Export Viewer", version: "0.4", release: "2017-07-24" }
global WinVersion   := RtlGetVersion()
global CommonFiles  := ["gdi32", "kernel32", "shell32", "user32"]
global IsExpandView := true

if (WinVersion < 0x0501) {
    MsgBox, 0x1030, % "Requirements", % "The minimum operating system requirement is Windows XP or Windows Server 2003"
    ExitApp
}


; MENU ==========================================================================================================================

Menu, Tray, Icon, shell32.dll, 73

Menu, FileMenu, Add, % "&Open...`tCtrl+O",   MenuOpenFile
Menu, FileMenu, Add, % "Load Common Dll's",  MenuOpenCommonFiles
Menu, FileMenu, Add
Menu, FileMenu, Add, % "E&xit`tAlt+F4",      MenuClose
Menu, MenuBar,  Add, % "&File",             :FileMenu

Menu, EditMenu, Add, % "Copy",               MenuCopy
Menu, EditMenu, Add, % "Select All`tCtrl+A", MenuSelect
Menu, EditMenu, Add
Menu, EditMenu, Add, % "Show Info`tCtrl+I",  MenuShowInfo
Menu, MenuBar,  Add, % "&Edit",             :EditMenu

Menu, ViewMenu, Add, % "Expand View",        MenuCollapse
Menu, ViewMenu, % (IsExpandView) ? "Check" : "UnCheck", % "Expand View"
Menu, MenuBar,  Add, % "&View",             :ViewMenu

Menu, HelpMenu, Add, % "&About`tF1",         MenuAbout
Menu, MenuBar,  Add, % "&Help",             :HelpMenu

Gui, Main: Menu, MenuBar


; GUI ===========================================================================================================================

Gui, Main: Default
Gui, Main: +LabelMain +hWndhMainGUI
Gui, Main: Margin, 7, 7
Gui, Main: Color, F1F5FB
Gui, Main: Font, s9, Segoe UI

Gui, Main: Add, ListView, xm ym w800 h450 vMyLV1 hWndhMyLV1 +LV0x14000, % "#|Function Name|Ordinal|Entry Point (RVA)|Module Name|Module Path"
LV_ModifyCol(1, "Integer 40"), LV_ModifyCol(2, 330), LV_ModifyCol(3, "Integer 55"), LV_ModifyCol(4, 240), LV_ModifyCol(5, 113), LV_ModifyCol(6, 0)
if (WinVersion >= 0x0600)
    SetWindowTheme(hMyLV1)

Gui, Main: Add, ListView, x+7 ym w200 h450 gMyLV2 vMyLV2 hWndhMyLV2 +LV0x14000, % "ModuleName"
GuiControl, % (IsExpandView) ? "Show" : "Hide", MyLV2
LV_ModifyCol(1, 178)
if (WinVersion >= 0x0600)
    SetWindowTheme(hMyLV2)
loop, files, % A_WinDir "\system32\*.dll"
    LV_Add("", A_LoopFileName)

Gui, Main: Add, Edit, xm y+7 w230 h23 +0x2000000 hWndhMyEdit gLV_SearchTable
if (WinVersion >= 0x0600)
    EM_SETCUEBANNER(hMyEdit, "Enter search here")

Gui, Main: Add, Text, x+450 yp w120 h23 +0x202 hWndhCounter, % ""
Gui, Main: Show, AutoSize, % app.name
SetFocus(hMyEdit)
HideFocusBorder(hMainGUI)
return


; CHILDS ========================================================================================================================

ChildInfo(function, rva, ordinal, module, path)
{
    Gui, Main: +0x8000000
    Gui, Info: New, -MinimizeBox +LabelInfo +OwnerMain +hWndhInfoGui
    Gui, Info: +LastFound
    Gui, Info: Margin, 7, 7
    Gui, Info: Font, s10, Segoe UI
    Gui, Info: Add, Text, xm ym w180 h25 0x200, % "Function Name:"
    Gui, Info: Add, Edit, x+1 yp w350 0x800, % function
    Gui, Info: Add, Text, xm y+4 w180 h25 0x200, % "Entry Point (RVA):"
    Gui, Info: Add, Edit, x+1 yp w350 0x800, % rva
    Gui, Info: Add, Text, xm y+4 w180 h25 0x200, % "Ordinal"
    Gui, Info: Add, Edit, x+1 yp w350 0x800, % ordinal "   (" Format("0x{:x}", ordinal) ")"
    Gui, Info: Add, Text, xm y+4 w180 h25 0x200, % "Modulename:"
    Gui, Info: Add, Edit, x+1 yp w350 0x800, % module
    Gui, Info: Add, Text, xm y+4 w180 h25 0x200, % "Full Path:"
    Gui, Info: Add, Edit, x+1 yp w350 0x800, % path
    Gui, Info: Add, Text, xm y+4 w180 h25 0x200, % "UnDecorateSymbolName:"
    Gui, Info: Add, Edit, xm y+4 w534 r3 0x800, % UnDecorateSymbolName(function)
    Gui, Info: Show, AutoSize, % ""
    WinWaitClose
    return

    InfoEscape:
    InfoClose:
        Gui, Main: -0x8000000
        Gui, Info: Destroy
    return
}


; WINDOW EVENTS =================================================================================================================

MainContextMenu:
    Gui, ListView, MyLV1
    if (A_GuiControl = "MyLV1") && (LV_GetNext() > 0) {
        Menu, ContextMenuLV1, Add, % "Copy", ContextCopy
        Menu, ContextMenuLV1, Add, % "Select All`tCtrl+A", ContextSelect
        Menu, ContextMenuLV1, Add, % "Show`tCtrl+I", ContextShowInfo
        Menu, ContextMenuLV1, Show, % A_GuiX, % A_GuiY
    }
    Gui, ListView, MyLV2
    if (A_GuiControl = "MyLV2") && (LV_GetNext() > 0) {
        Menu, ContextMenuLV2, Add, % "Load", ContextLoad
        Menu, ContextMenuLV2, Show, % A_GuiX, % A_GuiY
    }
return

MainDropFiles:
    GetFile := []
    loop, parse, A_GuiEvent, `n
    {
        SplitPath, A_LoopField,,, ext
        if (ext != "dll") {
            MsgBox, 0x1030, % "Load File", % "The selected file is not a valid DLL file. Please select a valid DLL file and try again."
            break
        }
        GetFile.Push(A_LoopField)
    }
    LV_LoadFiles(GetFile*)
return

MenuClose:
MainClose:
    ExitApp
return


; SCRIPT ========================================================================================================================

MenuOpenFile:
    GetFile := ""
    FileSelectFile, GetFile, 3, % A_WinDir "\System32", % "Open", % "Dynamic-link library (*.dll)"
    if !(ErrorLevel)
        LV_LoadFiles(GetFile)
return

MenuOpenCommonFiles:
    GetFile := []
    for each, File in CommonFiles
        GetFile.Push(A_WinDir "\system32\" File ".dll")
    LV_LoadFiles(GetFile*)
return

MenuCopy:
ContextCopy:
    ColNum := LVM_SUBITEMHITTEST(hMyLV1)
    ControlGet, CopyList, List, Selected Col%ColNum%, SysListView321, % "ahk_id " hMainGUI
    if !(ErrorLevel)
        Clipboard := CopyList
return

MenuSelect:
ContextSelect:
    Gui, Main: Default
    Gui, ListView, MyLV1
    LV_Modify(0, "Select")
return

MenuShowInfo:
ContextShowInfo:
    GetInfo := []
    ControlGet, ShowList, List, Focused, SysListView321, % "ahk_id " hMainGUI
    if !(ErrorLevel) {
        loop, parse, ShowList, `t
            GetInfo.Push(A_LoopField)
        ChildInfo(GetInfo[2], GetInfo[4], GetInfo[3], GetInfo[5], GetInfo[6])
    }
return

MenuCollapse:
    if !(IsExpandView) {
        Menu, ViewMenu, Check, % "Expand View"
        GuiControl, Show, MyLV2
        Gui, Main: Show, AutoSize
        IsExpandView := true
    } else {
        Menu, ViewMenu, UnCheck, % "Expand View"
        GuiControl, Hide, MyLV2
        Gui, Main: Show, AutoSize
        IsExpandView := false
    }
return

MyLV2:
    if (A_GuiEvent = "DoubleClick") {
        GetFile := ""
        Gui, ListView, MyLV2
        LV_Err := LV_GetText(GetFile, LV_GetNext(0, "Focused"), 1)
        if (LV_Err) && (GetFile != "")
            LV_LoadFiles(A_WinDir "\system32\" GetFile)
    }
return

ContextLoad:
    GetFile := []
    ControlGet, GetList, List, Selected Col1, SysListView322, % "ahk_id " hMainGUI
    if !(ErrorLevel) {
        loop, parse, GetList, `n
            GetFile.Push(A_WinDir "\system32\" A_LoopField)
        LV_LoadFiles(GetFile*)
    }
return

MenuAbout:
return


LV_LoadFiles(DllFiles*)
{
    global hMyEdit, hCounter, DllLoaded
    GuiControl,, % hMyEdit, % ""
    GuiControl,, % hCounter, % "Loading Functions..."
    DllExports := [], DllLoaded := []
    for each, DllFile in DllFiles {
        SplitPath, DllFile, ModuleName,,
        DllExports := GetDllExports(DllFile), index := 0
        sleep -1
        loop % DllExports.Functions.Length() {
            DllLoaded.Push({ n: DllExports.Functions[A_Index].Name
                           , o: DllExports.Functions[A_Index].Ordinal
                           , e: DllExports.Functions[A_Index].EntryPoint
                           , m: ModuleName
                           , p: DllExports.ModuleName
                           , i: ++index })
        }
    }
    LV_ShowTable(DllLoaded)
}

LV_ShowTable(Table)
{
    global hMyEdit, hCounter
    Gui, ListView, MyLV1
    LV_Delete()
    for k, v in Table
        LV_Add("", v.i, v.n, v.o, v.e, v.m, v.p)
    GuiControl,, % hCounter, % LV_GetCount() " Functions"
    SetFocus(hMyEdit)
}

LV_SearchTable()
{
    global hMyEdit, hCounter, DllLoaded
    GuiControlGet, SearchFiled,, % hMyEdit
    Gui, ListView, MyLV1
    LV_Delete()
    for k, v in DllLoaded
        if (InStr(v.n, SearchFiled))
            LV_Add("", v.i, v.n, v.o, v.e, v.m, v.p)
    GuiControl,, % hCounter, % LV_GetCount() " Functions"
    SetFocus(hMyEdit)
}


; FUNCTIONS =====================================================================================================================

RtlGetVersion()
{
    ; 0x0A00 - Windows 10
    ; 0x0603 - Windows 8.1
    ; 0x0602 - Windows 8 / Windows Server 2012
    ; 0x0601 - Windows 7 / Windows Server 2008 R2
    ; 0x0600 - Windows Vista / Windows Server 2008
    ; 0x0502 - Windows XP 64-Bit Edition / Windows Server 2003 / Windows Server 2003 R2
    ; 0x0501 - Windows XP
    static RTL_OSV_EX, init := NumPut(VarSetCapacity(RTL_OSV_EX, A_IsUnicode ? 284 : 156, 0), RTL_OSV_EX, "uint")
    if (DllCall("ntdll\RtlGetVersion", "ptr", &RTL_OSV_EX) != 0)
        throw Exception("RtlGetVersion failed", -1)
    return ((NumGet(RTL_OSV_EX, 4, "uint") << 8) | NumGet(RTL_OSV_EX, 8, "uint"))
}

EM_SETCUEBANNER(handle, string, hideonfocus := true)
{
    static EM_SETCUEBANNER := 0x1501
    if !(DllCall("user32\SendMessage", "ptr", handle, "uint", EM_SETCUEBANNER, "int", hideonfocus, "str", string, "int"))
        throw Exception("EM_SETCUEBANNER failed", -1)
    return true
}

SetWindowTheme(handle)
{
    if (HRESULT := DllCall("uxtheme\SetWindowTheme", "ptr", handle, "wstr", "Explorer", "ptr", 0) != 0)
        throw Exception("SetWindowTheme failed: " HRESULT, -1)
    return true
}

SetFocus(handle)
{
    if !(DllCall("user32\SetFocus", "ptr", handle, "ptr"))
        throw Exception("SetFocus failed: " A_LastError, -1)
    return true
}

SetWindowText(handle, string)
{
    if !(DllCall("user32\SetWindowText", "ptr", handle, "str", string))
        throw Exception("SetWindowText failed: " A_LastError, -1)
    return true
}

LVM_SUBITEMHITTEST(handle) ; by 'just me'
{
    VarSetCapacity(POINT, 8, 0)
    DllCall("user32\GetCursorPos", "ptr", &POINT)
    DllCall("user32\ScreenToClient", "ptr", handle, "ptr", &POINT)
    VarSetCapacity(LVHITTESTINFO, 24, 0)
    NumPut(NumGet(POINT, 0, "int"), LVHITTESTINFO, 0, "int"), NumPut(NumGet(POINT, 4, "int"), LVHITTESTINFO, 4, "int")
    if (DllCall("user32\SendMessage", "ptr", handle, "uint", 0x1039, "ptr", 0, "ptr", &LVHITTESTINFO) = -1)
        return 0
    return NumGet(LVHITTESTINFO, 16, "Int") + 1
}

HideFocusBorder(wParam, lParam := "", Msg := "", handle := "") ; by 'just me'
{
    static Affected         := []
    static WM_UPDATEUISTATE := 0x0128
    static SET_HIDEFOCUS    := 0x00010001 ; UIS_SET << 16 | UISF_HIDEFOCUS
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


; INCLUDES ======================================================================================================================

; ===============================================================================================================================
; Name ............: GetDllExports
; Description .....: Gets the functions exported by name from the specified DLL file
; Returns .........: an object containing the following keys:
;                    ModuleName      - The name of the loaded module
;                    Total           - The total amount of exported functions
;                    Names           - The number of functions exported by name
;                    OrdBase         - The ordinal base
;                    Bitness         - The bitness of the DLL file (32 / 64)
;                    Functions       - An array containing an object for each named function containing the following keys:
;                       Name         - The name of the function
;                       EntryPoint   - Entry point - the relative address of the function or its forward string
;                       Ordianl      - The ordinal of the function
; Authors..........: LoadLibrary()        by Bentschi
;                    DllListExports()     by SKAN
;                    GetNamedDllExports() by 'just me'
;                    DllExport()          by jNizM
; ===============================================================================================================================
GetDllExports(DllFile)
{
    static IMAGE_FILE_MACHINE_I386  := 0x014c
    static IMAGE_FILE_MACHINE_AMD64 := 0x8664

    hIMAGEHLP := DllCall("LoadLibrary", "str", "imagehlp.dll", "ptr") ; <-- fix an issue on Win XP - need to be preloaded before
    VarSetCapacity(LOADED_IMAGE, 88, 0), Export := { ModuleName: "", Total: 0, Names: 0, OrdBase: 0, Bitness: 0, Functions: [] }
    if (DllCall("imagehlp\MapAndLoad", "astr", DllFile, "ptr", 0, "ptr", &LOADED_IMAGE, "int", 1, "int", 1))
    {
        Export.ModuleName := StrGet(NumGet(LOADED_IMAGE, 0, "ptr"), "cp0")
        MappedAddress     := NumGet(LOADED_IMAGE, A_PtrSize * 2, "uptr")
        IMAGE_NT_HEADERS  := NumGet(LOADED_IMAGE, A_PtrSize * 3, "uptr")
        Machine           := NumGet(IMAGE_NT_HEADERS + 4, "ushort")
        if (Machine = IMAGE_FILE_MACHINE_I386) || (Machine = IMAGE_FILE_MACHINE_AMD64)
        {
            if (IMAGE_EXPORT_DIRECTORY := DllCall("imagehlp\ImageDirectoryEntryToData", "ptr", MappedAddress, "int", 0, "ushort", 0, "uint*", size, "uptr"))
            {
                AddressOfFunctions := NumGet(IMAGE_EXPORT_DIRECTORY + 0x1c, "uint")
                if (AddressTbl := DllCall("imagehlp\ImageRvaToVa", "ptr", IMAGE_NT_HEADERS, "ptr", MappedAddress, "uint", AddressOfFunctions, "ptr", 0, "uptr"))
                {
                    RvaOffset             := AddressTbl - AddressOfFunctions
                    EndOfSection          := IMAGE_EXPORT_DIRECTORY + size
                    OrdinalBase           := NumGet(IMAGE_EXPORT_DIRECTORY + 0x10, "uint")
                    NumberOfFunctions     := NumGet(IMAGE_EXPORT_DIRECTORY + 0x14, "uint")
                    NumberOfNames         := NumGet(IMAGE_EXPORT_DIRECTORY + 0x18, "uint")
                    AddressOfNames        := NumGet(IMAGE_EXPORT_DIRECTORY + 0x20, "uint") + RvaOffset
                    AddressOfNameOrdinals := NumGet(IMAGE_EXPORT_DIRECTORY + 0x24, "uint") + RvaOffset
                    Export.Total          := NumberOfFunctions
                    Export.OrdBase        := OrdinalBase
                    Export.Bitness        := (Machine = IMAGE_FILE_MACHINE_I386) ? 32 : 64
                    loop % NumberOfNames
                    {
                        NamePtr := NumGet(AddressOfNames + 0, "uint") + RvaOffset
                        Ordinal := NumGet(AddressOfNameOrdinals + 0, "ushort")
                        Address := NumGet(AddressTbl + 0, Ordinal * 4, "uint") + RvaOffset
                        EntryPt := (Address > IMAGE_EXPORT_DIRECTORY) && (Address < EndOfSection) ? StrGet(Address, "cp0") : Format("0x{:08x}", Address - RvaOffset)
                        Export.Functions.Push( { Name: StrGet(NamePtr, "cp0"), EntryPoint: EntryPt, Ordinal: Ordinal + OrdinalBase } )
                        AddressOfNames += 4, AddressOfNameOrdinals += 2
                    }
                }
            }
        }
        DllCall("imagehlp\UnMapAndLoad", "ptr", &LOADED_IMAGE)
    }
    Export.Names := Export.Functions.Length()
    DllCall("FreeLibrary", "ptr", hIMAGEHLP) ; <-- fix an issue on Win XP - need to be preloaded before
    return Export
}

UnDecorateSymbolName(Decorated)
{
    Length := VarSetCapacity(UnDecorated, 2048, 0)
    if (size := DllCall("imagehlp\UnDecorateSymbolName", "astr", Decorated, "ptr", &UnDecorated, "uint", Length, "uint", 0, "uint"))
        return StrGet(&UnDecorated, size, "cp0")
    else
        return Decorated
}


; REF ===========================================================================================================================

/*

typedef struct _LOADED_IMAGE {
    PSTR                  ModuleName;                                            // 0x00
    HANDLE                hFile;                                                 // 0x08
    PUCHAR                MappedAddress;                                         // 0x10
    PIMAGE_NT_HEADERS32   FileHeader;                                            // 0x18
    PIMAGE_SECTION_HEADER LastRvaSection;                                        // 0x20
    ULONG                 NumberOfSections;                                      // 0x28
    PIMAGE_SECTION_HEADER Sections;                                              // 0x30
    ULONG                 Characteristics;                                       // 0x38
    BOOLEAN               fSystemImage;                                          // 0x3c
    BOOLEAN               fDOSImage;                                             // 0x3d
    BOOLEAN               fReadOnly;                                             // 0x3f
    UCHAR                 Version;                                               // 0x3e
    LIST_ENTRY            Links;                                                 // 0x40
    ULONG                 SizeOfImage;                                           // 0x50
} LOADED_IMAGE, *PLOADED_IMAGE;                                                  // 0x58



typedef struct _IMAGE_NT_HEADERS {
    DWORD Signature;                                                             // 0x00
    IMAGE_FILE_HEADER FileHeader;                                                // 0x04
    IMAGE_OPTIONAL_HEADER32 OptionalHeader;                                      // 0x18
} IMAGE_NT_HEADERS32, *PIMAGE_NT_HEADERS32;

typedef struct _IMAGE_NT_HEADERS64 {
    DWORD Signature;                                                             // 0x00
    IMAGE_FILE_HEADER FileHeader;                                                // 0x04
    IMAGE_OPTIONAL_HEADER64 OptionalHeader;                                      // 0x18
} IMAGE_NT_HEADERS64, *PIMAGE_NT_HEADERS64;



typedef struct _IMAGE_FILE_HEADER {
    WORD  Machine;                                                               // 0x00
    WORD  NumberOfSections;                                                      // 0x02
    DWORD TimeDateStamp;                                                         // 0x04
    DWORD PointerToSymbolTable;                                                  // 0x08
    DWORD NumberOfSymbols;                                                       // 0x0c
    WORD  SizeOfOptionalHeader;                                                  // 0x10
    WORD  Characteristics;                                                       // 0x12
} IMAGE_FILE_HEADER, *PIMAGE_FILE_HEADER;



typedef struct _IMAGE_OPTIONAL_HEADER {
    WORD    Magic;                                                               // 0x00
    BYTE    MajorLinkerVersion;                                                  // 0x02
    BYTE    MinorLinkerVersion;                                                  // 0x03
    DWORD   SizeOfCode;                                                          // 0x04
    DWORD   SizeOfInitializedData;                                               // 0x08
    DWORD   SizeOfUninitializedData;                                             // 0x0c
    DWORD   AddressOfEntryPoint;                                                 // 0x10
    DWORD   BaseOfCode;                                                          // 0x14
    DWORD   BaseOfData;                                                          // 0x18
    DWORD   ImageBase;                                                           // 0x1c
    DWORD   SectionAlignment;                                                    // 0x20
    DWORD   FileAlignment;                                                       // 0x24
    WORD    MajorOperatingSystemVersion;                                         // 0x28
    WORD    MinorOperatingSystemVersion;                                         // 0x2a
    WORD    MajorImageVersion;                                                   // 0x2c
    WORD    MinorImageVersion;                                                   // 0x2e
    WORD    MajorSubsystemVersion;                                               // 0x30
    WORD    MinorSubsystemVersion;                                               // 0x32
    DWORD   Win32VersionValue;                                                   // 0x34
    DWORD   SizeOfImage;                                                         // 0x38
    DWORD   SizeOfHeaders;                                                       // 0x3c
    DWORD   CheckSum;                                                            // 0x40
    WORD    Subsystem;                                                           // 0x44
    WORD    DllCharacteristics;                                                  // 0x46
    DWORD   SizeOfStackReserve;                                                  // 0x48
    DWORD   SizeOfStackCommit;                                                   // 0x4c
    DWORD   SizeOfHeapReserve;                                                   // 0x50
    DWORD   SizeOfHeapCommit;                                                    // 0x54
    DWORD   LoaderFlags;                                                         // 0x58
    DWORD   NumberOfRvaAndSizes;                                                 // 0x5c
    IMAGE_DATA_DIRECTORY DataDirectory[IMAGE_NUMBEROF_DIRECTORY_ENTRIES];        // 0x60
} IMAGE_OPTIONAL_HEADER32, *PIMAGE_OPTIONAL_HEADER32;                            // 0x64

typedef struct _IMAGE_OPTIONAL_HEADER64 {
    WORD        Magic;                                                           // 0x00
    BYTE        MajorLinkerVersion;                                              // 0x02
    BYTE        MinorLinkerVersion;                                              // 0x03
    DWORD       SizeOfCode;                                                      // 0x04
    DWORD       SizeOfInitializedData;                                           // 0x08
    DWORD       SizeOfUninitializedData;                                         // 0x0c
    DWORD       AddressOfEntryPoint;                                             // 0x10
    DWORD       BaseOfCode;                                                      // 0x14
    ULONGLONG   ImageBase;                                                       // 0x18
    DWORD       SectionAlignment;                                                // 0x20
    DWORD       FileAlignment;                                                   // 0x24
    WORD        MajorOperatingSystemVersion;                                     // 0x28
    WORD        MinorOperatingSystemVersion;                                     // 0x2a
    WORD        MajorImageVersion;                                               // 0x2c
    WORD        MinorImageVersion;                                               // 0x2e
    WORD        MajorSubsystemVersion;                                           // 0x30
    WORD        MinorSubsystemVersion;                                           // 0x32
    DWORD       Win32VersionValue;                                               // 0x36
    DWORD       SizeOfImage;                                                     // 0x38
    DWORD       SizeOfHeaders;                                                   // 0x3c
    DWORD       CheckSum;                                                        // 0x40
    WORD        Subsystem;                                                       // 0x44
    WORD        DllCharacteristics;                                              // 0x46
    ULONGLONG   SizeOfStackReserve;                                              // 0x48
    ULONGLONG   SizeOfStackCommit;                                               // 0x50
    ULONGLONG   SizeOfHeapReserve;                                               // 0x58
    ULONGLONG   SizeOfHeapCommit;                                                // 0x60
    DWORD       LoaderFlags;                                                     // 0x68
    DWORD       NumberOfRvaAndSizes;                                             // 0x6c
    IMAGE_DATA_DIRECTORY DataDirectory[IMAGE_NUMBEROF_DIRECTORY_ENTRIES];        // 0x70
} IMAGE_OPTIONAL_HEADER64, *PIMAGE_OPTIONAL_HEADER64;                            // 0x74



typedef struct _IMAGE_DATA_DIRECTORY {
    DWORD   VirtualAddress;                                                      // 0x00
    DWORD   Size;                                                                // 0x04
} IMAGE_DATA_DIRECTORY, *PIMAGE_DATA_DIRECTORY;



typedef struct _IMAGE_EXPORT_DIRECTORY {
    DWORD   Characteristics;                                                     // 0x00
    DWORD   TimeDateStamp;                                                       // 0x04
    WORD    MajorVersion;                                                        // 0x08
    WORD    MinorVersion;                                                        // 0x0a
    DWORD   Name;                                                                // 0x0c
    DWORD   Base;                                                                // 0x10
    DWORD   NumberOfFunctions;                                                   // 0x14
    DWORD   NumberOfNames;                                                       // 0x18
    DWORD   AddressOfFunctions;                                                  // 0x1c
    DWORD   AddressOfNames;                                                      // 0x20
    DWORD   AddressOfNameOrdinals;                                               // 0x24
} IMAGE_EXPORT_DIRECTORY, *PIMAGE_EXPORT_DIRECTORY;

*/

; ===============================================================================================================================