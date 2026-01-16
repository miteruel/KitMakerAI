unit MainOCRKit;

//
// Donado por  Antonio Alcázar al proyecto MakerAI
//
// - GitHub: https://github.com/gustavoeenriquez/

interface

uses

  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.JSON, System.Net.HttpClient,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
DX.Pdf.Dynamic,
  uMakerAi.Core, uMakerAi.Chat.Messages, uMakerAi.Chat.Tools, uMakerAi.Chat,
  uMakerAi.Chat.Ollama, // uMakerAi.Ollama.Pdf,

  FMX.Layouts, FMX.Memo.Types, FMX.StdCtrls, FMX.Controls.Presentation,
  FMX.ScrollBox, FMX.Memo, uMakerAi.Tools.Functions,

  uMakerAi.Ollama.PdfIUM, uMakerAi.Chat.AiConnection,
  // Voludi_PyPDF2,

  uMakerAi.Chat.G4F, FMX.ListBox, FMX.Media, FMX.TabControl, FMX.Objects,
  System.Skia, FMX.Edit, FMX.Skia;

type
  TFormOCRKIT = class(TForm)
    Layout1: TLayout;
    LayoutTop: TLayout;
    Layout4: TLayout;
    Layout5: TLayout;
    Layout6: TLayout;
    MemoPrompt: TMemo;
    BtnAskToIA: TButton;
    OpenDialog1: TOpenDialog;
    AiFunctions1: TAiFunctions;
    AiOllamaPdfTool1: TAiOllamaPdfIUMTool;
    AiDelegada: TAiChatConnection;
    AIMain: TAiChatConnection;
    MediaPlayerss: TMediaPlayer;
    TabControl1: TTabControl;
    TabItemChat: TTabItem;
    Layout3: TLayout;
    MemoChat: TMemo;
    Splitter1: TSplitter;
    LblLog: TLabel;
    TabOCR: TTabItem;
    BtnDirect: TButton;
    Text1: TText;
    Text2: TText;
    Button1: TButton;
    SaveDialog1: TSaveDialog;
    CheckFun: TCheckBox;
    ChAttachPDFs: TCheckBox;
    layIndentation: TRectangle;
    layIndentationTitleDescription: TLayout;
    lblIndentationTitle: TLabel;
    lblIndentationDescription: TLabel;
    imgIndentation: TSkSvg;
    EditButton3: TEditButton;
    Label16: TLabel;
    SkSvg13: TSkSvg;
    edtPDFile: TEdit;
    TabConfig: TTabItem;
    Rectangle1: TRectangle;
    Layout7: TLayout;
    Label3: TLabel;
    SkSvg1: TSkSvg;
    ComboDriver: TComboBox;
    ComboModels: TComboBox;
    Rectangle2: TRectangle;
    Layout8: TLayout;
    Label1: TLabel;
    SkSvg2: TSkSvg;
    ComboDriverOCR: TComboBox;
    ComboModelOCR: TComboBox;
    Text3: TText;
    Text4: TText;
    Text5: TText;
    Button2: TButton;
    Timer1: TTimer;
    Rectangle3: TRectangle;
    Layout9: TLayout;
    Label7: TLabel;
    Label8: TLabel;
    SkSvg3: TSkSvg;
    EdDestino: TEdit;
    EditButton1: TEditButton;
    Label9: TLabel;
    SkSvg4: TSkSvg;
    CheckBoxCache: TCheckBox;
    Rectangle4: TRectangle;
    Layout2: TLayout;
    Label10: TLabel;
    Rectangle5: TRectangle;
    Layout10: TLayout;
    Label2: TLabel;
    SkSvg5: TSkSvg;
    procedure BtnAskToIAClick(Sender: TObject);
    procedure BtnDirectClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure AiFunctions1Functions0PDFToTextConverterAction(Sender: TObject;
      FunctionAction: TFunctionActionItem; FunctionName: string;
      ToolCall: TAiToolsFunction; var Handled: Boolean);
    procedure AiOllamaPdfTool1Progress(Sender: TObject;
      CurrentPage, TotalPages: Integer; const StatusMsg, texto: string;
      var ok: Boolean);
    procedure AiFunctions1Functions1CualEsMiNombreAction(Sender: TObject;
      FunctionAction: TFunctionActionItem; FunctionName: string;
      ToolCall: TAiToolsFunction; var Handled: Boolean);
    procedure ComboDriverChange(Sender: TObject);
    procedure ComboModelsChange(Sender: TObject);
    procedure AIMainError(Sender: TObject; const ErrorMsg: string;
      Exception: Exception; const AResponse: IHTTPResponse);
    procedure CheckFunChange(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure AIMainReceiveDataEnd(const Sender: TObject; aMsg: TAiChatMessage;
      AResponse: TJSONObject; aRole, aText: string);
    procedure ChAttachPDFsChange(Sender: TObject);
    procedure EditButton3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure ComboDriverOCRChange(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure EditButton1Click(Sender: TObject);
    procedure ComboModelOCRChange(Sender: TObject);
    procedure TabControl1Change(Sender: TObject);
    procedure CheckBoxCacheChange(Sender: TObject);
  private
    paso: Integer;
    { Private declarations }
    procedure AssignModel(const DriverName, ModelName: String);
    procedure UsarFunctionCalling();
    procedure UsarChatTool();

  public

    procedure AddLog_(const Value: String);
    procedure InitChats;
    procedure AfterInit;
    procedure SelectPDF();

    { Public declarations }
  end;

var
  FormOCRKIT: TFormOCRKIT;

implementation

{$R *.fmx}

uses
  KitMaker.Task,
  KitMaker.Utils,
  System.IOUtils;

procedure TFormOCRKIT.InitChats;

begin

  AiDelegada.RegisterUserParam('Ollama', 'Url', 'http://127.0.0.1:11434/');
  AiDelegada.RegisterUserParam('Ollama', 'Temperature', '0.7');
  AiDelegada.RegisterUserParam('Ollama', 'Asynchronous', 'False');

  AiDelegada.RegisterUserParam('Ollama', 'ResponseTimeOut', '720000');


  AIMain.params.Values['Asynchronous'] := 'False';

  LayoutTop.Visible := False;
  TabControl1.ActiveTab := TabConfig;
  DumpAICombo(AIMain, ComboDriver);
  DumpAICombo(AiDelegada, ComboDriverOCR);


  {$IFDEF MSWINDOWS}
    Timer1.Enabled := True;
  {$ENDIF}

  EdDestino.Text := TPath.GetTempFileName + '.txt';
  if PDFiumHandle=0 then
  begin
    ShowMessage('nolib')
  end else
  begin
 // ShowMessage(' di si si lib')

  end;

end;

procedure TFormOCRKIT.AfterInit;

begin
  inc(paso);
  case paso of
    1:
      SetComboIn(ComboDriverOCR, 'Ollama');
    2:
      SetComboIn(ComboModelOCR, 'deepseek-ocr:latest');
    3:
      Timer1.Enabled := False;
  end;

end;

procedure TFormOCRKIT.TabControl1Change(Sender: TObject);
begin
  LayoutTop.Visible := TabControl1.ActiveTab <> TabConfig
end;

procedure TFormOCRKIT.Timer1Timer(Sender: TObject);
begin

  AfterInit;
end;


procedure TFormOCRKIT.AiFunctions1Functions0PDFToTextConverterAction
  (Sender: TObject; FunctionAction: TFunctionActionItem; FunctionName: string;
  ToolCall: TAiToolsFunction; var Handled: Boolean);
var
  ParamFileName: string;
  TempFileName: string;
  Res: string;
begin
  Handled := True;
  Res := '';

  // 1. Parámetro opcional
  ParamFileName := ToolCall.params.Values['PDFFileName'];

  // 2. Si viene archivo adjunto (lo normal en Function Calling)
  if ToolCall.AskMsg.MediaFiles.Count > 0 then
  begin
    for var MF in ToolCall.AskMsg.MediaFiles do
    begin
      // 3. Crear nombre temporal aleatorio
      TempFileName := TPath.Combine(TPath.GetTempPath,
        TGUID.NewGuid.ToString.Replace('{', '').Replace('}', '') + '.pdf');

      try
        // 4. Guardar PDF temporal
        MF.SaveToFile(TempFileName);

        // 5. Extraer texto
        Res := AiOllamaPdfTool1.ExtractText(TempFileName);

      finally
        // 6. Eliminar archivo temporal
        if TFile.Exists(TempFileName) then
          TFile.Delete(TempFileName);
      end;
    end;
  end
  else
    // 7. Si no hay MediaFiles pero viene ruta explícita
    if (ParamFileName <> '') and TFile.Exists(ParamFileName) then
    begin
      Res := AiOllamaPdfTool1.ExtractText(ParamFileName);
    end
    else
    begin
      Res := 'No se encontraron archivos PDF para analizar';
    end;

  // 8. Respuesta a la función
  ToolCall.Response := Res;
end;

procedure TFormOCRKIT.AiFunctions1Functions1CualEsMiNombreAction
  (Sender: TObject; FunctionAction: TFunctionActionItem; FunctionName: string;
  ToolCall: TAiToolsFunction; var Handled: Boolean);

var
  tipo, Res: string;
begin
  Handled := True;
  Res := 'Antonio Alcazar ';

  // 1. Parámetro opcional
  tipo := ''; // ToolCall.Params.Values['tipo'];
  if tipo = 'apodo' then
  begin
    Res := 'toni'
  end
  else
  begin

    Res := Res + tipo;
  end;

  // 8. Respuesta a la función
  ToolCall.Response := Res;
end;

procedure TFormOCRKIT.AIMainError(Sender: TObject; const ErrorMsg: string;
  Exception: Exception; const AResponse: IHTTPResponse);
begin
  TaskA >
  procedure
  begin
      ShowMessage(ErrorMsg);
  end;
end;

procedure TFormOCRKIT.AIMainReceiveDataEnd(const Sender: TObject;
  aMsg: TAiChatMessage; AResponse: TJSONObject; aRole, aText: string);
begin
  MemoChat.Lines.Add(aText);

end;

procedure TFormOCRKIT.AiOllamaPdfTool1Progress(Sender: TObject;
  CurrentPage, TotalPages: Integer; const StatusMsg, texto: string;
  var ok: Boolean);
begin
  if (CurrentPage > 0) and (CurrentPage < 2) then
  begin
    ok := True
  end
  else
  begin

    ok := False
  end;
  if ok then
  begin
    AddLog_(StatusMsg);

  end;
  if texto <> '' then
  begin
    AddLog_(copy(texto, 1, 60));
  end;
end;

procedure TFormOCRKIT.BtnAskToIAClick(Sender: TObject);
var
  Prompt, Res: String;
  MF: TAIMediaFile;
  Msg: TAiChatMessage;
begin

  Prompt := MemoPrompt.Lines.Text;

  if edtPDFile.Text <> '' then
    if not FileExists(edtPDFile.Text) then
    begin
      edtPDFile.Text := ''
    end;

  If ChAttachPDFs.IsChecked then
    if edtPDFile.Text = '' then

    Begin
      If OpenDialog1.Execute then
      Begin
        edtPDFile.Text := OpenDialog1.FileName;
      End;

    End;
  if (edtPDFile.Text <> '') and

    ChAttachPDFs.IsChecked then
  Begin
    MF := TAIMediaFile.Create;
    MF.LoadFromfile(edtPDFile.Text);

    // TTask.Run(
    TaskA +
    procedure
    begin
      Res := AIMain.AddMessageAndRun(Prompt + ' ' + edtPDFile.Text,
        'user', [MF]);

      TaskA >
       procedure
        begin
          MemoChat.Lines.Add(Res);
        end;
    end;
  End
  Else
  Begin
    TaskA +
    procedure
    begin
      Res := AIMain.AddMessageAndRun(Prompt, 'user', []);
      TaskA >
      procedure
      begin
        MemoChat.Lines.Add(Res);
      end;
    end;
  End;

  // ChAttachPDF.IsChecked := False;
end;

procedure TFormOCRKIT.ChAttachPDFsChange(Sender: TObject);
begin
  CheckFunChange(Sender)
end;

procedure TFormOCRKIT.CheckBoxCacheChange(Sender: TObject);
begin
  if CheckBoxCache.IsChecked then
  begin
    AiOllamaPdfTool1.CacheTest :=
      'E:\DELPHI13\KitMakerAI\Win64\Debug\cache.txt';
  end
  else
  begin
    AiOllamaPdfTool1.CacheTest := '';
  end;
end;

procedure TFormOCRKIT.CheckFunChange(Sender: TObject);
var
  ok: Boolean;
begin
  ok := CheckFun.IsChecked;
  if ok then
  begin
    UsarFunctionCalling();
  end
  else
  begin
    UsarChatTool();
  end;
end;

procedure TFormOCRKIT.UsarFunctionCalling();
begin

  LblLog.Text := 'Uitlizando Function Calling';
  ChAttachPDFs.IsChecked := True;
  MemoPrompt.Lines.Text := 'Extrae el texto del PDF Adjunto';

  AIMain.AiChat.PdfTool := Nil; // No Necesita este parámetro
  AIMain.AiChat.Tool_Active := True;
  AIMain.params.Values['Tool_Active'] := 'True';
  AIMain.params.Values['Asynchronous'] := 'False';

  AIMain.AiFunctions := AiFunctions1;
  AIMain.ChatMode := TAiChatMode.cmConversation; // Modo de chat conversación
  AIMain.AiChat.EnabledFeatures := [TAiChatMediaSupport.Tcm_Pdf];
  // El usuario espera que retorne el contenido del pdf
  AIMain.AiChat.ChatMediaSupports := [TAiChatMediaSupport.Tcm_Pdf];
  // el modelo SI maneja pdf por de fecto

end;

procedure TFormOCRKIT.UsarChatTool();
begin

  LblLog.Text := 'Uitlizando Chat Tool';
  // ChAttachPDFs.IsChecked := True;
  MemoPrompt.Lines.Text := 'Haz un resumen de este texto adjunto';
  // MemoPrompt.Lines.Text := 'Extrae el texto del PDF Adjunto';

  // kimi-k2-thinking:cloud

  AIMain.AiChat.PdfTool := AiOllamaPdfTool1;
  // Asigna el tool a ollama para procesar pdf
  AIMain.AiChat.Tool_Active := False;
  AIMain.params.Values['Tool_Active'] := 'False';

  if ChAttachPDFs.IsChecked then
  begin
    AIMain.params.Values['Asynchronous'] := 'False';
  end
  else
  begin
    AIMain.params.Values['Asynchronous'] := 'True';
  end;

  AIMain.AiFunctions := nil;
  // AIMain.toolAiChat.Tool_Active := False; // Este modelo no maneja Function Callings
  AIMain.ChatMode := TAiChatMode.cmConversation; // Modo de chat conversación
  // AIMain.ChatMediaSupports := []; // el modelo no maneja ningún medio por defecto
  AIMain.AiChat.EnabledFeatures := [TAiChatMediaSupport.Tcm_Pdf];

end;

procedure TFormOCRKIT.AddLog_(const Value: String);
begin
  TThread.Queue(nil,
    procedure
    begin
      MemoChat.Lines.Add(Value);
    end);

end;

procedure TFormOCRKIT.FormCreate(Sender: TObject);
begin
  paso := 0;

  InitChats;
  UsarChatTool();
  // kit:=TAiKitSpeechTool.Create(self)
end;

procedure TFormOCRKIT.ComboDriverChange(Sender: TObject);
begin
  Cursor := crHourGlass;
  Try
    ChangeAICombo(AIMain, ComboDriver, ComboModels)
  Finally
    Cursor := crDefault;
  End;

end;

procedure TFormOCRKIT.ComboDriverOCRChange(Sender: TObject);
begin
  Cursor := crHourGlass;
  Try
    ChangeAICombo(AiDelegada, ComboDriverOCR, ComboModelOCR)
  Finally
    Cursor := crDefault;
  End;

end;

procedure TFormOCRKIT.ComboModelOCRChange(Sender: TObject);

Var
  DriverName, ModelName: String;
begin
  If Assigned(ComboModelOCR.Selected) then
  Begin
    DriverName := ComboDriverOCR.Text;
    ModelName := ComboModelOCR.Text;
    AiDelegada.DriverName := DriverName;
    AiDelegada.Model := ModelName;

  End;
end;

procedure TFormOCRKIT.ComboModelsChange(Sender: TObject);
Var
  DriverName, ModelName: String;
begin
  If Assigned(ComboModels.Selected) then
  Begin
    DriverName := ComboDriver.Text;
    ModelName := ComboModels.Text;
    AssignModel(DriverName, ModelName);
  End;
end;

procedure TFormOCRKIT.EditButton1Click(Sender: TObject);
begin
  if (SaveDialog1.Execute) then
  begin
    EdDestino.Text := SaveDialog1.FileName;
  end;

end;

procedure TFormOCRKIT.AssignModel(const DriverName, ModelName: String);
begin
  // 1. ASIGNACIÓN DEL DRIVER (Esto carga los DefaultParams del Factory al AiConn.Params)
  AIMain.DriverName := DriverName;
  AIMain.Model := ModelName;

  // AddLog(Format('Modelo cargado: %s (%s)', [ModelName, DriverName]));
end;

procedure TFormOCRKIT.BtnDirectClick(Sender: TObject);
Var
  Res: String;
begin

  If OpenDialog1.Execute then
  Begin

    TaskA +
    procedure
    begin
      Res := AiOllamaPdfTool1.ExtractText(OpenDialog1.FileName);

      TaskA >
      procedure
      begin
        MemoChat.Text := Res;
        if EdDestino.Text <> '' then
        begin
          MemoChat.Lines.SaveToFile(EdDestino.Text)
        end;
      end;
    end;
  End;
end;



// var n:integer=0;

procedure TFormOCRKIT.Button1Click(Sender: TObject);
// var nafi:string;
// s:string;
begin
  (*
    MediaPlayerss.Stop;
    s:=kit.ToToSo.InfoTTS;
    MemoChat.Lines.Add(s);
    //   kit.Speaks(MemoPrompt.Text);
    if (n>2) then
    begin
    n:=0;
    end;

    inc(n);
    nafi:=ExeVer_/('kitwav'+stints(n)+'.wav');
    kit.SaveToWAV(MemoPrompt.Text,nafi,'es');
    MediaPlayerss.FileName:=nafi;
    MediaPlayerss.Play;
  *)
end;

procedure TFormOCRKIT.Button2Click(Sender: TObject);
begin
  TabControl1.ActiveTab := TabItemChat
end;

procedure TFormOCRKIT.SelectPDF();
begin
  if (OpenDialog1.Execute) then
  begin
    edtPDFile.Text := OpenDialog1.FileName;
    ChAttachPDFs.IsChecked := True;
    // HTMLFormat();
  end;

end;

procedure TFormOCRKIT.EditButton3Click(Sender: TObject);
begin
  SelectPDF();

end;

end.

voludi_io
