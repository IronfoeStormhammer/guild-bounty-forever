local _, G = ...
function G.Record(o,old,localChange)
    if o.kind=='history' then
        local id=o.parent..':'..o.originRev
        G.db.history[id]={synced=true,action=o.action,note=o.note,quantity=o.quantity,reward=o.reward,id=o.parent,rev=o.originRev,at=o.updated,actor=o.owner,actorName=G.DisplayOwner(o),state=o.eventState,kind='history',title=o.title}
        return
    end
    local id=o.id..':'..o.rev
    local action=not old and 'created' or o.kind=='claim' and o.state or o.state=='closed' and 'closed' or 'edited'
    if o.decisions then for key,d in pairs(o.decisions) do if not old or not old.decisions[key] then action='claim '..d.state end end end
    if not G.db.history[id] or not G.db.history[id].synced then
        G.db.history[id]={action=action,note=o.note,quantity=o.quantity,reward=o.reward,id=o.id,rev=o.rev,at=o.updated,actor=o.owner,actorName=G.DisplayOwner(o),state=o.state,kind=o.kind,title=o.title,parent=o.parent}
    end
    if localChange then
        local event={id=o.id..'/history/'..o.rev,owner=o.owner,creator=G.Copy(o.creator),created=o.updated,updated=o.updated,rev=1,kind='history',state='recorded',title=o.title,note=o.note,parent=o.id,originRev=o.rev,eventState=o.state,action=action,quantity=o.quantity,reward=o.reward}
        G.Merge(event,G.me,true)
    end
end
function G.HistoryRows()
    local rows={} for _,h in pairs(G.db.history) do rows[#rows+1]=h end
    table.sort(rows,function(a,b) if a.at==b.at then return a.id<b.id end return a.at>b.at end);return rows
end
