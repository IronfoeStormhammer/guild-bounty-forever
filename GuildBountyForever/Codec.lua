local _, G = ...
G.Codec = {}
-- Length-prefixed, canonical, non-executable wire format. No loadstring/eval.
local function encode(v, depth)
    assert(depth < 10, 'nesting')
    local t = type(v)
    if t == 'string' then assert(#v <= 2048, 'string'); return 's'..#v..':'..v
    elseif t == 'number' then assert(v == v and math.abs(v) <= 1e14, 'number'); local s=tostring(v); return 'n'..#s..':'..s
    elseif t == 'boolean' then return v and 't' or 'f'
    elseif t == 'table' then
        local keys={}; for k in pairs(v) do assert(type(k)=='string','key'); keys[#keys+1]=k end
        assert(#keys<=80,'fields'); table.sort(keys)
        local out={'m',tostring(#keys),':'}
        for _,k in ipairs(keys) do out[#out+1]=encode(k,depth+1); out[#out+1]=encode(v[k],depth+1) end
        return table.concat(out)
    end
    error('type')
end
function G.Codec.Encode(v)
    local ok,s=pcall(encode,v,0); if ok and #s<=12000 then return s end
end
function G.Codec.Decode(s)
    if type(s)~='string' or #s>12000 then return nil end
    local pos,nodes=1,0
    local function read(depth)
        nodes=nodes+1; assert(depth<10 and nodes<=1200,'complexity')
        local t=s:sub(pos,pos);pos=pos+1
        if t=='t' then return true elseif t=='f' then return false end
        local stop=s:find(':',pos,true); assert(stop and stop-pos<=6,'length')
        local digits=s:sub(pos,stop-1); assert(digits:match('^%d+$'),'length')
        local n=tonumber(digits);pos=stop+1
        if t=='m' then
            assert(n<=80,'fields'); local v={}
            for i=1,n do local k=read(depth+1);assert(type(k)=='string' and v[k]==nil,'key');v[k]=read(depth+1) end
            return v
        end
        assert((t=='s' and n<=2048) or (t=='n' and n<=32),'type')
        assert(pos+n-1<=#s,'truncated');local v=s:sub(pos,pos+n-1);pos=pos+n
        if t=='n' then v=tonumber(v);assert(v and v==v and math.abs(v)<=1e14,'number') end
        return v
    end
    local ok,v=pcall(read,0);if ok and pos==#s+1 then return v end
end
