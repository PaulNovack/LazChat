unit PresentationUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TPresentationForm }

  TPresentationForm = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  PresentationForm: TPresentationForm;

implementation

{$R *.lfm}

{ TPresentationForm }

procedure TPresentationForm.Button1Click(Sender: TObject);
begin
  Memo1.Text := '';
end;

procedure TPresentationForm.FormCreate(Sender: TObject);
begin

end;

end.

