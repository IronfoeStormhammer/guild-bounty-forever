local _,G=...
G.Sync={};local S=G.Sync
local queue,assemblies,pending,peers,roster={},{},{},{},{}
local serial,tick,lastHello=0,0,0
local jobs,digestCache,rates={},nil,{}
function S.Invalidate() digestCache=nil end
S.prefix='GBF2'
function S.Reset() queue={};assemblies={};pending={};peers={};roster={};jobs={};digestCache=nil;rates={};lastHello=G.Now() end
function S.Roster()
    roster={}
    for i=1,GetNumGuildMembers() do local n,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,guid=GetGuildRosterInfo(i);local key=G.People.NameKey(n);if key then
            local actor=G.People.Key({name=n,guid=guid,ruleset=G.ruleset})
            if actor then roster[key]={key=actor,guid=guid,name=n} end
        end end
    roster[G.People.NameKey(G.player.name)]={key=G.me,guid=G.player.guid,name=G.player.name}
end
local function send(kind,body)
    if not IsInGuild() or #queue>900 then return end
    local raw=G.Codec.Encode({v=2,type=kind,body=body,ruleset=G.ruleset,region=G.region});if not raw then return end
    serial=serial+1;local id=tostring(G.Now())..'.'..serial
    local count=math.ceil(#raw/180);if count>67 then return end
    for i=1,count do queue[#queue+1]='2|'..id..'|'..i..'|'..count..'|'..raw:sub((i-1)*180+1,i*180) end
end
function S.Publish(o) send('UPDATE',o) end
function S.Hello() if not G.db then return end;lastHello=G.Now(); S.Roster();send('HELLO',{version=G.VERSION,digest=S.Digest and S.Digest() or ''});G.db.sync.lastHello=G.Now() end
local function summaries(to)
    for _,j in ipairs(jobs) do if j.to==to then return end end
    if #jobs>=20 then return end
    local ids={};for id in pairs(G.db.objects) do ids[#ids+1]=id end;table.sort(ids)
    jobs[#jobs+1]={to=to,ids=ids,index=1}
end
local function stamp(o)
    local raw=G.Codec.Encode(o);local h=0;for i=1,#raw do h=(h*33+raw:byte(i))%2147483647 end;return tostring(h)
end
local function digest()
    if digestCache then return digestCache end
    local ids={};for id in pairs(G.db.objects) do ids[#ids+1]=id end;table.sort(ids)
    local h=0
    for _,id in ipairs(ids) do local o=G.db.objects[id];local raw=id..':'..o.rev..':'..stamp(o);for i=1,#raw do h=(h*33+raw:byte(i))%2147483647 end end
    digestCache=tostring(#ids)..':'..h;return digestCache
end
local function handle(msg,sender)
    if type(msg)~='table' or msg.v~=2 or msg.ruleset~=G.ruleset or msg.region~=G.region or type(msg.body)~='table' then return end
    local b=msg.body
    if msg.type=='HELLO' then
        if peers[sender] and G.Now()-peers[sender]<30 then return end
        peers[sender]=G.Now();if b.digest~=digest() then summaries(sender) end
        -- Both directions, once per hello, including a reloading peer with stale data.
        send('VERSION',{to=sender,version=G.VERSION,digest=digest()})
    elseif msg.type=='VERSION' and b.to==G.me then if b.digest~=digest() then summaries(sender) end
    elseif msg.type=='SUMMARY' and b.to==G.me and type(b.items)=='table' then
        local ids={};local n=0
        for id,x in pairs(b.items) do
            n=n+1;if n>8 then return end
            if not G.Text(id,180) or type(x)~='table' or not G.Int(x.rev,1,1000000) or not G.Text(x.stamp,20) then return end
            local o=G.db.objects[id]
            if not o or x.rev>o.rev or (x.rev==o.rev and stamp(o)~=x.stamp) then ids[id]=true end
        end
        if next(ids) then
            local active,total=0,0;for _,p in pairs(pending) do total=total+1;if p.peer==sender then active=active+1 end end
            if active>=4 or total>=64 then return end
            local token=G.NewID();pending[token]={peer=sender,ids=ids,at=G.Now()};send('GET',{to=sender,token=token,ids=ids})
        end
    elseif msg.type=='GET' and b.to==G.me and G.Text(b.token,180) and type(b.ids)=='table' then
        local n=0;for id in pairs(b.ids) do n=n+1;if n>8 then return end;if not G.Text(id,180) then return end end
        for id in pairs(b.ids) do local o=G.db.objects[id];if o then send('OBJECT',{to=sender,token=b.token,object=o}) end end
    elseif msg.type=='OBJECT' and b.to==G.me and type(b.token)=='string' then
        local p=pending[b.token];local o=b.object
        if p and p.peer==sender and G.Now()-p.at<180 and type(o)=='table' and p.ids[o.id] then
            p.ids[o.id]=nil
            if o.owner~=G.me then G.Merge(o,sender,false) end
            if not next(p.ids) then pending[b.token]=nil end
        end
    elseif msg.type=='UPDATE' then
        if b.owner==sender and sender~=G.me then local ok,err=G.Merge(b,sender,false);if not ok then G.Debug('UPDATE ignored: '..tostring(err)) end end
    end
end
function S.Receive(prefix,msg,channel,sender)
    if prefix~=S.prefix or channel~='GUILD' or not IsInGuild() or type(msg)~='string' or #msg>254 then return end
    local entry=roster[G.People.NameKey(sender) or ''];if not entry then G.Debug('Ignored addon sender absent from guild roster.');return end
    sender=entry.key;if sender==G.me then return end
    local r=rates[sender];local now=G.Now()
    if not r or now-r.at>=10 then r={at=now,count=0};rates[sender]=r end
    r.count=r.count+1;if r.count>120 then return end
    local id,index,total,part=msg:match('^2|([%d%.]+)|(%d+)|(%d+)|(.*)$')
    index,total=tonumber(index),tonumber(total)
    if not id or #id>30 or not G.Int(total,1,67) or not G.Int(index,1,total) or #part>180 then return end
    local now=G.Now();local key=sender..':'..id;local a=assemblies[key]
    if not a then
        local count,global=0,0;for _,v in pairs(assemblies) do global=global+1;if v.sender==sender then count=count+1 end end
        if count>=4 or global>=64 then return end
        a={sender=sender,at=now,total=total,parts={},count=0};assemblies[key]=a
    end
    if a.total~=total then assemblies[key]=nil;return end
    if a.parts[index] then return end
    a.parts[index]=part;a.count=a.count+1
    if a.count==total then
        assemblies[key]=nil;local value=G.Codec.Decode(table.concat(a.parts))
        if value then local ok,err=pcall(handle,value,sender);if not ok then G.Debug('Ignored packet: '..tostring(err)) end end
    end
end
function S.Update(elapsed)
    tick=tick+elapsed;if tick<0.3 then return end;tick=0
    local now=G.Now()
    for k,a in pairs(assemblies) do if now-a.at>30 then assemblies[k]=nil end end
    for k,p in pairs(pending) do if now-p.at>180 then pending[k]=nil end end
    if IsInGuild() and now-lastHello>240 then lastHello=now;S.Hello() end
    if #queue<100 and jobs[1] then
        local j=jobs[1];local batch={};local n=0
        while j.index<=#j.ids and n<8 do
            local id=j.ids[j.index];j.index=j.index+1;local o=G.db.objects[id]
            if o then batch[id]={rev=o.rev,stamp=stamp(o)};n=n+1 end
        end
        if n>0 then send('SUMMARY',{to=j.to,items=batch}) end
        if j.index>#j.ids then table.remove(jobs,1) end
    end
    if #queue>0 and IsInGuild() and C_ChatInfo and C_ChatInfo.SendAddonMessage then
        if C_ChatInfo.AreOutgoingAddonChatMessagesRestricted and C_ChatInfo.AreOutgoingAddonChatMessagesRestricted() then queue={};return end
        local packet=table.remove(queue,1)
        local ok,result=pcall(C_ChatInfo.SendAddonMessage,S.prefix,packet,'GUILD')
        if not ok then ok,result=pcall(C_ChatInfo.SendAddonMessage,{prefix=S.prefix,message=packet,chatType='GUILD'}) end
        if not ok then G.LogError('SendAddonMessage',result) else G.db.sync.lastSent=now end
    end
end
S.Digest=digest
function S.Status() local n,p=0,0;for _ in pairs(G.db.objects) do n=n+1 end;for _ in pairs(peers) do p=p+1 end;return n..' records; '..p..' peers; '..#queue..' queued packets' end
