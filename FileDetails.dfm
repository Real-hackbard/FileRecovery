object FileDetailsForm: TFileDetailsForm
  Left = 305
  Top = 139
  BorderStyle = bsToolWindow
  Caption = 'File Details'
  ClientHeight = 173
  ClientWidth = 287
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object IconImg: TImage
    Left = 24
    Top = 16
    Width = 32
    Height = 32
  end
  object FileNameLbl: TLabel
    Left = 72
    Top = 8
    Width = 67
    Height = 13
    Caption = 'FileNameLbl'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object CreationTimeLbl: TLabel
    Left = 72
    Top = 56
    Width = 76
    Height = 13
    Caption = 'CreationTimeLbl'
  end
  object ChangeTimeLbl: TLabel
    Left = 72
    Top = 72
    Width = 72
    Height = 13
    Caption = 'ChangeTimeLbl'
  end
  object SizeLbl: TLabel
    Left = 72
    Top = 40
    Width = 32
    Height = 13
    Caption = 'SizeLbl'
  end
  object RecordLocationLbl: TLabel
    Left = 8
    Top = 104
    Width = 195
    Height = 13
    Caption = 'MFT File Record Location on Hard Drive :'
  end
  object FileTypeLbl: TLabel
    Left = 80
    Top = 24
    Width = 48
    Height = 11
    Caption = 'FileTypeLbl'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -9
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object CancelBtn: TButton
    Left = 112
    Top = 136
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 0
  end
  object RecoverBtn: TButton
    Left = 192
    Top = 136
    Width = 75
    Height = 25
    Caption = 'Recover'
    ModalResult = 1
    TabOrder = 1
  end
  object SysIco: TImageList
    Height = 32
    Width = 32
    Left = 24
    Top = 57
  end
end
