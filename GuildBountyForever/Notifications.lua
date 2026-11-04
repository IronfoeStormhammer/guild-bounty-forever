local _,G=...
function G.NotifyChange(o,old)
    if o.kind=='claim' then
        local p=G.db.objects[o.parent]
        if p and p.owner==G.me and o.state=='submitted' and G.Mail and G.Mail.CheckReceipts then G.Mail.CheckReceipts(false) end
        if p and p.owner==G.me and o.state=='submitted' and (not old or old.state~='submitted') then G.Chat(G.Safe(G.DisplayOwner(o))..' submitted a claim. Open /gbf → Mine to review.') end
    elseif old and (o.kind=='request' or o.kind=='pvp') then
        for id,d in pairs(o.decisions) do
            local c=G.db.objects[id]
            if c and c.owner==G.me and not old.decisions[id] then G.Chat('Your claim was '..d.state..'. Payment is handled manually.') end
        end
    end
end
function G.Offer(o,evidence,quantity,key)
    G.offers=G.offers or {}
    if evidence.itemID then
        -- An active prompt represents the bounty, regardless of chat/bag event order.
        for _,offer in ipairs(G.offers) do if offer.object==o.id and offer.evidence.itemID==evidence.itemID then
            offer.quantity=math.max(offer.quantity or 1,quantity or 1)
            if G.UI then G.UI.ShowOffer() end
            return
        end end
        G.lootOfferTimes=G.lootOfferTimes or {}
        local last=G.lootOfferTimes[key]
        if last and G.Now()-last<3 then return end
        G.lootOfferTimes[key]=G.Now()
        -- Old saved dismissals must not permanently silence future acquisitions.
    else
        if G.db.dismissed[key] then return end
        G.db.dismissed[key]=G.Now()
    end
    G.offers[#G.offers+1]={object=o.id,evidence=evidence,quantity=quantity}
    G.Chat('Bounty match: '..G.Items.Label(o)..' • '..G.Safe(G.DisplayOwner(o))..' • '..G.Money(o.reward)..'. Open the match prompt to continue.')
    if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_QUEST_LOG_OPEN) end
    if G.UI then G.UI.ShowOffer() end
end
