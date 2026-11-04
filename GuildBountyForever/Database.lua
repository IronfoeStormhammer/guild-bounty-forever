local _, G = ...
function G.InitDB()
    if type(GuildBountyForeverDB)~='table' then GuildBountyForeverDB={} end
    local db=GuildBountyForeverDB
    if type(db.schema)=='number' and db.schema>G.SCHEMA then return nil,'SavedVariables are from a newer addon. Update the addon.' end
    G.Migrate(db)
    db.schema=G.SCHEMA;db.prefs=type(db.prefs)=='table' and db.prefs or {};db.counter=G.Int(db.counter,0,1000000000) and db.counter or 0;db.partitions=type(db.partitions)=='table' and db.partitions or {}
    G.root=db;G.guildKey=nil; G.SwitchGuild();return true
end
function G.SwitchGuild()
    local key=G.GuildKey() or ('local:'..G.me)
    if G.guildKey==key then return end
    G.guildKey=key
    local guildName=GetGuildInfo and GetGuildInfo('player')
    if guildName and type(G.root.legacyScopes)=='table' then
        for oldKey,context in pairs(G.root.legacyScopes) do
            if type(context)=='table' and context.guildName==guildName then
                local old=G.root.partitions[oldKey]
                if type(old)=='table' then
                    local destination=G.root.partitions[key] or {};G.root.partitions[key]=destination
                    for _,field in ipairs({'objects','history','dismissed','evidence','observations'}) do
                        destination[field]=type(destination[field])=='table' and destination[field] or {}
                        for id,value in pairs(type(old[field])=='table' and old[field] or {}) do
                            local current=destination[field][id]
                            if not current or (field=='objects' and type(value)=='table' and type(current)=='table' and (tonumber(value.rev) or 0)>(tonumber(current.rev) or 0)) then destination[field][id]=value end
                        end
                    end
                    G.root.partitions[oldKey]=nil
                end
                G.root.legacyScopes[oldKey]=nil
            end
        end
    end
    local d=G.root.partitions[key];if type(d)~='table' then d={} G.root.partitions[key]=d end
    for _,k in ipairs({'objects','history','dismissed','evidence','sync','observations'}) do if type(d[k])~='table' then d[k]={} end end
    d.prefs=G.root.prefs;d.counter=math.max(G.Int(d.counter,0,1000000000) and d.counter or 0,G.root.counter or 0);G.db=d
    for id,o in pairs(d.objects) do if not G.Validate(o) or id~=o.id then d.objects[id]=nil end end
    for id,h in pairs(d.history) do if type(h)~='table' or not G.Text(h.id,180) or not G.Int(h.rev,1,1000000) or not G.Int(h.at,1,1e11) or not G.Text(h.actor,100) or not G.Text(h.title,160) or not G.Text(h.state,40) then d.history[id]=nil end end
    for id,v in pairs(d.evidence) do if type(v)~='table' or not G.Text(v.parent,180) or type(v.evidence)~='table' or not G.Int(v.evidence.at,1,1e11) then d.evidence[id]=nil end end
    for id,v in pairs(d.dismissed) do if type(id)~='string' or type(v)~='number' then d.dismissed[id]=nil end end
    for id,v in pairs(d.observations) do if type(v)~='table' or not G.People.Valid(v.identity) or id~=v.identity.guid then d.observations[id]=nil end end
    for _,o in pairs(d.objects) do if o.kind=='history' then G.Record(o) end end
    G.offers={};G.lootOfferTimes={};if G.Loot then G.Loot.pending={};G.Loot.totals=nil end;if G.PvP then G.PvP.hits={} end
    G.People.Observe(G.player,'unit')
    if G.Sync then G.Sync.Reset() end
    if G.UI then G.UI.selected=nil;if G.UI.editor then G.UI.editor:Hide();if G.UI.board then G.UI.board:Show();G.UI.detail:Show() end end end
end
function G.Merge(o,sender,localChange)
    if not G.Validate(o) then return nil,'Malformed object.' end
    local old=G.db.objects[o.id]
    if old then
        if old.owner~=o.owner or old.kind~=o.kind or old.created~=o.created then return nil,'Identity changed.' end
        if o.rev<old.rev then return nil,'Old revision.' end
        if o.rev==old.rev then
            local a,b=G.Codec.Encode(o),G.Codec.Encode(old)
            if not a or not b or a<=b then return nil,'Duplicate or losing revision.' end
        end
    end
    -- Live mutations must be signed by their channel sender. Forwarded snapshots are
    -- explicitly guild-trust data; they are not authenticated author signatures.
    if localChange and sender~=o.owner then return nil,'Wrong actor.' end
    if o.kind=='claim' then
        local p=G.db.objects[o.parent]
        if p and p.kind~='request' and p.kind~='pvp' then return nil,'Invalid parent.' end
    end
    -- Creator snapshots are ordered as whole objects. Context-dependent merge
    -- vetoes would make peers diverge when revisions arrive in different orders.
    local count=0;for _ in pairs(G.db.objects) do count=count+1 end
    local needed=not old and 1 or 0
    if localChange and o.kind~='history' then needed=needed+1 end
    if count+needed>10000 then return nil,'Database capacity reached.' end
    G.db.objects[o.id]=G.Copy(o);G.Record(o,old,localChange)
    if localChange and G.Sync then G.Sync.Publish(o) end
    if not localChange and G.NotifyChange then G.NotifyChange(o,old) end
    if G.Sync and G.Sync.Invalidate then G.Sync.Invalidate() end
    G.Refresh();return true
end
