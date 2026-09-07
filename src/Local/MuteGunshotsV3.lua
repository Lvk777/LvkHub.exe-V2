-- Local audio preference V3: mute gunshot/firing sounds on this client only.
-- Uses explicit sound-name/path matching plus a short local shot window so oddly named
-- WeaponSystem fire sounds are muted too. LvkHub HitSound is always preserved.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local Workspace=game:GetService("Workspace")
    local SoundService=game:GetService("SoundService")
    local ReplicatedStorage=game:GetService("ReplicatedStorage")
    local UIS=game:GetService("UserInputService")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Local

    State.Local.MuteGunshots=State.Local.MuteGunshots==true
    UI.Toggle(page,"Mute Gunshots",function() return State.Local.MuteGunshots end,function(v) State.Local.MuteGunshots=v end)

    local snapshots=setmetatable({}, {__mode="k"})
    local watched=setmetatable({}, {__mode="k"})
    local applying=false
    local shotWindowUntil=0

    local explicit={
        "gunshot","gun shot","weaponfire","weapon_fire","firesound","fire sound","shoot","shot","muzzle",
        "riflefire","pistolfire","revolverfire","firearm","bang","report","fire1","fire2","fire3",
    }

    local function pathOf(obj)
        local ok,s=pcall(function() return obj:GetFullName() end)
        return string.lower(ok and s or obj.Name)
    end

    local function isHubSound(s)
        return s.Name:find("LvkHubHitSound",1,true)~=nil
            or tostring(s.SoundId):find("91546829095879",1,true)~=nil
    end

    local function containsExplicit(s)
        s=string.lower(tostring(s or ""))
        for _,w in ipairs(explicit) do if s:find(w,1,true) then return true end end
        return false
    end

    local function weaponContext(sound,path)
        if sound:FindFirstAncestorWhichIsA("Tool") then return true end
        local cam=Workspace.CurrentCamera
        if cam and sound:IsDescendantOf(cam) then return true end
        if path:find("gunsystem",1,true) or path:find("weaponsystem",1,true) or path:find("weapon",1,true)
            or path:find("firearm",1,true) or path:find("guncontroller",1,true) or path:find("muzzle",1,true) then
            return true
        end
        return false
    end

    local function nearLocal(sound)
        local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        local p=sound.Parent
        while p and p~=game do
            if p:IsA("BasePart") then return (p.Position-root.Position).Magnitude<=40 end
            if p:IsA("Attachment") then return (p.WorldPosition-root.Position).Magnitude<=40 end
            p=p.Parent
        end
        return false
    end

    local function shouldMute(sound)
        if not sound or not sound:IsA("Sound") or isHubSound(sound) then return false end
        local path=pathOf(sound)
        if containsExplicit(sound.Name) or containsExplicit(path) then
            if weaponContext(sound,path) or nearLocal(sound) then return true end
        end
        -- During a local shot, any Sound coming from the equipped weapon/viewmodel or very
        -- close to the local character is treated as the firing report, even with generic names.
        if os.clock()<=shotWindowUntil and (weaponContext(sound,path) or nearLocal(sound)) then return true end
        return false
    end

    local function mute(sound)
        if not State.Local.MuteGunshots or not shouldMute(sound) then return end
        if snapshots[sound]==nil then snapshots[sound]=sound.Volume end
        if sound.Volume~=0 then
            applying=true
            pcall(function() sound.Volume=0 end)
            applying=false
        end
    end

    local function watchSound(sound)
        if not sound or not sound:IsA("Sound") or watched[sound] then return end
        watched[sound]=true
        sound.Played:Connect(function()
            if State.Local.MuteGunshots then mute(sound) end
        end)
        sound:GetPropertyChangedSignal("Volume"):Connect(function()
            if applying or not State.Local.MuteGunshots or not sound.Parent then return end
            if shouldMute(sound) and sound.Volume~=0 then mute(sound) end
        end)
        if State.Local.MuteGunshots then mute(sound) end
    end

    local function scan(root)
        if not root then return end
        if root:IsA("Sound") then watchSound(root) end
        for _,o in ipairs(root:GetDescendants()) do if o:IsA("Sound") then watchSound(o) end end
    end

    local function scanAll()
        scan(LP.Character)
        scan(LP:FindFirstChildOfClass("Backpack"))
        scan(LP:FindFirstChild("PlayerGui"))
        scan(Workspace.CurrentCamera)
        scan(Workspace)
        scan(SoundService)
        local assets=ReplicatedStorage:FindFirstChild("WeaponSystemAssets")
        if assets then scan(assets) end
        local shared=ReplicatedStorage:FindFirstChild("Shared")
        if shared then scan(shared) end
    end

    local function restoreAll()
        applying=true
        for s,v in pairs(snapshots) do
            if s and s.Parent then pcall(function() s.Volume=v end) end
            snapshots[s]=nil
        end
        applying=false
    end

    local function beginShotWindow()
        if not State.Local.MuteGunshots then return end
        shotWindowUntil=math.max(shotWindowUntil,os.clock()+.16)
        -- Catch sounds already playing or created during the shot on the same frame.
        scan(LP.Character)
        scan(Workspace.CurrentCamera)
        scan(SoundService)
        task.defer(function()
            if State.Local.MuteGunshots then
                scan(LP.Character);scan(Workspace.CurrentCamera);scan(Workspace);scan(SoundService)
                for s in pairs(watched) do if s and s.Parent and s.Playing then mute(s) end end
            end
        end)
    end

    local toolWatch=setmetatable({}, {__mode="k"})
    local function watchTool(tool)
        if not tool or not tool:IsA("Tool") or toolWatch[tool] then return end
        if not (tool:FindFirstChild("WeaponConfig") or tool:FindFirstChild("Ammo")) then return end
        toolWatch[tool]=true
        tool.Activated:Connect(beginShotWindow)
        local ammo=tool:FindFirstChild("Ammo")
        local mag=ammo and ammo:FindFirstChild("MagAmmo")
        local last=mag and tonumber(mag.Value)
        if mag and mag:IsA("ValueBase") then
            mag:GetPropertyChangedSignal("Value"):Connect(function()
                local n=tonumber(mag.Value)
                if n and last and n<last then beginShotWindow() end
                last=n
            end)
        end
        scan(tool)
    end

    local function scanTools()
        local ch=LP.Character
        if ch then for _,o in ipairs(ch:GetChildren()) do if o:IsA("Tool") then watchTool(o) end end end
        local bp=LP:FindFirstChildOfClass("Backpack")
        if bp then for _,o in ipairs(bp:GetChildren()) do if o:IsA("Tool") then watchTool(o) end end end
    end

    local function watchRoot(root)
        if not root then return end
        root.DescendantAdded:Connect(function(o)
            if o:IsA("Sound") then task.defer(watchSound,o) end
        end)
    end

    watchRoot(Workspace)
    watchRoot(SoundService)
    watchRoot(LP:FindFirstChild("PlayerGui"))
    watchRoot(LP:FindFirstChildOfClass("Backpack"))
    if Workspace.CurrentCamera then watchRoot(Workspace.CurrentCamera) end

    LP.CharacterAdded:Connect(function(ch)
        watchRoot(ch)
        ch.ChildAdded:Connect(function(o) if o:IsA("Tool") then task.defer(watchTool,o) end end)
        task.delay(.15,function() scanTools();if State.Local.MuteGunshots then scanAll() end end)
    end)
    if LP.Character then
        watchRoot(LP.Character)
        LP.Character.ChildAdded:Connect(function(o) if o:IsA("Tool") then task.defer(watchTool,o) end end)
    end
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if Workspace.CurrentCamera then watchRoot(Workspace.CurrentCamera) end
        if State.Local.MuteGunshots then task.defer(scanAll) end
    end)

    UIS.InputBegan:Connect(function(i,processed)
        if processed and UIS:GetFocusedTextBox() then return end
        if i.UserInputType==Enum.UserInputType.MouseButton1 then beginShotWindow() end
    end)

    scanTools()
    scanAll()
    local lastState=State.Local.MuteGunshots
    task.spawn(function()
        while task.wait(.08) do
            scanTools()
            local on=State.Local.MuteGunshots==true
            if on~=lastState then
                lastState=on
                if on then scanAll() else restoreAll() end
            elseif on then
                if os.clock()<=shotWindowUntil then
                    scan(LP.Character);scan(Workspace.CurrentCamera);scan(SoundService)
                end
                for s in pairs(watched) do if s and s.Parent and s.Playing and shouldMute(s) then mute(s) end end
            end
        end
    end)
end
