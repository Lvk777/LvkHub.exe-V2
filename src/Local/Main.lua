return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Local
    local Camera=Workspace.CurrentCamera
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() Camera=Workspace.CurrentCamera end)

    local BLUE=Color3.fromRGB(119,120,255)
    local materialMap={
        ForceField=Enum.Material.ForceField,
        Neon=Enum.Material.Neon,
        SmoothPlastic=Enum.Material.SmoothPlastic,
        Glass=Enum.Material.Glass,
        Foil=Enum.Material.Foil,
        Metal=Enum.Material.Metal,
        Plastic=Enum.Material.Plastic,
    }
    local materialList={"ForceField","Neon","SmoothPlastic","Glass","Foil","Metal","Plastic"}

    UI.Section(page,"Local")
    UI.Toggle(page,"HitSound",function() return State.Local.HitSound end,function(v) State.Local.HitSound=v end)

    -- =====================================================================
    -- SelfChams: ported from Yokai VisualsV4.
    -- =====================================================================
    local selfMaterial="ForceField"
    local selfColor=BLUE
    local selfTransparency=15
    UI.Toggle(page,"SelfChams",function() return State.Local.SelfChams end,function(v) State.Local.SelfChams=v end)
    UI.Dropdown(page,"Self Material",materialList,function() return selfMaterial end,function(v) selfMaterial=v end)
    UI.Number(page,"Self Transparency",function() return selfTransparency end,function(v) selfTransparency=v end,0,90)

    -- =====================================================================
    -- GunChams: ported from Yokai VisualsV4. Same material/texture handling,
    -- visibility-color logic and camera/viewmodel detection.
    -- =====================================================================
    local gunMaterial="ForceField"
    local gunVisibleColor=Color3.fromRGB(40,235,90)
    local gunOccludedColor=Color3.fromRGB(245,55,55)
    local gunUseVisibility=true
    local gunTransparency=0
    UI.Toggle(page,"GunChams",function() return State.Local.GunChams end,function(v) State.Local.GunChams=v end)
    UI.Dropdown(page,"Gun Material",materialList,function() return gunMaterial end,function(v) gunMaterial=v end)
    UI.Toggle(page,"Visibility Colors",function() return gunUseVisibility end,function(v) gunUseVisibility=v end)
    UI.Number(page,"Gun Transparency",function() return gunTransparency end,function(v) gunTransparency=v end,0,90)

    -- =====================================================================
    -- Trail: exact old Yokai Breadcrumbs geometry/lifetime semantics.
    -- Original defaults: Lifetime=20 -> 2.0 sec, Thickness=7 -> +/-0.07.
    -- =====================================================================
    local trailLifetime=20
    local trailThickness=7
    UI.Toggle(page,"Trail",function() return State.Local.Trail end,function(v) State.Local.Trail=v end)
    UI.Number(page,"Trail Lifetime",function() return trailLifetime end,function(v) trailLifetime=v end,1,100)
    UI.Number(page,"Trail Thickness",function() return trailThickness end,function(v) trailThickness=v end,1,30)

    local sound=Instance.new("Sound")
    sound.Name="LvkHubHitSound"
    sound.SoundId="rbxassetid://160715357"
    sound.Volume=.65
    sound.Parent=Camera or Workspace

    local healthCache=setmetatable({}, {__mode="k"})

    -- SelfChams state -------------------------------------------------------
    local selfParts=setmetatable({}, {__mode="k"})
    local selfTextures=setmetatable({}, {__mode="k"})
    local function rememberSelf(part)
        if selfParts[part] then return end
        selfParts[part]={
            Material=part.Material,
            Color=part.Color,
            Transparency=part.Transparency,
            LocalTransparencyModifier=part.LocalTransparencyModifier,
            CastShadow=part.CastShadow,
            TextureID=part:IsA("MeshPart") and part.TextureID or nil,
        }
    end
    local function applySelf()
        if not State.Local.SelfChams then return end
        local char=LP.Character
        if not char then return end
        for _,obj in ipairs(char:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name~="HumanoidRootPart" and not obj:FindFirstAncestorWhichIsA("Tool") then
                rememberSelf(obj)
                obj.Material=materialMap[selfMaterial] or Enum.Material.ForceField
                obj.Color=selfColor
                obj.Transparency=selfTransparency/100
                obj.LocalTransparencyModifier=0
                obj.CastShadow=false
                if obj:IsA("MeshPart") then obj.TextureID="" end
            elseif (obj:IsA("Decal") or obj:IsA("Texture")) and not obj:FindFirstAncestorWhichIsA("Tool") then
                if selfTextures[obj]==nil then selfTextures[obj]=obj.Transparency end
                obj.Transparency=1
            end
        end
        local head=char:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            rememberSelf(head)
            head.Material=materialMap[selfMaterial] or Enum.Material.ForceField
            head.Color=selfColor
            head.Transparency=selfTransparency/100
            head.LocalTransparencyModifier=0
            head.CastShadow=false
            if head:IsA("MeshPart") then head.TextureID="" end
        end
    end
    local function restoreSelf()
        for part,state in pairs(selfParts) do
            if part and part.Parent then pcall(function()
                part.Material=state.Material
                part.Color=state.Color
                part.Transparency=state.Transparency
                part.LocalTransparencyModifier=state.LocalTransparencyModifier
                part.CastShadow=state.CastShadow
                if part:IsA("MeshPart") and state.TextureID~=nil then part.TextureID=state.TextureID end
            end) end
        end
        for obj,t in pairs(selfTextures) do if obj and obj.Parent then pcall(function() obj.Transparency=t end) end end
        table.clear(selfParts)
        table.clear(selfTextures)
    end

    -- GunChams state --------------------------------------------------------
    local gunState=setmetatable({}, {__mode="k"})
    local gunTextures=setmetatable({}, {__mode="k"})
    local function isGunPart(part)
        if not part:IsA("BasePart") then return false end
        local char=LP.Character
        if char and part:IsDescendantOf(char) and part:FindFirstAncestorWhichIsA("Tool") then return true end
        if Camera and part:IsDescendantOf(Camera) then
            local cur=part.Parent
            while cur and cur~=Camera do
                if cur:IsA("Tool") then return true end
                if cur:IsA("Model") then
                    local n=cur.Name:lower()
                    if n:find("view") or n:find("weapon") or n:find("gun") or n:find("arms") or n=="currentweapon" then return true end
                end
                cur=cur.Parent
            end
        end
        return false
    end
    local function gunVisible(part)
        if not Camera or part:IsDescendantOf(Camera) then return true end
        local origin=Camera.CFrame.Position
        local direction=part.Position-origin
        if direction.Magnitude<.1 then return true end
        local rp=RaycastParams.new()
        rp.FilterType=Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances={LP.Character,Camera}
        rp.IgnoreWater=true
        local result=Workspace:Raycast(origin,direction,rp)
        return result==nil
    end
    local function applyGun()
        if not State.Local.GunChams then return end
        local active={}
        local roots={LP.Character,Camera}
        for _,root in ipairs(roots) do
            if root then
                for _,obj in ipairs(root:GetDescendants()) do
                    if isGunPart(obj) then
                        active[obj]=true
                        if not gunState[obj] then
                            gunState[obj]={Material=obj.Material,Color=obj.Color,Transparency=obj.Transparency,CastShadow=obj.CastShadow,TextureID=obj:IsA("MeshPart") and obj.TextureID or nil}
                        end
                        local visible=(not gunUseVisibility) or gunVisible(obj)
                        obj.Material=materialMap[gunMaterial] or Enum.Material.ForceField
                        obj.Color=visible and gunVisibleColor or gunOccludedColor
                        obj.Transparency=gunTransparency/100
                        obj.CastShadow=false
                        if obj:IsA("MeshPart") then obj.TextureID="" end
                        for _,d in ipairs(obj:GetDescendants()) do
                            if d:IsA("Decal") or d:IsA("Texture") then
                                if gunTextures[d]==nil then gunTextures[d]=d.Transparency end
                                d.Transparency=1
                            end
                        end
                    end
                end
            end
        end
        for part,state in pairs(gunState) do
            if not active[part] and part and part.Parent then
                pcall(function()
                    part.Material=state.Material
                    part.Color=state.Color
                    part.Transparency=state.Transparency
                    part.CastShadow=state.CastShadow
                    if part:IsA("MeshPart") and state.TextureID~=nil then part.TextureID=state.TextureID end
                end)
                gunState[part]=nil
            end
        end
    end
    local function restoreGun()
        for part,state in pairs(gunState) do if part and part.Parent then pcall(function()
            part.Material=state.Material
            part.Color=state.Color
            part.Transparency=state.Transparency
            part.CastShadow=state.CastShadow
            if part:IsA("MeshPart") and state.TextureID~=nil then part.TextureID=state.TextureID end
        end) end end
        for obj,t in pairs(gunTextures) do if obj and obj.Parent then pcall(function() obj.Transparency=t end) end end
        table.clear(gunState)
        table.clear(gunTextures)
    end

    -- Exact Yokai Breadcrumbs trail ----------------------------------------
    local breadcrumbtrail=nil
    local breadcrumbattachment=nil
    local breadcrumbattachment2=nil
    local function destroyTrail()
        if breadcrumbtrail then pcall(function() breadcrumbtrail:Destroy() end) end
        if breadcrumbattachment then pcall(function() breadcrumbattachment:Destroy() end) end
        if breadcrumbattachment2 then pcall(function() breadcrumbattachment2:Destroy() end) end
        breadcrumbtrail=nil
        breadcrumbattachment=nil
        breadcrumbattachment2=nil
    end
    local function ensureTrail()
        if not State.Local.Trail then destroyTrail(); return end
        local char=LP.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not root or not Camera then return end
        if not breadcrumbtrail then
            breadcrumbattachment=Instance.new("Attachment")
            breadcrumbattachment.Position=Vector3.new(0,(trailThickness/100)-2.7,0)
            breadcrumbattachment2=Instance.new("Attachment")
            breadcrumbattachment2.Position=Vector3.new(0,-(trailThickness/100)-2.7,0)
            breadcrumbtrail=Instance.new("Trail")
            breadcrumbtrail.Name="LvkHubTrail"
            breadcrumbtrail.Attachment0=breadcrumbattachment
            breadcrumbtrail.Attachment1=breadcrumbattachment2
            breadcrumbtrail.Color=ColorSequence.new(BLUE,BLUE)
            breadcrumbtrail.FaceCamera=true
            breadcrumbtrail.Lifetime=trailLifetime/10
            breadcrumbtrail.Enabled=true
        end
        breadcrumbattachment.Position=Vector3.new(0,(trailThickness/100)-2.7,0)
        breadcrumbattachment2.Position=Vector3.new(0,-(trailThickness/100)-2.7,0)
        breadcrumbtrail.Lifetime=trailLifetime/10
        breadcrumbattachment.Parent=root
        breadcrumbattachment2.Parent=root
        breadcrumbtrail.Parent=Camera
    end

    local selfWas=false
    local gunWas=false
    local trailWas=false
    local selfTimer=0
    local gunTimer=0
    local trailTimer=0

    RunService.Heartbeat:Connect(function(dt)
        if State.Local.HitSound then
            for model in pairs(Registry.Bots) do
                local hum=Registry.HumanoidOf(model)
                if hum then
                    local last=healthCache[hum]
                    if last and hum.Health<last then pcall(function() sound:Play() end) end
                    healthCache[hum]=hum.Health
                end
            end
        end

        if State.Local.SelfChams~=selfWas then
            if State.Local.SelfChams then applySelf() else restoreSelf() end
            selfWas=State.Local.SelfChams
        end
        selfTimer+=dt
        if State.Local.SelfChams and selfTimer>=.25 then selfTimer=0; applySelf() end

        if State.Local.GunChams~=gunWas then
            if State.Local.GunChams then applyGun() else restoreGun() end
            gunWas=State.Local.GunChams
        end
        gunTimer+=dt
        if State.Local.GunChams and gunTimer>=.08 then gunTimer=0; applyGun() end

        if State.Local.Trail~=trailWas then
            if State.Local.Trail then ensureTrail() else destroyTrail() end
            trailWas=State.Local.Trail
        end
        trailTimer+=dt
        if State.Local.Trail and trailTimer>=.30 then trailTimer=0; ensureTrail() end
    end)

    LP.CharacterAdded:Connect(function()
        restoreSelf()
        destroyTrail()
        task.wait(.45)
        if State.Local.SelfChams then applySelf() end
        if State.Local.Trail then ensureTrail() end
    end)
end
