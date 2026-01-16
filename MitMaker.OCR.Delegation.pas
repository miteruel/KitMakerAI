unit MitMaker.OCR.Delegation;

interface

//
// Donado por  Antonio Alcázar al proyecto MakerAI
//
// - GitHub: https://github.com/gustavoeenriquez/

uses

  System.Classes,
  uMakerAI.Core,
  uMakerAI.Chat.Tools,
  uMakerAI.Chat.Messages,
  uMakerAI.Chat.AiConnection;

type
  { TAiDelegaOcrTool: Delegar OCR }

  TAiDelegaOcrTool = class(TAiVisionToolBase)
  private

    FModel: string;
    FPrompt_: string;

    FAiConn: TAiChatConnection;

    procedure SetAiConn(const Value: TAiChatConnection);
    procedure ExecuteImageDescription(aMediaFile: TAiMediaFile;
      ResMsg, AskMsg: TAiChatMessage); override;

  public
    constructor Create(AOwner: TComponent); override;

    class function AddExtractTextFromFile(const Ai: TAiChatConnection;
      const AFilePath, APrompt: string): string;
    class function ExtractTextExternal(const Ai: TAiChatConnection;
      aMediaFile: TAiMediaFile; const APrompt: string): string;

    function ExternalRunOllamaOCR_(aMediaFile: TAiMediaFile;
      const AOverridePrompt: string): string;

  published
    property Model: string read FModel write FModel;
    property Prompt: string read FPrompt_ write FPrompt_;
    property AiConn: TAiChatConnection read FAiConn write SetAiConn;
  end;

implementation

uses
  System.StrUtils,
  System.SysUtils;

{ TAiDelegaOcrTool }

constructor TAiDelegaOcrTool.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Importante: La URL base. El InternalRun se encargará de asegurar el endpoint /api/chat
  // FUrl_ := 'http://localhost:11434/';
  FModel := 'deepseek-ocr:latest';
  FPrompt_ := 'Extract text in imagen';
  // FPrompt_ := '<|grounding|>Convert the document to markdown';
  FAiConn := nil;
end;

procedure TAiDelegaOcrTool.SetAiConn(const Value: TAiChatConnection);
begin
  FAiConn := Value
end;

class function TAiDelegaOcrTool.ExtractTextExternal(const Ai: TAiChatConnection;
  aMediaFile: TAiMediaFile; const APrompt: string): string;
var
  LInstance: TAiDelegaOcrTool;

begin
  Result := '';
  if not Assigned(aMediaFile) then
    Exit;
  if not Assigned(Ai) then
    Exit;

  LInstance := TAiDelegaOcrTool.Create(nil);
  try
    LInstance.AiConn := Ai;

    Result := LInstance.ExternalRunOllamaOCR_(aMediaFile, APrompt);
  finally
    LInstance.Free;
  end;
end;

class function TAiDelegaOcrTool.AddExtractTextFromFile(const Ai: TAiChatConnection;
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
  if AskMsg = nil then
    Exit;

  S := ExternalRunOllamaOCR_(aMediaFile, AskMsg.Prompt);
  if Assigned(ResMsg) then
    ResMsg.Prompt := S;

end;

function TAiDelegaOcrTool.ExternalRunOllamaOCR_(aMediaFile: TAiMediaFile;
  const AOverridePrompt: string): string;
var
  LFinalPrompt: string;
begin
  Result := '';
  if not Assigned(aMediaFile) then
    Exit;
  if not Assigned(AiConn) then
    Exit;

  AiConn.Messages.Clear;

  LFinalPrompt := IfThen(AOverridePrompt.IsEmpty, FPrompt_, AOverridePrompt);
  if LFinalPrompt.IsEmpty then
    LFinalPrompt := 'Extract text';

  // LFinalPrompt := '<|grounding|>Extract text in Json format';
  AiConn.Model := Model;
  Result := AiConn.AddMessageAndRun(LFinalPrompt, 'user', [aMediaFile]);

end;

end.

