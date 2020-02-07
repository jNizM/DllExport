; ===============================================================================================================================
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
; Authors..........: 'just me'
; ===============================================================================================================================

DllExportTable(DllPath)
{
	static LocSignatureOff  := 0x3c ; location of the file offset to the PE signature
	static SizeOfSignature  := 4    ; size of the PE signature
	static SizeOfCoffHdr    := 20   ; size of the COFF header
	static SizeOfSectionHdr := 40   ; size of a section header
	; Check the file path -------------------------------------------------------------------------------------------------------
	SplitPath, DllPath,,, FileExt
	if (FileExt <> "dll")
		return !(ErrorLevel := 1) ; invalid file extension
	; Open the file -------------------------------------------------------------------------------------------------------------
	if !(DllFile := FileOpen(DllPath, "r"))
		return !(ErrorLevel := 2) ; could not open the file for reading
	if (DllFile.Pos <> 0)                     
		return !(ErrorLevel := 3) ; AHK found a BOM, it isn't a DLL
	; MS-DOS header--------------------------------------------------------------------------------------------------------------
	DllFile.RawRead(RawBytes, 2)
	if !(StrGet(&RawBytes, 2, "cp0") == "MZ") 
		return !(ErrorLevel := 4) ; no MS-DOS stub
	; PE Signature --------------------------------------------------------------------------------------------------------------
	DllFile.Pos := LocSignatureOff
	DllFile.Pos := DllFile.Readuint() ; offset to the PE signature
	; Read the signature and advance the file pointer to the begin of the COFF header.
	DllFile.RawRead(RawBytes, SizeOfSignature)
	if !(StrGet(&RawBytes, SizeOfSignature, "cp0") == "PE")
		return !(ErrorLevel := 5) ; no PE file
	; COFF header ---------------------------------------------------------------------------------------------------------------
	; Machine types: IMAGE_FILE_MACHINE_I386 (x86) = 0x014C, IMAGE_FILE_MACHINE_AMD64 (x64) = 0x8664
	; Characteristics: IMAGE_FILE_DLL = 0x2000
	; Read the COFF file header and advance the file pointer to the begin of the optional header.
	DllFile.RawRead(RawBytes, SizeOfCoffHdr)
	Machine := NumGet(RawBytes, 0, "ushort") ; the type of the target machine
	if (Machine <> 0x014c) && (Machine <> 0x8664)
		return !(ErrorLevel := 6) ; wrong CPU type
	NumberOfSections := NumGet(RawBytes, 2, "ushort") ; the number of section headers
	SizeOfOptionalHeader := NumGet(RawBytes, 16, "ushort") ; the size of the optional header (required for DLL files)
	Characteristics := NumGet(RawBytes, 18, "ushort") ; the attributes of the file
	if !(Characteristics & 0x2000) ; IMAGE_FILE_DLL
		return !(ErrorLevel := 7) ; not a valid DLL file
	; Optional header -----------------------------------------------------------------------------------------------------------
	; PE format (magic number): PE32 (32-bit) = 0x010B, PE32+ (64-bit) = 0x020B
	; Read the optional header and advance the file pointer to the begin of the section headers.
	DllFile.RawRead(RawBytes, SizeOfOptionalHeader)
	Magic := NumGet(RawBytes, 0, "ushort") ; the state of the image file
	Off_64 := (Magic = 0x020b) ? 16 : 0 ; additional offset for 64-bit, zero for 32-bit
	SizeOfImage := NumGet(RawBytes, 56, "uint") ; the size of the image as loaded into memory
	OffSet := 92 + Off_64
	if ((NumberOfRvaAndSizes := NumGet(RawBytes, Offset + 0, "uint")) < 1) ; the number of data directory entries
	|| ((ExportAddr          := NumGet(RawBytes, Offset + 4, "uint")) < 1) ; the address of the export table (RVA)
	|| ((ExportSize          := NumGet(RawBytes, Offset + 8, "uint")) < 1) ; the size of the export table
		return !(ErrorLevel := 8) ; couldn't find an export table
	; Section headers -----------------------------------------------------------------------------------------------------------
	; The section data have to be 'loaded' to the relative virtual addresses defined in the section headers.
	; Otherwise, the RVAs defined in the export table don't match the corresponding data.
	; Read the section headers
	SectionsLength := SizeOfSectionHdr * NumberOfSections
	DllFile.RawRead(RawBytes, SectionsLength)
	; 'Load' the sections.
	VarSetCapacity(ImageData, SizeOfImage, 0) ; create a variable capable to store the sections data
	Offset := 0
	loop % NumberOfSections
	{
		VirtualAddress   := NumGet(RawBytes, Offset + 12, "uint")
		SizeOfRawData    := NumGet(RawBytes, Offset + 16, "uint")
		PointerToRawData := NumGet(RawBytes, Offset + 20, "uint")
		DllFile.Pos := PointerToRawData
		DllFile.RawRead(&ImageData + VirtualAddress, SizeOfRawData)
		Offset += SizeOfSectionHdr
	}
	; Export table --------------------------------------------------------------------------------------------------------------
	ImageBase    := &ImageData ; the address of the string buffer of ImageData is used as image base address.
	EndOfSection := ExportAddr + ExportSize
	ModNamePtr   := NumGet(ImageBase + ExportAddr + 0x0c, "uint") ; pointer to an ASCII string that contains the name of the DLL
	OrdinalBase  := NumGet(ImageBase + ExportAddr + 0x10, "uint") ; starting ordinal number for exports in this image
	FuncCount    := NumGet(ImageBase + ExportAddr + 0x14, "uint") ; number of entries in the export address table
	NameCount    := NumGet(ImageBase + ExportAddr + 0x18, "uint") ; number of entries in the name pointer table
	FuncTblPtr   := NumGet(ImageBase + ExportAddr + 0x1c, "uint") ; pointer to the export address table
	NameTblPtr   := NumGet(ImageBase + ExportAddr + 0x20, "uint") ; pointer to the export name pointer table
	OrdTblPtr    := NumGet(ImageBase + ExportAddr + 0x24, "uint") ; pointer to the ordinal table
	Exports      := { Module: StrGet(ImageBase + ModNamePtr, "cp0")
					, Total: FuncCount
					, Named: NameCount
					, OrdBase: OrdinalBase
					, Bitness: (Magic = 0x020b) ? 64 : 32
					, Functions: [] }
	loop % NameCount
	{
		NamePtr := NumGet(ImageBase + NameTblPtr, "uint")
		Ordinal := NumGet(ImageBase + OrdTblPtr, "ushort")
		FnAddr  := NumGet(ImageBase + FuncTblPtr + (Ordinal * 4), "uint")
		EntryPt := (FnAddr > ExportAddr) && (FnAddr < EndOfSection) ? StrGet(ImageBase + FnAddr, "cp0") : Format("0x{:08x}", FnAddr)
		Exports.Functions.Push({ Name: StrGet(ImageBase + NamePtr, "cp0"), EntryPoint: EntryPt, Ordinal: Ordinal + OrdinalBase })
		NameTblPtr += 4, OrdTblPtr += 2
	}
	VarSetCapacity(ImageData, 0) ; free the memory used to store the image data
	return Exports
}

; ===============================================================================================================================