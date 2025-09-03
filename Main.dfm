object Form1: TForm1
  Left = 362
  Top = 151
  Width = 769
  Height = 424
  Caption = 'File Recovery'
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label9: TLabel
    Left = 6
    Top = 361
    Width = 731
    Height = 13
    Alignment = taCenter
    AutoSize = False
    Caption = 'Program Ready'
    Color = clWhite
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentColor = False
    ParentFont = False
    Transparent = False
  end
  object Label4: TLabel
    Left = 8
    Top = 90
    Width = 129
    Height = 13
    Caption = 'MFT Location : Unknown'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 8
    Top = 58
    Width = 88
    Height = 13
    Caption = 'Serial : Unknown'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label3: TLabel
    Left = 8
    Top = 74
    Width = 80
    Height = 13
    Caption = 'Size : Unknown'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label1: TLabel
    Left = 8
    Top = 42
    Width = 89
    Height = 13
    Caption = 'Name : Unknown'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label5: TLabel
    Left = 8
    Top = 106
    Width = 105
    Height = 13
    Caption = 'MFT Size : Unknown'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label6: TLabel
    Left = 8
    Top = 122
    Width = 159
    Height = 13
    Caption = 'Number of Records : Unknown'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label7: TLabel
    Left = 8
    Top = 208
    Width = 155
    Height = 13
    Caption = 'Search for a specific File Name'
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label8: TLabel
    Left = 8
    Top = 266
    Width = 177
    Height = 13
    Caption = 'Reach Record Offset (hexadecimal)'
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object ScannedFiles_DollarSign: TLabel
    Left = 8
    Top = 292
    Width = 6
    Height = 13
    Caption = '$'
    Transparent = True
  end
  object ComboBox1: TComboBox
    Left = 6
    Top = 7
    Width = 75
    Height = 22
    Style = csDropDownList
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 14
    ParentFont = False
    TabOrder = 0
    TabStop = False
    OnChange = ComboBox1Change
  end
  object RichEdit1: TRichEdit
    Left = 256
    Top = 239
    Width = 481
    Height = 114
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 2
    WordWrap = False
    OnChange = LogChange
  end
  object StringGrid1: TStringGrid
    Left = 257
    Top = 6
    Width = 483
    Height = 227
    TabStop = False
    DefaultColWidth = 90
    DefaultRowHeight = 18
    FixedCols = 0
    RowCount = 1
    FixedRows = 0
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goRowSelect]
    ParentFont = False
    TabOrder = 1
  end
  object Edit1: TEdit
    Left = 8
    Top = 228
    Width = 209
    Height = 19
    TabStop = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -9
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
  end
  object BitBtn2: TBitBtn
    Left = 224
    Top = 228
    Width = 25
    Height = 22
    Hint = 'Find Next Occurrence...'
    Caption = '>>'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 4
    TabStop = False
    OnClick = BitBtn2Click
  end
  object BitBtn1: TBitBtn
    Left = 88
    Top = 6
    Width = 164
    Height = 25
    Caption = '  Scan for Deleted Files'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    TabStop = False
    OnClick = BitBtn1Click
  end
  object Edit2: TEdit
    Left = 16
    Top = 289
    Width = 201
    Height = 19
    Hint = 'Hexadecimal Value Required'
    TabStop = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -9
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 6
  end
  object BitBtn3: TBitBtn
    Left = 224
    Top = 288
    Width = 25
    Height = 22
    Hint = 'Reach this Offset...'
    Caption = '>>'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 7
    TabStop = False
    OnClick = BitBtn3Click
  end
  object BitBtn4: TBitBtn
    Left = 9
    Top = 324
    Width = 240
    Height = 29
    Caption = '  Recover the Selected File'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 8
    TabStop = False
    OnClick = BitBtn4Click
  end
  object RadioGroup1: TRadioGroup
    Left = 12
    Top = 149
    Width = 233
    Height = 44
    Caption = ' Sort Method '
    Color = clBtnFace
    Columns = 2
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    ItemIndex = 0
    Items.Strings = (
      'by Location'
      'by Name')
    ParentColor = False
    ParentFont = False
    TabOrder = 9
    OnClick = RadioGroup1Click
  end
  object SaveDialog: TSaveDialog
    Left = 299
    Top = 57
  end
end
