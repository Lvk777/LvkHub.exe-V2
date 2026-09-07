-- Local audio preference V2: mute firing/gunshot Sounds on this client only.
-- Preserves LvkHub HitSound and restores original volumes when disabled.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local Workspace=game:GetService("Workspace")
    local SoundService=game:GetService("SoundService")
    local ReplicatedStorage=game:GetService("ReplicatedStorage")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Local

    State.Local.MuteGunshots=State.Local.MuteGunshots==true
    UI.Toggle(page,"Mute Gunshots",function() return State.Local.MuteGunshots end,function(v) State.Local.MuteGunshots=v end)

    local snapshots=setmetatable({}, {__mode="k"})
    local guards=setmetatable({}, {__mode="k"})
    local applying=false

    local strongNames={fire=true,firing=true,shot=true,shoot=true,gunshot=true,muzzle=true}
    local words={"gunshot","gun shot","weaponfire","weapon_fire","firesound","fire sound","shoot","shot","muzzle","rifle","pistol","revolver","firearm"}

    local function lowerPath(obj)
        local ok,s=pcall(function() return obj:GetFullName() end)
        return string.lower(ok and s or obj.Name)
    end
    local function hubSound(s)
        return s.Name:find("LvkHubHitSound",1,true)~=nil or tostring(s.SoundId):find("91546829095879",1,true)~=nil
    end
    local function containsAny(s)
        s=string.lower(s or "")
        for _,w in ipairs(words) do if s:find(w,1,true) then return true end end
        return false
    end
    local function weaponContext(sound,path)
        if sound:FindFirstAncestorWhichIsA("Tool") then return true end
        local cam=Workspace.CurrentCamera
        if cam and sound:IsDescendantOf(cam) then return true end
        if path:find("gunsystem",1,true) or path:find("weaponsystem",1,true) or path:find("weapon",1,true) or path:find("firearm",1,true) then return true end
        local char=sound:FindFirstAncestorOfClass("Model")
        if char and char:FindFirstChildOfClass("Humanoid") and (char:FindFirstChildWhichIsA("Tool") or sound:FindFirstAncestorWhichIsA("Tool")) then return true end
        return false
    end
    local function shouldMute(sound)
        if not sound or not sound:IsA("Sound") or hubSound(sound) then return false end
        local n=string.lower(sound.Name):gsub("[%s_%-]","")
        local p=lowerPath(sound)
        if strongNames[n] and weaponContext(sound,p) then return true end
        if containsAny(sound.Name) and weaponContext(sound,p) then return true end
        if containsAny(p) and (p:find("weapon",1,true) or p:find("gun",1,true) or p:find("firearm",1,true) or p:find("muzzle",1,true)) then return true end
        return false
    end

    local function mute(sound)
        if not State.Local.MuteGunshots or not shouldMute(sound) then return end
        if snapshots[sound]==nil then snapshots[sound]=sound.Volume end
        if not guards[sound] then
            guards[sound]=sound:GetPropertyChangedSignal("Volume"):Connect(function()
                if applying or not State.Local.MuteGunshots or not sound.Parent then return end
                if shouldMute(sound) and sound.Volume~=0 then applying=true;sound.Volume=0;applying=false end
            end)
        end
        if sound.Volume~=0 then applying=true;sound.Volume=0;applying=false end
    end
    local function restoreAll()
        applying=true
        for s,v in pairs(snapshots) do if s and s.Parent then pcall(function() s.Volume=v end) end;snapshots[s]=nil end
        applying=false
        for s,c in pairs(guards) do pcall(function() c:Disconnect() end);guards[s]=nil end
    end
    local function scan(root)
        if not root then return end
        if root:IsA("Sound") then mute(root) end
        for _,o in ipairs(root:GetDescendants()) do if o:IsA("Sound") then mute(o) end end
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
    end
    local function watchRoot(root)
        if not root then return end
        root.DescendantAdded:Connect(function(o) if State.Local.MuteGunshots and o:IsA("Sound") then task.defer(mute,o) end end)
    end
    watchRoot(Workspace);watchRoot(SoundService);watchRoot(LP:FindFirstChild("PlayerGui"));watchRoot(LP:FindFirstChildOfClass("Backpack"))
    if Workspace.CurrentCamera then watchRoot(Workspace.CurrentCamera) end
    LP.CharacterAdded:Connect(function(ch) watchRoot(ch);if State.Local.MuteGunshots then task.delay(.15,scanAll) end end)
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() if Workspace.CurrentCamera then watchRoot(Workspace.CurrentCamera) end;if State.Local.MuteGunshots then task.defer(scanAll) end end)

    local last=State.Local.MuteGunshots
    if last then task.defer(scanAll) end
    task.spawn(function()
        while task.wait(.15) do
            local on=State.Local.MuteGunshots==true
            if on~=last then last=on;if on then scanAll() else restoreAll() end
            elseif on then
                -- New sounds can be very short-lived; rescan relevant local roots frequently.
                scan(LP.Character);scan(Workspace.CurrentCamera);scan(SoundService)
                for s in pairs(snapshots) do if s and s.Parent and shouldMute(s) and s.Volume~=0 then mute(s) end end
            end
        end
    end)
end
