unit NFeApiFuncoes;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, IdHTTP, ShellApi, IdCoderMIME, EncdDecd;

//Assinatura das fun��es
function enviaConteudoParaAPI(token: String; conteudo:TStringStream; url:String; isTxt:boolean):String;
function emitirNFe(token, conteudo: String; isTxt: boolean): String;
function consultarStatusProcessamento(token, CNPJ, nsNRec: String): String;
function downloadNFe(token, chNFe, tpDown:String; exibeNaTela: boolean): String;
function salvaXML(retorno, caminho, chNFe: String): String;
function salvaJSON(retorno, caminho, chNFe: String): String;
function salvaPDF(retorno, caminho, chNFe: String): String;

implementation

//Implementar as fun��es descritas na interface


  //Fun��o gen�rica de envio para um url, contendo o token no header
  function enviaConteudoParaAPI(token: String; conteudo:TStringStream; url:String; isTxt:boolean): String;
  var
    retorno: String;
    HTTP: TIdHTTP;  //Dispon�vel na aba 'Indy Servers'
  begin
    HTTP := TIdHTTP.Create(nil);

    try

      if isTxt then  //Informa que vai mandar um TXT
      begin
        HTTP.Request.ContentType := 'text/plain';
      end
      else	//Se for JSON
      begin
        HTTP.Request.ContentType := 'application/json';
      end;


      //Avisa o uso de UTF-8
      HTTP.Request.ContentEncoding := 'UTF-8';

      //Adiciona o token ao header
      HTTP.Request.CustomHeaders.Values['X-AUTH-TOKEN'] := token;

      //Faz o envio por POST do json para a url
      try
        retorno := HTTP.Post(url, conteudo);

      except
        on E:EIdHTTPProtocolException do

          Case HTTP.ResponseCode of
          //Se o json conter algum erro
            400: begin
              retorno :=  '400: ' + e.ErrorMessage;
              ShowMessage('Json inv�lido, verifique o retorno para mais informa��es');
            end;
            //Se o token n�o for enviado ou for inv�lido
            401: begin
              retorno := '401: ' + e.ErrorMessage;
              ShowMessage('Token n�o enviado ou inv�lido');
            end;
            //Se o token informado for inv�lido 403
            403: begin
              retorno := '403: ' + e.ErrorMessage;
              ShowMessage('Token sem permiss�o');
            end;
            //Se n�o encontrar o que foi requisitado
            404:begin
              retorno := '404: ' + e.ErrorMessage;
              ShowMessage('N�o encontrado, verifique o retorno para mais informa��es');
            end;
            //Caso contr�rio
            else
              retorno := HTTP.ResponseText + ': ' + e.ErrorMessage;
              ShowMessage('Erro desconhecido, verifique o retorno para mais informa��es');
          end;

      end;

    finally
      conteudo.Free();
      HTTP.Free();
    end;

    //Devolve o json de retorno da API
    Result := retorno;
  end;

  //Envia NFe
  function emitirNFe(token, conteudo: String; isTxt: boolean): String;
  var
    conteudoEnviar: TStringStream;
    urlEnvio, retorno: String;
  begin
    conteudoEnviar := TStringStream.Create(UTF8Encode(conteudo));
    //Informa a url para onde deve ser enviado
    urlEnvio :=  'https://nfe.ns.eti.br/nfe/issue';

    retorno := enviaConteudoParaAPI(token, conteudoEnviar, urlEnvio, isTxt);
    Result := retorno;
  end;

  //Consulta status de processamento do NFe
  function consultarStatusProcessamento(token, CNPJ, nsNRec: String): String;
  var
    json: TStringStream;
    urlEnvio, retorno: String;
  begin
    //Monta o Json
    json := TStringStream.Create('{' +
			'"X-AUTH-TOKEN": "' + token + '",' +
			'"CNPJ": "' + CNPJ + '",' +
			'"nsNRec": "' + nsNRec + '"' +
		'}');

    //Informa a url para onde deve ser enviado
    urlEnvio := 'https://nfe.ns.eti.br/nfe/issue/status';

    //Envia o json para a url
    retorno := enviaConteudoParaAPI(token, json, urlEnvio, False);

    //Devolve o retorno da API
    Result := retorno;
  end;


  //Download de NFe
  function downloadNFe(token, chNFe, tpDown: String; exibeNaTela: boolean): String;
  var
    json: TStringStream;
    baixarXML, baixarPDF, baixarJSON: boolean;
    caminho, status, urlEnvio, retorno: String;
  begin
    //Monta o Json
    json := TStringStream.Create('{' +
			'"X-AUTH-TOKEN": "' + token + '",' +
			'"chNFe": "' + chNFe + '",' +
			'"tpDown": "' + tpDown + '"' +
		'}');

    //Informa a url para onde deve ser enviado
    urlEnvio := 'https://nfe.ns.eti.br/nfe/get';

    //Envia o json para a url
    retorno := enviaConteudoParaAPI(token, json, urlEnvio, False);

    //Pega o status de retorno da requisi��o
    status := Copy(retorno, Pos('"status": ', retorno) + 11, 3);

    //Informa o diretorio onde salvar o arquivo
    caminho := '';

    //Checa o que baixar com base no tpDown informado
    if Pos('X', tpDown) <> 0 then
      baixarXML := true;
    if Pos('P', tpDown) <> 0 then
      baixarPDF := true;
    if Pos('J', tpDown) <> 0 then
      baixarJSON := true;

    //Se o retorno da API for positivo, salva o que foi solicitado
    if status = '200' then
    begin
      //Checa se deve baixar XML
      if baixarXML = true then
        salvaXML(retorno, caminho, chNFe);

      //Checa se deve baixar JSON
      if baixarJSON = true then
        //Se n�o baixou XML, baixa JSON
        if baixarXML <> true then
          salvaJSON(retorno, caminho, chNFe);

      //Checa se deve baixar PDF
      if baixarPDF = true then
        salvaPDF(retorno, caminho, chNFe);
        //Caso tenha sido marcada a op��o de de exibir em tela, abre o PDF salvo
        if exibeNaTela then
          ShellExecute(0, nil, PChar(caminho + chNFe + '-NFe.pdf'), nil, nil, SW_SHOWNORMAL);
    end
    else
    begin
      Showmessage('Ocorreu um erro, veja o Retorno da API para mais informa��es');
    end;

    //Devolve o retorno da API
    Result := retorno;
  end;


  //Fun��o para salvar o XML de retorno
  function salvaXML(retorno, caminho, chNFe: String): String;
  var
    arquivo: TextFile;
    inicioRetorno, finalRetorno: Integer;
    conteudoSalvar, localParaSalvar: String;
  begin
    //Seta o caminho para o arquivo XML
    localParaSalvar := caminho + chNFe + '-NFe.xml';

    //Associa o arquivo ao caminho
    AssignFile(arquivo, localParaSalvar);
    //Abre para escrita o arquivo
    Rewrite(arquivo);

    //Separa o retorno
    inicioRetorno := Pos('"xml":"<', retorno) + 7;
    finalRetorno := Pos('/nfeProc>', retorno) + 9;

    //Copia o retorno
    conteudoSalvar := Copy(retorno, inicioRetorno, finalRetorno - inicioRetorno);
    //Ajeita o XML retirando as barras antes das aspas duplas
    conteudoSalvar := StringReplace(conteudoSalvar, '\"', '"', [rfReplaceAll, rfIgnoreCase]);

    //Escreve o retorno no arquivo
    Writeln(arquivo, conteudoSalvar);

    //Fecha o arquivo
    CloseFile(arquivo);
  end;


  //Fun��o para salvar o JSON de retorno
  function salvaJSON(retorno, caminho, chNFe: String): String;
  var
    arquivo: TextFile;
    inicioRetorno, finalRetorno: Integer;
    conteudoSalvar, localParaSalvar: String;
  begin
    //Seta o caminho para o arquivo JSON
    localParaSalvar := caminho + chNFe + '-NFe.json';

    //Associa o arquivo ao caminho
    AssignFile(arquivo, localParaSalvar);
    //Abre para escrita o arquivo
    Rewrite(arquivo);

    //Separa o retorno
    inicioRetorno := Pos('"nfeProc":', retorno) + 10;

    //Checa se no retorno existe base64 de PDF
    if(Pos('"pdf":"', retorno) > 0) then
    begin
      //Se existir, o json vai at� onde come�a a tag de pdf
      finalRetorno := Pos('"pdf":"', retorno) - 1;
    end
    else
    begin
      //Se n�o existir, o json vai at� o final
      finalRetorno := Length(retorno);
    end;

    //Copia o retorno
    conteudoSalvar := Copy(retorno, inicioRetorno, finalRetorno - inicioRetorno);

    //Escreve o retorno no arquivo
    Writeln(arquivo, conteudoSalvar);

    //Fecha o arquivo
    CloseFile(arquivo);
  end;


  //Fun��o para salvar o PDF de retorno
  function salvaPDF(retorno, caminho, chNFe: String): String;
  var
    inicioRetorno, finalRetorno: Integer;
    conteudoSalvar, localParaSalvar: String;
    base64decodificado: TStringStream;
    arquivo: TFileStream;
  begin
    ////Seta o caminho para o arquivo PDF
    localParaSalvar := caminho + chNFe + '-NFe.pdf';

    //Separa o base64
    inicioRetorno := Pos('"pdf":"', retorno) + 7;
    finalRetorno := Length(retorno);

    //Copia e cria uma TString com o base64
    conteudoSalvar := Copy(retorno, inicioRetorno, finalRetorno - inicioRetorno);
    base64decodificado := TStringStream.Create(conteudoSalvar);

    //Cria o arquivo .pdf e decodifica o base64 para o arquivo
    try
      arquivo := TFileStream.Create(localParaSalvar, fmCreate);
      try
        DecodeStream(base64decodificado, arquivo);
      finally
        arquivo.Free;
      end;
    finally
      base64decodificado.Free;
    end;
  end;
end.