local _,G=...
G.Tutorial={version=2};local T,N,U=G.Tutorial,G.Native,G.UI
local meat='Interface\\Icons\\INV_Misc_Food_16'
local cloth='Interface\\Icons\\INV_Fabric_Linen_01'
T.steps={
    {title='Welcome — this is the real addon window',text='This tour uses example listings inside Guild Bounty. The gold outline and arrow show where to look. Nothing here publishes a request, moves an item or sends mail. Click Next to begin.',phase='board',target='status'},
    {title='Click Requests',text='This button shows open item bounties. Click the highlighted Requests button.',phase='board',target='requests',click=true},
    {title='Inspect an example listing',text='Boar Ribs: Ayla wants 10 and promises 2 gold in total. The icon, remaining quantity, reward and status make up a listing. Click its Details button.',phase='board',target='details',click=true},
    {title='This is the details panel',text='Details shows the full note and contract. The buttons below are actions for this listing. Read the demo note, then click Next.',phase='details',target='detail',coach='top'},
    {title='Accept the request',text='Accept request starts a claim: your intention to supply items. It does not deliver or pay anything. Click Accept request on this example.',phase='details',target='accept',click=true,coach='top'},
    {title='A matching drop opens this prompt',text='Finding a matching item shows the bounty and requester. Click Arrange delivery in this demo prompt. Later would dismiss it without accepting.',phase='match',target='match',click=true},
    {title='Choose how much to deliver',text='This is the quantity choice. The sample has 10 items remaining. Enter a number from 1 to 10, then click Accept demo. A smaller amount means a partial delivery.',phase='quantity',target='quantity',click=true},
    {title='Follow your claim in Mine',text='Mine contains your listings, your claims and submissions to review. Click Mine to see the example claim you just accepted.',phase='claim',target='mine',click=true},
    {title='Arrange mail instead of meeting',text='This accepted claim needs delivery. Contact requester opens a whisper draft in normal use. Click Mail COD here to practise mailing it.',phase='claim',target='mailcod',click=true,coach='top'},
    {title='Review the COD price',text='The reward is for the entire request. Partial delivery suggests a proportional amount; agree it with the requester. Check the example price and click Use COD mail.',phase='price',target='price',click=true},
    {title='Go to a mailbox',text='In normal play you must travel to a mailbox and open it. Click Open demo mailbox to simulate arriving. This does not open or change the game’s actual mail.',phase='mailbox',target='mailbox',click=true},
    {title='Prepare the delivery',text='At an open mailbox, this button selects matching stacks, splits the quantity, and fills recipient and COD. Click Prepare demo to see those fields filled.',phase='prepare',target='prepare',click=true},
    {title='Review, then manually Send',text='Check the requester, attachment quantity and COD amount. Normal delivery requires the game’s Send click. Click Send demo: this only changes the training example.',phase='send',target='send',click=true},
    {title='Now you are the requester',text='This example delivery has arrived. In normal mail you inspect it and accept the COD charge yourself. Click Accept demo COD to collect the example items.',phase='receive',target='receive',click=true},
    {title='Receipt and payment are automatic',text='The example claim is now paid. In real use, confirmed collection records receipt/COD automatically and shares it with the supplier. Every claimed item must be received. No extra Record paid click is needed.',phase='paid',target='detail',coach='top'},
    {title='Create your own listing',text='Now practise the other side. Click New request. You will get a separate practice form; your real requests and any unsaved draft are preserved.',phase='paid',target='new',click=true,coach='left'},
    {title='Exact Item selects one specific item',text='Click Exact Item. The example is Linen Cloth. In real use you can enter an ID, paste a link, shift-click or drop an item into this field.',phase='exact',target='exact',click=true},
    {title='These fields set the deal',text='Quantity is how many items you want. Gold, silver and copper are the total promised reward; Note gives delivery terms. These sample values can be changed without creating a real listing. Click Next when ready.',phase='exact',target='reward'},
    {title='Save opens a confirmation',text='Click Save to review this demo listing. In normal use, the confirmation is the point where you agree to publish the request.',phase='exact',target='save',click=true},
    {title='Confirm the example listing',text='Review the example quantity and reward. Click Confirm demo to add it to the practice board. No real record or guild message will be created.',phase='confirm',target='confirm',click=true},
    {title='Request a type of item instead',text='Click Rule Request. It uses named dropdowns rather than an item ID. All selected criteria must match.',phase='rule',target='rule',click=true},
    {title='Choose rules and character levels',text='Try the Item type, Subtype and Equipment slot dropdowns. Changing type resets subtype. Character-level limits mean the level required to use the item, not item level. Empty limits mean unrestricted. Click Next to practise stats.',phase='rule',target='criteria'},
    {title='Apply a stat',text='Strength ≥ 10 is ready as an example. You can change the stat or limits. Click Apply stat: the sound and separate locked row confirm it is selected.',phase='stat1',target='apply',click=true},
    {title='Add another stat',text='Stamina ≥ 8 is ready next. Click Apply stat again. It adds a second row instead of replacing Strength. In normal use, choose each additional stat from the picker.',phase='stat2',target='apply',click=true},
    {title='Each stat has its own row',text='Your two selected stats are shown below. Edit unlocks that row; Remove affects only that stat. Extra rows use scroll/Previous/Next. Apply any unfinished entry before saving.',phase='statsdone',target='statrows'},
    {title='PvP Target is a different listing type',text='Click PvP Target. Enter a full opposing player name or use a hostile player target. It uses kill evidence and manual payment rather than COD items.',phase='pvp',target='pvp',click=true},
    {title='This is the target field',text='The sample name is Ragnar Darkwood. Publicly available class, faction and rank can appear on a real prompt. Combat detection depends on what Forever exposes; /gbf status reports availability. Nothing here targets a real player.',phase='pvp',target='target'},
    {title='Browse PvP examples',text='Click PvP Bounties to see an example target listing. Details normally shows observed identity and available evidence.',phase='pvpboard',target='pvptab',click=true},
    {title='Use Mine to find your work',text='Click Mine. This example shows your created listing and a completed delivery. Real pending requests, claims and reviews stay here between sessions.',phase='mine',target='mine',click=true},
    {title='Filter personal activity',text='This button filters Mine: all activity, waiting for review, created by me, my claims or completed. Click it to show the example Completed filter.',phase='mine',target='filter',click=true},
    {title='This is the Completed filter',text='Only completed example claims are shown now. The same filter button can show pending reviews, your listings or your claims in normal use. Click Next to see History.',phase='minecompleted',target='filter'},
    {title='History keeps the changes',text='Click History. These sample entries show a listing, a sent delivery and a completed receipt. Real history is retained when a request closes.',phase='history',target='history',click=true},
    {title='You are ready to use Guild Bounty',text='Finish removes every demo and restores your real board/draft. /gbf help replays this tour. /gbf matches checks held items; /gbf testcod has explicit preview and real local-mail tests. Guildmates share records; without a guild, records stay local. Both sides should run the current addon.',phase='history',target='status'},
}
T.pages=T.steps -- Stable step count for saved progress and diagnostics.
local function prefs() return G.root and G.root.prefs end
function T.Complete() local p=prefs();return p and type(p.tutorial)=='table' and p.tutorial.version==T.version and p.tutorial.completed==true end
function T.Progress()
    local p=prefs();if not p then return end
    if type(p.tutorial)~='table' or p.tutorial.version~=T.version then p.tutorial={version=T.version,step=1,completed=false} end
    return p.tutorial
end
local function sound() if PlaySound and SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN then PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN,'Master') end end
local function hideStages() for _,f in pairs(T.stages or {}) do f:Hide() end end
local function stage(key,title,width,height)
    T.stages=T.stages or {};local f=T.stages[key]
    if not f then
        f=N.Frame(nil,U.frame,'ButtonFrameTemplate');T.stages[key]=f;f:SetSize(width,height);f:SetPoint('TOPLEFT',U.frame,'TOPLEFT',230,-120);f:SetFrameStrata('DIALOG');f:SetFrameLevel(90);N.Title(f,title..' • DEMO');if f.SetPortraitToAsset then f:SetPortraitToAsset(key=='confirm' and cloth or key=='mailbox' and 'Interface\\MailFrame\\Mail-Icon' or meat) end
        if f.Inset then f.Inset:Hide() end
        if f.CloseButton then f.CloseButton:SetScript('OnClick',function() T.Pause() end) end
        f.text=N.Label(f,'',18,-48,width-36,'GameFontHighlightSmall');f.text:SetHeight(height-100)
    end
    f:Show();return f
end
function T.Advance()
    if not T.active or T.step>=#T.steps then return end
    T.step=T.step+1;if T.required then T.Progress().step=T.step end;T.Render()
end
function T.Route(control,label)
    if not T.active or T.internal then return false end
    if control and (type(control)=='table' or type(control)=='userdata') and control.tourControl then return false end
    local phase=T.steps[T.step].phase
    if (phase=='rule' or phase=='stat1' or phase=='stat2' or phase=='statsdone') and (label=='Item type' or label=='Subtype' or label=='Equipment slot' or label=='Add stat requirement') then return false end
    if phase=='statsdone' and U.editor then
        if control==U.editor.statApply or control==U.editor.statPrevious or control==U.editor.statNext then return false end
        for _,row in ipairs(U.editor.statRows) do if control==row.edit or control==row.remove then return false end end
    end
    if control and control==T.target and T.steps[T.step].click then
        if T.steps[T.step].target=='apply' then T.beforeApplyCount=0;for _ in pairs(U.editor.statRules) do T.beforeApplyCount=T.beforeApplyCount+1 end;return false end -- Apply edits only the separate practice form.
        if T.steps[T.step].target=='quantity' then
            local n=G.Form.Integer(T.stages.quantity.amount:GetText(),1,10);if not n then T.frame.text:SetText('Enter a whole quantity from 1 to 10, then Accept demo.');return true end;T.quantity=n
        elseif T.steps[T.step].target=='filter' then T.completedFilter=true
        elseif T.steps[T.step].target=='save' then
            local e=U.editor;local quantity=G.Form.Integer(e.quantity:GetText(),1,100000);local gold=G.Form.Integer(e.gold:GetText(),0,10000000);local silver=G.Form.Integer(e.silver:GetText(),0,99);local copper=G.Form.Integer(e.copper:GetText(),0,99)
            if not quantity or not gold or not silver or not copper then T.frame.text:SetText('Enter a valid quantity and reward; silver/copper must be 0–99. Then click Save again.');return true end
            T.draft={name='Linen Cloth',quantity=quantity,reward=gold*10000+silver*100+copper}
        elseif T.steps[T.step].target=='confirm' then T.created=true;T.createdDemo=G.Copy(T.draft);sound()
        elseif T.steps[T.step].target=='receive' then T.paid=true;sound()
        elseif T.steps[T.step].target=='send' then T.sent=true end
        T.Advance();return true
    end
    if not control then return true end -- Only the explicitly allowed practice dropdown callbacks may run without a control.
    if T.frame then T.frame.count:SetText('DEMO TOUR • follow the highlighted control') end
    return true -- Other addon buttons cannot perform live actions during a practice tour.
end
function T.AfterAction(control)
    if control~=T.target or not T.steps[T.step] or T.steps[T.step].target~='apply' then return end
    local count=0;for _ in pairs(U.editor.statRules) do count=count+1 end
    if count>(T.beforeApplyCount or count) then if T.steps[T.step].phase=='stat1' then T.firstStats=G.Copy(U.editor.statRules) else T.finishedStats=G.Copy(U.editor.statRules) end;T.Advance() end
end
local function detailText(text)
    U.detailText:SetText(text);local height=math.max(130,U.detailText:GetStringHeight()+12);U.detailText:SetHeight(height);U.detailChild:SetHeight(height+12);U.detailScroll:SetVerticalScroll(0)
end
function T.RenderDemo()
    if not T.active or not U.ready then return end
    local phase=T.steps[T.step].phase
    local board=phase=='board' or phase=='details' or phase=='match' or phase=='quantity' or phase=='claim' or phase=='paid' or phase=='pvpboard' or phase=='mine' or phase=='minecompleted' or phase=='history'
    if not board then U.board:Hide();U.detail:Hide();return end
    if U.editor then U.editor:Hide() end;U.board:Show();U.detail:Show()
    U.tab=(phase=='pvpboard' and 2) or ((phase=='claim' or phase=='paid' or phase=='mine' or phase=='minecompleted') and 3) or (phase=='history' and 4) or 1;U.UpdateTabs()
    local rows
    if U.tab==2 then rows={{name='Ragnar Darkwood',owner='Ayla Oakheart • demo PvP target',qty='1 / 1',reward=50000,status='open',icon='Interface\\Icons\\ClassIcon_warrior'}}
    elseif U.tab==4 then rows={{name='Linen Cloth • demo listing created',owner='You • example history',qty='rev 1',reward=10000,status='created',icon=cloth},{name='Boar Ribs • delivery sent',owner='You → Ayla Oakheart • example',qty=tostring(T.quantity),reward=0,status='sent',icon=meat},{name='Boar Ribs • COD received',owner='Ayla Oakheart • example',qty=tostring(T.quantity),reward=0,status='paid',icon=meat}}
    elseif U.tab==3 then rows={{name='Boar Ribs • your demo claim',owner='For Ayla Oakheart • example only',qty=tostring(T.quantity),reward=T.quantity*2000,status=T.paid and 'paid' or 'accepted',icon=meat},{name=(T.createdDemo and T.createdDemo.name or 'Linen Cloth')..' • your demo listing',owner='You • not published',qty=T.createdDemo and (T.createdDemo.quantity..' / '..T.createdDemo.quantity) or '5 / 5',reward=T.createdDemo and T.createdDemo.reward or 10000,status='open',icon=cloth}}
    else rows={{name='[Boar Ribs]',owner='Ayla Oakheart • demo requester',qty='10 / 10',reward=20000,status='open',icon=meat},{name='Armor • Plate • Strength ≥ 10',owner='Mira Dawnforge • demo rule request',qty='1 / 1',reward=100000,status='open',icon='Interface\\Icons\\INV_Chest_Plate04'},{name='[Linen Cloth]',owner='Borin Stonehand • demo requester',qty='20 / 20',reward=10000,status='open',icon=cloth}} end
    if phase=='minecompleted' then rows={rows[1]} end
    U.empty:Hide();U.filterButton:SetShown(U.tab==3);U.filterButton:SetText(T.completedFilter and 'Completed • DEMO' or 'All personal activity • DEMO')
    U.count:SetText(#rows..' example listings • DEMO ONLY')
    for index,row in ipairs(U.rows) do
        local v=rows[index];row.object=nil
        if v then row:Show();row.title:SetText(v.name);row.sub:SetText(v.owner);row.qty:SetText(v.qty);row.state:SetText(v.status);row.money:Show();row.money:SetAmount(v.reward);row.icon.icon:SetTexture(v.icon);row.action:SetText(U.tab==4 and 'Inspect' or 'Details');row.selection:SetShown(index==1 and phase~='board') else row:Hide() end
    end
    for _,b in ipairs(U.actions) do b:Hide() end
    if phase=='details' or phase=='match' or phase=='quantity' then
        detailText('DEMO BOUNTY: Boar Ribs\nRequester: Ayla Oakheart\nRemaining: 10 / 10 • Total reward: '..G.Money(20000)..'\nNote: Send fresh ribs by COD. Agree a price for partial delivery.\nThis example is not in your saved records.')
        U.actions[1]:SetText('Accept request');U.actions[1]:Show()
    elseif phase=='claim' then
        detailText('DEMO CLAIM: '..T.quantity..' Boar Ribs for Ayla Oakheart\nStatus: accepted — not delivered or paid\nSuggested partial reward: '..G.Money(T.quantity*2000)..'\nNext: agree the price and arrange Mail COD.')
        U.actions[1]:SetText('Mail COD');U.actions[1]:Show()
    elseif phase=='paid' or phase=='mine' or phase=='minecompleted' then
        detailText('DEMO CLAIM: Boar Ribs\nSent: '..T.quantity..' items • Received: '..T.quantity..' / '..T.quantity..'\nCOD accepted: '..G.Money(T.quantity*2000)..' • Status: paid\nReceipt/payment recorded automatically.\nRequester remaining: '..(10-T.quantity)..' / 10. No real payment occurred.')
    elseif phase=='history' then detailText('DEMO HISTORY\nListing created → delivery sent → requester received and paid.\nReal history retains changes and completed requests.\nThese examples will disappear when you finish or pause the tour.')
    elseif phase=='pvpboard' then detailText('DEMO PVP TARGET: Ragnar Darkwood\nOpposing player • full name and surname\nReward: '..G.Money(50000)..' • Quantity: 1\nReadable kill evidence can prepare a claim; unavailable combat/rank data is not invented. Review and payment are separate from item COD.')
    else detailText('DEMO TOUR — choose the highlighted control.\nThese are sample listings, not guild requests. Real saved records and drafts are preserved.') end
end
function T.Editor(mode)
    T.internal=true
    if not U.editor then U.Editor() end
    U.editor.existing=nil;U.SetMode(mode);T.internal=false
    U.board:Hide();U.detail:Hide();U.editor:Show()
    return U.editor
end
function T.PrepareStep()
    local phase=T.steps[T.step].phase;hideStages()
    if phase=='exact' or phase=='confirm' then
        local e=T.Editor(1)
        if not T.exactReady then e.item:SetText('2589');e.quantity:SetText('5');e.gold:SetText('1');e.silver:SetText('0');e.copper:SetText('0');e.note:SetText('Practice listing only — not published.');T.exactReady=true end
        e.itemSlot.icon:SetTexture(cloth);e.itemPreview:SetText('[Linen Cloth] • DEMO');e.itemInfo:SetText('Example item preview • not an inventory item')
    elseif phase=='rule' or phase=='stat1' or phase=='stat2' or phase=='statsdone' then
        local e=T.Editor(2)
        if not T.ruleReady then e.class:SetValue('4');e.subclass:SetValue('4');e.slot:SetValue('INVTYPE_CHEST');e.required:SetText('10');e.maxRequired:SetText('40');T.ruleReady=true end
        if phase=='stat1' then
            e.statRules={};e.statOrder={};e.statOffset=0;U.StatSummary();e.stat:SetValue('ITEM_MOD_STRENGTH_SHORT',true);e.statMin:SetText('10');e.statMax:SetText('')
        elseif phase=='stat2' or phase=='statsdone' then
            e.statRules=G.Copy(phase=='stat2' and (T.firstStats or {ITEM_MOD_STRENGTH_SHORT={min=10}}) or (T.finishedStats or {ITEM_MOD_STRENGTH_SHORT={min=10},ITEM_MOD_STAMINA_SHORT={min=8}}));e.statOrder={};for key in pairs(e.statRules) do e.statOrder[#e.statOrder+1]=key end;table.sort(e.statOrder);e.statOffset=0;U.StatSummary()
            if phase=='stat2' then local key=e.statRules.ITEM_MOD_STAMINA_SHORT and 'ITEM_MOD_AGILITY_SHORT' or 'ITEM_MOD_STAMINA_SHORT';e.stat:SetValue(key,true);e.statMin:SetText('8');e.statMax:SetText('') else e.stat:SetValue('',true);e.statMin:SetText('');e.statMax:SetText('') end
        end
    elseif phase=='pvp' then local e=T.Editor(3);e.target:SetText('Ragnar Darkwood')
    else T.RenderDemo() end
    if phase=='match' then
        local f=stage('match','Bounty match',400,210);f.text:SetText('[Boar Ribs] • DEMO\nAyla Oakheart • wants 10 • reward '..G.Money(20000)..'\nYour example loot matches this bounty.')
        if not f.go then f.go=N.Button(f,'Arrange delivery',18,-160,220,function() end) end
    elseif phase=='quantity' then
        local f=stage('quantity','Choose delivery quantity',400,210);f.text:SetText('How many Boar Ribs will you deliver?\nThis example has 10 remaining.')
        if not f.amount then f.amount=N.Edit(f,'Quantity',18,-96,130,'3',6);f.go=N.Button(f,'Accept demo',180,-150,195,function() end) end;f.amount:SetText(tostring(T.quantity))
    elseif phase=='price' then
        local f=stage('price','Delivery price',420,220);f.text:SetText('Recipient: Ayla Oakheart\nQuantity: '..T.quantity..' Boar Ribs\nSuggested COD: '..G.Money(T.quantity*2000)..'\nAgree partial prices before sending.')
        if not f.go then f.go=N.Button(f,'Use COD mail',18,-170,250,function() end) end
    elseif phase=='mailbox' then
        local f=stage('mailbox','Visit a mailbox',420,210);f.text:SetText('In normal play, go to a mailbox and open it.\n\nThis practice mailbox never touches native mail.')
        if not f.go then f.go=N.Button(f,'Open demo mailbox',18,-160,250,function() end) end
    elseif phase=='prepare' or phase=='send' or phase=='receive' then
        local f=stage('mail','Mail delivery',450,280)
        local prepared=phase~='prepare'
        f.text:SetText(prepared and ('To: Ayla Oakheart\nSubject: DEMO delivery\nAttachment: '..T.quantity..' x Boar Ribs\nCOD: '..G.Money(T.quantity*2000)..'\n'..(phase=='receive' and 'Requester view: inspect, accept COD and collect.' or 'Supplier view: verify everything before Send.')) or 'To: —\nSubject: —\nAttachments: none\nCOD: —\nClick Prepare demo to fill this example.')
        if not f.go then f.go=N.Button(f,'Prepare demo',18,-230,280,function() end) end
        f.go:SetText(phase=='prepare' and 'Prepare demo' or phase=='send' and 'Send demo' or 'Accept demo COD')
    elseif phase=='confirm' then
        local f=stage('confirm','Confirm listing',420,220);local e=U.editor
        f.text:SetText('Publish example: Linen Cloth\nQuantity: '..e.quantity:GetText()..'\nReward: '..e.gold:GetText()..' gold '..e.silver:GetText()..' silver '..e.copper:GetText()..' copper\nThis creates a demo only.')
        if not f.go then f.go=N.Button(f,'Confirm demo',18,-170,250,function() end) end
    end
end
function T.Target()
    local key=T.steps[T.step].target
    if key=='status' then return U.status elseif key=='requests' then return U.frame.Tabs[1] elseif key=='details' then return U.rows[1].action
    elseif key=='detail' then return U.detailText elseif key=='accept' or key=='mailcod' then return U.actions[1]
    elseif key=='mine' then return U.frame.Tabs[3] elseif key=='new' then return U.newRequest
    elseif key=='exact' then return U.editor.modeButtons[1] elseif key=='reward' then return U.editor.gold elseif key=='save' then return U.editor.saveButton
    elseif key=='rule' then return U.editor.modeButtons[2] elseif key=='criteria' then return U.editor.class elseif key=='apply' then return U.editor.statApply
    elseif key=='statrows' then return U.editor.statPanel elseif key=='pvp' then return U.editor.modeButtons[3] elseif key=='target' then return U.editor.target
    elseif key=='pvptab' then return U.frame.Tabs[2] elseif key=='filter' then return U.filterButton elseif key=='history' then return U.frame.Tabs[4]
    elseif key=='prepare' or key=='send' or key=='receive' then return T.stages.mail.go
    else return T.stages[key] and T.stages[key].go end
end
function T.Render()
    if not T.active or T.rendering then return end;T.rendering=true
    local ok,err=pcall(function()
        T.PrepareStep();local step=T.steps[T.step];T.target=T.Target();local f=T.frame
        f.heading:SetText(step.title);f.text:SetText(step.text);f.count:SetText('DEMO TOUR • '..T.step..' / '..#T.steps)
        local textHeight=math.max(65,f.text:GetStringHeight()+4);f.text:SetHeight(textHeight);local height=textHeight+121;f:SetHeight(height)
        f:ClearAllPoints();if step.coach=='top' then f:SetPoint('TOPLEFT',U.frame,'TOPLEFT',26,-100) elseif step.coach=='left' then f:SetPoint('BOTTOMLEFT',U.frame,'BOTTOMLEFT',26,48) else f:SetPoint('BOTTOMRIGHT',U.frame,'BOTTOMRIGHT',-20,48) end
        f.previous:ClearAllPoints();f.previous:SetPoint('BOTTOMLEFT',f,'BOTTOMLEFT',14,10);f.next:ClearAllPoints();f.next:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',-14,10)
        f.next:SetText(T.step==#T.steps and 'Finish' or step.click and 'Click highlighted control' or 'Next');N.Enabled(f.next,not step.click);N.Enabled(f.previous,T.step>1)
        T.highlight:ClearAllPoints();T.highlight:SetPoint('TOPLEFT',T.target,'TOPLEFT',-5,5);T.highlight:SetPoint('BOTTOMRIGHT',T.target,'BOTTOMRIGHT',5,-5);T.highlight:Show()
        T.arrow:ClearAllPoints();T.arrow:SetPoint('BOTTOM',T.target,'TOP',0,8);T.arrow:Show();f:Show();U.frame:Show()
        U.status:SetText('DEMO TOUR • example listings only • no real requests, mail or gold changed')
    end)
    T.rendering=false;if not ok then T.Pause();G.UIError('Interactive tour',err) end
end
function T.Restore()
    T.active=false;hideStages();if T.frame then T.frame:Hide();T.highlight:Hide();T.arrow:Hide() end
    local saved=T.saved;if not saved then return end
    T.demoEditor=U.editor;if U.editor then U.editor:Hide() end;U.editor=saved.editor
    U.tab=saved.tab;U.offset=saved.offset;U.selected=saved.selected;U.filter=saved.filter;N.Title(U.frame,'Guild Bounty');U.status:SetText('')
    U.frame:ClearAllPoints();U.frame:SetPoint(saved.point,saved.relativeTo,saved.relative,saved.x,saved.y)
    U.board:Show();U.detail:Show();U.UpdateTabs();U.frame:SetShown(T.Complete() and saved.shown or false)
    if U.editor and saved.editorShown and T.Complete() then U.board:Hide();U.detail:Hide();U.editor:Show() end
    if T.Complete() then
        U.Refresh();for key in pairs(saved.aux or {}) do if key=='offer' then U.ShowOffer() elseif key=='mailTask' then if G.Mail.ShowTask then G.Mail.ShowTask() end elseif U[key] then U[key]:Show() end end
    end
    T.saved=nil
end
function T.Pause()
    if T.required then T.Progress().step=T.step end
    T.Restore();G.Chat('Tour paused. /gbf resumes; /gbf help restarts the practice tour.')
end
function T.Move(delta)
    if delta==-1 and T.step>1 then T.step=T.step-1;if T.required then T.Progress().step=T.step end;T.Render()
    elseif delta==1 and not T.steps[T.step].click then T.Advance() end
end
function T.Finish()
    if T.step~=#T.steps then return false end
    local p=T.Progress();p.completed=true;p.step=#T.steps;T.required=false;T.Restore();sound();G.Chat('Practice tour complete. The examples are gone. /gbf help replays it.')
    if not U.frame:IsShown() then U.Toggle() end;if G.offers and #G.offers>0 then U.ShowOffer() end
    if G.Mail and G.Mail.waiting and MailFrame and MailFrame:IsShown() and G.Mail.ShowTask then G.Mail.ShowTask() end
    return true
end
function T.Start(replay)
    local p=T.Progress();if not p then return end
    if T.active then T.Restore() end
    if not U.ready then local ok,err=pcall(U.Build);if not ok then G.UIError('Build tour window',err);return end end
    local point,relativeTo,relative,x,y=U.frame:GetPoint()
    T.saved={editor=U.editor,editorShown=U.editor and U.editor:IsShown(),shown=U.frame:IsShown(),tab=U.tab,offset=U.offset,selected=U.selected,filter=U.filter,point=point,relativeTo=relativeTo,relative=relative,x=x,y=y,offerShown=U.offer and U.offer:IsShown()}
    T.saved.aux={};for _,key in ipairs({'offer','cod','codTest','mailTask'}) do if U[key] and U[key]:IsShown() then T.saved.aux[key]=true;U[key]:Hide() end end
    if U.editor then U.editor:Hide() end;U.editor=T.demoEditor
    U.pendingSave=nil;if StaticPopup_Hide then StaticPopup_Hide('GBF_CONFIRM');StaticPopup_Hide('GBF_QUANTITY') end
    T.required=not T.Complete();T.step=(not replay and G.Int(p.step,1,#T.steps)) and p.step or 1
    T.active=true;T.firstStats=nil;T.finishedStats=nil;T.createdDemo=nil;T.draft=nil;T.quantity=3;T.paid=T.step>=15;T.sent=T.step>=14;T.created=T.step>=21;T.exactReady=false;T.ruleReady=false;T.completedFilter=false
    if U.editor then T.internal=true;U.Editor();T.internal=false end
    if not T.frame then
        local f=N.Frame('GuildBountyForeverTutorial',U.frame,'ButtonFrameTemplate');T.frame=f;f:SetSize(340,178);f:SetFrameStrata('DIALOG');f:SetFrameLevel(140);N.Title(f,'Guild Bounty • Practice');if f.SetPortraitToAsset then f:SetPortraitToAsset('Interface\\Icons\\INV_Misc_Book_09') end
        if f.Inset then f.Inset:Hide() end
        f.heading=N.Label(f,'',14,-42,312,'GameFontNormal');f.heading:SetHeight(30)
        f.text=N.Label(f,'',14,-76,312,'GameFontHighlightSmall');f.text:SetHeight(65)
        f.count=N.Label(f,'',14,-26,312,'GameFontDisableSmall')
        f.previous=N.Button(f,'Back',14,-144,66,function() T.Move(-1) end);f.previous.tourControl=true
        f.next=N.Button(f,'Next',90,-144,236,function() if T.step==#T.steps then T.Finish() else T.Move(1) end end);f.next.tourControl=true
        f.CloseButton:SetScript('OnClick',T.Pause)
        T.highlight=CreateFrame('Frame',nil,U.frame);T.highlight:SetFrameStrata('DIALOG');T.highlight:SetFrameLevel(110);T.highlight:EnableMouse(false)
        for _,edge in ipairs({'TOP','BOTTOM','LEFT','RIGHT'}) do local line=T.highlight:CreateTexture(nil,'OVERLAY');line:SetColorTexture(1,0.8,0.05,1);if edge=='TOP' or edge=='BOTTOM' then line:SetHeight(3);line:SetPoint(edge..'LEFT');line:SetPoint(edge..'RIGHT') else line:SetWidth(3);line:SetPoint('TOP'..edge);line:SetPoint('BOTTOM'..edge) end end
        T.arrow=CreateFrame('Frame',nil,U.frame);T.arrow:SetSize(32,32);T.arrow:SetFrameStrata('DIALOG');T.arrow:SetFrameLevel(115);T.arrow:EnableMouse(false)
        local texture=T.arrow:CreateTexture(nil,'OVERLAY');texture:SetAllPoints();texture:SetTexture('Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up')
        U.frame:HookScript('OnHide',function() if T.active then T.Pause() end end)
    end
    if T.required then p.step=T.step end
    N.Title(U.frame,'Guild Bounty • DEMO TOUR');T.Render()
end
function T.Require()
    if T.internal then return false end
    if T.active then return true end
    if T.Complete() then return false end
    T.Start(false);return true
end
function T.OnLogin()
    if T.Complete() then return end
    if C_Timer and C_Timer.After then C_Timer.After(1,function() if G.db and not T.Complete() then T.Start(false) end end) else T.Start(false) end
end
