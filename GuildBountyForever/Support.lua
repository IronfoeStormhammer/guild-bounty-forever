local _,G=...
G.Support={};local S,N=G.Support,G.Native
S.roasts={
    "May every green you loot have exactly one less Strength than the bounty requires.",
    "Your surname is longer than your attention span at the mailbox.",
    "Even a level-one boar would decline your guild application.",
    "May your next ten upgrades all be shirts.",
    "You negotiate like a goblin who skipped accounting.",
    "Somewhere, a kobold is warning its candle about you.",
    "Your bags are full, yet somehow your judgment still fits in them.",
    "May your perfect weapon drop with Spirit and a deeply confusing life story.",
    "You bring the tactical awareness of a sheep wearing a raid marker.",
    "The auctioneer saw you coming and invented a new deposit fee.",
    "May your fishing bobber attract nothing but unsolicited guild advice.",
    "Your hearthstone asked to be bound to somebody else.",
    "A training dummy just put a bounty on you for emotional damages.",
    "May all your Boar Ribs arrive individually wrapped in separate COD letters.",
    "Even the flight master would rather walk than explain directions to you.",
    "You have the inventory management skills of a murloc in a wind tunnel.",
    "May your next epic require the class you nearly rolled.",
    "The innkeeper has started charging you for standing near the fireplace.",
    "Your talent build looks like it was chosen by a gnome sneezing.",
    "May every mailbox be just outside your comfortable walking distance.",
    "Somewhere in Stormwind, a pigeon has a better retirement plan than you.",
    "You make a quest escort look decisive.",
    "May your mount stop to admire every flower between you and the mailbox.",
    "The guild bank labels your donations 'historical curiosities'.",
    "May your quest item drop the moment you decide to log out.",
    "A Defias cutpurse looked in your bags and left you a budgeting pamphlet.",
    "Your threat management is mostly a strongly worded apology.",
    "May your favorite boots squeak in every cathedral.",
    "Even your pet has you on follow out of pity.",
    "May all your carefully stacked materials become 'just one more stack'.",
    "You have the subtlety of a tauren in a gnomish cutlery shop.",
    "The kobolds took a vote. You still cannot have the candle.",
    "May your best cloak be permanently tucked into your trousers.",
    "You read delivery instructions like a warrior reads spell power.",
    "May every guild meeting begin with a detailed discussion of your mail etiquette.",
    "A murloc said something about you. The translation was not flattering.",
    "May your next treasure chest contain a smaller chest full of disappointment.",
    "Your battle plan has been returned to sender, postage due.",
    "May your fancy surname be misspelled on every commemorative mug in Azeroth.",
    "Even the spirit healer is asking whether this is a repeat appointment.",
    "May your perfect auction sell exactly three seconds after you buy another one.",
    "A sheep saw your equipment and cast Polymorph on itself to avoid the conversation.",
    "Your bags contain six professions' worth of optimism and no free slots.",
    "May every rare spawn wave politely before someone else tags it.",
    "The mailbox is not judging you. I am doing enough for both of us.",
    "May your next upgrade be an identical item with a more confident name.",
    "You have the negotiating power of a rabbit's foot without the rabbit.",
    "The guards are not ignoring your directions request. They are protecting the city.",
    "May your weapon enchant smell faintly of wet trogg.",
    "Your guild rank is one typo away from 'Decorative Furniture'.",
    "May every dungeon shortcut include the longest possible explanation.",
    "A goblin appraised your common sense and asked for a refund.",
    "May your next perfect green have the fashion sense of a Southshore scarecrow.",
    "You approach COD prices with the courage of someone else's wallet.",
    "May all your mail subjects be as descriptive as 'stuff'.",
    "Even the rats in the inn have formed a group without you.",
    "May your next escort quest insist on stopping for lunch at every bush.",
    "Your crit chance is higher than the chance you read the note field.",
    "May every reagent vendor recognize you as 'the one who forgot again'.",
    "A gnome checked your calculations and quietly put on a helmet.",
    "May your next guild portrait catch you mid-chew on a conjured muffin.",
    "You are the reason the mailbox needs a confirmation window.",
    "May your most impressive title be 'Almost Prepared'.",
    "The boars have added your face to their safety briefing.",
    "May every weapon you love look like it was assembled from spare spoons.",
    "Your pulling strategy has been classified as a weather event.",
    "May your next ten treasure maps all point to the same disappointing puddle.",
    "A trogg reviewed your route to the mailbox and suggested night school.",
    "May your inventory sort itself alphabetically by emotional attachment.",
    "You have the situational awareness of a fishing float.",
    "May your next perfectly priced bounty ask for the item you sold five minutes ago.",
    "Even the chickens in Westfall have stopped falling for your confidence.",
    "May your next cape billow dramatically in the wrong direction.",
    "Your raid preparation is a sandwich and a remarkable sense of entitlement.",
    "May all your ore nodes contain an unsolicited lecture about mining technique.",
    "The auction house has named a storage cupboard after your unsold listings.",
    "May your next dungeon group debate every corridor as if it were guild policy.",
    "Your mailbox has more completed objectives than your quest log.",
    "May your best fishing story be independently verified by a hostile murloc.",
    "A kobold offered to hold the candle while you found the Yes button.",
    "May your next matching drop be celebrated by exactly one sarcastic gnome.",
    "You make 'inventory full' sound like a personal philosophy.",
    "May your next pair of gloves have excellent stats and an embarrassing thumb situation.",
    "The flight master has listed you as 'fragile, this side up'.",
    "May your next mysterious artifact be a very old shopping list.",
    "Your guild note simply says 'requires adult supervision near stamps'.",
    "May all your carefully chosen stats be explained to you by an overconfident paladin.",
    "A wisp followed your plan and immediately chose a different tree.",
    "May every chest you open contain enough copper to make counting it annoying.",
    "Your most consistent proc is remembering the reagent after the pull.",
    "May your next cool item be just cool enough that you cannot bring yourself to vendor it.",
    "The gnolls have requested that you stop lowering the neighborhood's tactical standards.",
    "May your next heroic entrance be interrupted by the wrong bag opening.",
    "You are one unread tooltip away from inventing a new kind of accident.",
    "May your next letter be a formal complaint from the ribs you keep farming.",
    "A gnomish engineer described your plan as 'technically a direction'.",
    "May your next bounty pay in compliments that cannot cover postage.",
    "Your surname deserves a better first name to adventure with.",
    "May your next guild cheer arrive with a detailed list of conditions.",
    "May Azeroth remember you forever, mostly as the person who pressed No on the heart button.",
}
function S.PickRoast()
    local index=math.random(1,#S.roasts);if index==S.lastIndex then index=index%#S.roasts+1 end
    S.lastIndex=index;return S.roasts[index],index
end
function S.Show(phase)
    if not S.frame then
        local f=N.Frame('GuildBountyForeverThanks',UIParent,'ButtonFrameTemplate');S.frame=f;f:SetSize(470,245);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');N.Title(f,'A little love for Guild Bounty')
        if f.Inset then f.Inset:Hide() end
        if f.SetPortraitToAsset then f:SetPortraitToAsset('Interface\\AddOns\\GuildBountyForever\\Media\\Heart') end
        f.text=N.Label(f,'',24,-58,422,'GameFontHighlight');f.text:SetHeight(115)
        f.left=N.Button(f,'Yes',24,-194,195,function()
            if S.phase=='like' then S.Show('eu') elseif S.phase=='eu' then S.Show('alliance') elseif S.phase=='roast' then S.Show('roast') else S.Show('like') end
        end)
        f.right=N.Button(f,'No',249,-194,195,function()
            if S.phase=='like' then S.Show('roast') elseif S.phase=='eu' then S.Show('thanks') elseif S.phase=='roast' then S.Show('like') else f:Hide() end
        end)
        UISpecialFrames[#UISpecialFrames+1]='GuildBountyForeverThanks'
    end
    local f=S.frame;S.phase=phase
    if phase=='like' then f.text:SetText('Did you like the addon?');f.left:SetText('Yes');f.right:SetText('No')
    elseif phase=='eu' then f.text:SetText('Are you EU PvP?');f.left:SetText('Yes');f.right:SetText('No')
    elseif phase=='roast' then local roast,index=S.PickRoast();N.Title(f,'A friendly Azerothian curse • '..index..' / '..#S.roasts);f.text:SetText(roast);f.left:SetText('Another roast');f.right:SetText('Back')
    elseif phase=='thanks' then f.text:SetText("Then your thanks is enough. I don't need IRL money or support. Just enjoy WoW Forever :)");f.left:SetText('Back');f.right:SetText('Close')
    elseif phase=='alliance' then f.text:SetText("Send gold or cool shit to me: Ironfoe Thundercog.\n\nAlliance only. I don't want anything from the Horde but blood.");f.left:SetText('Back');f.right:SetText('Close') end
    if phase~='roast' then N.Title(f,'A little love for Guild Bounty') end
    f:Show()
end
function S.Open() S.Show('like') end
function S.Button(parent)
    local b=CreateFrame('Button',nil,parent);b:SetSize(32,32);b:SetPoint('BOTTOMRIGHT',parent,'BOTTOMRIGHT',-18,12);b:SetFrameLevel(parent:GetFrameLevel()+20);b:RegisterForClicks('LeftButtonUp')
    local path='Interface\\AddOns\\GuildBountyForever\\Media\\Heart'
    b:SetNormalTexture(path);b:SetPushedTexture(path);b:SetHighlightTexture(path,'ADD');b:SetScript('OnClick',N.Action('Did you like the addon?',S.Open,b))
    b:SetScript('OnEnter',function(self) GameTooltip:SetOwner(self,'ANCHOR_TOP');GameTooltip:SetText('Did you like Guild Bounty?');GameTooltip:AddLine('A little love, or a little Azerothian roast.',1,1,1);GameTooltip:Show() end)
    b:SetScript('OnLeave',function() GameTooltip:Hide() end)
    return b
end
