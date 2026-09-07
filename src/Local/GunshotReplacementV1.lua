-- Local cosmetic gunshot replacement.
-- Works together with MuteGunshotsV3: when Mute Gunshots is ON, the original local report
-- is muted and this replacement is played once per local shot.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local Workspace=game:GetService("Workspace")
    local SoundService=game:GetService("SoundService")
    local LP=Players.LocalPlayer

    local sound=Instance.new("Sound")
    sound.Name="LvkHubReplacementGunshot"
    sound.SoundId="rbxassetid://131677038997771"
    sound.Volume=.8
    sound.RollOffMaxDistance=80
    sound.Parent=SoundService

    local lastPlayed=0
    local function play()
        if not (State.Local and State.Local.MuteGunshots==true) then return end
        local now=os.clock()
        if now-lastPlayed<.035 then return end
        lastPlayed=now
        pcall(function()
            sound.TimePosition=0
            sound:Play()
        end)
    end

    local watched=setmetatable({}, {__mode="k"})
    local function watchTool(tool)
        if not tool or not tool:IsA("Tool") or watched[tool] then return end
        if not (tool:FindFirstChild("WeaponConfig") or tool:FindFirstChild("Ammo")) then return end
        watched[tool]=true
        local ammo=tool:FindFirstChild("Ammo")
        local mag=ammo and ammo:FindFirstChild("MagAmmo")
        if mag and mag:IsA("ValueBase") then
            local last=tonumber(mag.Value)
            mag:GetPropertyChangedSignal("Value"):Connect(function()
                local n=tonumber(mag.Value)
                if n and last and n<last then play() end
                last=n
            end)
        else
            tool.Activated:Connect(play)
        end
    end

    local function scan()
        local ch=LP.Character
        if ch then for _,x in ipairs(ch:GetChildren()) do if x:IsA("Tool") then watchTool(x) end end end
        local bp=LP:FindFirstChildOfClass("Backpack")
        if bp then for _,x in ipairs(bp:GetChildren()) do if x:IsA("Tool") then watchTool(x) end end end
    end

    local function bind()
        local ch=LP.Character
        if ch then ch.ChildAdded:Connect(function(x) if x:IsA("Tool") then task.defer(watchTool,x) end end) end
        local bp=LP:FindFirstChildOfClass("Backpack")
        if bp then bp.ChildAdded:Connect(function(x) if x:IsA("Tool") then task.defer(watchTool,x) end end) end
    end

    LP.CharacterAdded:Connect(function() task.delay(.2,function() bind();scan() end) end)
    bind();scan()
end
