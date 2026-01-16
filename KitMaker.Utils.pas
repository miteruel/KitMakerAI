unit KitMaker.Utils;

interface

uses
  classes,SysUtils,
  FMX.Memo, FMX.ListBox,
  uMakerAi.Chat.AiConnection;

procedure setCombo(const combo: TComboBox; const s: String;
  addifnot: boolean = false);

procedure SetComboIn(combo: TComboBox; const tex: string);

procedure AddMemTexto(FMemoPrompt: Tmemo; tex: String);

procedure DumpAICombo(Ai: TAiChatConnection; ComboDriver: TComboBox);
procedure ChangeAICombo(Ai: TAiChatConnection;
  ComboDriver, ComboModels: TComboBox);


type
  TListBoxHelper = Class helper for TListBox
    Function SelectedTexts(): String;
  End;

  TComboBoxhELPER = Class helper for TComboBox
    Function SelectedText(): String;

  End;

implementation

uses KitMaker.Task;

procedure setCombo(const combo: TComboBox; const s: String;
  addifnot: boolean = false);
var
  ix: integer;
begin
  ix := combo.Items.indexof(s);
  if ix < 0 then
    if addifnot then
    begin
      combo.Items.Add(s);

      ix := combo.Items.indexof(s);

    end;
  if ix >= 0 then
    combo.itemindex := ix

end;

{ TListBoxHelper }

function TListBoxHelper.SelectedTexts: String;
begin
  result := '';
  if itemindex >= 0 then
  begin
    result := Items[itemindex];
  end;
end;

{ TComboBoxhELPER }

function TComboBoxhELPER.SelectedText: String;
begin
  result := '';
  if itemindex >= 0 then
  begin
    result := Items[itemindex];
  end;
end;

procedure AddMemTexto(FMemoPrompt: Tmemo; tex: String);
begin

  if tex <> '' then
  begin

    TaskA >
    procedure
    begin
      FMemoPrompt.BeginUpdate;
      Try
        FMemoPrompt.Lines.Text := FMemoPrompt.Lines.Text + tex + ' ';
        FMemoPrompt.GoToTextEnd;
      Finally
        FMemoPrompt.EndUpdate;
        // Application.ProcessMessages;
      End;

    end;
  end;

end;

procedure SetComboIn(combo: TComboBox; const tex: string);
Var

  indi: integer;
begin
  Try
    if combo <> nil then
    begin
      if combo.Items.Count > 0 then
      begin
        indi := combo.Items.indexof(tex);
        if indi < 0 then
          indi := 0;
        combo.itemindex := indi;
      end;
    end;
  Except
  End;
end;

procedure ChangeAICombo(Ai: TAiChatConnection;
  ComboDriver, ComboModels: TComboBox);
Var
  DriverName: String;
  List: TStringList;
begin
  If Assigned(ComboDriver.Selected) then
  Begin
    DriverName := Trim(ComboDriver.Text);

    Ai.DriverName := DriverName;

    List := Ai.GetModels;
    Try
      List.Sort;
      ComboModels.Items.Text := List.Text;
    Finally
      List.Free;
    End;
  End;

end;

procedure DumpAICombo(Ai: TAiChatConnection; ComboDriver: TComboBox);
Var
  List: TStringList;

begin

  Ai.params.Values['Asynchronous'] := 'False';

  Try
    List := Ai.GetDriversNames;
    Try
      List.Sort;
      ComboDriver.Items.Text := List.Text;
      If ComboDriver.Items.Count > 0 then
        ComboDriver.itemindex := 0;
    Finally
      List.Free;
    End;
  Except

  End;
end;

end.
