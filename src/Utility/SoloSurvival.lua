-- LvkHub.exe SOLO SURVIVAL
-- Best-effort local hunger/thirst refill. Hard blocked whenever another Player exists.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local LP=Players.LocalPlayer
    local Restrictions=shared.LvkHubRestrictions
    local page=UI.Pages.Utility

    State.Utility.FullHunger=State.Utility.FullHunger==true
    State.Utility.FullThirst=State.Utility.FullThirst==true

    local function soloAllowed()
        return type(Restrictions)=="table"
            and type(Restrictions.SoloWeaponModsAllowed)=="function"
            and Restrictions.SoloWeaponModsAllowed()==true
    end

    UI.Section(page,"SOLO SURVIVAL")
    local _,guard=UI.Row(page,"SURVIVAL GUARD: checking...",38)
    guard.TextColor3=Color3.fromRGB(255,190,85)
    UI.Toggle(page,"Full Hunger [SOLO]",function() return State.Utility.FullHunger end,function(v) State.Utility.FullHunger=v end)
    UI.Toggle(page,"Full Thirst [SOLO]",function() return State.Utility.FullThirst end,function(v) State.Utility.FullThirst=v end)
    local _,status=UI.Row(page,"Sources: scanning...",38)
    status.TextColor3=Color3.fromRGB(145,150,170)
    status.TextSize=11

    local hungerNames={hunger=true,food=true,satiety=true,calories=true,hungervalue=true}
    local thirstNames={thirst=true,water=true,hydration=true,thirstvalue=true}
    local snapshots=setmetatable({}, {__mode="k"})
    local attrSnapshots=setmetatable({}, {__mode="k"})

    local function normalize(s)
        return tostring(s):lower():gsub("[%s_%-]","")
    end

    local function classify(name)
        local n=normalize(name)
        if hungerNames[n] then return "hunger" end
        if thirstNames[n] then return "thirst" end
        return nil
    end

    local function fullValue(obj,current)
        local ok,max=pcall(function() return obj.MaxValue end)
        if ok and typeof(max)=="number" and max>0 then return max end
        current=tonumber(current) or 0
        if current>=0 and current<=1.01 then return 1 end
        if current<=100 then return 100 end
        return current
    end

    local function attrMax(inst,name,current)
        local candidates={"Max"..name,name.."Max","Max_"..name,name.."_Max"}
        for _,k in ipairs(candidates) do
            local v=inst:GetAttribute(k)
            if typeof(v)=="number" and v>0 then return v end
        end
        current=tonumber(current) or 0
        if current>=0 and current<=1.01 then return 1 end
        if current<=100 then return 100 end
        return current
    end

    local function roots()
        local list={LP}
        if LP.Character then table.insert(list,LP.Character) end
        return list
    end

    local function captureValue(obj)
        if snapshots[obj]==nil then snapshots[obj]=obj.Value end
    end

    local function captureAttr(inst,name,value)
        attrSnapshots[inst]=attrSnapshots[inst] or {}
        if attrSnapshots[inst][name]==nil then
            attrSnapshots[inst][name]={had=inst:GetAttribute(name)~=nil,value=value}
        end
    end

    local function restoreAll()
        for obj,v in pairs(snapshots) do
            if obj and obj.Parent then pcall(function() obj.Value=v end) end
            snapshots[obj]=nil
        end
        for inst,map in pairs(attrSnapshots) do
            if inst and inst.Parent then
                for name,s in pairs(map) do
                    pcall(function() if s.had then inst:SetAttribute(name,s.value) else inst:SetAttribute(name,nil) end end)
                end
            end
            attrSnapshots[inst]=nil
        end
    end

    local function apply()
        local foundH,foundT=0,0
        for _,root in ipairs(roots()) do
            for _,obj in ipairs(root:GetDescendants()) do
                if obj:IsA("ValueBase") and typeof(obj.Value)=="number" then
                    local kind=classify(obj.Name)
                    if kind then
                        if kind=="hunger" then foundH+=1 else foundT+=1 end
                        local enabled=(kind=="hunger" and State.Utility.FullHunger) or (kind=="thirst" and State.Utility.FullThirst)
                        if enabled then
                            captureValue(obj)
                            local wanted=fullValue(obj,obj.Value)
                            if obj.Value~=wanted then pcall(function() obj.Value=wanted end) end
                        end
                    end
                end
            end
            for name,value in pairs(root:GetAttributes()) do
                if typeof(value)=="number" then
                    local kind=classify(name)
                    if kind then
                        if kind=="hunger" then foundH+=1 else foundT+=1 end
                        local enabled=(kind=="hunger" and State.Utility.FullHunger) or (kind=="thirst" and State.Utility.FullThirst)
                        if enabled then
                            captureAttr(root,name,value)
                            local wanted=attrMax(root,name,value)
                            if value~=wanted then pcall(function() root:SetAttribute(name,wanted) end) end
                        end
                    end
                end
            end
        end
        status.Text=string.format("Sources: hunger %d • thirst %d",foundH,foundT)
        return foundH,foundT
    end

    local wasAllowed=soloAllowed()
    local timer=0
    RunService.Heartbeat:Connect(function(dt)
        timer+=dt
        if timer<.12 then return end
        timer=0
        local allowed=soloAllowed()
        if allowed then
            guard.Text="SURVIVAL GUARD: READY • only LocalPlayer"
            guard.TextColor3=Color3.fromRGB(80,225,125)
            apply()
            if not State.Utility.FullHunger and not State.Utility.FullThirst and (next(snapshots)~=nil or next(attrSnapshots)~=nil) then restoreAll() end
        else
            guard.Text="SURVIVAL GUARD: BLOCKED • another Player present"
            guard.TextColor3=Color3.fromRGB(245,80,80)
            if wasAllowed or next(snapshots)~=nil or next(attrSnapshots)~=nil then restoreAll() end
        end
        wasAllowed=allowed
    end)

    Players.PlayerAdded:Connect(function(p)
        if p~=LP then task.defer(restoreAll) end
    end)
    LP.CharacterAdded:Connect(function() task.defer(restoreAll) end)
end
