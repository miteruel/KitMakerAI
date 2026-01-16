unit uMakerAi.Chat.G4F;
//
// Donado por  Antonio Alcázar al proyecto MakerAI
//
// - GitHub: https://github.com/gustavoeenriquez/

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Threading,
  System.Variants, System.Net.Mime, System.IOUtils, System.Generics.Collections,
  System.NetEncoding,
  System.JSON, System.StrUtils, System.Net.URLClient, System.Net.HttpClient,
  System.Net.HttpClientComponent,
  REST.JSON, REST.Types, REST.Client,


  uMakerAi.ParamsRegistry, uMakerAi.Chat, uMakerAi.Embeddings, uMakerAi.Core, uMakerAi.Embeddings.Core;

Type


  TAiChatG4F = Class(TAiChat)

  Protected
    Function InitChatCompletions: String; Override;
  Public
    Constructor Create(Sender: TComponent); Override;
    Destructor Destroy; Override;
    class procedure RegisterDefaultParamG4f(Params: TStrings; const url:string; const model:string='');

  Published
  End;




  TAiG4FGemini = Class(TAiChatG4F)
  Public
    Constructor Create(Sender: TComponent); Override;
    Destructor Destroy; Override;
    class function GetDriverName: string; Override;
    class procedure RegisterDefaultParams(Params: TStrings); Override;
    class function CreateInstance(Sender: TComponent): TAiChat; Override;
  Published
  End;




  TAiG4FOllama = Class(TAiChatG4F)
  Public
    Constructor Create(Sender: TComponent); Override;
    Destructor Destroy; Override;
    class function GetDriverName: string; Override;
    class procedure RegisterDefaultParams(Params: TStrings); Override;
    class function CreateInstance(Sender: TComponent): TAiChat; Override;
  Published
  End;




  TAiG4FPollinations = Class(TAiChatG4F)
  Public
    Constructor Create(Sender: TComponent); Override;
    Destructor Destroy; Override;
    class function GetDriverName: string; Override;
    class procedure RegisterDefaultParams(Params: TStrings); Override;
    class function CreateInstance(Sender: TComponent): TAiChat; Override;
  Published
  End;

 TAiG4FNvidia = Class(TAiChatG4F)
  Public
    Constructor Create(Sender: TComponent); Override;
    Destructor Destroy; Override;
    class function GetDriverName: string; Override;
    class procedure RegisterDefaultParams(Params: TStrings); Override;
    class function CreateInstance(Sender: TComponent): TAiChat; Override;
  Published
  End;

  TAiG4FGroqChat = Class(TAiChatG4F)

  Protected
    Function InitChatCompletions: String; Override;
  Public
    Constructor Create(Sender: TComponent); Override;
    Destructor Destroy; Override;
    class function GetDriverName: string; Override;
    class procedure RegisterDefaultParams(Params: TStrings); Override;
    class function CreateInstance(Sender: TComponent): TAiChat; Override;
  End;


procedure Register;




implementation

uses uMakerAi.Chat.Messages;



Const
  GlAIUrlOllama = 'https://g4f.dev/api/ollama/';
  GlAIUrlPollin = 'https://g4f.dev/api/pollinations/';
  GlAIUrlNvidia = 'https://g4f.dev/api/nvidia/';
  GlAIUrlGroq = 'https://g4f.dev/api/groq/';
  GlAIUrlGemini = 'https://g4f.dev/api/gemini/';




class procedure TAiChatG4F.RegisterDefaultParamG4f(Params: TStrings; const url,model:string);
Begin
  Params.Clear;
  Params.Add('ApiKey=secret');
  if model<>'' then
  begin
   Params.Add('Model='+model);
  end;
//  Params.Add('Model=meta-llama/llama-guard-4-12b');
  Params.Add('MaxTokens=4096');
  Params.Add('URL='+url);
//    Params.Add('URL=https://api.groq.com/openai/v1/');
End;

(*
class function TAiChatG4F.CreateInstance(Sender: TComponent): TAiChat;
Begin
  Result := TAiChatG4F.Create(Sender);
End;
*)

constructor TAiChatG4F.Create(Sender: TComponent);
begin
  inherited;
  ApiKey := 'secret';

end;

destructor TAiChatG4F.Destroy;
begin

  inherited;
end;

function TAiChatG4F.InitChatCompletions: String;
Var
  AJSONObject, jToolChoice: TJSonObject;
  JArr: TJSonArray;
  JStop: TJSonArray;
  Lista: TStringList;
  I: Integer;
  LAsincronico: Boolean;
  LastMsg: TAiChatMessage;
  Res, LModel: String;
begin

//   result:= inherited InitChatCompletions();
  // exit;


  If User = '' then
    User := 'user';

  LModel := TAiChatFactory.Instance.GetBaseModel(GetDriverName, Model);

  If LModel = '' then
    LModel := 'llama-3.2-11b-text-preview';

  // Las funciones no trabajan en modo ascincrono
  LAsincronico := Self.Asynchronous and (not Self.Tool_Active);

  // En groq hay una restricción sobre las imágenes

  FClient.Asynchronous := LAsincronico;

  AJSONObject := TJSonObject.Create;
  Lista := TStringList.Create;

  Try

    if (ReasoningFormat = 'Raw') and (Tool_Active or (Response_format = tiaChatRfJson) or (Response_format = tiaChatRfJsonSchema)) then
    begin
      Raise Exception.Create('G4F Error: ReasoningFormat no puede ser "raw" cuando se usan Tools o JSON mode. Use "parsed" o "hidden".');
    end;

    AJSONObject.AddPair('stream', TJSONBool.Create(LAsincronico));

    If Tool_Active and (Trim(GetTools(TToolFormat.tfOpenAi).Text) <> '') then
    Begin
{$IF CompilerVersion < 35}
      JArr := TJSONUtils.ParseAsArray(GetTools(TToolFormat.tfOpenAi).Text);
{$ELSE}
      JArr := TJSonArray(TJSonArray.ParseJSONValue(GetTools(TToolFormat.tfOpenAi).Text));
{$ENDIF}
      If Not Assigned(JArr) then
        Raise Exception.Create('La propiedad Tools están mal definido, debe ser un JsonArray');
      AJSONObject.AddPair('tools', JArr);

      If (Trim(Tool_choice) <> '') then
      Begin
{$IF CompilerVersion < 35}
        jToolChoice := TJSONUtils.ParseAsObject(Tool_choice);
{$ELSE}
        jToolChoice := TJSonObject(TJSonArray.ParseJSONValue(Tool_choice));
{$ENDIF}
        If Assigned(jToolChoice) then
          AJSONObject.AddPair('tools_choice', jToolChoice);
      End;
    End;

    LastMsg := Messages.Last;
    If Assigned(LastMsg) then
    Begin
      If LastMsg.MediaFiles.Count > 0 then
      Begin
        AJSONObject.AddPair('messages', LastMsg.ToJSon); // Si tiene imágenes solo envia una entrada
      End
      Else
      Begin
        AJSONObject.AddPair('messages', GetMessages); // Si no tiene imágenes envía todos los mensajes
      End;
    End;

    AJSONObject.AddPair('model', LModel);

    if ReasoningFormat <> '' then
      AJSONObject.AddPair('reasoning_format', ReasoningFormat); // 'parsed, raw, hidden';

//    if ReasoningEffort <> '' then
//      AJSONObject.AddPair('reasoning_effort', ReasoningEffort); // 'none, default');

    AJSONObject.AddPair('temperature', TJSONNumber.Create(Trunc(Temperature * 100) / 100));
    AJSONObject.AddPair('max_tokens', TJSONNumber.Create(Max_tokens));

//    If Top_p <> 0 then
   //   AJSONObject.AddPair('top_p', TJSONNumber.Create(Top_p));

    AJSONObject.AddPair('user', User);
    AJSONObject.AddPair('n', TJSONNumber.Create(N));

    If (FResponse_format = tiaChatRfJsonSchema) then
    Begin
      AJSONObject.AddPair('response_format', TJSonObject.Create.AddPair('type', 'json_schema'))
    End
    Else If { LAsincronico or } (FResponse_format = tiaChatRfJson) then
      AJSONObject.AddPair('response_format', TJSonObject.Create.AddPair('type', 'json_object'))
    Else If (FResponse_format = tiaChatRfText) then
      AJSONObject.AddPair('response_format', TJSonObject.Create.AddPair('type', 'text'))
    Else
      AJSONObject.AddPair('response_format', TJSonObject.Create.AddPair('type', 'text'));

    Lista.CommaText := Stop;
    If Lista.Count > 0 then
    Begin
      JStop := TJSonArray.Create;
      For I := 0 to Lista.Count - 1 do
        JStop.Add(Lista[I]);
      AJSONObject.AddPair('stop', JStop);
    End;

    If Logprobs = True then
    Begin
      If Logit_bias <> '' then
        AJSONObject.AddPair('logit_bias', TJSONNumber.Create(Logit_bias));

      AJSONObject.AddPair('logprobs', TJSONBool.Create(Logprobs));

      If Top_logprobs <> '' then
        AJSONObject.AddPair('top_logprobs', TJSONNumber.Create(Top_logprobs));
    End;

    If Seed > 0 then
      AJSONObject.AddPair('seed', TJSONNumber.Create(Seed));

    Res := UTF8ToString(AJSONObject.ToJSon);
    Res := StringReplace(Res, '\/', '/', [rfReplaceAll]);
    Result := StringReplace(Res, '\r\n', '', [rfReplaceAll]);
  Finally
    AJSONObject.Free;
    Lista.Free;
  End;
end;





procedure Register;
begin
  RegisterComponents('MakerAI',
  [TAiG4FOllama,TAiG4FPollinations,TAiG4FNvidia,TAiG4FGroqChat,TAiG4FGemini]);
end;

{ TAiOllamaChat }


class function TAiG4FGemini.GetDriverName: string;
Begin
  Result := 'G4FGemini';
End;

class procedure TAiG4FGemini.RegisterDefaultParams(Params: TStrings);
Begin
  RegisterDefaultParamG4f(params,GlAIUrlGemini)
End;

class function TAiG4FGemini.CreateInstance(Sender: TComponent): TAiChat;
Begin
  Result := TAiG4FGemini.Create(Sender);
End;

constructor TAiG4FGemini.Create(Sender: TComponent);
begin
  inherited;
  ApiKey := 'secret';
  Model := 'meta-llama/llama-guard-4-12b';
  Url := GlAIUrlGemini;

end;

destructor TAiG4FGemini.Destroy;
begin

  inherited;
end;



{ TAiOllamaChat }

class function TAiG4FOllama.GetDriverName: string;
Begin
  Result := 'G4FOllama';
End;

class procedure TAiG4FOllama.RegisterDefaultParams(Params: TStrings);
Begin
  RegisterDefaultParamG4f(params,GlAIUrlOllama)
  (*

  Params.Clear;
  Params.Add('ApiKey=secret');
  Params.Add('Model=meta-llama/llama-guard-4-12b');
  Params.Add('MaxTokens=4096');
  Params.Add('URL=https://g4f.dev/api/ollama/');
//    Params.Add('URL=https://api.groq.com/openai/v1/');
*)
End;

class function TAiG4FOllama.CreateInstance(Sender: TComponent): TAiChat;
Begin
  Result := TAiG4FOllama.Create(Sender);
End;

constructor TAiG4FOllama.Create(Sender: TComponent);
begin
  inherited;
  ApiKey := 'secret';
  Model := 'meta-llama/llama-guard-4-12b';
  Url := GlAIUrlOllama;
end;

destructor TAiG4FOllama.Destroy;
begin

  inherited;
end;



{ TAiOllamaChat }

class function TAiG4FPollinations.GetDriverName: string;
Begin
  Result := 'G4FPollinations';
End;

class procedure TAiG4FPollinations.RegisterDefaultParams(Params: TStrings);
Begin
  RegisterDefaultParamG4f(params,GlAIUrlPollin)
End;

class function TAiG4FPollinations.CreateInstance(Sender: TComponent): TAiChat;
Begin
  Result := TAiG4FPollinations.Create(Sender);
End;

constructor TAiG4FPollinations.Create(Sender: TComponent);
begin
  inherited;
  ApiKey := 'secret';
//  Model := 'meta-llama/llama-guard-4-12b';
  Url := GlAIUrlPollin;
end;

destructor TAiG4FPollinations.Destroy;
begin

  inherited;
end;


{ TAiOllamaChat }

class function TAiG4FNvidia.GetDriverName: string;
Begin
  Result := 'G4FNVidia';
End;

class procedure TAiG4FNvidia.RegisterDefaultParams(Params: TStrings);
Begin
 RegisterDefaultParamG4f(params,GlAIUrlNvidia)
 (*
  Params.Clear;
  Params.Add('ApiKey=secret');

  Params.Add('MaxTokens=4096');
  Params.Add('URL=https://g4f.dev/api/nvidia/');
//    Params.Add('URL=https://api.groq.com/openai/v1/');
*)
End;

class function TAiG4FNvidia.CreateInstance(Sender: TComponent): TAiChat;
Begin
  Result := TAiG4FNvidia.Create(Sender);
End;

constructor TAiG4FNvidia.Create(Sender: TComponent);
begin
  inherited;
  ApiKey := 'secret';
//  Model := 'meta-llama/llama-guard-4-12b';
  Url := GlAIUrlNvidia;

end;

destructor TAiG4FNvidia.Destroy;
begin

  inherited;
end;


class function TAiG4FGroqChat.GetDriverName: string;
Begin
  Result := 'G4FGroq';
End;

class procedure TAiG4FGroqChat.RegisterDefaultParams(Params: TStrings);
Begin
  Params.Clear;
  Params.Add('ApiKey=secret');
  Params.Add('Model=llama-3.3-70b-versatile');
  Params.Add('MaxTokens=4096');
  Params.Add('URL=https://g4f.dev/api/groq/');
//    Params.Add('URL=https://api.groq.com/openai/v1/');
End;


class function TAiG4FGroqChat.CreateInstance(Sender: TComponent): TAiChat;
Begin
  Result := TAiG4FGroqChat.Create(Sender);
End;

constructor TAiG4FGroqChat.Create(Sender: TComponent);
begin
  inherited;
  ApiKey := 'secret';
  Model := 'meta-llama/llama-guard-4-12b';
  Url := GlAIUrlGroq;

end;

destructor TAiG4FGroqChat.Destroy;
begin

  inherited;
end;

function TAiG4FGroqChat.InitChatCompletions: String;
Var
  AJSONObject, jToolChoice: TJSonObject;
  JArr: TJSonArray;
  JStop: TJSonArray;
  Lista: TStringList;
  I: Integer;
  LAsincronico: Boolean;
  LastMsg: TAiChatMessage;
  Res, LModel: String;
begin
   result:= inherited InitChatCompletions()
   (*
  If User = '' then
    User := 'user';

  LModel := TAiChatFactory.Instance.GetBaseModel(GetDriverName, Model);

  If LModel = '' then
    LModel := 'llama-3.2-11b-text-preview';

  // Las funciones no trabajan en modo ascincrono
  LAsincronico := Self.Asynchronous and (not Self.Tool_Active);

  // En groq hay una restricción sobre las imágenes

  FClient.Asynchronous := LAsincronico;

  AJSONObject := TJSonObject.Create;
  Lista := TStringList.Create;

  Try

    if (ReasoningFormat = 'Raw') and (Tool_Active or (Response_format = tiaChatRfJson) or (Response_format = tiaChatRfJsonSchema)) then
    begin
      Raise Exception.Create('Groq Error: ReasoningFormat no puede ser "raw" cuando se usan Tools o JSON mode. Use "parsed" o "hidden".');
    end;

    AJSONObject.AddPair('stream', TJSONBool.Create(LAsincronico));

    If Tool_Active and (Trim(GetTools(TToolFormat.tfOpenAi).Text) <> '') then
    Begin
{$IF CompilerVersion < 35}
      JArr := TJSONUtils.ParseAsArray(GetTools(TToolFormat.tfOpenAi).Text);
{$ELSE}
      JArr := TJSonArray(TJSonArray.ParseJSONValue(GetTools(TToolFormat.tfOpenAi).Text));
{$ENDIF}
      If Not Assigned(JArr) then
        Raise Exception.Create('La propiedad Tools están mal definido, debe ser un JsonArray');
      AJSONObject.AddPair('tools', JArr);

      If (Trim(Tool_choice) <> '') then
      Begin
{$IF CompilerVersion < 35}
        jToolChoice := TJSONUtils.ParseAsObject(Tool_choice);
{$ELSE}
        jToolChoice := TJSonObject(TJSonArray.ParseJSONValue(Tool_choice));
{$ENDIF}
        If Assigned(jToolChoice) then
          AJSONObject.AddPair('tools_choice', jToolChoice);
      End;
    End;

    LastMsg := Messages.Last;
    If Assigned(LastMsg) then
    Begin
      If LastMsg.MediaFiles.Count > 0 then
      Begin
        AJSONObject.AddPair('messages', LastMsg.ToJSon); // Si tiene imágenes solo envia una entrada
      End
      Else
      Begin
        AJSONObject.AddPair('messages', GetMessages); // Si no tiene imágenes envía todos los mensajes
      End;
    End;

    AJSONObject.AddPair('model', LModel);

    if ReasoningFormat <> '' then
      AJSONObject.AddPair('reasoning_format', ReasoningFormat); // 'parsed, raw, hidden';

//?    if ReasoningEffort <> '' then
//?      AJSONObject.AddPair('reasoning_effort', ReasoningEffort); // 'none, default');

    AJSONObject.AddPair('temperature', TJSONNumber.Create(Trunc(Temperature * 100) / 100));
    AJSONObject.AddPair('max_tokens', TJSONNumber.Create(Max_tokens));

    If Top_p <> 0 then
      AJSONObject.AddPair('top_p', TJSONNumber.Create(Top_p));

    AJSONObject.AddPair('frequency_penalty', TJSONNumber.Create(Trunc(Frequency_penalty * 100) / 100));
    AJSONObject.AddPair('presence_penalty', TJSONNumber.Create(Trunc(Presence_penalty * 100) / 100));
    AJSONObject.AddPair('user', User);
    AJSONObject.AddPair('n', TJSONNumber.Create(N));

    If (FResponse_format = tiaChatRfJsonSchema) then
    Begin
      AJSONObject.AddPair('response_format', TJSonObject.Create.AddPair('type', 'json_schema'))
    End
    Else If { LAsincronico or } (FResponse_format = tiaChatRfJson) then
      AJSONObject.AddPair('response_format', TJSonObject.Create.AddPair('type', 'json_object'))
    Else If (FResponse_format = tiaChatRfText) then
      AJSONObject.AddPair('response_format', TJSonObject.Create.AddPair('type', 'text'))
    Else
      AJSONObject.AddPair('response_format', TJSonObject.Create.AddPair('type', 'text'));

    Lista.CommaText := Stop;
    If Lista.Count > 0 then
    Begin
      JStop := TJSonArray.Create;
      For I := 0 to Lista.Count - 1 do
        JStop.Add(Lista[I]);
      AJSONObject.AddPair('stop', JStop);
    End;

    If Logprobs = True then
    Begin
      If Logit_bias <> '' then
        AJSONObject.AddPair('logit_bias', TJSONNumber.Create(Logit_bias));

      AJSONObject.AddPair('logprobs', TJSONBool.Create(Logprobs));

      If Top_logprobs <> '' then
        AJSONObject.AddPair('top_logprobs', TJSONNumber.Create(Top_logprobs));
    End;

    If Seed > 0 then
      AJSONObject.AddPair('seed', TJSONNumber.Create(Seed));

    Res := UTF8ToString(AJSONObject.ToJSon);
    Res := StringReplace(Res, '\/', '/', [rfReplaceAll]);
    Result := StringReplace(Res, '\r\n', '', [rfReplaceAll]);
  Finally
    AJSONObject.Free;
    Lista.Free;
  End;
  *)
end;



Procedure InitChatModels;
Var
  Model: String;
Begin


  // ===================================================================
  // CONFIGURACIÓN GLOBAL DE OLLAMA (Defaults para todos sus modelos)
  // ===================================================================
  // Por defecto, Ollama es texto puro y no tiene herramientas nativas
  TAiChatFactory.Instance.RegisterUserParam('G4FGemini', 'Max_Tokens', '8000');
  TAiChatFactory.Instance.RegisterUserParam('G4FGemini', 'Temperature', '0.7');
  TAiChatFactory.Instance.RegisterUserParam('G4FGemini', 'Asynchronous', 'False');
  TAiChatFactory.Instance.RegisterUserParam('G4FGemini', 'Tool_Active', 'False');

  // Capa Física: Ollama por defecto no acepta binarios (solo texto)
  TAiChatFactory.Instance.RegisterUserParam('G4FGemini', 'NativeInputFiles', '[]');
  TAiChatFactory.Instance.RegisterUserParam('G4FGemini', 'NativeOutputFiles', '[]');

  // Capa Lógica: Habilidades nativas mínimas
  TAiChatFactory.Instance.RegisterUserParam('G4FGemini', 'ChatMediaSupports', '[]');

  // Intención: Por defecto queremos que todos tengan texto y razonamiento si lo exponen
  TAiChatFactory.Instance.RegisterUserParam('G4FGemini', 'EnabledFeatures', '[]');



End;





Initialization
TAiChatFactory.Instance.RegisterDriver(TAiG4FGroqChat);

TAiChatFactory.Instance.RegisterDriver(TAiG4FNvidia);


TAiChatFactory.Instance.RegisterDriver(TAiG4FPollinations);

TAiChatFactory.Instance.RegisterDriver(TAiG4FOllama);
TAiChatFactory.Instance.RegisterDriver(TAiG4FGemini);
InitChatModels;


end.
