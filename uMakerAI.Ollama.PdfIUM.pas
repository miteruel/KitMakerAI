unit uMakerAI.Ollama.PdfIUM;

interface

//
// Donado por  Antonio Alcázar al proyecto MakerAI
//
// - GitHub: https://github.com/gustavoeenriquez/



{.$define LOGMIT}

uses



  System.Classes,
  uMakerAI.Core,
  uMakerAI.Chat.Tools,
  uMakerAI.Chat.Messages,
  uMakerAI.Chat.AiConnection,
  System.Types,

  System.UITypes  ,
  KitMaker.Pdf.Extractor  ;




type
  { TAiDelegaOcrTool: Delegar OCR  }

  TAiDelegaOcrTool = class(TAiVisionToolBase)
  private

    FModel: string;
    FPrompt_: string;
    FKeepAlive: string;

    FAiConn: TAiChatConnection;

    procedure SetAiConn(const Value: TAiChatConnection);
    procedure ExecuteImageDescription(aMediaFile: TAiMediaFile;
      ResMsg, AskMsg: TAiChatMessage); override;

  public
    constructor Create(AOwner: TComponent); override;


    class function AddExtractTextFromFile(Ai: TAiChatConnection;
      const AFilePath, APrompt: string): string;
    class function ExtractTextExternal(Ai: TAiChatConnection;
      aMediaFile: TAiMediaFile; const APrompt: string): string;

    function ExternalRunOllamaOCR_(aMediaFile: TAiMediaFile;
      const AOverridePrompt: string): string;

  published
    property Model: string read FModel write FModel;
    property KeepAlive: string read FKeepAlive write FKeepAlive;

    property Prompt_: string read FPrompt_ write FPrompt_;
    property AiConn: TAiChatConnection read FAiConn write SetAiConn;
  end;

type
  TOnPdfOcrProgress = procedure(Sender: TObject;
    CurrentPage, TotalPages: Integer; const StatusMsg: string;
    const texto: string; var ok: Boolean) of object;

  TAiOllamaPdfIUMTool = class(TAiPdfToolBase)
  private
    FModel: string;
    FPrompt: string;

    FOnProgress: TOnPdfOcrProgress;
    pdfes: TPdfExtractor;
    FAiConn: TAiChatConnection;

    function InternalRunPdfOcr(aMediaFile: TAiMediaFile;
      ResMsg, AskMsg: TAiChatMessage; const AOverridePrompt: string): string;
  protected
    procedure ExecutePdfAnalysis(aMediaFile: TAiMediaFile;
      ResMsg, AskMsg: TAiChatMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    Destructor Destroy; override;
    function PdfActivo(const APdfPath: string): TPdfExtractor;
    function ExtractText(const APdfPath: string): string; overload;

    function ExtractTextFromFiles(const APdfPath_: string): string;

  private
    FCacheTest: string;


    // 1. Procesar por ruta de archivo
    function ExtractText(const APdfPath: string; const APrompt: string)
      : string; overload;

    // 2. Procesar por Stream (Útil para bases de datos o archivos en memoria)
    function ExtractText_(AStream: TStream; const AFileName: string;
      const APrompt: string): string; overload;
    procedure SetCacheTest(const Value: string);


  published
    property CacheTest: string read FCacheTest write SetCacheTest;

    property Model: string read FModel write FModel;
    property Prompt: string read FPrompt write FPrompt;
    property OnProgress: TOnPdfOcrProgress read FOnProgress write FOnProgress;
    property AiConn: TAiChatConnection read FAiConn write FAiConn;
  end;
  (*

  TAiOllamaPdfTool = class(TAiOllamaPdfIUMTool)
  public
    FUrl_: string;
    FDPI_: Integer;

    FGhostscriptPath: string;
  published
    property Url: string read FUrl_ write FUrl_;

    property GhostscriptPath: string read FGhostscriptPath
      write FGhostscriptPath;
    property DPI: Integer read FDPI_ write FDPI_ default 300;

  end;
  *)

procedure Register;

implementation


{$IFDEF LOGMIT}
 {$I incspynET}

{$ENDIF}



uses

{$IFDEF LOGMIT}

 {$IFDEF COMPACMODES}
  Monada_Sys,

{$ELSE}
  Monada_Directory,
  Monada_File,


{$ENDIF}



{$ENDIF}

   KitMaker.task,

  System.JSON, System.Net.HttpClient,
  System.Net.HttpClientComponent, System.Net.URLClient,

  FMX.Graphics,
  System.StrUtils,
//  System.Threading,
  System.SysUtils,
  System.IOUtils,

  System.Math, FMX.Platform;

procedure DeleteCharSt(var st: String; ch1: Char);
var
  i: Integer;
Begin
  for i := Length(st) downto 1 do
//  for i := LastChar(st) downto LowSt_ do

  Begin
    if st[i] = ch1 then
    begin
      Delete(st, i, 1);
    end;
  end;
end;



procedure Register;
begin
  RegisterComponents('MakerAI', [TAiOllamaPdfIUMTool, TAiDelegaOcrTool]);
end;

{ TAiOllamaPdfIUMTool }

constructor TAiOllamaPdfIUMTool.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // FUrl_ := 'http://localhost:11434/';
  FModel := 'deepseek-ocr';
  FPrompt := 'extract all';
  // FDPI_ := 300;
  try
    // FGhostscriptPath := TGhostscriptPDF.FindGhostscriptPath;
  except
    // FGhostscriptPath := '';
  end;
end;

{ Implementaciones de ExtractText (Instancia) }

function TAiOllamaPdfIUMTool.ExtractText(const APdfPath: string): string;
begin
  Result := ExtractText(APdfPath, FPrompt);
end;

function TAiOllamaPdfIUMTool.ExtractText(const APdfPath: string;
  const APrompt: string): string;
begin
  Result := ExtractTextFromFiles(APdfPath);
end;


function TAiOllamaPdfIUMTool.ExtractText_(AStream: TStream;
  const AFileName: string; const APrompt: string): string;
var
  TempPath: string;
  FileStream: TFileStream;
begin
  Result := '';
  if not Assigned(AStream) then
    Exit;

  // Creamos una ruta temporal con el nombre de archivo proporcionado
  TempPath := TPath.Combine(TPath.GetTempPath, AFileName);

  // Guardamos el contenido del Stream a un archivo físico temporal
  FileStream := TFileStream.Create(TempPath, fmCreate);
  try
    AStream.Position := 0;
    FileStream.CopyFrom(AStream, AStream.Size);
  finally
    FileStream.Free;
  end;

  try
    // Procesamos el archivo temporal usando la lógica ya existente
    Result := ExtractText(TempPath, APrompt);
  finally
    // IMPORTANTE: Limpiamos el archivo temporal de PDF
    if TFile.Exists(TempPath) then
      TFile.Delete(TempPath);
  end;
end;

function TAiOllamaPdfIUMTool.ExtractTextFromFiles(const APdfPath_
  : string): string;
var
  PageCount, I: Integer;
  TempImg: string;
  PageText: string;
  FullText: TStringBuilder;
  filepng: tstringlist;

  ok: Boolean;
  pdfe: TPdfExtractor;

begin
  Result := '';
  if not FileExists(APdfPath_) then
    Exit;

{$IFDEF LOGMIT}
  var fifa:TMonaFile:=CacheTest;
  result:=fifa.AnsiContent;
  if result<>'' then
  begin
    exit
  end;


{$ENDIF}


  pdfe := PdfActivo(APdfPath_);
  filepng := pdfe.PdfPages2PNGs();

  // IMPORTANTE: El prompt es muy sensible en este ocr  debe ir en minuscula y con un espacio inicial
  // si se cambia el prompt es posible que no funcione correctamente.
  FullText := TStringBuilder.Create;

  try
    PageCount := filepng.count; // pdfe.PageCount;
    pdfe.DirOutput := TPath.GetTempPath;

    if filepng.count > 0 then

      for I := 0 to filepng.count - 1 do
      begin
        ok := true;
        if Assigned(OnProgress) then
          OnProgress(Self, I, filepng.count,
            Format('Procesando página %d de %d...', [I, PageCount]), '', ok);

        TempImg := filepng[I]; // pdfe.ConvertPageToImage( I);
        if ok then

          if not TempImg.IsEmpty then
            try
              // PageText := TAiDelegaOcrTool.ExtractTextFromFile( TempImg, Prompt, Url);

              PageText := TAiDelegaOcrTool.AddExtractTextFromFile(AiConn,
                TempImg, Prompt);

              // PageText := TAiDelegaOcrTool.ExtractTextFromFile(TempImg, Prompt, Url);
              if Assigned(OnProgress) then
                OnProgress(Self, I, filepng.count,
                  Format('Procesada página %d de %d...', [I, PageCount]),
                  PageText, ok);

              FullText.AppendLine(Format('--- PÁGINA %d ---', [I]));
              FullText.AppendLine(PageText);
              FullText.AppendLine;
            finally
              // if TFile.Exists(TempImg) then
              // TFile.Delete(TempImg);
            end;
      end;
    Result := FullText.ToString;
    DeleteCharSt(result,'"');
  finally
    freeNil(pdfes);
    filepng.Free;
    FullText.Free;
  end;
end;

function TAiOllamaPdfIUMTool.InternalRunPdfOcr(aMediaFile: TAiMediaFile;
  ResMsg, AskMsg: TAiChatMessage; const AOverridePrompt: string): string;
var
  LFinalPrompt: string;
begin
  LFinalPrompt := IfThen(AOverridePrompt.IsEmpty, FPrompt, AOverridePrompt);

  // Usamos el nuevo método de Stream del componente para procesar el MediaFile
  // Esto maneja automáticamente la creación y borrado del temporal.
  Result := ExtractText_(aMediaFile.Content, aMediaFile.filename, LFinalPrompt);

  Var
  S := StringReplace(AskMsg.Prompt + sLineBreak + 'PDF Data is ' + Result,
    #$D#$A, '\n', [rfReplaceAll]);
  S := StringReplace(S, #$D, '\n', [rfReplaceAll]);
  S := StringReplace(S, #$A, '\n', [rfReplaceAll]);

  AskMsg.Prompt := S;

  ResMsg.Content := Result;
  ResMsg.Prompt := Result;
  ResMsg.Role := 'assistant';
  ResMsg.Model := FModel;
  aMediaFile.Procesado := true;
  aMediaFile.Transcription := Result;

  ReportDataEnd(ResMsg, 'assistant', Result);
  ReportState(acsFinished, 'Análisis PDF completado');
end;


(*
  procedure TPdfExtractor.SetLastFiles(const Value: string);
  begin
  FLastFiles := Value;
  end;

*)

procedure GuardarImagen(const RutaArchivo: string; FImage: TBitmap);
begin
  // FImage.Picture := ...   // (ya está cargado)
  if FileExists(RutaArchivo) then
    DeleteFile(RutaArchivo); // opcional, evita “archivo en uso”

  // Si quieres guardar explícitamente como BMP:
  FImage.SaveToFile(RutaArchivo); // el formato se infiere por la extensión
end;




function TAiOllamaPdfIUMTool.PdfActivo(const APdfPath: string): TPdfExtractor;
begin
  if Assigned(pdfes) then
    if pdfes.LastFile <> APdfPath then
    begin
      freeNil(pdfes)
    end;
  if pdfes = Nil then

  begin
    pdfes := TPdfExtractor.Create(Self);
    pdfes.LoadFromFile(APdfPath);
  end;

  Result := pdfes
end;




procedure TAiOllamaPdfIUMTool.SetCacheTest(const Value: string);
begin
  FCacheTest := Value;
end;

destructor TAiOllamaPdfIUMTool.Destroy;
begin

  inherited;
end;

{ Integración con MakerAi Framework }

procedure TAiOllamaPdfIUMTool.ExecutePdfAnalysis(aMediaFile: TAiMediaFile;
  ResMsg, AskMsg: TAiChatMessage);
begin
  (*
    if IsAsync then
    TTask.Run(
    procedure
    begin
    InternalRunPdfOcr(aMediaFile, ResMsg, AskMsg, AskMsg.Prompt);
    end)
    else
  *)
  InternalRunPdfOcr(aMediaFile, ResMsg, AskMsg, AskMsg.Prompt);
end;

{ TAiDelegaOcrTool }

constructor TAiDelegaOcrTool.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Importante: La URL base. El InternalRun se encargará de asegurar el endpoint /api/chat
  // FUrl_ := 'http://localhost:11434/';
  FModel := 'deepseek-ocr:latest';
  FPrompt_ := 'Extract text in Json format';
  // FPrompt_ := '<|grounding|>Convert the document to markdown';

  FKeepAlive := '1m';

  AiConn := nIL;
end;

procedure TAiDelegaOcrTool.SetAiConn(const Value: TAiChatConnection);
begin
  FAiConn := Value
end;

class function TAiDelegaOcrTool.ExtractTextExternal(Ai: TAiChatConnection;
  aMediaFile: TAiMediaFile; const APrompt: string): string;
var
  LInstance: TAiDelegaOcrTool;

begin
  Result := '';
  if not Assigned(aMediaFile) then
    Exit;
  LInstance := TAiDelegaOcrTool.Create(nil);
  LInstance.AiConn := Ai;

  try
    Result := LInstance.ExternalRunOllamaOCR_(aMediaFile, APrompt);
  finally
    LInstance.Free;
  end;
end;

class function TAiDelegaOcrTool.AddExtractTextFromFile(Ai: TAiChatConnection;
  const AFilePath, APrompt: string): string;
var
  LMedia: TAiMediaFile;
begin
  Result := '';
  if not FileExists(AFilePath) then
    Exit;
  LMedia := TAiMediaFile.Create;
  try
    LMedia.LoadFromFile(AFilePath);
    Result := ExtractTextExternal(Ai, LMedia, APrompt);
  finally
    LMedia.Free;
  end;
end;

procedure TAiDelegaOcrTool.ExecuteImageDescription(aMediaFile: TAiMediaFile;
  ResMsg, AskMsg: TAiChatMessage);
var
  S: string;
begin
  S := ExternalRunOllamaOCR_(aMediaFile, AskMsg.Prompt);
  if Assigned(ResMsg) then
    ResMsg.Prompt := S;

end;

function TAiDelegaOcrTool.ExternalRunOllamaOCR_(aMediaFile: TAiMediaFile;
  const AOverridePrompt: string): string;
var
  LFinalPrompt    : string;
begin
  Result := '';
  if not Assigned(aMediaFile) then
    Exit;
  if not Assigned(AiConn) then
    Exit;

  AiConn.Messages.Clear;

  LFinalPrompt := IfThen(AOverridePrompt.IsEmpty, FPrompt_, AOverridePrompt);
  if LFinalPrompt.IsEmpty then
    LFinalPrompt := '<|grounding|>Extract text in Json format';
  AiConn.Model := Model;
  Result := AiConn.AddMessageAndRun(LFinalPrompt, 'user', [aMediaFile]);

end;






end.



