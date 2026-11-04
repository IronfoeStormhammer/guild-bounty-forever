local _, G = ...
local states={request={open=true,closed=true},pvp={open=true,closed=true},claim={accepted=true,submitted=true,withdrawn=true},history={recorded=true}}
local common={id=true,owner=true,kind=true,created=true,updated=true,rev=true,state=true,title=true,note=true,creator=true}
local specific={request={quantity=true,reward=true,itemID=true,rules=true,decisions=true,receipts=true},pvp={quantity=true,reward=true,target=true,decisions=true},claim={quantity=true,parent=true,evidence=true,delivery=true},history={quantity=true,reward=true,parent=true,originRev=true,eventState=true,action=true}}
local ruleKeys={classID=true,subclassID=true,slot=true,minLevel=true,minRequired=true,maxLevel=true,maxRequired=true,stats=true}
function G.Validate(o)
    if type(o)~='table' or not specific[o.kind] then return false end
    local encoded=G.Codec.Encode(o);if not encoded or #encoded>10000 then return false end
    for k in pairs(o) do if not common[k] and not specific[o.kind][k] then return false end end
    if not G.Text(o.id,180) or not G.Text(o.owner,100) or o.id:sub(1,#o.owner+1)~=o.owner..'/' then return false end
    if not states[o.kind] or not states[o.kind][o.state] or not G.Int(o.rev,1,1000000) or not G.Int(o.created,1,1e11) or not G.Int(o.updated,o.created,1e11) then return false end
    if type(o.creator)~='table' then return false end
    if (o.owner:match('^Player%-') and o.creator and o.creator.guid~=o.owner) or (o.owner:match('^name:') and o.creator and G.People.Key(o.creator)~=o.owner) then return false end
    if not G.People.Valid(o.creator,true) or not G.Text(o.title,160) or not G.Text(o.note,2000) or G.CharCount(o.note)>500 then return false end
    if o.kind=='history' then
        return G.Text(o.parent,180) and G.Int(o.originRev,1,1000000) and G.Text(o.eventState,40) and G.Text(o.action,40) and o.rev==1 and o.id==o.parent..'/history/'..o.originRev and (o.quantity==nil or G.Int(o.quantity,1,100000)) and (o.reward==nil or G.Int(o.reward,0,100000000000))
    end
    if o.kind=='claim' then
        if not G.Text(o.parent,180) or not G.Int(o.quantity,1,100000) or type(o.evidence)~='table' then return false end
        local numeric={itemID={1,100000000},at={1,1e11},flags={0,4294967295},combatTime={0,1e14}}
        local strings={ruleset=20,link=500,zone=200,targetGUID=100,targetName=100,event=60,sourceGUID=100,sourceName=100,method=160,character=100}
        if not G.Int(o.evidence.at,1,1e11) then return false end
        for k,v in pairs(o.evidence) do
            if numeric[k] then
                if k=='combatTime' then if type(v)~='number' or v~=v or v<0 or v>1e14 then return false end
                elseif not G.Int(v,numeric[k][1],numeric[k][2]) then return false end
            elseif strings[k] then if not G.Text(v,strings[k]) then return false end
            else return false end
        end
        if o.delivery~=nil then
            local d=o.delivery;if type(d)~='table' then return false end
            for key,value in pairs(d) do
                if key=='selfTest' then if type(value)~='boolean' then return false end
                elseif key=='subject' then if not G.Text(value,80) then return false end
                elseif key=='amount' then if not G.Int(value,0,100000000) then return false end
                elseif key=='sentAt' or key=='payoutAt' then if not G.Int(value,o.created,1e11) then return false end
                elseif key=='items' then
                    if type(value)~='table' then return false end;local count=0
                    for id,quantity in pairs(value) do count=count+1;if count>12 or type(id)~='string' or not id:match('^%d+$') or not G.Int(tonumber(id),1,100000000) or not G.Int(quantity,1,100000) then return false end end
                else return false end
            end
            if d.sentAt then
                if not d.subject or d.amount==nil or type(d.items)~='table' or not next(d.items) then return false end
                local total=0;for _,quantity in pairs(d.items) do total=total+quantity end;if total~=o.quantity then return false end
            end
        end
        return true
    end
    if o.receipts~=nil then
        if o.kind~='request' or type(o.receipts)~='table' then return false end
        local count=0;for id,r in pairs(o.receipts) do
            count=count+1;if count>40 or not G.Text(id,180) or type(r)~='table' or not G.Int(r.quantity,1,100000) or not G.Int(r.at,o.created,1e11) or not G.Int(r.amount,0,100000000) or type(r.codPaid)~='boolean' or not G.Text(r.subject,80) or type(r.items)~='table' then return false end
            for key in pairs(r) do if key~='quantity' and key~='at' and key~='amount' and key~='codPaid' and key~='subject' and key~='items' then return false end end
            local total,n=0,0;for item,quantity in pairs(r.items) do n=n+1;if n>12 or type(item)~='string' or not item:match('^%d+$') or not G.Int(quantity,1,100000) then return false end;total=total+quantity end;if total~=r.quantity then return false end
        end
    end
    if not G.Int(o.quantity,1,100000) or not G.Int(o.reward,0,100000000000) or type(o.decisions)~='table' then return false end
    local count=0
    for id,d in pairs(o.decisions) do
        count=count+1
        if count>40 or not G.Text(id,180) or type(d)~='table' or (d.state~='paid' and d.state~='rejected') or not G.Int(d.quantity,1,100000) or not G.Int(d.at,o.created,1e11) then return false end
        for k in pairs(d) do if k~='state' and k~='quantity' and k~='at' then return false end end
    end
    local paid=0;for _,d in pairs(o.decisions) do if d.state=='paid' then paid=paid+d.quantity end end
    if paid>o.quantity then return false end
    if o.kind=='pvp' then
        if o.quantity~=1 or not G.People.Valid(o.target,true) then return false end
    elseif o.itemID then
        if not G.Int(o.itemID,1,100000000) or o.rules then return false end
    else
        if type(o.rules)~='table' or not next(o.rules) then return false end
        for k,v in pairs(o.rules) do
            if not ruleKeys[k] then return false end
            if k=='slot' then if not G.Text(v,40) or not v:match('^INVTYPE_[A-Z0-9_]+$') then return false end
            elseif k=='stats' then
                if type(v)~='table' or not next(v) then return false end
                local count=0;for stat,b in pairs(v) do
                    count=count+1;if count>80 or type(stat)~='string' or #stat>100 or not stat:match('^ITEM_MOD_[A-Z0-9_]+_SHORT$') or type(b)~='table' or not next(b) then return false end
                    for bound,n in pairs(b) do if (bound~='min' and bound~='max') or not G.Int(n,0,1000000) then return false end end
                    if b.min and b.max and b.min>b.max then return false end
                end
            elseif not G.Int(v,0,10000) then return false end
        end
        if o.rules.minLevel and o.rules.maxLevel and o.rules.minLevel>o.rules.maxLevel or o.rules.minRequired and o.rules.maxRequired and o.rules.minRequired>o.rules.maxRequired then return false end
    end
    return true
end
function G.Remaining(o)
    local paid=0;for _,d in pairs(o.decisions or {}) do if d.state=='paid' then paid=paid+d.quantity end end
    return math.max(0,o.quantity-paid)
end
function G.ClaimState(c)
    local p=G.db.objects[c.parent];local d=p and p.decisions and p.decisions[c.id]
    return d and d.state or c.state
end
function G.Create(kind,fields)
    local o=G.Copy(fields);o.kind=kind;o.owner=G.me;o.creator=G.Copy(G.player);o.id=G.NewID();o.created=G.Now();o.updated=o.created;o.rev=1;o.state=kind=='claim' and 'accepted' or 'open';o.note=o.note or '';o.title=o.title or '';if kind~='claim' then o.decisions={} end
    if not G.Validate(o) then return nil,'Invalid fields.' end
    local ok,err=G.Merge(o,G.me,true);if ok then return o end return nil,err
end
function G.Edit(o,fields)
    o=o and G.db.objects[o.id];if not o then return nil,'Record unavailable.' end
    if o.owner~=G.me then return nil,'Only the creator can edit this record.' end
    local editable=o.kind=='claim' and {state=true,delivery=true} or {quantity=true,reward=true,note=true,state=true,decisions=true,receipts=true}
    for k in pairs(fields) do if not editable[k] then return nil,'Identity and claim facts cannot be edited.' end end
    if o.kind=='claim' then
        if o.state=='withdrawn' or (o.state=='submitted' and fields.state=='accepted') then return nil,'Invalid claim transition.' end
        if G.ClaimState(o)=='paid' or G.ClaimState(o)=='rejected' then
            local previous=G.Copy(o.delivery or {});local incoming=fields.delivery
            if incoming then previous.payoutAt=incoming.payoutAt end
            if fields.state or not incoming or not o.delivery or not o.delivery.sentAt or G.Codec.Encode(previous)~=G.Codec.Encode(incoming) then return nil,'This claim has a final decision.' end
        end
    elseif o.state=='closed' then
        for k,v in pairs(fields) do if k~='decisions' and not (k=='state' and v=='closed') then return nil,'This request is closed.' end end
    end
    local n=G.Copy(o);for k,v in pairs(fields) do n[k]=G.Copy(v) end
    n.rev=n.rev+1;n.updated=math.max(G.Now(),o.updated)
    local ok,err=G.Merge(n,G.me,true);return ok and n or nil,err
end
