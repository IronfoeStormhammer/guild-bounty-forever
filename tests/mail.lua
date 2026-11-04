-- Native mail contract tests: no real game/API writes.
local count=0;local function check(value,label) count=count+1;assert(value,label) end
local G={me='Player-Supplier',guildKey='guild',db={objects={},prefs={}},Items={},Mail={},Codec={}}
G.Int=function(n,lo,hi) return type(n)=='number' and n==math.floor(n) and n>=lo and n<=hi end
G.Chat=function() end;G.Safe=tostring;G.Money=tostring;G.Now=function() return 1800000000 end;G.Refresh=function() end
G.DisplayOwner=function(o) return o.creator.name end;G.ClaimState=function(c) return c.state end
G.Items.Label=function() return '[Boar Ribs]' end
G.Items.Match=function(o,value) return tonumber(tostring(value):match('item:(%d+)'))==o.itemID or value==o.itemID end
local parent={id='Player-Buyer/1',kind='request',owner='Player-Buyer',itemID=2677,creator={name='Buyer Other'},quantity=5,reward=10000}
local claim={kind='claim',id='Player-Supplier/2',parent=parent.id,owner=G.me,quantity=5,state='accepted',created=1800000000}
G.db.objects[parent.id]=parent;G.db.objects[claim.id]=claim
G.Copy=function(value) if type(value)~='table' then return value end;local copy={};for k,v in pairs(value) do copy[k]=G.Copy(v) end;return copy end
G.Edit=function(o,fields) for k,v in pairs(fields) do o[k]=G.Copy(v) end;return o end
G.Debug=function() end;G.People={NameKey=function(s) return s and s:lower() end}
G.Submit=function(c) c.state='submitted';return c end
G.LogError=function(_,err) error(err) end
local function box() return {text='',SetText=function(self,v) self.text=v end,GetText=function(self) return self.text end} end
SendMailNameEditBox=box();SendMailSubjectEditBox=box();SendMailBodyEditBox=box();SendMailMoney={amount=0}
local open=true;MailFrame={IsShown=function() return open end};ATTACHMENTS_MAX_SEND=12;MAX_COD_AMOUNT=10000;NUM_BAG_SLOTS=0
local bags,cursor,sentItems={},nil,{};local nativeSends=0;local cod=0;local moneySent=0
C_Container={GetContainerNumSlots=function() return #bags end,GetContainerItemInfo=function(_,slot) return bags[slot] end,
    PickupContainerItem=function(_,slot) cursor={id=bags[slot].itemID,count=bags[slot].stackCount};bags[slot].stackCount=0 end,
    SplitContainerItem=function(_,slot,n) cursor={id=bags[slot].itemID,count=n};bags[slot].stackCount=bags[slot].stackCount-n end}
GetCursorInfo=function() if cursor then return 'item',cursor.id end end
GetSendMailItem=function(index) local item=sentItems[index];if item then return 'Boar Ribs',item.id,1,item.count end end
GetSendMailItemLink=function(index) local item=sentItems[index];return item and ('item:'..item.id) end
ClickSendMailItemButton=function(index) sentItems[index]=cursor;cursor=nil end
MailFrameTab_OnClick=function(_,tab) check(tab==2,'native send-mail tab') end
MoneyInputFrame_SetCopper=function(frame,amount) frame.amount=amount end;MoneyInputFrame_GetCopper=function(frame) return frame.amount end
SendMailCODButton={GetChecked=function(self) return self.checked end};SendMailRadioButton_OnClick=function(index) SendMailCODButton.checked=index==2 end
SetSendMailMoney=function(n) moneySent=n end;SetSendMailCOD=function(n) cod=n end
SendMail=function() nativeSends=nativeSends+1 end
hooksecurefunc=function(name,callback) local original=_G[name];_G[name]=function(...) original(...);callback(...) end end
C_Timer={After=function(_,fn) fn() end}
assert(loadfile('GuildBountyForever/Mail.lua'))('GuildBountyForever',G)
local function reset()
    bags={{itemID=2677,hyperlink='item:2677',stackCount=3},{itemID=2677,hyperlink='item:2677',stackCount=10}}
    sentItems={};cursor=nil;SendMailNameEditBox:SetText('');SendMailSubjectEditBox:SetText('');SendMailBodyEditBox:SetText('');SendMailMoney.amount=0
    G.Mail.waiting=nil;G.Mail.prepared=nil;G.Mail.sending=nil;G.db.prefs.codSent={};G.db.prefs.mailQueue=nil;claim.state='accepted';claim.delivery=nil;claim.quantity=5;open=true;G.Mail.receiving={};G.Mail.inbox=nil
end
local function prepare(c,amount) local ok,err=G.Mail.Queue(c,amount);if not ok then return nil,err end;return G.Mail.Prepare() end
reset();local ok=prepare(claim,10000);check(ok,'prepare COD')
check(SendMailNameEditBox:GetText()=='Buyer Other' and SendMailCODButton.checked and cod==10000 and moneySent==0,'recipient and COD never send-money mode')
check(sentItems[1].count==3 and sentItems[2].count==2 and bags[2].stackCount==8,'exact stacks split and attached')
check(nativeSends==0 and claim.state=='accepted','preparation neither sends mail nor submits claim')
SendMail(SendMailNameEditBox:GetText(),SendMailSubjectEditBox:GetText());G.Mail.Event('MAIL_SEND_SUCCESS')
check(claim.state=='submitted' and G.db.prefs.codSent[claim.id].amount==10000,'verified send success submits but never records paid')
check(not prepare(claim,10000),'already mailed claim cannot prepare a second delivery')
reset();SendMailSubjectEditBox:SetText('Existing draft');check(not prepare(claim,10000) and #sentItems==0 and SendMailSubjectEditBox:GetText()=='Existing draft','preserves unrelated draft')
reset();bags[1].isBound=true;bags[2].isLocked=true;check(not prepare(claim,10000),'bound and locked stacks excluded')
reset();claim.quantity=20;check(not prepare(claim,10000) and #sentItems==0,'insufficient inventory has no attachment effects')
reset();cursor={id=55,count=1};check(not prepare(claim,10000),'preserves occupied cursor')
reset();check(not prepare(claim,100000001),'COD upper limit')
reset();open=false;check(G.Mail.Queue(claim,5000) and #sentItems==0,'queues outside mailbox');open=true;G.Mail.Event('MAIL_SHOW');check(#sentItems==0,'mailbox opening waits for explicit Prepare delivery');G.Mail.Prepare();check(#sentItems==2 and SendMailMoney.amount==5000,'explicit prepare fills queued claim')
SendMail('Other Person',SendMailSubjectEditBox:GetText());G.Mail.Event('MAIL_SEND_SUCCESS');check(claim.state=='accepted','changed recipient cannot submit claim')
reset();prepare(claim,10000);sentItems[2].count=3;SendMail('Buyer Other',SendMailSubjectEditBox:GetText());G.Mail.Event('MAIL_SEND_SUCCESS');check(claim.state=='accepted','changed attachments cannot submit claim')
reset();prepare(claim,10000);SendMail('Buyer Other',SendMailSubjectEditBox:GetText());G.Mail.Event('MAIL_FAILED');check(claim.state=='accepted','failed send does not submit')
reset();prepare(claim,10000);G.Mail.Event('MAIL_CLOSED');check(not G.Mail.prepared and not G.Mail.sending,'mail closure clears tracking')
reset();open=false;G.Mail.Queue(claim,10000);G.guildKey='other';open=true;G.Mail.Event('MAIL_SHOW');G.Mail.Prepare();check(#sentItems==0 and not G.Mail.waiting,'context switch cancels pending preparation')
-- Self-test shares planning but cannot create claims, move stacks or populate mail.
reset();G.guildKey='guild'
local own={id='Player-Supplier/own',kind='request',owner=G.me,itemID=2677,state='open',quantity=10,reward=10000,creator={name='Supplier Self'}}
G.db.objects[own.id]=own;G.Remaining=function(o) return o.quantity end
local objectCount=0;for _ in pairs(G.db.objects) do objectCount=objectCount+1 end
SendMailSubjectEditBox:SetText('Preserve my draft');local beforeSend=nativeSends
local preview=assert(G.Mail.TestPlan(own,5,5000))
check(preview.recipient=='Supplier Self' and preview.items[1].count==3 and preview.items[2].count==2,'own-bounty preview plans exact stack split')
check(bags[1].stackCount==3 and bags[2].stackCount==10 and #sentItems==0 and not cursor,'preview never moves or splits real inventory')
check(nativeSends==beforeSend and SendMailSubjectEditBox:GetText()=='Preserve my draft' and SendMailMoney.amount==0,'preview preserves native mail and never sends')
local afterCount=0;for _ in pairs(G.db.objects) do afterCount=afterCount+1 end
check(objectCount==afterCount and not G.Mail.waiting and not G.Mail.prepared and next(G.db.prefs.codSent)==nil,'preview creates no claims, queue or payment records')
check(not G.Mail.TestPlan(own,11,100),'preview rejects excess quantity')
check(not G.Mail.TestPlan(own,1,100000001),'preview respects COD amount limit')
check(not G.Mail.TestPlan(parent,1,100),'preview only accepts own bounties')
local selfClaim={id='self-claim',parent=own.id,owner=G.me,quantity=1,state='accepted'};G.db.objects[selfClaim.id]=selfClaim
check(not G.Mail.Queue(selfClaim,100),'test preview does not unlock real self-mail flow')
-- Receiver observes native collection; unrelated updates cannot complete a bounty.
reset();G.guildKey='guild';G.me='Player-Supplier';prepare(claim,10000);SendMail('Buyer Other',SendMailSubjectEditBox:GetText());G.Mail.Event('MAIL_SEND_SUCCESS')
check(claim.delivery and claim.delivery.sentAt and claim.delivery.items['2677']==5,'supplier publishes sent metadata and exact attachments')
local mailbox={};local wallet=100000;GetMoney=function() return wallet end
GetInboxNumItems=function() return #mailbox end
GetInboxHeaderInfo=function(i) local r=mailbox[i];if r then return nil,nil,r.sender,r.subject,r.money,r.cod end end
GetInboxItem=function(i,slot) local item=mailbox[i] and mailbox[i].items[slot];if item then return 'Boar Ribs',item.id,1,item.count end end
GetInboxItemLink=function(i,slot) local item=mailbox[i] and mailbox[i].items[slot];return item and ('item:'..item.id) end
TakeInboxItem=function() end;TakeInboxMoney=function() end
local receipts={};G.ReceiveDelivery=function(c,id,qty,amount,subject,paid) receipts[#receipts+1]={claim=c.id,quantity=qty,paid=paid};return true end
G.me=parent.owner;mailbox={{sender='Supplier Self',subject=claim.delivery.subject,money=0,cod=10000,items={[1]={id=2677,count=3},[2]={id=2677,count=2}}}}
-- Correct sender is validated against the supplier identity, even if the subject matches.
claim.creator={name='Supplier Self'};G.Mail.Event('MAIL_SHOW');TakeInboxItem(1,1)
G.Mail.Event('MAIL_SUCCESS');check(#receipts==0,'mail success without item removal and bag gain is not receipt')
mailbox[1].items[1]=nil;mailbox[1].cod=0;bags[1].stackCount=bags[1].stackCount+3;wallet=wallet-10000;G.Mail.Event('BAG_UPDATE_DELAYED')
check(#receipts==1 and receipts[1].quantity==3 and receipts[1].paid,'COD acceptance and first stack receipt observed')
G.Mail.Event('MAIL_SUCCESS');check(#receipts==1,'duplicate mail events do not repeat receipt')
TakeInboxItem(1,2);mailbox[1].items[2]=nil;bags[2].stackCount=bags[2].stackCount+2;G.Mail.Event('MAIL_SUCCESS')
check(#receipts==2 and receipts[2].quantity==2,'second attachment receipt tracked independently')
G.Mail.CaptureInbox();mailbox[1].sender='Wrong Person';mailbox[1].items[1]={id=2677,count=3};G.Mail.CaptureInbox();TakeInboxItem(1,1);check(not next(G.Mail.receiving),'wrong sender cannot claim receipt')
G.me='Player-Supplier';mailbox={{sender='Buyer Other',subject='COD Payment: '..claim.delivery.subject,money=10000,cod=0,items={}}};G.Mail.Event('MAIL_SHOW');TakeInboxMoney(1)
mailbox[1].money=0;wallet=wallet+10000;G.Mail.Event('MAIL_SUCCESS');check(claim.delivery.payoutAt~=nil,'supplier COD proceeds collection tracked')
-- Collection proof may arrive before MAIL_SUCCESS, including one-attachment native COD calls.
G.me=parent.owner;claim.delivery.payoutAt=nil;G.Mail.receiving={};receipts={}
mailbox={{sender='Supplier Self',subject=claim.delivery.subject,money=0,cod=10000,items={[1]={id=2677,count=2}}}}
G.Mail.Event('MAIL_SHOW');TakeInboxItem(1);mailbox[1].items[1]=nil;mailbox[1].cod=0;bags[1].stackCount=bags[1].stackCount+2
G.Mail.Event('BAG_UPDATE_DELAYED');check(#receipts==1 and receipts[1].quantity==2 and receipts[1].paid,'accepting COD records automatically without waiting for MAIL_SUCCESS or a manual button')
G.Mail.Event('MAIL_SUCCESS');check(#receipts==1,'later mail success cannot duplicate an automatic receipt')
check(SendMailBodyEditBox:GetText():find('recorded automatically',1,true) and not SendMailBodyEditBox:GetText():find('record this claim paid',1,true),'prepared mail instructs automatic recording')
print('PASS: '..count..' COD plan, native draft, attachment, review and send-result checks. Live mailbox behavior remains unverified.')
