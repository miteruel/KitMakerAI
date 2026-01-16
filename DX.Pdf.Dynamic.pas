{*******************************************************************************

//
// Donado por  Antonio Alcázar al proyecto MakerAI
//
// - GitHub: https://github.com/gustavoeenriquez/


Esta unidad esta modificada para poder usar la libreria  pdfium, de forma dinamica



  Unit: DX.Pdf.API


  Part of DX Pdfium4D - Delphi Cross-Platform Wrapper für Pdfium
  https://github.com/omonien/DX-Pdfium4D

  Description:
    Platform-independent PDFium C-API bindings for Delphi.
    Provides low-level bindings to the PDFium library.
    For high-level object-oriented access, use DX.Pdf.Document instead.

  Based on:
    PDFium from https://pdfium.googlesource.com/pdfium/
    Binaries from https://github.com/bblanchon/pdfium-binaries

  Author: Olaf Monien
  Copyright (c) 2025 Olaf Monien
  License: MIT - see LICENSE file

  MIT License

Copyright (c) 2025 Olaf Monien

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*******************************************************************************}
unit DX.Pdf.Dynamic;


interface

uses
    FMX.Graphics,
  System.Classes,
  System.Types,
  System.UITypes,

  System.SysUtils
  {$IFDEF MSWINDOWS}
  , Winapi.Windows
  {$ENDIF}
  ;

const
  {$IFDEF MSWINDOWS}
    {$IFDEF WIN64}
      PDFIUM_DLL = 'pdfium.dll';
    {$ELSE}
      PDFIUM_DLL = 'pdfium.dll';
    {$ENDIF}
  {$ENDIF}
  {$IFDEF MACOS}
    {$IFDEF CPUARM64}
      PDFIUM_DLL = 'libpdfium.dylib';
    {$ELSE}
      PDFIUM_DLL = 'libpdfium.dylib';
    {$ENDIF}
  {$ENDIF}
  {$IFDEF LINUX}
    PDFIUM_DLL = 'libpdfium.so';
  {$ENDIF}
  {$IFDEF ANDROID}
    PDFIUM_DLL = 'libpdfium.so';
  {$ENDIF}
  {$IFDEF IOS}
    PDFIUM_DLL = 'libpdfium.dylib';
  {$ENDIF}

  // Error codes
  FPDF_ERR_SUCCESS = 0;
  FPDF_ERR_UNKNOWN = 1;
  FPDF_ERR_FILE = 2;
  FPDF_ERR_FORMAT = 3;
  FPDF_ERR_PASSWORD = 4;
  FPDF_ERR_SECURITY = 5;
  FPDF_ERR_PAGE = 6;

  // Render flags
  FPDF_ANNOT = $01;
  FPDF_LCD_TEXT = $02;
  FPDF_NO_NATIVETEXT = $04;
  FPDF_GRAYSCALE = $08;
  FPDF_DEBUG_INFO = $80;
  FPDF_NO_CATCH = $100;
  FPDF_RENDER_LIMITEDIMAGECACHE = $200;
  FPDF_RENDER_FORCEHALFTONE = $400;
  FPDF_PRINTING = $800;
  FPDF_RENDER_NO_SMOOTHTEXT = $1000;
  FPDF_RENDER_NO_SMOOTHIMAGE = $2000;
  FPDF_RENDER_NO_SMOOTHPATH = $4000;
  FPDF_REVERSE_BYTE_ORDER = $10;

  // Page rotation
  FPDF_ROTATE_0 = 0;
  FPDF_ROTATE_90 = 1;
  FPDF_ROTATE_180 = 2;
  FPDF_ROTATE_270 = 3;

  // Bitmap formats
  FPDFBitmap_Unknown = 0;
  FPDFBitmap_Gray = 1;
  FPDFBitmap_BGR = 2;
  FPDFBitmap_BGRx = 3;
  FPDFBitmap_BGRA = 4;

type
  // Opaque types (pointers to internal PDFium structures)
  FPDF_DOCUMENT = type Pointer;
  FPDF_PAGE = type Pointer;
  FPDF_BITMAP = type Pointer;
  FPDF_TEXTPAGE = type Pointer;
  FPDF_PAGELINK = type Pointer;
  FPDF_SCHHANDLE = type Pointer;
  FPDF_BOOKMARK = type Pointer;
  FPDF_DEST = type Pointer;
  FPDF_ACTION = type Pointer;
  FPDF_LINK = type Pointer;

  // Basic types
  FPDF_BOOL = type Integer;
  FPDF_DWORD = type Cardinal;
  FPDF_WCHAR = type Word;
  FPDF_BYTESTRING = type PAnsiChar;
  FPDF_WIDESTRING = type PWideChar;
  FPDF_STRING = type PAnsiChar;

  // Structures
  PFS_MATRIX = ^FS_MATRIX;
  FS_MATRIX = record
    A: Single;
    B: Single;
    C: Single;
    D: Single;
    E: Single;
    F: Single;
  end;

  PFS_RECTF = ^FS_RECTF;
  FS_RECTF = record
    Left: Single;
    Top: Single;
    Right: Single;
    Bottom: Single;
  end;

  PFS_SIZEF = ^FS_SIZEF;
  FS_SIZEF = record
    Width: Single;
    Height: Single;
  end;

  PFS_POINTF = ^FS_POINTF;
  FS_POINTF = record
    X: Single;
    Y: Single;
  end;

  PFPDF_LIBRARY_CONFIG = ^FPDF_LIBRARY_CONFIG;
  FPDF_LIBRARY_CONFIG = record
    Version: Integer;
    UserFontPaths: PPAnsiChar;
    Isolate: Pointer;
    V8EmbedderSlot: Cardinal;
  end;

  // Callback function for custom file access
  TFPDFFileAccessGetBlock = function(param: Pointer; position: Cardinal;
    pBuf: PByte; size: Cardinal): Integer; cdecl;

  // Structure for custom file access (streaming support)
  PFPDF_FILEACCESS = ^FPDF_FILEACCESS;
  FPDF_FILEACCESS = record
    m_FileLen: Cardinal;
    m_GetBlock: TFPDFFileAccessGetBlock;
    m_Param: Pointer;
  end;

  // Function types for dynamic loading
  TFPDF_InitLibrary = procedure; cdecl;
  TFPDF_InitLibraryWithConfig = procedure(const AConfig: PFPDF_LIBRARY_CONFIG); cdecl;
  TFPDF_DestroyLibrary = procedure; cdecl;
  TFPDF_GetLastError = function: Cardinal; cdecl;
  TFPDF_LoadDocument = function(const AFilePath: FPDF_STRING; const APassword: FPDF_BYTESTRING): FPDF_DOCUMENT; cdecl;
  TFPDF_LoadMemDocument = function(const ADataBuf: Pointer; ASize: Integer; const APassword: FPDF_BYTESTRING): FPDF_DOCUMENT; cdecl;
  TFPDF_LoadCustomDocument = function(pFileAccess: PFPDF_FILEACCESS; const APassword: FPDF_BYTESTRING): FPDF_DOCUMENT; cdecl;
  TFPDF_CloseDocument = procedure(ADocument: FPDF_DOCUMENT); cdecl;
  TFPDF_GetPageCount = function(ADocument: FPDF_DOCUMENT): Integer; cdecl;
  TFPDF_GetFileVersion = function(ADocument: FPDF_DOCUMENT; var AFileVersion: Integer): FPDF_BOOL; cdecl;
  TFPDF_GetPageSizeByIndex = function(ADocument: FPDF_DOCUMENT; APageIndex: Integer; out AWidth: Double; out AHeight: Double): FPDF_BOOL; cdecl;
  TFPDF_GetMetaText = function(ADocument: FPDF_DOCUMENT; const ATag: FPDF_BYTESTRING; ABuffer: Pointer; ABufLen: Cardinal): Cardinal; cdecl;
  TFPDF_LoadPage = function(ADocument: FPDF_DOCUMENT; APageIndex: Integer): FPDF_PAGE; cdecl;
  TFPDF_ClosePage = procedure(APage: FPDF_PAGE); cdecl;
  TFPDF_GetPageWidth = function(APage: FPDF_PAGE): Double; cdecl;
  TFPDF_GetPageHeight = function(APage: FPDF_PAGE): Double; cdecl;
  TFPDFPage_GetRotation = function(APage: FPDF_PAGE): Integer; cdecl;
  TFPDFBitmap_Create = function(AWidth: Integer; AHeight: Integer; AAlpha: Integer): FPDF_BITMAP; cdecl;
  TFPDFBitmap_CreateEx = function(AWidth: Integer; AHeight: Integer; AFormat: Integer; AFirstScan: Pointer; AStride: Integer): FPDF_BITMAP; cdecl;
  TFPDFBitmap_Destroy = procedure(ABitmap: FPDF_BITMAP); cdecl;
  TFPDFBitmap_GetBuffer = function(ABitmap: FPDF_BITMAP): Pointer; cdecl;
  TFPDFBitmap_GetWidth = function(ABitmap: FPDF_BITMAP): Integer; cdecl;
  TFPDFBitmap_GetHeight = function(ABitmap: FPDF_BITMAP): Integer; cdecl;
  TFPDFBitmap_GetStride = function(ABitmap: FPDF_BITMAP): Integer; cdecl;
  TFPDFBitmap_FillRect = procedure(ABitmap: FPDF_BITMAP; ALeft: Integer; ATop: Integer; AWidth: Integer; AHeight: Integer; AColor: FPDF_DWORD); cdecl;
  TFPDF_RenderPageBitmap = procedure(ABitmap: FPDF_BITMAP; APage: FPDF_PAGE; AStartX: Integer; AStartY: Integer; ASizeX: Integer; ASizeY: Integer; ARotate: Integer; AFlags: Integer); cdecl;
  {$IFDEF MSWINDOWS}
  TFPDF_RenderPage = procedure(ADC: HDC; APage: FPDF_PAGE; AStartX: Integer; AStartY: Integer; ASizeX: Integer; ASizeY: Integer; ARotate: Integer; AFlags: Integer); cdecl;
  {$ENDIF}
  TFPDFText_LoadPage = function(APage: FPDF_PAGE): FPDF_TEXTPAGE; cdecl;
  TFPDFText_ClosePage = procedure(ATextPage: FPDF_TEXTPAGE); cdecl;
  TFPDFText_CountChars = function(ATextPage: FPDF_TEXTPAGE): Integer; cdecl;
  TFPDFText_GetUnicode = function(ATextPage: FPDF_TEXTPAGE; AIndex: Integer): Cardinal; cdecl;
  TFPDFText_GetText = function(ATextPage: FPDF_TEXTPAGE; AStartIndex: Integer; ACount: Integer; AResult: PWideChar): Integer; cdecl;
  TFPDFBookmark_GetFirstChild = function(ADocument: FPDF_DOCUMENT; ABookmark: FPDF_BOOKMARK): FPDF_BOOKMARK; cdecl;
  TFPDFBookmark_GetNextSibling = function(ADocument: FPDF_DOCUMENT; ABookmark: FPDF_BOOKMARK): FPDF_BOOKMARK; cdecl;
  TFPDFBookmark_GetTitle = function(ABookmark: FPDF_BOOKMARK; ABuffer: Pointer; ABufLen: Cardinal): Cardinal; cdecl;
  TFPDFBookmark_GetDest = function(ADocument: FPDF_DOCUMENT; ABookmark: FPDF_BOOKMARK): FPDF_DEST; cdecl;

var
  // Function pointers
  FPDF_InitLibrary: TFPDF_InitLibrary = nil;
  FPDF_InitLibraryWithConfig: TFPDF_InitLibraryWithConfig = nil;
  FPDF_DestroyLibrary: TFPDF_DestroyLibrary = nil;
  FPDF_GetLastError: TFPDF_GetLastError = nil;
  FPDF_LoadDocument: TFPDF_LoadDocument = nil;
  FPDF_LoadMemDocument: TFPDF_LoadMemDocument = nil;
  FPDF_LoadCustomDocument: TFPDF_LoadCustomDocument = nil;
  FPDF_CloseDocument: TFPDF_CloseDocument = nil;
  FPDF_GetPageCount: TFPDF_GetPageCount = nil;
  FPDF_GetFileVersion: TFPDF_GetFileVersion = nil;
  FPDF_GetPageSizeByIndex: TFPDF_GetPageSizeByIndex = nil;
  FPDF_GetMetaText: TFPDF_GetMetaText = nil;
  FPDF_LoadPage: TFPDF_LoadPage = nil;
  FPDF_ClosePage: TFPDF_ClosePage = nil;
  FPDF_GetPageWidth: TFPDF_GetPageWidth = nil;
  FPDF_GetPageHeight: TFPDF_GetPageHeight = nil;
  FPDFPage_GetRotation: TFPDFPage_GetRotation = nil;
  FPDFBitmap_Create: TFPDFBitmap_Create = nil;
  FPDFBitmap_CreateEx: TFPDFBitmap_CreateEx = nil;
  FPDFBitmap_Destroy: TFPDFBitmap_Destroy = nil;
  FPDFBitmap_GetBuffer: TFPDFBitmap_GetBuffer = nil;
  FPDFBitmap_GetWidth: TFPDFBitmap_GetWidth = nil;
  FPDFBitmap_GetHeight: TFPDFBitmap_GetHeight = nil;
  FPDFBitmap_GetStride: TFPDFBitmap_GetStride = nil;
  FPDFBitmap_FillRect: TFPDFBitmap_FillRect = nil;
  FPDF_RenderPageBitmap: TFPDF_RenderPageBitmap = nil;
  {$IFDEF MSWINDOWS}
  FPDF_RenderPage: TFPDF_RenderPage = nil;
  {$ENDIF}
  FPDFText_LoadPage: TFPDFText_LoadPage = nil;
  FPDFText_ClosePage: TFPDFText_ClosePage = nil;
  FPDFText_CountChars: TFPDFText_CountChars = nil;
  FPDFText_GetUnicode: TFPDFText_GetUnicode = nil;
  FPDFText_GetText_: TFPDFText_GetText = nil;
  FPDFBookmark_GetFirstChild: TFPDFBookmark_GetFirstChild = nil;
  FPDFBookmark_GetNextSibling: TFPDFBookmark_GetNextSibling = nil;
  FPDFBookmark_GetTitle: TFPDFBookmark_GetTitle = nil;
  FPDFBookmark_GetDest: TFPDFBookmark_GetDest = nil;

// Load/Unload functions
function LoadPDFiumLibrary(const ADllPath: string = ''): Boolean;
procedure UnloadPDFiumLibrary;
function IsPDFiumLoaded: Boolean;

// Helper functions
function FPDF_BoolToBoolean(AValue: FPDF_BOOL): Boolean; inline;
function BooleanToFPDF_Bool(AValue: Boolean): FPDF_BOOL; inline;
function FPDF_ErrorToString(AError: Cardinal): string;



type
  EPdfException = class(Exception);
  EPdfLoadException = class(EPdfException);
  EPdfPageException = class(EPdfException);
  EPdfRenderException = class(EPdfException);

  TPdfPage = class;
  TPdfDocument = class;
  TPdfStreamAdapter = class;

  /// <summary>
  /// Adapter class that bridges TStream to PDFium's FPDF_FILEACCESS interface
  /// Enables true streaming support without loading entire PDF into memory
  /// </summary>
  TPdfStreamAdapter = class
  private
    FStream: TStream;
    FFileAccess: FPDF_FILEACCESS;
    FOwnsStream: Boolean;
    class function GetBlockCallback(param: Pointer; position: Cardinal;
      pBuf: PByte; size: Cardinal): Integer; cdecl; static;
  public
    constructor Create(AStream: TStream; AOwnsStream: Boolean = False);
    destructor Destroy; override;

    property FileAccess: FPDF_FILEACCESS read FFileAccess;
    property Stream: TStream read FStream;
  end;

  /// <summary>
  /// Represents a single page in a PDF document
  /// </summary>
  TPdfPage = class
  private
    FDocument: TPdfDocument;
    FHandle: FPDF_PAGE;
    FPageIndex: Integer;
    FWidth: Double;
    FHeight: Double;
    function GetRotation: Integer;
  public
    constructor Create(ADocument: TPdfDocument; APageIndex: Integer);
    destructor Destroy; override;

    /// <summary>
    /// Page index (0-based)
    /// </summary>
    property PageIndex: Integer read FPageIndex;

    /// <summary>
    /// Page width in points (1/72 inch)
    /// </summary>
    property Width: Double read FWidth;

    /// <summary>
    /// Page height in points (1/72 inch)
    /// </summary>
    property Height: Double read FHeight;

    /// <summary>
    /// Page rotation (0, 90, 180, or 270 degrees)
    /// </summary>
    property Rotation: Integer read GetRotation;

    /// <summary>
    /// Internal PDFium page handle
    /// </summary>
    property Handle: FPDF_PAGE read FHandle;
  end;

  /// <summary>
  /// Represents a PDF document
  /// </summary>
  TPdfDocument = class
  private
    FHandle: FPDF_DOCUMENT;
    FPageCount: Integer;
    FFileName: string;
    FStreamAdapter: TPdfStreamAdapter; // Stream adapter must remain valid while document is open!
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    /// Loads a PDF document from a file
    /// </summary>
    procedure LoadFromFile(const AFileName: string; const APassword: string = '');

    /// <summary>
    /// Loads a PDF document from a stream with efficient streaming support
    /// </summary>
    /// <remarks>
    /// This method uses PDFium's custom file access API for efficient streaming.
    /// The stream is NOT loaded entirely into memory - PDFium reads blocks on demand.
    /// The stream must remain valid and seekable for the lifetime of the document.
    /// Ideal for large PDFs, network streams, or memory-constrained scenarios.
    /// </remarks>
    /// <param name="AStream">Source stream (must support seeking)</param>
    /// <param name="AOwnsStream">If true, the document takes ownership and will free the stream on Close</param>
    /// <param name="APassword">Optional password for encrypted PDFs</param>
    procedure LoadFromStream(AStream: TStream; AOwnsStream: Boolean = False; const APassword: string = '');

    /// <summary>
    /// Closes the currently loaded document
    /// </summary>
    procedure Close;

    /// <summary>
    /// Checks if a document is currently loaded
    /// </summary>
    function IsLoaded: Boolean;

    /// <summary>
    /// Gets a page by index (0-based). Caller is responsible for freeing the page.
    /// </summary>
    function GetPageByIndex(AIndex: Integer): TPdfPage;

    /// <summary>
    /// Gets the PDF file version (e.g., 14 for PDF 1.4, 17 for PDF 1.7)
    /// </summary>
    function GetFileVersion: Integer;

    /// <summary>
    /// Gets the PDF version as a string (e.g., "1.4", "1.7")
    /// </summary>
    function GetFileVersionString: string;

    /// <summary>
    /// Gets metadata from the PDF document (Title, Author, Subject, Keywords, Creator, Producer, CreationDate, ModDate)
    /// </summary>
    function GetMetadata(const ATag: string): string;

    /// <summary>
    /// Checks if the document is PDF/A compliant and returns the version (e.g., "PDF/A-1b", "PDF/A-2u")
    /// </summary>
    function GetPdfAInfo: string;

    /// <summary>
    /// Number of pages in the document
    /// </summary>
    property PageCount: Integer read FPageCount;

    /// <summary>
    /// File name of the loaded document
    /// </summary>
    property FileName: string read FFileName;

    /// <summary>
    /// Internal PDFium document handle
    /// </summary>
    property Handle: FPDF_DOCUMENT read FHandle;
  end;

  /// <summary>
  /// Global PDFium library manager (singleton)
  /// </summary>
  TPdfLibrary = class
  private
    class var FInstance: TPdfLibrary;
    class var FInitialized: Boolean;
    class var FReferenceCount: Integer;
    class function GetInstance: TPdfLibrary; static;
  public
    class constructor Create;
    class destructor Destroy;

    /// <summary>
    /// Initializes the PDFium library
    /// </summary>
    class procedure Initialize;

    /// <summary>
    /// Shuts down the PDFium library
    /// </summary>
    class procedure Finalize;

    /// <summary>
    /// Checks if the library is initialized
    /// </summary>
    class function IsInitialized: Boolean;

    /// <summary>
    /// Singleton instance
    /// </summary>
    class property Instance: TPdfLibrary read GetInstance;
  end;


  type
  /// <summary>
  /// FMX-specific PDF page renderer
  /// </summary>
  TPdfPageRendererFMX = class helper for TPdfPage
  public
    /// <summary>
    /// Renders the page to an FMX bitmap
    /// </summary>
    procedure RenderToBitmap(ABitmap: FMX.Graphics.TBitmap; ABackgroundColor: TAlphaColor = TAlphaColors.White);
  end;
var
  PDFiumHandle: {$IFDEF MSWINDOWS}HMODULE{$ELSE}NativeUInt{$ENDIF} = 0;


implementation

uses   System.IOUtils;


function LoadPDFiumLibrary(const ADllPath: string = ''): Boolean;
var
 fulldll,  LDllPath: string;
begin
  Result := False;

  if PDFiumHandle <> 0 then
    Exit(True); // Ya está cargada

  if ADllPath <> '' then
    LDllPath := ADllPath
  else
    LDllPath := PDFIUM_DLL;

  {$IFDEF MSWINDOWS}
  PDFiumHandle := LoadLibrary(PChar(LDllPath));
  {$ELSE}
  fulldll:=TPath.GetDocumentsPath + TPath.DirectorySeparatorChar +LDllPath;
  if FileExists(fulldll) then
  begin

  PDFiumHandle := SafeLoadLibrary(fulldll);
  end;
  {$ENDIF}
     //               SafeLoadLibrary(VoskLibName);


  if PDFiumHandle = 0 then
    Exit;

  try
    // Cargar todas las funciones
    @FPDF_InitLibrary := GetProcAddress(PDFiumHandle, 'FPDF_InitLibrary');
    @FPDF_InitLibraryWithConfig := GetProcAddress(PDFiumHandle, 'FPDF_InitLibraryWithConfig');
    @FPDF_DestroyLibrary := GetProcAddress(PDFiumHandle, 'FPDF_DestroyLibrary');
    @FPDF_GetLastError := GetProcAddress(PDFiumHandle, 'FPDF_GetLastError');
    @FPDF_LoadDocument := GetProcAddress(PDFiumHandle, 'FPDF_LoadDocument');
    @FPDF_LoadMemDocument := GetProcAddress(PDFiumHandle, 'FPDF_LoadMemDocument');
    @FPDF_LoadCustomDocument := GetProcAddress(PDFiumHandle, 'FPDF_LoadCustomDocument');
    @FPDF_CloseDocument := GetProcAddress(PDFiumHandle, 'FPDF_CloseDocument');
    @FPDF_GetPageCount := GetProcAddress(PDFiumHandle, 'FPDF_GetPageCount');
    @FPDF_GetFileVersion := GetProcAddress(PDFiumHandle, 'FPDF_GetFileVersion');
    @FPDF_GetPageSizeByIndex := GetProcAddress(PDFiumHandle, 'FPDF_GetPageSizeByIndex');
    @FPDF_GetMetaText := GetProcAddress(PDFiumHandle, 'FPDF_GetMetaText');
    @FPDF_LoadPage := GetProcAddress(PDFiumHandle, 'FPDF_LoadPage');
    @FPDF_ClosePage := GetProcAddress(PDFiumHandle, 'FPDF_ClosePage');
    @FPDF_GetPageWidth := GetProcAddress(PDFiumHandle, 'FPDF_GetPageWidth');
    @FPDF_GetPageHeight := GetProcAddress(PDFiumHandle, 'FPDF_GetPageHeight');
    @FPDFPage_GetRotation := GetProcAddress(PDFiumHandle, 'FPDFPage_GetRotation');
    @FPDFBitmap_Create := GetProcAddress(PDFiumHandle, 'FPDFBitmap_Create');
    @FPDFBitmap_CreateEx := GetProcAddress(PDFiumHandle, 'FPDFBitmap_CreateEx');
    @FPDFBitmap_Destroy := GetProcAddress(PDFiumHandle, 'FPDFBitmap_Destroy');
    @FPDFBitmap_GetBuffer := GetProcAddress(PDFiumHandle, 'FPDFBitmap_GetBuffer');
    @FPDFBitmap_GetWidth := GetProcAddress(PDFiumHandle, 'FPDFBitmap_GetWidth');
    @FPDFBitmap_GetHeight := GetProcAddress(PDFiumHandle, 'FPDFBitmap_GetHeight');
    @FPDFBitmap_GetStride := GetProcAddress(PDFiumHandle, 'FPDFBitmap_GetStride');
    @FPDFBitmap_FillRect := GetProcAddress(PDFiumHandle, 'FPDFBitmap_FillRect');
    @FPDF_RenderPageBitmap := GetProcAddress(PDFiumHandle, 'FPDF_RenderPageBitmap');
    {$IFDEF MSWINDOWS}
    @FPDF_RenderPage := GetProcAddress(PDFiumHandle, 'FPDF_RenderPage');
    {$ENDIF}
    @FPDFText_LoadPage := GetProcAddress(PDFiumHandle, 'FPDFText_LoadPage');
    @FPDFText_ClosePage := GetProcAddress(PDFiumHandle, 'FPDFText_ClosePage');
    @FPDFText_CountChars := GetProcAddress(PDFiumHandle, 'FPDFText_CountChars');
    @FPDFText_GetUnicode := GetProcAddress(PDFiumHandle, 'FPDFText_GetUnicode');
    @FPDFText_GetText_ := GetProcAddress(PDFiumHandle, 'FPDFText_GetText');
    @FPDFBookmark_GetFirstChild := GetProcAddress(PDFiumHandle, 'FPDFBookmark_GetFirstChild');
    @FPDFBookmark_GetNextSibling := GetProcAddress(PDFiumHandle, 'FPDFBookmark_GetNextSibling');
    @FPDFBookmark_GetTitle := GetProcAddress(PDFiumHandle, 'FPDFBookmark_GetTitle');
    @FPDFBookmark_GetDest := GetProcAddress(PDFiumHandle, 'FPDFBookmark_GetDest');

    // Verificar que al menos las funciones críticas se cargaron
    Result := Assigned(FPDF_InitLibrary) and
              Assigned(FPDF_DestroyLibrary) and
              Assigned(FPDF_LoadDocument);

    if not Result then
    begin
      UnloadPDFiumLibrary;
    end;
  except
    UnloadPDFiumLibrary;
    raise;
  end;
end;

procedure UnloadPDFiumLibrary;
begin
  if PDFiumHandle <> 0 then
  begin
    {$IFDEF MSWINDOWS}
    FreeLibrary(PDFiumHandle);
    {$ELSE}
    FreeLibrary(PDFiumHandle);
    {$ENDIF}
    PDFiumHandle := 0;

    // Limpiar punteros
    FPDF_InitLibrary := nil;
    FPDF_InitLibraryWithConfig := nil;
    FPDF_DestroyLibrary := nil;
    FPDF_GetLastError := nil;
    FPDF_LoadDocument := nil;
    FPDF_LoadMemDocument := nil;
    FPDF_LoadCustomDocument := nil;
    FPDF_CloseDocument := nil;
    FPDF_GetPageCount := nil;
    FPDF_GetFileVersion := nil;
    FPDF_GetPageSizeByIndex := nil;
    FPDF_GetMetaText := nil;
    FPDF_LoadPage := nil;
    FPDF_ClosePage := nil;
    FPDF_GetPageWidth := nil;
    FPDF_GetPageHeight := nil;
    FPDFPage_GetRotation := nil;
    FPDFBitmap_Create := nil;
    FPDFBitmap_CreateEx := nil;
    FPDFBitmap_Destroy := nil;
    FPDFBitmap_GetBuffer := nil;
    FPDFBitmap_GetWidth := nil;
    FPDFBitmap_GetHeight := nil;
    FPDFBitmap_GetStride := nil;
    FPDFBitmap_FillRect := nil;
    FPDF_RenderPageBitmap := nil;
    {$IFDEF MSWINDOWS}
    FPDF_RenderPage := nil;
    {$ENDIF}
    FPDFText_LoadPage := nil;
    FPDFText_ClosePage := nil;
    FPDFText_CountChars := nil;
    FPDFText_GetUnicode := nil;
    FPDFText_GetText_ := nil;
    FPDFBookmark_GetFirstChild := nil;
    FPDFBookmark_GetNextSibling := nil;
    FPDFBookmark_GetTitle := nil;
    FPDFBookmark_GetDest := nil;
  end;
end;

function IsPDFiumLoaded: Boolean;
begin
  Result := PDFiumHandle <> 0;
end;

function FPDF_BoolToBoolean(AValue: FPDF_BOOL): Boolean;
begin
  Result := AValue <> 0;
end;

function BooleanToFPDF_Bool(AValue: Boolean): FPDF_BOOL;
begin
  if AValue then
    Result := 1
  else
    Result := 0;
end;

function FPDF_ErrorToString(AError: Cardinal): string;
begin
  case AError of
    FPDF_ERR_SUCCESS: Result := 'Success';
    FPDF_ERR_UNKNOWN: Result := 'Unknown error';
    FPDF_ERR_FILE: Result := 'File not found or could not be opened';
    FPDF_ERR_FORMAT: Result := 'File not in PDF format or corrupted';
    FPDF_ERR_PASSWORD: Result := 'Password required or incorrect password';
    FPDF_ERR_SECURITY: Result := 'Unsupported security scheme';
    FPDF_ERR_PAGE: Result := 'Page not found or content error';
  else
    Result := 'Unknown error code: ' + AError.ToString;
  end;
end;


{ TPdfStreamAdapter }

constructor TPdfStreamAdapter.Create(AStream: TStream; AOwnsStream: Boolean);
begin
  inherited Create;
  FStream := AStream;
  FOwnsStream := AOwnsStream;

  // Initialize FPDF_FILEACCESS structure
  FFileAccess.m_FileLen := FStream.Size;
  FFileAccess.m_GetBlock := GetBlockCallback;
  FFileAccess.m_Param := Self;  // Pass Self as user data to callback
end;

destructor TPdfStreamAdapter.Destroy;
begin
  if FOwnsStream then
    FStream.Free;
  inherited;
end;

class function TPdfStreamAdapter.GetBlockCallback(param: Pointer; position: Cardinal;
  pBuf: PByte; size: Cardinal): Integer;
var
  LAdapter: TPdfStreamAdapter;
  LBytesRead: Integer;
begin
  Result := 0;  // Default: error

  if param = nil then
    Exit;

  LAdapter := TPdfStreamAdapter(param);

  try
    // Seek to requested position
    LAdapter.FStream.Position := position;

    // Read requested block
    LBytesRead := LAdapter.FStream.Read(pBuf^, size);

    // Return success if we read the expected amount
    if LBytesRead = Integer(size) then
      Result := 1  // Success
    else
      Result := 0; // Error: couldn't read full block
  except
    // Any exception = error
    Result := 0;
  end;
end;

{ TPdfLibrary }

class constructor TPdfLibrary.Create;
begin
  FInstance := nil;
  FInitialized := False;
  FReferenceCount := 0;
end;

class destructor TPdfLibrary.Destroy;
begin
  if FInitialized then
    Finalize;
  FreeAndNil(FInstance);
end;

class function TPdfLibrary.GetInstance: TPdfLibrary;
begin
  if FInstance = nil then
    FInstance := TPdfLibrary.Create;
  Result := FInstance;
end;

class procedure TPdfLibrary.Initialize;
begin
  if not FInitialized then
  begin
    FPDF_InitLibrary;
    FInitialized := True;
  end;
  Inc(FReferenceCount);
end;

class procedure TPdfLibrary.Finalize;
begin
  Dec(FReferenceCount);
  if (FReferenceCount <= 0) and FInitialized then
  begin
    FPDF_DestroyLibrary;
    FInitialized := False;
    FReferenceCount := 0;
  end;
end;

class function TPdfLibrary.IsInitialized: Boolean;
begin
  Result := FInitialized;
end;

{ TPdfDocument }

constructor TPdfDocument.Create;
begin
  inherited Create;
  FHandle := nil;
  FPageCount := 0;
  FFileName := '';
  FStreamAdapter := nil;
  TPdfLibrary.Initialize;
end;

destructor TPdfDocument.Destroy;
begin
  Close;
  TPdfLibrary.Finalize;
  inherited;
end;

procedure TPdfDocument.LoadFromFile(const AFileName: string; const APassword: string = '');
var
  LPasswordAnsi: AnsiString;
  LFilePathUtf8: UTF8String;
  LError: Cardinal;
begin
  Close;

  if not FileExists(AFileName) then
    raise EPdfLoadException.CreateFmt('File not found: %s', [AFileName]);

  LFilePathUtf8 := UTF8String(AFileName);
  if APassword <> '' then
    LPasswordAnsi := AnsiString(APassword)
  else
    LPasswordAnsi := '';

  FHandle := FPDF_LoadDocument(FPDF_STRING(PAnsiChar(LFilePathUtf8)), FPDF_BYTESTRING(PAnsiChar(LPasswordAnsi)));

  if FHandle = nil then
  begin
    LError := FPDF_GetLastError;
    raise EPdfLoadException.CreateFmt('Failed to load PDF: %s (%s)', [AFileName, FPDF_ErrorToString(LError)]);
  end;

  FFileName := AFileName;
  FPageCount := FPDF_GetPageCount(FHandle);
end;

procedure TPdfDocument.LoadFromStream(AStream: TStream; AOwnsStream: Boolean; const APassword: string);
var
  LPasswordAnsi: AnsiString;
  LError: Cardinal;
begin
  Close;

  if AStream = nil then
    raise EPdfLoadException.Create('Stream is nil');

  // Create stream adapter for PDFium's custom file access
  FStreamAdapter := TPdfStreamAdapter.Create(AStream, AOwnsStream);

  if APassword <> '' then
    LPasswordAnsi := AnsiString(APassword)
  else
    LPasswordAnsi := '';

  // Load using custom document API - enables true streaming!
  FHandle := FPDF_LoadCustomDocument(@FStreamAdapter.FFileAccess, FPDF_BYTESTRING(PAnsiChar(LPasswordAnsi)));

  if FHandle = nil then
  begin
    LError := FPDF_GetLastError;
    FreeAndNil(FStreamAdapter);  // Clean up on error
    raise EPdfLoadException.CreateFmt('Failed to load PDF from stream: %s', [FPDF_ErrorToString(LError)]);
  end;

  FFileName := '';
  FPageCount := FPDF_GetPageCount(FHandle);
end;

procedure TPdfDocument.Close;
begin
  if FHandle <> nil then
  begin
    FPDF_CloseDocument(FHandle);
    FHandle := nil;
    FPageCount := 0;
    FFileName := '';
  end;
  FreeAndNil(FStreamAdapter);   // Free stream adapter (and optionally the stream)
end;

function TPdfDocument.IsLoaded: Boolean;
begin
  Result := FHandle <> nil;
end;

function TPdfDocument.GetPageByIndex(AIndex: Integer): TPdfPage;
begin
  if not IsLoaded then
    raise EPdfPageException.Create('No document loaded');

  if (AIndex < 0) or (AIndex >= FPageCount) then
    raise EPdfPageException.CreateFmt('Page index out of range: %d (valid range: 0-%d)', [AIndex, FPageCount - 1]);

  Result := TPdfPage.Create(Self, AIndex);
end;

function TPdfDocument.GetFileVersion: Integer;
var
  LVersion: Integer;
begin
  Result := 0;
  if IsLoaded then
  begin
    if FPDF_BoolToBoolean(FPDF_GetFileVersion(FHandle, LVersion)) then
      Result := LVersion;
  end;
end;

function TPdfDocument.GetFileVersionString: string;
var
  LVersion: Integer;
begin
  LVersion := GetFileVersion;
  if LVersion > 0 then
    Result := Format('%d.%d', [LVersion div 10, LVersion mod 10])
  else
    Result := 'Unknown';
end;

function TPdfDocument.GetMetadata(const ATag: string): string;
var
  LBufLen: Cardinal;
  LBuffer: array of WideChar;
  LTagAnsi: AnsiString;
begin
  Result := '';
  if not IsLoaded then
    Exit;

  LTagAnsi := AnsiString(ATag);

  // Get required buffer size
  LBufLen := FPDF_GetMetaText(FHandle, FPDF_BYTESTRING(PAnsiChar(LTagAnsi)), nil, 0);
  if LBufLen <= 2 then // Empty or just null terminator
    Exit;

  // Allocate buffer and get metadata (UTF-16LE encoded)
  SetLength(LBuffer, LBufLen div 2);
  FPDF_GetMetaText(FHandle, FPDF_BYTESTRING(PAnsiChar(LTagAnsi)), @LBuffer[0], LBufLen);

  // Convert to string (remove null terminator)
  Result := string(PWideChar(@LBuffer[0])).Trim;
end;

function TPdfDocument.GetPdfAInfo: string;
var
  LProducer: string;
  LCreator: string;
  LSubject: string;
begin
  Result := '';
  if not IsLoaded then
    Exit;

  // Check Producer and Creator metadata for PDF/A information
  LProducer := GetMetadata('Producer');
  LCreator := GetMetadata('Creator');
  LSubject := GetMetadata('Subject');

  // Look for PDF/A markers in metadata
  if LProducer.ToUpper.Contains('PDF/A') then
  begin
    // Try to extract version (e.g., "PDF/A-1b", "PDF/A-2u", "PDF/A-3")
    if LProducer.ToUpper.Contains('PDF/A-1') then
      Result := 'PDF/A-1'
    else if LProducer.ToUpper.Contains('PDF/A-2') then
      Result := 'PDF/A-2'
    else if LProducer.ToUpper.Contains('PDF/A-3') then
      Result := 'PDF/A-3'
    else if LProducer.ToUpper.Contains('PDF/A-4') then
      Result := 'PDF/A-4'
    else
      Result := 'PDF/A';
  end
  else if LCreator.ToUpper.Contains('PDF/A') then
  begin
    if LCreator.ToUpper.Contains('PDF/A-1') then
      Result := 'PDF/A-1'
    else if LCreator.ToUpper.Contains('PDF/A-2') then
      Result := 'PDF/A-2'
    else if LCreator.ToUpper.Contains('PDF/A-3') then
      Result := 'PDF/A-3'
    else if LCreator.ToUpper.Contains('PDF/A-4') then
      Result := 'PDF/A-4'
    else
      Result := 'PDF/A';
  end
  else if LSubject.ToUpper.Contains('PDF/A') then
  begin
    if LSubject.ToUpper.Contains('PDF/A-1') then
      Result := 'PDF/A-1'
    else if LSubject.ToUpper.Contains('PDF/A-2') then
      Result := 'PDF/A-2'
    else if LSubject.ToUpper.Contains('PDF/A-3') then
      Result := 'PDF/A-3'
    else if LSubject.ToUpper.Contains('PDF/A-4') then
      Result := 'PDF/A-4'
    else
      Result := 'PDF/A';
  end;
end;

{ TPdfPage }

constructor TPdfPage.Create(ADocument: TPdfDocument; APageIndex: Integer);
begin
  inherited Create;
  FDocument := ADocument;
  FPageIndex := APageIndex;

  FHandle := FPDF_LoadPage(FDocument.Handle, FPageIndex);
  if FHandle = nil then
    raise EPdfPageException.CreateFmt('Failed to load page %d', [FPageIndex]);

  FWidth := FPDF_GetPageWidth(FHandle);
  FHeight := FPDF_GetPageHeight(FHandle);
end;

destructor TPdfPage.Destroy;
begin
  if FHandle <> nil then
    FPDF_ClosePage(FHandle);
  inherited;
end;

function TPdfPage.GetRotation: Integer;
begin
  if FHandle <> nil then
    Result := FPDFPage_GetRotation(FHandle)
  else
    Result := 0;
end;


{ TPdfPageRendererFMX }

procedure TPdfPageRendererFMX.RenderToBitmap(ABitmap: FMX.Graphics.TBitmap; ABackgroundColor: TAlphaColor);
var
  LPdfBitmap: FPDF_BITMAP;
  LBuffer: Pointer;
  LStride: Integer;
  LBitmapData: TBitmapData;
  LSrcPtr: PByte;
  LDstPtr: PByte;
  LY: Integer;
  LX: Integer;
  LR, LG, LB, LA: Byte;
  LBgColor: FPDF_DWORD;
begin
  if Handle = nil then
    raise EPdfRenderException.Create('Page not loaded');

  if ABitmap = nil then
    raise EPdfRenderException.Create('Bitmap is nil');

  // Bitmap size should already be set by caller to desired resolution
  // Don't resize here - caller determines the DPI/resolution

  // Validate bitmap has valid size
  if (ABitmap.Width <= 0) or (ABitmap.Height <= 0) then
    raise EPdfRenderException.Create('Bitmap has invalid size');

  // Create PDFium bitmap (BGRA format)
  LPdfBitmap := FPDFBitmap_Create(ABitmap.Width, ABitmap.Height, 1);
  if LPdfBitmap = nil then
    raise EPdfRenderException.Create('Failed to create PDFium bitmap');

  try
    // Fill with background color (convert ARGB to BGRA)
    LA := TAlphaColorRec(ABackgroundColor).A;
    LR := TAlphaColorRec(ABackgroundColor).R;
    LG := TAlphaColorRec(ABackgroundColor).G;
    LB := TAlphaColorRec(ABackgroundColor).B;
    LBgColor := (LA shl 24) or (LR shl 16) or (LG shl 8) or LB;
    FPDFBitmap_FillRect(LPdfBitmap, 0, 0, ABitmap.Width, ABitmap.Height, LBgColor);

    // Render PDF page to bitmap with high-quality settings
    // Use FPDF_ANNOT for annotations and FPDF_LCD_TEXT for better text rendering
    FPDF_RenderPageBitmap(
      LPdfBitmap,
      Handle,
      0, 0,
      ABitmap.Width, ABitmap.Height,
      FPDF_ROTATE_0,
      FPDF_ANNOT or FPDF_LCD_TEXT
    );

    // Copy PDFium bitmap to FMX bitmap
    LBuffer := FPDFBitmap_GetBuffer(LPdfBitmap);
    LStride := FPDFBitmap_GetStride(LPdfBitmap);

    if ABitmap.Map(TMapAccess.Write, LBitmapData) then
    try
      LSrcPtr := LBuffer;
      for LY := 0 to ABitmap.Height - 1 do
      begin
        LDstPtr := LBitmapData.GetScanline(LY);
        for LX := 0 to ABitmap.Width - 1 do
        begin
          // PDFium uses BGRA, FMX uses BGRA on Windows, RGBA on other platforms
          LB := LSrcPtr^; Inc(LSrcPtr);
          LG := LSrcPtr^; Inc(LSrcPtr);
          LR := LSrcPtr^; Inc(LSrcPtr);
          LA := LSrcPtr^; Inc(LSrcPtr);

          {$IFDEF MSWINDOWS}
          // Windows: BGRA -> BGRA (no conversion needed)
          LDstPtr^ := LB; Inc(LDstPtr);
          LDstPtr^ := LG; Inc(LDstPtr);
          LDstPtr^ := LR; Inc(LDstPtr);
          LDstPtr^ := LA; Inc(LDstPtr);
          {$ELSE}
          // macOS/iOS/Android: BGRA -> RGBA
          LDstPtr^ := LR; Inc(LDstPtr);
          LDstPtr^ := LG; Inc(LDstPtr);
          LDstPtr^ := LB; Inc(LDstPtr);
          LDstPtr^ := LA; Inc(LDstPtr);
          {$ENDIF}
        end;
        // Skip to next scanline in source
        LSrcPtr := PByte(NativeInt(LBuffer) + (LY + 1) * LStride);
      end;
    finally
      ABitmap.Unmap(LBitmapData);
    end;
  finally
    FPDFBitmap_Destroy(LPdfBitmap);
  end;
end;


initialization

  LoadPDFiumLibrary

finalization
  UnloadPDFiumLibrary;

end.


