-- Run with luajit tests/run.lua from the repository root. No game/install writes.
local checks=0
local function check(v,msg) checks=checks+1;assert(v,msg or ('check '..checks)) end
local now=1800000000
local peers={'Alice Ironforge','Bob Oakheart','Cara Swiftwind'}
local messages={}
local function client(name)
    local env=setmetatable({},{__index=_G});env._G=env
    env.GetServerTime=function() return now end;env.time=env.GetServerTime
    env.Constants={CharacterNameSeparatorConsts={CHARACTERNAME_SURNAME_SEPARATOR=' '}}
    env.Enum={GameRule={PvPRuleset=10,RPRuleset=11}}
    env.C_GameRules={IsGameRuleActive=function() return false end};env.GetCurrentRegion=function() return 3 end
    env.UnitNameUnmodified=function() return name:match('^(%S+) (.+)$') end;env.UnitName=env.UnitNameUnmodified
    env.UnitGUID=function() return 'Player-1-'..name:match('^(%S+)') end
    env.GetGuildInfo=function() return 'Test Guild' end;env.IsInGuild=function() return true end
    env.GetNumGuildMembers=function() return #peers end;env.GetGuildRosterInfo=function(i) local values={[1]=peers[i],[17]='Player-1-'..peers[i]:match('^(%S+)')};return unpack(values,1,17) end
    env.GetRealZoneText=function() return 'Durotar' end
    env.C_ChatInfo={RegisterAddonMessagePrefix=function() return true end,SendAddonMessage=function(prefix,msg,channel) check(#msg<=254,'packet too large');messages[#messages+1]={sender=name,prefix=prefix,msg=msg,channel=channel} end}
    env.C_Item={GetItemInfo=function(v)
        local id=tonumber(tostring(v):match('item:(%d+)')) or tonumber(v)
        if id~=123 then return nil end
        return 'Test Sword','|cff1eff00|Hitem:123::::::::|h[Test Sword]|h|r',2,40,35,'Weapon','Sword',1,'INVTYPE_WEAPON',135328,1,2,7
    end,RequestLoadItemDataByID=function() end}
    env.LOOT_ITEM_SELF='You receive loot: %s.';env.LOOT_ITEM_SELF_MULTIPLE='You receive loot: %sx%d.'
    env.DEFAULT_CHAT_FRAME={AddMessage=function() end}
    local G={}
    local files={'Util','Codec','Identity','Migration','History','Models','Database','Sync','Items','Form','Claims','Notifications','Loot','PvP'}
    for _,f in ipairs(files) do local chunk=assert(loadfile('GuildBountyForever/'..f..'.lua'));setfenv(chunk,env);chunk('GuildBountyForever',G) end
    check(G.People.RefreshPlayer());check(G.InitDB());G.Sync.Roster();G.env=env;return G
end
local A,B,C=client(peers[1]),client(peers[2]),client(peers[3])
local clients={A,B,C}
local function pump(rounds,reverse)
    for i=1,rounds do
        if i%3==0 then now=now+1 end
        for _,g in ipairs(clients) do g.Sync.Update(0.31) end
        local batch=messages;messages={}
        if reverse then for j=#batch,1,-1 do local m=batch[j];for _,g in ipairs(clients) do g.Sync.Receive(m.prefix,m.msg,m.channel,m.sender) end end
        else for _,m in ipairs(batch) do for _,g in ipairs(clients) do g.Sync.Receive(m.prefix,m.msg,m.channel,m.sender) end end end
    end
end
local function eq(a,b) return A.Codec.Encode(a)==A.Codec.Encode(b) end
local values={empty='',text='a|b:c\n',num=123,flag=true,nested={a=false,b=45}}
check(eq(A.Codec.Decode(A.Codec.Encode(values)),values),'roundtrip')
check(A.Codec.Encode({b=2,a=1})==A.Codec.Encode({a=1,b=2}),'canonical')
for _,raw in ipairs({'','m900:','s5:abc','n3:nan','s9999999:x','m2:s1:at s1:af','n3:inf','x0:',A.Codec.Encode(values)..'extra','m1:n1:1t'}) do check(not A.Codec.Decode(raw),'malformed decode '..raw) end
math.randomseed(999)
for i=1,1000 do local b={};for j=1,math.random(0,100) do b[j]=string.char(math.random(0,255)) end;local ok=pcall(A.Codec.Decode,table.concat(b));check(ok,'fuzz panic') end
local req=assert(A.Create('request',{title='Sword',itemID=123,quantity=5,reward=10203,note='Need swords'}))
check(A.Validate(req));check(A.Remaining(req)==5)
check(A.Items.Match(req,123));check(not A.Items.Match(req,124))
local rule=assert(A.Create('request',{title='Weapons',rules={classID=2,subclassID=7,minLevel=40,minRequired=30,slot='INVTYPE_WEAPON'},quantity=2,reward=0}))
check(A.Items.Match(rule,123));check(A.Items.Match(rule,999)==nil,'uncached must defer')
local mismatch=A.Copy(rule);mismatch.rules.minLevel=41;check(not A.Items.Match(mismatch,123))
local bad=A.Copy(req);bad.quantity=-1;check(not A.Validate(bad));bad=A.Copy(req);bad.extra=true;check(not A.Validate(bad))
bad=A.Copy(req);bad.owner='Player-1-Evil';check(not A.Validate(bad),'id ownership')
check(not A.Merge(bad,'Player-1-Evil',false))
pump(200,true)
check(eq(A.db.objects[req.id],B.db.objects[req.id]),'live initial convergence')
local count=0;for _ in pairs(B.db.history) do count=count+1 end
check(not B.Merge(req,A.me,false),'duplicate rejected');local count2=0;for _ in pairs(B.db.history) do count2=count2+1 end;check(count==count2,'duplicate history')
local newer=assert(A.Edit(req,{note='Updated'}));pump(80)
check(B.db.objects[req.id].note=='Updated');check(not B.Merge(req,A.me,false),'out of order')
local branch=A.Copy(newer);branch.note='zzzzzzzz';B.Merge(branch,A.me,false);A.Merge(branch,A.me,false);check(eq(A.db.objects[req.id],B.db.objects[req.id]),'same revision total order')
local claim=assert(B.Accept(B.db.objects[req.id],{itemID=123,at=now,zone='Durotar',character=B.me,method='test'},2));check(claim.state=='accepted')
check(not A.Edit(claim,{state='submitted'}),'wrong actor edit');check(not B.Edit(claim,{quantity=3}),'immutable quantity')
claim=assert(B.Submit(claim));pump(200)
check(A.db.objects[claim.id].state=='submitted')
check(not C.Decide(claim,'paid'),'wrong reviewer')
local paid=assert(A.Decide(A.db.objects[claim.id],'paid'));check(A.Remaining(paid)==3);pump(150)
check(B.ClaimState(B.db.objects[claim.id])=='paid');check(not B.Edit(B.db.objects[claim.id],{state='withdrawn'}),'final claim')
check(not A.Decide(A.db.objects[claim.id],'paid'),'repeat payment')
local second=assert(B.Accept(B.db.objects[req.id],{at=now,method='manual'},1));second=assert(B.Submit(second));pump(100)
assert(A.Decide(A.db.objects[second.id],'rejected'));pump(100);check(B.ClaimState(second)=='rejected')
local bnty=assert(A.Create('pvp',{title='Enemy',target={name='Enemy Other',ruleset='PvE',guid='Player-2-Enemy',class='MAGE',faction='Alliance',level=60},quantity=1,reward=10000}))
check(A.PvP.Matches(bnty,'Player-2-Enemy','Enemy'));check(not A.PvP.Matches(bnty,'Player-2-Other','Enemy Other'))
local typed=A.Copy(bnty);typed.target.guid=nil;check(not A.PvP.Matches(typed,'x','Enemy'));check(A.PvP.Matches(typed,'x','Enemy Other','PvE'))
pump(100)
B.PvP.Kill('Player-2-Enemy','Enemy Other','personal credit','PARTY_KILL','Player-1-Bob','Bob',1,100)
local ev;for _,v in pairs(B.db.evidence) do if v.parent==bnty.id then ev=v.evidence end end;check(ev and ev.targetGUID=='Player-2-Enemy')
local pc=assert(B.Accept(B.db.objects[bnty.id],ev,1));check(B.Submit(pc));pump(150)
local pfinal=assert(A.Decide(A.db.objects[pc.id],'paid'));check(pfinal.state=='closed' and A.Remaining(pfinal)==0)
-- A peer that missed all updates can recover owner-offline snapshots from Bob.
pump(200);now=now+31;local D=client('Cara Swiftwind');clients={B,D};messages={};D.Sync.Hello();pump(700,true)
check(eq(D.db.objects[req.id],B.db.objects[req.id]),'offline owner snapshot recovery');check(D.db.history[req.id..':1'] and D.db.history[req.id..':2'],'offline history recovery');check(D.ClaimState(D.db.objects[claim.id])=='paid')
-- Unsolicited non-owner live writes never become authoritative.
local forged=B.Copy(B.db.objects[req.id]);forged.rev=99;forged.note='Forged'
local raw=B.Codec.Encode({v=2,type='UPDATE',body=forged,ruleset='PvE',region=3})
for i=1,math.ceil(#raw/180) do D.Sync.Receive('GBF2','2|777.1|'..i..'|'..math.ceil(#raw/180)..'|'..raw:sub((i-1)*180+1,i*180),'GUILD',B.player.name) end
check(D.db.objects[req.id].rev~=99,'actor enforcement')
for _,m in ipairs({'bad','2|1|0|1|x','2|1|1|999|x','2|1|a|1|x','2|2|1|1|m999999:'}) do check(pcall(D.Sync.Receive,'GBF2',m,'GUILD',B.player.name),'malformed network panic') end
-- Loot only matches localized self messages; ignore somebody else's loot.
local before=0;for _ in pairs(B.db.dismissed) do before=before+1 end
B.Loot.Message('Alice receives loot: |cff1eff00|Hitem:123::::::::|h[Test Sword]|h|r.')
local after=0;for _ in pairs(B.db.dismissed) do after=after+1 end;check(before==after,'other player loot')
B.Loot.Message('You receive loot: |cff1eff00|Hitem:123::::::::|h[Test Sword]|h|r.x2.')
B.Loot.Message('You receive loot: |cff1eff00|Hitem:123::::::::|h[Test Sword]|h|r.')
local oldCount=0;for _ in pairs(B.db.dismissed) do oldCount=oldCount+1 end
B.Loot.Message('You receive loot: |cff1eff00|Hitem:123::::::::|h[Test Sword]|h|r.')
local newCount=0;for _ in pairs(B.db.dismissed) do newCount=newCount+1 end;check(oldCount==newCount,'persistent loot dedup')
local invalid=B.Copy(claim);invalid.evidence.at='yesterday';check(not B.Validate(invalid),'typed evidence')
invalid=B.Copy(req);invalid.parent='bad';check(not B.Validate(invalid),'kind-specific fields')
-- Exercise the actual combat handler with mock native event tuples.
local oldOffers=#(B.offers or {});local combat
B.env.bit=require('bit');B.env.C_CombatLog={GetCurrentEventInfo=function() return unpack(combat) end,IsCombatLogRestricted=function() return false end}
local liveBounty=assert(A.Create('pvp',{title='Next enemy',target={name='Next Other',ruleset='PvE',guid='Player-2-Next'},quantity=1,reward=0}));clients={A,B};messages={};A.Sync.Publish(liveBounty);pump(100)
combat={now,'SPELL_DAMAGE',false,B.env.UnitGUID(),'Bob',1,0,'Player-2-Next','Next Other',64,0};B.PvP.Combat()
combat={now,'UNIT_DIED',false,'', '',0,0,'Player-2-Next','Next Other',64,0};B.PvP.Combat()
local found=false;for _,v in pairs(B.db.evidence) do if v.parent==liveBounty.id then found=v.evidence.method:find('participation only',1,true)~=nil end end;check(found,'damage participation evidence')
local offerCount=#B.offers;B.PvP.Combat();check(#B.offers==offerCount,'death dedup')
B.env.C_CombatLog.IsCombatLogRestricted=function() return true end;check(pcall(B.PvP.Combat),'restricted log graceful')
local saved=B.env.GuildBountyForeverDB;check(type(saved)=='table' and saved.schema==2)
B.env.GuildBountyForeverDB={schema=100};check(not B.InitDB(),'future schema');B.env.GuildBountyForeverDB=saved;check(B.InitDB())
-- Guild separation prevents leaking a previous guild's records to a new guild.
B.env.GetGuildInfo=function() return 'Other Guild' end;B.SwitchGuild();check(next(B.db.objects)==nil,'guild scope')
B.env.GetGuildInfo=function() return 'Test Guild' end;B.SwitchGuild();check(B.db.objects[req.id]~=nil,'guild restore')
local E=client('Cara Swiftwind');E.env.GuildBountyForeverDB={schema=0,prefs='bad',guilds={['OldLocation:Test Guild']={objects={broken={}},history={broken='bad'},evidence={broken={}},dismissed={broken={}}}}};check(E.InitDB());check(next(E.db.objects)==nil and next(E.db.history)==nil and next(E.db.evidence)==nil,'migration sanitation')
-- Regression: full two-part identities, rulesets and observed enrichment.
check(A.player.name=='Alice Ironforge' and A.me=='Player-1-Alice','full native name + GUID owner')
check(A.People.Name('  Ironfoe   Stormhammer  ')=='Ironfoe Stormhammer','normalize spacing without removing surname')
check(A.People.Name('Ironfoe-Stormhammer')==nil,'no forced hyphen separator')
check(A.People.Name('Ironfoe')==nil and A.People.Name('One Two Three')==nil,'full two-part validation')
check(A.People.Name('Élan Cœur')=='Élan Cœur','preserve UTF-8 display')
local function flagTest(pvp,rp,expected)
    A.env.C_GameRules.IsGameRuleActive=function(flag) return flag==10 and pvp or flag==11 and rp end
    check(A.People.Ruleset()==expected,'ruleset '..expected)
end
flagTest(false,false,'PvE');flagTest(true,false,'PvP');flagTest(false,true,'RP-PvE');flagTest(true,true,'RP-PvP');flagTest(false,false,'PvE')
A.env.Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR='·'
check(A.People.Join('Ironfoe','Stormhammer')=='Ironfoe·Stormhammer','native separator authoritative')
check(A.People.Name('Ironfoe Stormhammer')=='Ironfoe·Stormhammer','typed space canonicalized to native separator')
A.env.Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR=' '
local manual=A.People.Manual('Ironfoe Stormhammer');check(not manual.guid and manual.source=='manual','unresolved manual identity')
A.People.Observe({name='Ironfoe Stormhammer',guid='Player-2-Ironfoe',ruleset='PvE',class='WARRIOR',level=60,source='target'},'target')
local resolved,label=A.People.Resolve(manual);check(resolved.guid=='Player-2-Ironfoe' and resolved.class=='WARRIOR','observation enriches target');check(not manual.guid,'manual contract is not rewritten')
local manualBounty={target=manual}
check(A.PvP.Matches(manualBounty,'Player-2-Ironfoe','different display','PvE'),'observed GUID preferred')
check(not A.PvP.Matches(manualBounty,'Player-2-Wrong','Ironfoe Stormhammer','PvE'),'name cannot override observed GUID')
local fresh={target=A.People.Manual('Other Player')}
check(A.PvP.Matches(fresh,'Player-2-Other','Other Player','PvE'),'full name and same context')
check(not A.PvP.Matches(fresh,'Player-2-Other','Other Player','PvP'),'different ruleset rejected')
A.People.Observe({name='Other Player',guid='Player-2-One',ruleset='PvE',source='combat'},'combat')
A.People.Observe({name='Other Player',guid='Player-2-Two',ruleset='PvE',source='target'},'target')
check(not A.PvP.Matches(fresh,'Player-2-One','Other Player','PvE'),'ambiguous name rejected')
local link='|cff1eff00|Hitem:123::::::::|h[Test Sword]|h|r'
for _,v in ipairs({'123',' 123 ',link,'item:123::::::::'}) do check(A.Items.ParseInput(v)==123,'item input parse') end
for _,v in ipairs({'-1','1.2','1e3','123oops','0','fake item:123 text','|Hspell:123|h[Test]|h'}) do check(not A.Items.ParseInput(v),'invalid item input '..v) end
local draft={mode=1,item='123',quantity='2',gold='4',silver='5',copper='6',note='A note',target='Ignored Player',targetInfo={name='Ignored Player',guid='Player-1-Ignored'}}
local kind,fields=A.Form.Build(draft);check(kind=='request' and fields.itemID==123 and fields.reward==40506 and not fields.target and not fields.rules,'exact form isolated')
local changed=A.Copy(draft);changed.item='999999';check(not A.Form.Build(changed),'uncached form blocked')
for _,entry in ipairs({{'quantity','0'},{'quantity','1.5'},{'quantity','1e2'},{'gold','-1'},{'silver','100'},{'copper','-1'},{'note',string.rep('x',501)}}) do
    local d=A.Copy(draft);d[entry[1]]=entry[2];check(not A.Form.Build(d),'form rejects '..entry[1])
end
changed=A.Copy(draft);changed.mode=3;changed.quantity='garbage';changed.target='Ironfoe Stormhammer';changed.targetInfo=nil
kind,fields=A.Form.Build(changed);check(kind=='pvp' and fields.quantity==1 and not fields.itemID and not fields.rules and not fields.target.guid,'pvp isolated and quantity fixed')
changed.target='Ironfoe';check(not A.Form.Build(changed),'pvp full name required')
changed=A.Copy(draft);changed.mode=2;check(not A.Form.Build(changed),'empty rules rejected')
changed.class='2';changed.slot='INVTYPE_2HWEAPON';kind,fields=A.Form.Build(changed);check(kind=='request' and fields.rules.classID==2 and fields.rules.slot=='INVTYPE_2HWEAPON' and not fields.itemID and not fields.target,'rule form isolation')
changed.level='0';check(not A.Form.Build(changed),'zero minimum is not meaningful')
-- Populated schema-1 migration: remap IDs and decisions, retain UI/history/ignored state.
local M=client('Alice Ironforge');local oldOwner='AliceIronforge-OldLocation';local oldID=oldOwner..'/1700000000/1';local claimOwner='BobOakheart-OldLocation';local oldClaim=claimOwner..'/1700000001/1'
M.env.GuildBountyForeverDB={schema=1,prefs={position={point='CENTER',relative='CENTER',x=31,y=-12},tab=3},guilds={['OldLocation:Test Guild']={counter=9,objects={
    [oldID]={id=oldID,owner=oldOwner,kind='request',created=1700000000,updated=1700000002,rev=2,state='open',title='Sword',note='Retained',quantity=5,reward=100,itemID=123,decisions={[oldClaim]={state='paid',quantity=2,at=1700000002}}},
    [oldClaim]={id=oldClaim,owner=claimOwner,kind='claim',created=1700000001,updated=1700000001,rev=1,state='submitted',title='Sword',note='',parent=oldID,quantity=2,evidence={at=1700000001,itemID=123,character=claimOwner,method='manual'}},
    [oldOwner..'/1700000003/2']={id=oldOwner..'/1700000003/2',owner=oldOwner,kind='pvp',created=1700000003,updated=1700000003,rev=1,state='open',title='Enemy',note='',quantity=1,reward=0,decisions={},target={name='Enemy Other-OldLocation',guid='Player-2-Enemy',realm='discard this obsolete field'}}
},history={a={id=oldID,rev=1,at=1700000000,actor=oldOwner,state='open',kind='request',title='Sword'}},dismissed={[oldID..':123']=1700000004},evidence={},sync={}}}}
check(M.InitDB(),'populated migration initializes');local migratedID=M.me..'/1700000000/1';local mr=M.db.objects[migratedID]
check(mr and mr.note=='Retained' and mr.creator.name=='Alice Ironforge' and M.Remaining(mr)==3,'request + decisions preserved')
local mc;local mt;for _,o in pairs(M.db.objects) do if o.kind=='claim' then mc=o elseif o.kind=='pvp' then mt=o end end
check(mc and mc.parent==migratedID and mr.decisions[mc.id] and M.ClaimState(mc)=='paid','claim links remapped')
check(mt and mt.target.name=='Enemy Other' and mt.target.guid=='Player-2-Enemy','target name migrated')
check(M.db.history[migratedID..':1'] and M.db.dismissed[migratedID..':123'],'history and ignored matches preserved')
check(M.root.prefs.position.x==31 and M.root.prefs.tab==3 and M.db.counter==9,'UI and counter preserved')
check(not M.root.guilds and M.root.schema==2,'old partitions retired')
local function forbiddenKey(t)
    for k,v in pairs(t) do if type(k)=='string' and k:lower():find('realm',1,true) then return true end;if type(v)=='table' and forbiddenKey(v) then return true end end
end
check(not forbiddenKey(M.root),'no obsolete identity fields after migration')
-- Bag acquisition fallback, chat/bag dedup and no effect from stack moves.
local inventory=0;B.env.C_Container={GetContainerNumSlots=function(bag) return bag==0 and 1 or 0 end,GetContainerItemInfo=function() if inventory>0 then return {itemID=123,stackCount=inventory,hyperlink=link} end end}
B.db.dismissed={};B.offers={};B.Loot.Scan(true);inventory=3;B.Loot.Scan(false);local offers=#B.offers;check(offers>0,'bag increase matches')
B.Loot.Scan(false);B.Loot.Message('You receive loot: '..link..'x3.');check(#B.offers==offers,'chat and bag deduplicate')
local accepted=assert(B.Accept(B.db.objects[req.id],{at=now,itemID=123,character=B.player.name,method='inventory'},1));local again=assert(B.Accept(B.db.objects[req.id],{at=now,itemID=123,character=B.player.name,method='inventory'},1));check(accepted.id==again.id,'duplicate accept reuses active fulfilment')
-- Context envelope rejects packets from a different ruleset, even with a roster name.
local alien=B.Copy(req);alien.rev=999;alien.note='wrong context';local encoded=B.Codec.Encode({v=2,type='UPDATE',body=alien,ruleset='PvP',region=3})
M.Sync.Roster();for index=1,math.ceil(#encoded/180) do M.Sync.Receive('GBF2','2|999.1|'..index..'|'..math.ceil(#encoded/180)..'|'..encoded:sub((index-1)*180+1,index*180),'GUILD','Alice Ironforge') end
check(M.db.objects[migratedID].rev==2,'context/self packet cannot mutate local data')
-- Repeat actual chunk deliveries; neither requests nor history may multiply.
clients={A,C};messages={};A.Sync.Publish(A.db.objects[req.id]);pump(100)
local beforeObjects,beforeHistory=0,0;for _ in pairs(C.db.objects) do beforeObjects=beforeObjects+1 end;for _ in pairs(C.db.history) do beforeHistory=beforeHistory+1 end
local packet=A.Codec.Encode({v=2,type='UPDATE',body=A.db.objects[req.id],ruleset='PvE',region=3});local parts=math.ceil(#packet/180)
for pass=1,2 do for index=parts,1,-1 do local raw='2|555.1|'..index..'|'..parts..'|'..packet:sub((index-1)*180+1,index*180);C.Sync.Receive('GBF2',raw,'GUILD',A.player.name);C.Sync.Receive('GBF2',raw,'GUILD',A.player.name) end end
local afterObjects,afterHistory=0,0;for _ in pairs(C.db.objects) do afterObjects=afterObjects+1 end;for _ in pairs(C.db.history) do afterHistory=afterHistory+1 end
check(beforeObjects==afterObjects and beforeHistory==afterHistory,'duplicate reverse-order chunks retain one logical record/history')
local Late=client('Alice Ironforge');Late.env.GetGuildInfo=function() return nil end
Late.env.GuildBountyForeverDB={schema=1,prefs={},guilds={['OldLocation:Test Guild']={objects={[oldID]={id=oldID,owner=oldOwner,kind='request',created=1700000000,updated=1700000000,rev=1,state='open',title='Sword',note='',quantity=2,reward=0,itemID=123,decisions={}}}}}}
check(Late.InitDB());check(next(Late.root.legacyScopes)~=nil,'late guild record retained')
Late.env.GetGuildInfo=function() return 'Test Guild' end;Late.SwitchGuild();check(Late.db.objects[Late.me..'/1700000000/1']~=nil,'late guild partition attaches without restart')
local Local=client('Cara Swiftwind');Local.env.IsInGuild=function() return false end;Local.env.GetGuildInfo=function() return nil end;Local.SwitchGuild();local localOnly=assert(Local.Create('request',{itemID=123,title='Local sword',quantity=1,reward=0}));check(Local.db.objects[localOnly.id]~=nil,'unguilded creation');messages={};Local.Sync.Hello();Local.Sync.Update(0.31);check(#messages==0,'unguilded sync disabled')
check(B.Loot.ParseSelf('You receive loot: '..link..'x3.')==3,'native stack quantity format')
B.env.LOOT_ITEM_SELF_MULTIPLE='Received %2$d of %1$s.'
check(B.Loot.ParseSelf('Received 7 of '..link..'.')==7,'localized positional stack quantity')
check(not B.Loot.ParseSelf('Another character receives '..link),'ignore other-player format')
-- Presentation failure must not make a successful write look like a failed transaction.
local savedUI=A.UI;A.UI={Refresh=function() error('simulated native rendering failure') end}
local resilient,reason=A.Create('request',{itemID=123,title='Committed despite renderer',quantity=1,reward=0})
check(resilient and A.db.objects[resilient.id],'renderer error does not abort successful data write')
check(A.lastUIError and A.lastUIError.action=='Refresh','renderer failure is diagnosable');A.UI=savedUI
-- Owner-created bounties still prompt. Saved dismissals do not silence later drops.
local rib=assert(A.Create('request',{title='Boar Ribs',itemID=2677,quantity=10,reward=10000}))
A.offers={};A.db.dismissed[rib.id..':2677']=now-100
A.Loot.Message('You receive loot: |cffffffff|Hitem:2677::::::::|h[Boar Ribs]|h|r.')
check(#A.offers==1 and A.offers[1].object==rib.id,'own Boar Ribs bounty prompts without item cache')
check(A.offers[1].quantity==1 and A.offers[1].evidence.itemID==2677,'ribs loot evidence retained')
A.offers={};now=now+4;A.Loot.Message('You receive loot: |cffffffff|Hitem:2677::::::::|h[Boar Ribs]|h|r.')
check(#A.offers==1,'later drop prompts after prior dismissal')
A.Loot.Message('You receive loot: |cffffffff|Hitem:2677::::::::|h[Boar Ribs]|h|r.x2.')
check(#A.offers==1 and A.offers[1].quantity==2,'active match coalesces duplicate sources')
local ownOffers=#A.offers;A.Loot.Message('Bob receives loot: |cffffffff|Hitem:2677::::::::|h[Boar Ribs]|h|r.')
check(#A.offers==ownOffers,'other-player ribs do not trigger personal offer')
local held=0;A.env.C_Container={GetContainerNumSlots=function(bag) return bag==0 and 1 or 0 end,GetContainerItemInfo=function() if held>0 then return {itemID=2677,stackCount=held} end end}
A.Loot.Scan(true);A.offers={};now=now+4;held=3;A.Loot.Scan(false)
check(#A.offers==1 and A.offers[1].object==rib.id,'own bounty bag fallback works without chat or cached link')
A.Loot.Scan(false);check(#A.offers==1,'unchanged bags do not repeat prompt')
A.offers={};now=now+4;A.Loot.Scan(false,true);check(#A.offers==1 and A.offers[1].evidence.method=='Manual bag check (items currently held)','manual bag check finds previously acquired ribs')
-- Configurable ranges and stat metadata are validated and matched without a sample ID.
local statDraft={mode=2,quantity='1',gold='0',silver='0',copper='0',level='20',maxLevel='50',required='10',maxRequired='40',stats={ITEM_MOD_STRENGTH_SHORT={min='10',max='20'},ITEM_MOD_STAMINA_SHORT={min='5'}}}
local sk,sf=A.Form.Build(statDraft);check(sk=='request' and not sf.itemID and sf.rules.maxLevel==50,'range/stat-only form does not require item')
local sr=assert(A.Create('request',sf));check(A.Validate(sr),'stats pass model');check(A.Codec.Decode(A.Codec.Encode(sr)).rules.stats.ITEM_MOD_STAMINA_SHORT.min==5,'stats survive protocol round trip')
local oldInfo=A.Items.Info;A.Items.Info=function() return {link='item:123',level=40,required=30} end
-- Functions use the sandbox client environment, retrievable via getfenv under LuaJIT.
local itemEnv=getfenv(A.Items.Match);local previousAPI=itemEnv.C_Item
itemEnv.C_Item={GetItemStats=function() return {ITEM_MOD_STRENGTH_SHORT=15,ITEM_MOD_STAMINA_SHORT=5} end}
check(A.Items.Match(sr,123)==true,'all stat and level bounds match')
local bounded=A.Copy(sr);bounded.rules.maxLevel=39;check(not A.Items.Match(bounded,123),'maximum item level enforced');bounded=A.Copy(sr);bounded.rules.maxRequired=29;check(not A.Items.Match(bounded,123),'maximum required level enforced')
itemEnv.C_Item.GetItemStats=function() return {ITEM_MOD_STRENGTH_SHORT=21,ITEM_MOD_STAMINA_SHORT=5} end;check(A.Items.Match(sr,123)==false,'maximum stat enforced')
itemEnv.C_Item.GetItemStats=function() return {ITEM_MOD_STRENGTH_SHORT=15} end;check(A.Items.Match(sr,123)==false,'missing stat counts as zero')
itemEnv.C_Item.GetItemStats=function() return nil end;check(A.Items.Match(sr,123)==nil,'unavailable stats defer instead of match')
itemEnv.C_Item=previousAPI;A.Items.Info=oldInfo
local bad=A.Copy(statDraft);bad.maxLevel='10';check(not A.Form.Build(bad),'reversed level range rejected')
bad=A.Copy(statDraft);bad.stats.ITEM_MOD_STRENGTH_SHORT.max='2';check(not A.Form.Build(bad),'reversed stat range rejected')
bad=A.Copy(sr);bad.rules.stats.ITEM_MOD_STAMINA_SHORT.min=-1;check(not A.Validate(bad),'malformed synced stat rejected')
-- Supplier-authored send status and requester-authored receipts converge on both peers.
do local A,B=client('Alice Ironforge'),client('Bob Oakheart')
clients={A,B};messages={};local deliveryRequest=assert(A.Create('request',{itemID=123,title='Mailed swords',quantity=5,reward=10000}));pump(150)
local mailed=assert(B.Accept(B.db.objects[deliveryRequest.id],nil,5));mailed=assert(B.Edit(mailed,{delivery={sentAt=now,subject='GBF-model-delivery',amount=10000,items={['123']=5}}}));mailed=assert(B.Submit(mailed));pump(150)
check(A.db.objects[mailed.id].delivery.sentAt~=nil,'sent metadata synchronized to requester')
check(A.ReceiveDelivery(A.db.objects[mailed.id],123,3,10000,'GBF-model-delivery',true),'first receipt accepted')
check(A.Remaining(A.db.objects[deliveryRequest.id])==5 and A.db.objects[deliveryRequest.id].receipts[mailed.id].quantity==3,'partial receipt does not complete request')
check(not A.ReceiveDelivery(A.db.objects[mailed.id],123,3,10000,'GBF-model-delivery',true),'duplicate/excess receipt rejected')
check(not B.ReceiveDelivery(B.db.objects[mailed.id],123,2,10000,'GBF-model-delivery',true),'supplier cannot author recipient receipt')
check(A.ReceiveDelivery(A.db.objects[mailed.id],123,2,10000,'GBF-model-delivery',false),'remaining receipt accepted using prior COD payment')
pump(180);check(B.ClaimState(B.db.objects[mailed.id])=='paid' and B.db.objects[deliveryRequest.id].receipts[mailed.id].quantity==5 and B.Remaining(B.db.objects[deliveryRequest.id])==0,'receiver completion synchronizes back to supplier')
local paidDelivery=B.Copy(B.db.objects[mailed.id].delivery);paidDelivery.payoutAt=now;check(B.Edit(B.db.objects[mailed.id],{delivery=paidDelivery}),'supplier can record payout after final payment decision')
pump(120);check(A.db.objects[mailed.id].delivery.payoutAt~=nil,'payout observation synchronized')
local corrupt=A.Copy(A.db.objects[deliveryRequest.id]);corrupt.receipts[mailed.id].items['123']=9;check(not A.Validate(corrupt),'inconsistent received totals rejected')
end
print('PASS: '..checks..' checks (codec/fuzz, full-name/ruleset identity, observations, forms, claims, PvP, sync, migration and loot dedup).')
