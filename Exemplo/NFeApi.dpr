program NFeApiExample;

uses
  Forms,
  principal in 'principal.pas' {FormPrincipal},
  NFeAPI in 'NFeAPI.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormPrincipal, FormPrincipal);
  Application.Run;
end.
