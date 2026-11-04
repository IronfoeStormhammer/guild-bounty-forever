local _,G=...
G.Items={requested={}};local I=G.Items
function I.ID(value)
    local n=tonumber(tostring(value or ''):match('item:(%d+)')) or tonumber(value)
    return G.Int(n,1,100000000) and n or nil
end
function I.ParseInput(value)
    if type(value)=='number' then return I.ID(value) end
    if type(value)~='string' then return nil end
    value=value:match('^%s*(.-)%s*$')
    if value:match('^%d+$') or value:match('^item:%d+:[^%s|]*$') or value:match('^|c%x%x%x%x%x%x%x%x|Hitem:%d+:.-|h.-|h|r$') or value:match('^|Hitem:%d+:.-|h.-|h$') then return I.ID(value) end
end
function I.Info(value)
    local api=C_Item and C_Item.GetItemInfo or GetItemInfo
    if not api then G.Debug('Item metadata API unavailable.');return nil end
    local ok,n,link,q,level,required,kind,sub,stack,slot,icon,price,classID,subclassID=pcall(api,value)
    if not ok then G.LogError('GetItemInfo',n);return nil end
    if not n then
        if C_Item and C_Item.RequestLoadItemDataByID then local id=I.ID(value);if id and (not I.requested[id] or G.Now()-I.requested[id]>30) then I.requested[id]=G.Now();C_Item.RequestLoadItemDataByID(id) end end
        return nil
    end
    return {id=I.ID(link),name=n,link=link,quality=q,level=level,required=required,slot=slot,icon=icon,classID=classID,subclassID=subclassID}
end
function I.Match(o,value)
    local id=I.ID(value);if not id then return false end
    if o.itemID then return o.itemID==id end
    local info=I.Info(value);if not info then return nil end
    for k,v in pairs(o.rules or {}) do
        if k=='minLevel' then if not info.level or info.level<v then return false end
        elseif k=='maxLevel' then if not info.level or info.level>v then return false end
        elseif k=='maxRequired' then if not info.required or info.required>v then return false end
        elseif k=='stats' then
            local api=C_Item and C_Item.GetItemStats or GetItemStats
            if not api then return nil end
            local ok,stats=pcall(api,info.link);if not ok or type(stats)~='table' then return nil end
            for stat,bounds in pairs(v) do local amount=stats[stat] or 0;if type(amount)~='number' then return nil end;if bounds.min and amount<bounds.min or bounds.max and amount>bounds.max then return false end end
        elseif k=='minRequired' then if not info.required or info.required<v then return false end
        elseif k=='classID' or k=='subclassID' or k=='slot' then if info[k]~=v then return false end
        else return false end
    end
    return true
end
function I.Label(o)
    if o.kind=='claim' then return o.title end
    if o.kind=='pvp' then return G.Safe(o.target.name) end
    if o.itemID then local info=I.Info(o.itemID);return info and info.link or ('Item #'..o.itemID..' (loading)') end
    return I.RulesLabel(o.rules or {})
end

function I.ClassName(id)
    if C_Item and C_Item.GetItemClassInfo then local ok,name=pcall(C_Item.GetItemClassInfo,tonumber(id));if ok and type(name)=='string' and name~='' then return name end end
    return 'Saved item type'
end
function I.SubclassName(classID,id)
    if C_Item and C_Item.GetItemSubClassInfo then local ok,name=pcall(C_Item.GetItemSubClassInfo,tonumber(classID),tonumber(id));if ok and type(name)=='string' and name~='' then return name end end
    return 'Saved subtype'
end
function I.ClassOptions()
    local options={{value='',label='Any item type'}}
    if C_Item and C_Item.GetItemClassInfo then
        for id=0,30 do local ok,name=pcall(C_Item.GetItemClassInfo,id);if ok and type(name)=='string' and name~='' then options[#options+1]={value=tostring(id),label=name} end end
    end
    return options
end
function I.SubclassOptions(classID)
    local options={{value='',label=classID and 'Any subtype' or 'Choose item type first'}}
    if classID and C_Item and C_Item.GetItemSubClassInfo then
        for id=0,30 do local ok,name=pcall(C_Item.GetItemSubClassInfo,tonumber(classID),id);if ok and type(name)=='string' and name~='' then options[#options+1]={value=tostring(id),label=name} end end
    end
    return options
end
local slots={
    {'INVTYPE_HEAD','Head'},{'INVTYPE_NECK','Neck'},{'INVTYPE_SHOULDER','Shoulder'},
    {'INVTYPE_BODY','Shirt'},{'INVTYPE_CHEST','Chest'},{'INVTYPE_ROBE','Robe'},
    {'INVTYPE_WAIST','Waist'},{'INVTYPE_LEGS','Legs'},{'INVTYPE_FEET','Feet'},
    {'INVTYPE_WRIST','Wrist'},{'INVTYPE_HAND','Hands'},{'INVTYPE_FINGER','Finger'},
    {'INVTYPE_TRINKET','Trinket'},{'INVTYPE_CLOAK','Back'},{'INVTYPE_WEAPON','One-Hand'},
    {'INVTYPE_2HWEAPON','Two-Hand'},{'INVTYPE_WEAPONMAINHAND','Main Hand'},
    {'INVTYPE_WEAPONOFFHAND','Off Hand'},{'INVTYPE_SHIELD','Shield'},{'INVTYPE_HOLDABLE','Held In Off-hand'},
    {'INVTYPE_RANGED','Ranged'},{'INVTYPE_RANGEDRIGHT','Ranged (right)'},{'INVTYPE_THROWN','Thrown'},
    {'INVTYPE_RELIC','Relic'},{'INVTYPE_BAG','Bag'},{'INVTYPE_TABARD','Tabard'},
    {'INVTYPE_AMMO','Ammunition'},{'INVTYPE_QUIVER','Quiver'},{'INVTYPE_NON_EQUIP_IGNORE','Not equippable'},
}
function I.SlotOptions()
    local result={{value='',label='Any equipment slot'}}
    for _,entry in ipairs(slots) do result[#result+1]={value=entry[1],label=_G[entry[1]] or entry[2]} end
    return result
end
function I.SlotName(value)
    for _,option in ipairs(I.SlotOptions()) do if option.value==value then return option.label end end
    return 'Saved equipment slot'
end
function I.RulesLabel(rules)
    local parts={}
    if rules.classID~=nil then parts[#parts+1]=I.ClassName(rules.classID) end
    if rules.subclassID~=nil then parts[#parts+1]=I.SubclassName(rules.classID,rules.subclassID) end
    if rules.slot then parts[#parts+1]=I.SlotName(rules.slot) end
    if rules.minLevel then parts[#parts+1]='Item level '..rules.minLevel..'+' end
    if rules.minRequired then parts[#parts+1]='Required level '..rules.minRequired..'+' end
    if rules.maxLevel then parts[#parts+1]='Item level ≤ '..rules.maxLevel end
    if rules.maxRequired then parts[#parts+1]='Required level ≤ '..rules.maxRequired end
    for _,option in ipairs(I.StatOptions()) do local b=rules.stats and rules.stats[option.value];if b then parts[#parts+1]=option.label..' '..(b.min and ('≥ '..b.min) or '')..(b.max and (' ≤ '..b.max) or '') end end
    return table.concat(parts,', ')
end

-- Enumerate native stat labels; only values returned by GetItemStats are matched.
function I.StatOptions()
    local names={ITEM_MOD_STRENGTH_SHORT='Strength',ITEM_MOD_AGILITY_SHORT='Agility',ITEM_MOD_STAMINA_SHORT='Stamina',ITEM_MOD_INTELLECT_SHORT='Intellect',ITEM_MOD_SPIRIT_SHORT='Spirit',ITEM_MOD_HEALTH_SHORT='Health',ITEM_MOD_MANA_SHORT='Mana',ITEM_MOD_ARMOR_SHORT='Armor',ITEM_MOD_ATTACK_POWER_SHORT='Attack Power',ITEM_MOD_SPELL_POWER_SHORT='Spell Power'}
    for key,value in pairs(_G) do if type(key)=='string' and key:match('^ITEM_MOD_[A-Z0-9_]+_SHORT$') and type(value)=='string' and value~='' then names[key]=value end end
    local options={};for key,label in pairs(names) do options[#options+1]={value=key,label=label} end
    table.sort(options,function(a,b) return a.label==b.label and a.value<b.value or a.label<b.label end);return options
end
