unit principal;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, uJSON;

type
  TFormPrincipal = class(TForm)
    pgControl: TPageControl;
    formEnviar: TTabSheet;
    labelTokenEnviar: TLabel;
    labelRetornoEnviar: TLabel;
    editTokenEnviar: TEdit;
    btnEnviar: TButton;
    memoEnviar: TMemo;
    memoConteudo: TMemo;
    formConsultar: TTabSheet;
    labelTokenConsultar: TLabel;
    labelRetornoConsultar: TLabel;
    labelCNPJConsultar: TLabel;
    labelNumRec: TLabel;
    memoConsultar: TMemo;
    editTokenConsultar: TEdit;
    btnConsultar: TButton;
    editCNPJConsultar: TEdit;
    editNumRec: TEdit;
    formDownload: TTabSheet;
    labelRetornoDownload: TLabel;
    labelTokenDownload: TLabel;
    labelChaveDownload: TLabel;
    labelTpDown: TLabel;
    labelOpcoesDownload: TLabel;
    btnDownload: TButton;
    editTokenDownload: TEdit;
    memoDownload: TMemo;
    editChaveDownload: TEdit;
    editTpDownload: TEdit;
    checkExibir: TCheckBox;
    checkEnviaTxt: TCheckBox;
    Label1: TLabel;
    procedure btnEnviarClick(Sender: TObject);
    procedure btnConsultarClick(Sender: TObject);
    procedure btnDownloadClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormPrincipal: TFormPrincipal;

implementation

uses NFeApiFuncoes;

{$R *.dfm}

  procedure TFormPrincipal.btnEnviarClick(Sender: TObject);
  var
    retorno, nRec: String;
    jsonRetorno : TJSONObject;
  begin
    //Valida se for enviado o token para emitir o CT-e de exemplo
    if ((editTokenEnviar.Text <> '') and (memoConteudo.Text <> '')) then
    begin
      retorno := emitirNFe(editTokenEnviar.Text, memoConteudo.Text, checkEnviaTxt.Checked);
      memoEnviar.Text := retorno;

      if(memoEnviar.Text[1] = '{') then
      begin
        jsonRetorno := TJsonObject.Create(retorno);
        if(jsonRetorno.getString('status') = '200') then
          editNumRec.Text := jsonRetorno.getString('nsNRec');
      end
      else
      begin
        if pos('DOCTYPE html', retorno) > 0 then
        begin
          memoEnviar.Lines.Add(#13#10 + #13#10 + 'Codigo do erro: 400' + #13#10 + 'Motivo: Dados enviados são inválidos');
        end
        else
        begin
          jsonRetorno := TJsonObject.Create(Copy(retorno, Pos(': ', retorno) + 2, Length(retorno)));
          jsonRetorno := jsonRetorno.getJSONObject('erro');
          memoEnviar.Lines.Add(#13#10 + #13#10 + 'Codigo do erro: ' + jsonRetorno.getString('cStat') + #13#10 +
          'Motivo: ' + jsonRetorno.getString('xMotivo'));
        end;
      end;
    end
    else
    begin
      Showmessage('Todos os campos devem estar preenchidos');
    end;
  end;


  procedure TFormPrincipal.btnConsultarClick(Sender: TObject);
  var
    retorno: String;
    jsonRetorno : TJSONObject;
  begin
    //Valida se todos os campos foram preenchidos com algum valor
    if ((editTokenConsultar.Text <> '') and (editCNPJConsultar.Text <> '') and (editNumRec.Text <> '')) then
    begin
      retorno := consultarStatusProcessamento(editTokenConsultar.Text, editCNPJConsultar.Text, editNumRec.Text);
      memoConsultar.Text := retorno;

      if(memoConsultar.Text[1] = '{') then
      begin
        jsonRetorno := TJsonObject.Create(retorno);
        if(jsonRetorno.getString('status') = '200') then
          editChaveDownload.Text := jsonRetorno.getString('chNFe');
      end
      else
      begin
        jsonRetorno := TJsonObject.Create(Copy(retorno, Pos(': ', retorno) + 2, Length(retorno)));
        jsonRetorno := jsonRetorno.getJSONObject('erro');
        memoConsultar.Lines.Add(#13#10 + #13#10 + 'Codigo do erro: ' + jsonRetorno.getString('cStat') + #13#10 +
          'Motivo: ' + jsonRetorno.getString('xMotivo'));
      end;

    end
    else
    begin
      Showmessage('Todos os campos devem estar preenchidos');
    end;
  end;



  procedure TFormPrincipal.btnDownloadClick(Sender: TObject);
  var
    retorno: String;
    jsonRetorno: TJSONObject;
  begin
    if ((editTokenDownload.Text <> '') and (editChaveDownload.Text <> '') and (editTpDownload.Text <> '')) then
    begin
      //Valida se todos os campos foram preenchidos com algum valor
      retorno := downloadNFe(editTokenDownload.Text, editChaveDownload.Text, editTpDownload.Text, checkExibir.Checked);
      memoDownload.Text := retorno;

      if(memoDownload.Text[1] <> '{') then
      begin
          jsonRetorno := TJsonObject.Create(Copy(retorno, Pos(': ', retorno) + 2, Length(retorno)));
          memoDownload.Lines.Add(#13#10 + #13#10 + 'Codigo do erro: ' + jsonRetorno.getString('status') + #13#10 +
	            'Motivo: ' + jsonRetorno.getString('motivo'));
      end;
    end
    else
    begin
      Showmessage('Todos os campos devem estar preenchidos');
    end;
  end;

end.
