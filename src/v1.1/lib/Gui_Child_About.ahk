; ===============================================================================================================================

ChildAbout()
{
    Gui, Main:  +0x8000000
    Gui, About: New, -MinimizeBox +LabelAbout +OwnerMain +hWndhGuiAbout
    Gui, About: +LastFound
    Gui, About: Margin, 10, 10
    Gui, About: Font, s9, Segoe UI
	Gui, About: Add, Picture, xm-10 ym-5 w64 h64 Icon73, shell32.dll
	Gui, About: Add, Text, x+1 ym w200 0x200, % app.name " " app.version
	Gui, About: Add, Text, xp y+2 w200 0x200, % app.release
	Gui, About: Add, Text, xp y+2 w200 0x200, % "Copyright (c) 2017-2020 " app.author
	Gui, About: Add, Text, xm y+16 w292 r3, % app.name " is free Software.`nHowever, you can support the project with a donation. (see GitHub page)"
	Gui, About: Add, Button, xm y+16 w80 gAboutGitHub, % "GitHub"
	Gui, About: Add, Button, x+6 yp w80 gAboutForum, % "Forum"
    Gui, About: Show, AutoSize, % "About"
    WinWaitClose
    return
}

AboutEscape:
AboutClose:
    Gui, Main: -0x8000000
    Gui, About: Destroy
return

AboutGitHub:
	Run % "https://github.com/jNizM/DllExport"
return

AboutForum:
	Run % "https://www.autohotkey.com/boards/viewtopic.php?t=34262"
return

; ===============================================================================================================================