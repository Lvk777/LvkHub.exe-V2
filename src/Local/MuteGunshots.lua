-- Local audio preference: mute gunshot/firing sounds while preserving LvkHub HitSound.
-- No global print/log hooks and no server-side changes.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local Workspace=game:GetService("Workspace")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Local

    State.Local.MuteGunshots=State.Local.MuteGunshots==true

    UI.Toggle(page,"Mute Gunshots",function()
        return State.Local.MuteGunshots
    end,function(v)
        State.Local.MuteGunshots=v
    end)

    local snapshots=setmetatable({}, {__mode="k"})
    local guards=setmetatable({}, {__mode="k"})

    local patterns={"gunshot","gun shot","shoot","shot","muzzle","weaponfire","weapon_fire","fire sound","firesound","bulletfire","bullet_fire"}

    local function full(obj)
        local ok,r=pcall(function() return obj:GetFullName() end)
        return ok and string.lower(r) or string.lower(obj.Name)
    end

    local function containsAny(s)
        s=string.lower(s or "")
        for _,p in ipairs(patterns) do
            if string.find(s,p,1,true) then return true end
        end
        return false
    end

    local function isHubHitSound(sound)
        if string.find(sound.Name,"LvkHubHitSound",1,true) then return true end
        return string.find(tostring(sound.SoundId),"91546829095879",1,true)~=nil
    end

    local function shouldMute(sound)
        if not sound or not sound:IsA("Sound") or isHubHitSound(sound) then return false end
        local n=string.lower(sound.Name)
        local p=full(sound)
        local camera=Workspace.CurrentCamera
        local inTool=sound:FindFirstAncestorWhichIsA("Tool")~=nil
        local inCamera=camera and sound:IsDescendantOf(camera)
        local weaponPath=string.find(p,"weapon",1,true) or string.find(p,"gunsystem",1,true) or string.find(p,"firearm",1,true)
        if containsAny(n) then return true end
        if (inTool or inCamera or weaponPath) and containsAny(p) then return true end
        return false
    end

    local applying=false
    local function mute(sound)
        if not State.Local.MuteGunshots or not shouldMute(sound) then return end
        if snapshots[sound]==nil then snapshots[sound]=sound.Volume end
        if not guards[sound] then
            guards[sound]=sound:GetPropertyChangedSignal("Volume"):Connect(function()
                if applying or not State.Local.MuteGunshots or not sound.Parent then return end
                if shouldMute(sound) and sound.Volume~=0 then
                    applying=true
                    sound.Volume=0
                    applying=false
                end
            end)
        end
        if sound.Volume~=0 then
            applying=true
            sound.Volume=0
            applying=false
        end
    end

    local function restoreAll()
        applying=true
        for sound,volume in pairs(snapshots) do
            if sound and sound.Parent then pcall(function() sound.Volume=volume end) end
            snapshots[sound]=nil
        end
        applying=false
        for sound,c in pairs(guards) do
            pcall(function() c:Disconnect() end)
            guards[sound]=nil
        end
    end

    local function scan(root)
        if not root then return end
        if root:IsA("Sound") then mute(root) end
        for _,obj in ipairs(root:GetDescendants()) do
            if obj:IsA("Sound") then mute(obj) end
        end
    end

    local function scanAll()
        scan(LP.Character)
        scan(LP:FindFirstChild("PlayerGui"))
        scan(Workspace.CurrentCamera)
        scan(Workspace)
    end

    Workspace.DescendantAdded:Connect(function(obj)
        if State.Local.MuteGunshots and obj:IsA("Sound") then task.defer(mute,obj) end
    end)

    local pg=LP:FindFirstChild("PlayerGui")
    if pg then
        pg.DescendantAdded:Connect(function(obj)
            if State.Local.MuteGunshots and obj:IsA("Sound") then task.defer(mute,obj) end
        end)
    end

    LP.CharacterAdded:Connect(function(char)
        char.DescendantAdded:Connect(function(obj)
            if State.Local.MuteGunshots and obj:IsA("Sound") then task.defer(mute,obj) end
        end)
        if State.Local.MuteGunshots then task.delay(.25,scanAll) end
    end)

    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if State.Local.MuteGunshots then task.defer(scanAll) end
    end)

    local last=State.Local.MuteGunshots
    if last then task.defer(scanAll) end
    task.spawn(function()
        while task.wait(.20) do
            local now=State.Local.MuteGunshots==true
            if now~=last then
                last=now
                if now then scanAll() else restoreAll() end
            elseif now then
                -- Re-assert only on already tracked sounds; avoids full-world rescans every frame.
                for sound in pairs(snapshots) do
                    if sound and sound.Parent and shouldMute(sound) and sound.Volume~=0 then mute(sound) end
                end
            end
        end
    end)
end
