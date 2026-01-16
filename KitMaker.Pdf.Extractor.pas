unit KitMaker.Pdf.Extractor;

interface


//
// Donado por  Antonio Alcázar al proyecto MakerAI
//
// - GitHub: https://github.com/gustavoeenriquez/
(*
Esta unidad esta modificada para poder usar la libreria  pdfium, de forma dinamica


  Part of DX Pdfium4D - Delphi Cross-Platform Wrapper für Pdfium
  https://github.com/omonien/DX-Pdfium4D
  *)

uses

  System.UITypes,
  System.Classes,DX.Pdf.Dynamic;


type
  /// <summary>
  /// Abstract base class for PDF viewer components
  /// </summary>
  /// <remarks>
  /// This class provides framework-independent functionality for PDF viewing.
  /// Derived classes (FMX, VCL) implement the rendering and UI-specific parts.
  /// </remarks>
  TPdfExtractor = class(TComponent)
  private
    FDocument: TPdfDocument;
    FCurrentPage: TPdfPage;
    FCurrentPageIndex: Integer;
    FBackgroundColor: TAlphaColor;
    // FShowLoadingIndicator: Boolean;
    FOnPageChanged: TNotifyEvent;
    FIsRendering: Boolean;
    FLastFiles: string;

    FDirOutput: string;

    FRootFiles: string;

    procedure SetCurrentPageIndex(const AValue: Integer);
    procedure SetBackgroundColor(const AValue: TAlphaColor);
    // procedure SetShowLoadingIndicator(const AValue: Boolean);
    function GetPageCount: Integer;

  protected
    /// <summary>
    /// Triggers page rendering
    /// </summary>
    procedure RenderCurrentPage;

    /// <summary>
    /// Current page object (can be nil)
    /// </summary>
    property CurrentPage: TPdfPage read FCurrentPage write FCurrentPage;

    /// <summary>
    /// Flag indicating if rendering is in progress
    /// </summary>
    property IsRendering: Boolean read FIsRendering write FIsRendering;

  private

    procedure SetDirOutput(const Value: string);
    procedure SetRootFiles(const Value: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GetCurrentPage_: TPdfPage;
    procedure SetCurrentPage(const AValue: TPdfPage);
    function GetIsRendering_: Boolean;
    procedure SetIsRendering_(const AValue: Boolean);
    function SaveActualPage(const RutaArchivo: string): string;

    function PdfPages2PNGs(): tstringlist;
    function PdfPages2JPG(): tstringlist;

    procedure SavePdfPages();
    function OutputFilename(const raiz:string):string;


    function ConvertPageToImage(PageNumber: Integer;
      const OutputFile: string = ''): string;

    /// <summary>
    /// Loads a PDF document from a file
    /// </summary>
    procedure LoadFromFile(const AFileName: string;
      const APassword: string = '');

    /// <summary>
    /// Closes the currently loaded document
    /// </summary>
    procedure Close; virtual;

    /// <summary>
    /// Navigates to the next page
    /// </summary>
    procedure NextPage;

    /// <summary>
    /// Navigates to the previous page
    /// </summary>
    procedure PreviousPage;

    /// <summary>
    /// Navigates to the first page
    /// </summary>
    procedure FirstPage;

    /// <summary>
    /// Navigates to the last page
    /// </summary>
    procedure LastPage;

    /// <summary>
    /// Checks if a document is currently loaded
    /// </summary>
    function IsDocumentLoaded: Boolean;

    /// <summary>
    /// Current page index (0-based)
    /// </summary>
    property CurrentPageIndex: Integer read FCurrentPageIndex
      write SetCurrentPageIndex;

    /// <summary>
    /// Number of pages in the document
    /// </summary>
    property PageCount: Integer read GetPageCount;

    /// <summary>
    /// The PDF document object
    /// </summary>
    property Document: TPdfDocument read FDocument;

    /// <summary>
    /// Background color for the viewer
    /// </summary>
    property BackgroundColor_: TAlphaColor read FBackgroundColor
      write SetBackgroundColor;

    /// <summary>
    /// Event fired when the current page changes
    /// </summary>
    property OnPageChanged: TNotifyEvent read FOnPageChanged
      write FOnPageChanged;

    property LastFile: string read FLastFiles write FLastFiles;
    property DirOutput: string read FDirOutput write SetDirOutput;

    property RootFiles: string read FRootFiles write SetRootFiles;

  end;


implementation


uses
KitMaker.Task,
System.IOUtils,
System.SysUtils,
FMX.Graphics

;




procedure TPdfExtractor.SetDirOutput(const Value: string);
begin
  FDirOutput := Value;
end;

function TPdfExtractor.ConvertPageToImage(PageNumber: Integer;
  const OutputFile: string): string;
begin
  CurrentPageIndex := PageNumber;
  Result := SaveActualPage(OutputFile);
end;

{ TPdfExtractor }

constructor TPdfExtractor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDocument := TPdfDocument.Create;
  FCurrentPage := nil;
  FCurrentPageIndex := -1;
  FBackgroundColor := TAlphaColors.White;
  // FShowLoadingIndicator__ := True;
  FIsRendering := False;
  FLastFiles := '';

  FDirOutput :='';
  FRootFiles := 'imagenes';


end;

destructor TPdfExtractor.Destroy;
begin
  Close;
  FreeNil(FDocument);
  inherited;
end;

procedure TPdfExtractor.LoadFromFile(const AFileName: string;
  const APassword: string);
begin
  Close;
  FLastFiles := AFileName;

  FDocument.LoadFromFile(AFileName, APassword);
  if FDocument.PageCount > 0 then
    SetCurrentPageIndex(0)
  else
    FCurrentPageIndex := -1;
end;

(*
  procedure TPdfExtractor.LoadFromStream_(AStream: TStream; AOwnsStream: Boolean; const APassword: string);
  begin
  Close;
  FDocument.LoadFromStream(AStream, AOwnsStream, APassword);
  if FDocument.PageCount > 0 then
  SetCurrentPageIndex(0)
  else
  FCurrentPageIndex := -1;
  end;
*)

procedure TPdfExtractor.Close;
begin
  FreeNil(FCurrentPage);
  FCurrentPageIndex := -1;
  FDocument.Close;
end;

function TPdfExtractor.IsDocumentLoaded: Boolean;
begin
  Result := FDocument.IsLoaded;
end;

function TPdfExtractor.GetPageCount: Integer;
begin
  if IsDocumentLoaded then
    Result := FDocument.PageCount
  else
    Result := 0;
end;

procedure TPdfExtractor.SetCurrentPageIndex(const AValue: Integer);
begin
  if not IsDocumentLoaded then
    Exit;

  if (AValue < 0) or (AValue >= FDocument.PageCount) then
    Exit;

  if FCurrentPageIndex <> AValue then
  begin
    FCurrentPageIndex := AValue;
    RenderCurrentPage;
    if Assigned(FOnPageChanged) then
      FOnPageChanged(Self);
  end;
end;

procedure TPdfExtractor.SetBackgroundColor(const AValue: TAlphaColor);
begin
  if FBackgroundColor <> AValue then
  begin
    FBackgroundColor := AValue;
    if IsDocumentLoaded then
      RenderCurrentPage;

  end;
end;

procedure TPdfExtractor.RenderCurrentPage;
begin
  if not IsDocumentLoaded then
    Exit;

  if (FCurrentPageIndex < 0) or (FCurrentPageIndex >= FDocument.PageCount) then
    Exit;

  if FIsRendering then
    Exit;

  FIsRendering := true;

end;

procedure TPdfExtractor.NextPage;
begin
  if IsDocumentLoaded and (FCurrentPageIndex < FDocument.PageCount - 1) then
    SetCurrentPageIndex(FCurrentPageIndex + 1);
end;

procedure TPdfExtractor.PreviousPage;
begin
  if IsDocumentLoaded and (FCurrentPageIndex > 0) then
    SetCurrentPageIndex(FCurrentPageIndex - 1);
end;

procedure TPdfExtractor.FirstPage;
begin
  if IsDocumentLoaded then
    SetCurrentPageIndex(0);
end;

procedure TPdfExtractor.LastPage;
begin
  if IsDocumentLoaded and (FDocument.PageCount > 0) then
    SetCurrentPageIndex(FDocument.PageCount - 1);
end;

function TPdfExtractor.GetCurrentPage_: TPdfPage;
begin
  Result := CurrentPage;
end;

procedure TPdfExtractor.SetCurrentPage(const AValue: TPdfPage);
begin
  CurrentPage := AValue;
end;

function TPdfExtractor.GetIsRendering_: Boolean;
begin
  Result := IsRendering;
end;

procedure TPdfExtractor.SetIsRendering_(const AValue: Boolean);
begin
  IsRendering := AValue;
end;

procedure TPdfExtractor.SetRootFiles(const Value: string);
begin
  FRootFiles := Value;
end;



function RenderPageInBitmap(Pdf_: TPdfExtractor; w: Integer = 1000;
  h: Integer = 1500): FMX.Graphics.TBitmap;
var
  LRenderWidth: Integer;
  LRenderHeight: Integer;
  LAspectRatio_: Double;
  LControlWidth: Integer;
  LControlHeight: Integer;

  LPageIndex: Integer;
  LBackgroundColor__: TAlphaColor;
  LCurrentPage: TPdfPage;
  // LCoreFMX__: TPdfExtractor;
begin
  Result := nil;
  // LCoreFMX__ := TPdfExtractor(Pdf_);

  // Capture values in main thread
  LPageIndex := Pdf_.CurrentPageIndex;
  LBackgroundColor__ := Pdf_.BackgroundColor_;

  // Get screen scale factor for high-DPI displays
  // LScale_ := 1.0;

  // Get control size in pixels
  LControlWidth := w; // Trunc(Width);
  LControlHeight := h; // Trunc(Height);

  if (LControlWidth <= 0) or (LControlHeight <= 0) then
  begin
    Pdf_.SetIsRendering_(False);
    Exit;
  end;

  // Load page in main thread (PDFium is not thread-safe for loading)
  Pdf_.SetCurrentPage(Pdf_.Document.GetPageByIndex(LPageIndex));
  LCurrentPage := Pdf_.GetCurrentPage_;

  if LCurrentPage = nil then
  begin
    // LCoreFMX_.SetIsRendering(False);
    // DoShowLoadingIndicatorInternal(False);
    Exit;
  end;

  // Calculate aspect ratio of PDF page
  LAspectRatio_ := LCurrentPage.Width / LCurrentPage.Height;

  // Calculate render size to fit control while maintaining aspect ratio
  if LControlWidth = 1000 then
  begin
    LRenderWidth := round(LCurrentPage.Width);
    LRenderHeight := round(LCurrentPage.Height);
    // LRenderWidth :=round( LCurrentPage.Width)*2;
    // LRenderHeight := round(LCurrentPage.Height)*2;

  end
  else if LControlWidth / LControlHeight > LAspectRatio_ then
  begin
    // Height is limiting factor
    LRenderHeight := round(LControlHeight);
    LRenderWidth := round(LRenderHeight * LAspectRatio_);
  end
  else
  begin
    // Width is limiting factor
    LRenderWidth := round(LControlWidth);
    LRenderHeight := round(LRenderWidth / LAspectRatio_);
  end;

  Result := FMX.Graphics.TBitmap.Create;
  try
    Result.SetSize(LRenderWidth, LRenderHeight);
    Result.BitmapScale := 1; // LScale;

    // Render at exact size (this is the slow part)
    LCurrentPage.RenderToBitmap(Result, LBackgroundColor__);

  except

  end;
  // end);
end;


procedure GuardarImagen(const RutaArchivo: string; FImage: TBitmap);
begin
  // FImage.Picture := ...   // (ya está cargado)
  if FileExists(RutaArchivo) then
    DeleteFile(RutaArchivo); // opcional, evita “archivo en uso”

  // Si quieres guardar explícitamente como BMP:
  FImage.SaveToFile(RutaArchivo); // el formato se infiere por la extensión
end;



function TPdfExtractor.OutputFilename(const raiz:string):string;
begin
   result:=TPath.Combine(FDirOutput, raiz)
//   result:=ConBarra(FDirOutput) + raiz
end;


procedure TPdfExtractor.SavePdfPages();
var
  bitmap: FMX.Graphics.TBitmap;
begin
  for var I := 0 to PageCount - 1 do
  begin

    bitmap := RenderPageInBitmap(Self);
    try
      GuardarImagen(OutputFilename (FRootFiles + IntToStr(I) +'.jpg'), bitmap);
    finally
      freeNil(bitmap)
    end;
    NextPage
  end;
  // UpdateStatusBar;
end;

function TPdfExtractor.PdfPages2JPG(): tstringlist;
var
  bitmap: FMX.Graphics.TBitmap;
var
  na: string;
begin
  Result := tstringlist.Create;
  for var I := 0 to PageCount - 1 do
  begin

    bitmap := RenderPageInBitmap(Self);
    try
      na :=OutputFilename (FRootFiles + IntToStr(I) + '.jpg');
      Result.add(na);
      GuardarImagen(na, bitmap);
    finally
      freeNil(bitmap)
    end;
    NextPage
  end;
  // UpdateStatusBar;
end;


function RenderPageSave(Pdf_: TPdfExtractor; const na: string;
  w: Integer = 1000; h: Integer = 1500): String;
var
  bitmap: FMX.Graphics.TBitmap;
begin
  Result := na;
  bitmap := RenderPageInBitmap(Pdf_);
  try
    GuardarImagen(na, bitmap);
  finally
    freeNil(bitmap)
  end;
  // UpdateStatusBar;
end;



function TPdfExtractor.PdfPages2PNGs(): tstringlist;
var
  na: string;
begin
  Result := tstringlist.Create;
  try
    for var I := 0 to PageCount - 1 do
    begin
      na := OutputFilename (FRootFiles + IntToStr(I) + '.png');
      Result.add(RenderPageSave(Self, na));

      NextPage
    end;
  finally

  end;
end;

function TPdfExtractor.SaveActualPage(const RutaArchivo: string): string;
var
  bitmap: FMX.Graphics.TBitmap;
  Ruta: string;
begin
  try
    Ruta := RutaArchivo;
    if Ruta = '' then
    begin
      Ruta :=OutputFilename (FRootFiles + IntToStr(CurrentPageIndex) + '.jpg')
    end;

    bitmap := RenderPageInBitmap(Self);
    try
      GuardarImagen(Ruta, bitmap);
    finally
      freeNil(bitmap)
    end;
    Result := Ruta;
  except

  end;

  // UpdateStatusBar;
end;


end.
