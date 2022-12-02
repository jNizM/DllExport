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

	hIMAGEHLP := DllCall("LoadLibrary", "str", "imagehlp.dll", "ptr")

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
	DllCall("FreeLibrary", "ptr", hIMAGEHLP)
	Export.Names := Export.Functions.Length()
	return Export
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