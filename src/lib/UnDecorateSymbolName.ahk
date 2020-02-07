; ===============================================================================================================================
; Function .................:  UnDecorateSymbolName
; Links ....................:  https://docs.microsoft.com/en-us/windows/win32/api/dbghelp/nf-dbghelp-undecoratesymbolname
; Description ..............:  Undecorates the specified decorated C++ symbol name.
; ===============================================================================================================================

UnDecorateSymbolName(Decorated)
{
	static UNDNAME_COMPLETE := 0x0000
	len := VarSetCapacity(UnDecorated, 2048, 0)
	if (size := DllCall("imagehlp\UnDecorateSymbolName", "astr", Decorated, "ptr", &UnDecorated, "uint", len, "uint", UNDNAME_COMPLETE, "uint"))
		return StrGet(&UnDecorated, size, "cp0")
	return Decorated
}

; ===============================================================================================================================