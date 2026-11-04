local _,G=...
G.Form={}
local function integer(value,lo,hi)
    if type(value)~='string' or not value:match('^%s*%d+%s*$') then return nil end
    local n=tonumber(value);return G.Int(n,lo,hi) and n or nil
end
G.Form.Integer=integer
local slots={INVTYPE_NON_EQUIP_IGNORE=true,INVTYPE_HEAD=true,INVTYPE_NECK=true,INVTYPE_SHOULDER=true,INVTYPE_BODY=true,INVTYPE_CHEST=true,INVTYPE_WAIST=true,INVTYPE_LEGS=true,INVTYPE_FEET=true,INVTYPE_WRIST=true,INVTYPE_HAND=true,INVTYPE_FINGER=true,INVTYPE_TRINKET=true,INVTYPE_WEAPON=true,INVTYPE_SHIELD=true,INVTYPE_RANGED=true,INVTYPE_CLOAK=true,INVTYPE_2HWEAPON=true,INVTYPE_BAG=true,INVTYPE_TABARD=true,INVTYPE_ROBE=true,INVTYPE_WEAPONMAINHAND=true,INVTYPE_WEAPONOFFHAND=true,INVTYPE_HOLDABLE=true,INVTYPE_AMMO=true,INVTYPE_THROWN=true,INVTYPE_RANGEDRIGHT=true,INVTYPE_QUIVER=true,INVTYPE_RELIC=true}
function G.Form.Build(draft)
    local mode=draft.mode
    if mode~=1 and mode~=2 and mode~=3 then return nil,'Select a request type.' end
    local gold=integer(draft.gold,0,10000000);local silver=integer(draft.silver,0,99);local copper=integer(draft.copper,0,99)
    if not gold or not silver or not copper then return nil,'Enter whole rewards: gold ≥ 0, silver/copper 0–99.' end
    local quantity=mode==3 and 1 or integer(draft.quantity,1,100000)
    if not quantity then return nil,'Quantity must be a whole number from 1 to 100000.' end
    local note=(draft.note or ''):gsub('[\r\n]',' ')
    if not G.Text(note,2000) or G.CharCount(note)>500 then return nil,'The note limit is 500 characters.' end
    local fields={quantity=quantity,reward=gold*10000+silver*100+copper,note=note}
    if mode==1 then
        local id=G.Items.ParseInput(draft.item)
        if not id then return nil,'Enter an item ID or a complete item link.' end
        local info=G.Items.Info(id)
        if not info then return nil,'Item information is loading or unavailable. Wait, or check the ID.' end
        if info.id~=id then return nil,'The item could not be resolved.' end
        fields.itemID=id;fields.title=info.name;return 'request',fields
    elseif mode==2 then
        local rules={};local mapping={class='classID',subclass='subclassID',level='minLevel',required='minRequired',maxLevel='maxLevel',maxRequired='maxRequired'}
        for field,key in pairs(mapping) do
            local value=draft[field] or ''
            if value~='' then
                local min=(field=='class' or field=='subclass') and 0 or 1
                local max=(field=='required' or field=='maxRequired') and 255 or (field=='class' or field=='subclass') and 30 or 10000
                local n=integer(value,min,max);if not n then return nil,'Check the numeric rule fields.' end;rules[key]=n
            end
        end
        local slot=(draft.slot or ''):match('^%s*(.-)%s*$')
        if slot~='' then if not slots[slot] then return nil,'Choose a valid equipment slot.' end;rules.slot=slot end
        if rules.subclassID and not rules.classID then return nil,'Choose an item type before a subtype.' end
        for _,pair in ipairs({{'minLevel','maxLevel'},{'minRequired','maxRequired'}}) do if rules[pair[1]] and rules[pair[2]] and rules[pair[1]]>rules[pair[2]] then return nil,'Minimum level must not exceed maximum level.' end end
        local stats={};local statCount=0
        for key,bounds in pairs(draft.stats or {}) do
            if type(key)~='string' or not key:match('^ITEM_MOD_[A-Z0-9_]+_SHORT$') or type(bounds)~='table' then return nil,'Choose a supported stat.' end
            local range={};for _,bound in ipairs({'min','max'}) do local value=bounds[bound];if value~=nil and value~='' then range[bound]=integer(tostring(value),0,1000000);if not range[bound] then return nil,'Stat limits must be whole numbers from 0 to 1000000.' end end end
            if range.min and range.max and range.min>range.max then return nil,'Minimum stat must not exceed maximum stat.' end
            if next(range) then statCount=statCount+1;if statCount>80 then return nil,'Use at most 80 stat requirements.' end;stats[key]=range end
        end
        if next(stats) then rules.stats=stats end
        if not next(rules) then return nil,'Set at least one meaningful rule.' end
        if C_Item and C_Item.GetItemClassInfo and rules.classID then
            local ok,value=pcall(C_Item.GetItemClassInfo,rules.classID);if not ok or not value then return nil,'Choose an available item type.' end
        end
        if C_Item and C_Item.GetItemSubClassInfo and rules.classID and rules.subclassID then
            local ok,value=pcall(C_Item.GetItemSubClassInfo,rules.classID,rules.subclassID);if not ok or not value then return nil,'Choose an available subtype for this item type.' end
        end
        fields.rules=rules;fields.title='Rule request';return 'request',fields
    end
    local target=G.People.Manual(draft.target)
    if not target then return nil,'Enter the full character name, including surname.' end
    if draft.targetInfo and G.People.Valid(draft.targetInfo) and G.People.NameKey(draft.targetInfo.name)==G.People.NameKey(target.name) then target=G.Copy(draft.targetInfo) end
    fields.target=target;fields.title=target.name;return 'pvp',fields
end
