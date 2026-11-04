local _,G=...
G.Mail={};local M=G.Mail
local function fail(message) G.Chat(message);return nil,message end
local function attachments()
    local items={};for index=1,(ATTACHMENTS_MAX_SEND or 12) do
        local name,id,texture,count=GetSendMailItem(index)
        if name then items[#items+1]={id=id,count=count,index=index,link=GetSendMailItemLink and GetSendMailItemLink(index)} end
    end;return items
end
function M.IsSelfTest(claim,parent) return claim and parent and claim.delivery and claim.delivery.selfTest==true and parent.owner==G.me and IsInGuild and not IsInGuild() end
function M.Plan(claim,testOnly)
    local parent=claim and G.db.objects[claim.parent]
    if not parent or parent.kind~='request' or claim.owner~=G.me or (parent.owner==G.me and not testOnly and not M.IsSelfTest(claim,parent)) or (G.ClaimState(claim)~='accepted' and G.ClaimState(claim)~='submitted') then return nil,'Choose your active item claim for another requester.' end
    if (claim.delivery and claim.delivery.sentAt) or (G.db.prefs.codSent and G.db.prefs.codSent[claim.id]) then return nil,'This claim already has sent COD mail. Await acceptance/payment or review it manually before arranging a new delivery.' end
    if not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerItemInfo or not C_Container.PickupContainerItem or not C_Container.SplitContainerItem then return nil,'Native bag attachment APIs are unavailable.' end
    local needed=claim.quantity;local plan={}
    for bag=0,(NUM_BAG_SLOTS or 4) do for slot=1,C_Container.GetContainerNumSlots(bag) do
        local item=C_Container.GetContainerItemInfo(bag,slot)
        if item and not item.isLocked and not item.isBound and item.stackCount and G.Items.Match(parent,item.hyperlink or item.itemID)==true then
            local bound=false
            if C_Item and C_Item.IsBound and ItemLocation and ItemLocation.CreateFromBagAndSlot then local ok,value=pcall(C_Item.IsBound,ItemLocation:CreateFromBagAndSlot(bag,slot));bound=not ok or value end
            if not bound then
                local take=math.min(needed,item.stackCount);plan[#plan+1]={bag=bag,slot=slot,id=item.itemID,link=item.hyperlink,count=take,total=item.stackCount};needed=needed-take
                if needed==0 then if #plan>(ATTACHMENTS_MAX_SEND or 12) then return nil,'This quantity needs too many mail attachments. Consolidate stacks first.' end;return plan,parent end
            end
        end
    end end
    return nil,'Not enough unlocked, mailable matching items in your bags for this claim.'
end
-- Read-only self-test: never inserts the temporary claim into the database.
function M.TestPlan(request,quantity,amount)
    request=request and G.db.objects[request.id]
    if not request or request.kind~='request' or request.owner~=G.me or request.state~='open' then return nil,'Select one of your open item bounties for this local test.' end
    if not G.Int(quantity,1,G.Remaining(request)) then return nil,'Choose a quantity within the remaining bounty amount.' end
    if not G.Int(amount,0,(MAX_COD_AMOUNT or 10000)*10000) then return nil,'Enter a COD amount within the client limit.' end
    local temporary={id='local-cod-preview',owner=G.me,parent=request.id,quantity=quantity,state='accepted'}
    local plan,err=M.Plan(temporary,true);if not plan then return nil,err end
    return {recipient=G.DisplayOwner(request),quantity=quantity,amount=amount,subject='TEST ONLY - Guild Bounty delivery',items=plan,request=request.id}
end
function M.Queue(claim,amount)
    claim=claim and G.db.objects[claim.id]
    if not G.Int(amount,0,(MAX_COD_AMOUNT or 10000)*10000) then return fail('COD amount exceeds the client limit or is invalid.') end
    local plan,parent=M.Plan(claim);if not plan then return fail(parent) end
    M.waiting={claim=claim.id,amount=amount,context=G.guildKey};G.db.prefs.mailQueue=G.Copy(M.waiting)
    if M.ShowTask then M.ShowTask() end
    G.Chat('Delivery accepted. Go to a mailbox, open mail, then press Prepare delivery. Quantity: '..claim.quantity..' items for '..G.Safe(G.DisplayOwner(parent))..'.');return true
end
function M.Prepare()
    local pending=M.waiting;if not pending then return end
    if pending.context~=G.guildKey then M.waiting=nil;G.db.prefs.mailQueue=nil;return fail('COD preparation cancelled because the guild context changed.') end
    if not MailFrame or not MailFrame:IsShown() then return fail('Open a mailbox first.') end
    if not GetSendMailItem or not ClickSendMailItemButton or not SendMailNameEditBox or not SendMailSubjectEditBox or not SendMailBodyEditBox or not MailFrameTab_OnClick or not MoneyInputFrame_SetCopper or not MoneyInputFrame_GetCopper or not SendMailCODButton or not SendMailRadioButton_OnClick then return fail('Native mail controls are unavailable.') end
    if GetCursorInfo and GetCursorInfo() then return fail('Clear the cursor before preparing COD mail.') end
    if #attachments()>0 or SendMailNameEditBox:GetText()~='' or SendMailSubjectEditBox:GetText()~='' or SendMailBodyEditBox:GetText()~='' or (MoneyInputFrame_GetCopper and MoneyInputFrame_GetCopper(SendMailMoney)>0) then return fail('An existing mail draft is open. Send or clear it, then click Mail COD again; your draft was preserved.') end
    local claim=G.db.objects[pending.claim];local plan,parent=M.Plan(claim);if not plan then return fail(parent) end
    MailFrameTab_OnClick(nil,2)
    M.prepared=nil;M.sending=nil
    for index,item in ipairs(plan) do
        local current=C_Container.GetContainerItemInfo(item.bag,item.slot)
        if not current or current.itemID~=item.id or current.stackCount~=item.total or current.isLocked or G.Items.Match(parent,current.hyperlink or current.itemID)~=true then return fail('Bag contents changed. Review the mail attachments and retry.') end
        if item.count<item.total then C_Container.SplitContainerItem(item.bag,item.slot,item.count) else C_Container.PickupContainerItem(item.bag,item.slot) end
        if not GetCursorInfo or GetCursorInfo()~='item' then return fail('The client did not allow attaching this item. Review the draft and attach it manually.') end
        ClickSendMailItemButton(index)
        if GetCursorInfo() then return fail('This item could not be mailed. Return the cursor item to your bags and review the draft.') end
    end
    local expected={};for _,item in ipairs(plan) do expected[item.id]=(expected[item.id] or 0)+item.count end
    local actual={};for _,item in ipairs(attachments()) do actual[item.id]=(actual[item.id] or 0)+item.count end
        for id,count in pairs(expected) do if actual[id]~=count then return fail('Attachment verification failed. Review the mail draft before sending.') end end
        for id,count in pairs(actual) do if expected[id]~=count then return fail('Unexpected attachment. Review the mail draft before sending.') end end
    local hash=0;for i=1,#claim.id do hash=(hash*33+claim.id:byte(i))%2147483647 end
    local subject='GBF-'..claim.created..'-'..hash
    SendMailNameEditBox:SetText(G.DisplayOwner(parent));SendMailSubjectEditBox:SetText(subject)
    SendMailBodyEditBox:SetText('Guild Bounty delivery: '..claim.quantity..' x '..G.Items.Label(parent)..'\nClaim: '..claim.id..'\nCOD: '..string.format('%dg %ds %dc',math.floor(pending.amount/10000),math.floor(pending.amount/100)%100,pending.amount%100)..'\nAccept the COD and collect all claimed items with Guild Bounty enabled. Receipt and payment are recorded automatically; no separate confirmation in the addon is needed.')
    SendMailRadioButton_OnClick(2);MoneyInputFrame_SetCopper(SendMailMoney,pending.amount)
    if SetSendMailMoney then SetSendMailMoney(0) end
    if SetSendMailCOD then SetSendMailCOD(pending.amount) end
    M.prepared={claim=claim.id,context=G.guildKey,recipient=G.DisplayOwner(parent),subject=subject,amount=pending.amount,expected=expected}
    M.waiting=nil;G.db.prefs.mailQueue=nil;if G.UI and G.UI.mailTask then G.UI.mailTask:Hide() end;M.InstallHook()
    G.Chat('COD prepared. Review recipient, items and '..G.Money(pending.amount)..' in the native mail window, then click Send.');return true
end
function M.InstallHook()
    if M.hooked or not hooksecurefunc or not SendMail then return end
    hooksecurefunc('SendMail',function(recipient,subject)
        M.sending=nil;local p=M.prepared
        if not p or p.context~=G.guildKey or recipient~=p.recipient or subject~=p.subject or not SendMailCODButton:GetChecked() or MoneyInputFrame_GetCopper(SendMailMoney)~=p.amount then return end
        local claim=G.db.objects[p.claim];local parent=claim and G.db.objects[claim.parent];if not parent then return end
        local actual={};for _,item in ipairs(attachments()) do if G.Items.Match(parent,item.link or item.id)~=true then return end;actual[item.id]=(actual[item.id] or 0)+item.count end
        for id,count in pairs(p.expected) do if actual[id]~=count then return end end
        for id,count in pairs(actual) do if p.expected[id]~=count then return end end
        M.sending=p
    end);M.hooked=true
end
function M.Sent(p)
    local claim=G.db.objects[p.claim];if not claim then return end
    local d=G.Copy(claim.delivery or {});d.sentAt=G.Now();d.subject=p.subject;d.amount=p.amount;d.items={}
    for id,count in pairs(p.expected) do d.items[tostring(id)]=count end
    local saved,err=G.Edit(claim,{delivery=d});if not saved then G.Chat('Mail sent; delivery tracking failed: '..tostring(err));return end
    if G.ClaimState(saved)=='accepted' then local submitted,reason=G.Submit(saved);if not submitted then G.Chat('Mail sent; submit the claim manually: '..tostring(reason)) end end
    G.db.prefs.codSent=G.db.prefs.codSent or {};G.db.prefs.codSent[p.claim]={at=G.Now(),amount=p.amount}
    G.Chat('Delivery sent. The requester will see it in Mine; receipt and COD payment are tracked when they collect it from mail.');G.Refresh()
end
function M.StartSelfTest(request,quantity,amount)
    if not IsInGuild or IsInGuild() then return fail('Real self-mail testing is only available in local, unguilded mode.') end
    local plan,err=M.TestPlan(request,quantity,amount);if not plan then return fail(err) end
    local claim,reason=G.Accept(request,nil,quantity);if not claim then return fail(reason) end
    claim,reason=G.Edit(claim,{delivery={selfTest=true}});if not claim then return fail(reason) end
    local ok,problem=M.Queue(claim,amount);if not ok then return nil,problem end
    G.Chat('REAL LOCAL MAIL TEST: actual items and COD are used. The game must allow self-mail; rejected sends remain unsent.');return claim
end
function M.Bags()
    local counts={};if not C_Container then return counts end
    for bag=0,(NUM_BAG_SLOTS or 4) do for slot=1,C_Container.GetContainerNumSlots(bag) do local item=C_Container.GetContainerItemInfo(bag,slot);if item and item.itemID and item.stackCount then counts[item.itemID]=(counts[item.itemID] or 0)+item.stackCount end end end
    return counts
end
function M.Inbox()
    local rows={};if not GetInboxNumItems or not GetInboxHeaderInfo or not GetInboxItem then return rows end
    for index=1,GetInboxNumItems() do
        local _,_,sender,subject,money,cod=GetInboxHeaderInfo(index)
        if sender and subject then
            local row={index=index,sender=sender,subject=subject,money=money or 0,cod=cod or 0,items={}}
            for slot=1,(ATTACHMENTS_MAX_RECEIVE or 16) do local name,id,_,count=GetInboxItem(index,slot);if name and id and count then row.items[slot]={id=id,count=count,link=GetInboxItemLink and GetInboxItemLink(index,slot)} end end
            rows[index]=row
        end
    end
    return rows
end
local function sameName(a,b) return G.People.NameKey(a)==G.People.NameKey(b) end
function M.MatchInbox(row,payout)
    for _,claim in pairs(G.db.objects) do
        local d=claim.delivery;local parent=claim.parent and G.db.objects[claim.parent]
        if claim.kind=='claim' and parent and d and d.sentAt and d.subject then
            if not payout and parent.owner==G.me and row.subject==d.subject and sameName(row.sender,G.DisplayOwner(claim)) and (row.cod==d.amount or row.cod==0) then return claim,parent end
            if payout and claim.owner==G.me and not d.payoutAt and row.money==d.amount and row.money>0 and row.subject:find(d.subject,1,true) and sameName(row.sender,G.DisplayOwner(parent)) then return claim,parent end
        end
    end
end
function M.CaptureInbox()
    M.inbox=M.Inbox();M.notifiedInbox=M.notifiedInbox or {}
    for _,row in pairs(M.inbox) do
        local claim=M.MatchInbox(row,false)
        if claim and G.ClaimState(claim)=='submitted' and next(row.items) and not M.notifiedInbox[claim.id] then
            G.Chat('Bounty delivery arrived from '..G.Safe(row.sender)..': '..row.subject..'. Review the items and accept COD in your native inbox; collection updates the bounty.');M.notifiedInbox[claim.id]=true
        end
    end
    if not M.receiving or not next(M.receiving) then M.bagBaseline=M.Bags();M.moneyBaseline=GetMoney and GetMoney() end
end
function M.ObserveTake(index,slot,payout)
    local row=M.inbox and M.inbox[index];if not row then return end
    local claim,parent=M.MatchInbox(row,payout);if not claim then return end
    if not payout and not slot then local only;for index in pairs(row.items) do if only then return end;only=index end;slot=only end
    local item=not payout and row.items[slot];if not payout then
        if not item or not claim.delivery.items[tostring(item.id)] or G.Items.Match(parent,item.link or item.id)~=true then return end
    end
    M.receiving=M.receiving or {};local key=claim.id..(payout and ':gold' or ':'..slot)
    if M.receiving[key] then return end
    M.receiving[key]={claim=claim.id,context=G.guildKey,subject=row.subject,sender=row.sender,slot=slot,item=item,payout=payout,money=row.money,cod=row.cod,before=payout and M.moneyBaseline or (M.bagBaseline and M.bagBaseline[item.id] or 0),at=G.Now()}
end
function M.CheckReceipts(success)
    if not M.receiving then return end
    local inbox=M.Inbox();local bags=M.Bags()
    for key,attempt in pairs(M.receiving) do
        if success then attempt.success=true end
        if attempt.context~=G.guildKey or G.Now()-attempt.at>30 then M.receiving[key]=nil
        else -- Correlated native collection, removal and inventory changes are decisive even if MAIL_SUCCESS is delayed.
            local current;local duplicate=false
            for _,row in pairs(inbox) do if row.subject==attempt.subject and sameName(row.sender,attempt.sender) then if current then duplicate=true end;current=row end end
            local claim=G.db.objects[attempt.claim]
            if not duplicate and claim then
                if attempt.payout then
                    if (not current or current.money==0) and attempt.before and GetMoney and GetMoney()-attempt.before>=attempt.money then
                        local d=G.Copy(claim.delivery);d.payoutAt=G.Now();local saved=G.Edit(claim,{delivery=d});if saved then G.Chat('COD proceeds collected for '..G.Items.Label(G.db.objects[claim.parent])..'.');M.receiving[key]=nil end
                    end
                else
                    local item=current and current.items[attempt.slot];local removed=not item or item.id~=attempt.item.id or item.count<attempt.item.count
                    local quantity=(item and item.id==attempt.item.id) and (attempt.item.count-item.count) or attempt.item.count
                    if removed and quantity>0 and (bags[attempt.item.id] or 0)-attempt.before>=quantity and (not current or current.cod==0) then
                        local saved,err=G.ReceiveDelivery(claim,attempt.item.id,quantity,claim.delivery.amount,attempt.subject,attempt.cod==claim.delivery.amount)
                        if saved then
                            G.Chat('Mail delivery received: '..quantity..' items. Receipt recorded automatically.')
                            if G.ClaimState(claim)=='paid' then G.Chat('Claim completed automatically: all claimed items received and COD accepted.');if PlaySound and SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN then PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN,'Master') end end
                            M.receiving[key]=nil else G.Debug('Receipt not recorded: '..tostring(err));if G.ClaimState(claim)~='accepted' then M.receiving[key]=nil end end
                    end
                end
            end
        end
    end
end
function M.InstallInboxHooks()
    if not hooksecurefunc then return end
    if TakeInboxItem and not M.itemHooked then hooksecurefunc('TakeInboxItem',function(index,slot) M.ObserveTake(index,slot,false) end);M.itemHooked=true end
    if TakeInboxMoney and not M.moneyHooked then hooksecurefunc('TakeInboxMoney',function(index) M.ObserveTake(index,nil,true) end);M.moneyHooked=true end
end
function M.Event(event)
    if event=='MAIL_SHOW' then
        if not M.waiting and type(G.db.prefs.mailQueue)=='table' then local pending=G.db.prefs.mailQueue;if pending.context==G.guildKey and G.db.objects[pending.claim] then M.waiting=G.Copy(pending) end end
        M.InstallInboxHooks();M.CaptureInbox();if M.ShowTask then M.ShowTask() end
        if C_Timer then C_Timer.After(0.2,function() if MailFrame and MailFrame:IsShown() then M.CaptureInbox();if M.ShowTask then M.ShowTask() end end end) end
    elseif event=='MAIL_INBOX_UPDATE' or event=='MAIL_SUCCESS' or event=='BAG_UPDATE_DELAYED' then
        M.CheckReceipts(event=='MAIL_SUCCESS');if MailFrame and MailFrame:IsShown() then M.CaptureInbox() end
    elseif event=='MAIL_SEND_SUCCESS' then
        local p=M.sending;M.sending=nil;M.prepared=nil;if p and p.context==G.guildKey then M.Sent(p) end
    elseif event=='MAIL_FAILED' then M.sending=nil;M.receiving={};G.Chat('Mail operation failed. No send, receipt or payment completion was recorded; review the native mail error.')
    elseif event=='MAIL_CLOSED' then M.prepared=nil;M.sending=nil;M.inbox=nil;M.receiving={};if G.UI and G.UI.mailTask then G.UI.mailTask:Hide() end end
end
