local _,G=...
G.PvP={hits={}}
local P=G.PvP
function P.Target()
    if not UnitExists('target') or not UnitIsPlayer('target') or not UnitCanAttack('player','target') then return nil,'Target an opposing player.' end
    local identity=G.People.Unit('target','target')
    if not identity then return nil,'The target full name is unavailable.' end
    G.People.Observe(identity,'target');return identity
end
function P.ObserveTarget()
    if UnitExists('target') and UnitIsPlayer('target') then
        local identity=G.People.Unit('target','target');if identity then G.People.Observe(identity,'target');G.Refresh() end
    end
end
function P.Matches(o,guid,name,ruleset)
    local target,resolution=G.People.Resolve(o.target)
    if target.guid then return type(guid)=='string' and target.guid==guid end
    if resolution=='Ambiguous observations' then return false end
    local key=G.People.NameKey(name)
    return key and target.ruleset and ruleset and target.ruleset==ruleset and G.People.NameKey(target.name)==key or false
end
function P.Kill(guid,name,method,event,sourceGUID,sourceName,flags,combatTime)
    for _,o in pairs(G.db.objects) do
        if o.kind=='pvp' and o.state=='open' and G.Remaining(o)>0 and P.Matches(o,guid,name,G.ruleset) then
            local recent=false
            for _,v in pairs(G.db.evidence) do if v.parent==o.id and v.evidence.targetGUID==guid and math.abs(G.Now()-v.evidence.at)<15 then recent=true;break end end
            local key=o.id..':'..guid..':'..G.Now()
            if not recent and not G.db.evidence[key] then
                local e={targetGUID=guid,targetName=name or '',at=G.Now(),zone=GetRealZoneText(),character=G.player.name,ruleset=G.ruleset,method=method,event=event,sourceGUID=sourceGUID or '',sourceName=sourceName or '',flags=flags or 0,combatTime=combatTime or 0}
                G.db.evidence[key]={parent=o.id,evidence=e}
                G.Offer(o,e,1,key)
            end
        end
    end
end
function P.Available()
    if G.combatBlocked then return false end
    local getter=C_CombatLog and C_CombatLog.GetCurrentEventInfo or CombatLogGetCurrentEventInfo
    if type(getter)~='function' then return false end
    if C_CombatLog and C_CombatLog.IsCombatLogRestricted then
        local ok,restricted=pcall(C_CombatLog.IsCombatLogRestricted)
        if not ok or (issecretvalue and issecretvalue(restricted)) or restricted then return false end
    end
    return true
end
function P.Combat()
    if not P.Available() then return end
    local getEvent=C_CombatLog and C_CombatLog.GetCurrentEventInfo or CombatLogGetCurrentEventInfo
    local ok,ts,event,hidden,sg,sn,sf,sr,dg,dn,df=pcall(getEvent)
    if not ok then G.LogError('Combat event getter',ts);return end
    if issecretvalue and (issecretvalue(ts) or issecretvalue(sn) or issecretvalue(sf) or issecretvalue(event) or issecretvalue(dg) or issecretvalue(sg) or issecretvalue(df) or issecretvalue(dn)) then return end
    if type(event)~='string' or type(dg)~='string' or not dg:match('^Player%-') then return end
    local hostile=Enum and Enum.CombatLogObject and Enum.CombatLogObject.ReactionHostile or COMBATLOG_OBJECT_REACTION_HOSTILE or 0x40
    if type(df)~='number' or not bit or bit.band(df,hostile)==0 then return end
    local full=G.People.Name(dn)
    if full and G.ruleset then local identity=G.People.Manual(full);identity.guid=dg;identity.source='combat';G.People.Observe(identity,'combat') end
    local mine=sg==G.player.guid
    if mine and event:find('_DAMAGE',1,true) then P.hits[dg]={at=G.Now(),source=sg,name=sn} end
    if event=='PARTY_KILL' and mine then
        P.Kill(dg,dn,'Personal PARTY_KILL credit',event,sg,sn,df,ts)
    elseif event=='UNIT_DIED' then
        local h=P.hits[dg]
        if h and G.Now()-h.at<=30 then P.Kill(dg,dn,'Recent personal damage + UNIT_DIED; participation only',event,h.source,h.name,df,ts) end
        P.hits[dg]=nil
    end
    for id,h in pairs(P.hits) do if G.Now()-h.at>30 then P.hits[id]=nil end end
end

function P.Art(target)
    local identity=G.People.Resolve(target)
    local icon=identity.class and ('Interface\\Icons\\ClassIcon_'..identity.class:lower()) or ('Interface\\PvPRankBadges\\PvPRank'..(identity.faction=='Horde' and 'Horde' or 'Alliance'))
    local rank='Rank unavailable'
    if identity.pvpRank~=nil then
        rank=identity.pvpRank==0 and 'Unranked' or ('Rank '..identity.pvpRank..(identity.pvpRankName and ' '..identity.pvpRankName or ''))
        if identity.pvpRank>0 and identity.pvpRank<=14 then rank='|TInterface\\PvPRankBadges\\PvPRank'..string.format('%02d',identity.pvpRank)..':18|t '..rank end
    end
    return icon,rank
end
