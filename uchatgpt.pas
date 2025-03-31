unit uChatGpt;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, fpjson, jsonparser, opensslsockets,Dialogs;


type
  { TChatCompletion }
  TChatGPTCompletion = class
  public
    {
      Calls the ChatGPT Chat Completion endpoint using an array of messages
      for conversation context. Returns the assistant's reply as a string.
    }
    class function GetChatCompletion(
      const APIKey: string;
      Messages: TJSONArray;
      const Model: string;
      const ATemperature: Double = 0.1;
      const AMaxTokens: Integer = 4096
    ): string;

    {
      Gets a list of models from OpenAI /v1/models endpoint.
      Returns a TStringList of model "id" values. The caller is
      responsible for freeing the returned TStringList.
    }
    class function GetModelsList(const APIKey: string): TStringList;
  end;

implementation

uses
  Unit1;

class function TChatGPTCompletion.GetChatCompletion(
  const APIKey: string;
  Messages: TJSONArray;
  const Model: string;
  const ATemperature: Double;
  const AMaxTokens: Integer
): string;
var
  HttpClient: TFPHttpClient;
  ResponseData: TStringStream;
  RequestJSON: TJSONObject;
  ResponseJSON: TJSONData;
  Parser: TJSONParser;
  ChoicesArray: TJSONArray;
  ErrorObj: TJSONObject;
begin
  Result := '';

  HttpClient := TFPHttpClient.Create(nil);
  ResponseData := TStringStream.Create('');
  RequestJSON := TJSONObject.Create;
  try
    // Build the request JSON
    RequestJSON.Add('model', Model);
    // Clone the TJSONArray in case you want to reuse or modify it externally
    RequestJSON.Add('messages', Messages.Clone as TJSONArray);

    RequestJSON.Add('temperature', ATemperature);
    RequestJSON.Add('max_tokens', AMaxTokens);

    // Setup headers
    HttpClient.AddHeader('Content-Type', 'application/json');
    HttpClient.AddHeader('Authorization', 'Bearer ' + APIKey);
    HttpClient.AllowRedirect := True;
    HttpClient.IOTimeout := 100000;
    HttpClient.ConnectTimeout := 100000;
    HttpClient.IOTimeout := 100000;


    try
      // Perform POST
      HttpClient.RequestBody := TStringStream.Create(RequestJSON.AsJSON);
      HttpClient.Post('http://localhost:8089/v1/chat/completions', ResponseData);
    except
      on E: Exception do
      begin
        ShowMessage('Error sending request: ' + E.Message);
        Exit; // Exit early if HTTP POST failed.
      end;
    end;


    if HttpClient.ResponseStatusCode <> 200 then
    begin
      ShowMessage('Request failed. Status code: ' + IntToStr(HttpClient.ResponseStatusCode)
                  + ' - ' + HttpClient.ResponseStatusText);
      Exit;
    end;


    // Parse JSON response
    ResponseData.Position := 0;
    Parser := TJSONParser.Create(ResponseData.DataString);
    try
      try
        ResponseJSON := Parser.Parse;
      except
        on E: Exception do
        begin
          ShowMessage('Error parsing JSON: ' + E.Message);
          Exit;
        end;
      end;

      // Check if there's an "error" object
      if (ResponseJSON.JSONType = jtObject) then
      begin
        ErrorObj := TJSONObject(ResponseJSON).FindPath('error') as TJSONObject;
        if Assigned(ErrorObj) then
        begin
          // OpenAI errors are often returned under "error.message"
          ShowMessage('OpenAI error: ' + ErrorObj.Get('message', 'Unknown error.'));
          Exit;
        end;

        // Otherwise, try to parse the successful response
        ChoicesArray := TJSONObject(ResponseJSON).FindPath('choices') as TJSONArray;
        if Assigned(ChoicesArray) and (ChoicesArray.Count > 0) then
        begin
          // Extract assistant's content
          Result := TJSONObject(ChoicesArray.Items[0])
                      .FindPath('message.content')
                      .AsString;
        end
        else
        begin
          ShowMessage('No valid "choices" found in the response.');
        end;
      end
      else
      begin
        ShowMessage('Unexpected JSON structure. Expected a JSON object at the root.');
      end;

    finally
      Parser.Free;
      if Assigned(ResponseJSON) then
        ResponseJSON.Free;
    end;

  finally
    // Free resources
    RequestJSON.Free;
    HttpClient.RequestBody.Free; // Always free RequestBody if allocated
    HttpClient.Free;
    ResponseData.Free;
  end;
end;

class function TChatGPTCompletion.GetModelsList(const APIKey: string): TStringList;
var
  HttpClient: TFPHttpClient;
  ResponseData: TStringStream;
  Parser: TJSONParser;
  ResponseJSON: TJSONData;
  DataArray: TJSONArray;
  i: Integer;
  ModelID: string;
begin
  // The caller must free this TStringList
  Result := TStringList.Create;
  HttpClient := TFPHttpClient.Create(nil);
  ResponseData := TStringStream.Create('');
  try
    HttpClient.AddHeader('Authorization','Bearer ' + APIKey);
    HttpClient.AddHeader('Content-Type','application/json');
    HttpClient.AllowRedirect := True;
    HttpClient.IOTimeout := 30000;
    HttpClient.ConnectTimeout := 30000;

    // GET request to /v1/models
    HttpClient.Get('http://localhost:8089/v1/models', ResponseData);

    // Parse JSON
    ResponseData.Position := 0;
    Parser := TJSONParser.Create(ResponseData.DataString);
    try
      ResponseJSON := Parser.Parse;
      if (ResponseJSON.JSONType = jtObject) then
      begin
        // The response typically has "data" -> [ { "id": "model-name", ...}, ... ]
        DataArray := TJSONObject(ResponseJSON).FindPath('data') as TJSONArray;
        if Assigned(DataArray) then
        begin
          for i := 0 to DataArray.Count - 1 do
          begin
            ModelID := TJSONObject(DataArray.Items[i]).Get('id', '');
            if ModelID <> '' then
              Result.Add(ModelID);
          end;
        end;
      end;
    finally
      Parser.Free;
      ResponseJSON.Free;
    end;
  finally
    HttpClient.Free;
    ResponseData.Free;
  end;
end;

end.

