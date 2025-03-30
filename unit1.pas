unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, TypInfo, Graphics, Dialogs, StdCtrls,
  FileCtrl, ComboEx, ShellCtrls, EditBtn, Menus, ComCtrls, SynEdit,
  SynHighlighterPHP, fpjson, jsonparser, uchatOllama, uChatGpt,
  RegExpr, Unit2, GamesUnit, Types;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    DefaultPromptsJson: TMemo;
    Memo1: TMemo;
    Memo2: TMemo;
    SaveCodeButton: TButton;
    CopyFromQAToCodeButton: TButton;
    Label10: TLabel;
    ShowGamesButton: TButton;
    SynPHPSyn1: TSynPHPSyn;
    UseCodeCheck: TCheckBox;
    UseQAndR: TCheckBox;
    ClearCodeButton: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    ClassNameEdit: TEdit;
    DeleteButton: TButton;
    GetModelsButton: TButton;
    Label2: TLabel;
    PromptLabel: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Memo3: TMemo;
    Memo4: TMemo;
    NewPromptButton: TButton;
    PageControl1: TPageControl;
    PromptCombo: TComboBox;
    QAndATab: TTabSheet;
    PromptTab: TTabSheet;
    ModelCombo: TComboBox;
    DirectoryEdit1: TDirectoryEdit;
    EditMaxTokens: TEdit;
    EditTemperature: TEdit;
    FileListBox1: TFileListBox;
    Label1: TLabel;  // Holds the API key
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    SaveDialog1: TSaveDialog;
    UpdatePromptButton: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure ClearCodeButtonClick(Sender: TObject);
    procedure CopyFromQAToCodeButtonClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure GetModelsButtonClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure DeleteButtonClick(Sender: TObject);
    procedure NewPromptButtonClick(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure DirectoryEdit1Change(Sender: TObject);
    procedure FileListBox1DblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
    procedure Memo4Change(Sender: TObject);
    procedure Memo4KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PromptComboChange(Sender: TObject);
    procedure PromptTabContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure SaveCodeButtonClick(Sender: TObject);
    procedure SaveJsonButtonClick(Sender: TObject);
    procedure ShowGamesButtonClick(Sender: TObject);
    procedure UpdatePromptButtonClick(Sender: TObject);
    procedure UpdatePromptButtonKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure UseCodeCheckChange(Sender: TObject);
    procedure UseQAndRChange(Sender: TObject);

  public
    procedure AddNewPrompt(NewSystemPromptName, NewSystemPrompt: String);
  private
    FConversation: TJSONArray;  // Holds the entire conversation
    FirstMessage: Integer;
    ConfigPath, ConfigDir: string;
    StartDirectory: string;
    //FJsonData: TJSONObject;
    FJsonData: TJSONArray;
    JsonNameList: TStrings;
    function PrettyPrintJSON(const RawJSON: string): string;
    procedure RemoveMarkdownSyntaxFromMemo;
    procedure UpdatePromptAtIndex(Index: Integer; NewSystemPrompt: String);

    procedure LoadJsonData;
    procedure SaveJsonData;
    procedure CreateDefaultJson;
    procedure DeletePrompt(Index: Integer);




  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }




procedure TForm1.FormCreate(Sender: TObject);
var
  SystemMsg: TJSONObject;
  JSONData: TJSONData;
  JSONObject: TJSONObject;
  PromptJSONData: TJSONData;
  PromptJSONItem: TJSONData;
  JSONFile: TStringList;
  ChatGPTKey, HomeDir: string;

  i: Integer;
  key, idxKey, value : string;
  object_name, field_name, field_value, object_type, object_items: String;
begin
    FirstMessage := 1;
    FileListBox1.Directory := DirectoryEdit1.Directory;
    // Create the conversation array
    FConversation := TJSONArray.Create;
    // Add a system message
    SystemMsg := TJSONObject.Create;
    SystemMsg.Add('role', 'system');
    SystemMsg.Add('content',Memo4.Text);

    FConversation.Add(SystemMsg);
    //    Cross-platform function that returns something like:
    //    - Linux/macOS: /home/username/
    //    - Windows: C:\Users\username\
    HomeDir := GetUserDir;
    ConfigDir  := IncludeTrailingPathDelimiter(HomeDir) + '.lazOpenAI';
    ConfigPath := IncludeTrailingPathDelimiter(ConfigDir) + 'settings.json';
    if not DirectoryExists(ConfigDir) then
      ForceDirectories(ConfigDir);
    if not FileExists(ConfigPath) then
    begin
      JSONObject := TJSONObject.Create;
      try
        JSONObject.Add('startDirectory', '');
        JSONObject.Add('chatGPTKey', '');
        JSONFile := TStringList.Create;
        try
          JSONFile.Text := JSONObject.FormatJSON();
          JSONFile.SaveToFile(ConfigPath);
        finally
          JSONFile.Free;
        end;
      finally
        JSONObject.Free;
      end;

      ShowMessage(
        'A new "settings.json" file has been created at:' + sLineBreak +
        ConfigPath + sLineBreak + sLineBreak +
        'Please open this file, fill in valid values, ' + sLineBreak +
        'Enter a Valid ChatGPT API Key and rerun the application.'
      );
      Application.Terminate;
      Exit;
    end;
    JSONFile := TStringList.Create;
    try
      JSONFile.LoadFromFile(ConfigPath);
      JSONData := GetJSON(JSONFile.Text);
      try
        JSONObject      := TJSONObject(JSONData);
        StartDirectory  := JSONObject.Get('startDirectory', '');
        ChatGPTKey      := JSONObject.Get('chatGPTKey', '');
      finally
        JSONData.Free;
      end;
    finally
      JSONFile.Free;
    end;
    Label1.Caption:= ChatGPTKey;
    DirectoryEdit1.Text := StartDirectory;
    GetModelsButton.Click;

   LoadJsonData;


   JsonNameList := TStringList.Create;

   object_type := GetEnumName(TypeInfo(TJSONtype), Ord(FJsonData.JSONType));
   if object_type <> 'jtArray' then
   begin
     PromptJSONData := FJsonData.Items[0];
     PromptJSONItem := TJSONObject(FJsonData).Items[0];
     idxKey := PromptJSONItem.Value;
     PromptJSONItem := TJSONObject(FJsonData).Items[1];
     value := PromptJSONItem.Value;
     JsonNameList.Add(value);
   end
   else
   begin
     for i := 0 to FJsonData.Count - 1 do
     begin
       PromptJSONData := FJsonData.Items[i];
       key := TJSONObject(PromptJSONData).Names[0];
       PromptJSONItem := TJSONObject(PromptJSONData).Items[0];
       idxKey := PromptJSONItem.Value;
       key := TJSONObject(PromptJSONData).Names[1];
       PromptJSONItem := TJSONObject(PromptJSONData).Items[1];
       value := PromptJSONItem.Value;
       PromptCombo.Items.Add(idxKey);
       JsonNameList.Add(value);
     end;
   end;

     // Set the default ComboBox selection (first item)
     if PromptCombo.Items.Count > 0 then
       PromptCombo.ItemIndex := 0;

     // Display the corresponding value in Memo1
     Memo4.Text := JsonNameList.Strings[0];
   //finally
   //  JsonNameList.Free;
   //end;


end;




// 2) Free the conversation JSON when the form closes
procedure TForm1.FormDestroy(Sender: TObject);
begin
  FConversation.Free;
end;

procedure TForm1.Label1Click(Sender: TObject);
begin

end;

procedure TForm1.Memo1Change(Sender: TObject);
begin

end;

procedure TForm1.Memo4Change(Sender: TObject);
begin

end;

procedure TForm1.Memo4KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  UpdatePromptButton.visible := True;
end;

procedure TForm1.PromptComboChange(Sender: TObject);
var
  SystemMsg: TJSONObject;
begin
  Memo4.Text := JsonNameList[PromptCombo.ItemIndex];
  FConversation.Free;
  FConversation := TJSONArray.Create;
  SystemMsg := TJSONObject.Create;
  SystemMsg.Add('role', 'system');
  SystemMsg.Add('content', Memo4.Text);
  FConversation.Add(SystemMsg);
  FirstMessage := 1;
end;

procedure TForm1.PromptTabContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin

end;

procedure TForm1.SaveCodeButtonClick(Sender: TObject);
var
  FullPath: string;
begin
  // Combine the selected directory and the filename
  FullPath :=  FileListBox1.FileName;

  // Save the memo’s text to the resulting file
  Memo1.Lines.SaveToFile(FullPath);
end;



procedure TForm1.SaveJsonButtonClick(Sender: TObject);
begin
  SaveJsonData;
end;

procedure TForm1.ShowGamesButtonClick(Sender: TObject);
begin
  GamesForm.Show;
end;

procedure TForm1.UpdatePromptButtonClick(Sender: TObject);
begin
  UpdatePromptAtIndex(PromptCombo.ItemIndex,Memo4.Text);
  UpdatePromptButton.visible := false;
end;

procedure TForm1.UpdatePromptButtonKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin

end;

procedure TForm1.UseCodeCheckChange(Sender: TObject);
begin
  if UseCodeCheck.Checked then
     UseQAndR.Checked := False;
  if not UseCodeCheck.Checked then
     UseQAndR.Checked := True;
end;

procedure TForm1.UseQAndRChange(Sender: TObject);
begin
  if UseQAndR.Checked then
     UseCodeCheck.Checked := False;
  if not UseQAndR.Checked then
     UseCodeCheck.Checked := True;
end;

// 3) Send a new user prompt, get the assistant reply
procedure TForm1.Button1Click(Sender: TObject);
var
  APIKey: string;
  Temperature: Double;
  MaxTokens: Integer;
  UserMsg: TJSONObject;
  UserPrompt, RequestPayload, Response: string;
  RequestJSON: TJSONObject;
begin
  Memo3.Clear;
  APIKey := Label1.Caption;
  UserPrompt := Trim(Memo1.Text);
  if UserPrompt = '' then
  begin
    ShowMessage('Please enter a prompt in Memo1.');
    Exit;
  end;
  if FirstMessage <> 0 then
    begin
    if Memo1.Text = '' then
    begin
      ShowMessage('Please enter code in File to Sent LLM Memo.');
      Exit;
    end;
  end;

  Temperature := StrToFloatDef(EditTemperature.Text, 0.7);
  MaxTokens    := StrToIntDef(EditMaxTokens.Text, 512);

  // STEP 1) Add new user message to FConversation
  //UserMsg := TJSONObject.Create;
  //UserMsg.Add('role', 'user');
  //UserMsg.Add('content', UserPrompt);
  //FConversation.Add(UserMsg);
  // (You can cast if needed in older FPC: FConversation.Add(TJSONData(UserMsg));)
  if (FirstMessage = 0) and (not UseCodeCheck.Checked) then
  begin
    UserMsg := TJSONObject.Create;
    UserMsg.Add('role', 'user');
    UserMsg.Add('content', Memo2.Text);
    FConversation.Add(UserMsg);
  end
  else
  begin
    UserMsg := TJSONObject.Create;
    UserMsg.Add('role', 'user');
    UserMsg.Add('content', Memo1.Text);
    FConversation.Add(UserMsg);
    if FirstMessage = 1 then
    begin
      UseCodeCheck.Checked := False;
      UseQAndR.Checked := True;
    end;
  end;
  FirstMessage := 0;
  Memo2.Clear;

  // STEP 2) Build the exact JSON that TChatCompletion will send
  //         (same structure as inside TChatCompletion).
  RequestJSON := TJSONObject.Create;
  try
    // clone the conversation array so we don't mutate the original
    RequestJSON.Add('messages', FConversation.Clone as TJSONArray);
    RequestJSON.Add('temperature', Temperature);
    RequestJSON.Add('max_tokens', MaxTokens);
    RequestJSON.Add('stream', false);
    // Show the JSON in Memo3
    Memo3.Text := PrettyPrintJSON(RequestJSON.AsJSON);
  finally
    RequestJSON.Free;
  end;

  // STEP 3) Now call GetChatCompletion to actually POST the request
  Response := TChatGPTCompletion.GetChatCompletion(
                APIKey,
                FConversation,
                ModelCombo.Text,
                Temperature,
                MaxTokens
              );
  Memo2.Lines.Add(Response);
  RemoveMarkdownSyntaxFromMemo;

end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if SaveDialog1.Execute then
    Memo2.Lines.SaveToFile( SaveDialog1.Filename );

end;

procedure TForm1.ClearCodeButtonClick(Sender: TObject);
begin
  Memo1.Clear;
end;

procedure TForm1.CopyFromQAToCodeButtonClick(Sender: TObject);
begin
     Memo1.Text := Memo2.Text;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  ModelCombo.Text := 'gpt-4o-mini';
end;

procedure TForm1.RemoveMarkdownSyntaxFromMemo;
var
  RegExp: TRegExpr;
begin
  // Create regular expression object
  RegExp := TRegExpr.Create;
  try
    // Remove leading whitespace and newlines
    RegExp.Expression := '^[\s\r\n]+';
    Memo2.Lines.Text := RegExp.Replace(Memo2.Lines.Text, '', True);

    // After trimming, check if the text starts with a newline, and remove it
    if (Length(Memo1.Lines.Text) > 0) and (Memo1.Lines.Text[1] in [#10, #13]) then
      Memo1.Lines.Text := Copy(Memo1.Lines.Text, 2, Length(Memo1.Lines.Text) - 1);

       // Ensure there's no leading empty line (check after trimming)
    while (Length(Memo1.Lines.Text) > 0) and (Memo1.Lines.Text[1] in [#13, #10]) do
      Memo1.Lines.Text := Copy(Memo1.Lines.Text, 2, Length(Memo1.Lines.Text) - 1);

    // Remove markdown syntax
    Memo2.Lines.Text := StringReplace(Memo2.Lines.Text, '```php', '', [rfReplaceAll]);
    Memo2.Lines.Text := StringReplace(Memo2.Lines.Text, '```json', '', [rfReplaceAll]);
    Memo2.Lines.Text := StringReplace(Memo2.Lines.Text, '```', '', [rfReplaceAll]);
  finally
    RegExp.Free;
  end;
end;

// 4) Example: Show the list of models in Memo2
procedure TForm1.GetModelsButtonClick(Sender: TObject);
var
  ModelList: TStringList;
  i: Integer;
begin
  if Label1.Caption <> '' then
  begin
    ModelList := TChatGPTCompletion.GetModelsList(Label1.Caption);
    try
      for i := 0 to ModelList.Count - 1 do
      begin
        //Memo2.Lines.Add(ModelList[i]);
        ModelCombo.Items.Add(ModelList[i]);
      end;
    finally
      ModelList.Free;
    end;
    ModelCombo.Text := 'gpt-4o-mini';
  end
  else
  begin
    ShowMessage('You must have a valid chat gpt API Key in you settings.json');
    Application.Terminate;
  end;
  ModelCombo.Text := 'gpt-4o-mini';
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Memo2.Clear;
end;

procedure TForm1.DeleteButtonClick(Sender: TObject);
begin
  DeletePrompt(PromptCombo.ItemIndex);
end;

procedure TForm1.NewPromptButtonClick(Sender: TObject);
begin
  NewPromptForm.show;
end;

procedure TForm1.Button5Click(Sender: TObject);
var
  SystemMsg: TJSONObject;
begin
  FConversation.Free;
  FConversation := TJSONArray.Create;
  SystemMsg := TJSONObject.Create;
  SystemMsg.Add('role', 'system');
  SystemMsg.Add('content', Memo4.Text);
  FConversation.Add(SystemMsg);
  FirstMessage := 1;
  UseCodeCheck.Checked := True;
  UseQAndR.Checked := False;
end;

procedure TForm1.Button6Click(Sender: TObject);
var
  SystemMsg: TJSONObject;
begin
  FConversation := TJSONArray.Create;
  SystemMsg := TJSONObject.Create;
  SystemMsg.Add('role', 'system');
  SystemMsg.Add('content', Memo4.text);
  FConversation.Add(SystemMsg);
end;

procedure TForm1.Button7Click(Sender: TObject);
var
  ClassPos, StartPos, i: Integer;
begin


  // Look for the substring 'class '
  ClassPos := Pos('class ', Memo2.Text);
  if ClassPos = 0 then
    Exit; // Not found

  // Move the starting position to the character after 'class '
  StartPos := ClassPos + Length('class ');

  // Skip any additional whitespace after 'class ' (just in case)
  while (StartPos <= Length(Memo2.Text))
    and (Memo2.Text[StartPos] in [#9, #10, #13, ' ']) do
    Inc(StartPos);

  // Now gather characters that make up the class name
  i := StartPos;
  while (i <= Length(Memo2.Text))
    and (Memo2.Text[i] in ['a'..'z', 'A'..'Z', '0'..'9', '_']) do
    Inc(i);

  // Extract the substring from StartPos to i-1
  ClassNameEdit.Text := Copy(Memo2.Text, StartPos, i - StartPos) + '.php';
  Memo2.Lines.SaveToFile('phpfiles/reports/'+ ClassNameEdit.Text);
end;

procedure TForm1.DirectoryEdit1Change(Sender: TObject);
var
  HomeDir: string;
  JSONFile: TStringList;
  JSONData: TJSONData;
  JSONObject: TJSONObject;
begin
    FileListBox1.Directory := DirectoryEdit1.Directory;
  // 1. Build the path to the settings file in ~/.lazOpenAI/
  HomeDir   := GetUserDir;
  ConfigDir := IncludeTrailingPathDelimiter(HomeDir) + '.lazOpenAI';
  ConfigPath := IncludeTrailingPathDelimiter(ConfigDir) + 'settings.json';

  // 2. Safeguard: Ensure the file exists (optionally handle if it doesn't)
  if not FileExists(ConfigPath) then
  begin
    ShowMessage('Cannot update settings.json because it does not exist!' + sLineBreak +
                'Expected location: ' + ConfigPath);
    Exit;
  end;

  // 3. Load the existing JSON into memory
  JSONFile := TStringList.Create;
  try
    JSONFile.LoadFromFile(ConfigPath);
    JSONData := GetJSON(JSONFile.Text);
    try
      JSONObject := TJSONObject(JSONData);

      // 4. Update the "startDirectory" field with DirectoryEdit1’s current value
      JSONObject.Strings['startDirectory'] := DirectoryEdit1.Text;

      // 5. (Optional) You can also preserve the other fields (e.g. chatGPTKey)
      //    by not touching them. We’re only changing "startDirectory" here.

      // 6. Write the modified JSON back to disk
      JSONFile.Text := JSONObject.FormatJSON();
      JSONFile.SaveToFile(ConfigPath);

    finally
      JSONData.Free;
    end;
  finally
    JSONFile.Free;
  end;
end;



procedure TForm1.FileListBox1DblClick(Sender: TObject);
begin
  Memo1.Lines.LoadFromFile(FileListBox1.FileName);
end;

procedure TForm1.LoadJsonData;
var
  JsonFile: TStringList;
begin
  JsonFile := TStringList.Create;
  try
    // Check if the JSON file exists, if not, create the default
    if not FileExists(ConfigDir + '/systemprompts.json') then
    begin
      CreateDefaultJson; // Create a default JSON if it doesn't exist
    end;

    // Read the JSON file into a string list
    JsonFile.LoadFromFile(ConfigDir + '/systemprompts.json');
    // Parse the JSON string into a TJSONObject
    FJsonData := TJSONArray(GetJSON(JsonFile.Text));
  finally
    JsonFile.Free;
  end;
end;

procedure TForm1.SaveJsonData;
var
  JsonFile: TStringList;
begin
  JsonFile := TStringList.Create;
  try
    // Convert the JSON object back to a string
    JsonFile.Text := FJsonData.AsJSON;
    // Save it to the file
    JsonFile.SaveToFile(ConfigDir + '/systemprompts.json');
  finally
    JsonFile.Free;
  end;
end;

procedure TForm1.CreateDefaultJson;
var
  JsonFile: TStringList;
  DefaultJson: TJSONObject;
begin
  DefaultPromptsJson.Lines.SaveToFile(ConfigDir + '/systemprompts.json');
end;

function TForm1.PrettyPrintJSON(const RawJSON: string): string;
var
  Parser: TJSONParser;
  Data: TJSONData;
begin
  Result := '';
  if Trim(RawJSON) = '' then
    Exit;  // Nothing to format

  // Create a JSON parser
  Parser := TJSONParser.Create(RawJSON);
  try
    // Parse the input JSON string into a TJSONData hierarchy
    Data := Parser.Parse;
    try
      // You can adjust formatting options if desired, e.g. [foSingleLineArray]
      Result := Data.FormatJSON([], 2);
    finally
      Data.Free;
    end;
  finally
    Parser.Free;
  end;
end;

procedure TForm1.AddNewPrompt(NewSystemPromptName, NewSystemPrompt: String);
var
  NewPrompt: TJSONObject;
begin
  try
    // Create a new TJSONObject for the new prompt
    NewPrompt := TJSONObject.Create;

    // Add the systemPromptName and systemPrompt as key-value pairs
    NewPrompt.Add('systemPromptName', NewSystemPromptName);
    NewPrompt.Add('systemPrompt', NewSystemPrompt);

    // Append the new prompt to the TJSONArray (FJsonData)
    FJsonData.Add(NewPrompt); // This works because NewPrompt is a TJSONData object

    // Keep the ComboBox in sync
    PromptCombo.Items.Add(NewSystemPromptName);

    // Keep JsonNameList in sync
    JsonNameList.Add(NewSystemPrompt);

    // Save the updated JSON data
    SaveJsonData;

  except
    on E: Exception do
      ShowMessage('Error adding new prompt: ' + E.Message);
  end;
end;


procedure TForm1.DeletePrompt(Index: Integer);
begin
  try
    if (Index < 0) or (Index >= FJsonData.Count) then
    begin
      ShowMessage('Index out of bounds for JSON array');
      Exit;
    end;
    FJsonData.Delete(Index);
    SaveJsonData;
    if (Index < 0) or (Index >= PromptCombo.Items.Count) then
    begin
      ShowMessage('Index out of bounds for ComboBox items');
      Exit;
    end;
    PromptCombo.Items.Delete(Index);
    PromptCombo.ItemIndex := 0;
    if (Index < 0) or (Index >= JsonNameList.Count) then
    begin
      ShowMessage('Index out of bounds for JsonNameList');
      Exit;
    end;
    JsonNameList.Delete(Index);

  except
    on E: Exception do
      ShowMessage('Error deleting prompt: ' + E.Message);
  end;
end;

procedure TForm1.UpdatePromptAtIndex(Index: Integer; NewSystemPrompt: String);
var
  PromptObject: TJSONObject;
begin
  try
    if (Index < 0) or (Index >= FJsonData.Count) then
    begin
      ShowMessage('Index out of bounds for JSON array.');
      Exit;
    end;
    PromptObject := FJsonData.Items[Index] as TJSONObject;

    if Assigned(PromptObject) then
    begin
      PromptObject.Strings['systemPrompt'] := NewSystemPrompt;
      SaveJsonData;
    end
    else
    begin
      ShowMessage('Unable to cast item to TJSONObject.');
      Exit;
    end;
    if (Index < 0) or (Index >= JsonNameList.Count) then
    begin
      ShowMessage('Index out of bounds for JsonNameList.');
      Exit;
    end;
    JsonNameList[Index] := NewSystemPrompt;
  except
    on E: Exception do
      ShowMessage('Error updating prompt: ' + E.Message);
  end;
end;












end.

