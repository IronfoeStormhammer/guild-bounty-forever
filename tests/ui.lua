-- Structural smoke test. This mock does not claim to render Blizzard artwork.
local G={};local count=0;local scenario=arg[1] or 'init-failure';local scripts={};local frameNames={}
local methods={};local focus=nil;local cursor=nil;local delegated=0
local function fire(self,event,...) if self.scripts[event] then self.scripts[event](self,...) end;for _,fn in ipairs(self.hooks[event] or {}) do fn(self,...) end end
local function frame(kind,name,parent,template)
    local f=setmetatable({kind=kind,name=name,parent=parent,template=template,shown=true,text='',hooks={},scripts={},w=100,h=20,children={}},{__index=methods})
    if name then _G[name]=f;frameNames[name]=f end
    if parent then parent.children[#parent.children+1]=f end
    if template=='ButtonFrameTemplate' then f.CloseButton=frame('Button',nil,f);f.Inset=frame('Frame',nil,f);f.TitleText=frame('FontString',nil,f) end
    if template=='MinimalScrollBar' then
        f.Init=function() if scenario=='init-failure' then error('simulated native scrollbar Init failure') end end
        f.RegisterCallback=function() end
    end
    if kind=='DropdownButton' then
        f.Text=frame('FontString',nil,f)
        f.SetupMenu=function(self,generator) self.generator=generator;self:GenerateMenu() end
        f.GenerateMenu=function(self) self.optionsMenu={};local root={SetScrollMode=function() end,CreateRadio=function(_,label,selected,callback) self.optionsMenu[#self.optionsMenu+1]={label=label,selected=selected,callback=callback} end};if self.generator then self.generator(self,root) end end
    end
    if kind=='ItemButton' then f.icon=frame('Texture',nil,f) end
    if template=='PanelTabButtonTemplate' then f.Text=frame('FontString',nil,f);f.Left=frame('Texture',nil,f);f.Right=frame('Texture',nil,f) end
    return f
end
for _,n in ipairs({'SetNormalTexture','SetPushedTexture','SetPoint','ClearAllPoints','SetClampedToScreen','SetMovable','EnableMouse','RegisterForDrag','SetFrameStrata','SetAutoFocus','SetMaxLetters','ClearFocus','SetFocus','SetJustifyH','SetJustifyV','SetSpacing','SetTexture','SetColorTexture','SetAllPoints','SetBlendMode','SetAlpha','SetHighlightTexture','EnableMouseWheel','SetScrollChild','SetFrameLevel','StartMoving','StopMovingOrSizing','SetResizeToFit','SetAltArrowKeyMode','SetFontObject','SetTextInsets','SetCursorPosition','RegisterEvent','SetWordWrap','RegisterForClicks','LockHighlight','UnlockHighlight'}) do methods[n]=function() end end
function methods:SetTexture(value) self.texture=value end
function methods:SetPoint(...) self.point={...} end
function methods:LockHighlight() self.highlighted=true end
function methods:UnlockHighlight() self.highlighted=false end
function methods:SetSize(w,h) self.w=w;self.h=h end
function methods:SetWidth(w) self.w=w end
function methods:SetHeight(h) self.h=h end
function methods:GetHeight() return self.h end
function methods:GetWidth() return self.w end
function methods:GetPoint() return 'CENTER',UIParent,'CENTER',0,0 end
function methods:CreateFontString(...) return frame('FontString',nil,self) end
function methods:CreateTexture(...) return frame('Texture',nil,self) end
function methods:SetText(s) self.text=s or '';fire(self,'OnTextChanged',false) end
function methods:GetText() return self.text end
function methods:GetStringHeight() local n=1;for _ in self.text:gmatch('\n') do n=n+1 end return n*14 end
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:HookScript(name,fn) if scenario=='hook-failure' and name=='OnScrollRangeChanged' then error('simulated unavailable native scroll script') end;self.hooks[name]=self.hooks[name] or {};table.insert(self.hooks[name],fn) end
function methods:Show() local old=self.shown;self.shown=true;if not old then fire(self,'OnShow') end end
function methods:Hide() local old=self.shown;self.shown=false;if old then fire(self,'OnHide') end end
function methods:IsShown() return self.shown end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:SetEnabled(v) self.enabled=v end
function methods:Enable() self.enabled=true end
function methods:Disable() self.enabled=false end
function methods:SetID(v) self.id=v end
function methods:GetID() return self.id end
function methods:SetVerticalScroll(v) self.scroll=v end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:GetVerticalScrollRange() return 0 end
function methods:HasFocus() return focus==self end
function methods:SetFocus() if focus and focus~=self then focus:ClearFocus() end;focus=self;fire(self,'OnEditFocusGained') end
function methods:ClearFocus() if focus==self then focus=nil;fire(self,'OnEditFocusLost') end end
function methods:EnableKeyboard(v) self.keyboard=v end
function methods:EnableMouse(v) self.mouse=v end
function methods:GetFrameLevel() return self.frameLevel or 1 end
function methods:SetFrameLevel(v) self.frameLevel=v end
function methods:SetButtonState(v,locked) self.buttonState=v;self.locked=locked end

CreateFrame=frame;UIParent=frame('Frame');UISpecialFrames={};StaticPopupDialogs={};ACCEPT='Accept';CANCEL='Cancel'
local soundCount=0;SOUNDKIT={IG_QUEST_LOG_OPEN=123};PlaySound=function() soundCount=soundCount+1 end
StaticPopup_Show=function(name) return StaticPopupDialogs[name] end;StaticPopup_Hide=function(name) if StaticPopupDialogs[name] and StaticPopupDialogs[name].OnHide then StaticPopupDialogs[name].OnHide() end end
GetCoinTextureString=nil;C_CurrencyInfo={GetCoinTextureString=function(n) return n..' copper' end}
Constants={CharacterNameSeparatorConsts={CHARACTERNAME_SURNAME_SEPARATOR=' '}};UnitNameUnmodified=function() return 'Alice','Ironforge' end;UnitGUID=function() return 'Player-1-Alice' end
Enum={GameRule={PvPRuleset=1,RPRuleset=2}};C_GameRules={IsGameRuleActive=function() return false end};GetCurrentRegion=function() return 3 end
GetServerTime=function() return 1800000000 end;GetGuildInfo=function() return 'Guild' end;GetRealZoneText=function() return 'Zone' end;IsInGuild=function() return true end
GetNumGuildMembers=function() return 0 end
C_Item={GetItemClassInfo=function(id) return ({[0]='Consumable',[2]='Weapon',[4]='Armor',[7]='Trade Goods'})[id] end,GetItemSubClassInfo=function(id,sub) return (({[2]={[7]='Sword',[1]='Axe'},[4]={[1]='Cloth',[4]='Plate'}})[id] or {})[sub] end,GetItemInfo=function(id) id=tonumber(tostring(id):match('item:(%d+)')) or tonumber(id);if id==123 then return 'Sword','|cff1eff00|Hitem:123::::::::|h[Sword]|h|r',2,30,20,'Weapon','Sword',1,'INVTYPE_WEAPON',135328,0,2,7 end end}
GameTooltip={Hide=function() end,SetOwner=function() end,SetHyperlink=function() end,Show=function() end};date=os.date
GetCursorInfo=function() if cursor then return unpack(cursor) end end;ClearCursor=function() cursor=nil end
GetCurrentKeyBoardFocus=function() return focus end
ChatFrameUtil={InsertLink=function() delegated=delegated+1;return false end};ChatEdit_InsertLink=ChatFrameUtil.InsertLink
function hooksecurefunc(object,key,callback)
    if type(object)=='string' then callback=key;key=object;object=_G end
    local original=object[key];object[key]=function(...) local result=original(...);callback(...);return result end
end
PanelTemplates_TabResize=function() end;PanelTemplates_SetTab=function() end
for _,n in ipairs({'Util','Codec','Identity','Migration','History','Models','Database','Sync','Items','Form','Claims','Notifications','Loot','PvP','Mail','Native','Support','UI','Tutorial'}) do assert(loadfile('GuildBountyForever/'..n..'.lua'))('GuildBountyForever',G) end
assert(G.People.RefreshPlayer());assert(G.InitDB());G.root.prefs.tutorial={version=G.Tutorial.version,step=#G.Tutorial.pages,completed=true};G.UI.Toggle();assert(G.UI.frame:IsShown())
local function check(v,s) count=count+1;assert(v,s) end
local function save() G.UI.SaveEditor();local popup=StaticPopupDialogs.GBF_CONFIRM;if G.UI.pendingSave and popup then popup.OnAccept() end end
check(G.UI.ready and G.UI.error and G.UI.detailText and #G.UI.frame.Tabs==4,'window is fully built despite optional scrollbar failure');check(scenario=='healthy' or G.scrollbarError~=nil,'scrollbar fault isolated and diagnosed');check(G.Money(1900)=='1900 copper','namespaced money API with missing legacy global');
check(#G.UI.rows==8,'dense rows');check(#G.UI.actions==4,'actions')
G.UI.Editor();local e=G.UI.editor;e.item:SetText('123');e.quantity:SetText('2');e.gold:SetText('5');save();check(not e:IsShown(),'save item')
local req;for _,o in pairs(G.db.objects) do if o.kind=='request' then req=o end end;check(req and req.itemID==123,'item fields');check(G.UI.rows[1].title:GetText():find('Sword'),'quality item link')
G.UI.Editor();e.mode=2;G.UI.EditorFields();e.class:SetValue('2');e.slot:SetValue('INVTYPE_WEAPON');save();check(not e:IsShown(),'rule form saves')
G.UI.Editor();e.mode=3;G.UI.EditorFields();e.target:SetText('Enemy Other');save();check(not e:IsShown(),'pvp saves')
for i=1,4 do G.UI.tab=i;G.UI.Refresh() end
G.UI.tab=3;G.UI.Refresh();check(G.UI.filterButton:IsShown(),'mine filter')
G.UI.Editor(req);e.note:SetText('Edited note');save();check(G.db.objects[req.id].note=='Edited note','editor revision')
local claim=assert(G.Accept(G.db.objects[req.id],nil,1));claim=assert(G.Submit(claim));G.UI.selected=claim.id;G.UI.Refresh();check(G.UI.actions[1]:IsShown(),'review action')
local before=0;for _ in pairs(G.db.history) do before=before+1 end
for i=1,20 do G.UI.Refresh() end
local after=0;for _ in pairs(G.db.history) do after=after+1 end;check(before==after,'browsing creates no history')
G.offers={{object=req.id,quantity=1,evidence={at=1800000000}}};G.UI.ShowOffer();check(G.UI.offer:IsShown(),'match prompt')
-- Regression cases wire the actual handlers. This remains a mock, not a keyboard simulator.
G.UI.Editor();e=G.UI.editor
check(#e.modeButtons==3,'three direct selectors')
for i=1,3 do e.modeButtons[i].scripts.OnClick();check(e.mode==i and e.modeButtons[i].buttonState=='PUSHED','direct mode '..i) end
check(e.target.mouse and e.target.keyboard and e.target.enabled,'explicit native input enabled')
check(e.target.scripts.OnMouseDown and e.target.scripts.OnEnterPressed and e.target.scripts.OnEscapePressed,'focus handlers')
e.target.scripts.OnMouseDown(e.target,'LeftButton');check(e.target:HasFocus(),'target click focus')
e.target:SetText('Ironfoe Stormhammer');check(e.target:GetText()=='Ironfoe Stormhammer','two-part input retained')
e.target.scripts.OnEnterPressed(e.target);check(not e.target:HasFocus(),'enter clears focus')
e.target:SetFocus();e.target.scripts.OnEscapePressed(e.target);check(not e.target:HasFocus(),'escape clears focus')
check(not e.target.scripts.OnKeyDown,'native editing keys are not intercepted')
G.UI.SetMode(1);e.item:SetFocus()
local link='|cff1eff00|Hitem:123::::::::|h[Sword]|h|r'
local before=delegated;check(not ChatFrameUtil.InsertLink(link),'native return preserved');check(delegated==before+1 and e.resolvedItem.id==123,'secure post-hook preview resolved')
check(not ChatEdit_InsertLink(link),'legacy native return preserved')
local other=CreateFrame('EditBox');other:SetFocus();check(not ChatFrameUtil.InsertLink(link) and delegated==before+3,'other edit box delegates')
G.UI.SetMode(3);e.target:SetFocus();check(not ChatFrameUtil.InsertLink(link),'pvp mode cannot consume item link')
G.UI.SetMode(1);cursor={'item',123,link};e.itemSlot.scripts.OnReceiveDrag();check(cursor==nil and e.resolvedItem.id==123,'item slot drop')
cursor={'item',123,link};e.item.scripts.OnMouseUp(e.item,'LeftButton');check(cursor==nil,'click-to-place cursor item')
cursor={'spell',123};check(not G.UI.DropItem() and cursor~=nil,'non-item cursor untouched');cursor=nil
e.item:SetText('999999');e.saveButton.scripts.OnClick();check(e:IsShown() and G.UI.error:GetText()~='','uncached item save blocked')
e.item:SetText('not an item');e.saveButton.scripts.OnClick();check(e:IsShown(),'invalid item save blocked')
local function totals() local n,h=0,0;for _ in pairs(G.db.objects) do n=n+1 end;for _ in pairs(G.db.history) do h=h+1 end;return n,h end
local objects,history=totals();e.cancelButton.scripts.OnClick();local objects2,history2=totals();check(objects==objects2 and history==history2,'cancel has no data/history side effects')
G.UI.Editor();e.item:SetText('123');G.UI.SetMode(3);e.target:SetText('Ironfoe Stormhammer');e.targetInfo={name='Ironfoe Stormhammer',guid='Player-2-Ironfoe',source='target',ruleset='PvE'};G.UI.SetMode(1);check(not e.targetInfo,'switch clears captured target identity')
G.UI.SetMode(2);e.class:SetValue('2');e.slot:SetValue('INVTYPE_2HWEAPON');e.gold:SetText('7');e.note:SetText('Carry this note');G.UI.SetMode(3);check(e.gold:GetText()=='7' and e.note:GetText()=='Carry this note','common fields retained')
e.target:SetText('Ironfoe Stormhammer');e.saveButton.scripts.OnClick();if G.UI.pendingSave then StaticPopupDialogs.GBF_CONFIRM.OnAccept() end;local saved
for _,o in pairs(G.db.objects) do if o.kind=='pvp' and o.target.name=='Ironfoe Stormhammer' then saved=o end end
check(saved and not saved.itemID and not saved.rules and not saved.target.guid,'mode fields isolated')
for _,key in ipairs({'quantity','gold','silver','copper','note','required'}) do check(e[key].mouse and e[key].keyboard and e[key].scripts.OnMouseDown,'input configuration '..key) end
-- Save confirmation is transactional; success selects the exact new object and plays once.
G.UI.Editor();e=G.UI.editor;G.UI.SetMode(1);e.item:SetText('123');e.quantity:SetText('3');e.gold:SetText('2')
local preObjects,preHistory=totals();local preSound=soundCount;e.saveButton.scripts.OnClick();local postObjects,postHistory=totals()
check(G.UI.pendingSave and preObjects==postObjects and preHistory==postHistory,'save waits for confirmation without writes')
StaticPopupDialogs.GBF_CONFIRM.OnCancel();check(e:IsShown() and not G.UI.pendingSave and soundCount==preSound,'cancel confirmation retains draft without success sound')
e.saveButton.scripts.OnClick();local confirm=StaticPopupDialogs.GBF_CONFIRM;confirm.OnAccept();confirm.OnAccept()
check(not e:IsShown() and G.UI.board:IsShown() and G.UI.detail:IsShown(),'confirmed save returns to board')
check(soundCount==preSound+1,'success sound exactly once')
local selected=G.db.objects[G.UI.selected];check(selected and selected.quantity==3,'saved object selected')
check(G.UI.detailText:GetText():find('Remaining: 3 / 3',1,true),'details shows saved quantity')
check(G.UI.detailText:GetText():find('Reward promise:',1,true),'details shows reward')
local chosenRow
for _,row in ipairs(G.UI.rows) do if row.object and row.object.id==selected.id then chosenRow=row end end
check(chosenRow~=nil,'new object is visible even when timestamps tie')
chosenRow.action.scripts.OnClick();check(G.UI.selected==selected.id and G.UI.detailText:GetText()~='','actual Details click renders text')
G.UI.Editor();for i=1,3 do e.modeButtons[i].scripts.OnClick();check(e.mode==i,'actual type button changes mode '..i) end;G.UI.CancelEditor()
for i,tab in ipairs(G.UI.frame.Tabs) do
    tab.scripts.OnClick();check(G.UI.tab==i and tab.highlighted,'footer selects board '..i)
    check(tab.point[3]==-634 and -tab.point[3]+tab.h<G.UI.frame.h,'footer stays inside window '..i)
    for j,other in ipairs(G.UI.frame.Tabs) do check(other.highlighted==(i==j),'single footer selection') end
end
G.UI.Editor();G.UI.SetMode(2)
local function choose(control,label)
    control:GenerateMenu();for _,option in ipairs(control.optionsMenu) do if option.label==label then option.callback();return end end;error('missing menu option '..label)
end
choose(e.class,'Weapon');choose(e.subclass,'Sword');check(e.class:GetValue()=='2' and e.subclass:GetValue()=='7','named menus select stable criteria')
choose(e.class,'Armor');check(e.subclass:GetValue()=='' and e.subclass.Text:GetText()=='Any subtype','changing type resets subtype')
choose(e.subclass,'Plate');choose(e.slot,'Two-Hand');e.gold:SetText('1');save()
local rule=G.db.objects[G.UI.selected];check(rule.rules.classID==4 and rule.rules.subclassID==4 and rule.rules.slot=='INVTYPE_2HWEAPON','dropdown save preserves criteria')
G.UI.Editor(rule);check(e.class.Text:GetText()=='Armor' and e.subclass.Text:GetText()=='Plate' and e.slot.Text:GetText()=='Two-Hand','editing restores dropdown labels and subtype in order')
check(G.Items.Label(rule):find('Armor',1,true) and G.Items.Label(rule):find('Plate',1,true),'board uses readable rule names')
choose(e.class,'Any item type');check(e.subclass:GetValue()=='' and not e.subclass.enabled,'any type clears and disables subtype');G.UI.CancelEditor()
G.UI.Editor();G.UI.SetMode(2)
check(not e.item:IsShown() and not e.item.caption:IsShown(),'rule mode has no item ID requirement or sample control')
check(e.level==nil and e.maxLevel==nil,'item-level controls removed')
e.required:SetText('10');e.maxRequired:SetText('40');choose(e.stat,'Strength');e.statMin:SetText('10');e.statMax:SetText('25')
local beforeApply=soundCount;e.statApply.scripts.OnClick()
check(soundCount==beforeApply+1 and e.statRows[1].key=='ITEM_MOD_STRENGTH_SHORT' and e.statRows[1].text:GetText():find('[Locked]',1,true),'apply creates locked row and confirms with sound')
check(e.stat:GetValue()=='' and e.statMin:GetText()=='' and e.statMax:GetText()=='','fresh blank stat entry after apply')
choose(e.stat,'Stamina');e.statMin:SetText('8');e.saveButton.scripts.OnClick();check(not G.UI.pendingSave and G.UI.error:GetText():find('Apply',1,true),'unfinished stat must be applied before save')
e.statApply.scripts.OnClick();check(e.statRows[2].key=='ITEM_MOD_STAMINA_SHORT','second stat receives a separate row');save()
local statRule=G.db.objects[G.UI.selected]
check(statRule and not statRule.rules.minLevel and not statRule.rules.maxLevel and statRule.rules.minRequired==10 and statRule.rules.maxRequired==40 and statRule.rules.stats.ITEM_MOD_STRENGTH_SHORT.min==10 and statRule.rules.stats.ITEM_MOD_STAMINA_SHORT.min==8,'save character levels and multiple locked stats without item levels')
G.UI.Editor(statRule);local strengthRow
for _,row in ipairs(e.statRows) do if row.key=='ITEM_MOD_STRENGTH_SHORT' then strengthRow=row end end
strengthRow.edit.scripts.OnClick();check(e.stat:GetValue()=='ITEM_MOD_STRENGTH_SHORT' and e.statMin:GetText()=='10' and e.statMax:GetText()=='25','explicit Edit restores stat bounds')
e.statMin:SetText('12');e.statApply.scripts.OnClick();check(e.statRules.ITEM_MOD_STRENGTH_SHORT.min==12 and e.statRules.ITEM_MOD_STAMINA_SHORT.min==8,'editing preserves other locked stats')
for _,row in ipairs(e.statRows) do if row.key=='ITEM_MOD_STRENGTH_SHORT' then row.remove.scripts.OnClick();break end end
check(not e.statRules.ITEM_MOD_STRENGTH_SHORT and e.statRules.ITEM_MOD_STAMINA_SHORT,'row Remove affects only selected stat');G.UI.CancelEditor()
G.UI.Editor();G.UI.SetMode(2)
for _,label in ipairs({'Strength','Stamina','Agility','Intellect'}) do choose(e.stat,label);e.statMin:SetText('5');e.statApply.scripts.OnClick() end
check(#e.statOrder==4 and e.statRules.ITEM_MOD_STRENGTH_SHORT and e.statRules.ITEM_MOD_INTELLECT_SHORT,'more than three stats remain retained')
e.statPrevious.scripts.OnClick();check(e.statRows[1].key=='ITEM_MOD_STRENGTH_SHORT','previous page reveals earlier stats');e.statNext.scripts.OnClick();check(e.statRows[3].key=='ITEM_MOD_INTELLECT_SHORT','next page reveals additional stats')
local appliedSound=soundCount;choose(e.stat,'Spirit');e.statMin:SetText('20');e.statMax:SetText('10');e.statApply.scripts.OnClick();check(soundCount==appliedSound and not e.statRules.ITEM_MOD_SPIRIT_SHORT,'invalid stat is not locked or confirmed');G.UI.CancelEditor()
local noDate=date;date=nil;check(G.Date('%d %b',1800000000)~='','date formatting has a compatibility fallback');date=noDate
local oldRefresh=G.UI.Refresh;G.UI.Refresh=function() error('simulated display error') end
local oldObjects=totals();local rendered=G.Create('request',{itemID=123,title='Successful write',quantity=1,reward=0});check(rendered and G.db.objects[rendered.id],'data commit survives UI callback failure');G.UI.Refresh=oldRefresh
-- Bootstrap wiring: delayed hello, target/item events, guild arrival and diagnostics.
local timers={};C_Timer={After=function(delay,fn) timers[#timers+1]={delay=delay,fn=fn} end};SlashCmdList={};C_ChatInfo={RegisterAddonMessagePrefix=function() return true end}
GetBuildInfo=function() return '1.60.1','70707','date',16001 end
local chats={};DEFAULT_CHAT_FRAME={AddMessage=function(_,text) chats[#chats+1]=text end}
assert(loadfile('GuildBountyForever/Debug.lua'))('GuildBountyForever',G)
assert(loadfile('GuildBountyForever/Bootstrap.lua'))('GuildBountyForever',G)
G.events.scripts.OnEvent(G.events,'ADDON_LOADED','GuildBountyForever');G.events.scripts.OnEvent(G.events,'PLAYER_LOGIN')
check(type(SlashCmdList.GUILDBOUNTYFOREVER)=='function' and G.events.scripts.OnUpdate~=nil,'bootstrap initialized')
check(#timers>0 and timers[#timers].delay==7,'initial hello delayed')
G.events.scripts.OnEvent(G.events,'GET_ITEM_INFO_RECEIVED',123,true);check(G.UI.ItemPreview~=nil,'item cache event wiring')
SlashCmdList.GUILDBOUNTYFOREVER('debug');SlashCmdList.GUILDBOUNTYFOREVER('debug identity');SlashCmdList.GUILDBOUNTYFOREVER('debug item 123');SlashCmdList.GUILDBOUNTYFOREVER('debug records');SlashCmdList.GUILDBOUNTYFOREVER('status');check(#chats>=5,'read-only diagnostics')
local guildPresent=false;IsInGuild=function() return guildPresent end;GetGuildInfo=function() return guildPresent and 'Guild' or nil end
G.events.scripts.OnEvent(G.events,'PLAYER_GUILD_UPDATE');local localContext=G.guildKey;guildPresent=true;G.events.scripts.OnEvent(G.events,'GUILD_ROSTER_UPDATE');check(G.guildKey~=localContext and timers[#timers].delay==2,'guild arrival auto sync scheduled')
G.events.scripts.OnEvent(G.events,'ADDON_ACTION_FORBIDDEN','GuildBountyForever','TestProtectedAction()');check(G.security.action=='TestProtectedAction()' and G.root.prefs.lastSecurity==G.security,'security action persisted for diagnosis')
check(not G.PvP.Available(),'missing combat getter disables restricted registration')
-- Loot offer opens a delivery workflow rather than silently creating a claim.
local supplierMe,supplierPlayer=G.me,G.player;G.me='Player-2-Buyer';G.player={name='Buyer Other',guid=G.me,ruleset='PvE',region=3}
local delivery=assert(G.Create('request',{title='Sword delivery',itemID=123,quantity=5,reward=20000,note='Meet in town'}))
G.me,G.player=supplierMe,supplierPlayer
G.offers={{object=delivery.id,quantity=2,evidence={itemID=123,link=link,at=1800000000,method='self loot'}}};G.UI.ShowOffer()
check(G.UI.offer:IsShown() and G.UI.offer.primary:GetText()=='Arrange delivery','foreign bounty prompts delivery')
check(G.UI.offer.text:GetText():find('Still needed: 5 / 5',1,true) and G.UI.offer.text:GetText():find('Meet in town',1,true),'offer shows quantity and bounty note')
G.UI.offer.primary.scripts.OnClick();local qty=StaticPopupDialogs.GBF_QUANTITY
local qtyBox=CreateFrame('EditBox');qty.OnShow({EditBox=qtyBox});check(qtyBox:GetText()=='2','delivery defaults to found quantity')
qty.OnAccept({EditBox=qtyBox});local deliveryClaim=G.db.objects[G.UI.selected]
check(deliveryClaim and deliveryClaim.kind=='claim' and deliveryClaim.parent==delivery.id and deliveryClaim.quantity==2 and G.UI.tab==3,'delivery opens exact retained claim')
check(#G.offers==0 and not G.UI.offer:IsShown(),'accepted match is removed')
check(G.UI.cod:IsShown() and G.UI.cod.gold:GetText()=='0' and G.UI.cod.silver:GetText()=='80','delivery opens editable proportional COD amount')
G.UI.cod:Hide()
local function action(label) for _,button in ipairs(G.UI.actions) do if button:IsShown() and button:GetText()==label then return button end end;error('missing action '..label) end
local whisper;ChatFrameUtil.SendTellWithMessage=function(name,message) whisper={name=name,message=message} end
action('Contact requester').scripts.OnClick();check(whisper and whisper.name=='Buyer Other' and whisper.message:find('delivery and payment',1,true),'contact opens addressed delivery draft')
action('Submit for review').scripts.OnClick();check(G.db.objects[deliveryClaim.id].state=='accepted','submit requires explicit confirmation');StaticPopupDialogs.GBF_CONFIRM.OnAccept()
check(G.db.objects[deliveryClaim.id].state=='submitted' and G.UI.detailText:GetText():find('Manual delivery submitted',1,true),'supplier enters delivery/payment review')
local currentMe=G.me;G.me=delivery.owner;G.UI.OpenRecord(G.db.objects[deliveryClaim.id]);action('Record paid').scripts.OnClick();StaticPopupDialogs.GBF_CONFIRM.OnAccept()
check(G.ClaimState(G.db.objects[deliveryClaim.id])=='paid' and G.Remaining(G.db.objects[delivery.id])==3,'requester payment review updates remaining quantity')
G.me=currentMe
local ownMatch=G.db.objects[req.id];G.offers={{object=ownMatch.id,quantity=1,evidence={itemID=123,at=1800000000}}};G.UI.ShowOffer()
local beforeOwn=totals();G.UI.offer.primary.scripts.OnClick();check(G.UI.selected==ownMatch.id and totals()==beforeOwn,'own match opens bounty without self-payment claim')
G.offers={{object=ownMatch.id,quantity=1,evidence={itemID=123,at=1800000000}}};G.UI.ShowOffer();G.UI.offer.dismiss.scripts.OnClick(G.UI.offer.dismiss,'LeftButton');check(#G.offers==0,'Later handles native button arguments')
G.offers={{object=ownMatch.id,quantity=1,evidence={itemID=123,at=1800000000}}};G.UI.ShowOffer();G.UI.offer.CloseButton.scripts.OnClick(G.UI.offer.CloseButton,'LeftButton');check(#G.offers==0,'close handles native button arguments')
G.offers={{object=ownMatch.id,quantity=1,evidence={itemID=123,at=1800000000}}};G.UI.ShowOffer()
check(G.UI.offer.w==400 and G.UI.offer.h<285 and not G.UI.offer.view:IsShown(),'own prompt is compact with two actions')
check(G.UI.offer.matchIcon.texture==135328,'item icon fills portrait fallback')
local ranked=assert(G.Create('pvp',{target={name='Enemy Other',class='WARRIOR',faction='Horde',pvpRank=9,pvpRankName='Centurion'},title='Enemy Other',quantity=1,reward=10000}))
G.offers={{object=ranked.id,quantity=1,evidence={at=1800000000}}};G.UI.ShowOffer()
check(G.UI.offer.matchIcon.texture:find('ClassIcon_warrior',1,true) and G.UI.offer.text:GetText():find('Rank 9 Centurion',1,true),'PvP prompt shows class icon and captured rank badge')
local _,unknownRank=G.PvP.Art({name='Unknown Other'});check(unknownRank=='Rank unavailable','unavailable PvP rank is never invented')
-- Local preview works with own bounties and does not write production data.
local ownTest=assert(G.Create('request',{title='Test sword preview',itemID=123,quantity=5,reward=10000}))
G.UI.selected=ownTest.id;C_Container={GetContainerNumSlots=function(bag) return bag==0 and 1 or 0 end,GetContainerItemInfo=function() return {itemID=123,hyperlink=link,stackCount=10} end,PickupContainerItem=function() error('test must not pick up') end,SplitContainerItem=function() error('test must not split') end}
local previewObjects,previewHistory=totals();SlashCmdList.GUILDBOUNTYFOREVER('testcod');local test=G.UI.codTest
check(test:IsShown() and test.request:GetValue()==ownTest.id,'testcod opens selected own bounty without guild requirement')
test.quantity:SetText('3');test.preview.scripts.OnClick();check(test.output:GetText():find('split 3 from 10',1,true) and test.output:GetText():find('sending disabled',1,true),'preview explains stack split and disabled sending')
local objectsAfter,historyAfter=totals();check(objectsAfter==previewObjects and historyAfter==previewHistory,'UI preview creates no claims/history')
test.quantity:SetText('6');test.preview.scripts.OnClick();check(test.output:GetText():find('quantity',1,true),'UI preview reports invalid quantity');test:Hide()
-- Live self-test uses actual preparation calls only after an explicit mailbox click.
IsInGuild=function() return false end;G.guildKey='local:'..G.me
G.UI.TestCOD();test=G.UI.codTest;test.quantity:SetText('3');local bagStack=10;local mailCursor;local attached={};local sends=0
C_Container={GetContainerNumSlots=function(bag) return bag==0 and 1 or 0 end,GetContainerItemInfo=function() return {itemID=123,hyperlink=link,stackCount=bagStack} end,PickupContainerItem=function() mailCursor=bagStack;bagStack=0 end,SplitContainerItem=function(_,_,n) mailCursor=n;bagStack=bagStack-n end}
GetCursorInfo=function() if mailCursor then return 'item',123 end end
SendMailNameEditBox=CreateFrame('EditBox');SendMailSubjectEditBox=CreateFrame('EditBox');SendMailBodyEditBox=CreateFrame('EditBox');SendMailMoney={amount=0}
MailFrame=CreateFrame('Frame');MailFrame:Hide();SendMailCODButton={GetChecked=function(self) return self.checked end}
MoneyInputFrame_SetCopper=function(f,n) f.amount=n end;MoneyInputFrame_GetCopper=function(f) return f.amount end
SendMailRadioButton_OnClick=function() SendMailCODButton.checked=true end;MailFrameTab_OnClick=function() end
GetSendMailItem=function(i) if attached[i] then return 'Sword',123,135328,attached[i] end end
GetSendMailItemLink=function(i) return attached[i] and link end;ClickSendMailItemButton=function(i) attached[i]=mailCursor;mailCursor=nil end
SendMail=function() sends=sends+1 end
local liveBefore=totals();test.start.scripts.OnClick();local liveClaim=G.db.objects[G.UI.selected]
check(totals()>liveBefore and liveClaim.kind=='claim' and liveClaim.delivery.selfTest and liveClaim.state=='accepted','real local test creates labeled accepted claim')
check(bagStack==10 and G.Mail.waiting and sends==0,'accept tells user to go to mailbox without preparing or sending')
MailFrame:Show();G.Mail.Event('MAIL_SHOW');check(G.UI.mailTask:IsShown() and bagStack==10,'mailbox shows explicit Prepare delivery control')
G.UI.mailTask.prepare.scripts.OnClick();check(bagStack==7 and attached[1]==3 and SendMailNameEditBox:GetText()==G.player.name and sends==0,'prepare fills self recipient and exact attachments but never sends')
SendMail(SendMailNameEditBox:GetText(),SendMailSubjectEditBox:GetText());G.Mail.Event('MAIL_FAILED');check(G.db.objects[liveClaim.id].state=='accepted' and not G.db.objects[liveClaim.id].delivery.sentAt,'server-rejected self mail remains unsent')
SendMail(SendMailNameEditBox:GetText(),SendMailSubjectEditBox:GetText());G.Mail.Event('MAIL_SEND_SUCCESS');check(G.db.objects[liveClaim.id].state=='submitted' and G.db.objects[liveClaim.id].delivery.sentAt,'server-success self mail uses real send tracking')
-- A native COD acceptance automatically completes the real claim; no review button is used.
local delivered=G.db.objects[liveClaim.id];local inboxItem=true;local inboxCOD=delivered.delivery.amount
GetInboxNumItems=function() return 1 end
GetInboxHeaderInfo=function() return nil,nil,G.player.name,delivered.delivery.subject,0,inboxCOD end
GetInboxItem=function(_,slot) if inboxItem and slot==1 then return 'Sword',123,135328,3 end end
GetInboxItemLink=function(_,slot) return inboxItem and slot==1 and link end
TakeInboxItem=function() end
G.Mail.Event('MAIL_SHOW');TakeInboxItem(1,1);inboxItem=false;inboxCOD=0;bagStack=10;G.Mail.Event('BAG_UPDATE_DELAYED')
check(G.ClaimState(G.db.objects[liveClaim.id])=='paid' and G.db.objects[ownTest.id].receipts[liveClaim.id].codPaid,'native COD acceptance completes claim automatically without Record paid')
check(G.Remaining(G.db.objects[ownTest.id])==2,'automatic receipt reduces remaining quantity by delivered amount')
local paidRevision=G.db.objects[ownTest.id].rev;G.Mail.Event('MAIL_SUCCESS');check(G.db.objects[ownTest.id].rev==paidRevision,'late success cannot record payment twice')
-- Interactive onboarding uses real controls plus isolated examples, never live records/mail.
local tutorialObjects,tutorialHistory=totals();local realTabPreference=G.db.prefs.tab;local realEditor=G.UI.editor;local originalNote=realEditor.note:GetText();realEditor.note:SetText('Preserve my real draft')
local queueBefore=G.Mail.waiting;local sendsBefore=sends;local stackBefore=bagStack;G.root.prefs.tutorial=nil
G.Tutorial.OnLogin();local launch=timers[#timers];check(launch.delay==1,'first login schedules interactive tour');launch.fn()
local tour=G.Tutorial;local wizard=tour.frame
check(tour.active and wizard:IsShown() and G.UI.frame:IsShown() and tour.step==1,'tour opens actual addon window')
check(G.UI.rows[1].title:GetText()=='[Boar Ribs]' and G.UI.rows[1].object==nil,'example listing rendered without a live object')
check(tour.highlight:IsShown() and tour.arrow:IsShown() and tour.target==G.UI.status,'gold outline and arrow point at real control')
check(not tour.Finish() and not tour.Complete(),'cannot finish early')
wizard.next.scripts.OnClick(wizard.next);local step=tour.step;wizard.next.scripts.OnClick(wizard.next)
check(tour.step==step and not wizard.next.enabled,'action step cannot be skipped with Next')
G.UI.frame.Tabs[1].scripts.OnClick(G.UI.frame.Tabs[1]);check(tour.step==3,'clicking real Requests tab advances tour')
wizard.CloseButton.scripts.OnClick();check(not tour.active and not tour.Complete() and G.UI.editor==realEditor,'pause restores original editor reference')
G.UI.Toggle();check(tour.active and tour.step==3 and G.UI.frame:IsShown(),'resume returns to highlighted step inside addon')
local transitions=0
while tour.step<#tour.steps and transitions<#tour.steps+3 do
    local before=tour.step;local spec=tour.steps[before]
    if spec.phase=='stat2' then
        wizard.CloseButton.scripts.OnClick();G.UI.Toggle();check(tour.step==before and tour.active,'late resume reconstructs stat practice state')
    elseif spec.phase=='statsdone' then
        wizard.previous.scripts.OnClick(wizard.previous);check(tour.steps[tour.step].phase=='stat2','Back returns to stat exercise');tour.target.scripts.OnClick(tour.target);check(tour.step==before,'re-applying second stat after Back returns to locked rows')
    elseif spec.phase=='rule' and spec.target=='criteria' then
        local changed=false;G.Native.Action('Item type',function() changed=true end)({menu=true});check(changed,'native dropdown selection is allowed on practice form')
    end
    if spec.click then local target=tour.target;check(target and target.scripts.OnClick,'clickable target '..spec.target);target.scripts.OnClick(target,'LeftButton') else wizard.next.scripts.OnClick(wizard.next) end
    check(tour.step==before+1,'expected tour interaction advances '..before..' '..spec.target)
    transitions=transitions+1
end
check(tour.step==#tour.steps and wizard.next:GetText()=='Finish','tour reaches final step through actual highlighted controls')
check(tour.sent and tour.paid and tour.created,'demo exercises publishing, sending and automatic receipt')
check(G.db.prefs.tab==realTabPreference,'demo tab clicks do not change saved real navigation')
check(G.UI.editor~=realEditor and realEditor.note:GetText()=='Preserve my real draft','practice form never edits original draft')
wizard.next.scripts.OnClick(wizard.next)
check(tour.Complete() and not tour.active and not wizard:IsShown() and G.UI.editor==realEditor,'finish removes demo and restores real UI')
check(not G.UI.count:GetText():find('DEMO',1,true),'real listings replace example rows on finish')
check(realEditor.note:GetText()=='Preserve my real draft' and G.Mail.waiting==queueBefore and sends==sendsBefore and bagStack==stackBefore,'tour preserves drafts, native mail queue, sends and inventory')
local tutorialAfter,historyAfter=totals();check(tutorialAfter==tutorialObjects and historyAfter==tutorialHistory,'publishing and receiving demos create no production data')
local completeStep=G.root.prefs.tutorial.step;tour.OnLogin();check(not tour.active,'completed login does not restart tour')
if G.UI.codTest then G.UI.codTest:Show() end
SlashCmdList.GUILDBOUNTYFOREVER('help');check(not G.UI.codTest:IsShown(),'tour hides real auxiliary panels while preserving them')
check(tour.active and tour.step==1 and not tour.required,'help replays interactive tour')
wizard.CloseButton.scripts.OnClick();check(tour.Complete() and G.root.prefs.tutorial.step==completeStep and not tour.active,'closing replay restores data and preserves completion')
check(G.UI.codTest:IsShown(),'closing replay restores previously open real test panel');G.UI.codTest:Hide()
realEditor.note:SetText(originalNote)
-- Heart flow is local UI only, with all 100 distinct jokes available.
local supportObjects,supportHistory=totals();local supportQueue=G.Mail.waiting;local supportSends=sends
local heart=G.UI.heart;check(heart and heart.w==32 and heart.h==32 and heart.point[1]=='BOTTOMRIGHT','heart sits inside bottom-right footer')
local seen={};check(#G.Support.roasts==100,'100 roast choices')
for _,roast in ipairs(G.Support.roasts) do check(type(roast)=='string' and #roast>10 and not seen[roast],'unique nonempty roast');seen[roast]=true end
heart.scripts.OnClick(heart);local support=G.Support;local love=support.frame
check(love:IsShown() and support.phase=='like' and love.text:GetText()=='Did you like the addon?','heart opens question')
love.right.scripts.OnClick();local firstRoast=love.text:GetText();check(support.phase=='roast' and seen[firstRoast],'No shows a listed roast')
love.left.scripts.OnClick();check(love.text:GetText()~=firstRoast,'another roast avoids immediate repetition')
love.right.scripts.OnClick();love.left.scripts.OnClick();check(support.phase=='eu','Yes asks EU PvP')
love.right.scripts.OnClick();check(support.phase=='thanks' and love.text:GetText():find("thanks is enough",1,true),'non-EU player receives thanks')
love.left.scripts.OnClick();love.left.scripts.OnClick();love.left.scripts.OnClick();check(support.phase=='alliance' and love.text:GetText():find('Ironfoe Thundercog',1,true),'EU PvP player sees requested Alliance character')
love.right.scripts.OnClick();check(not love:IsShown(),'close dismisses thanks flow')
local supportAfter,supportHistoryAfter=totals();check(supportAfter==supportObjects and supportHistoryAfter==supportHistory and G.Mail.waiting==supportQueue and sends==supportSends,'heart flow creates no records, delivery tasks or sends')
print('PASS ['..scenario..']: '..count..' UI construction, native handler wiring, focus ownership, input, mode isolation, cancel and bootstrap checks. Live keyboard/mouse behavior remains unverified.')
