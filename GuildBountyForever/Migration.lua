local _,G=...
local function hash(s) local h=0;for i=1,#s do h=(h*33+s:byte(i))%2147483647 end;return tostring(h) end
-- Schema 1 encoded an obsolete location suffix into names and partition keys.
-- Recover only names supported by the native two-part representation; never
-- guess missing surname boundaries from compressed text.
function G.Migrate(db)
    if db.schema==G.SCHEMA then return end
    local old=type(db.guilds)=='table' and db.guilds or {}
    local partitions=type(db.partitions)=='table' and db.partitions or {}
    db.legacyScopes=type(db.legacyScopes)=='table' and db.legacyScopes or {}
    local currentGuild=GetGuildInfo and GetGuildInfo('player')
    local report={from=tonumber(db.schema) or 0,at=G.Now(),records=0,unresolved=0}
    for scope,d in pairs(old) do if type(d)=='table' then
        local location,guild=tostring(scope):match('^(.-):(.+)$')
        local destination=(guild==currentGuild and G.GuildKey()) or (tostring(scope):match('^unguilded:') and ('local:'..G.me)) or ('legacy:'..hash(tostring(scope)))
        local out=partitions[destination] or {objects={},history={},dismissed={},evidence={},observations={},sync={}}
        partitions[destination]=out
        if guild and guild~=currentGuild and location~='unguilded' then db.legacyScopes[destination]={guildName=guild} end
        local owners,ids={},{}
        local function recover(value)
            if type(value)~='string' then return {name='Unresolved character',source='migration'} end
            local name=value
            if location and location~='unguilded' and name:sub(-#location-1)=='-'..location then name=name:sub(1,-#location-2) end
            local full=G.People.Name(name)
            local compact=(G.player.name:gsub('%s',''))
            if name==G.player.firstName..'-'..G.player.surname or name==G.player.name or name:gsub('%s','')==compact or name:match('^(.-)%-')==compact then return G.Copy(G.player) end
            if full then local p=G.People.Manual(full);p.source='migration';return p end
            return {name=name:find('-',1,true) and 'Unresolved character' or name,source='migration'}
        end
        local objects=type(d.objects)=='table' and d.objects or {}
        for id,o in pairs(objects) do if type(o)=='table' and type(o.owner)=='string' and type(id)=='string' then
            local person=recover(o.owner);local owner=(person.guid and G.People.Key(person)) or (person.source~='migration' and G.People.Key(person)) or (person.name~='Unresolved character' and G.People.Name(person.name) and G.People.Key(person)) or ('legacy:'..hash(o.owner))
            owners[o.owner]={key=owner,person=person}
            local suffix=id:sub(#o.owner+1);ids[id]=owner..suffix
        end end
        local function ref(id) return ids[id] or id end
        for id,o in pairs(objects) do if ids[id] and owners[o.owner] then
            local who=owners[o.owner];local n={id=ids[id],owner=who.key,creator=G.Copy(who.person),kind=o.kind,created=o.created,updated=o.updated,rev=o.rev,state=o.state,title=o.title,note=o.note or '',quantity=o.quantity,reward=o.reward}
            if n.kind=='request' then n.itemID=o.itemID;n.rules=G.Copy(o.rules)
            elseif n.kind=='pvp' then
                local target=type(o.target)=='table' and o.target or {};n.target=recover(target.name)
                for _,k in ipairs({'guid','faction','class','level'}) do n.target[k]=target[k] end
                n.title=n.target.name
                if not G.People.Name(n.target.name) then report.unresolved=report.unresolved+1 end
            elseif n.kind=='claim' then
                n.parent=ref(o.parent);n.evidence=G.Copy(o.evidence or {});n.evidence.character=who.person.name
                for _,k in ipairs({'targetName','sourceName'}) do if n.evidence[k] then n.evidence[k]=recover(n.evidence[k]).name end end
            elseif n.kind=='history' then
                n.parent=ref(o.parent);n.originRev=o.originRev;n.eventState=o.eventState;n.action=o.action
                if type(n.parent)=='string' and type(n.originRev)=='number' then n.id=n.parent..'/history/'..n.originRev;ids[id]=n.id end
            end
            if n.kind=='request' or n.kind=='pvp' then n.decisions={};for claim,decision in pairs(type(o.decisions)=='table' and o.decisions or {}) do n.decisions[ref(claim)]=G.Copy(decision) end end
            out.objects[n.id]=n;report.records=report.records+1
        end end
        for key,h in pairs(type(d.history)=='table' and d.history or {}) do if type(h)=='table' and type(h.id)=='string' then
            local n=G.Copy(h);n.id=ref(h.id) or ('legacy:'..hash(tostring(key)));local who=owners[h.actor];n.actor=who and who.key or 'legacy:'..hash(tostring(h.actor));n.actorName=who and who.person.name or 'Unresolved character'
            n.parent=h.parent and ref(h.parent) or nil;out.history[n.id..':'..tostring(n.rev)]=n
        end end
        for key,value in pairs(type(d.dismissed)=='table' and d.dismissed or {}) do
            if type(key)=='string' then local changed=key;for from,to in pairs(ids) do if changed:sub(1,#from)==from then changed=to..changed:sub(#from+1);break end end;out.dismissed[changed]=value end
        end
        for key,v in pairs(type(d.evidence)=='table' and d.evidence or {}) do if type(v)=='table' and type(v.evidence)=='table' then local n=G.Copy(v);n.parent=ref(n.parent);n.evidence.character=G.player.name;for _,k in ipairs({'targetName','sourceName'}) do if n.evidence[k] then n.evidence[k]=recover(n.evidence[k]).name end end;out.evidence['migrated:'..hash(tostring(key))]=n end end
        out.counter=math.max(out.counter or 0,tonumber(d.counter) or 0);out.sync={migratedAt=G.Now()}
    end end
    db.partitions=partitions;db.guilds=nil;db.migration=report;db.schema=G.SCHEMA
end
