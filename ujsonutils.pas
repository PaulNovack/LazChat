unit
UJsonUtils;

uses
  Classes, SysUtils, fpjson, jsonparser;

function PrettyPrintJSON(const RawJSON: string): string;
var
  Parser: TJSONParser;
  Data: TJSONData;
begin
  Result := '';
  if Trim(RawJSON) = '' then
    Exit;  // Nothing to format

  // Create a JSON parser
  Parser := TJSONParser.Create(RawJSON, [joUTF8, joStrict]);
  try
    // Parse the input JSON string into a TJSONData hierarchy
    Data := Parser.Parse;
    try
      // Format the JSON with indentation
      // The second parameter (2) is the indentation size
      // You can adjust formatting options if desired, e.g. [foSingleLineArray]
      Result := Data.FormatJSON([], 2);
    finally
      Data.Free;
    end;
  finally
    Parser.Free;
  end;
end;

