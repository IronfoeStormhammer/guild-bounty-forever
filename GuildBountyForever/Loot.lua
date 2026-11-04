local _,G=...
G.Loot={pending={}}
local function process(link,quantity,method)
    local uncached=false
    for _,o in pairs(G.db.objects) do
        if o.kind=='request' and o.state=='open' and G.Remaining(o)>0 then
            local match=G.Items.Match(o,link)
            if match==nil then uncached=true
            elseif match then
                local key=o.id..':'..G.Items.ID(link)
                G.Offer(o,{itemID=G.Items.ID(link),link=link,at=G.Now(),zone=GetRealZoneText(),character=G.player.name,ruleset=G.ruleset,method=method or 'CHAT_MSG_LOOT (self)'},quantity,key)
            end
        end
    end
    return not uncached
end
local function lootPattern(format)
    local pattern,captures={},{};local i=1
    while i<=#format do
        local rest=format:sub(i)
        local token=rest:match('^%%[1-9]%d*%$[sd]') or rest:match('^%%[sd]')
        if token then
            local kind=token:sub(-1);captures[#captures+1]=kind;pattern[#pattern+1]=kind=='d' and '(%d+)' or '(.+)';i=i+#token
        else
            local char=format:sub(i,i);pattern[#pattern+1]=char:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])','%%%1');i=i+1
        end
    end
    return '^'..table.concat(pattern)..'$',captures
end
function G.Loot.ParseSelf(message)
    if type(message)~='string' then return nil end
    for _,format in ipairs({LOOT_ITEM_SELF_MULTIPLE or '',LOOT_ITEM_CREATED_SELF_MULTIPLE or '',LOOT_ITEM_PUSHED_SELF_MULTIPLE or '',LOOT_ITEM_SELF or '',LOOT_ITEM_CREATED_SELF or '',LOOT_ITEM_PUSHED_SELF or ''}) do
        if format~='' then
            local pattern,kinds=lootPattern(format);local values={message:match(pattern)}
            if #values>0 then
                local quantity=1;for index,kind in ipairs(kinds) do if kind=='d' then quantity=tonumber(values[index]) or 1 end end
                return math.max(1,math.min(quantity,100000))
            end
        end
    end
end
function G.Loot.Message(message)
    local quantity=G.Loot.ParseSelf(message)
    local selfLoot=quantity~=nil
    if not selfLoot then return end
    local link=message:match('(|c%x+|Hitem:.-|h.-|h|r)') or message:match('(|Hitem:.-|h.-|h)')
    if not link then return end
    if not process(link,quantity) then G.Loot.pending[#G.Loot.pending+1]={link=link,quantity=quantity,at=G.Now()} end
end
function G.Loot.Retry()
    local keep={};for _,v in ipairs(G.Loot.pending) do if G.Now()-v.at<30 and not process(v.link,v.quantity,v.method) then keep[#keep+1]=v end end;G.Loot.pending=keep
end

-- Inventory events cover acquisitions that do not emit a self-loot chat line.
-- Seed on login/context change; moves/splits with unchanged totals are ignored.
function G.Loot.Scan(initial,checkHeld)
    if not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerItemInfo then return nil,'Inventory API unavailable.' end
    local totals,links={},{}
    for bag=0,(NUM_BAG_SLOTS or 4) do
        for slot=1,C_Container.GetContainerNumSlots(bag) do
            local info=C_Container.GetContainerItemInfo(bag,slot)
            if info and info.itemID and info.stackCount then
                totals[info.itemID]=(totals[info.itemID] or 0)+info.stackCount;links[info.itemID]=info.hyperlink
            end
        end
    end
    local before=G.Loot.totals;G.Loot.totals=totals
    if (initial or not before) and not checkHeld then return true end
    before=before or {}
    for id,count in pairs(totals) do
        local gained=checkHeld and count or count-(before[id] or 0)
        if gained>0 then
            local link=links[id] or ('item:'..id)
            local method=checkHeld and 'Manual bag check (items currently held)' or 'BAG_UPDATE_DELAYED inventory increase'
            if not process(link,gained,method) then G.Loot.pending[#G.Loot.pending+1]={link=link,quantity=gained,at=G.Now(),method=method} end
        end
    end
    return true
end
