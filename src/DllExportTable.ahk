; ===========================================================================================================================================================================
; Name ............: DllExportTable
; Description .....: Gets the functions exported by name from the specified DLL file
; Returns .........: an object containing the following keys:
;                    Module          - The name of the loaded module
;                    Total           - The total amount of exported functions
;                    Named           - The number of functions exported by name
;                    OrdBase         - The ordinal base
;                    Bitness         - The bitness of the DLL file (32 / 64)
;                    Functions       - An array containing an object for each named function containing the following keys:
;                       Name         - The name of the function
;                       EntryPoint   - Entry point - the relative address of the function or its forward string
;                       Ordianl      - The ordinal of the function
; Authors..........: 'just me', jNizM
; ===========================================================================================================================================================================

#Requires AutoHotkey v2.0-beta


; ===========================================================================================================================================================================

DllExportTable(DllPath)
{
	static LocSignatureOff := 0x3c ; location of the file offset to the PE signature
	static SizeOfSignature := 4 ; size of the PE signature
	static SizeOfCoffHdr := 20 ; size of the COFF header
	static SizeOfSectionHdr := 40 ; size of a section header
	static IMAGE_FILE_MACHINE_I386 := 0x014c ; architecture type is x86
	static IMAGE_FILE_MACHINE_AMD64 := 0x8664 ; architecture type is x64
	static IMAGE_FILE_DLL := 0x2000 ; image is a DLL file
	static IMAGE_NT_OPTIONAL_HDR64_MAGIC := 0x20b ; The file is an executable image


	SplitPath DllPath,,, &FileExt
	if (FileExt != "dll")
		throw ValueError("invalid file extension")


	DllFile := FileOpen(DllPath, "r")
	if !(DllFile)
		throw OSError("could not open the file for reading")
	if (DllFile.Pos != 0)
		throw Error("AHK found a BOM, it isn't a dll file")


	; =======================================================================================================================================================================
	; MS-DOS Stub   –   https://learn.microsoft.com/en-us/windows/win32/debug/pe-format#ms-dos-stub-image-only
	;
	; The MS-DOS stub is a valid application that runs under MS-DOS. It is placed at the front of the EXE image.
	; The linker places a default stub here, which prints out the message "This program cannot be run in DOS mode" when the image is run in MS-DOS.
	; =======================================================================================================================================================================
	RawBytes := Buffer(2, 0)
	DllFile.RawRead(RawBytes, 2)
	if !(StrGet(RawBytes, 2, "cp0") == "MZ")
		throw Error("no MS-DOS stub")


	; =======================================================================================================================================================================
	; SIGNATURE   –   https://learn.microsoft.com/en-us/windows/win32/debug/pe-format#signature-image-only
	;
	; After the MS-DOS stub, at the file offset specified at offset 0x3c, is a 4-byte signature that identifies the file as a PE format image file.
	; This signature is "PE\0\0" (the letters "P" and "E" followed by two null bytes).
	; =======================================================================================================================================================================
	DllFile.Pos := LocSignatureOff
	DllFile.Pos := DllFile.ReadUInt()
	RawBytes := Buffer(SizeOfSignature, 0)
	DllFile.RawRead(RawBytes, SizeOfSignature)
	if !(StrGet(RawBytes, SizeOfSignature, "cp0") == "PE")
		throw Error("no PE file")


	; =======================================================================================================================================================================
	; COFF File Header   –   https://learn.microsoft.com/en-us/windows/win32/debug/pe-format#coff-file-header-object-and-image
	;
	; At the beginning of an object file, or immediately after the signature of an image file, is a standard COFF file header.
	; =======================================================================================================================================================================
	RawBytes := Buffer(SizeOfCoffHdr, 0)
	DllFile.RawRead(RawBytes, SizeOfCoffHdr) ; Read the COFF file header and advance the file pointer to the begin of the optional header.
	Machine := NumGet(RawBytes, 0, "UShort") ; The number that identifies the type of target machine.
	NumberOfSections := NumGet(RawBytes, 2, "UShort") ; The number of sections. This indicates the size of the section table, which immediately follows the headers.
	SizeOfOptionalHeader := NumGet(RawBytes, 16, "UShort") ; The size of the optional header, which is required for executable files but not for object files.
	Characteristics := NumGet(RawBytes, 18, "UShort") ; The flags that indicate the attributes of the file.
	if (Machine != IMAGE_FILE_MACHINE_I386) && (Machine != IMAGE_FILE_MACHINE_AMD64)
		throw Error("wrong CPU type")
	if !(Characteristics & IMAGE_FILE_DLL)
		throw Error("not a valid DLL file")


	; =======================================================================================================================================================================
	; OPTIONAL HEADER   –   https://learn.microsoft.com/en-us/windows/win32/debug/pe-format#optional-header-image-only
	;
	; PE format (magic number): PE32  (32-bit) = 0x010B   |   PE32+ (64-bit) = 0x020B
	; Read the optional header and advance the file pointer to the begin of the section headers.
	; =======================================================================================================================================================================
	RawBytes := Buffer(SizeOfOptionalHeader, 0)
	DllFile.RawRead(RawBytes, SizeOfOptionalHeader)
	Magic := NumGet(RawBytes, 0, "UShort") ; the state of the image file
	Off64 := (Magic = IMAGE_NT_OPTIONAL_HDR64_MAGIC) ? 16 : 0 ; additional offset for 64-bit, zero for 32-bit
	SizeOfImage := NumGet(RawBytes, 56, "UInt") ; the size of the image as loaded into memory
	Offset := 92 + Off64
	if ((NumberOfRvaAndSizes := NumGet(RawBytes, Offset + 0, "UInt")) < 1) ; the number of data directory entries
	|| ((ExportAddr          := NumGet(RawBytes, Offset + 4, "UInt")) < 1) ; the address of the export table (RVA)
	|| ((ExportSize          := NumGet(RawBytes, Offset + 8, "UInt")) < 1) ; the size of the export table
		throw Error("couldn't find an export table")


	; =======================================================================================================================================================================
	; SECTION HEADERS   –   https://learn.microsoft.com/en-us/windows/win32/debug/pe-format#section-table-section-headers
	;
	; The section data have to be 'loaded' to the relative virtual addresses defined in the section headers.
	; Otherwise, the RVAs defined in the export table don't match the corresponding data.
	; =======================================================================================================================================================================
	SectionsLength := SizeOfSectionHdr * NumberOfSections
	RawBytes := Buffer(SectionsLength, 0)
	DllFile.RawRead(RawBytes, SectionsLength) ; read the section headers
	ImageData := Buffer(SizeOfImage, 0) ; create a variable capable to store the sections data
	Offset := 0
	loop NumberOfSections
	{
		VirtualAddress   := NumGet(RawBytes, Offset + 12, "UInt") ; the address of the first byte of the section relative to the image base when the section is loaded into memory.
		SizeOfRawData    := NumGet(RawBytes, Offset + 16, "UInt")
		PointerToRawData := NumGet(RawBytes, Offset + 20, "UInt")
		DllFile.Pos      := PointerToRawData
		DllFile.RawRead(ImageData.Ptr + VirtualAddress, SizeOfRawData)
		Offset += SizeOfSectionHdr
	}


	; =======================================================================================================================================================================
	; EXPORT DIRECTORY TABLE   –   https://learn.microsoft.com/en-us/windows/win32/debug/pe-format#export-directory-table
	;
	; The export symbol information begins with the export directory table, which describes the remainder of the export symbol information.
	; The export directory table contains address information that is used to resolve imports to the entry points within this image.
	; =======================================================================================================================================================================
	ImageBase    := ImageData.Ptr ; the address of the string buffer of ImageData is used as image base address
	EndOfSection := ExportAddr + ExportSize
	ModNamePtr   := NumGet(ImageBase + ExportAddr + 12, "UInt") ; the address of the ASCII string that contains the name of the DLL
	OrdinalBase  := NumGet(ImageBase + ExportAddr + 16, "UInt") ; the starting ordinal number for exports in this image
	FuncCount    := NumGet(ImageBase + ExportAddr + 20, "UInt") ; the number of entries in the export address table
	NameCount    := NumGet(ImageBase + ExportAddr + 24, "UInt") ; the number of entries in the name pointer table
	FuncTblPtr   := NumGet(ImageBase + ExportAddr + 28, "UInt") ; the address of the export address table
	NameTblPtr   := NumGet(ImageBase + ExportAddr + 32, "UInt") ; the address of the export name pointer table
	OrdTblPtr    := NumGet(ImageBase + ExportAddr + 36, "UInt") ; the address of the ordinal table

	Exports := Map( "Module",   StrGet(ImageBase + ModNamePtr, "cp0")
	              , "Total",    FuncCount
	              , "Named",    NameCount
	              , "OrdBase",  OrdinalBase
	              , "Bitness",  (Magic = IMAGE_NT_OPTIONAL_HDR64_MAGIC) ? 64 : 32
	              , "Functions", Map() )

	loop NameCount
	{
		NamePtr := NumGet(ImageBase + NameTblPtr, "UInt")
		Ordinal := NumGet(ImageBase + OrdTblPtr, "UShort")
		FnAddr  := NumGet(ImageBase + FuncTblPtr + (Ordinal * 4), "UInt")
		EntryPt := (FnAddr > ExportAddr) && (FnAddr < EndOfSection)
				 ? StrGet(ImageBase + FnAddr, "cp0")
				 : Format("0x{:08x}", FnAddr)
		Exports["Functions"][A_Index] := Map( "Name",       StrGet(ImageBase + NamePtr, "cp0")
											, "EntryPoint", EntryPt
											, "Ordinal",    Ordinal + OrdinalBase )
		NameTblPtr += 4, OrdTblPtr += 2
	}

	return Exports
}

; ===========================================================================================================================================================================