local _,G=...
G.People={};local P=G.People
local function public(v) return not issecretvalue or not issecretvalue(v) end
function P.Separator()
    local c=Constants and Constants.CharacterNameSeparatorConsts
    return c and c.CHARACTERNAME_SURNAME_SEPARATOR or ' '
end
local function trim(s) return type(s)=='string' and s:match('^%s*(.-)%s*$') or nil end
function P.Parts(value)
    value=trim(value);if not value or value=='' then return end
    local first,last
    if NameUtil and NameUtil.SplitPlayerNameIntoParts then
        local ok,a,b=pcall(NameUtil.SplitPlayerNameIntoParts,value);if ok then first,last=a,b end
    end
    if not first then
        local sep=P.Separator();local at=value:find(sep,1,true)
        if at then first,last=value:sub(1,at-1),value:sub(at+#sep) end
    end
    -- Keyboard input uses a space even if a localized native separator differs.
    if not first then first,last=value:match('^(%S+)%s+(.+)$') end
    if not first or not last then return end
    first,last=trim(first),trim(last)
    if first=='' or last=='' or first:find('%s') or last:find('%s') or first:find('[|:/%c%d]') or last:find('[|:/%c%d]') then return end
    return first,last
end
function P.Name(value)
    local a,b=P.Parts(value);if a then return a..P.Separator()..b end
end
function P.NameKey(value)
    local name=P.Name(value);return name and (strlower and strlower(name) or name:lower()) or nil
end
function P.Join(first,last)
    if not public(first) or not public(last) then return end
    if P.Name(first) then return P.Name(first) end
    return first and last and P.Name(first..P.Separator()..last) or nil
end
function P.Ruleset()
    local rules=Enum and Enum.GameRule
    if not (C_GameRules and C_GameRules.IsGameRuleActive and rules and rules.PvPRuleset and rules.RPRuleset) then return nil end
    local ok,pvp=pcall(C_GameRules.IsGameRuleActive,rules.PvPRuleset)
    local ok2,rp=pcall(C_GameRules.IsGameRuleActive,rules.RPRuleset)
    if not ok or not ok2 or not public(pvp) or not public(rp) then return nil end
    return rp and (pvp and 'RP-PvP' or 'RP-PvE') or (pvp and 'PvP' or 'PvE')
end
function P.Context()
    local region=GetCurrentRegion and GetCurrentRegion() or nil
    return P.Ruleset(),region
end
function P.Unit(unit,source)
    local first,last
    local getter=UnitNameUnmodified or UnitName
    if getter then local ok,a,b=pcall(getter,unit);if ok and public(a) and public(b) then first,last=a,b end end
    local name=P.Join(first,last)
    if NameUtil and NameUtil.GetUnmodifiedUnitFullName then
        local ok,n=pcall(NameUtil.GetUnmodifiedUnitFullName,unit);if ok and public(n) then name=P.Name(n) or name end
    end
    if not name then return nil end
    local a,b=P.Parts(name);local ruleset,region=P.Context()
    local result={name=name,firstName=a,surname=b,ruleset=ruleset,region=region,source=source or 'unit'}
    local function field(key,fn,...)
        if not fn then return end;local ok,value=pcall(fn,...);if ok and public(value) and value~=nil and value~='' then result[key]=value end
    end
    field('guid',UnitGUID,unit);field('faction',UnitFactionGroup,unit);field('level',UnitLevel,unit)
    if result.level and (type(result.level)~='number' or result.level<1) then result.level=nil end
    if UnitClass then local ok,_,class=pcall(UnitClass,unit);if ok and public(class) then result.class=class end end
    if UnitPVPRank and GetPVPRankInfo then
        local ok,rank=pcall(UnitPVPRank,unit)
        if ok and public(rank) and type(rank)=='number' then
            local valid,title,number=pcall(GetPVPRankInfo,rank,unit)
            if valid and public(title) and public(number) and G.Int(number,0,20) then result.pvpRank=number;if type(title)=='string' then result.pvpRankName=title end end
        end
    end
    return result
end
function P.Manual(name)
    local full=P.Name(name);if not full then return nil end
    local first,last=P.Parts(full)
    return {name=full,firstName=first,surname=last,ruleset=G.ruleset,region=G.region,source='manual'}
end
function P.Key(info)
    if not info then return nil end
    if info.guid and info.guid:match('^Player%-') then return info.guid end
    local key=P.NameKey(info.name)
    return key and ('name:'..(info.ruleset or 'unknown')..':'..key) or nil
end
function P.Valid(info,allowLegacy)
    if type(info)~='table' or not G.Text(info.name,100) then return false end
    if not P.Name(info.name) and not (allowLegacy and info.source=='migration') then return false end
    local fields={name=100,firstName=50,surname=50,guid=100,faction=30,class=30,source=30,pvpRankName=100}
    for k,v in pairs(info) do
        if fields[k] then if not G.Text(v,fields[k]) then return false end
        elseif k=='ruleset' then if v~='PvE' and v~='PvP' and v~='RP-PvE' and v~='RP-PvP' then return false end
        elseif k=='region' then if not G.Int(v,1,20) then return false end
        elseif k=='pvpRank' then if not G.Int(v,0,20) then return false end
        elseif k=='level' then if not G.Int(v,1,255) then return false end
        else return false end
    end
    if info.guid and not info.guid:match('^Player%-[%w%-]+$') then return false end
    return true
end
function P.Observe(info,source)
    if not G.db or not P.Valid(info) or not info.guid then return end
    local old=G.db.observations[info.guid]
    local record=old and G.Copy(old.identity) or {}
    for k,v in pairs(info) do record[k]=v end
    record.source=source or info.source or 'unit'
    G.db.observations[info.guid]={identity=record,at=G.Now(),observer=G.me}
end
function P.Resolve(target)
    if target.guid then
        local copy=G.Copy(target);local observed=G.db.observations[target.guid]
        if observed then for k,v in pairs(observed.identity) do copy[k]=v end end
        return copy,'GUID captured'
    end
    local key=P.NameKey(target.name);if not key or not target.ruleset then return G.Copy(target),'Unresolved' end
    local found
    for _,v in pairs(G.db.observations) do
        local i=v.identity
        if i.ruleset==target.ruleset and P.NameKey(i.name)==key then
            if found and found.guid~=i.guid then return G.Copy(target),'Ambiguous observations' end
            found=i
        end
    end
    if found then local result=G.Copy(target);for k,v in pairs(found) do result[k]=v end;return result,'Observed locally ('..found.source..')' end
    return G.Copy(target),'Unresolved'
end
function P.RefreshPlayer()
    local player=P.Unit('player','unit');if not player then return nil end
    G.player=player;G.ruleset,G.region=P.Context();G.me=P.Key(player);return G.me~=nil
end
function G.Identity(name)
    if name then return P.Name(name) end
    return G.player and G.player.name or (P.Unit('player') or {}).name
end
function G.DisplayOwner(o) return o.creator and o.creator.name or (o.owner==G.me and G.player.name) or 'Unresolved character' end
function G.GuildKey()
    local name=GetGuildInfo and GetGuildInfo('player')
    if not name or name=='' then return nil end
    return tostring(G.region or 'unknown')..':'..(G.ruleset or 'unknown')..':guild:'..name
end
