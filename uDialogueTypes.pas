unit uDialogueTypes;

interface

uses
   System.SysUtils, System.Classes, System.Generics.Collections,
   System.DateUtils, System.JSON, Vcl.Graphics;

type
  TNodeType = (
    ntNPCDialogue,
    ntPlayerReply,
    ntConditional,
    ntRandom,
    ntScript,
    ntCombatTrigger,
    ntQuestUpdate,
    ntTrade,
    ntEndDialogue,
    ntComment
  );

  TSkillType = (
    skSpeech, skBarter, skScience, skRepair, skLockpick,
    skSneak, skMedicine, skSurvival, skGambling,
    skEnergyWeapons, skSmallGuns, skBigGuns
  );

  TConditionOperator = (coEQ, coNEQ, coLT, coGT, coLTE, coGTE);
  TBoolOp = (boAND, boOR, boNOT);

  TConditionType = (
    ctSkillCheck, ctStatCheck, ctReputation, ctKarma,
    ctGlobalVar, ctLocalVar, ctQuestFlag, ctInventory,
    ctTimeOfDay, ctCompanion, ctRandom
  );

  TCondition = record
    CondType: TConditionType;
    Variable: string;
    Operator: TConditionOperator;
    Value: string;
    BoolOp: TBoolOp;
  end;

  TSkillCheck = record
    Skill: TSkillType;
    Difficulty: Integer;      // 1-100
    CritSuccessBonus: Integer;
    XPReward: Integer;
    SuccessMessage: string;
    FailureMessage: string;
    SuccessNodeID: string;
    FailureNodeID: string;
  end;

  TPlayerOption = class
  public
    ID: string;
    Text: string;
    TargetNodeID: string;
    Conditions: TArray<TCondition>;
    HasSkillCheck: Boolean;
    SkillCheck: TSkillCheck;
    IsHidden: Boolean;
    ScriptOnSelect: string;
    ReputationRequired: Integer;
    KarmaRequired: Integer;
    ItemRequired: string;
    constructor Create;
  end;

  TScriptEvent = (
    seOnDialogueStart, seOnNodeEnter, seOnOptionSelected,
    seOnSkillCheck, seOnQuestUpdate, seOnCombatStart, seOnDialogueEnd
  );

  TNodeScript = class
  public
    EventType: TScriptEvent;
    ScriptCode: string;
    IsEnabled: Boolean;
    constructor Create;
  end;

  TDialogueNode = class
  private
    FID: string;
    FNodeType: TNodeType;
    FText: string;
    FSpeaker: string;
    FPortraitFile: string;
    FVoiceFile: string;
    FX, FY: Integer;
    FWidth, FHeight: Integer;
    FColor: TColor;
    FSelected: Boolean;
    FPlayerOptions: TObjectList<TPlayerOption>;
    FConditions: TList<TCondition>;
    FScripts: TObjectList<TNodeScript>;
    FComment: string;
    FQuestID: string;
    FQuestFlag: string;
    FScriptFile: string;
    FReputation: Integer;
    FKarma: Integer;
    FTag: string;
    FNotes: string;
    FNextNodeID: string;  // For simple linear nodes
    FIsStartNode: Boolean;
    FRandomWeight: Integer;
    FCombatScript: string;
    FTradeInventory: string;
  public
    constructor Create(const aID: string; aType: TNodeType);
    destructor Destroy; override;
    function ToJSON: TJSONObject;
    procedure FromJSON(obj: TJSONObject);
    property ID: string read FID write FID;
    property NodeType: TNodeType read FNodeType write FNodeType;
    property Text: string read FText write FText;
    property Speaker: string read FSpeaker write FSpeaker;
    property PortraitFile: string read FPortraitFile write FPortraitFile;
    property VoiceFile: string read FVoiceFile write FVoiceFile;
    property X: Integer read FX write FX;
    property Y: Integer read FY write FY;
    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    property Color: TColor read FColor write FColor;
    property Selected: Boolean read FSelected write FSelected;
    property PlayerOptions: TObjectList<TPlayerOption> read FPlayerOptions;
    property Conditions: TList<TCondition> read FConditions;
    property Scripts: TObjectList<TNodeScript> read FScripts;
    property Comment: string read FComment write FComment;
    property QuestID: string read FQuestID write FQuestID;
    property QuestFlag: string read FQuestFlag write FQuestFlag;
    property ScriptFile: string read FScriptFile write FScriptFile;
    property Reputation: Integer read FReputation write FReputation;
    property Karma: Integer read FKarma write FKarma;
    property Tag: string read FTag write FTag;
    property Notes: string read FNotes write FNotes;
    property NextNodeID: string read FNextNodeID write FNextNodeID;
    property IsStartNode: Boolean read FIsStartNode write FIsStartNode;
    property RandomWeight: Integer read FRandomWeight write FRandomWeight;
    property CombatScript: string read FCombatScript write FCombatScript;
    property TradeInventory: string read FTradeInventory write FTradeInventory;
  end;

  TFloatMessage = class
  public
    ID: string;
    Category: string;
    Text: string;
    Priority: Integer;
    Weight: Integer;
    Condition: string;
    TimedDuration: Single;
    IsAmbient: Boolean;
    IsCombatTaunt: Boolean;
    IsContextSensitive: Boolean;
    LocaleKey: string;
    constructor Create;
    function ToJSON: TJSONObject;
    procedure FromJSON(obj: TJSONObject);
  end;

  TDialogueProject = class
  private
    FName: string;
    FFilePath: string;
    FNPCName: string;
    FNPCScript: string;
    FNodes: TObjectList<TDialogueNode>;
    FFloatMessages: TObjectList<TFloatMessage>;
    FGlobalVars: TDictionary<string, string>;
    FModified: Boolean;
    FStartNodeID: string;
    FDescription: string;
    FVersion: string;
    FAuthor: string;
    FCreatedDate: TDateTime;
    FModifiedDate: TDateTime;
    FTags: TStringList;
    FLocales: TStringList;
    FActiveLocale: string;
  public
    constructor Create;
    destructor Destroy; override;
    function AddNode(aType: TNodeType): TDialogueNode;
    procedure RemoveNode(const aID: string);
    function FindNode(const aID: string): TDialogueNode;
    function GetConnectedNodes(const aNodeID: string): TList<TDialogueNode>;
    function SaveToFile(const aPath: string): Boolean;
    function LoadFromFile(const aPath: string): Boolean;
    function ToJSON: TJSONObject;
    procedure FromJSON(obj: TJSONObject);
    function ValidateProject: TStringList;
    property Name: string read FName write FName;
    property FilePath: string read FFilePath write FFilePath;
    property NPCName: string read FNPCName write FNPCName;
    property NPCScript: string read FNPCScript write FNPCScript;
    property Nodes: TObjectList<TDialogueNode> read FNodes;
    property FloatMessages: TObjectList<TFloatMessage> read FFloatMessages;
    property GlobalVars: TDictionary<string, string> read FGlobalVars;
    property Modified: Boolean read FModified write FModified;
    property StartNodeID: string read FStartNodeID write FStartNodeID;
    property Description: string read FDescription write FDescription;
    property Version: string read FVersion write FVersion;
    property Author: string read FAuthor write FAuthor;
    property CreatedDate: TDateTime read FCreatedDate;
    property ModifiedDate: TDateTime read FModifiedDate;
    property Tags: TStringList read FTags;
    property Locales: TStringList read FLocales;
    property ActiveLocale: string read FActiveLocale write FActiveLocale;
  end;

const
  NODE_TYPE_NAMES: array[TNodeType] of string = (
    'NPC Dialogue', 'Player Reply', 'Conditional', 'Random',
    'Script', 'Combat Trigger', 'Quest Update', 'Trade',
    'End Dialogue', 'Comment'
  );

  SKILL_NAMES: array[TSkillType] of string = (
    'Speech', 'Barter', 'Science', 'Repair', 'Lockpick',
    'Sneak', 'Medicine', 'Survival', 'Gambling',
    'Energy Weapons', 'Small Guns', 'Big Guns'
  );

  OPERATOR_NAMES: array[TConditionOperator] of string = (
    '==', '!=', '<', '>', '<=', '>='
  );

  NODE_DEFAULT_COLORS: array[TNodeType] of TColor = (
    $002B1F0F,  // NPC Dialogue - dark amber
    $00102B10,  // Player Reply - dark green
    $00261A08,  // Conditional - dark orange
    $00081A26,  // Random - dark cyan
    $00200820,  // Script - dark purple
    $00200808,  // Combat - dark red
    $00082020,  // Quest - dark teal
    $00201808,  // Trade - dark gold
    $00101010,  // End - dark gray
    $00181818   // Comment - medium gray
  );

  NODE_ACCENT_COLORS: array[TNodeType] of TColor = (
    $0020AAFF,  // NPC - amber
    $0040FF40,  // Player - green
    $000080FF,  // Conditional - orange
    $00FFFF00,  // Random - cyan
    $00FF80FF,  // Script - purple
    $000040FF,  // Combat - red
    $00FFFF40,  // Quest - teal
    $0040C0FF,  // Trade - gold
    $00808080,  // End - gray
    $00909090   // Comment - light gray
  );

function GenerateNodeID: string;
function NodeTypeToStr(nt: TNodeType): string;
function StrToNodeType(const s: string): TNodeType;
function SkillTypeToStr(st: TSkillType): string;

implementation

function GenerateNodeID: string;
var
  g: TGUID;
begin
  CreateGUID(g);
  Result := GUIDToString(g);
  Result := StringReplace(Result, '{', '', []);
  Result := StringReplace(Result, '}', '', []);
  Result := StringReplace(Result, '-', '', [rfReplaceAll]);
  Result := 'N_' + Copy(Result, 1, 12);
end;

function NodeTypeToStr(nt: TNodeType): string;
begin
  Result := NODE_TYPE_NAMES[nt];
end;

function StrToNodeType(const s: string): TNodeType;
var
  t: TNodeType;
begin
  Result := ntNPCDialogue;
  for t := Low(TNodeType) to High(TNodeType) do
    if NODE_TYPE_NAMES[t] = s then
    begin
      Result := t;
      Exit;
    end;
end;

function SkillTypeToStr(st: TSkillType): string;
begin
  Result := SKILL_NAMES[st];
end;

{ TPlayerOption }
constructor TPlayerOption.Create;
begin
  inherited;
  ID := GenerateNodeID;
  IsHidden := False;
  HasSkillCheck := False;
  ReputationRequired := 0;
  KarmaRequired := -1000;
end;

{ TNodeScript }
constructor TNodeScript.Create;
begin
  inherited;
  IsEnabled := True;
  EventType := seOnNodeEnter;
  ScriptCode := '';
end;

{ TDialogueNode }
constructor TDialogueNode.Create(const aID: string; aType: TNodeType);
begin
  inherited Create;
  FID := aID;
  FNodeType := aType;
  FWidth := 240;
  FHeight := 120;
  FColor := NODE_DEFAULT_COLORS[aType];
  FPlayerOptions := TObjectList<TPlayerOption>.Create(True);
  FConditions := TList<TCondition>.Create;
  FScripts := TObjectList<TNodeScript>.Create(True);
  FReputation := 0;
  FKarma := -1000;
  FRandomWeight := 1;
  FIsStartNode := False;
end;

destructor TDialogueNode.Destroy;
begin
  FPlayerOptions.Free;
  FConditions.Free;
  FScripts.Free;
  inherited;
end;

function TDialogueNode.ToJSON: TJSONObject;
var
  optArr, condArr, scriptArr: TJSONArray;
  opt: TPlayerOption;
  cond: TCondition;
  sc: TNodeScript;
  condObj, optObj, scObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', FID);
  Result.AddPair('type', IntToStr(Ord(FNodeType)));
  Result.AddPair('text', FText);
  Result.AddPair('speaker', FSpeaker);
  Result.AddPair('portrait', FPortraitFile);
  Result.AddPair('voice', FVoiceFile);
  Result.AddPair('x', TJSONNumber.Create(FX));
  Result.AddPair('y', TJSONNumber.Create(FY));
  Result.AddPair('width', TJSONNumber.Create(FWidth));
  Result.AddPair('height', TJSONNumber.Create(FHeight));
  Result.AddPair('color', TJSONNumber.Create(Integer(FColor)));
  Result.AddPair('comment', FComment);
  Result.AddPair('questId', FQuestID);
  Result.AddPair('questFlag', FQuestFlag);
  Result.AddPair('scriptFile', FScriptFile);
  Result.AddPair('reputation', TJSONNumber.Create(FReputation));
  Result.AddPair('karma', TJSONNumber.Create(FKarma));
  Result.AddPair('tag', FTag);
  Result.AddPair('notes', FNotes);
  Result.AddPair('nextNodeId', FNextNodeID);
  Result.AddPair('isStartNode', TJSONBool.Create(FIsStartNode));
  Result.AddPair('randomWeight', TJSONNumber.Create(FRandomWeight));
  Result.AddPair('combatScript', FCombatScript);
  Result.AddPair('tradeInventory', FTradeInventory);

  // Player options
  optArr := TJSONArray.Create;
  for opt in FPlayerOptions do
  begin
    optObj := TJSONObject.Create;
    optObj.AddPair('id', opt.ID);
    optObj.AddPair('text', opt.Text);
    optObj.AddPair('targetNodeId', opt.TargetNodeID);
    optObj.AddPair('isHidden', TJSONBool.Create(opt.IsHidden));
    optObj.AddPair('hasSkillCheck', TJSONBool.Create(opt.HasSkillCheck));
    optObj.AddPair('scriptOnSelect', opt.ScriptOnSelect);
    optObj.AddPair('reputationRequired', TJSONNumber.Create(opt.ReputationRequired));
    optObj.AddPair('karmaRequired', TJSONNumber.Create(opt.KarmaRequired));
    optObj.AddPair('itemRequired', opt.ItemRequired);
    if opt.HasSkillCheck then
    begin
      var skObj := TJSONObject.Create;
      skObj.AddPair('skill', TJSONNumber.Create(Ord(opt.SkillCheck.Skill)));
      skObj.AddPair('difficulty', TJSONNumber.Create(opt.SkillCheck.Difficulty));
      skObj.AddPair('critBonus', TJSONNumber.Create(opt.SkillCheck.CritSuccessBonus));
      skObj.AddPair('xpReward', TJSONNumber.Create(opt.SkillCheck.XPReward));
      skObj.AddPair('successMsg', opt.SkillCheck.SuccessMessage);
      skObj.AddPair('failMsg', opt.SkillCheck.FailureMessage);
      skObj.AddPair('successNode', opt.SkillCheck.SuccessNodeID);
      skObj.AddPair('failNode', opt.SkillCheck.FailureNodeID);
      optObj.AddPair('skillCheck', skObj);
    end;
    optArr.Add(optObj);
  end;
  Result.AddPair('options', optArr);

  // Conditions
  condArr := TJSONArray.Create;
  for cond in FConditions do
  begin
    condObj := TJSONObject.Create;
    condObj.AddPair('type', TJSONNumber.Create(Ord(cond.CondType)));
    condObj.AddPair('variable', cond.Variable);
    condObj.AddPair('operator', TJSONNumber.Create(Ord(cond.Operator)));
    condObj.AddPair('value', cond.Value);
    condObj.AddPair('boolOp', TJSONNumber.Create(Ord(cond.BoolOp)));
    condArr.Add(condObj);
  end;
  Result.AddPair('conditions', condArr);

  // Scripts
  scriptArr := TJSONArray.Create;
  for sc in FScripts do
  begin
    scObj := TJSONObject.Create;
    scObj.AddPair('event', TJSONNumber.Create(Ord(sc.EventType)));
    scObj.AddPair('code', sc.ScriptCode);
    scObj.AddPair('enabled', TJSONBool.Create(sc.IsEnabled));
    scriptArr.Add(scObj);
  end;
  Result.AddPair('scripts', scriptArr);
end;

procedure TDialogueNode.FromJSON(obj: TJSONObject);
var
  v: TJSONValue;
  arr: TJSONArray;
  optObj, condObj, scObj: TJSONObject;
  opt: TPlayerOption;
  sc: TNodeScript;
  cond: TCondition;
  i: Integer;
begin
  FNodeType := TNodeType(obj.GetValue<Integer>('type'));
  FText := obj.GetValue<string>('text');
  FSpeaker := obj.GetValue<string>('speaker');
  FPortraitFile := obj.GetValue<string>('portrait');
  FVoiceFile := obj.GetValue<string>('voice');
  FX := obj.GetValue<Integer>('x');
  FY := obj.GetValue<Integer>('y');
  FWidth := obj.GetValue<Integer>('width');
  FHeight := obj.GetValue<Integer>('height');
  FColor := TColor(obj.GetValue<Integer>('color'));
  FComment := obj.GetValue<string>('comment');
  FQuestID := obj.GetValue<string>('questId');
  FQuestFlag := obj.GetValue<string>('questFlag');
  FScriptFile := obj.GetValue<string>('scriptFile');
  FReputation := obj.GetValue<Integer>('reputation');
  FKarma := obj.GetValue<Integer>('karma');
  FTag := obj.GetValue<string>('tag');
  FNotes := obj.GetValue<string>('notes');
  FNextNodeID := obj.GetValue<string>('nextNodeId');
  FIsStartNode := obj.GetValue<Boolean>('isStartNode');
  FRandomWeight := obj.GetValue<Integer>('randomWeight');
  FCombatScript := obj.GetValue<string>('combatScript');
  FTradeInventory := obj.GetValue<string>('tradeInventory');

  FPlayerOptions.Clear;
  v := obj.GetValue('options');
  if Assigned(v) and (v is TJSONArray) then
  begin
    arr := TJSONArray(v);
    for i := 0 to arr.Count - 1 do
    begin
      optObj := arr.Items[i] as TJSONObject;
      opt := TPlayerOption.Create;
      opt.ID := optObj.GetValue<string>('id');
      opt.Text := optObj.GetValue<string>('text');
      opt.TargetNodeID := optObj.GetValue<string>('targetNodeId');
      opt.IsHidden := optObj.GetValue<Boolean>('isHidden');
      opt.HasSkillCheck := optObj.GetValue<Boolean>('hasSkillCheck');
      opt.ScriptOnSelect := optObj.GetValue<string>('scriptOnSelect');
      opt.ReputationRequired := optObj.GetValue<Integer>('reputationRequired');
      opt.KarmaRequired := optObj.GetValue<Integer>('karmaRequired');
      opt.ItemRequired := optObj.GetValue<string>('itemRequired');
      if opt.HasSkillCheck then
      begin
        var skObj := optObj.GetValue('skillCheck') as TJSONObject;
        if Assigned(skObj) then
        begin
          opt.SkillCheck.Skill := TSkillType(skObj.GetValue<Integer>('skill'));
          opt.SkillCheck.Difficulty := skObj.GetValue<Integer>('difficulty');
          opt.SkillCheck.CritSuccessBonus := skObj.GetValue<Integer>('critBonus');
          opt.SkillCheck.XPReward := skObj.GetValue<Integer>('xpReward');
          opt.SkillCheck.SuccessMessage := skObj.GetValue<string>('successMsg');
          opt.SkillCheck.FailureMessage := skObj.GetValue<string>('failMsg');
          opt.SkillCheck.SuccessNodeID := skObj.GetValue<string>('successNode');
          opt.SkillCheck.FailureNodeID := skObj.GetValue<string>('failNode');
        end;
      end;
      FPlayerOptions.Add(opt);
    end;
  end;

  FConditions.Clear;
  v := obj.GetValue('conditions');
  if Assigned(v) and (v is TJSONArray) then
  begin
    arr := TJSONArray(v);
    for i := 0 to arr.Count - 1 do
    begin
      condObj := arr.Items[i] as TJSONObject;
      cond.CondType := TConditionType(condObj.GetValue<Integer>('type'));
      cond.Variable := condObj.GetValue<string>('variable');
      cond.Operator := TConditionOperator(condObj.GetValue<Integer>('operator'));
      cond.Value := condObj.GetValue<string>('value');
      cond.BoolOp := TBoolOp(condObj.GetValue<Integer>('boolOp'));
      FConditions.Add(cond);
    end;
  end;

  FScripts.Clear;
  v := obj.GetValue('scripts');
  if Assigned(v) and (v is TJSONArray) then
  begin
    arr := TJSONArray(v);
    for i := 0 to arr.Count - 1 do
    begin
      scObj := arr.Items[i] as TJSONObject;
      sc := TNodeScript.Create;
      sc.EventType := TScriptEvent(scObj.GetValue<Integer>('event'));
      sc.ScriptCode := scObj.GetValue<string>('code');
      sc.IsEnabled := scObj.GetValue<Boolean>('enabled');
      FScripts.Add(sc);
    end;
  end;
end;

{ TFloatMessage }
constructor TFloatMessage.Create;
begin
  inherited;
  ID := GenerateNodeID;
  Priority := 5;
  Weight := 1;
  TimedDuration := 3.0;
  IsAmbient := True;
end;

function TFloatMessage.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', ID);
  Result.AddPair('category', Category);
  Result.AddPair('text', Text);
  Result.AddPair('priority', TJSONNumber.Create(Priority));
  Result.AddPair('weight', TJSONNumber.Create(Weight));
  Result.AddPair('condition', Condition);
  Result.AddPair('timedDuration', TJSONNumber.Create(TimedDuration));
  Result.AddPair('isAmbient', TJSONBool.Create(IsAmbient));
  Result.AddPair('isCombatTaunt', TJSONBool.Create(IsCombatTaunt));
  Result.AddPair('isContextSensitive', TJSONBool.Create(IsContextSensitive));
  Result.AddPair('localeKey', LocaleKey);
end;

procedure TFloatMessage.FromJSON(obj: TJSONObject);
begin
  ID := obj.GetValue<string>('id');
  Category := obj.GetValue<string>('category');
  Text := obj.GetValue<string>('text');
  Priority := obj.GetValue<Integer>('priority');
  Weight := obj.GetValue<Integer>('weight');
  Condition := obj.GetValue<string>('condition');
  TimedDuration := obj.GetValue<Double>('timedDuration');
  IsAmbient := obj.GetValue<Boolean>('isAmbient');
  IsCombatTaunt := obj.GetValue<Boolean>('isCombatTaunt');
  IsContextSensitive := obj.GetValue<Boolean>('isContextSensitive');
  LocaleKey := obj.GetValue<string>('localeKey');
end;

{ TDialogueProject }
constructor TDialogueProject.Create;
begin
  inherited;
  FNodes := TObjectList<TDialogueNode>.Create(True);
  FFloatMessages := TObjectList<TFloatMessage>.Create(True);
  FGlobalVars := TDictionary<string, string>.Create;
  FTags := TStringList.Create;
  FLocales := TStringList.Create;
  FLocales.Add('en-US');
  FActiveLocale := 'en-US';
   FName := 'New Dialogue';
   FVersion := '1.0.6';
   FAuthor := '';
  FCreatedDate := Now;
  FModifiedDate := Now;
  FModified := False;
end;

destructor TDialogueProject.Destroy;
begin
  FNodes.Free;
  FFloatMessages.Free;
  FGlobalVars.Free;
  FTags.Free;
  FLocales.Free;
  inherited;
end;

function TDialogueProject.AddNode(aType: TNodeType): TDialogueNode;
begin
  Result := TDialogueNode.Create(GenerateNodeID, aType);
  if FNodes.Count = 0 then
    Result.IsStartNode := True;
  FNodes.Add(Result);
  FModified := True;
end;

procedure TDialogueProject.RemoveNode(const aID: string);
var
  i: Integer;
begin
  for i := FNodes.Count - 1 downto 0 do
    if FNodes[i].ID = aID then
    begin
      FNodes.Delete(i);
      FModified := True;
      Exit;
    end;
end;

function TDialogueProject.FindNode(const aID: string): TDialogueNode;
var
  node: TDialogueNode;
begin
  Result := nil;
  for node in FNodes do
    if node.ID = aID then
    begin
      Result := node;
      Exit;
    end;
end;

function TDialogueProject.GetConnectedNodes(const aNodeID: string): TList<TDialogueNode>;
var
  node, target: TDialogueNode;
  opt: TPlayerOption;
begin
  Result := TList<TDialogueNode>.Create;
  node := FindNode(aNodeID);
  if not Assigned(node) then Exit;

  if node.NextNodeID <> '' then
  begin
    target := FindNode(node.NextNodeID);
    if Assigned(target) then Result.Add(target);
  end;

  for opt in node.PlayerOptions do
  begin
    if opt.TargetNodeID <> '' then
    begin
      target := FindNode(opt.TargetNodeID);
      if Assigned(target) and not Result.Contains(target) then
        Result.Add(target);
    end;
    if opt.HasSkillCheck then
    begin
      if opt.SkillCheck.SuccessNodeID <> '' then
      begin
        target := FindNode(opt.SkillCheck.SuccessNodeID);
        if Assigned(target) and not Result.Contains(target) then
          Result.Add(target);
      end;
      if opt.SkillCheck.FailureNodeID <> '' then
      begin
        target := FindNode(opt.SkillCheck.FailureNodeID);
        if Assigned(target) and not Result.Contains(target) then
          Result.Add(target);
      end;
    end;
  end;
end;

function TDialogueProject.ToJSON: TJSONObject;
var
  nodeArr, msgArr, varArr: TJSONArray;
  node: TDialogueNode;
  msg: TFloatMessage;
  pair: TPair<string, string>;
  varObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', FName);
  Result.AddPair('npcName', FNPCName);
  Result.AddPair('npcScript', FNPCScript);
  Result.AddPair('description', FDescription);
  Result.AddPair('version', FVersion);
  Result.AddPair('author', FAuthor);
  Result.AddPair('startNodeId', FStartNodeID);
  Result.AddPair('createdDate', DateTimeToStr(FCreatedDate));
  Result.AddPair('modifiedDate', DateTimeToStr(Now));
  Result.AddPair('activeLocale', FActiveLocale);
  Result.AddPair('locales', string.Join(',', FLocales.ToStringArray));
  Result.AddPair('tags', FTags.CommaText);

  nodeArr := TJSONArray.Create;
  for node in FNodes do
    nodeArr.Add(node.ToJSON);
  Result.AddPair('nodes', nodeArr);

  msgArr := TJSONArray.Create;
  for msg in FFloatMessages do
    msgArr.Add(msg.ToJSON);
  Result.AddPair('floatMessages', msgArr);

  varArr := TJSONArray.Create;
  for pair in FGlobalVars do
  begin
    varObj := TJSONObject.Create;
    varObj.AddPair('key', pair.Key);
    varObj.AddPair('value', pair.Value);
    varArr.Add(varObj);
  end;
  Result.AddPair('globalVars', varArr);
end;

procedure TDialogueProject.FromJSON(obj: TJSONObject);
var
  arr: TJSONArray;
  i: Integer;
  node: TDialogueNode;
  msg: TFloatMessage;
  nodeObj, varObj: TJSONObject;
  v: TJSONValue;
begin
  FName := obj.GetValue<string>('name');
  FNPCName := obj.GetValue<string>('npcName');
  FNPCScript := obj.GetValue<string>('npcScript');
  FDescription := obj.GetValue<string>('description');
  FVersion := obj.GetValue<string>('version');
  FAuthor := obj.GetValue<string>('author');
  FStartNodeID := obj.GetValue<string>('startNodeId');
  FActiveLocale := obj.GetValue<string>('activeLocale');

try
     var d := obj.GetValue<string>('createdDate');
     d := StringReplace(d, ' ', 'T', [rfReplaceAll]);
     FCreatedDate := ISO8601ToDate(d, False);
   except
     FCreatedDate := Now;
   end;
   try
     var d := obj.GetValue<string>('modifiedDate');
     d := StringReplace(d, ' ', 'T', [rfReplaceAll]);
     FModifiedDate := ISO8601ToDate(d, False);
   except
     FModifiedDate := Now;
   end;

  var locStr := obj.GetValue<string>('locales');
  FLocales.Clear;
  FLocales.CommaText := locStr;

  var tagStr := obj.GetValue<string>('tags');
  FTags.CommaText := tagStr;

  FNodes.Clear;
  v := obj.GetValue('nodes');
  if Assigned(v) and (v is TJSONArray) then
  begin
    arr := TJSONArray(v);
    for i := 0 to arr.Count - 1 do
    begin
      nodeObj := arr.Items[i] as TJSONObject;
      node := TDialogueNode.Create(nodeObj.GetValue<string>('id'),
        TNodeType(nodeObj.GetValue<Integer>('type')));
      node.FromJSON(nodeObj);
      FNodes.Add(node);
    end;
  end;

  FFloatMessages.Clear;
  v := obj.GetValue('floatMessages');
  if Assigned(v) and (v is TJSONArray) then
  begin
    arr := TJSONArray(v);
    for i := 0 to arr.Count - 1 do
    begin
      msg := TFloatMessage.Create;
      msg.FromJSON(arr.Items[i] as TJSONObject);
      FFloatMessages.Add(msg);
    end;
  end;

  FGlobalVars.Clear;
  v := obj.GetValue('globalVars');
  if Assigned(v) and (v is TJSONArray) then
  begin
    arr := TJSONArray(v);
    for i := 0 to arr.Count - 1 do
    begin
      varObj := arr.Items[i] as TJSONObject;
      FGlobalVars.Add(varObj.GetValue<string>('key'), varObj.GetValue<string>('value'));
    end;
  end;
end;

function TDialogueProject.SaveToFile(const aPath: string): Boolean;
var
  jsonObj: TJSONObject;
  sl: TStringList;
begin
  Result := False;
  jsonObj := ToJSON;
  try
    sl := TStringList.Create;
    try
      sl.Text := jsonObj.Format(2);
      sl.SaveToFile(aPath, TEncoding.UTF8);
      FFilePath := aPath;
      FModified := False;
      FModifiedDate := Now;
      Result := True;
    finally
      sl.Free;
    end;
  finally
    jsonObj.Free;
  end;
end;

function TDialogueProject.LoadFromFile(const aPath: string): Boolean;
var
  sl: TStringList;
  jsonObj: TJSONObject;
begin
  Result := False;
  if not FileExists(aPath) then Exit;
  sl := TStringList.Create;
  try
    sl.LoadFromFile(aPath, TEncoding.UTF8);
    jsonObj := TJSONObject.ParseJSONValue(sl.Text) as TJSONObject;
    if Assigned(jsonObj) then
    try
      FromJSON(jsonObj);
      FFilePath := aPath;
      FModified := False;
      Result := True;
    finally
      jsonObj.Free;
    end;
  finally
    sl.Free;
  end;
end;

function TDialogueProject.ValidateProject: TStringList;
var
   node: TDialogueNode;
   opt: TPlayerOption;
   seenIDs: TStringList;
   issues: TStringList;
 begin
   seenIDs := TStringList.Create;
   issues := nil;
   try
     issues := TStringList.Create;

     // Check for start node
     if FStartNodeID = '' then
       issues.Add('WARNING: No start node defined');

     // Check each node
     for node in FNodes do
     begin
       // Duplicate ID check
       if seenIDs.IndexOf(node.ID) >= 0 then
         issues.Add('ERROR: Duplicate node ID: ' + node.ID)
       else
         seenIDs.Add(node.ID);

       // Empty text check
       if (node.NodeType in [ntNPCDialogue, ntPlayerReply]) and (Trim(node.Text) = '') then
         issues.Add('WARNING: Node ' + node.ID + ' has no text');

       // Broken links in options
       for opt in node.PlayerOptions do
       begin
         if (opt.TargetNodeID <> '') and not Assigned(FindNode(opt.TargetNodeID)) then
           issues.Add('ERROR: Node ' + node.ID + ' option links to missing node: ' + opt.TargetNodeID);
         if opt.HasSkillCheck then
         begin
           if (opt.SkillCheck.SuccessNodeID <> '') and not Assigned(FindNode(opt.SkillCheck.SuccessNodeID)) then
             issues.Add('ERROR: Skill check success node missing in ' + node.ID);
           if (opt.SkillCheck.FailureNodeID <> '') and not Assigned(FindNode(opt.SkillCheck.FailureNodeID)) then
             issues.Add('ERROR: Skill check failure node missing in ' + node.ID);
         end;
       end;

       // Broken next node link
       if (node.NextNodeID <> '') and not Assigned(FindNode(node.NextNodeID)) then
         issues.Add('ERROR: Node ' + node.ID + ' next node missing: ' + node.NextNodeID);
     end;

     // Check start node exists
     if (FStartNodeID <> '') and not Assigned(FindNode(FStartNodeID)) then
       issues.Add('ERROR: Start node ID refers to missing node: ' + FStartNodeID);

     Result := issues;
     issues := nil;
   finally
     seenIDs.Free;
     issues.Free;
   end;
 end;

end.
