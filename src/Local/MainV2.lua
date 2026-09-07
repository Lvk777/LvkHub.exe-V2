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

    local selfMaterial="ForceField"
    local selfColor=BLUE
    local selfTransparency=15
    local selfGlow=false
    local gunMaterial="ForceField"
    local gunColor=BLUE
    local gunTransparency=0
    local gunGlow=false
    local trailLifetime=20
    local trailThickness=7

    UI.Section(page,"Local")
    UI.Toggle(page,"HitSound",function() return State.Local.HitSound end,function(v) State.Local.HitSound=v end)

    UI.Toggle(page,"SelfChams",function() return State.Local.SelfChams end,function(v) State.Local.SelfChams=v end)
    UI.Dropdown(page,"Self Material",materialList,function() return selfMaterial end,function(v) selfMaterial=v end)
    UI.Number(page,"Self R",function() return math.floor(selfColor.R*255+.5) end,function(v) selfColor=Color3.fromRGB(v,math.floor(selfColor.G*255+.5),math.floor(selfColor.B*255+.5)) end,0,255)
    UI.Number(page,"Self G",function() return math.floor(selfColor.G*255+.5) end,function(v) selfColor=Color3.fromRGB(math.floor(selfColor.R*255+.5),v,math.floor(selfColor.B*255+.5)) end,0,255)
    UI.Number(page,"Self B",function() return math.floor(selfColor.B*255+.5) end,function(v) selfColor=Color3.fromRGB(math.floor(selfColor.R*255+.5),math.floor(selfColor.G*255+.5),v) end,0,255)
    UI.Number(page,"Self Transparency",function() return selfTransparency end,function(v) selfTransparency=v end,0,90)
    UI.Toggle(page,"Self Glow",function() return selfGlow end,function(v) selfGlow=v end)

    UI.Toggle(page,"GunChams",function() return State.Local.GunChams end,function(v) State.Local.GunChams=v end)
    UI.Dropdown(page,"Gun Material",materialList,function() return gunMaterial end,function(v) gunMaterial=v end)
    UI.Number(page,"Gun R",function() return math.floor(gunColor.R*255+.5) end,function(v) gunColor=Color3.fromRGB(v,math.floor(gunColor.G*255+.5),math.floor(gunColor.B*255+.5)) end,0,255)
    UI.Number(page,"Gun G",function() return math.floor(gunColor.G*255+.5) end,function(v) gunColor=Color3.fromRGB(math.floor(gunColor.R*255+.5),v,math.floor(gunColor.B*255+.5)) end,0,255)
    UI.Number(page,"Gun B",function() return math.floor(gunColor.B*255+.5) end,function(v) gunColor=Color3.fromRGB(math.floor(gunColor.R*255+.5),math.floor(gunColor.G*255+.5),v) end,0,255)
    UI.Number(page,"Gun Transparency",function() return gunTransparency end,function(v) gunTransparency=v end,0,90)
    UI.Toggle(page,"Gun Glow",function() return gunGlow end,function(v) gunGlow=v end)

    UI.Toggle(page,"Trail",function() return State.Local.Trail end,function(v) State.Local.Trail=v end)
    UI.Number(page,"Trail Lifetime",function() return trailLifetime end,function(v) trailLifetime=v end,1,100)
    UI.Number(page,"Trail Thickness",function() return trailThickness end,function(v) trailThickness=v end,1,30)

    local sound=Instance.new("Sound")
    sound.Name="LvkHubHitSoundV2"
    sound.SoundId="rbxassetid://160715357"
    sound.Volume=.7
    sound.Parent=Camera or Workspace
    shared.LvkHubPlayHitSound=function()
        if State.Local.HitSound then
            if Camera and sound.Parent~=Camera then sound.Parent=Camera end
            pcall(function() sound.TimePosition=0; sound:Play() end)
        end
    end

    ------------------------------------------------------------------------
    -- Self chams: stays applied while weapon scripts rebuild/retouch avatar.
    ------------------------------------------------------------------------
    local selfParts=setmetatable({}, {__mode="k"})
    local selfTextures=setmetatable({}, {__mode="k"})
    local selfHighlight=nil

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

    local function ensureSelfHighlight(char)
        if not selfGlow then
            if selfHighlight then selfHighlight:Destroy(); selfHighlight=nil end
            return
        end
        if not selfHighlight or not selfHighlight.Parent then
            selfHighlight=Instance.new("Highlight")
            selfHighlight.Name="LvkHubSelfGlow"
            selfHighlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
            selfHighlight.FillTransparency=.78
            selfHighlight.OutlineTransparency=.05
            selfHighlight.Parent=char
        end
        selfHighlight.Adornee=char
        selfHighlight.FillColor=selfColor
        selfHighlight.OutlineColor=selfColor
        selfHighlight.Enabled=State.Local.SelfChams and selfGlow
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
        ensureSelfHighlight(char)
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
        for obj,t in pairs(selfTextures) do
            if obj and obj.Parent then pcall(function() obj.Transparency=t end) end
        end
        table.clear(selfParts)
        table.clear(selfTextures)
        if selfHighlight then selfHighlight:Destroy(); selfHighlight=nil end
    end

    ------------------------------------------------------------------------
    -- Gun chams: only actual Tool/weapon models. Never camera arm/body rigs.
    ------------------------------------------------------------------------
    local gunState=setmetatable({}, {__mode="k"})
    local gunTextures=setmetatable({}, {__mode="k"})
    local gunHighlights=setmetatable({}, {__mode="k"})

    local bodyNames={
        ["head"]=true,["torso"]=true,["uppertorso"]=true,["lowertorso"]=true,
        ["humanoidrootpart"]=true,["left arm"]=true,["right arm"]=true,
        ["left leg"]=true,["right leg"]=true,["lefthand"]=true,["righthand"]=true,
        ["leftupperarm"]=true,["rightupperarm"]=true,["leftlowerarm"]=true,["rightlowerarm"]=true,
        ["leftupperleg"]=true,["rightupperleg"]=true,["leftlowerleg"]=true,["rightlowerleg"]=true,
    }

    local function equippedTool()
        local char=LP.Character
        if not char then return nil end
        for _,x in ipairs(char:GetChildren()) do
            if x:IsA("Tool") then return x end
        end
        return nil
    end

    local function cameraWeaponRoots(tool)
        local roots={}
        if tool then table.insert(roots,tool) end
        if not Camera then return roots end
        local toolName=tool and tool.Name:lower() or ""
        for _,m in ipairs(Camera:GetDescendants()) do
            if m:IsA("Model") then
                local n=m.Name:lower()
                local grip=m:FindFirstChild("Grip",true)
                local muzzle=grip and grip:FindFirstChild("Muzzle",true)
                local strongName=toolName~="" and (n==toolName or n:find(toolName,1,true))
                if strongName or (grip and muzzle) then
                    table.insert(roots,m)
                end
            end
        end
        return roots
    end

    local function ensureGunGlow(root)
        if not gunGlow then
            local old=gunHighlights[root]
            if old then old:Destroy(); gunHighlights[root]=nil end
            return
        end
        local h=gunHighlights[root]
        if not h or not h.Parent then
            h=Instance.new("Highlight")
            h.Name="LvkHubGunGlow"
            h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
            h.FillTransparency=.80
            h.OutlineTransparency=.05
            h.Parent=root
            gunHighlights[root]=h
        end
        h.Adornee=root
        h.FillColor=gunColor
        h.OutlineColor=gunColor
        h.Enabled=State.Local.GunChams and gunGlow
    end

    local function applyGun()
        if not State.Local.GunChams then return end
        local tool=equippedTool()
        local active={}
        local roots=cameraWeaponRoots(tool)
        for _,root in ipairs(roots) do
            ensureGunGlow(root)
            for _,obj in ipairs(root:GetDescendants()) do
                if obj:IsA("BasePart") and not bodyNames[obj.Name:lower()] then
                    active[obj]=true
                    if not gunState[obj] then
                        gunState[obj]={Material=obj.Material,Color=obj.Color,Transparency=obj.Transparency,CastShadow=obj.CastShadow,TextureID=obj:IsA("MeshPart") and obj.TextureID or nil}
                    end
                    obj.Material=materialMap[gunMaterial] or Enum.Material.ForceField
                    obj.Color=gunColor
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

        for part,state in pairs(gunState) do
            if not active[part] then
                if part and part.Parent then pcall(function()
                    part.Material=state.Material
                    part.Color=state.Color
                    part.Transparency=state.Transparency
                    part.CastShadow=state.CastShadow
                    if part:IsA("MeshPart") and state.TextureID~=nil then part.TextureID=state.TextureID end
                end) end
                gunState[part]=nil
            end
        end
        for root,h in pairs(gunHighlights) do
            if not table.find(roots,root) then
                if h then h:Destroy() end
                gunHighlights[root]=nil
            end
        end
    end

    local function restoreGun()
        for part,state in pairs(gunState) do
            if part and part.Parent then pcall(function()
                part.Material=state.Material
                part.Color=state.Color
                part.Transparency=state.Transparency
                part.CastShadow=state.CastShadow
                if part:IsA("MeshPart") and state.TextureID~=nil then part.TextureID=state.TextureID end
            end) end
        end
        for obj,t in pairs(gunTextures) do if obj and obj.Parent then pcall(function() obj.Transparency=t end) end end
        for _,h in pairs(gunHighlights) do if h then pcall(function() h:Destroy() end) end end
        table.clear(gunState); table.clear(gunTextures); table.clear(gunHighlights)
    end

    ------------------------------------------------------------------------
    -- Trail.
    ------------------------------------------------------------------------
    local breadcrumbtrail=nil
    local a0=nil
    local a1=nil
    local function destroyTrail()
        if breadcrumbtrail then breadcrumbtrail:Destroy() end
        if a0 then a0:Destroy() end
        if a1 then a1:Destroy() end
        breadcrumbtrail=nil; a0=nil; a1=nil
    end
    local function ensureTrail()
        if not State.Local.Trail then destroyTrail(); return end
        local char=LP.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if not root or not Camera then return end
        if not breadcrumbtrail then
            a0=Instance.new("Attachment")
            a1=Instance.new("Attachment")
            breadcrumbtrail=Instance.new("Trail")
            breadcrumbtrail.Name="LvkHubTrail"
            breadcrumbtrail.Attachment0=a0
            breadcrumbtrail.Attachment1=a1
            breadcrumbtrail.Color=ColorSequence.new(BLUE,BLUE)
            breadcrumbtrail.FaceCamera=true
            breadcrumbtrail.Enabled=true
        end
        a0.Position=Vector3.new(0,(trailThickness/100)-2.7,0)
        a1.Position=Vector3.new(0,-(trailThickness/100)-2.7,0)
        breadcrumbtrail.Lifetime=trailLifetime/10
        a0.Parent=root; a1.Parent=root; breadcrumbtrail.Parent=Camera
    end

    local healthCache=setmetatable({}, {__mode="k"})
    local selfWas=false
    local gunWas=false
    local trailWas=false
    local selfTick=0
    local gunTick=0
    local trailTick=0

    RunService.RenderStepped:Connect(function(dt)
        if State.Local.HitSound then
            for model in pairs(Registry.Bots) do
                local hum=Registry.HumanoidOf(model)
                if hum then
                    local last=healthCache[hum]
                    if last and hum.Health<last then shared.LvkHubPlayHitSound() end
                    healthCache[hum]=hum.Health
                end
            end
        end

        if State.Local.SelfChams~=selfWas then
            if State.Local.SelfChams then applySelf() else restoreSelf() end
            selfWas=State.Local.SelfChams
        end
        selfTick+=dt
        if State.Local.SelfChams and selfTick>=.05 then selfTick=0; applySelf() end
        if State.Local.SelfChams and LP.Character then ensureSelfHighlight(LP.Character) end

        if State.Local.GunChams~=gunWas then
            if State.Local.GunChams then applyGun() else restoreGun() end
            gunWas=State.Local.GunChams
        end
        gunTick+=dt
        if State.Local.GunChams and gunTick>=.05 then gunTick=0; applyGun() end

        if State.Local.Trail~=trailWas then
            if State.Local.Trail then ensureTrail() else destroyTrail() end
            trailWas=State.Local.Trail
        end
        trailTick+=dt
        if State.Local.Trail and trailTick>=.25 then trailTick=0; ensureTrail() end
    end)

    LP.CharacterAdded:Connect(function()
        restoreSelf(); restoreGun(); destroyTrail()
        task.wait(.35)
        if State.Local.SelfChams then applySelf() end
        if State.Local.GunChams then applyGun() end
        if State.Local.Trail then ensureTrail() end
    end)
end
