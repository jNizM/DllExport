; ===========================================================================================================================================================================

/*
	DllExportViewer (written in AutoHotkey)
	Author ....: jNizM
	Released ..: 2017-07-10
	Modified ..: 2022-12-06
	License ...: MIT
	GitHub ....: https://github.com/jNizM/DllExport
	Forum .....: https://www.autohotkey.com/boards/viewtopic.php?t=111097
*/


; COMPILER DIRECTIVES =======================================================================================================================================================

;@Ahk2Exe-SetDescription    DllExportViewer (x64)
;@Ahk2Exe-SetFileVersion    0.9.2
;@Ahk2Exe-SetProductName    DllExportViewer
;@Ahk2Exe-SetProductVersion 2.0-rc.2
;@Ahk2Exe-SetCopyright      (c) 2017-2022 jNizM
;@Ahk2Exe-SetLanguage       0x0407


; SCRIPT DIRECTIVES =========================================================================================================================================================

#Requires AutoHotkey v2.0-



; RUN =======================================================================================================================================================================

DllExportViewer()
;DllExportViewer("Dark") ; <- Dark Theme


; DllExportViewer ===========================================================================================================================================================

DllExportViewer(GuiTheme := "")
{

	App     := Map("name", "DllExportViewer", "version", "0.9.2", "release", "2022-12-06", "author", "jNizM", "licence", "MIT")

	Common  := Array("gdi32", "combase", "ntdll", "kernel32", "ole32", "shell32", "shlwapi", "user32") ; common used dlls
	Graphic := Array("d3d11", "dxgi", "gdi32", "gdi32full", "Gdiplus", "glu32", "opengl32") ; graphics related
	Crypt   := Array("advapi32", "bcrypt", "crypt32", "ncrypt", "rpcrt4", "secur32") ; crypt / security ralated
	DllList := Map("Common used", Common, "Graphics related", Graphic, "Crypt / security ralated", Crypt)

	switch GuiTheme
	{
		case "Dark":
			TBack  := "3E3E3E"
			TCtrls := " Background5B5B5B"
			TFont  := " cD9D9D9"
		default:
			TBack := TCtrls := TFont := ""
	}

	; TRAY ==============================================================================================================================================================

	if (VerCompare(A_OSVersion, "10.0.22000") >= 0)
		TraySetIcon("shell32.dll", 73)


	; MENU BAR ==========================================================================================================================================================

	FileMenu := Menu()
	for key, value in DllList
		FileMenu.Add(key, MenuHandler)
	FileMenu.Add()
	FileMenu.Add("System32", MenuHandler)
	FileMenu.Add("SysWOW64", MenuHandler)
	MyMenuBar := MenuBar()
	MyMenuBar.Add("&Load Dll's", FileMenu)


	; GUI ===============================================================================================================================================================

	Main := Gui("+Resize +MinSize840x480", App["name"])
	Main.MenuBar   := MyMenuBar
	Main.BackColor := TBack
	Main.MarginX   := 10
	Main.MarginY   := 10

	Main.SetFont("s9" TFont, "Segoe UI")
	LV1_Header := ["#", "Function Name", "Ordinal", "Entry Point (RVA)", "Module Name", "Module Path"]
	LV2_Header := ["Module Name", "Module Path"]
	LV1 := Main.AddListView("xm ym w760 h540" TCtrls, LV1_Header)
	LV1.OnEvent("ContextMenu", LV1_ContextMenu)
	LV2 := Main.AddListView("x+10 yp w220 h540" TCtrls, LV2_Header)
	Folder := Map()
	loop Files, A_WinDir "\System32\*.dll"
	{
		Folder[A_LoopFileName] := A_LoopFileFullPath
		LV2.Add(, A_LoopFileName, A_LoopFileFullPath)
	}
	LV2.ModifyCol(1, 198, "Module Name (" LV2.GetCount() ")")
	LV2.ModifyCol(2, 0)
	LV2.OnEvent("DoubleClick", LV2_DoubleClick)
	LV2.OnEvent("ContextMenu", LV2_ContextMenu)
	ED1 := Main.AddEdit("xm y+7 w300" TCtrls)
	ED1.OnEvent("Change", LV1_Search)
	EM_SETCUEBANNER(ED1, "Search...")
	TX1 := Main.AddText("x+5 yp w455 h23 0x202")
	ED2 := Main.AddEdit("x+10 yp w220" TCtrls)
	ED2.OnEvent("Change", LV2_Search)
	EM_SETCUEBANNER(ED2, "Search...")
	Main.OnEvent("DropFiles", GuiDropFiles)
	Main.OnEvent("Size", GuiSize)
	Main.OnEvent("Close", (*) => ExitApp)
	Main.Show("AutoSize")
	OnMessage 0x0100, WM_KEYDOWN
	HideFocusBorder(Main.Hwnd)

	if (VerCompare(A_OSVersion, "10.0.17763") >= 0) && (GuiTheme = "Dark")
	{
		DWMWA_USE_IMMERSIVE_DARK_MODE := 19
		if (VerCompare(A_OSVersion, "10.0.18985") >= 0)
		{
			DWMWA_USE_IMMERSIVE_DARK_MODE := 20
		}
		DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", Main.hWnd, "Int", DWMWA_USE_IMMERSIVE_DARK_MODE, "Int*", true, "Int", 4)
		SetExplorerTheme(LV1.hWnd, "DarkMode_Explorer"), SetExplorerTheme(LV2.hWnd, "DarkMode_Explorer")
		uxtheme := DllCall("GetModuleHandle", "Str", "uxtheme", "Ptr")
		DllCall(DllCall("GetProcAddress", "Ptr", uxtheme, "Ptr", 135, "Ptr"), "Int", 2) ; ForceDark
		DllCall(DllCall("GetProcAddress", "Ptr", uxtheme, "Ptr", 136, "Ptr"))
	}
	else
		SetExplorerTheme(LV1.hWnd), SetExplorerTheme(LV2.hWnd)


	; WINDOW MESSAGES ===================================================================================================================================================

	WM_KEYDOWN(wParam, lParam, msg, hwnd)
	{
		if (hwnd = LV2.hwnd)
		{
			switch wParam
			{
				case 0x0D: ; VK_RETURN
					LV2_Load(LV2)
					return 0
			}
		}
	}

	; MENU EVENTS =======================================================================================================================================================

	MenuHandler(ItemName, *)
	{
		Folder := Map()
		LV2.Opt("-Redraw")
		LV2.Delete()
		switch ItemName
		{
			case "System32", "SysWOW64":
			{
				loop Files, A_WinDir "\" ItemName "\*.dll"
				{
					Folder[A_LoopFileName] := A_LoopFileFullPath
					LV2.Add(, A_LoopFileName, A_LoopFileFullPath)
				}
			}
			default:
			{
				GetFiles := Array()
				for k, v in DllList[ItemName]
				{
					Folder[v ".dll"] := A_WinDir "\System32\" v ".dll"
					LV2.Add(, v ".dll", A_WinDir "\System32\" v ".dll")
				}
			}
		}
		LV2.ModifyCol(1, 198, "Module Name (" LV2.GetCount() ")")
		LV2.Opt("+Redraw")
	}


	; WINDOW EVENTS =====================================================================================================================================================

	GuiSize(thisGui, MinMax, Width, Height)
	{
		if (MinMax = -1)
			return
		LV1.Move(,, Width - 250, Height - 50)
		LV2.Move(Width - 230,,, Height - 50)
		ED1.Move(, Height - 33)
		TX1.Move(Width - 695, Height - 33)
		ED2.Move(Width - 230, Height - 33)
	}


	GuiDropFiles(GuiObj, GuiCtrlObj, FileArray, *)
	{
		switch GuiCtrlObj.ClassNN
		{
			case "SysListView321":
			{
				GetFiles := Array()
				for each, DroppedFile in FileArray
				{
					if (DirExist(DroppedFile))
					{
						loop Files, DroppedFile "\*.dll", "R"
							GetFiles.Push(A_LoopFileFullPath)
					}
					else
					{
						SplitPath DroppedFile,,, &ext
						if (ext = "dll")
							GetFiles.Push(DroppedFile)
					}
				}
				LV_LoadFiles(GetFiles)
			}
			case "SysListView322":
			default:
				return
		}
	}


	LV1_ContextMenu(LV1, Item, IsRightClick, X, Y)
	{
		if (LV1.GetCount() > 0)
		{
			LV_Menu := Menu()
			LV_Menu.Add("Function Info", LV_ShowFunctionInfo)
			LV_Menu.Add("Module Info", LV_ShowModuleInfo)
			LV_Menu.Add("Search Web", LV_SearchFunction)
			LV_Menu.Show(X, Y)
		}

		LV_ShowFunctionInfo(*)
		{
			GetInfo := Array()
			GetList := ListViewGetContent("Focused", LV1)
			loop Parse, GetList, "`t"
				GetInfo.Push(A_LoopField)
			ChildFunctionInfo(GetInfo)
		}

		LV_ShowModuleInfo(*)
		{
			GetList := ListViewGetContent("Focused Col6", LV1)
			ChildModuleInfo(GetList)
		}

		LV_SearchFunction(*)
		{
			GetFunc := ListViewGetContent("Focused Col2", LV1)
			try
				Run "https://learn.microsoft.com/en-us/search/?terms=" GetFunc
		}
	}


	LV2_ContextMenu(LV2, Item, IsRightClick, X, Y)
	{
		if (LV2.GetCount() > 0)
		{
			LV_Menu := Menu()
			LV_Menu.Add("Select All", LV_MenuSelect)
			LV_Menu.Add("Load Module", LV_Load)
			LV_Menu.Add("Module Info", LV_ShowModuleInfo)
			LV_Menu.Show(X, Y)
		}

		LV_MenuSelect(*)
		{
			LV2.Modify(0, "Select")
		}

		LV_Load(*)
		{
			LV2_Load(LV2)
		}

		LV_ShowModuleInfo(*)
		{
			GetList := ListViewGetContent("Focused Col1", LV2)
			ChildModuleInfo(GetList)
		}
	}


	LV2_DoubleClick(LV2, *)
	{
		LV2_Load(LV2)
	}


	; GUI CHILDS ========================================================================================================================================================

	ChildFunctionInfo(FunctionInfo)
	{
		FChild := Gui("-MinimizeBox Owner" Main.hWnd, "Function Info")
		Main.Opt("+Disabled")
		FChild.BackColor := TBack
		FChild.MarginX   := 10
		FChild.MarginY   := 10
		FChild.SetFont("s10" TFont, "Segoe UI")
		FChild.AddText("xm ym w120 h24 0x200", "Function Name:")
		FChild.AddEdit("x+1 yp w300 0x800" TCtrls, FunctionInfo[2])
		FChild.AddText("xm y+5 w120 h24 0x200", "Entry Point (RVA):")
		FChild.AddEdit("x+1 yp w300 0x800" TCtrls, FunctionInfo[4])
		FChild.AddText("xm y+5 w120 h23 0x200", "Ordinal:")
		FChild.AddEdit("x+1 yp w300 0x800" TCtrls, FunctionInfo[3] "   (" Format("0x{:x}", FunctionInfo[3]) ")")
		FChild.AddText("xm y+5 w120 h23 0x200", "Module Name:")
		FChild.AddEdit("x+1 yp w300 0x800" TCtrls, FunctionInfo[5])
		FChild.AddText("xm y+5 w120 h23 0x200", "Full Path:")
		FChild.AddEdit("x+1 yp w300 0x800" TCtrls, FunctionInfo[6])
		FChild.AddText("xm y+5 w180 h23 0x200", "Undecorated Symbol Name:")
		FChild.AddEdit("xm y+5 w421 r3 0x800" TCtrls, UnDecorateSymbolName(FunctionInfo[2]))
		FChild.OnEvent("Close", FChild_Close)
		FChild.OnEvent("Escape", FChild_Close)
		FChild.Show("AutoSize")

		if (VerCompare(A_OSVersion, "10.0.17763") >= 0) && (GuiTheme = "Dark")
		{
			DWMWA_USE_IMMERSIVE_DARK_MODE := 19
			if (VerCompare(A_OSVersion, "10.0.18985") >= 0)
			{
				DWMWA_USE_IMMERSIVE_DARK_MODE := 20
			}
			DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", FChild.hWnd, "Int", DWMWA_USE_IMMERSIVE_DARK_MODE, "Int*", true, "Int", 4)
		}

		FChild_Close(*)
		{
			Main.Opt("-Disabled")
			FChild.Destroy()
		}
	}


	ChildModuleInfo(ModulePath)
	{
		FileInfo := GetFileVersionInfo(ModulePath)
		SplitPath ModulePath, &ModuleName
		MChild := Gui("-MinimizeBox Owner" Main.hWnd, "Module Info")
		Main.Opt("+Disabled")
		MChild.BackColor := TBack
		MChild.MarginX   := 10
		MChild.MarginY   := 10
		MChild.SetFont("s10" TFont, "Segoe UI")
		MChild.AddText("xm ym w120 h24 0x200", "Module Name:")
		MChild.AddEdit("x+1 yp w300 0x800" TCtrls, ModuleName)
		MChild.AddText("xm y+5 w120 h24 0x200", "Original Name:")
		MChild.AddEdit("x+1 yp w300 0x800" TCtrls, FileInfo.Has("OriginalFilename") ? FileInfo["OriginalFilename"] : "")
		MChild.AddText("xm y+5 w120 h23 0x200", "Company Name:")
		MChild.AddEdit("x+1 yp w300 0x800" TCtrls, FileInfo["CompanyName"] ? FileInfo["CompanyName"] : "")
		MChild.AddText("xm y+5 w120 h23 0x200", "Product Version:")
		MChild.AddEdit("x+1 yp w300 0x800" TCtrls, FileInfo["ProductVersion"] ? FileInfo["ProductVersion"] : "")
		MChild.AddText("xm y+5 w120 h23 0x200", "File Version:")
		MChild.AddEdit("x+1 yp w300 0x800" TCtrls, FileInfo["FileVersion"] ? FileInfo["FileVersion"] : "")
		MChild.OnEvent("Close", MChild_Close)
		MChild.OnEvent("Escape", MChild_Close)
		MChild.Show("AutoSize")

		if (VerCompare(A_OSVersion, "10.0.17763") >= 0) && (GuiTheme = "Dark")
		{
			DWMWA_USE_IMMERSIVE_DARK_MODE := 19
			if (VerCompare(A_OSVersion, "10.0.18985") >= 0)
			{
				DWMWA_USE_IMMERSIVE_DARK_MODE := 20
			}
			DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", MChild.hWnd, "Int", DWMWA_USE_IMMERSIVE_DARK_MODE, "Int*", true, "Int", 4)
		}

		MChild_Close(*)
		{
			Main.Opt("-Disabled")
			MChild.Destroy()
		}
	}


	; Messages ==========================================================================================================================================================

	EM_SETCUEBANNER(handle, string, option := false)
	{
		static ECM_FIRST       := 0x1500
		static EM_SETCUEBANNER := ECM_FIRST + 1

		SendMessage(EM_SETCUEBANNER, option, StrPtr(string), handle)
	}


	; Functions =========================================================================================================================================================

	LV2_Load(LV2)
	{
		GetInfo := Array()
		GetList := ListViewGetContent("Selected Col2", LV2)
		loop Parse, GetList, "`n"
			GetInfo.Push(A_LoopField)
		LV_LoadFiles(GetInfo)
	}


	LV_LoadFiles(DllFiles)
	{
		global DllLoaded := Array()
		for each, File in DllFiles
		{
			SplitPath File, &ModuleName
			DllExports := DllExportTable(File)
			loop DllExports["Named"]
			{
				Dll := Object()
				Dll.Name := DllExports["Functions"][A_Index]["Name"]
				Dll.Ordinal := DllExports["Functions"][A_Index]["Ordinal"]
				Dll.EntryPoint := DllExports["Functions"][A_Index]["EntryPoint"]
				Dll.ModuleName := DllExports["Module"]
				Dll.ModulePath := File
				Dll.Index := A_Index
				DllLoaded.Push(Dll)
			}
		}
		LV_ShowTable(DllLoaded)
	}


	LV_ShowTable(Table)
	{
		LV1.Opt("-Redraw")
		LV1.Delete()
		for k, v in Table
			LV1.Add("", v.Index, v.Name, v.Ordinal, v.EntryPoint, v.ModuleName, v.ModulePath)
		LV1.ModifyCol(1, 35)
		LV1.ModifyCol(2, "Auto")
		LV1.Opt("+Redraw")
		TX1.Value := LV1.GetCount() " Functions "
	}


	LV1_Search(CtrlObj, *)
	{
		if (IsSet(DllLoaded))
		{
			LV1.Opt("-Redraw")
			LV1.Delete()
			for k, v in DllLoaded
				try
					if (RegExMatch(v.Name, "i)" CtrlObj.Value))
						LV1.Add("", v.Index, v.Name, v.Ordinal, v.EntryPoint, v.ModuleName, v.ModulePath)
			LV1.ModifyCol(1, 35)
			LV1.ModifyCol(2, "Auto")
			LV1.Opt("+Redraw")
			TX1.Value := LV1.GetCount() " Functions "
		}
	}


	LV2_Search(CtrlObj, *)
	{
		LV2.Opt("-Redraw")
		LV2.Delete()
		for k, v in Folder
			try
				if (RegExMatch(SubStr(k, 1, -4), "i)" CtrlObj.Value))
					LV2.Add("", k, v)
		LV2.ModifyCol(1, 198, "Module Name (" LV2.GetCount() ")")
		LV2.Opt("+Redraw")
	}


	HideFocusBorder(wParam, lParam := "", Msg := "", hWnd := "")
	{
		static Affected         := Map()
		static WM_UPDATEUISTATE := 0x0128
		static UIS_SET          := 1
		static UISF_HIDEFOCUS   := 0x1
		static SET_HIDEFOCUS    := UIS_SET << 16 | UISF_HIDEFOCUS
		static init             := OnMessage(WM_UPDATEUISTATE, HideFocusBorder)

		if (Msg = WM_UPDATEUISTATE)
		{
			if (wParam = SET_HIDEFOCUS)
				Affected[hWnd] := true
			else if (Affected.Has(hWnd))
				PostMessage(WM_UPDATEUISTATE, SET_HIDEFOCUS, 0,, "ahk_id " hWnd)
		}
		else if (DllCall("user32\IsWindow", "Ptr", wParam, "UInt"))
			PostMessage(WM_UPDATEUISTATE, SET_HIDEFOCUS, 0,, "ahk_id " wParam)
	}


	SetExplorerTheme(handle, WindowTheme := "Explorer")
	{
		if (DllCall("GetVersion", "UChar") > 5)
		{
			VarSetStrCapacity(&ClassName, 1024)
			if (DllCall("user32\GetClassName", "Ptr", handle, "Str", ClassName, "Int", 512, "Int"))
			{
				if (ClassName = "SysListView32") || (ClassName = "SysTreeView32")
					return !DllCall("uxtheme\SetWindowTheme", "Ptr", handle, "Str", WindowTheme, "Ptr", 0)
			}
		}
		return false
	}


	GetFileVersionInfo(FileName)
	{
		static StringTable := [ "Comments", "CompanyName", "FileDescription", "FileVersion", "InternalName", "LegalCopyright"
							  , "LegalTrademarks", "OriginalFilename", "PrivateBuild", "ProductName", "ProductVersion", "SpecialBuild" ]

		if !(size := DllCall("version\GetFileVersionInfoSize", "Str", FileName, "Ptr", 0, "UInt"))
		{
			MsgBox("GetFileVersionInfoSize failed: " A_LastError)
			return -1
		}
		data := Buffer(size, 0)
		if !(DllCall("version\GetFileVersionInfo", "Str", FileName, "UInt", 0, "UInt", data.size, "Ptr", data))
		{
			MsgBox("GetFileVersionInfo failed: " A_LastError)
			return -1
		}
		if !(DllCall("version\VerQueryValue", "Ptr", data, "Str", "\VarFileInfo\Translation", "Ptr*", &buf := 0, "UInt*", &len := 0))
		{
			MsgBox("VerQueryValue failed")
			return -1
		}
		LangCP := Format("{:04X}{:04X}", NumGet(buf + 0, "UShort"), NumGet(buf + 2, "UShort"))
		FileInfo := Map()
		for index, value in StringTable
		{
			if (DllCall("version\VerQueryValue", "Ptr", data, "Str", "\StringFileInfo\" . LangCP . "\" value, "Ptr*", &buf, "UInt*", &len))
			{
				FileInfo[value] := StrGet(buf, len, "UTF-16")
			}
		}
		return FileInfo
	}


	UnDecorateSymbolName(Decorated)
	{
		static UNDNAME_COMPLETE := 0x0000
		VarSetStrCapacity(&UnDecorated, 2048)
		if (DllCall("dbghelp\UnDecorateSymbolNameW", "Str", Decorated, "Str", UnDecorated, "UInt", 2048, "UInt", UNDNAME_COMPLETE, "UInt"))
			return UnDecorated
		return
	}
}


; INCLUDES ==================================================================================================================================================================

#Include DllExportTable.ahk


; ===========================================================================================================================================================================