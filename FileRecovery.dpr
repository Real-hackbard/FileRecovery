program FileRecovery;

{%ToDo 'FileRecovery.todo'}

uses
  Forms,
  Main in 'Main.pas' {Form1},
  FileDetails in 'FileDetails.pas' {FileDetailsForm};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := '';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFileDetailsForm, FileDetailsForm);
  Application.Run;
end.
