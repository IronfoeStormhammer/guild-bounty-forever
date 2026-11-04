local _,G=...
local f=CreateFrame('Frame');G.events=f
local loaded,ready=false,false
local function initialize()
    if ready or not loaded or not G.People.RefreshPlayer() then return ready end
    local ok,err=G.InitDB();if not ok then G.Chat(err);return false end
    ready=true
    if G.security then G.root.prefs.lastSecurity=G.security end
    if G.PvP.Available() then
        local registered,reason=pcall(f.RegisterEvent,f,'COMBAT_LOG_EVENT_UNFILTERED')
        if not registered then G.LogError('Combat event registration',reason) end
    end
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        local registered,result=pcall(C_ChatInfo.RegisterAddonMessagePrefix,G.Sync.prefix)
        if not registered then G.LogError('RegisterAddonMessagePrefix',result) end
    end
    f:SetScript('OnUpdate',function(_,elapsed) G.Sync.Update(elapsed) end)
    return true
end
local function guildContext()
    if not ready then return end
    G.People.RefreshPlayer();local previous=G.guildKey;G.SwitchGuild();G.Sync.Roster()
    if previous~=G.guildKey then G.Loot.Scan(true);C_Timer.After(2,function() if G.db then G.Sync.Hello() end end);G.Refresh() end
end
for _,event in ipairs({'ADDON_LOADED','PLAYER_LOGIN','PLAYER_GUILD_UPDATE','GUILD_ROSTER_UPDATE','CHAT_MSG_ADDON','CHAT_MSG_LOOT','GET_ITEM_INFO_RECEIVED','ITEM_DATA_LOAD_RESULT','BAG_UPDATE_DELAYED','PLAYER_TARGET_CHANGED','UNIT_NAME_UPDATE','GAME_RULES_CHANGED','PLAYER_LOGOUT','MAIL_SHOW','MAIL_CLOSED','MAIL_SEND_SUCCESS','MAIL_FAILED','MAIL_INBOX_UPDATE','MAIL_SUCCESS','ADDON_ACTION_BLOCKED','ADDON_ACTION_FORBIDDEN'}) do
    local ok,err=pcall(f.RegisterEvent,f,event);if not ok then G.LogError('RegisterEvent '..event,err) end
end
local function dispatch(event,...)
    if event=='ADDON_ACTION_BLOCKED' or event=='ADDON_ACTION_FORBIDDEN' then
        local addon,action=...
        if addon=='GuildBountyForever' then
            local previous=G.security
            G.security={event=event,action=tostring(action or 'unknown'),at=G.Now()}
            if G.root then G.root.prefs.lastSecurity=G.security end
            if action and (tostring(action):find('Combat',1,true) or tostring(action):find('COMBAT',1,true)) then G.combatBlocked=true end
            if not previous or previous.action~=G.security.action then G.Chat('Blizzard blocked '..G.Safe(action or 'unknown action')..'. Details: /gbf status') end
        end
        return
    elseif event=='ADDON_LOADED' then
        if ...~='GuildBountyForever' then return end
        loaded=true
        SLASH_GUILDBOUNTYFOREVER1='/gbf';SlashCmdList.GUILDBOUNTYFOREVER=function(msg)
            if not ready and not initialize() then G.Chat('Player identity is not available yet. Try after login.');return end
            local ok,err=pcall(G.Command,msg);if not ok then G.LogError('Slash command',err) end
        end
        initialize()
    elseif event=='PLAYER_LOGIN' then
        if not initialize() then return end
        guildContext();G.Loot.Scan(true);G.Tutorial.OnLogin()
        C_Timer.After(7,function() if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end;G.Sync.Hello() end)
    elseif not ready then return
    elseif event=='PLAYER_GUILD_UPDATE' or event=='GUILD_ROSTER_UPDATE' or event=='GAME_RULES_CHANGED' then guildContext()
    elseif event=='MAIL_SHOW' or event=='MAIL_CLOSED' or event=='MAIL_SEND_SUCCESS' or event=='MAIL_FAILED' or event=='MAIL_INBOX_UPDATE' or event=='MAIL_SUCCESS' then G.Mail.Event(event)
    elseif event=='CHAT_MSG_ADDON' then G.Sync.Receive(...)
    elseif event=='CHAT_MSG_LOOT' then G.Loot.Message(...)
    elseif event=='BAG_UPDATE_DELAYED' then G.Loot.Scan(false);G.Mail.Event(event)
    elseif event=='GET_ITEM_INFO_RECEIVED' or event=='ITEM_DATA_LOAD_RESULT' then G.Loot.Retry();if G.UI and G.UI.ItemPreview then G.UI.ItemPreview() end;G.Refresh()
    elseif event=='PLAYER_TARGET_CHANGED' then G.PvP.ObserveTarget()
    elseif event=='UNIT_NAME_UPDATE' then local unit=...;if unit=='player' then guildContext() elseif unit=='target' then G.PvP.ObserveTarget() end
    elseif event=='COMBAT_LOG_EVENT_UNFILTERED' then G.PvP.Combat(event)
    elseif event=='PLAYER_LOGOUT' then G.root.counter=G.db.counter end
end
f:SetScript('OnEvent',function(_,event,...)
    local ok,err=pcall(dispatch,event,...);if not ok then G.LogError(event,err) end
end)
