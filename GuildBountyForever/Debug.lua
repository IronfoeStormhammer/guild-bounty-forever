local _,G=...
local function showIdentity(identity)
    if not identity then G.Chat('No accessible full player identity.');return end
    local fields={};for _,key in ipairs({'name','firstName','surname','ruleset','guid','faction','class','level','region','source'}) do if identity[key]~=nil then fields[#fields+1]=key..'='..G.Safe(identity[key]) end end
    G.Chat(table.concat(fields,'; '))
end
function G.Command(msg)
    msg=(msg or ''):match('^%s*(.-)%s*$');local command,arg=msg:match('^(%S+)%s*(.-)$');command=command and command:lower() or ''
    if command=='' then G.UI.Toggle()
    elseif command=='help' then G.Tutorial.Start(true)
    elseif command=='testcod' then G.UI.TestCOD()
    elseif command=='matches' then
        G.lootOfferTimes={};local ok,err=G.Loot.Scan(false,true)
        if not ok then G.Chat(err) elseif not G.offers or #G.offers==0 then G.Chat('No cached open bounty matches found in your bags. Uncached rules retry when item data loads.') end
    elseif command=='sync' then G.Sync.Hello();G.Chat(G.Sync.Status())
    elseif command=='status' then
        local _,build,_,interface=GetBuildInfo();G.Chat('v'..G.VERSION..' • build '..build..' • interface '..interface..' • schema '..G.SCHEMA)
        G.Chat((G.ruleset or 'Ruleset API unavailable')..' • '..(GetGuildInfo('player') or 'No guild: local drafts')..' • '..G.Sync.Status())
        G.Chat('Combat getter: '..tostring((C_CombatLog and C_CombatLog.GetCurrentEventInfo~=nil) or CombatLogGetCurrentEventInfo~=nil)..'; detection permitted: '..tostring(G.PvP.Available()))
    local security=G.security or G.root.prefs.lastSecurity;if security then G.Chat('Last Blizzard block: '..G.Safe(security.action)..' ('..G.Safe(security.event)..')') end
    if G.scrollbarError then G.Chat('Optional scrollbar: '..G.Safe(G.scrollbarError)) end
    local failure=G.lastUIError or G.root.prefs.lastUIError;if failure then G.Chat('Last UI error: '..G.Safe(failure.action)..': '..G.Safe(failure.message)) end
    elseif command=='debug' then
        if arg=='' then G.db.prefs.debug=not G.db.prefs.debug;G.Chat('Debug '..(G.db.prefs.debug and 'on' or 'off'));return end
        if not G.db.prefs.debug then G.Chat('Enable diagnostics first: /gbf debug');return end
        local action,value=arg:match('^(%S+)%s*(.-)$');action=action and action:lower()
        if action=='identity' then showIdentity(G.player);G.Chat('Native surname separator: ['..G.People.Separator()..']')
        elseif action=='target' then local target,err=G.PvP.Target();if target then showIdentity(target) else G.Chat(err) end
        elseif action=='item' then local id=G.Items.ParseInput(value);local info=id and G.Items.Info(id);G.Chat(info and (info.link..' • ID '..id..' • level '..info.level..' • class '..tostring(info.classID)..'/'..tostring(info.subclassID)..' • '..tostring(info.slot)) or 'Invalid ID or uncached/unavailable item; no record created.')
        elseif action=='sync' then G.Sync.Hello();G.Chat(G.Sync.Status()..' • prefix '..G.Sync.prefix..' • context '..G.Safe(G.guildKey))
        elseif action=='records' then
            local counts={};for _,o in pairs(G.db.objects) do counts[o.kind]=(counts[o.kind] or 0)+1 end
            local parts={};for kind,count in pairs(counts) do parts[#parts+1]=kind..'='..count end;table.sort(parts);G.Chat(table.concat(parts,', '))
            if G.root.migration then G.Chat('Migrated records: '..G.root.migration.records..'; unresolved targets: '..G.root.migration.unresolved) end
        else G.Chat('/gbf debug identity | target | item <ID> | sync | records') end
    elseif command=='resetposition' then G.db.prefs.position=nil;if G.UI.frame then G.UI.frame:ClearAllPoints();G.UI.frame:SetPoint('CENTER') end
    else G.Chat('/gbf | help | status | matches | testcod | sync | debug | resetposition') end
end
