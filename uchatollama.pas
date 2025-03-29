unit uchatOllama;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, fpjson, jsonparser, opensslsockets;

type

  { TChatCompletion }
  TChatOllamaCompletion = class
  public
    {
      Calls a local Ollama server at http://localhost:11411/generate
      using an array of messages for context. Returns the assistant's
      reply as a concatenated string of tokens.
    }
    class function GetChatCompletion(
      const APIKey: string;   // Not used for Ollama, but left here to keep the signature
      Messages: TJSONArray;
      const Model: string = 'llama2-7b';  // Or any model Ollama has
      const ATemperature: Double = 0.7;
      const AMaxTokens: Integer = 512
    ): string;

    {
      Example: If Ollama has a /models endpoint that returns a list of models,
      you can adapt the code below. Some versions of Ollama do:
        GET http://localhost:11411/models
      returning an array of model names.
    }
    class function GetModelsList(const APIKey: string): TStringList;
  end;

implementation
uses
  Unit1;

class function TChatOllamaCompletion.GetChatCompletion(
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
  i: Integer;
  MsgObj: TJSONObject;
  CombinedPrompt: string;
  Line: string;
  FullResponse: String;
  Lines: TStringArray;
begin
  Result := '';

  // 1) Combine all messages into a single prompt string
  //    e.g. "System: ... User: ... Assistant: ..."
  //    Adjust formatting as you prefer
  CombinedPrompt := '';
  for i := 0 to Messages.Count - 1 do
  begin
    MsgObj := TJSONObject(Messages.Items[i]);
    CombinedPrompt += MsgObj.Strings['role'] + ': ' + MsgObj.Strings['content'] + #10;
  end;

  // 2) Prepare the Ollama /generate request JSON
  RequestJSON := TJSONObject.Create;
  try
    RequestJSON.Add('model', Model);
    RequestJSON.Add('prompt', CombinedPrompt);

    // Optional: If you want to pass temperature or max_tokens to Ollama,
    // add them if the version supports it. For example:
    // RequestJSON.Add('temperature', ATemperature);
    // RequestJSON.Add('num_ctx', AMaxTokens);

    HttpClient := TFPHttpClient.Create(nil);
    ResponseData := TStringStream.Create('');
    try
      // Ollama does not require an Authorization header by default
      HttpClient.AddHeader('Content-Type','application/json');
      HttpClient.AllowRedirect := True;
      HttpClient.IOTimeout := 30000;
      HttpClient.ConnectTimeout := 30000;

      // POST to your locally running Ollama instance
      HttpClient.RequestBody := TStringStream.Create(RequestJSON.AsJSON);
      HttpClient.Post('http://localhost:11434/api/chat', ResponseData);
      ResponseData.Position := 0;
      FullResponse := ResponseData.DataString;
      Form1.Memo3.Text := FullResponse;
      // Split by line endings.
      Lines := FullResponse.Split(LineEnding);

      for i := 0 to High(Lines) do
      begin
        Line := Lines[i];

        if Line.StartsWith('data: ') then
        begin
          // Remove the "data: " prefix
          Line := Copy(Line, 7, MaxInt);
          // Remove quotes if present
          Line := StringReplace(Line, '"', '', [rfReplaceAll]);
          // Accumulate
          Result += Line;
        end;
      end;
    finally
      HttpClient.RequestBody.Free;
      HttpClient.Free;
      ResponseData.Free;
    end;
  finally
    RequestJSON.Free;
  end;
end;

class function TChatOllamaCompletion.GetModelsList(const APIKey: string): TStringList;
var
  HttpClient: TFPHttpClient;
  ResponseData: TStringStream;
  Parser: TJSONParser;
  ResponseJSON: TJSONData;
  i: Integer;
  ModelName: string;
begin
  // Adapted for Ollama. If Ollama supports an endpoint /models that returns JSON:
  //   ["llama2-7b", "your-model", ...]
  // We'll parse it below. Otherwise, adjust as needed.
  Result := TStringList.Create;
  HttpClient := TFPHttpClient.Create(nil);
  ResponseData := TStringStream.Create('');
  try
    HttpClient.AddHeader('Content-Type', 'application/json');
    HttpClient.AllowRedirect := True;
    HttpClient.IOTimeout := 30000;
    HttpClient.ConnectTimeout := 30000;

    // For example: GET http://localhost:11411/models
    HttpClient.Get('http://localhost:11411/models', ResponseData);

    // Parse JSON array
    ResponseData.Position := 0;
    Parser := TJSONParser.Create(ResponseData.DataString);
    try
      ResponseJSON := Parser.Parse;
      if ResponseJSON.JSONType = jtArray then
      begin
        // "ResponseJSON" is an array of model names
        for i := 0 to TJSONArray(ResponseJSON).Count - 1 do
        begin
          ModelName := TJSONArray(ResponseJSON).Items[i].AsString;
          Result.Add(ModelName);
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

