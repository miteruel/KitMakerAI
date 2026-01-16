program MiKitOCRDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainOCRKit in 'MainOCRKit.pas' {FormOCRKIT},
  uMakerAI.Ollama.PdfIUM in 'uMakerAI.Ollama.PdfIUM.pas',
  KitMaker.Pdf.Extractor in 'KitMaker.Pdf.Extractor.pas',
  KitMaker.Utils in 'KitMaker.Utils.pas',
  uMakerAi.Chat.G4F in 'uMakerAi.Chat.G4F.pas',
  DX.Pdf.Dynamic in 'DX.Pdf.Dynamic.pas';

(*
uses
  System.StartUpCopy,
  FMX.Forms,
  MiuOllamaPDFMain in 'MiuOllamaPDFMain.pas' {Form19},
  uMakerAI.Ollama.PdfIUM in '..\..\Demos\MIChat\uMakerAI.Ollama.PdfIUM.pas',
  uMakerAI.Ollama.Pdf in '..\uMakerAI.Ollama.Pdf.pas',
  uGhostscriptPDF in '..\uGhostscriptPDF.pas',
  Mit.MakerAI.Ollama.Ocr in '..\..\Demos\MIChat\Mit.MakerAI.Ollama.Ocr.pas',
  uMakerAi.Chat.G4F_Groq in 'E:\d2025\Mit-Developer-Tools-master\MiaMaker\uMakerAi.Chat.G4F_Groq.pas',
  uMakerAi.Chat.G4F_pollinations in 'E:\D2025\Mit-Developer-Tools-master\MiaMaker\uMakerAi.Chat.G4F_pollinations.pas';
    *)
{$R *.res}

begin
  ReportMemoryLeaksOnShutdown:=true;
  Application.Initialize;
  Application.CreateForm(TFormOCRKIT, FormOCRKIT);
  Application.Run;
end.
Application.CreateForm(TForm19, Form19);
  Application.CreateForm(TForm19, Form19);

  //  ,  KitMaker.Local.Speech in '..\..\Demos\MIChat\KitMaker.Local.Speech.pas'
