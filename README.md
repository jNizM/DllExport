# AHK Dll Export Viewer
[![AHK](https://img.shields.io/badge/ahk-2.0--beta.15-C3D69B.svg?style=flat-square)]()
[![OS](https://img.shields.io/badge/os-windows-C3D69B.svg?style=flat-square)]()
[![Releases](https://img.shields.io/github/downloads/jNizM/DllExport/total.svg?style=flat-square&color=95B3D7)](https://github.com/jNizM/DllExport/releases)

Displays a list of all exported functions for the specified Dll files.


## Features
* Displays the name of the function
* Displays the ordinal of the function
* Displays the entry point (the relative address) of the function or its forward string
* Displays OriginalFilename / CompanyName / ProductVersion / FileVersion from a module
* Load common dll's / use drag and drop / filter by searchbar


## Examples
![DllExport](img/DllExport.png)
![DllExport](img/DllExport_2.png)
![DllExport](img/DllExport_3.png)
![DllExport](img/DllExport_4.png)


## Infos
* [AHK Thread](https://autohotkey.com/boards/viewtopic.php?t=111097)
* [MapAndLoad](https://learn.microsoft.com/en-us/windows/win32/api/imagehlp/nf-imagehlp-mapandload) & [UnMapAndLoad](https://learn.microsoft.com/en-us/windows/win32/api/imagehlp/nf-imagehlp-unmapandload)
* [ImageDirectoryEntryToData](https://learn.microsoft.com/en-us/windows/win32/api/dbghelp/nf-dbghelp-imagedirectoryentrytodata)
* [ImageRvaToVa](https://learn.microsoft.com/en-us/windows/win32/api/dbghelp/nf-dbghelp-imagervatova)
* [PE Format Layout](https://drive.google.com/file/d/0B3_wGJkuWLytbnIxY1J5WUs4MEk/view)


## Contributing
* thanks Bentschi for LoadLibrary() (v1.1)
* thanks SKAN for DllListExports() (v1.1)
* thanks 'just me' for GetNamedDllExports() and his testings (v1.1)
* thanks Drugwash for his tips and his testings (v1.1)
* thanks Alguimist for his gui design idea (v1.1)


## Inspired by
* [Dependency Walker](http://www.dependencywalker.com/)
* [DLL Export Viewer](http://www.nirsoft.net/utils/dll_export_viewer.html) by NirSoft


## Questions / Bugs / Issues
If you notice any kind of bugs or issues, report them on the [AHK Thread](https://autohotkey.com/boards/viewtopic.php?t=111097). Same for any kind of questions.


## Copyright and License
[![MIT License](https://img.shields.io/github/license/jNizM/DllExport.svg?style=flat-square&color=C3D69B)](LICENSE)


## Donations
[![PayPal](https://img.shields.io/badge/paypal-donate-B2A2C7.svg?style=flat-square)](https://www.paypal.me/smithz)