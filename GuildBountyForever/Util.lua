local _, G = ...
G.VERSION='1.0.0'; G.SCHEMA=2
function G.Now() return GetServerTime and GetServerTime() or time() end
function G.Copy(v) if type(v)~='table' then return v end local r={} for k,x in pairs(v) do r[k]=G.Copy(x) end return r end
function G.Int(n,lo,hi) return type(n)=='number' and n==math.floor(n) and n>=lo and n<=hi end
function G.Text(s,n) return type(s)=='string' and #s<=n and not s:find('[%z\1-\8\11\12\14-\31]') end
function G.Safe(s) return tostring(s or ''):gsub('|','||') end
function G.Chat(s) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cffffd200Guild Bounty:|r '..s) end end
function G.UIError(action,err)
    G.lastUIError={action=action,message=tostring(err),at=G.Now()}
    if G.root then G.root.prefs.lastUIError=G.lastUIError end
    if G.UI and G.UI.error then G.UI.error:SetText(action..' failed: '..tostring(err)) end
    G.Chat(G.Safe(action..' failed: '..tostring(err)))
end
function G.Refresh()
    if G.UI and G.UI.Refresh then
        local ok,err=pcall(G.UI.Refresh)
        if not ok then G.UIError('Refresh',err) end
    end
end
function G.NewID()
    G.db.counter=(G.db.counter or 0)+1
    return G.me..'/'..G.Now()..'/'..G.db.counter
end
function G.Debug(s)
    if not G.db or not G.db.prefs.debug then return end
    G.logs=G.logs or {};G.logs[#G.logs+1]={at=G.Now(),message=tostring(s)};if #G.logs>100 then table.remove(G.logs,1) end
    G.Chat(G.Safe(s))
end

function G.LogError(where,err) G.Debug(where..': '..tostring(err)) end

function G.CharCount(s) local _,n=s:gsub('[^\128-\191]','');return n end

function G.Date(format,timestamp)
    local formatter=date or (os and os.date)
    if formatter then local ok,value=pcall(formatter,format,timestamp);if ok then return value end end
    return tostring(timestamp or '')
end

function G.Money(amount)
    amount=G.Int(amount,0,100000000000) and amount or 0
    local formatter=C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or GetCoinTextureString
    if type(formatter)=='function' then local ok,value=pcall(formatter,amount);if ok and type(value)=='string' then return value end end
    return math.floor(amount/10000)..'|TInterface\\MoneyFrame\\UI-GoldIcon:0|t '..(math.floor(amount/100)%100)..'|TInterface\\MoneyFrame\\UI-SilverIcon:0|t '..(amount%100)..'|TInterface\\MoneyFrame\\UI-CopperIcon:0|t'
end
