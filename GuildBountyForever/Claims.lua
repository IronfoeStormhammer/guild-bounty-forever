local _,G=...
function G.Accept(o,evidence,quantity)
    o=o and G.db.objects[o.id];if not o or (o.kind~='request' and o.kind~='pvp') then return nil,'Request unavailable.' end
    if o.state~='open' or G.Remaining(o)<=0 then return nil,'This request is closed or fulfilled.' end
    if evidence then
        for _,c in pairs(G.db.objects) do if c.kind=='claim' and c.owner==G.me and c.parent==o.id and (G.ClaimState(c)=='accepted' or G.ClaimState(c)=='submitted') then
            if (evidence.itemID and c.evidence.itemID==evidence.itemID) or (evidence.targetGUID and c.evidence.targetGUID==evidence.targetGUID and c.evidence.at==evidence.at) then return c end
        end end
    end
    quantity=math.min(quantity or 1,G.Remaining(o))
    return G.Create('claim',{title=o.title,parent=o.id,quantity=quantity,evidence=evidence or {at=G.Now(),zone=GetRealZoneText(),character=G.player.name,ruleset=G.ruleset,method='Manual intent'}})
end
function G.Submit(c)
    c=c and G.db.objects[c.id];if not c or c.kind~='claim' then return nil,'Claim unavailable.' end
    local p=G.db.objects[c.parent]
    if not p or p.state~='open' or G.ClaimState(c)~='accepted' then return nil,'The claim cannot be submitted.' end
    if p.kind=='pvp' and not c.evidence.targetGUID then return nil,'Select a detected kill from your local evidence first.' end
    return G.Edit(c,{state='submitted'})
end
function G.Decide(c,decision)
    c=c and G.db.objects[c.id];if not c or c.kind~='claim' then return nil,'Claim unavailable.' end
    local p=G.db.objects[c.parent]
    if not p or p.owner~=G.me or G.ClaimState(c)~='submitted' or (decision~='paid' and decision~='rejected') then return nil,'Only the creator can review submitted claims.' end
    if decision=='paid' and c.quantity>G.Remaining(p) then return nil,'Claim exceeds the remaining quantity.' end
    local d=G.Copy(p.decisions);d[c.id]={state=decision,quantity=c.quantity,at=G.Now()}
    local n=0;for _ in pairs(d) do n=n+1 end;if n>40 then return nil,'This request has reached its review limit.' end
    local remaining=G.Remaining(p)-(decision=='paid' and c.quantity or 0)
    return G.Edit(p,{decisions=d,state=remaining<=0 and 'closed' or p.state})
end

-- Only the requester authors receipts; supplier mail observations stay on the claim.
function G.ReceiveDelivery(claim,itemID,quantity,amount,subject,codPaid)
    local c=claim and G.db.objects[claim.id];local p=c and G.db.objects[c.parent];local d=c and c.delivery
    if not p or p.owner~=G.me or not d or not d.sentAt or d.subject~=subject or d.amount~=amount or G.ClaimState(c)~='submitted' then return nil,'Delivery does not match a submitted mailed claim.' end
    local id=tostring(itemID);if not G.Int(quantity,1,100000) or not d.items[id] then return nil,'Unexpected delivery item.' end
    local receipts=G.Copy(p.receipts or {});local r=receipts[c.id] or {quantity=0,at=G.Now(),amount=amount,subject=subject,codPaid=false,items={}}
    local n=(r.items[id] or 0)+quantity;if n>d.items[id] then return nil,'Delivery was already recorded or exceeds the claim.' end
    r.items[id]=n;r.quantity=r.quantity+quantity;r.codPaid=r.codPaid or codPaid or amount==0;r.at=G.Now();receipts[c.id]=r
    local saved,err=G.Edit(p,{receipts=receipts});if not saved then return nil,err end
    if r.quantity==c.quantity and r.codPaid then local paid,reason=G.Decide(c,'paid');if paid then return paid end;G.Chat('Delivery received, but completion needs manual review: '..tostring(reason));return saved,reason end
    return saved
end
