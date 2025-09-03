unit FileDetails;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ShellAPI, ImgList;

type
  TFileDetailsForm = class(TForm)
    CancelBtn: TButton;
    RecoverBtn: TButton;
    IconImg: TImage;
    FileNameLbl: TLabel;
    CreationTimeLbl: TLabel;
    ChangeTimeLbl: TLabel;
    SizeLbl: TLabel;
    RecordLocationLbl: TLabel;
    SysIco: TImageList;
    FileTypeLbl: TLabel;
    procedure FormCreate(Sender: TObject);
    function GetIconIndex(Extension: String; Attributes: DWORD; var FileType :string):Integer;
  private
    { Déclarations privates }
  public
    { Déclarations public }
  end;

var
  FileDetailsForm: TFileDetailsForm;

implementation

{$R *.dfm}

function TFileDetailsForm.GetIconIndex(Extension: String; Attributes: DWORD; var FileType :string):Integer;
var SHFileInfo: TSHFileInfo;
  begin
   if Extension[1] <> '.' then Extension := '.' + Extension;
   SHGetFileInfo(PChar(Extension), Attributes, SHFileInfo, SizeOf(TSHFileInfo),
                 SHGFI_SYSICONINDEX or SHGFI_USEFILEATTRIBUTES or SHGFI_TYPENAME);
   FileType := SHFileInfo.szTypeName; // FileType
   Result := SHFileInfo.iIcon; // IconIndex
  end;


procedure TFileDetailsForm.FormCreate(Sender: TObject);
var
  SHFileInfo :TSHFileINfo;
begin
    SysIco.Handle := SHGetFileInfo('', 0, SHFileInfo, SizeOF(SHFileInfo), SHGFI_SYSICONINDEX or SHGFI_LARGEICON);
end;


end.
