local _,G=...
G.UI={tab=1,offset=0,rows={}};local U,N=G.UI,G.Native
local names={'Requests','PvP Bounties','Mine','History'}
local filters={'All personal activity','Waiting for my review','Created by me','My claims','Completed'}
local function result(o,err) if not o then U.error:SetText(err or 'Unable to save.') else U.error:SetText('');G.Refresh() end end
local function money(n) return G.Money(n) end
local function state(o) if o.kind=='claim' then return G.ClaimState(o) end return o.state=='open' and G.Remaining(o)==0 and 'fulfilled' or o.state end
local function collect()
    local out={}
    if U.tab==4 then return G.HistoryRows() end
    for _,o in pairs(G.db.objects) do
        local include=false
        if U.tab==1 then include=o.kind=='request' and o.state=='open' and G.Remaining(o)>0
        elseif U.tab==2 then include=o.kind=='pvp' and o.state=='open' and G.Remaining(o)>0
        else
            local p=o.parent and G.db.objects[o.parent]
            local mine=o.owner==G.me;local review=p and p.owner==G.me and G.ClaimState(o)=='submitted'
            local f=U.filter or 1
            include=(f==1 and (mine or review)) or (f==2 and review) or (f==3 and mine and o.kind~='claim') or (f==4 and mine and o.kind=='claim') or (f==5 and mine and (state(o)=='closed' or state(o)=='paid' or state(o)=='rejected'))
        end
        if include and o.kind~='history' then out[#out+1]=o end
    end
    table.sort(out,function(a,b) if a.created==b.created then return a.id<b.id end return a.created>b.created end)
    return out
end
local function detail(o,historic)
    U.selected=o and o.id or nil
    for _,b in ipairs(U.actions) do b:Hide() end
    if not o then U.detailText:SetHeight(130);U.detailText:SetText('Select a row to inspect its details and available actions.');return end
    if historic then
        U.detailText:SetText('History: '..G.Safe(historic.action or historic.state)..' • revision '..historic.rev..'\n'..G.Date('%d %b %H:%M',historic.at)..' • '..G.Safe(historic.actorName or 'Unresolved character')..'\n'..G.Safe(historic.title)..'\n'..G.Safe(historic.note or '')..'\nQuantity: '..tostring(historic.quantity or '')..'  Reward promise: '..money(historic.reward)..'\nID: '..G.Safe(historic.id))
        U.detailText:SetHeight(math.max(130,U.detailText:GetStringHeight()+12));U.detailChild:SetHeight(math.max(140,U.detailText:GetStringHeight()+24));return
    end
    local lines={G.Items.Label(o),G.Safe(G.DisplayOwner(o))..'  •  '..G.Date('%d %b %H:%M',o.created)..'  •  '..state(o)..'  •  revision '..o.rev}
    if o.kind~='claim' then lines[#lines+1]='Remaining: '..G.Remaining(o)..' / '..o.quantity..'    Reward promise: '..money(o.reward) end
    if o.note~='' then lines[#lines+1]=G.Safe(o.note) end
    if o.kind=='pvp' then local target,resolution=G.People.Resolve(o.target);lines[#lines+1]='Target: '..G.Safe(target.name)..' | '..G.Safe(target.guid or 'No observed GUID')..' | '..G.Safe(target.class or '')..' '..G.Safe(target.faction or '')..' | '..G.Safe(target.ruleset or 'Context unavailable')..' | '..resolution end
    if o.kind=='claim' then
        local p=G.db.objects[o.parent];lines[#lines+1]='For: '..(p and G.Items.Label(p) or 'Parent record pending sync')..'    Quantity: '..o.quantity
        local d=o.delivery;local r=p and p.receipts and p.receipts[o.id]
        if d and d.selfTest then lines[#lines+1]='REAL LOCAL MAIL TEST - self delivery' end
        if d and d.sentAt then lines[#lines+1]='Mail sent: '..G.Date('%d %b %H:%M',d.sentAt)..' • COD '..money(d.amount)..' • '..d.subject end
        if r then lines[#lines+1]='Requester received: '..r.quantity..' / '..o.quantity..' • '..(r.codPaid and 'COD accepted/paid' or 'Payment unconfirmed') end
        if d and d.payoutAt then lines[#lines+1]='Supplier collected COD proceeds: '..G.Date('%d %b %H:%M',d.payoutAt) end
        local e=o.evidence
        lines[#lines+1]='Evidence: '..G.Safe(e.method or 'Manual')..' | '..G.Safe(e.zone or '')..' | '..G.Date('%d %b %H:%M',e.at or o.created)
        for _,k in ipairs({'itemID','targetName','targetGUID','event','sourceGUID','sourceName','flags','combatTime','character'}) do if e[k] then lines[#lines+1]=k..': '..G.Safe(e[k]) end end
        if p and p.kind=='request' then
            local sent=G.db.prefs.codSent and G.db.prefs.codSent[o.id];if sent and not (d and d.sentAt) then lines[#lines+1]='COD mailed: '..G.Date('%d %b %H:%M',sent.at)..' • '..money(sent.amount) end
            lines[#lines+1]='Delivery: '..G.Safe(G.DisplayOwner(o))..' → '..G.Safe(G.DisplayOwner(p))
            lines[#lines+1]='Reward promise for the full request: '..money(p.reward)..'. Agree payment for this '..o.quantity..'-item claim with the requester.'
            lines[#lines+1]=G.ClaimState(o)=='accepted' and 'Next: agree the price, then use Mail COD to arrange delivery.' or G.ClaimState(o)=='submitted' and (d and d.sentAt and 'Receipt and payment record automatically when the requester accepts COD and collects all claimed items. No separate Record paid click is needed.' or 'Manual delivery submitted for requester review. Verified COD mail records automatically.') or 'Delivery/payment review: '..G.ClaimState(o)
        end
        lines[#lines+1]='Loot detection does not prove delivery. Trade, mail and gold transfers are manual.'
    else
        local count=0;for _,c in pairs(G.db.objects) do if c.parent==o.id then count=count+1 end end
        lines[#lines+1]=count..' claims retained. See Mine to review submissions.'
    end
    lines[#lines+1]='ID: '..G.Safe(o.id)
    U.detailText:SetText(table.concat(lines,'\n'));U.detailText:SetHeight(math.max(130,U.detailText:GetStringHeight()+12));U.detailChild:SetHeight(math.max(140,U.detailText:GetStringHeight()+24))
    U.detailScroll:SetVerticalScroll(0)
    local x=12;local function action(label,fn)
        local b=U.actions[#U.activeActions+1];U.activeActions[#U.activeActions+1]=b
        b:ClearAllPoints();b:SetPoint('BOTTOMLEFT',U.detail,x,8);b:SetWidth(126);b:SetText(label);b:SetScript('OnClick',N.Action(label,fn,b));b:Show();x=x+132
    end
    U.activeActions={}
    if o.kind=='claim' then
        if o.owner==G.me and G.ClaimState(o)=='accepted' then action('Submit for review',function() U.Confirm('Submit this claim for delivery/payment review? Arrange the handover with the requester; this does not transfer items or gold.',function() result(G.Submit(o)) end) end) end
        local deliveryParent=G.db.objects[o.parent]
        if not (o.delivery and o.delivery.sentAt) and not (G.db.prefs.codSent and G.db.prefs.codSent[o.id]) and deliveryParent and deliveryParent.kind=='request' and (deliveryParent.owner~=G.me or G.Mail.IsSelfTest(o,deliveryParent)) and o.owner==G.me and (G.ClaimState(o)=='accepted' or G.ClaimState(o)=='submitted') then action('Mail COD',function() U.COD(o) end) end
        if o.owner==G.me and (G.ClaimState(o)=='accepted' or G.ClaimState(o)=='submitted') then action('Withdraw',function() result(G.Edit(o,{state='withdrawn'})) end) end
        local p=G.db.objects[o.parent]
        if p and p.kind=='request' and (o.owner==G.me or p.owner==G.me) and o.owner~=p.owner then
            action(o.owner==G.me and 'Contact requester' or 'Contact supplier',function()
                local peer=o.owner==G.me and p or o
                if ChatFrameUtil and ChatFrameUtil.SendTellWithMessage then ChatFrameUtil.SendTellWithMessage(G.DisplayOwner(peer),'Guild Bounty: '..o.quantity..' x '..G.Items.Label(p)..'. Can we arrange delivery and payment?')
                else U.error:SetText('Whisper '..G.Safe(G.DisplayOwner(peer))..' to agree delivery and payment.') end
            end)
        end
        if p and p.owner==G.me and G.ClaimState(o)=='submitted' then
            action(o.delivery and o.delivery.sentAt and 'Manual review' or 'Record paid',function() U.Confirm('Manual settlement override: confirm you received the claimed items/evidence and paid the agreed reward. Verified COD collection records automatically.',function() result(G.Decide(o,'paid')) end) end)
            action('Reject',function() U.Confirm('Reject this claim permanently?',function() result(G.Decide(o,'rejected')) end) end)
        end
    else
        if o.state=='open' and G.Remaining(o)>0 then
            if o.kind=='request' then action('Accept request',function() U.Quantity(o) end)
            else action('Use kill evidence',function()
                local latest
                for _,v in pairs(G.db.evidence) do if v.parent==o.id and (not latest or v.evidence.at>latest.at) then latest=v.evidence end end
                if latest then result(G.Accept(o,latest,1)) else U.error:SetText('No detected personal kill evidence for this target yet.') end
            end) end
        end
        if o.owner==G.me and o.state=='open' then
            action('Edit',function() U.Editor(o) end)
            action('Close',function() U.Confirm('Close this request? Its history and claims are retained.',function() result(G.Edit(o,{state='closed'})) end) end)
        end
    end
end
function U.Refresh()
    if G.Tutorial and G.Tutorial.active then G.Tutorial.RenderDemo();return end
    if not U.ready or not U.frame or not U.frame:IsShown() then return end
    U.status:SetText((G.ruleset or 'Ruleset unavailable')..' • '..(IsInGuild() and G.Safe(GetGuildInfo('player')) or 'No guild — local drafts only')..'   •   '..G.Sync.Status())
    local list=collect();U.list=list;U.offset=math.max(0,math.min(U.offset,math.max(0,#list-8)))
    U.count:SetText(#list..' records   '..(U.offset+1)..'–'..math.min(U.offset+8,#list));U.empty:SetShown(#list==0)
    U.empty:SetText(U.tab==3 and 'Your requests, fulfilments and claims awaiting review appear here.' or U.tab==4 and 'Activity appears here when records change.' or 'No open guild requests. Create one, or wait for a guild peer to synchronize.')
    U.filterButton:SetShown(U.tab==3);U.filterButton:SetText(filters[U.filter or 1])
    for i,row in ipairs(U.rows) do
        local o=list[i+U.offset];row.object=o
        if o then
            row:Show();local obj=U.tab==4 and G.db.objects[o.id] or o
            row.icon.icon:SetTexture('Interface\\Icons\\INV_Misc_Note_01');row.icon:SetScript('OnEnter',nil)
            if obj and obj.itemID then local info=G.Items.Info(obj.itemID);row.icon.icon:SetTexture(info and info.icon or 'Interface\\Icons\\INV_Misc_QuestionMark');N.Tooltip(row.icon,obj.itemID)
            elseif obj and obj.kind=='pvp' then row.icon.icon:SetTexture('Interface\\Icons\\Achievement_PVP_A_01')
            elseif obj and obj.kind=='claim' then local e=obj.evidence;if e.itemID then local info=G.Items.Info(e.itemID);row.icon.icon:SetTexture(info and info.icon or 'Interface\\Icons\\INV_Misc_QuestionMark');N.Tooltip(row.icon,e.itemID) end end
            if U.tab==4 then
                row.title:SetText(G.Safe(o.title));row.sub:SetText(G.Date('%d %b %H:%M',o.at)..' • '..G.Safe(o.actorName or 'Unresolved character'));row.qty:SetText('rev '..o.rev);row.state:SetText(o.action or o.state);row.money:Hide();row.action:SetText('Inspect')
            else
                row.title:SetText(G.Items.Label(o));row.sub:SetText(G.Safe(G.DisplayOwner(o)));row.qty:SetText(o.kind=='claim' and tostring(o.quantity) or (G.Remaining(o)..' / '..o.quantity));row.state:SetText(state(o));row.money:Show();row.money:SetAmount(o.reward or 0);row.action:SetText(o.kind=='claim' and 'Review' or 'Details')
            end
            row.selection:SetShown(U.selected==o.id and (U.tab~=4 or (U.historySelection and U.historySelection.rev==o.rev)))
        else row:Hide() end
    end
    if U.selected and G.db.objects[U.selected] then detail(G.db.objects[U.selected],U.tab==4 and U.historySelection or nil) else detail(nil) end
end
function U.Confirm(text,fn,cancel)
    local resolved=false
    local function accept() if resolved then return end;resolved=true;fn() end
    local function reject() if resolved then return end;resolved=true;if cancel then cancel() end end
    StaticPopupDialogs.GBF_CONFIRM={text=text,button1=ACCEPT,button2=CANCEL,OnAccept=N.Action('Confirm',accept),OnCancel=reject,OnHide=reject,timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3}
    StaticPopup_Show('GBF_CONFIRM')
end
function U.Quantity(o,evidence,defaultQuantity,onAccepted)
    if G.Tutorial and G.Tutorial.Require() then return end
    StaticPopupDialogs.GBF_QUANTITY={text='Quantity you intend to fulfil (up to '..G.Remaining(o)..'):',button1=ACCEPT,button2=CANCEL,hasEditBox=true,maxLetters=6,OnShow=function(self) local box=self.GetEditBox and self:GetEditBox() or self.EditBox or self.editBox;box:SetText(tostring(math.min(defaultQuantity or 1,G.Remaining(o))));box:SetFocus() end,OnAccept=function(self)
        local n=tonumber((self.GetEditBox and self:GetEditBox() or self.EditBox or self.editBox):GetText());if not G.Int(n,1,G.Remaining(o)) then U.error:SetText('Enter a valid quantity.');return end
        local claim,err=G.Accept(o,evidence,n);result(claim,err);if claim then if onAccepted then onAccepted(claim) else U.OpenRecord(claim) end end
    end,timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3}
    StaticPopup_Show('GBF_QUANTITY')
end
local function buildEditor()
    local e=N.Frame(nil,U.frame,'InsetFrameTemplate');e:SetFrameLevel(U.frame:GetFrameLevel()+30);e:SetPoint('TOPLEFT',12,-62);e:SetPoint('BOTTOMRIGHT',-12,42);U.editor=e
    e.heading=N.Label(e,'New request',16,-14,650,'GameFontNormalLarge')
    e.mode=1
    e.modeButtons={}
    for i,label in ipairs({'Exact Item','Rule Request','PvP Target'}) do
        local mode=i;e.modeButtons[i]=N.Button(e,label,16+(i-1)*178,-43,170,function() U.SetMode(mode) end)
    end
    N.BackgroundFocus(e)
    e.item=N.Edit(e,'Item ID or item link (focus, then shift-click; or drop)',16,-83,510,'',500)
    e.itemSlot=N.Icon(e,566,-97);e.itemSlot:SetSize(36,36);e.itemSlot:SetFrameLevel(e:GetFrameLevel()+10);e.itemSlot:EnableMouse(true)
    e.itemPreview=N.Label(e,'Drop an item here',610,-97,245,'GameFontHighlightSmall');e.itemPreview:SetHeight(35)
    e.itemInfo=N.Label(e,'',610,-136,245,'GameFontDisableSmall');e.itemInfo:SetHeight(52)
    e.item:SetScript('OnTextChanged',function() U.ItemPreview() end)
    e.item:SetScript('OnReceiveDrag',function() U.DropItem() end)
    e.item:SetScript('OnMouseUp',function(_,button) if button=='LeftButton' then U.DropItem() end end)
    e.itemSlot:SetScript('OnReceiveDrag',function() U.DropItem() end)
    e.itemSlot:SetScript('OnMouseUp',function(_,button) if button=='LeftButton' and not U.DropItem() then e.item:SetFocus() end end)
    e.target=N.Edit(e,'Opposing player — full character name',16,-83,370,'',100)
    e.target:SetScript('OnTextChanged',function() if not e.settingTarget and e.targetInfo and G.People.NameKey(e.target:GetText())~=G.People.NameKey(e.targetInfo.name) then e.targetInfo=nil end end)
    e.targetButton=N.Button(e,'Use target',410,-102,115,function()
        N.ClearFocus();local target,err=G.PvP.Target()
        if target then e.settingTarget=true;e.targetInfo=target;e.target:SetText(target.name);e.settingTarget=false;U.error:SetText('Observed target captured: '..target.name)
        else U.error:SetText(err) end
    end)
    e.class=N.Choice(e,'Item type',16,-83,200,G.Items.ClassOptions(),function(value)
        local classID=value~='' and tonumber(value) or nil
        e.subclass:SetOptions(G.Items.SubclassOptions(classID));e.subclass:SetValue('',true);N.Enabled(e.subclass,classID~=nil)
    end)
    e.subclass=N.Choice(e,'Subtype',250,-83,200,G.Items.SubclassOptions(nil))
    e.slot=N.Choice(e,'Equipment slot',484,-83,230,G.Items.SlotOptions())
    e.required=N.Edit(e,'Minimum character level',16,-143,190,'',5)
    e.maxRequired=N.Edit(e,'Maximum character level',250,-143,190,'',5)
    e.statRules={};e.statOrder={};e.statOffset=0
    e.stat=N.Choice(e,'Add stat requirement',16,-185,290,{{value='',label='Choose a stat'}})
    e.statMin=N.Edit(e,'Minimum stat',340,-185,130,'',7)
    e.statMax=N.Edit(e,'Maximum stat',500,-185,130,'',7)
    e.statApply=N.Button(e,'Apply stat',660,-204,110,function()
        local key=e.stat:GetValue();if key=='' then U.error:SetText('Choose a stat first.');return end
        if e.statMin:GetText()=='' and e.statMax:GetText()=='' then U.error:SetText('Enter a minimum or maximum for this stat.');return end
        local candidate=G.Copy(e.statRules);candidate[key]={min=e.statMin:GetText(),max=e.statMax:GetText()}
        local _,fields=G.Form.Build({mode=2,stats=candidate,quantity='1',gold='0',silver='0',copper='0'})
        if type(fields)~='table' then U.error:SetText(fields);return end
        if not e.statRules[key] then e.statOrder[#e.statOrder+1]=key end
        e.statRules=fields.rules.stats;e.statOffset=math.max(0,#e.statOrder-3)
        e.stat:SetValue('',true);e.statMin:SetText('');e.statMax:SetText('');U.StatSummary();N.ClearFocus()
        U.error:SetText('Stat applied and locked. Choose another stat.')
        if PlaySound and SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN then PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN,'Master') end
    end)
    e.statPanel=CreateFrame('Frame',nil,e);e.statPanel:SetPoint('TOPLEFT',16,-238);e.statPanel:SetSize(770,86);e.statRows={}
    for index=1,3 do
        local row=CreateFrame('Frame',nil,e.statPanel);row:SetPoint('TOPLEFT',0,-(index-1)*28);row:SetSize(654,26);e.statRows[index]=row
        row.text=N.Label(row,'',4,-5,448,'GameFontHighlightSmall')
        row.edit=N.Button(row,'Edit',464,0,76,function()
            local key=row.key;local range=e.statRules[key];if not range then return end
            e.statRules[key]=nil;for i,value in ipairs(e.statOrder) do if value==key then table.remove(e.statOrder,i);break end end
            U.StatSummary();e.stat:SetValue(key,true);e.statMin:SetText(tostring(range.min or ''));e.statMax:SetText(tostring(range.max or ''));U.error:SetText('Editing stat. Apply it again to lock the new limits.')
        end)
        row.remove=N.Button(row,'Remove',548,0,90,function()
            e.statRules[row.key]=nil;for i,value in ipairs(e.statOrder) do if value==row.key then table.remove(e.statOrder,i);break end end;U.StatSummary()
        end)
    end
    e.statPage=N.Label(e.statPanel,'',660,-1,110,'GameFontHighlightSmall')
    e.statPrevious=N.Button(e.statPanel,'Previous',660,-22,110,function() e.statOffset=math.max(0,e.statOffset-3);U.StatSummary() end)
    e.statNext=N.Button(e.statPanel,'Next',660,-52,110,function() e.statOffset=math.min(math.max(0,#e.statOrder-3),e.statOffset+3);U.StatSummary() end)
    e.statPanel:EnableMouseWheel(true);e.statPanel:SetScript('OnMouseWheel',function(_,delta) e.statOffset=math.max(0,math.min(math.max(0,#e.statOrder-3),e.statOffset-delta));U.StatSummary() end)
    e.help=N.Label(e,'Criteria are ANDed. Empty fields are ignored. Choose named item types, subtypes and equipment slots.\nMatching uses cached C_Item metadata; unsupported stats are deliberately excluded.',16,-278,775,'GameFontHighlightSmall');e.help:SetHeight(40)
    e.quantity=N.Edit(e,'Quantity',16,-331,100,'1',6)
    e.gold=N.Edit(e,'Reward gold',150,-331,110,'0',8)
    e.silver=N.Edit(e,'Silver',280,-331,75,'0',2)
    e.copper=N.Edit(e,'Copper',375,-331,75,'0',2)
    e.note=N.Edit(e,'Note (optional, 500 characters)',16,-391,760,'',500)
    N.Label(e,'Reward is the total promise for this request. Agree partial payments with the creator. All payments are manual.',16,-445,775,'GameFontHighlightSmall')
    e.saveButton=N.Button(e,'Save',16,-481,110,function() N.ClearFocus();U.SaveEditor() end)
    e.cancelButton=N.Button(e,'Cancel',136,-481,110,U.CancelEditor)
    e:Hide()
end
function U.ItemPreview()
    local e=U.editor;if not e or not e.itemSlot then return end
    local id=G.Items.ParseInput(e.item:GetText());e.resolvedItem=nil
    e.itemSlot.icon:SetTexture('Interface\\Icons\\INV_Misc_QuestionMark')
    if not id then e.itemPreview:SetText(e.item:GetText()=='' and 'Drop an item here' or 'Enter an item ID or item link.');e.itemInfo:SetText('');e.itemSlot:SetScript('OnEnter',nil);return end
    local info=G.Items.Info(id)
    N.Tooltip(e.itemSlot,id)
    if info then
        e.resolvedItem=info;e.itemSlot.icon:SetTexture(info.icon);e.itemPreview:SetText(info.link)
        e.itemInfo:SetText('Item #'..id..' • item level '..tostring(info.level)..'\nRequires level '..tostring(info.required)..'\n'..tostring(info.slot or ''))
    else e.itemPreview:SetText('Loading item #'..id..'…');e.itemInfo:SetText('Save requires resolved item information.') end
end
function U.InsertItem(value)
    local e=U.editor
    if not e or not e:IsShown() or e.mode==3 then return false end
    local id=G.Items.ParseInput(value);if not id then return false end
    e.item:SetText(type(value)=='string' and value or tostring(id));e.item:SetCursorPosition(0);U.ItemPreview();G.Debug('Item input captured: '..id);return true
end
function U.DropItem()
    local e=U.editor;if not e or not e:IsShown() or e.mode==3 then return false end
    local kind,id,link=GetCursorInfo()
    if kind~='item' then return false end
    id=G.Items.ID(id) or G.Items.ID(link)
    if not id and C_Cursor and C_Cursor.GetCursorItem and C_Item and C_Item.GetItemID then
        local location=C_Cursor.GetCursorItem();if location then id=G.Items.ID(C_Item.GetItemID(location)) end
    end
    if not id then G.Debug('Item cursor had no readable item ID.');return false end
    if U.InsertItem(id) then ClearCursor();return true end
    return false
end
function U.LinkInputActive()
    local e=U.editor
    if not e or not U.frame:IsShown() or not e:IsShown() or e.mode==3 or not e.item:HasFocus() then return false end
    if GetCurrentKeyBoardFocus then return GetCurrentKeyBoardFocus()==e.item end
    return true
end
function U.InstallLinkInput()
    if U.linksInstalled then return end
    U.linksInstalled=true
    -- Secure post-hooks observe links without replacing/tainting Blizzard's
    -- dispatcher or changing its protected call chain and return values.
    local function capture(link)
        if U.LinkInputActive() then U.InsertItem(link) end
    end
    if hooksecurefunc and ChatFrameUtil and type(ChatFrameUtil.InsertLink)=='function' then
        hooksecurefunc(ChatFrameUtil,'InsertLink',capture)
    else G.Debug('Secure item-link hook unavailable; ID/paste/drop remain available.') end
    if hooksecurefunc and type(ChatEdit_InsertLink)=='function' then
        hooksecurefunc('ChatEdit_InsertLink',capture)
    end
end
function U.SetMode(mode)
    local e=U.editor;if not e or e.existing or mode<1 or mode>3 then return end
    N.ClearFocus();e.mode=mode;G.Debug('Selected request type '..mode)
    -- Draft fields are isolated. Validation only reads the selected mode.
    if mode~=3 then e.targetInfo=nil end
    U.error:SetText('');U.EditorFields()
end
function U.CancelEditor()
    local e=U.editor;N.ClearFocus();U.pendingSave=nil;if StaticPopup_Hide then StaticPopup_Hide('GBF_CONFIRM') end;e:Hide();e.existing=nil;e.targetInfo=nil;e.resolvedItem=nil
    U.board:Show();U.detail:Show();U.Refresh()
end
function U.StatSummary()
    local e=U.editor;local names={};local options={{value='',label='Choose another stat'}}
    for _,option in ipairs(G.Items.StatOptions()) do names[option.value]=option.label;if not e.statRules[option.value] then options[#options+1]=option end end
    e.stat:SetOptions(options);e.statOffset=math.max(0,math.min(e.statOffset,math.max(0,#e.statOrder-3)))
    for index,row in ipairs(e.statRows) do
        local key=e.statOrder[index+e.statOffset];local range=key and e.statRules[key];row.key=key;row:SetShown(range~=nil)
        if range then row.text:SetText((names[key] or key)..'   •   Min: '..tostring(range.min or 'Any')..'   Max: '..tostring(range.max or 'Any')..'   [Locked]') end
    end
    e.statPage:SetText(#e.statOrder==0 and 'No stats yet' or (e.statOffset+1)..'–'..math.min(#e.statOrder,e.statOffset+3)..' / '..#e.statOrder)
    N.Enabled(e.statPrevious,e.statOffset>0);N.Enabled(e.statNext,e.statOffset+3<#e.statOrder)
end
function U.EditorFields()
    local e=U.editor
    for i,b in ipairs(e.modeButtons) do
        N.Enabled(b,not e.existing or i==e.mode);b:SetButtonState(i==e.mode and 'PUSHED' or 'NORMAL',false)
        if i==e.mode then b:LockHighlight() else b:UnlockHighlight() end
    end
    for _,k in ipairs({'class','subclass','slot','required','maxRequired','stat','statMin','statMax','statApply','statPanel'}) do e[k]:SetShown(e.mode==2);if e[k].caption then e[k].caption:SetShown(e.mode==2) end end
    for _,k in ipairs({'item','itemSlot','itemPreview','itemInfo'}) do e[k]:SetShown(e.mode==1) end
    e.item.caption:SetShown(e.mode==1);e.target:SetShown(e.mode==3);e.target.caption:SetShown(e.mode==3);e.targetButton:SetShown(e.mode==3)
    N.Enabled(e.quantity,e.mode~=3);if e.mode==3 then e.quantity:SetText('1') end
    e.help:ClearAllPoints();e.help:SetPoint('TOPLEFT',e.mode==2 and 478 or 16,e.mode==2 and -143 or -278);e.help:SetWidth(e.mode==2 and 300 or 775);e.help:SetHeight(40)
    e.help:SetText(e.mode==2 and 'Character level means the level required to use the item. Apply each stat to lock its row, then add another. All selected criteria must match.' or e.mode==3 and 'Enter both parts of the character name. Use target captures observed identity when available.\nContext: '..(G.ruleset or 'unavailable')..'. Kill records distinguish credit from damage participation.' or 'Type an item ID, paste a link, or focus this field and shift-click an item.\nDrop onto the field or item slot. Save requires valid, resolved item information.')
    U.ItemPreview()
end
function U.Editor(o)
    if G.Tutorial and G.Tutorial.Require() then return end
    if not U.ready then G.UIError('New request','Window initialization is incomplete.');return end
    if U.pendingSave then U.pendingSave=nil;if StaticPopup_Hide then StaticPopup_Hide('GBF_CONFIRM') end end
    if not U.editor then buildEditor() end
    local e=U.editor;e.existing=o;e.mode=o and (o.kind=='pvp' and 3 or o.rules and 2 or 1) or (U.tab==2 and 3 or 1)
    e.heading:SetText(o and 'Edit request' or 'Create guild request');e.item:SetText(o and tostring(o.itemID or '') or '')
    e.settingTarget=true;e.targetInfo=o and G.Copy(o.target) or nil;e.target:SetText(o and o.target and o.target.name or '');e.settingTarget=false
    local r=o and o.rules or {};for _,pair in ipairs({{'class','classID'},{'subclass','subclassID'},{'slot','slot'},{'required','minRequired'},{'maxRequired','maxRequired'}}) do local field,key=pair[1],pair[2]; if field=='class' or field=='subclass' or field=='slot' then e[field]:SetValue(r[key] or '') else e[field]:SetText(tostring(r[key] or '')) end end
    e.quantity:SetText(tostring(o and o.quantity or 1));local reward=o and o.reward or 0
    e.gold:SetText(tostring(math.floor(reward/10000)));e.silver:SetText(tostring(math.floor(reward/100)%100));e.copper:SetText(tostring(reward%100));e.note:SetText(o and o.note or '')
    e.statRules=G.Copy(r.stats or {});e.statOrder={};for key in pairs(e.statRules) do e.statOrder[#e.statOrder+1]=key end;table.sort(e.statOrder);e.statOffset=0;e.stat:SetValue('',true);e.statMin:SetText('');e.statMax:SetText('');U.StatSummary()
    N.Enabled(e.subclass,e.class:GetValue()~='');U.EditorFields();U.board:Hide();U.detail:Hide();e:Show();U.error:SetText('')
end
function U.SaveEditor(confirmed)
    if G.Tutorial and G.Tutorial.active then return end
    local e=U.editor;local draft={mode=e.mode,targetInfo=e.targetInfo}
    for _,key in ipairs({'item','target','required','maxRequired','quantity','gold','silver','copper','note'}) do draft[key]=e[key]:GetText() end
    for _,key in ipairs({'class','subclass','slot'}) do draft[key]=e[key]:GetValue() end
    draft.stats=G.Copy(e.statRules)
    if e.mode==2 and (e.stat:GetValue()~='' or e.statMin:GetText()~='' or e.statMax:GetText()~='') then U.error:SetText('Apply the current stat to lock it before saving.');return end
    if e.existing and e.existing.rules then draft.level=tostring(e.existing.rules.minLevel or '');draft.maxLevel=tostring(e.existing.rules.maxLevel or '') end
    local kind,fields=G.Form.Build(draft)
    if not kind then U.error:SetText(fields);return end
    if not confirmed then
        if U.pendingSave then return end
        local context=G.guildKey;local editor=e;local contract=G.Copy(fields);local editID=e.existing and e.existing.id
        U.pendingSave=true
        U.Confirm((editID and 'Save changes to ' or 'Create request for ')..G.Safe(fields.title)..'?\nQuantity: '..fields.quantity..'\nReward promise: '..money(fields.reward),function()
            U.pendingSave=nil
            if G.guildKey~=context or not U.frame:IsShown() or not editor:IsShown() then return end
            -- Validate the frozen contract again, and commit exactly once.
            U.CommitSave(kind,contract,editID)
        end,function() U.pendingSave=nil end)
        return
    end
    U.CommitSave(kind,fields,e.existing and e.existing.id)
end
function U.CommitSave(kind,fields,editID)
    local e=U.editor;local o,err
    local original=editID and G.db.objects[editID]
    if editID and not original then result(nil,'The request is no longer available.');return end
    if original then
        -- Preserve target/item identity on edits; recreate to change the contract.
        if original.kind~=kind or original.itemID~=fields.itemID or G.Codec.Encode(original.rules or {})~=G.Codec.Encode(fields.rules or {}) or G.Codec.Encode(original.target or {})~=G.Codec.Encode(fields.target or {}) then U.error:SetText('Item, criteria and target identity are fixed. Close and create a new request to change them.');return end
        local paid=original.quantity-G.Remaining(original);if fields.quantity<paid then U.error:SetText('Quantity cannot be less than completed quantity.');return end
        o,err=G.Edit(original,{quantity=fields.quantity,reward=fields.reward,note=fields.note})
    else o,err=G.Create(kind,fields) end
    if o then
        N.ClearFocus();e:Hide();U.board:Show();U.detail:Show();U.tab=kind=='pvp' and 2 or 1;U.offset=0;U.selected=o.id;G.db.prefs.tab=U.tab
        U.UpdateTabs()
        G.Refresh()
        -- Same-second IDs may sort after older rows; put the new request on screen.
        for index,value in ipairs(U.list or {}) do if value.id==o.id then U.offset=math.floor((index-1)/8)*8;break end end
        G.Refresh();U.error:SetText(editID and 'Changes saved.' or 'Request created. Select Details below to review it.')
        G.Chat(editID and 'Changes saved.' or ('Request created: '..G.Items.Label(o)))
        if PlaySound and SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN then PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN,'Master') end
    else result(nil,err) end
end
function U.Build()
    U.ready=false;U.actions={}
    local f=N.Frame('GuildBountyForeverFrame',UIParent,'ButtonFrameTemplate');U.frame=f;f:Hide()
    f:SetSize(920,670);f:SetPoint('CENTER');f:SetClampedToScreen(true);f:SetMovable(true);f:EnableMouse(true);f:SetFrameStrata('HIGH')
    N.BackgroundFocus(f)
    local drag=CreateFrame('Frame',nil,f);U.dragHandle=drag;drag:SetPoint('TOPLEFT',60,-1);drag:SetPoint('TOPRIGHT',-35,-1);drag:SetHeight(28);drag:EnableMouse(true);drag:RegisterForDrag('LeftButton');drag:SetFrameLevel(f:GetFrameLevel()+20)
    drag:SetScript('OnDragStart',function() N.ClearFocus();f:StartMoving() end)
    drag:SetScript('OnDragStop',function() f:StopMovingOrSizing();if G.Tutorial and G.Tutorial.active then return end;local point,_,relative,x,y=f:GetPoint();G.db.prefs.position={point=point,relative=relative,x=x,y=y} end)
    drag:SetScript('OnMouseDown',N.ClearFocus)
    local p=G.db.prefs.position;if type(p)=='table' and type(p.point)=='string' and type(p.relative)=='string' and type(p.x)=='number' and type(p.y)=='number' then f:ClearAllPoints();f:SetPoint(p.point,UIParent,p.relative,p.x,p.y) end
    N.Title(f,'Guild Bounty')
    if f.SetPortraitToAsset then f:SetPortraitToAsset('Interface\\Icons\\INV_Misc_Coin_01') elseif f.PortraitContainer and f.PortraitContainer.portrait then f.PortraitContainer.portrait:SetTexture('Interface\\Icons\\INV_Misc_Coin_01') end
    if f.Inset then f.Inset:Hide() end
    UISpecialFrames[#UISpecialFrames+1]='GuildBountyForeverFrame'
    U.status=N.Label(f,'',74,-35,650,'GameFontHighlightSmall')
    U.newRequest=N.Button(f,'New request',770,-31,130,function() U.Editor() end)
    U.board=N.Frame(nil,f,'InsetFrameTemplate');U.board:SetPoint('TOPLEFT',12,-64);U.board:SetSize(896,350)
    local board=U.board
    U.filterButton=N.Button(board,filters[1],12,-8,220,function()
        if MenuUtil and MenuUtil.CreateContextMenu then
            MenuUtil.CreateContextMenu(U.filterButton,function(_,root) for i,label in ipairs(filters) do local index=i;root:CreateRadio(label,function() return (U.filter or 1)==index end,function() U.filter=index;U.offset=0;U.Refresh() end) end end)
        else U.filter=(U.filter or 1)%#filters+1;U.offset=0;U.Refresh() end
    end)
    N.Label(board,'Item / target / claim',50,-42,315)
    N.Label(board,'Remaining',400,-42,80);N.Label(board,'Reward',495,-42,140);N.Label(board,'Status',665,-42,100)
    for i=1,8 do
        local row=CreateFrame('Button',nil,board);row:SetPoint('TOPLEFT',8,-62-(i-1)*32);row:SetSize(866,32);U.rows[i]=row
        local bg=row:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetColorTexture(1,1,1,i%2==0 and 0.025 or 0.055)
        row:SetHighlightTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight','ADD')
        row.selection=row:CreateTexture(nil,'ARTWORK');row.selection:SetAllPoints();row.selection:SetTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight');row.selection:SetBlendMode('ADD');row.selection:SetAlpha(0.3)
        row.icon=N.Icon(row,1,-1);row.title=N.Label(row,'',40,-2,340,'GameFontHighlightSmall');row.sub=N.Label(row,'',40,-17,340,'GameFontDisableSmall');row.title:SetHeight(15);row.title:SetWordWrap(false);row.sub:SetHeight(13);row.sub:SetWordWrap(false)
        row.qty=N.Label(row,'',392,-9,90,'GameFontHighlightSmall');row.money=N.Money(row,488,-10);row.state=N.Label(row,'',657,-9,90,'GameFontHighlightSmall')
        local function select() if row.object then local obj=G.db.objects[row.object.id];if obj then U.historySelection=U.tab==4 and row.object or nil;detail(obj,U.historySelection);U.Refresh() end end end
        row.action=N.Button(row,'Details',755,-4,100,select);row:RegisterForClicks('LeftButtonUp');row:SetScript('OnClick',N.Action('Details',select,row))
        row:SetScript('OnEnter',function(self) local value=self.object and G.db.objects[self.object.id];if value then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(G.Items.Label(value));GameTooltip:AddLine(G.Safe(G.DisplayOwner(value)),1,1,1);if value.kind=='pvp' then GameTooltip:AddLine(G.Safe(value.target.name)..' • '..G.Safe(value.target.ruleset or 'Context unavailable'),1,1,1) end;GameTooltip:Show() end end)
        row:SetScript('OnLeave',function() GameTooltip:Hide() end)
    end
    U.empty=N.Label(board,'',70,-145,720,'GameFontHighlight');U.empty:SetHeight(75);U.empty:SetJustifyH('CENTER')
    U.count=N.Label(board,'',12,-327,240,'GameFontDisableSmall')
    N.Button(board,'Previous',655,-323,102,function() U.offset=math.max(0,U.offset-8);U.Refresh() end)
    N.Button(board,'Next',765,-323,102,function() U.offset=U.offset+8;U.Refresh() end)
    board:EnableMouseWheel(true);board:SetScript('OnMouseWheel',function(_,delta) U.offset=U.offset-delta;U.Refresh() end)
    U.detail=N.Frame(nil,f,'InsetFrameTemplate');U.detail:SetPoint('TOPLEFT',12,-422);U.detail:SetSize(896,192)
    U.detailScroll=CreateFrame('ScrollFrame',nil,U.detail);U.detailScroll:SetPoint('TOPLEFT',12,-10);U.detailScroll:SetPoint('BOTTOMRIGHT',-22,40)
    U.detailChild=CreateFrame('Frame',nil,U.detailScroll);U.detailChild:SetSize(848,140);U.detailScroll:SetScrollChild(U.detailChild);U.detailChild:SetPoint('TOPLEFT',U.detailScroll,'TOPLEFT',0,0)
    U.detailText=N.Label(U.detailChild,'',0,0,840,'GameFontHighlightSmall');U.detailText:SetJustifyV('TOP');U.detailText:SetSpacing(3);U.detailText:SetHeight(130)
    U.detailScroll:EnableMouseWheel(true);U.detailScroll:SetScript('OnMouseWheel',function(self,d) self:SetVerticalScroll(math.max(0,math.min(self:GetVerticalScroll()-d*28,self:GetVerticalScrollRange()))) end)
    U.actions={};for i=1,4 do U.actions[i]=N.Button(U.detail,'',12,-155,126,function() end);U.actions[i]:Hide() end
    U.error=N.Label(f,'',16,-616,880,'GameFontRedSmall');U.error:SetHeight(14)
    f.numTabs=4;f.Tabs={}
    -- A native button footer avoids the Camelot tab art/text offsets that placed
    -- the selected label below the frame border on this installed client.
    for i,title in ipairs(names) do
        local index=i
        local tab=N.Button(f,title,18+(i-1)*145,-634,138,function()
            U.tab=index;U.offset=0;U.selected=nil;G.db.prefs.tab=index;if U.editor then U.CancelEditor() end
            U.board:Show();U.detail:Show();U.UpdateTabs();G.Refresh()
        end)
        f.Tabs[i]=tab;tab:SetID(i);tab:SetFrameLevel(f:GetFrameLevel()+20)
    end
    U.heart=G.Support.Button(f)
    U.tab=G.Int(G.db.prefs.tab,1,4) and G.db.prefs.tab or 1;U.UpdateTabs()
    f:SetScript('OnShow',U.Refresh);f:Hide()
    U.InstallLinkInput()
    -- Optional native chrome is initialized only after essential controls exist.
    U.detailBar=N.ScrollBar(U.detail,U.detailScroll)
    assert(U.detailText and U.error and #U.actions==4 and #f.Tabs==4,'Incomplete UI construction')
    U.ready=true
end
function U.UpdateTabs()
    for i,tab in ipairs(U.frame.Tabs or {}) do
        tab:Enable();tab:SetButtonState(i==U.tab and 'PUSHED' or 'NORMAL',false)
        if i==U.tab then tab:LockHighlight() else tab:UnlockHighlight() end
    end
end
function U.Toggle()
    if G.Tutorial and G.Tutorial.Require() then return end
    if not U.ready then
        local ok,err=pcall(U.Build)
        if not ok then if U.frame then U.frame:Hide() end;G.UIError('Build window',err);return end
    end
    U.frame:SetShown(not U.frame:IsShown())
end
function U.TestCOD()
    if G.Tutorial and G.Tutorial.Require() then return end
    local options={}
    for _,request in pairs(G.db.objects) do if request.kind=='request' and request.owner==G.me and request.state=='open' and G.Remaining(request)>0 then options[#options+1]={value=request.id,label=G.Items.Label(request)} end end
    table.sort(options,function(a,b) return a.value<b.value end)
    if #options==0 then G.Chat('Create an open item bounty first, then use /gbf testcod. No guild or second character is required.');return end
    if not U.codTest then
        local f=N.Frame('GuildBountyForeverCODTest',UIParent,'ButtonFrameTemplate');U.codTest=f;f:SetSize(590,510);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');N.Title(f,'Local COD mail test')
        if f.Inset then f.Inset:Hide() end
        f.request=N.Choice(f,'Your bounty',18,-46,540,{},function(key)
            local request=G.db.objects[key];if not request then return end
            f.quantity:SetText('1');local amount=math.floor(request.reward/request.quantity)
            f.gold:SetText(tostring(math.floor(amount/10000)));f.silver:SetText(tostring(math.floor(amount/100)%100));f.copper:SetText(tostring(amount%100))
            f:ShowText('Choose a quantity and COD price, then Preview. Preview is read-only. Start real mail test creates a real local claim and queues actual items for the mailbox; you click native Send. Your server must permit self-mail.')
        end)
        f.quantity=N.Edit(f,'Quantity',18,-104,100,'1',6);f.gold=N.Edit(f,'COD gold',152,-104,110,'0',8);f.silver=N.Edit(f,'Silver',292,-104,90,'0',2);f.copper=N.Edit(f,'Copper',412,-104,90,'0',2)
        f.preview=N.Button(f,'Preview only',18,-160,200,function()
            local quantity=G.Form.Integer(f.quantity:GetText(),1,100000);local gold=G.Form.Integer(f.gold:GetText(),0,10000000);local silver=G.Form.Integer(f.silver:GetText(),0,99);local copper=G.Form.Integer(f.copper:GetText(),0,99)
            if not quantity or not gold or not silver or not copper then f:ShowText('Enter a valid quantity and price. Silver/copper must be 0–99.');return end
            local plan,err=G.Mail.TestPlan(G.db.objects[f.request:GetValue()],quantity,gold*10000+silver*100+copper)
            if not plan then f:ShowText(err);return end
            local lines={'TEST PREVIEW - sending disabled','Recipient: '..G.Safe(plan.recipient),'COD: '..money(plan.amount)..' • Quantity: '..plan.quantity,'Planned attachments:'}
            for index,item in ipairs(plan.items) do
                local info=G.Items.Info(item.link or item.id)
                lines[#lines+1]=index..'. '..(info and info.link or ('Item #'..item.id))..' x'..item.count..' • bag '..item.bag..', slot '..item.slot..(item.count<item.total and (' • split '..item.count..' from '..item.total..', leave '..(item.total-item.count)) or ' • whole stack')
            end
            lines[#lines+1]='No items moved. No native mail draft changed. No claim/payment recorded.'
            f:ShowText(table.concat(lines,'\n'))
            if PlaySound and SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN then PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN,'Master') end
        end)
        f.start=N.Button(f,'Start real mail test',240,-160,230,function()
            local quantity=G.Form.Integer(f.quantity:GetText(),1,100000);local gold=G.Form.Integer(f.gold:GetText(),0,10000000);local silver=G.Form.Integer(f.silver:GetText(),0,99);local copper=G.Form.Integer(f.copper:GetText(),0,99)
            if not quantity or not gold or not silver or not copper then f:ShowText('Enter a valid quantity and COD price.');return end
            local claim,err=G.Mail.StartSelfTest(G.db.objects[f.request:GetValue()],quantity,gold*10000+silver*100+copper)
            if not claim then f:ShowText(err);return end
            f:Hide();U.OpenRecord(claim);U.frame:Hide()
        end)
        f.scroll=CreateFrame('ScrollFrame',nil,f);f.scroll:SetPoint('TOPLEFT',18,-202);f.scroll:SetSize(550,238)
        f.content=CreateFrame('Frame',nil,f.scroll);f.content:SetSize(528,238);f.scroll:SetScrollChild(f.content)
        f.output=N.Label(f.content,'',0,0,528,'GameFontHighlightSmall');f.output:SetHeight(238)
        function f:ShowText(text)
            self.output:SetText(text);local height=math.max(238,self.output:GetStringHeight()+12);self.output:SetHeight(height);self.content:SetHeight(height);self.scroll:SetVerticalScroll(0)
        end
        f.scroll:EnableMouseWheel(true);f.scroll:SetScript('OnMouseWheel',function(_,delta) f.scroll:SetVerticalScroll(math.max(0,math.min(math.max(0,f.content:GetHeight()-238),f.scroll:GetVerticalScroll()-delta*28))) end)
        N.Button(f,'Close test',18,-450,200,function() f:Hide() end)
    end
    local f=U.codTest;f.request:SetOptions(options);local selected=U.selected
    local found=false;for _,option in ipairs(options) do if option.value==selected then found=true end end
    local id=found and selected or options[1].value;f.request:SetValue('',true);f.request:SetValue(id);f:Show()
end
function U.ShowMailTask()
    if G.Tutorial and G.Tutorial.Require() then return end
    local pending=G.Mail.waiting
    if not pending or not MailFrame or not MailFrame:IsShown() then if U.mailTask then U.mailTask:Hide() end;return end
    if not U.mailTask then
        local f=N.Frame('GuildBountyForeverMailTask',UIParent,'ButtonFrameTemplate');U.mailTask=f;f:SetSize(350,210);f:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-30,-160);f:SetFrameStrata('DIALOG');N.Title(f,'Bounty mail delivery')
        if f.Inset then f.Inset:Hide() end
        f.text=N.Label(f,'',18,-48,314,'GameFontHighlightSmall');f.text:SetHeight(100)
        f.prepare=N.Button(f,'Prepare delivery',18,-160,190,function() local ok,err=G.Mail.Prepare();if not ok then f.text:SetText(err or 'Unable to prepare delivery.') end end)
        N.Button(f,'Later',220,-160,110,function() f:Hide() end)
    end
    local claim=G.db.objects[pending.claim];local parent=claim and G.db.objects[claim.parent]
    if not parent then G.Mail.waiting=nil;U.mailTask:Hide();return end
    U.mailTask.text:SetText((G.Mail.IsSelfTest(claim,parent) and 'REAL SELF-MAIL TEST\n' or '')..claim.quantity..' items to '..G.Safe(G.DisplayOwner(parent))..'\nCOD: '..money(pending.amount)..'\nPrepare attaches the items and fills the draft. Review it and manually click the native Send button.');U.mailTask:Show()
end
G.Mail.ShowTask=U.ShowMailTask
function U.COD(claim)
    if G.Tutorial and G.Tutorial.Require() then return end
    local parent=G.db.objects[claim.parent];if not parent then return end
    if not U.cod then
        local f=N.Frame('GuildBountyForeverCOD',UIParent,'ButtonFrameTemplate');U.cod=f;f:SetSize(410,230);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');N.Title(f,'Prepare bounty COD')
        if f.Inset then f.Inset:Hide() end
        f.text=N.Label(f,'',18,-48,374,'GameFontHighlightSmall');f.text:SetHeight(52)
        f.gold=N.Edit(f,'Gold',18,-109,110,'0',8);f.silver=N.Edit(f,'Silver',156,-109,80,'0',2);f.copper=N.Edit(f,'Copper',266,-109,80,'0',2)
        N.Button(f,'Use COD mail',18,-182,170,function()
            local gold=G.Form.Integer(f.gold:GetText(),0,10000000);local silver=G.Form.Integer(f.silver:GetText(),0,99);local copper=G.Form.Integer(f.copper:GetText(),0,99)
            if not gold or not silver or not copper then f.text:SetText('Enter a valid COD amount. Silver and copper must be 0–99.');return end
            local ok,err=G.Mail.Queue(f.claim,gold*10000+silver*100+copper)
            if ok then f:Hide();if U.frame then U.frame:Hide() end else f.text:SetText(err) end
        end)
        N.Button(f,'Cancel',218,-182,170,function() f:Hide() end)
    end
    local f=U.cod;f.claim=claim;local amount=math.floor(parent.reward*claim.quantity/parent.quantity)
    f.gold:SetText(tostring(math.floor(amount/10000)));f.silver:SetText(tostring(math.floor(amount/100)%100));f.copper:SetText(tostring(amount%100))
    f.text:SetText(claim.quantity..' items → '..G.Safe(G.DisplayOwner(parent))..'\nSuggested proportional COD. Edit to the agreed price. Go to a mailbox, open mail and click Prepare delivery. Then review and manually click Send.');f:Show()
end
function U.OpenRecord(o)
    if G.Tutorial and G.Tutorial.Require() then return end
    if not U.ready then local ok,err=pcall(U.Build);if not ok then G.UIError('Open bounty',err);return end end
    if U.editor and U.editor:IsShown() then U.CancelEditor() end
    U.tab=o.kind=='claim' and 3 or o.kind=='pvp' and 2 or 1;U.filter=1;U.selected=o.id;U.offset=0
    G.db.prefs.tab=U.tab;U.frame:Show();U.board:Show();U.detail:Show();U.UpdateTabs()
    local list=collect();for index,value in ipairs(list) do if value.id==o.id then U.offset=math.floor((index-1)/8)*8;break end end
    U.Refresh()
end
function U.ShowOffer()
    if G.Tutorial and (G.Tutorial.active or not G.Tutorial.Complete()) then return end
    if not G.offers or #G.offers==0 then if U.offer then U.offer:Hide() end return end
    if not U.offer then
        local f=N.Frame('GuildBountyForeverOffer',UIParent,'ButtonFrameTemplate');U.offer=f;f:SetSize(400,190);f:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-40,-180);f:SetFrameStrata('DIALOG');N.Title(f,'Guild Bounty match')
        if f.Inset then f.Inset:Hide() end
        f.text=N.Label(f,'',18,-48,364,'GameFontHighlightSmall');f.text:SetHeight(90)
        local function pop(target)
            if type(target)=='table' and target.object then for index,offer in ipairs(G.offers) do if offer==target then table.remove(G.offers,index);break end end else table.remove(G.offers,1) end
            U.ShowOffer()
        end
        f.primary=N.Button(f,'Arrange delivery',20,-238,155,function()
            local v=G.offers[1];local o=v and G.db.objects[v.object];if not o then pop();return end
            if o.owner==G.me then U.OpenRecord(o);pop();return end
            if o.kind=='request' then
                -- Build the main UI before creating a claim so validation errors are visible.
                U.OpenRecord(o)
                U.Quantity(o,v.evidence,v.quantity,function(claim) U.OpenRecord(claim);pop(v);U.COD(claim) end)
            else
                local claim,err=G.Accept(o,v.evidence,v.quantity)
                if claim then U.OpenRecord(claim);pop() else G.Chat(err) end
            end
        end)
        f.view=N.Button(f,'View bounty',184,-238,135,function() local v=G.offers[1];local o=v and G.db.objects[v.object];if o then if o.owner==G.me and IsInGuild and not IsInGuild() then U.selected=o.id;U.TestCOD() else U.OpenRecord(o) end end end)
        f.dismiss=N.Button(f,'Later',328,-238,135,pop)
        if f.CloseButton then f.CloseButton:SetScript('OnClick',pop) end
    end
    local v=G.offers[1];local o=G.db.objects[v.object]
    if not o or o.state~='open' or G.Remaining(o)<=0 then table.remove(G.offers,1);U.ShowOffer();return end
    local own=o.owner==G.me
    U.offer.primary:SetText(own and 'Open my bounty' or o.kind=='pvp' and 'Prepare claim' or 'Arrange delivery')
    local icon,rank
    if o.kind=='pvp' then icon,rank=G.PvP.Art(o.target) else local info=G.Items.Info(v.evidence.link or v.evidence.itemID or o.itemID);icon=info and info.icon or 'Interface\\Icons\\INV_Misc_QuestionMark' end
    if U.offer.SetPortraitToAsset then U.offer:SetPortraitToAsset(icon) elseif U.offer.PortraitContainer and U.offer.PortraitContainer.portrait then U.offer.PortraitContainer.portrait:SetTexture(icon) else
        if not U.offer.matchIcon then U.offer.matchIcon=U.offer:CreateTexture(nil,'ARTWORK');U.offer.matchIcon:SetSize(40,40);U.offer.matchIcon:SetPoint('TOPLEFT',-4,5) end
        U.offer.matchIcon:SetTexture(icon)
    end
    local lines={G.Items.Label(o),G.Safe(G.DisplayOwner(o))..' • Reward: '..money(o.reward)}
    if rank then lines[#lines+1]=rank end
    lines[#lines+1]='Found: '..tostring(v.quantity or 1)..' • Still needed: '..G.Remaining(o)..' / '..o.quantity
    if o.note~='' then lines[#lines+1]=G.Safe(#o.note>100 and o.note:sub(1,100)..'…' or o.note) end
    lines[#lines+1]=own and 'Your bounty matched. Open it to review or close.' or o.kind=='pvp' and 'Prepare a claim for review.' or 'Choose quantity, then prepare a COD delivery.'
    U.offer.text:SetText(table.concat(lines,'\n'));local height=math.max(76,U.offer.text:GetStringHeight()+6);U.offer.text:SetHeight(height);U.offer:SetHeight(height+100)
    local localTest=own and IsInGuild and not IsInGuild() and o.kind=='request'
    U.offer.view:SetText(localTest and 'Test delivery' or 'View bounty');U.offer.view:SetShown(not own or localTest)
    if own and not localTest then
        U.offer.primary:SetWidth(220);U.offer.primary:ClearAllPoints();U.offer.primary:SetPoint('TOPLEFT',18,-height-62)
        U.offer.dismiss:SetWidth(126);U.offer.dismiss:ClearAllPoints();U.offer.dismiss:SetPoint('TOPLEFT',256,-height-62)
    else
        for index,button in ipairs({U.offer.primary,U.offer.view,U.offer.dismiss}) do button:SetWidth(116);button:ClearAllPoints();button:SetPoint('TOPLEFT',18+(index-1)*124,-height-62) end
    end
    U.offer:Show()
end
