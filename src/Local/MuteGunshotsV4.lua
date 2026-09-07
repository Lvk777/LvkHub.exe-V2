-- Local gunshot mute V4.
-- Learns the actual firing Sound on first shots and keeps it muted consistently during semi-auto and full-auto.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local Workspace=game:GetService("Workspace")
    local UIS=game:GetService("UserInputService")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Local

    State.Local.MuteGunshots=State.Local.MuteGunshots==true
    UI.Toggle(page,"Mute Gunshots",function() return State.Local.MuteGunshots end,function(v) State.Local.MuteGunshots=v end)

    local snapshots=setmetatable({}, {__mode="k"})
    local learned=setmetatable({}, {__mode="k"})
    local watched=setmetatable({}, {__mode="k"})
    local shotUntil=0

    local function currentTool()
        local ch=LP.Character;if not ch then return nil end
        for _,x in ipairs(ch:GetChildren()) do if x:IsA("Tool") and (x:FindFirstChild("WeaponConfig") or x:FindFirstChild("Ammo")) then return x end end
    end
    local function weaponContext(sound)
        local tool=currentTool()
        if tool and sound:IsDescendantOf(tool) then return true end
        local cam=Workspace.CurrentCamera
        if cam and sound:IsDescendantOf(cam) then return true end
        local p=sound.Parent
        while p and p~=game do
            if p:IsA("Model") then
                local n=p.Name:lower()
                if n:find("weapon",1,true) or n:find("gun",1,true) then return true end
            end
            p=p.Parent
        end
        return false
    end
    local function isHubSound(s)
        return s.Name:find("LvkHub",1,true)~=nil or tostring(s.SoundId):find("91546829095879",1,true)~=nil
    end
    local function mute(s)
        if not State.Local.MuteGunshots or not s or not s.Parent or isHubSound(s) then return end
        if snapshots[s]==nil then snapshots[s]=s.Volume end
        if s.Volume~=0 then pcall(function() s.Volume=0 end) end
    end
    local function restore()
        for s,v in pairs(snapshots) do if s and s.Parent then pcall(function() s.Volume=v end) end;snapshots[s]=nil end
        table.clear(learned)
    end
    local function watch(s)
        if not s or not s:IsA("Sound") or watched[s] or isHubSound(s) then return end
        watched[s]=true
        s.Played:Connect(function()
            if not State.Local.MuteGunshots then return end
            if learned[s] or (os.clock()<=shotUntil and weaponContext(s)) then
                learned[s]=true
                mute(s)
            end
        end)
        s:GetPropertyChangedSignal("Volume"):Connect(function()
            if State.Local.MuteGunshots and learned[s] and s.Volume~=0 then mute(s) end
        end)
    end
    local function scan(root)
        if not root then return end
        if root:IsA("Sound") then watch(root) end
        for _,d in ipairs(root:GetDescendants()) do if d:IsA("Sound") then watch(d) end end
    end
    local function scanLocalWeaponAudio()
        scan(currentTool())
        scan(Workspace.CurrentCamera)
        scan(LP.Character)
    end
    local function beginShot()
        if not State.Local.MuteGunshots then return end
        shotUntil=os.clock()+.25
        scanLocalWeaponAudio()
        task.defer(function()
            scanLocalWeaponAudio()
            for s in pairs(watched) do
                if s and s.Parent and s.Playing and weaponContext(s) then learned[s]=true;mute(s) end
            end
        end)
    end

    local toolSeen=setmetatable({}, {__mode="k"})
    local function bindTool(tool)
        if not tool or not tool:IsA("Tool") or toolSeen[tool] then return end
        if not (tool:FindFirstChild("WeaponConfig") or tool:FindFirstChild("Ammo")) then return end
        toolSeen[tool]=true
        tool.Activated:Connect(beginShot)
        local ammo=tool:FindFirstChild("Ammo")
        local mag=ammo and ammo:FindFirstChild("MagAmmo")
        if mag and mag:IsA("ValueBase") then
            local last=tonumber(mag.Value)
            mag:GetPropertyChangedSignal("Value"):Connect(function()
                local n=tonumber(mag.Value)
                if n and last and n<last then beginShot() end
                last=n
            end)
        end
        scan(tool)
    end
    local function scanTools()
        local ch=LP.Character;if ch then for _,x in ipairs(ch:GetChildren()) do if x:IsA("Tool") then bindTool(x) end end end
        local bp=LP:FindFirstChildOfClass("Backpack");if bp then for _,x in ipairs(bp:GetChildren()) do if x:IsA("Tool") then bindTool(x) end end end
    end

    if LP.Character then LP.Character.DescendantAdded:Connect(function(d) if d:IsA("Sound") then watch(d) end end);LP.Character.ChildAdded:Connect(function(x) if x:IsA("Tool") then task.defer(bindTool,x) end end) end
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() task.defer(scanLocalWeaponAudio) end)
    UIS.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 and not UIS:GetFocusedTextBox() then beginShot() end end)
    LP.CharacterAdded:Connect(function(ch) task.delay(.15,function() scanTools();scanLocalWeaponAudio() end) end)

    local lastState=State.Local.MuteGunshots
    task.spawn(function()
        while task.wait(.06) do
            scanTools()
            local on=State.Local.MuteGunshots==true
            if on~=lastState then
                lastState=on
                if not on then restore() else scanLocalWeaponAudio() end
            elseif on then
                for s in pairs(learned) do if s and s.Parent and s.Volume~=0 then mute(s) end end
            end
        end
    end)
end
