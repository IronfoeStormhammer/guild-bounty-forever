local _,G=...
G.Native={};local N=G.Native
function N.Frame(name,parent,template)
    local ok,f=pcall(CreateFrame,'Frame',name,parent,template)
    if ok then return f end
    G.Debug('Template unavailable: '..tostring(template))
    return CreateFrame('Frame',name,parent,'BackdropTemplate')
end
function N.Label(parent,text,x,y,width,font)
    local f=parent:CreateFontString(nil,'OVERLAY',font or 'GameFontNormalSmall');f:SetPoint('TOPLEFT',x,y);f:SetWidth(width or 200);f:SetJustifyH('LEFT');f:SetText(text);return f
end
function N.Action(label,fn,target)
    return function(...)
        local control=target or select(1,...)
        if G.Tutorial and G.Tutorial.active and G.Tutorial.Route(control,label) then return end
        local ok,err=pcall(fn,...)
        if ok and G.Tutorial and G.Tutorial.active and G.Tutorial.AfterAction then G.Tutorial.AfterAction(control,label) end
        if not ok then
            G.UIError(label,err)
        end
    end
end
function N.Enabled(button,enabled)
    if enabled then button:Enable() else button:Disable() end
end
function N.Button(parent,text,x,y,w,fn)
    local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');b:SetFrameLevel(parent:GetFrameLevel()+10);b:SetSize(w or 110,24);b:SetPoint('TOPLEFT',x,y);b:SetText(text)
    b:RegisterForClicks('LeftButtonUp');b:SetScript('OnClick',N.Action(text,fn,b));return b
end
function N.Edit(parent,label,x,y,w,value,max)
    local caption=N.Label(parent,label,x,y,w)
    local e=CreateFrame('EditBox',nil,parent,'InputBoxTemplate');e:SetSize(w,22);e:SetPoint('TOPLEFT',x+5,y-19);e:SetAutoFocus(false);e:EnableMouse(true);e:EnableKeyboard(true);e:SetEnabled(true);e:SetAltArrowKeyMode(false);e:SetFontObject(ChatFontNormal or GameFontHighlightSmall);e:SetTextInsets(4,4,0,0);e:SetFrameLevel(parent:GetFrameLevel()+10);e:SetMaxLetters(max or 500);e:SetText(value or '');e:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    e:SetScript('OnMouseDown',function(self,button) if button=='LeftButton' then self:SetFocus() end end)
    e:SetScript('OnEnterPressed',function(self) self:ClearFocus() end)
    e:HookScript('OnEditFocusGained',function(self) N.focus=self;G.Debug('Input focus: '..label) end)
    e:HookScript('OnEditFocusLost',function(self) if N.focus==self then N.focus=nil end end)
    e:HookScript('OnHide',function(self) self:ClearFocus();if N.focus==self then N.focus=nil end end)
    e.caption=caption;e:HookScript('OnHide',function() caption:Hide() end);e:HookScript('OnShow',function() caption:Show() end)
    return e
end
function N.Tooltip(frame,value)
    frame:SetScript('OnEnter',function(self) if value then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetHyperlink(type(value)=='number' and ('item:'..value) or value);GameTooltip:Show() end end)
    frame:SetScript('OnLeave',function() GameTooltip:Hide() end)
end
function N.Title(f,title)
    if f.SetTitle then f:SetTitle(title) elseif f.TitleText then f.TitleText:SetText(title) elseif f.TitleContainer and f.TitleContainer.TitleText then f.TitleContainer.TitleText:SetText(title) else N.Label(f,title,70,-12,300,'GameFontNormalLarge') end
end
function N.Money(parent,x,y)
    local f=N.Frame(nil,parent,'MoneyDisplayFrameTemplate');f:SetPoint('TOPLEFT',x,y);if f.SetResizeToFit then f:SetResizeToFit(true) end
    if not f.SetAmount then f.text=N.Label(f,'',0,0,120);f.SetAmount=function(self,n) self.text:SetText(G.Money(n)) end end
    return f
end
function N.Icon(parent,x,y)
    local ok,b=pcall(CreateFrame,'ItemButton',nil,parent)
    if not ok then b=CreateFrame('Button',nil,parent);b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetAllPoints() end
    b:SetSize(30,30);b:SetPoint('TOPLEFT',x,y);return b
end

-- The installed SharedXML MinimalScrollBar exposes Init and OnScroll callbacks.
function N.ScrollBar(parent,scroll)
    local bar
    local ok,problem=pcall(function()
        bar=CreateFrame('EventFrame',nil,parent,'MinimalScrollBar')
        bar:SetPoint('TOPRIGHT',-8,-8);bar:SetPoint('BOTTOMRIGHT',-8,40)
        assert(bar.Init and bar.RegisterCallback,'Native scrollbar methods unavailable')
        bar:Init(1,0.2)
        bar:RegisterCallback('OnScroll',N.Action('Scroll details',function(_,percent)
            if type(percent)=='number' then scroll:SetVerticalScroll(percent*scroll:GetVerticalScrollRange()) end
        end),bar)
        scroll:HookScript('OnScrollRangeChanged',N.Action('Resize details scroll',function(self)
            local range=self:GetVerticalScrollRange();local height=self:GetHeight()
            bar:SetVisibleExtentPercentage(height/math.max(height+range,1));bar:SetShown(range>1)
        end))
        scroll:HookScript('OnVerticalScroll',N.Action('Scroll details position',function(self,value)
            local range=self:GetVerticalScrollRange()
            if range>0 and math.abs(bar:GetScrollPercentage()-value/range)>0.001 then bar:SetScrollPercentage(value/range,true) end
        end))
    end)
    if not ok then
        if bar then bar:Hide() end
        G.scrollbarError=tostring(problem)
        if G.root then G.root.prefs.scrollbarError=G.scrollbarError end
        G.LogError('Optional scrollbar disabled; mouse wheel remains available',problem)
        return nil
    end
    return bar
end

function N.ClearFocus() if N.focus then N.focus:ClearFocus();N.focus=nil end end
function N.BackgroundFocus(frame)
    frame:EnableMouse(true);frame:SetScript('OnMouseDown',function() N.ClearFocus() end)
end

-- Uses Forever's intrinsic DropdownButton and native Menu radio selections.
function N.Choice(parent,label,x,y,width,options,onChange)
    local caption=N.Label(parent,label,x,y,width)
    local ok,button=pcall(CreateFrame,'DropdownButton',nil,parent,'WowStyle2DropdownTemplate')
    if not ok then button=N.Button(parent,'',x+5,y-19,width,function() end) end
    button:ClearAllPoints();button:SetPoint('TOPLEFT',x+5,y-19);button:SetSize(width,24);button:SetFrameLevel(parent:GetFrameLevel()+10)
    button.caption=caption;button.value='';button.options=options or {}
    local function display(self)
        local text=self.options[1] and self.options[1].label or 'Any'
        for _,option in ipairs(self.options) do if option.value==self.value then text=option.label;break end end
        if self.SetDefaultText then self:SetDefaultText(text) end
        if self.Text then self.Text:SetText(text) else self:SetText(text..' |TInterface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up:14|t') end
    end
    function button:GetValue() return self.value end
    function button:SetValue(value,silent)
        value=value==nil and '' or tostring(value);local previous=self.value;self.value=value
        local known=false;for _,option in ipairs(self.options) do if option.value==value then known=true end end
        if not known and value~='' then self.options[#self.options+1]={value=value,label='Saved selection'} end
        display(self)
        if previous~=value and not silent and onChange then onChange(value) end
        if self.GenerateMenu then self:GenerateMenu() end
    end
    function button:SetOptions(values)
        self.options=values;display(self);if self.GenerateMenu then self:GenerateMenu() end
    end
    local function generate(_,root)
        if root.SetScrollMode then root:SetScrollMode(260) end
        for _,option in ipairs(button.options) do
            local value,text=option.value,option.label
            root:CreateRadio(text,function() return button.value==value end,N.Action(label,function() button:SetValue(value) end))
        end
    end
    if button.SetupMenu then button:SetupMenu(generate)
    else button:SetScript('OnClick',N.Action(label,function()
        N.ClearFocus()
        if MenuUtil and MenuUtil.CreateContextMenu then MenuUtil.CreateContextMenu(button,generate)
        else error('Native dropdown menu is unavailable.') end
    end)) end
    button:HookScript('OnHide',function() caption:Hide() end);button:HookScript('OnShow',function() caption:Show() end)
    display(button);return button
end
