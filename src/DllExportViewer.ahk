; GLOBAL SETTINGS ===============================================================================================================

#NoEnv
#SingleInstance Force
#Persistent

SetBatchLines -1

global app := { name: "DLL Export Viewer", version: "0.8", release: "2020-02-07", author: "jNizM", licence: "MIT" }


; GLOBALS / STATICS =============================================================================================================

global CommonFiles  := [ "gdi32", "kernel32", "shell32", "user32" ]


; MENU ==========================================================================================================================

Menu, Tray, Icon, shell32.dll, 73

Menu, FileMenu, Add, % "&Open...`tCtrl+O",      MenuOpenFile
Menu, FileMenu, Add, % "Load Common Dlls",      MenuOpenCommonFiles
Menu, FileMenu, Add
Menu, FileMenu, Add, % "E&xit`tAlt+F4",         MenuClose
Menu, MenuBar,  Add, % "&File",                :FileMenu

Menu, EditMenu, Add, % "Copy`tCtrl+C",          MenuCopy
Menu, EditMenu, Add, % "Select All`tCtrl+A",    MenuSelect
Menu, EditMenu, Add
Menu, EditMenu, Add, % "Function Info`tCtrl+F", MenuShowFunctionInfo
Menu, EditMenu, Add, % "Module Info`tCtrl+M",   MenuShowModuleInfo
Menu, MenuBar,  Add, % "&Edit",                :EditMenu

Menu, HelpMenu, Add, % "&About`tF1",            MenuAbout
Menu, MenuBar,  Add, % "&Help",                :HelpMenu

Gui, Main: Menu, MenuBar


; GUI ===========================================================================================================================

Gui, Main: Default
Gui, Main: +LabelMain +hWndhGuiMain +MinSize1021x582 +Resize
Gui, Main: Margin, 7, 7
Gui, Main: Color, F1F5FB
Gui, Main: Font, s9, Segoe UI

Gui, Main: Add, ListView, xm ym w800 h540 vMainLV01 hWndhMainLV01 +LV0x14000, % "#|Function Name|Ordinal| Entry Point (RVA)|Module Name|Module Path"
SetWindowTheme(hMainLV01)

Gui, Main: Add, ListView, x+7 yp w200 h540 gMainLV02 vMainLV02 hWndhMainLV02 +LV0x14000, % "Module Name|Module Path"
SetWindowTheme(hMainLV02)
Loop, Files, % A_WinDir "\System32\*.dll"
	LV_Add("", A_LoopFileName, A_LoopFileFullPath)
LV_ModifyCol(1, 178, "Module Name (" LV_GetCount() ")"), LV_ModifyCol(2, 0)

Gui, Main: Add, Edit, xm y+7 w300 gLV_SearchTable vMainEdt01 hWndhMainEdt01
EM_SETCUEBANNER(hMainEdt01, "Enter search here")

Gui, Main: Add, Text, x+5 yp w495 h23 vMainTxt01 +0x202

Gui, Main: Show, AutoSize, % app.name
HideFocusBorder(hGuiMain)
return


; GUI CHILDS ====================================================================================================================

#Include lib\Gui_Child_About.ahk
#Include lib\Gui_Child_FunctionInfo.ahk
#Include lib\Gui_Child_ModuleInfo.ahk


; WINDOW EVENTS =================================================================================================================

MenuClose:
MainClose:
	ExitApp
return


MainSize:
	GuiControl, Move,     MainLV01,  % "x7 y7 h" (A_GuiHeight - 42) " w" (A_GuiWidth - 221)
	GuiControl, Move,     MainLV02,  % "x+" (A_GuiWidth - 207) " y7 h" (A_GuiHeight - 42)
	GuiControl, Move,     MainEdt01, % "x7 y" (A_GuiHeight - 30)
	GuiControl, MoveDraw, MainTxt01, % "x+" (A_GuiWidth - 709) " y" (A_GuiHeight - 30)
return


MainContextMenu:
	Gui, ListView, MainLV01
	if (A_GuiControl = "MainLV01") && (LV_GetNext() > 0) {
		Menu, ContextMenuLV01, Add, % "Copy`tCtrl+C", ContextCopy
		Menu, ContextMenuLV01, Add, % "Select All`tCtrl+A", ContextSelect
		Menu, ContextMenuLV01, Add, % "Function Info`tCtrl+F", ContextShowFunctionInfo
		Menu, ContextMenuLV01, Add, % "Module Info`tCtrl+M", ContextShowModuleInfo
		Menu, ContextMenuLV01, Show, % A_GuiX, % A_GuiY
	}
	Gui, ListView, MainLV02
	if (A_GuiControl = "MainLV02") && (LV_GetNext() > 0) {
		Menu, ContextMenuLV02, Add, % "Load", ContextLoad
		Menu, ContextMenuLV02, Show, % A_GuiX, % A_GuiY
	}
return


MainDropFiles:
	if (A_GuiControl = "MainLV01") {
		GetFile := []
		Loop, Parse, A_GuiEvent, `n
		{
			if (InStr(FileExist(A_LoopField), "D"))
				Loop, Files, % A_LoopField "\*.dll", R
					GetFile.Push(A_LoopFileFullPath)
			else {
				SplitPath, A_LoopField,,, ext
				if (ext = "dll")
					GetFile.Push(A_LoopField)
			}
		}
		LV_LoadFiles(GetFile*)
	}
	if (A_GuiControl = "MainLV02") {
		StaticFolder := []
		Gui, ListView, MainLV02
		GuiControl, -Redraw, MainLV02
		LV_Delete()
		Loop, Parse, A_GuiEvent, `n
		{
			if (InStr(FileExist(A_LoopField), "D"))
				Loop, Files, % A_LoopField "\*.dll", R
					LV_Add("", A_LoopFileName, A_LoopFileFullPath)
			else {
				SplitPath, A_LoopField, FileName,, ext
				if (ext = "dll")
					LV_Add("", FileName, A_LoopField)
			}
		}
		LV_ModifyCol(1, 178, "Module Name (" LV_GetCount() ")")
		GuiControl, +Redraw, MainLV02
	}
return


MenuOpenFile:
	GetFile := ""
	FileSelectFile, GetFile, 3, % A_WinDir "\System32", % "Open", % "Dynamic-link library (*.dll)"
	if !(ErrorLevel)
		LV_LoadFiles(GetFile)
return


MenuOpenCommonFiles:
	GetFile := []
	for each, File in CommonFiles
		GetFile.Push(A_WinDir "\System32\" File ".dll")
	LV_LoadFiles(GetFile*)
return


MenuCopy:
ContextCopy:
	ColNum := LVM_SUBITEMHITTEST(hMainLV01)
	ControlGet, CopyList, List, Selected Col%ColNum%, SysListView321, % "ahk_id " hGuiMain
	if !(ErrorLevel)
		Clipboard := CopyList
return


MenuSelect:
ContextSelect:
	Gui, Main: Default
	Gui, ListView, MainLV01
	LV_Modify(0, "Select")
return


MenuShowFunctionInfo:
ContextShowFunctionInfo:
	GetInfo := []
	Gui, Main: Default
	ControlGet, ShowList, List, Focused, SysListView321, % "ahk_id " hGuiMain
	if !(ErrorLevel)
	{
		Loop, Parse, ShowList, `t
			GetInfo.Push(A_LoopField)
		ChildFunctionInfo(GetInfo[2], GetInfo[4], GetInfo[3], GetInfo[5], GetInfo[6])
	}
return


MenuShowModuleInfo:
ContextShowModuleInfo:
	GetModule := ""
	Gui, Main: Default
	ControlGet, GetModule, List, Focused Col6, SysListView321, % "ahk_id " hGuiMain
	if !(ErrorLevel) && (GetModule != "")
		ChildModuleInfo(GetModule)
return


ContextLoad:
	Gui, Main: Default
	Gui, ListView, MainLV02
	GetFile := [], GetList := ""
	ControlGet, GetList, List, Selected Col2, SysListView322, % "ahk_id " hGuiMain
	if !(ErrorLevel) {
		Loop, Parse, GetList, `n
			GetFile.Push(A_LoopField)
		LV_LoadFiles(GetFile*)
	}
	sleep -1
return


MenuAbout:
	ChildAbout()
return


MainLV02:
	if (A_GuiEvent = "DoubleClick") {
		GetFile := ""
		Gui, ListView, MainLV02
		LV_Err := LV_GetText(GetFile, LV_GetNext(0, "Focused"), 2)
		if (LV_Err) && (GetFile != "")
			LV_LoadFiles(GetFile)
	}
return


; FUNCTIONS =====================================================================================================================

LV_LoadFiles(DllFiles*)
{
	global MainTxt01, DllLoaded, IsSearchPause

	GuiControl,, MainTxt01, % "Loading Functions... "
	IsSearchPause := true, DllExports := [], DllLoaded := []

	for earch, DllFile in DllFiles
	{
		SplitPath, DllFile, ModuleName,,
		DllExports := DllExportTable(DllFile), index := 0
		sleep -1
		loop % DllExports.Named
		{
			DllLoaded.Push( { Name:       DllExports.Functions[A_Index].Name
							, Ordinal:    DllExports.Functions[A_Index].Ordinal
							, EntryPoint: DllExports.Functions[A_Index].EntryPoint
							, ModuleName: DllExports.Module
							, ModulePath: DllFile
							, Index:      ++index } )
		}
	}
	LV_ShowTable(DllLoaded)
}

LV_ShowTable(Table)
{
	global hGuiMain, MainEdt01, MainTxt01

	if (IsObject(Table)) {
		Gui, Main: Default
		GuiControl, -Redraw, MainLV01
		Gui, ListView, MainLV01
		LV_Delete()

		for k, v in Table
			LV_Add("", v.Index, v.Name, v.Ordinal, v.EntryPoint, v.ModuleName, v.ModulePath)

		GuiControl,, MainTxt01, % GetNumberFormatEx(LV_GetCount()) " Functions "
		GuiControl,, MainEdt01, % ""
		LV_ModifyCol(1, 35), LV_ModifyCol(2, "Auto")
		GuiControl, +Redraw, MainLV01
	}
}

LV_SearchTable()
{
	global hGuiMain, MainEdt01, MainTxt01, DllLoaded, IsSearchPause

	if !(IsSearchPause) {
		Gui, Main: Default
		GuiControlGet, SearchField,, MainEdt01
		GuiControl, -Redraw, MainLV01
		Gui, ListView, MainLV01
		LV_Delete()

		for k, v in DllLoaded
			if (InStr(v.Name, SearchField))
				LV_Add("", v.Index, v.Name, v.Ordinal, v.EntryPoint, v.ModuleName, v.ModulePath)

		GuiControl,, MainTxt01, % GetNumberFormatEx(LV_GetCount()) " Functions "
		GuiControl, +Redraw, MainLV01
	}
	IsSearchPause := false
}


; INCLUDES ======================================================================================================================

#Include lib\DllExportTable.ahk
#Include lib\EM_SETCUEBANNER.ahk
#Include lib\GetFileVersionInfo.ahk
#Include lib\HideFocusBorder.ahk
#Include lib\LVM_SUBITEMHITTEST.ahk
#Include lib\SetWindowTheme.ahk
#Include lib\UnDecorateSymbolName.ahk


; ===============================================================================================================================