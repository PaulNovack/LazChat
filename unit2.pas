unit Unit2;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TNewPromptForm }

  TNewPromptForm = class(TForm)
    SaveButton: TButton;
    CancelButton: TButton;
    PromptNameEdit: TEdit;
    PromptLabel: TLabel;
    PromptMemo: TMemo;
    PromptLabel1: TLabel;
    procedure SaveButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  NewPromptForm: TNewPromptForm;



implementation

{$R *.lfm}
uses Unit1;

{ TNewPromptForm }

procedure TNewPromptForm.FormCreate(Sender: TObject);
begin

end;

procedure TNewPromptForm.SaveButtonClick(Sender: TObject);
begin
  Form1.AddNewPrompt(PromptNameEdit.Text,PromptMemo.Text);
  NewPromptForm.Hide;
end;

procedure TNewPromptForm.CancelButtonClick(Sender: TObject);
begin
  NewPromptForm.Hide;
end;

end.

