
unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, FileDetails, XPMan, ComCtrls, Grids, ValEdit,
  ExtCtrls, Buttons;

type
  TDynamicCharArray = array of Char;

type
  TBOOT_SEQUENCE = packed record
    _jmpcode : array[1..3] of Byte;
   	cOEMID: array[1..8] of Char;
 	  wBytesPerSector: Word;
 	  bSectorsPerCluster: Byte;
    wSectorsReservedAtBegin: Word;
 	  Mbz1: Byte;
 	  Mbz2: Word;
 	  Reserved1: Word;
 	  bMediaDescriptor: Byte;
 	  Mbz3: Word;
 	  wSectorsPerTrack: Word;
 	  wSides: Word;
 	  dwSpecialHiddenSectors: DWord;
 	  Reserved2: DWord;
 	  Reserved3: DWord;
 	  TotalSectors: Int64;
 	  MftStartLcn: Int64;
 	  Mft2StartLcn: Int64;
 	  ClustersPerFileRecord: DWord;
 	  ClustersPerIndexBlock: DWord;
 	  VolumeSerialNumber: Int64;
 	  _loadercode: array[1..430] of Byte;
 	  wSignature: Word;
  end;

type
  TNTFS_RECORD_HEADER = packed record
    Identifier: array[1..4] of Char;
    UsaOffset : Word;
    UsaCount : Word;
    LSN : Int64;
  end;

type
  TFILE_RECORD = packed record
    Header: TNTFS_RECORD_HEADER;
	  SequenceNumber : Word;
	  ReferenceCount : Word;
	  AttributesOffset : Word;
	  Flags : Word; // $0000 = Deleted, $0001 = InUse, $0002 = Directory
	  BytesInUse : DWord;
	  BytesAllocated : DWord;
	  BaseFileRecord : Int64;
	  NextAttributeID : Word;
   // Pading : Word;
   // MFTRecordNumber : DWord;
  end;

type
  TRECORD_ATTRIBUTE = packed record
    AttributeType : DWord;
    Length : DWord;
    NonResident : Byte;
    NameLength : Byte;
    NameOffset : Word;
    Flags : Word;
    AttributeNumber : Word;
  end;

type
  TRESIDENT_ATTRIBUTE = packed record
    Attribute : TRECORD_ATTRIBUTE;
    ValueLength : DWord;
    ValueOffset : Word;
    Flags : Word;
  end;

type
  TNONRESIDENT_ATTRIBUTE = packed record
    Attribute: TRECORD_ATTRIBUTE;
    LowVCN: Int64;
    HighVCN: Int64;
    RunArrayOffset : Word;
    CompressionUnit : Byte;
    Padding : array[1..5] of Byte;
    AllocatedSize: Int64;
    DataSize: Int64;
    InitializedSize: Int64;
    CompressedSize: Int64;
  end;

type
  TFILENAME_ATTRIBUTE = packed record
	  Attribute: TRESIDENT_ATTRIBUTE;
    DirectoryFileReferenceNumber: Int64;
    CreationTime: Int64;
    ChangeTime: Int64;
    LastWriteTime: Int64;
    LastAccessTime: Int64;
    AllocatedSize: Int64;
    DataSize: Int64;
    FileAttributes: DWord;
    AlignmentOrReserved: DWord;
    NameLength: Byte;
    NameType: Byte;
	  Name: Word;
  end;

type
  TSTANDARD_INFORMATION = packed record
	  Attribute: TRESIDENT_ATTRIBUTE;
	  CreationTime: Int64;
	  ChangeTime: Int64;
	  LastWriteTime: Int64;
	  LastAccessTime: Int64;
	  FileAttributes: DWord;
	  Alignment: array[1..3] of DWord;
	  QuotaID: DWord;
	  SecurityID: DWord;
	  QuotaCharge: Int64;
	  USN: Int64;
  end;

type
  TForm1 = class(TForm)
    ComboBox1: TComboBox;
    Label9: TLabel;
    RichEdit1: TRichEdit;
    StringGrid1: TStringGrid;
    SaveDialog: TSaveDialog;
    Label4: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label1: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Edit1: TEdit;
    BitBtn2: TBitBtn;
    BitBtn1: TBitBtn;
    Label8: TLabel;
    Edit2: TEdit;
    ScannedFiles_DollarSign: TLabel;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    RadioGroup1: TRadioGroup;
    procedure FormCreate(Sender: TObject);
    procedure ChangeUIEnableStatus(EnableControls: boolean; MaskList: boolean=false);
    procedure ComboBox1Change(Sender: TObject);
    procedure Log(Item: string; ItemColor: TColor=clBlack);
    procedure LogChange(Sender: TObject);
    procedure SortStringGrid(var GenStrGrid: TStringGrid; ThatCol: Integer);
    procedure RadioGroup1Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    function FindAttributeByType(RecordData: TDynamicCharArray; AttributeType: DWord;
                                 FindSpecificFileNameSpaceValue: boolean=false) : TDynamicCharArray;
    procedure FixupUpdateSequence(var RecordData: TDynamicCharArray);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
  private
  public
  end;

const

  atAttributeStandardInformation = $10;
  atAttributeFileName = $30;
  atAttributeData = $80; {
      ATTRIBUTE_TYPE Possible Values ( SizeOf DWord ) :
      AttributeStandardInformation = $10,    AttributeAttributeList = $20,
      AttributeFileName = $30,               AttributeObjectId = $40,
      AttributeSecurityDescriptor = $50,     AttributeVolumeName	= $60,
      AttributeVolumeInformation = $70,      AttributeData = $80,
      AttributeIndexRoot = $90,              AttributeIndexAllocation = $A0,
      AttributeBitmap = $B0,                 AttributeReparsePoint	= $C0,
      AttributeEAInformation = $D0,          AttributeEA = $E0,
      AttributePropertySet = $F0,            AttributeLoggedUtilityStream = $100   }

var
  Form1: TForm1;

  BytesPerFileRecord: Word;                       //    \
  BytesPerCluster: Word;                          //     |__    Conversion
  BytesPerSector: Word;                           //     |      Ratios
  SectorsPerCluster: Word;                        //    /

  CURRENT_DRIVE: string;                          //    Saves the Drive which is currently used

  MASTER_FILE_TABLE_LOCATION : Int64;             //    \
  MASTER_FILE_TABLE_END : Int64;                  //     |__    MFT Location & Contents
  MASTER_FILE_TABLE_SIZE : Int64;                 //     |      Information
  MASTER_FILE_TABLE_RECORD_COUNT : integer;       //    /

  DEBUG_FOLDER_LOCATION : string;                 //    Debug Path where the log file and other
                                                  //    Status files are saved

  SEARCHING_FLAG : boolean;                       //    Prevents from several FileName researches
                                                  //    to be made at the same time in the Grid

implementation


{$R *.dfm}
procedure TForm1.FormCreate(Sender: TObject);
var
  i: integer;
  Bits: set of 0..25;
  ValidDrives: TStrings;
  tmpStr: string;

begin
  DEBUG_FOLDER_LOCATION := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName))+'Debug\';
  ForceDirectories(DEBUG_FOLDER_LOCATION);

  ValidDrives := TStringList.Create;
  try
    integer(Bits) := GetLogicalDrives;
    for i := 0 to 25 do begin
      tmpStr := Char(i+Ord('A'))+':';
      if (i in Bits) and (GetDriveType(Pchar(tmpStr+'\'))=DRIVE_FIXED) then ValidDrives.Append(tmpStr);
    end;
    ComboBox1.Items.Assign(ValidDrives);
    if ComboBox1.Items.Count<>0 then ComboBox1.ItemIndex := 0;
    Log('Drives List Updated', clGreen);
  finally
    FreeAndNil(ValidDrives);
  end;

  with StringGrid1 do begin
    RowCount := 1;
    Rows[0].Text := ('Record Location:'+#13#10+'File Name:'+#13#10+
                     'Size(Bytes):'+#13#10+'Creation Date:'+#13#10+'Change Date:');
  end;

  SEARCHING_FLAG := false;
end;

function NormalizeString(S: string): string;
const
  Source =  'àäâãçéèêëìïîôöòûüùÿÁÀÄÂÃÉÈÊËÍÎÌÔÖÒÓÕÜÛÙÚÝ';
  Destination = 'AAAAAEEEEIIIOOOOOUUUUYAAAAAEEEEIIIOOOOOUUUUY ';
var
  i, position: integer;
begin
  S := Trim(S);
  for i:=1 to Length(S) do begin
    position := Pos(S[i],Source);
    if position > 0 then S[i] := Destination[position];
    if not (S[i] in ['a'..'z','A'..'Z','0'..'9','_','-']) then S[i] := ' ';
  end;
  result := UpperCase(S);
end;

function GetVolumeLabel(Drive: Char): string;
var
   unused, flags: DWord;
   buffer: array [0..MAX_PATH] of Char;
begin
  buffer[0] := #$00;
  if GetVolumeInformation(PChar(Drive + ':\'), buffer, DWord(sizeof(buffer)),nil,unused,flags,nil,0) then
     SetString(result, buffer, StrLen(buffer))
  else result := '';
end;

function Int64TimeToDateTime(aFileTime: Int64): TDateTime;
var
  UTCTime, LocalTime: TSystemTime;
begin
  FileTimeToSystemTime( TFileTime(aFileTime), UTCTime);
  SystemTimeToTzSpecificLocalTime(nil, UTCTime, LocalTime);
  result := SystemTimeToDateTime(LocalTime);
end;

procedure TForm1.ChangeUIEnableStatus(EnableControls, MaskList: boolean);
begin
  BitBtn1.Enabled := EnableControls;
  ComboBox1.Enabled := EnableControls;
  BitBtn4.Enabled := EnableControls;
  RadioGroup1.Enabled := EnableControls;
  Edit1.Enabled := EnableControls;
  BitBtn2.Enabled := EnableControls;
  Edit2.Enabled := EnableControls;
  BitBtn3.Enabled := EnableControls;
  StringGrid1.Enabled := EnableControls;
  StringGrid1.Visible := (not MaskList);
  if EnableControls then Label9.Caption := '';
  SEARCHING_FLAG := not EnableControls;
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
var
  VolumeLabel: string;
begin
  VolumeLabel := ComboBox1.Text;
  VolumeLabel := GetVolumeLabel(VolumeLabel[1]);
  if VolumeLabel <> '' then Label1.Caption := 'Name : '+VolumeLabel
  else Label1.Caption := 'Name : Unknown';
  Label2.Caption := 'Serial : Unknown';
  Label3.Caption := 'Size : Unknown';
  Label4.Caption := 'MFT Location : Unknown';
  Label5.Caption := 'MFT Size : Unknown';
  Label6.Caption := 'Number of Records : Unknown';
  StringGrid1.RowCount := 1;
end;

procedure TForm1.Log(Item: string; ItemColor:TColor=clBlack);
var
 i1, i2, i3 : integer;
 Date : string;
begin
 i1 := Length(RichEdit1.Lines.Text);
 Date := DateTimeToStr(now)+' | ';
 i2 := i1 + Length(Date);
 RichEdit1.Lines.Add(Date+Item);
 i3 := Length(RichEdit1.Lines.Text);
 RichEdit1.SelStart := i1;
 RichEdit1.SelLength := i2-i1;
 RichEdit1.SelAttributes.Color := clblack;
 RichEdit1.SelStart := i2;
 RichEdit1.SelLength := i3-i2;
 RichEdit1.SelAttributes.Color := ItemColor;
 RichEdit1.SelStart := i3;
 SendMessage(RichEdit1.Handle,WM_VScroll,SB_LINEDOWN,0);
end;

procedure TForm1.LogChange(Sender: TObject);
begin
  RichEdit1.Lines.SaveToFile(DEBUG_FOLDER_LOCATION+'LOG.RTF');
end;

procedure TForm1.SortStringGrid(var GenStrGrid: TStringGrid; ThatCol: Integer);
const
  SeparatorChar = '@';
var
  CountItem, i, j, k, PositionIndex: integer;
  TmpList: TStringList;
  TmpStr1, TmpStr2: string;
begin
  CountItem := GenStrGrid.RowCount;
  TmpList        := TStringList.Create;
  TmpList.Sorted := False;
  try
    begin
      for i := 1 to (CountItem - 1) do
        TmpList.Add(GenStrGrid.Rows[i].Strings[ThatCol] + SeparatorChar + GenStrGrid.Rows[i].Text);
      TmpList.Sort;

      for k := 1 to TmpList.Count do
      begin
        TmpStr1 := TmpList.Strings[(k - 1)];
        PositionIndex := Pos(SeparatorChar, TmpStr1);
        TmpStr2  := '';
        TmpStr2 := Copy(TmpStr1, (PositionIndex + 1), Length(TmpStr1));
        TmpList.Strings[(k - 1)] := '';
        TmpList.Strings[(k - 1)] := TmpStr2;
      end;

      for j := 1 to (CountItem - 1) do
        GenStrGrid.Rows[j].Text := TmpList.Strings[(j - 1)];
    end;
  finally
    TmpList.Free;
  end;
end;

procedure TForm1.RadioGroup1Click(Sender: TObject);
begin
  SortStringGrid(StringGrid1, RadioGroup1.ItemIndex);
end;

procedure TForm1.BitBtn2Click(Sender: TObject);
var
  i, StartingRow : integer;
  Found : boolean;
  Request : string;
begin
  if SEARCHING_FLAG then exit;
  ChangeUIEnableStatus(false);


  Request := NormalizeString(Edit1.Text);
  Log('Searching for any FileName attribute containing "'+Request+'"', clGray);
  Label9.Caption := 'Searching for any FileName attributes containing "'+Request+'"';
  Application.ProcessMessages;


  Found := false;
  StartingRow := StringGrid1.Row+1; // Starts the research from the current line
  if StartingRow = StringGrid1.RowCount-1 then StartingRow := 1;

  for i:=StartingRow to StringGrid1.RowCount-1 do begin
    if Pos( Request,
            NormalizeString(StringGrid1.Rows[i].Strings[1])) <> 0 then begin
      Found := true;
      StringGrid1.Row := i;
      break;
    end;
  end;

  if Found then begin
    Log('Next Occurrence found on line #'+IntToStr(i), clGray);
  end else begin
    Log('The research did not return any matches.', clGray);
    if StartingRow>2 then
      MessageBoxA(Handle,
                  Pchar('The research did not return any matches starting from line #'+
                        IntToStr(StartingRow)+#13#10+
                        'You can try to launch it again from the beginning of the list.'),
                  Pchar('Information'),
                  MB_ICONINFORMATION + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST)
    else
      MessageBoxA(Handle,
                  Pchar('The research did not return any matches'),
                  Pchar('Information'),
                  MB_ICONINFORMATION + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);

  end;

  ChangeUIEnableStatus(true);
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
var
  i : integer;
  Found : boolean;
  Offset : string;
begin
  if SEARCHING_FLAG then exit;
  ChangeUIEnableStatus(false);
  Offset := '$'+NormalizeString(Edit2.Text);
  Log('Searching for the record corresponding to the Offset '+Offset, clGray);
  Label9.Caption := 'Searching for the record corresponding to the Offset '+Offset;
  Application.ProcessMessages;
  Found := false;
  for i:=1 to StringGrid1.RowCount-1 do begin
    if StringGrid1.Rows[i].Strings[0] = Offset then begin
      Found := true;
      StringGrid1.Row := i;
      break;
    end;
  end;
  if Found then begin
    Log('File Record Found', clGray);
  end else begin
    Log('The research did not return any matches.');
    MessageBoxA(Handle,
                Pchar('The research did not return any matches'),
                Pchar('Information'),
                MB_ICONINFORMATION + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
  end;

  ChangeUIEnableStatus(true);
end;

function TForm1.FindAttributeByType(RecordData: TDynamicCharArray; AttributeType: DWord;
                                      FindSpecificFileNameSpaceValue: boolean=false) : TDynamicCharArray;
var
  pFileRecord: ^TFILE_RECORD;
  pRecordAttribute: ^TRECORD_ATTRIBUTE;
  NextAttributeOffset: Word;
  TmpRecordData: TDynamicCharArray;
  TotalBytes: Word;
begin
  New(pFileRecord);
  ZeroMemory(pFileRecord, SizeOf(TFILE_RECORD));
  CopyMemory(pFileRecord, RecordData, SizeOf(TFILE_RECORD));
  if  pFileRecord.Header.Identifier[1] + pFileRecord.Header.Identifier[2]
     + pFileRecord.Header.Identifier[3] + pFileRecord.Header.Identifier[4]<>'FILE' then begin
    NextAttributeOffset := 0;
  end else begin
    NextAttributeOffset := pFileRecord^.AttributesOffset;
  end;

  TotalBytes := Length(RecordData);
  Dispose(pFileRecord);

  New(pRecordAttribute);
  ZeroMemory(pRecordAttribute, SizeOf(TRECORD_ATTRIBUTE));

  SetLength(TmpRecordData,TotalBytes-(NextAttributeOffset-1));
  TmpRecordData := Copy(RecordData,NextAttributeOffset,TotalBytes-(NextAttributeOffset-1));
  CopyMemory(pRecordAttribute, TmpRecordData, SizeOf(TRECORD_ATTRIBUTE));

  while (pRecordAttribute^.AttributeType <> $FFFFFFFF) and
        (pRecordAttribute^.AttributeType <> AttributeType) do begin
    NextAttributeOffset := NextAttributeOffset + pRecordAttribute^.Length;
    SetLength(TmpRecordData,TotalBytes-(NextAttributeOffset-1));
    TmpRecordData := Copy(RecordData,NextAttributeOffset,TotalBytes-(NextAttributeOffset-1));
    CopyMemory(pRecordAttribute, TmpRecordData, SizeOf(TRECORD_ATTRIBUTE));
  end;

  if pRecordAttribute^.AttributeType = AttributeType then begin

    if (FindSpecificFileNameSpaceValue) and (AttributeType=atAttributeFileName)  then begin
      if (TmpRecordData[$59]=Char($0)) {POSIX} or (TmpRecordData[$59]=Char($1)) {Win32}
         or (TmpRecordData[$59]=Char($3)) {Win32&DOS} then begin
        SetLength(result,pRecordAttribute^.Length);
        result := Copy(TmpRecordData,0,pRecordAttribute^.Length);
      end else begin
        NextAttributeOffset := NextAttributeOffset + pRecordAttribute^.Length;
        SetLength(TmpRecordData,TotalBytes-(NextAttributeOffset-1));
        TmpRecordData := Copy(RecordData,NextAttributeOffset,TotalBytes-(NextAttributeOffset-1));
        // Recursive Call : finds next matching attributes
        result := FindAttributeByType(TmpRecordData,AttributeType,true);
      end;

    end else begin
      SetLength(result,pRecordAttribute^.Length);
      result := Copy(TmpRecordData,0,pRecordAttribute^.Length);
    end;

  end else begin
    result := nil;
  end;
  Dispose(pRecordAttribute);
end;

procedure TForm1.FixupUpdateSequence(var RecordData: TDynamicCharArray);
var
  pFileRecord: ^TFILE_RECORD;
  UpdateSequenceOffset, UpdateSequenceCount: Word;
  UpdateSequenceNumber: array[1..2] of Char;
  i: integer;
begin
  New(pFileRecord);
  ZeroMemory(pFileRecord, SizeOf(TFILE_RECORD));
  CopyMemory(pFileRecord, RecordData, SizeOf(TFILE_RECORD));

  with pFileRecord^.Header do begin
    if Identifier[1]+Identifier[2]+Identifier[3]+Identifier[4] <> 'FILE' then begin
      Dispose(pFileRecord);
      raise Exception.Create('Unable to Fixup the Update Sequence: Invalid Record Data:'+
                             ' No FILE Identifier found');
    end;
  end;

  UpdateSequenceOffset := pFileRecord^.Header.UsaOffset;
  UpdateSequenceCount := pFileRecord^.Header.UsaCount;
  Dispose(pFileRecord);
  UpdateSequenceNumber[1] := RecordData[UpdateSequenceOffset];
  UpdateSequenceNumber[2] := RecordData[UpdateSequenceOffset+1];

  for i:=1 to UpdateSequenceCount-1 do begin
    if (RecordData[i*BytesPerSector-2] <> UpdateSequenceNumber[1])
       and (RecordData[i*BytesPerSector-1] <> UpdateSequenceNumber[2]) then begin
      Log('Warning: Invalid Record Data: Sector n°'+IntToStr(i)+' may be corrupt!', clMaroon);
      MessageBoxA(Handle,
                  Pchar('Warning : Invalid Record Data: Sector n°'+IntToStr(i)+' may be corrupt!'+
                        #13#10+'The process will NOT be interrupted.'),
                  Pchar('Warning'),
                  MB_ICONEXCLAMATION + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    end;
    RecordData[i*BytesPerSector-2] := RecordData[UpdateSequenceOffset+2*i];
    RecordData[i*BytesPerSector-1] := RecordData[UpdateSequenceOffset+1+2*i];
  end;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
var
  hDevice, hDest : THandle;
  BootData: array[1..512] of Char;
  MFTData: TDynamicCharArray;
  MFTAttributeData: TDynamicCharArray;
  StandardInformationAttributeData: TDynamicCharArray;
  FileNameAttributeData: TDynamicCharArray;
  DataAttributeHeader: TDynamicCharArray;
  dwread: LongWord;
  dwwritten: LongWord;
  pBootSequence: ^TBOOT_SEQUENCE;
  pFileRecord: ^TFILE_RECORD;
  pMFTNonResidentAttribute : ^TNONRESIDENT_ATTRIBUTE;
  pStandardInformationAttribute : ^TSTANDARD_INFORMATION;
  pFileNameAttribute : ^TFILENAME_ATTRIBUTE;
  pDataAttributeHeader: ^TRECORD_ATTRIBUTE;
  CurrentRecordCounter: integer;
  CurrentRecordLocator: Int64;
  FileName: WideString;
  FileCreationTime, FileChangeTime: TDateTime;
  FileParentDirectoryRecordNumber: Int64;
  FileSize: Int64;
  FileSizeArray : TDynamicCharArray;
  i: integer;
begin
  CURRENT_DRIVE := ComboBox1.Text;
  if CURRENT_DRIVE = '' then begin
    MessageBoxA(Handle,
                Pchar('No Drive Detected !'+#13#10+'Unable to continue.'),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    exit;
  end else begin
    Log('Gathering Information concerning the drive '+CURRENT_DRIVE+'\ ...');
    Label9.Caption := 'Gathering Information concerning the drive '+CURRENT_DRIVE+'\ ...';
  end;
  ChangeUIEnableStatus(false,true);
  hDevice := CreateFile( PChar('\\.\'+CURRENT_DRIVE), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE,
                         nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if (hDevice = INVALID_HANDLE_VALUE) then begin
    Log('Invalid Handle Value : Error '+IntToStr(GetLastError()), clred);
    MessageBoxA(Handle,
                Pchar('Invalid Handle Value '+#13#10+' Error '+IntToStr(GetLastError())),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    Closehandle(hDevice);
    ChangeUIEnableStatus(true);
    exit;
  end else begin
    Log('Drive '+CURRENT_DRIVE+'\ Successfully Opened', clgreen);
  end;


                      {// EXPORTS THE RESULT INTO A FILE : VISUALIZATION ==== DEBUG PURPOSE ONLY ====
                      SetFilePointer(hDevice, 0, nil, FILE_BEGIN);
                      Readfile(hDevice, BootData, 512, dwread, nil);
                      hDest:= CreateFile(PChar(DEBUG_FOLDER_LOCATION+'BootSequence.txt'), GENERIC_WRITE,
                                         0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
                      WriteFile(hDest,BootData,512, dwwritten, nil);
                      Closehandle(hDest);
                      Log('Boot Sequence File Written : BootSequence.txt ('+IntToStr(dwwritten)+' Bytes)'
                          ,clblue);
                      // ===========================================================================}

  New(PBootSequence);
  ZeroMemory(PBootSequence, SizeOf(TBOOT_SEQUENCE));
  SetFilePointer(hDevice, 0, nil, FILE_BEGIN);
  ReadFile(hDevice,PBootSequence^, 512,dwread,nil);
  Label1.Caption := 'Name : '+GetVolumeLabel(CURRENT_DRIVE[1]);
  Label2.Caption := 'Serial : '+IntToHex(PBootSequence.VolumeSerialNumber,8);

  Log('Boot Sequence Data Read : '+IntToStr(dwread)+' Bytes', clblue);
  with PBootSequence^ do begin
    if  (cOEMID[1]+cOEMID[2]+cOEMID[3]+cOEMID[4] <> 'NTFS') then begin
      MessageBoxA(Handle,
                  Pchar('This is not a NTFS disk !'+#13#10+'Unable to continue.'),
                  Pchar('Error'),
                  MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
      Log('Error : This is not a NTFS disk !', clred);
      Dispose(PBootSequence);
      Closehandle(hDevice);
      ChangeUIEnableStatus(true);
      exit;
    end else begin
      Log('This is a NTFS disk.', clGreen);
    end;
  end;
  BytesPerSector := PBootSequence^.wBytesPerSector;
  SectorsPerCluster := PBootSequence^.bSectorsPerCluster;
  BytesPerCluster := SectorsPerCluster * BytesPerSector;
  Log('Bytes Per Sector : '+IntToStr(BytesPerSector));
  Log('Sectors Per Cluster : '+IntToStr(SectorsPerCluster));
  Log('Bytes Per Cluster : '+IntToStr(BytesPerCluster));
  Label3.Caption := 'Size : '+IntToStr(PBootSequence.TotalSectors*BytesPerSector)+' bytes';
  if (PBootSequence^.ClustersPerFileRecord < $80) then
      BytesPerFileRecord := PBootSequence^.ClustersPerFileRecord * BytesPerCluster
  else
      BytesPerFileRecord := 1 shl ($100 - PBootSequence^.ClustersPerFileRecord);
  Log('Bytes Per File Record : '+IntToStr(BytesPerFileRecord));

  MASTER_FILE_TABLE_LOCATION := PBootSequence^.MftStartLcn * PBootSequence^.wBytesPerSector
                                * PBootSequence^.bSectorsPerCluster;
  Log('MFT Location : $'+IntToHex(MASTER_FILE_TABLE_LOCATION,2));
  Label4.Caption := 'MFT Location : $'+IntToHex(MASTER_FILE_TABLE_LOCATION,2);



                    {// EXPORTS THE RESULT INTO A FILE : VISUALIZATION ==== DEBUG PURPOSE ONLY ====
                    SetLength(MFTData,BytesPerFileRecord);
                    SetFilePointer(hDevice, Int64Rec(MASTER_FILE_TABLE_LOCATION).Lo,
                                   @Int64Rec(MASTER_FILE_TABLE_LOCATION).Hi, FILE_BEGIN);
                    Readfile(hDevice, PChar(MFTData)^, BytesPerFileRecord, dwread, nil);

                    hDest:= CreateFile(PChar(DEBUG_FOLDER_LOCATION+'mft_mainrecord.txt'), GENERIC_WRITE,
                                       0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
                    WriteFile(hDest, PChar(MFTData)^, BytesPerFileRecord, dwwritten, nil);
                    Closehandle(hDest);
                    Log('MFT File Written : mft_mainrecord.txt ('+IntToStr(dwwritten)+' Bytes)', clBlue);
                    // ===========================================================================}



  SetLength(MFTData,BytesPerFileRecord);
  SetFilePointer(hDevice, Int64Rec(MASTER_FILE_TABLE_LOCATION).Lo,
                 @Int64Rec(MASTER_FILE_TABLE_LOCATION).Hi, FILE_BEGIN);
  Readfile(hDevice, PChar(MFTData)^, BytesPerFileRecord, dwread, nil);
  Log('MFT Data Read : '+IntToStr(dwread)+' Bytes', clBlue);

  try
    FixupUpdateSequence(MFTData);
  except on E: Exception do begin
    Log('Error : '+E.Message, clred);
    MessageBoxA(Handle,
                Pchar(E.Message+#13#10+'Unable to continue.'),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    Closehandle(hDevice);
    ChangeUIEnableStatus(true);
    exit;
    end;
  end;
  Log('MFT Data FixedUp');



                    {// EXPORTS THE RESULT INTO A FILE : VISUALIZATION ==== DEBUG PURPOSE ONLY ====
                    hDest:= CreateFile(PChar(DEBUG_FOLDER_LOCATION+'mft_fixedup.txt'), GENERIC_WRITE, 0,
                                       nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
                    WriteFile(hDest, PChar(MFTData)^, BytesPerFileRecord, dwwritten, nil);
                    Closehandle(hDest);
                    Log('FixedUp MFT File Written : mft_fixedup.txt ('+IntToStr(dwwritten)+' Bytes)',
                        clBlue);
                    // ===========================================================================}



  MFTAttributeData := FindAttributeByType(MFTData,atAttributeData);



                    {// EXPORTS THE RESULT INTO A FILE : VISUALIZATION ==== DEBUG PURPOSE ONLY ====
                    hDest:= CreateFile(PChar(DEBUG_FOLDER_LOCATION+'mft_attrdata.txt'), GENERIC_WRITE, 0,
                                       nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
                    WriteFile(hDest, PChar(MFTAttributeData)^, Length(MFTAttributeData), dwwritten, nil);
                    Closehandle(hDest);
                    Log('MFT $ATTRIBUTE_DATA File Written : mft_attrdata.txt ('+IntToStr(dwwritten)+
                        ' Bytes)', clBlue);
                    // ===========================================================================}



  New(pMFTNonResidentAttribute);
  ZeroMemory(pMFTNonResidentAttribute, SizeOf(TNONRESIDENT_ATTRIBUTE));
  CopyMemory(pMFTNonResidentAttribute, MFTAttributeData, SizeOf(TNONRESIDENT_ATTRIBUTE));

  if (pMFTNonResidentAttribute^.Attribute.Flags = $8000)
     or (pMFTNonResidentAttribute^.Attribute.Flags = $4000)
     or (pMFTNonResidentAttribute^.Attribute.Flags = $0001) then begin
    MessageBoxA(Handle,
                Pchar('The MFT is sparse, encrypted or compressed.'+#13#10+'Unable to continue.'),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    Log('Error : The MFT is fragmented : Unable to continue.', clRed);
    Dispose(pMFTNonResidentAttribute);
    ChangeUIEnableStatus(true);
    exit;
  end;
  MASTER_FILE_TABLE_SIZE := pMFTNonResidentAttribute^.HighVCN - pMFTNonResidentAttribute^.LowVCN;
                                                             { \_____________ = 0 _____________/ }

  Dispose(pMFTNonResidentAttribute);
  MASTER_FILE_TABLE_END := MASTER_FILE_TABLE_LOCATION + MASTER_FILE_TABLE_SIZE;
  MASTER_FILE_TABLE_RECORD_COUNT := (MASTER_FILE_TABLE_SIZE * BytesPerCluster) div BytesPerFileRecord;
  Log('MFT Size : '+IntToStr(MASTER_FILE_TABLE_SIZE)+' Clusters');
  Log('Number Of Records : '+IntToStr(MASTER_FILE_TABLE_RECORD_COUNT));
  Label5.Caption := 'MFT Size : '+IntToStr(MASTER_FILE_TABLE_SIZE*BytesPerCluster)+' bytes';
  Label6.Caption := 'Number of Records : '+IntToStr(MASTER_FILE_TABLE_RECORD_COUNT);


  Log('Scanning for deleted files, please wait...');
  Label9.Caption := 'Analyzing File Record 16 out of '+IntToStr(MASTER_FILE_TABLE_RECORD_COUNT);
  Application.ProcessMessages;
  StringGrid1.RowCount := 1;
  RadioGroup1.ItemIndex := 0;
  for CurrentRecordCounter := 16 to MASTER_FILE_TABLE_RECORD_COUNT-1 do begin

    if (CurrentRecordCounter mod 512) = 0 then begin // Refreshes File Counter every 512 records
       Label9.Caption := 'Analyzing File Record '+IntToStr(CurrentRecordCounter)+' out of '
                            +IntToStr(MASTER_FILE_TABLE_RECORD_COUNT);
       Application.ProcessMessages;
    end;

    CurrentRecordLocator := MASTER_FILE_TABLE_LOCATION + CurrentRecordCounter*BytesPerFileRecord;
    SetLength(MFTData,BytesPerFileRecord);
    SetFilePointer(hDevice, Int64Rec(CurrentRecordLocator).Lo,
                   @Int64Rec(CurrentRecordLocator).Hi, FILE_BEGIN);
    Readfile(hDevice, PChar(MFTData)^, BytesPerFileRecord, dwread, nil);
    try
      FixupUpdateSequence(MFTData);
    except on E: Exception do begin
      Log('Warning : File Record '+IntToStr(CurrentRecordCounter)+' out of '
          +IntToStr(MASTER_FILE_TABLE_RECORD_COUNT-1)+' : '+E.Message, clMaroon);
      continue;
      end;
    end;



                    {// EXPORTS THE RESULT INTO A FILE : VISUALIZATION ==== DEBUG PURPOSE ONLY ====
                    hDest:= CreateFile(PChar(DEBUG_FOLDER_LOCATION+'mft_filerecord_fixedup.txt'),
                                       GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
                    WriteFile(hDest, PChar(MFTData)^, BytesPerFileRecord, dwwritten, nil);
                    Closehandle(hDest);
                    ShowMessage('FixedUp MFT FileRecordData Written : '+IntToStr(dwwritten)+' Bytes');
                    // ===========================================================================}



    New(pFileRecord);
    ZeroMemory(pFileRecord, SizeOf(TFILE_RECORD));
    CopyMemory(pFileRecord, MFTData, SizeOf(TFILE_RECORD));



    if pFileRecord^.Flags=$0 then begin // If the file is set as Deleted

      StandardInformationAttributeData := FindAttributeByType(MFTData, atAttributeStandardInformation);
      if StandardInformationAttributeData<>nil then begin
        New(pStandardInformationAttribute);
        ZeroMemory(pStandardInformationAttribute, SizeOf(TSTANDARD_INFORMATION));
        CopyMemory(pStandardInformationAttribute, StandardInformationAttributeData,
                   SizeOf(TSTANDARD_INFORMATION));
           FileCreationTime := Int64TimeToDateTime(pStandardInformationAttribute^.CreationTime);
           FileChangeTime := Int64TimeToDateTime(pStandardInformationAttribute^.ChangeTime);
        Dispose(pStandardInformationAttribute);
      end else begin
        continue;
      end;

      FileNameAttributeData := FindAttributeByType(MFTData, atAttributeFileName, true);
      if FileNameAttributeData<>nil then begin
        New(pFileNameAttribute);
        ZeroMemory(pFileNameAttribute, SizeOf(TFILENAME_ATTRIBUTE));
        CopyMemory(pFileNameAttribute, FileNameAttributeData, SizeOf(TFILENAME_ATTRIBUTE));
           FileName := WideString(Copy(FileNameAttributeData, $5A, pFileNameAttribute^.NameLength*2));
        Dispose(pFileNameAttribute);
      end else begin
        continue;
      end;

      DataAttributeHeader := FindAttributeByType(MFTData, atAttributeData);
      if DataAttributeHeader<>nil then begin
        New(pDataAttributeHeader);
        ZeroMemory(pDataAttributeHeader, SizeOf(TRECORD_ATTRIBUTE));
        CopyMemory(pDataAttributeHeader, DataAttributeHeader, SizeOf(TRECORD_ATTRIBUTE));
           FileSizeArray := Copy(DataAttributeHeader, $10+(pDataAttributeHeader^.NonResident)*$20,
                                 (pDataAttributeHeader^.NonResident+$1)*$4 );
           FileSize := 0;
           for i:=Length(FileSizeArray)-1 downto 0 do FileSize := (FileSize shl 8)+Ord(FileSizeArray[i]);
        Dispose(pDataAttributeHeader);
      end else begin
        continue;
      end;

      StringGrid1.RowCount := StringGrid1.RowCount + 1;
      StringGrid1.Rows[StringGrid1.RowCount-1].Text :=
                        ('$'+IntToHex(CurrentRecordLocator,2)+#13#10
                         +FileName+#13#10
                         +IntToStr(FileSize)+#13#10
                         +FormatDateTime('c',FileCreationTime)+#13#10
                         +FormatDateTime('c',FileChangeTime));

    end;
    Dispose(pFileRecord);
  end;

  Log('All File Records Analyzed ('+IntToStr(MASTER_FILE_TABLE_RECORD_COUNT)+')',clGreen);
  Application.ProcessMessages;
  StringGrid1.FixedRows := 1;
  ChangeUIEnableStatus(true);
  Dispose(PBootSequence);
  Closehandle(hDevice);

end;

procedure TForm1.BitBtn4Click(Sender: TObject);
var
  RecordLocator: Int64;
  hDevice, hDest : THandle;
  MFTFileRecord: TDynamicCharArray;
  StandardInformationAttributeData: TDynamicCharArray;
  FileNameAttributeData: TDynamicCharArray;
  DataAttributeHeader: TDynamicCharArray;
  ResidentDataAttributeData: TDynamicCharArray;
  NonResidentDataAttributeData: TDynamicCharArray;
  pFileRecord: ^TFILE_RECORD;
  pStandardInformationAttribute : ^TSTANDARD_INFORMATION;
  pFileNameAttribute : ^TFILENAME_ATTRIBUTE;
  pDataAttributeHeader : ^TRECORD_ATTRIBUTE;
  pResidentDataAttribute : ^TRESIDENT_ATTRIBUTE;
  pNonResidentDataAttribute : ^TNONRESIDENT_ATTRIBUTE;
  dwread: LongWord;
  dwwritten: LongWord;
  FileName: WideString;
  FileCreationTime, FileChangeTime: TDateTime;
  NonResidentFlag : boolean;
  DataAttributeSize: DWord;
  NonRes_OffsetToDataRuns: Word;
  NonRes_DataSize: Int64;
  NonRes_DataRuns: TDynamicCharArray;
  NonRes_DataRunsIndex: integer;
  NonRes_DataOffset: Int64;
  NonRes_DataOffset_inBytes: Int64;
  NonRes_CurrentLength: Int64;
  NonRes_CurrentOffset: Int64;
  NonRes_CurrentLengthSize: Byte;
  NonRes_CurrentOffsetSize: Byte;
  NonRes_CurrentData: TDynamicCharArray;
  NonRes_PreviousFileDataLength: Int64;
  Res_OffsetToData: Word;
  Res_DataSize: Int64;
  FileData: TDynamicCharArray;
  FileType: string;
  i : integer;
  i64 : Int64;
begin
  if (StringGrid1.Row<1) or (StringGrid1.Rows[1].Strings[0]='')
     or (StringGrid1.Rows[1].Strings[0]=' ') then exit;

  RecordLocator := StrToInt64(StringGrid1.Rows[StringGrid1.Row].Strings[0]);
  Log('Attempting to restore from FileRecord $'+IntToHex(RecordLocator,2));
  hDevice := CreateFile( PChar('\\.\'+CURRENT_DRIVE), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE,
                         nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if (hDevice = INVALID_HANDLE_VALUE) then begin
    Log('Invalid Handle Value : Error '+IntToStr(GetLastError()), clred);
    MessageBoxA(Handle,
                Pchar('Invalid Handle Value'+#13#10+'Error '+IntToStr(GetLastError())),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    Closehandle(hDevice);
    exit;
  end else begin
    Log('Drive '+CURRENT_DRIVE+'\ Successfully Opened', clGreen);
  end;
  SetFilePointer(hDevice, 0, nil, FILE_BEGIN);
  SetLength(MFTFileRecord,BytesPerFileRecord);
  SetFilePointer(hDevice, Int64Rec(RecordLocator).Lo, @Int64Rec(RecordLocator).Hi, FILE_BEGIN);
  Readfile(hDevice, PChar(MFTFileRecord)^, BytesPerFileRecord, dwread, nil);
  try
    FixupUpdateSequence(MFTFileRecord);
  except on E: Exception do begin
    Log('Error during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)+') : '
        +E.Message, clred);
    MessageBoxA(Handle,
                Pchar('Error during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)+')'
                      +#13#10+E.Message+#13#10+'Unable to continue.'),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    Closehandle(hDevice);
    exit;
    end;
  end;
  Log('FileRecord Data FixedUp', clGreen);



                    {// EXPORTS THE RESULT INTO A FILE : VISUALIZATION ==== DEBUG PURPOSE ONLY ====
                    hDest:= CreateFile(PChar(DEBUG_FOLDER_LOCATION+''), GENERIC_WRITE, 0, nil,
                                       CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
                    WriteFile(hDest, PChar(MFTFileRecord)^, BytesPerFileRecord, dwwritten, nil);
                    Closehandle(hDest);
                    Log('FixedUp FileRecordData Written : filerecord_fixedup.txt ('+IntToStr(dwwritten)
                        +' Bytes)', clBlue);
                    // ===========================================================================}



  New(pFileRecord);
  ZeroMemory(pFileRecord, SizeOf(TFILE_RECORD));
  CopyMemory(pFileRecord, MFTFileRecord, SizeOf(TFILE_RECORD));
  if pFileRecord^.Flags<>0 then begin
    Log('Error : The file seems no longer listed as Deleted.', clred);
    MessageBoxA(Handle,
                Pchar('Error during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)+')'
                      +#13#10'The file seems no longer listed as Deleted.'+#13#10+'Unable to continue.'),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    Dispose(pFileRecord);
    Closehandle(hDevice);
    exit;
  end;
  Log('File actually listed as Deleted.', clGreen);
  StandardInformationAttributeData := FindAttributeByType(MFTFileRecord, atAttributeStandardInformation);
  if StandardInformationAttributeData<>nil then begin
    New(pStandardInformationAttribute);
    ZeroMemory(pStandardInformationAttribute, SizeOf(TSTANDARD_INFORMATION));
    CopyMemory(pStandardInformationAttribute, StandardInformationAttributeData,
               SizeOf(TSTANDARD_INFORMATION));
    Log('FileCreationTime : '+IntToStr(pStandardInformationAttribute^.CreationTime), clBlue);
    Log('FileChangeTime : '+IntToStr(pStandardInformationAttribute^.ChangeTime), clBlue);
          FileCreationTime := Int64TimeToDateTime(pStandardInformationAttribute^.CreationTime);
          FileChangeTime := Int64TimeToDateTime(pStandardInformationAttribute^.ChangeTime);
    Dispose(pStandardInformationAttribute);
    Log('DateTime information retrieved', clGreen);
  end else begin
    FileCreationTime := now;
    FileChangeTime := now;
    Log('Warning : Unable to retrieve the file DateTime information.', clMaroon);
    Log('DateTime information recreated (default value: now)', clMaroon);
    MessageBoxA(Handle,
                Pchar('Warning during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)
                      +')'+#13#10+'Unable to retrieve the file DateTime information.'
                      +#13#10+'Default values will be used instead.'),
                Pchar('Warning'),
                MB_ICONEXCLAMATION + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
  end;
  FileNameAttributeData := FindAttributeByType(MFTFileRecord, atAttributeFileName, true);
  if FileNameAttributeData<>nil then begin
    New(pFileNameAttribute);
    ZeroMemory(pFileNameAttribute, SizeOf(TFILENAME_ATTRIBUTE));
    CopyMemory(pFileNameAttribute, FileNameAttributeData, SizeOf(TFILENAME_ATTRIBUTE));
          FileName := WideString(Copy(FileNameAttributeData, $5A, pFileNameAttribute^.NameLength*2));
    Log('FileName : '+FileName, clBlue);
    Dispose(pFileNameAttribute);
    Log('FileName information retrieved', clGreen);
  end else begin
    FileName := 'UntitledFile.xxx';
    Log('Warning : Unable to retrieve the file FileName information.', clMaroon);
    Log('FileName information recreated (default value: UntitledFile.xxx)', clMaroon);
    MessageBoxA(Handle,
                Pchar('Warning during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)
                      +')'+#13#10+'Unable to retrieve the file FileName information.'
                      +#13#10+'Default value will be used instead.'),
                Pchar('Warning'),
                MB_ICONEXCLAMATION + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
  end;
  DataAttributeHeader := FindAttributeByType(MFTFileRecord, atAttributeData);
  if DataAttributeHeader<>nil then begin
    New(pDataAttributeHeader);
    ZeroMemory(pDataAttributeHeader, SizeOf(TRECORD_ATTRIBUTE));
    CopyMemory(pDataAttributeHeader, DataAttributeHeader, SizeOf(TRECORD_ATTRIBUTE));
          NonResidentFlag := pDataAttributeHeader^.NonResident=1;
          DataAttributeSize := pDataAttributeHeader^.Length;
    Dispose(pDataAttributeHeader);
    Log('Non-Resident Flag : '+IntToStr(Ord(NonResidentFlag)), clBlue);
    Log('Data Attribute Size : '+IntToStr(DataAttributeSize), clBlue);
  end else begin
    Log('Error : Unable to get any DataType information', clred);
    MessageBoxA(Handle,
                Pchar('Error during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)+')'
                      +#13#10+'Unable to get any DataType information.'+#13#10+'Unable to continue.'),
                Pchar('Error'),
                MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    Dispose(pFileRecord);
    Closehandle(hDevice);
    exit;
  end;
  if NonResidentFlag then begin

    Log('The Data Attribute is Non-Resident.');
    NonResidentDataAttributeData := FindAttributeByType(MFTFileRecord, atAttributeData);
    if NonResidentDataAttributeData<>nil then begin
      New(pNonResidentDataAttribute);
      ZeroMemory(pNonResidentDataAttribute, SizeOf(TNONRESIDENT_ATTRIBUTE));
      CopyMemory(pNonResidentDataAttribute,NonResidentDataAttributeData, SizeOf(TNONRESIDENT_ATTRIBUTE));
            NonRes_OffsetToDataRuns := pNonResidentDataAttribute^.RunArrayOffset;
            NonRes_DataSize := pNonResidentDataAttribute^.DataSize;
      Log('Offset To Data Runs : $'+IntToHex(NonRes_OffsetToDataRuns,2), clBlue);
      Log('Data Size : $'+IntToHex(NonRes_DataSize,2), clBlue);
      Dispose(pNonResidentDataAttribute);
      SetLength(NonRes_DataRuns, DataAttributeSize-(NonRes_OffsetToDataRuns-1));
      NonRes_DataRuns := Copy(NonResidentDataAttributeData,NonRes_OffsetToDataRuns,
                              DataAttributeSize-(NonRes_OffsetToDataRuns-1));
      Log('Data Runs retrieved.', clGreen);
    end else begin
      Log('Error : Unable to read NonResident Data information.', clred);
      MessageBoxA(Handle,
                  Pchar('Error during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)
                        +')'+#13#10+'Unable to read NonResident Data information.'
                        +#13#10+'Unable to continue.'),
                  Pchar('Error'),
                  MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
      Dispose(pFileRecord);
      Closehandle(hDevice);
      exit;
    end;

    try
      SetLength(FileData, 0);
      NonRes_DataRunsIndex := 0;
      NonRes_DataOffset := 0;
      while NonRes_DataRuns[NonRes_DataRunsIndex] <> Char($00)  do begin
        NonRes_CurrentLengthSize := Ord(NonRes_DataRuns[NonRes_DataRunsIndex]) and $F;
        NonRes_CurrentOffsetSize := (Ord(NonRes_DataRuns[NonRes_DataRunsIndex]) shr 4) and $F;
        NonRes_CurrentLength := 0;
        NonRes_CurrentOffset := 0;
        for i := NonRes_CurrentLengthSize-1 downto 0 do
            NonRes_CurrentLength := (Ord(NonRes_CurrentLength) shl 8)
                                    + Ord(NonRes_DataRuns[1+i+NonRes_DataRunsIndex]);
        for i := NonRes_CurrentLengthSize+NonRes_CurrentOffsetSize-1 downto NonRes_CurrentLengthSize do
            NonRes_CurrentOffset := (Ord(NonRes_CurrentOffset) shl 8)
                                    + Ord(NonRes_DataRuns[1+i+NonRes_DataRunsIndex]);
        if (NonRes_CurrentOffset > ($80 shl ((8*NonRes_CurrentOffsetSize)-1)))
           and (NonRes_DataRunsIndex<>0) then // This is a signed value (first one excepted!!!)
          NonRes_DataOffset := NonRes_DataOffset
                               - ( ($100 shl ((8*NonRes_CurrentOffsetSize)-1) ) - NonRes_CurrentOffset)
        else
          NonRes_DataOffset := NonRes_DataOffset + NonRes_CurrentOffset;

        SetLength(NonRes_CurrentData, NonRes_CurrentLength*BytesPerCluster);
        NonRes_DataOffset_inBytes := NonRes_DataOffset*BytesPerCluster;
        SetFilePointer(hDevice, Int64Rec(NonRes_DataOffset_inBytes).Lo,
                       @Int64Rec(NonRes_DataOffset_inBytes).Hi, FILE_BEGIN);
        Readfile(hDevice, PChar(NonRes_CurrentData)^, NonRes_CurrentLength*BytesPerCluster, dwread, nil);

        NonRes_PreviousFileDataLength := Length(FileData);
        SetLength(FileData, NonRes_PreviousFileDataLength + (NonRes_CurrentLength*BytesPerCluster));

        if NonRes_CurrentOffset=0 then begin
          i64 := NonRes_PreviousFileDataLength;
          while i64 <= Length(FileData)-1 do begin
            FileData[i64] := Char($00);
            inc(i64);
          end;
          { The following code cannot be compiled because Int64 isn't considered as an ordinal type
          for i64 := NonRes_PreviousFileDataLength to Length(FileData)-1 do
              FileData[i64] := $00; }

        end else begin
          i64 := NonRes_PreviousFileDataLength;
          while i64 <= Length(FileData)-1 do begin
            FileData[i64] := NonRes_CurrentData[i64-NonRes_PreviousFileDataLength];
            inc(i64);
          end;
          { The following code cannot be compiled because Int64 isn't considered as an ordinal type
          for i64 := NonRes_PreviousFileDataLength to Length(FileData)-1 do
              FileData[i64] := NonRes_CurrentData[i-NonRes_PreviousFileDataLength]; }

        end;
        NonRes_DataRunsIndex := NonRes_DataRunsIndex+NonRes_CurrentLengthSize+NonRes_CurrentOffsetSize+1;
      end;
      SetLength(FileData, NonRes_DataSize);
      Log('Data Runs processed : Data Recovered', clGreen);
    except
      Log('Error : Unable to compute correctly the DataRuns information.', clred);
      MessageBoxA(Handle,
                  Pchar('Error during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)
                        +')'+#13#10+'Unable to compute correctly the DataRuns information.'
                        +#13#10+'Unable to continue.'),
                  Pchar('Error'),
                  MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
      Dispose(pFileRecord);
      Closehandle(hDevice);
      exit;
    end;
  end else begin
    Log('The Data Attribute is Resident.');
    ResidentDataAttributeData := FindAttributeByType(MFTFileRecord, atAttributeData);
    if ResidentDataAttributeData<>nil then begin
      New(pResidentDataAttribute);
      ZeroMemory(pResidentDataAttribute, SizeOf(TRESIDENT_ATTRIBUTE));
      CopyMemory(pResidentDataAttribute, ResidentDataAttributeData, SizeOf(TRESIDENT_ATTRIBUTE));
            Res_OffsetToData := pResidentDataAttribute^.ValueOffset;
            Res_DataSize := pResidentDataAttribute^.ValueLength;
      Log('Offset To Data : $'+IntToHex(Res_OffsetToData,2), clBlue);
      Log('Data Size : $'+IntToHex(Res_DataSize,2), clBlue);
      Dispose(pResidentDataAttribute);
            SetLength(FileData, Res_DataSize);
            FileData := Copy(ResidentDataAttributeData,Res_OffsetToData,Res_DataSize);
      Log('Data Recovered', clGreen);
    end else begin
      Log('Error : Unable to read Resident Data information.', clred);
      MessageBoxA(Handle,
                  Pchar('Error during File Recovery (File Record Address : $'+IntToHex(RecordLocator,2)
                        +')'+#13#10'Unable to read Resident Data information.'
                        +#13#10+'Unable to continue.'),
                  Pchar('Error'),
                  MB_ICONSTOP + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
      Dispose(pFileRecord);
      Closehandle(hDevice);
      exit;
    end;

  end;
  FileDetailsForm.FileNameLbl.Caption := FileName;
  FileDetailsForm.SizeLbl.Caption := IntToStr(Length(FileData))+' Bytes';
  FileDetailsForm.CreationTimeLbl.Caption := 'Creation : '+FormatDateTime('c', FileCreationTime);
  FileDetailsForm.ChangeTimeLbl.Caption := 'Last Change : '+FormatDateTime('c', FileChangeTime);;
  FileDetailsForm.RecordLocationLbl.Caption := 'MFT File Record Location on Hard Drive : $'
                                               +IntToHex(RecordLocator,2);
  FileDetailsForm.SysIco.GetIcon(FileDetailsForm.GetIconIndex(ExtractFileExt(FileName), 0, FileType),
                                 FileDetailsForm.IconImg.Picture.Icon.Create);
  FileDetailsForm.FileTypeLbl.Caption := FileType;
  if (FileDetailsForm.ShowModal = mrOK) then begin
    SaveDialog.FileName := FileName;
    if SaveDialog.Execute then begin
      // Saves the Restored File
      hDest:= CreateFile(PChar(SaveDialog.FileName), GENERIC_WRITE, 0, nil, CREATE_ALWAYS,
                         FILE_ATTRIBUTE_NORMAL, 0);
      WriteFile(hDest, PChar(FileData)^, Length(FileData), dwwritten, nil);
      Closehandle(hDest);
      Log('Recovered File Written : '+ExtractFileName(SaveDialog.FileName)+' ('
          +IntToStr(dwwritten)+' Bytes)', clBlue);
      Log('File Recovered', clGreen);
      MessageBoxA(Handle,
                  Pchar('The file has been recovered and saved :'+#13#10+SaveDialog.FileName),
                  Pchar('Information'),
                  MB_ICONINFORMATION + MB_SYSTEMMODAL + MB_SETFOREGROUND + MB_TOPMOST);
    end;
  end;
  Dispose(pFileRecord);
  Closehandle(hDevice);
end;

end.
