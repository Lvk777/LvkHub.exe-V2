-- LvkHub.exe Local V4
-- SelfChams and GunChams are client-only Highlight overlays.
-- HitSound playback is owned only by DummyHitSoundV2.lua to avoid duplicate sounds.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")

    local LP=Players.LocalPlayer
    local page=UI.Pages.Local
    local Camera=Workspace.CurrentCamera

    local A=State.Local._Appearance or {}
    A.SelfColor=A.SelfColor or Color3.fromRGB(119,120,255)
    A.GunColor=A.GunColor or Color3.fromRGB(119,120,255)
    A.TrailColor=A.TrailColor or Color3.fromRGB(119,120,255)
    A.SelfTransparency=tonumber(A.SelfTransparency) or 45
    A.GunTransparency=tonumber(A.GunTransparency) or 35
    A.SelfGlow=A.SelfGlow==true
    A.GunGlow=A.GunGlow==true
    A.TrailLifetime=tonumber(A.TrailLifetime) or 20
    A.TrailThickness=tonumber(A.TrailThickness) or 7
    State.Local._Appearance=A

    UI.Section(page,"Local")
    UI.Toggle(page,"HitSound",function() return State.Local.HitSound end,function(v) State.Local.HitSound=v end)
    UI.Toggle(page,"SelfChams",function() return State.Local.SelfChams end,function(v) State.Local.SelfChams=v end)
    UI.Toggle(page,"GunChams",function() return State.Local.GunChams end,function(v) State.Local.GunChams=v end)
    UI.Toggle(page,"Trail",function() return State.Local.Trail end,function(v) State.Local.Trail=v end)

    local selfHighlight=nil
    local gunHighlights=setmetatable({}, {__mode="k"})

    local function destroySelf()
        if selfHighlight then selfHighlight:Destroy(); selfHighlight=nil end
    end

    local function selfFillTransparency()
        local t=math.clamp((tonumber(A.SelfTransparency) or 45)/100,0,1)
        return math.clamp(.42+t*.50,.42,.94)
    end

    local function gunFillTransparency()
        local t=math.clamp((tonumber(A.GunTransparency) or 35)/100,0,1)
        return math.clamp(.34+t*.56,.34,.94)
    end

    local function updateSelf()
        if not State.Local.SelfChams then destroySelf(); return end
        local ch=LP.Character
        local cam=Workspace.CurrentCamera
        if not ch or not cam then destroySelf(); return end
        if not selfHighlight or not selfHighlight.Parent then
            selfHighlight=Instance.new("Highlight")
            selfHighlight.Name="LvkHubSelfChamsLocal"
            selfHighlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
            selfHighlight.Parent=cam
        end
        selfHighlight.Adornee=ch
        selfHighlight.FillColor=A.SelfColor
        selfHighlight.OutlineColor=A.SelfColor
        selfHighlight.FillTransparency=selfFillTransparency()
        selfHighlight.OutlineTransparency=A.SelfGlow and .02 or .34
        selfHighlight.Enabled=true
    end

    local function equippedTool()
        local ch=LP.Character
        if not ch then return nil end
        for _,x in ipairs(ch:GetChildren()) do
            if x:IsA("Tool") then return x end
        end
        return nil
    end

    local function addUnique(list,seen,obj)
        if obj and not seen[obj] then
            seen[obj]=true
            table.insert(list,obj)
        end
    end

    local function weaponAdornees()
        local result,seen={},{}
        local tool=equippedTool()
        if tool then
            local model=tool:FindFirstChildWhichIsA("Model",true)
            if model then
                addUnique(result,seen,model)
            else
                for _,p in ipairs(tool:GetDescendants()) do
                    if p:IsA("BasePart") then addUnique(result,seen,p) end
                end
            end
        end

        local cam=Workspace.CurrentCamera
        if cam then
            local toolName=tool and tool.Name:lower() or ""
            for _,m in ipairs(cam:GetDescendants()) do
                if m:IsA("Model") then
                    local n=m.Name:lower()
                    local grip=m:FindFirstChild("Grip",true)
                    local muzzle=grip and grip:FindFirstChild("Muzzle",true)
                    if (toolName~="" and (n==toolName or n:find(toolName,1,true))) or (grip and muzzle) then
                        addUnique(result,seen,m)
                    end
                end
            end
        end
        return result
    end

    local function clearGun()
        for obj,h in pairs(gunHighlights) do
            if h then pcall(function() h:Destroy() end) end
            gunHighlights[obj]=nil
        end
    end

    local function updateGun()
        if not State.Local.GunChams then clearGun(); return end
        local cam=Workspace.CurrentCamera
        if not cam then clearGun(); return end
        local live={}
        for _,adornee in ipairs(weaponAdornees()) do
            live[adornee]=true
            local h=gunHighlights[adornee]
            if not h or not h.Parent then
                h=Instance.new("Highlight")
                h.Name="LvkHubGunChamsLocal"
                h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent=cam
                gunHighlights[adornee]=h
            end
            h.Adornee=adornee
            h.FillColor=A.GunColor
            h.OutlineColor=A.GunColor
            h.FillTransparency=gunFillTransparency()
            h.OutlineTransparency=A.GunGlow and 0 or .28
            h.Enabled=true
        end
        for obj,h in pairs(gunHighlights) do
            if not live[obj] or not obj.Parent then
                if h then h:Destroy() end
                gunHighlights[obj]=nil
            end
        end
    end

    local trail,a0,a1=nil,nil,nil
    local function clearTrail()
        if trail then trail:Destroy() end
        if a0 then a0:Destroy() end
        if a1 then a1:Destroy() end
        trail=nil; a0=nil; a1=nil
    end

    local function updateTrail()
        if not State.Local.Trail then clearTrail(); return end
        local ch=LP.Character
        local root=ch and ch:FindFirstChild("HumanoidRootPart")
        local cam=Workspace.CurrentCamera
        if not root or not cam then clearTrail(); return end
        if not trail then
            a0=Instance.new("Attachment")
            a0.Name="LvkHubTrailA0"
            a1=Instance.new("Attachment")
            a1.Name="LvkHubTrailA1"
            trail=Instance.new("Trail")
            trail.Name="LvkHubTrailLocal"
            trail.Attachment0=a0
            trail.Attachment1=a1
            trail.FaceCamera=true
            trail.Enabled=true
            a0.Parent=root
            a1.Parent=root
            trail.Parent=cam
        end
        local width=math.clamp((tonumber(A.TrailThickness) or 7)/10,.08,3)
        a0.Position=Vector3.new(width*.5,-2.3,0)
        a1.Position=Vector3.new(-width*.5,-2.3,0)
        trail.Lifetime=math.clamp((tonumber(A.TrailLifetime) or 20)/10,.1,10)
        trail.Color=ColorSequence.new(A.TrailColor,A.TrailColor)
        trail.Transparency=NumberSequence.new({
            NumberSequenceKeypoint.new(0,.08),
            NumberSequenceKeypoint.new(1,1),
        })
        trail.WidthScale=NumberSequence.new({
            NumberSequenceKeypoint.new(0,width),
            NumberSequenceKeypoint.new(1,0),
        })
        trail.LightEmission=State.Local.TrailGlow and 1 or .15
    end

    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        Camera=Workspace.CurrentCamera
        destroySelf()
        clearGun()
    end)

    local timer=0
    RunService.RenderStepped:Connect(function(dt)
        timer+=dt
        if timer<.08 then return end
        timer=0
        updateSelf()
        updateGun()
        updateTrail()
    end)

    LP.CharacterAdded:Connect(function()
        destroySelf(); clearGun(); clearTrail()
    end)
end
