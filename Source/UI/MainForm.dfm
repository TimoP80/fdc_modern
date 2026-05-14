object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Fallout Dialogue Creator'
  ClientHeight = 600
  ClientWidth = 1000
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clLime
  Font.Height = -11
  Font.Name = 'Courier New'
  Font.Style = []
  Menu = mainMenu
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pnlLeft: TPanel
    Left = 0
    Top = 0
    Width = 200
    Height = 600
    Align = alLeft
    BevelOuter = bvNone
    Color = clGreen
    ParentBackground = False
    TabOrder = 0
    object lstNodePalette: TListBox
      Left = 0
      Top = 0
      Width = 200
      Height = 600
      Align = alClient
      Color = clBlack
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clLime
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ItemHeight = 13
      ParentColor = False
      ParentFont = False
      TabOrder = 0
    end
  end
  object splitLeft: TSplitter
    Left = 200
    Top = 0
    Width = 5
    Height = 600
    Color = clLime
    ParentColor = False
  end
  object pnlCenter: TPanel
    Left = 205
    Top = 0
    Width = 595
    Height = 600
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
  end
  object splitRight: TSplitter
    Left = 800
    Top = 0
    Width = 5
    Height = 600
    Color = clLime
    ParentColor = False
  end
  object pnlRight: TPanel
    Left = 805
    Top = 0
    Width = 195
    Height = 600
    Align = alRight
    BevelOuter = bvNone
    Color = clGreen
    ParentBackground = False
    TabOrder = 4
    object propInspector: TStringGrid
      Left = 0
      Top = 0
      Width = 195
      Height = 600
      Align = alClient
      ColCount = 2
      DefaultColWidth = 90
      FixedRows = 1
      RowCount = 10
      TabOrder = 0
    end
  end
  object splitBottom: TSplitter
    Left = 205
    Top = 565
    Width = 595
    Height = 5
    Color = clLime
    ParentColor = False
  end
  object pnlBottom: TPanel
    Left = 205
    Top = 570
    Width = 595
    Height = 30
    Align = alBottom
    BevelOuter = bvNone
    Color = clBlack
    ParentBackground = False
    TabOrder = 6
    object memConsole: TMemo
      Left = 0
      Top = 0
      Width = 595
      Height = 30
      Align = alClient
      Color = clBlack
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clLime
      Font.Height = -11
      Font.Name = 'Courier New'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      ReadOnly = True
      TabOrder = 0
    end
  end
  object mainMenu: TMainMenu
    Left = 8
    Top = 8
    object mnuFile: TMenuItem
      Caption = '&File'
      object mnuNew: TMenuItem
        Caption = '&New'
        OnClick = mnuNewClick
      end
      object mnuOpen: TMenuItem
        Caption = '&Open'
        OnClick = mnuOpenClick
      end
      object mnuSave: TMenuItem
        Caption = '&Save'
        OnClick = mnuSaveClick
      end
      object mnuExit: TMenuItem
        Caption = 'E&xit'
        OnClick = mnuExitClick
      end
    end
    object mnuExport: TMenuItem
      Caption = '&Export'
      object mnuExportSSL: TMenuItem
        Caption = 'Export &SSL'
        OnClick = mnuExportSSLClick
      end
      object mnuExportMSG: TMenuItem
        Caption = 'Export &MSG'
        OnClick = mnuExportMSGClick
      end
    end
  end
end