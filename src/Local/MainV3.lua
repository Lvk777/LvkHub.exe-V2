-- Local/self cosmetic features with Yokai-style draggable color bars.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")
    local Workspace=game:GetService("Workspace")

    local LP=Players.LocalPlayer
    local page=UI.Pages.Local
    local Camera=Workspace.CurrentCamera
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() Camera=Workspace.CurrentCamera end)

    local A=State.Local._Appearance or {
        SelfColor=Color3.fromRGB(119,120,255),
        GunColor=Color3.fromRGB(119,120,255),
        TrailColor=Color3.fromRGB(119,120,255),
        SelfMaterial="ForceField",
        GunMaterial="ForceField",
        SelfTransparency=15,
        GunTransparency=0,
        SelfGlow=false,
        GunGlow=false,
        TrailLifetime=20,
        TrailThickness=7,
    }
    State.Local._Appearance=A

    local materialMap={
        ForceField=Enum.Material.ForceField, Neon=Enum.Material.Neon,
        SmoothPlastic=Enum.Material.SmoothPlastic, Glass=Enum.Material.Glass,
        Foil=Enum.Material.Foil, Metal=Enum.Material.Metal, Plastic=Enum.Material.Plastic,
    }
    local materialList={"ForceField","Neon","SmoothPlastic","Glass","Foil","Metal","Plastic"}

    local rainbow=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(1/6,Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6,Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(3/6,Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6,Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(5/6,Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0)),
    })

    local function rounded(obj,r)
        local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 4); c.Parent=obj
    end

    local function colorBar(label,get,set)
        local row,text=UI.Row(page,label,38)
        text.Size=UDim2.fromOffset(72,38)
        local bar=Instance.new("Frame")
        bar.Position=UDim2.fromOffset(80,11)
        bar.Size=UDim2.new(1,-90,0,16)
        bar.BackgroundColor3=Color3.new(1,1,1)
        bar.BorderSizePixel=0
        bar.Active=true
        bar.Parent=row
        rounded(bar,4)
        local grad=Instance.new("UIGradient"); grad.Color=rainbow; grad.Parent=bar
        local knob=Instance.new("Frame")
        knob.AnchorPoint=Vector2.new(.5,.5)
        knob.Size=UDim2.fromOffset(4,22)
        knob.BackgroundColor3=Color3.fromRGB(248,248,250)
        knob.BorderSizePixel=0
        knob.Parent=bar
        local ks=Instance.new("UIStroke"); ks.Color=Color3.fromRGB(20,20,24); ks.Parent=knob
        local dragging=false
        local function sync()
            local c=get(); if typeof(c)=="Color3" then knob.Position=UDim2.new(select(1,c:ToHSV()),0,.5,0) end
        end
        local function setX(x)
            local h=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1)
            set(Color3.fromHSV(h,1,1)); knob.Position=UDim2.new(h,0,.5,0)
        end
        bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; setX(i.Position.X) end end)
        UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then setX(i.Position.X) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
        task.defer(sync)
    end

    UI.Section(page,"Local")
    UI.Toggle(page,"HitSound",function() return State.Local.HitSound end,function(v) State.Local.HitSound=v end)

    UI.Toggle(page,"SelfChams",function() return State.Local.SelfChams end,function(v) State.Local.SelfChams=v end)
    UI.Dropdown(page,"Self Material",materialList,function() return A.SelfMaterial end,function(v) A.SelfMaterial=v end)
    colorBar("Self Color",function() return A.SelfColor end,function(v) A.SelfColor=v end)
    UI.Number(page,"Self Transparency",function() return A.SelfTransparency end,function(v) A.SelfTransparency=v end,0,90)
    UI.Toggle(page,"Self Glow",function() return A.SelfGlow end,function(v) A.SelfGlow=v end)

    UI.Toggle(page,"GunChams",function() return State.Local.GunChams end,function(v) State.Local.GunChams=v end)
    UI.Dropdown(page,"Gun Material",materialList,function() return A.GunMaterial end,function(v) A.GunMaterial=v end)
    colorBar("Gun Color",function() return A.GunColor end,function(v) A.GunColor=v end)
    UI.Number(page,"Gun Transparency",function() return A.GunTransparency end,function(v) A.GunTransparency=v end,0,90)
    UI.Toggle(page,"Gun Glow",function() return A.GunGlow end,function(v) A.GunGlow=v end)

    UI.Toggle(page,"Trail",function() return State.Local.Trail end,function(v) State.Local.Trail=v end)
    colorBar("Trail Color",function() return A.TrailColor end,function(v) A.TrailColor=v end)
    UI.Number(page,"Trail Lifetime",function() return A.TrailLifetime end,function(v) A.TrailLifetime=v end,1,100)
    UI.Number(page,"Trail Thickness",function() return A.TrailThickness end,function(v) A.TrailThickness=v end,1,30)

    local sound=Instance.new("Sound")
    sound.Name="LvkHubHitSoundV3"
    sound.SoundId="rbxassetid://160715357"
    sound.Volume=.7
    sound.Parent=Camera or Workspace
    shared.LvkHubPlayHitSound=function()
        if State.Local.HitSound then
            if Camera and sound.Parent~=Camera then sound.Parent=Camera end
            pcall(function() sound.TimePosition=0; sound:Play() end)
        end
    end

    local selfParts=setmetatable({}, {__mode="k"})
    local selfTextures=setmetatable({}, {__mode="k"})
    local selfHighlight=nil
    local function applySelf()
        if not State.Local.SelfChams then return end
        local ch=LP.Character; if not ch then return end
        for _,o in ipairs(ch:GetDescendants()) do
            if o:IsA("BasePart") and o.Name~="HumanoidRootPart" and not o:FindFirstAncestorWhichIsA("Tool") then
                if not selfParts[o] then
                    selfParts[o]={Material=o.Material,Color=o.Color,Transparency=o.Transparency,LocalTransparencyModifier=o.LocalTransparencyModifier,CastShadow=o.CastShadow,TextureID=o:IsA("MeshPart") and o.TextureID or nil}
                end
                o.Material=materialMap[A.SelfMaterial] or Enum.Material.ForceField
                o.Color=A.SelfColor
                o.Transparency=A.SelfTransparency/100
                o.LocalTransparencyModifier=0
                o.CastShadow=false
                if o:IsA("MeshPart") then o.TextureID="" end
            elseif (o:IsA("Decal") or o:IsA("Texture")) and not o:FindFirstAncestorWhichIsA("Tool") then
                if selfTextures[o]==nil then selfTextures[o]=o.Transparency end
                o.Transparency=1
            end
        end
        if A.SelfGlow then
            if not selfHighlight or not selfHighlight.Parent then
                selfHighlight=Instance.new("Highlight")
                selfHighlight.Name="LvkHubSelfGlow"
                selfHighlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                selfHighlight.FillTransparency=.78
                selfHighlight.OutlineTransparency=.05
                selfHighlight.Parent=ch
            end
            selfHighlight.Adornee=ch
            selfHighlight.FillColor=A.SelfColor
            selfHighlight.OutlineColor=A.SelfColor
            selfHighlight.Enabled=true
        elseif selfHighlight then selfHighlight:Destroy(); selfHighlight=nil end
    end
    local function restoreSelf()
        for o,s in pairs(selfParts) do
            if o and o.Parent then pcall(function()
                o.Material=s.Material; o.Color=s.Color; o.Transparency=s.Transparency; o.LocalTransparencyModifier=s.LocalTransparencyModifier; o.CastShadow=s.CastShadow
                if o:IsA("MeshPart") and s.TextureID~=nil then o.TextureID=s.TextureID end
            end) end
        end
        for o,t in pairs(selfTextures) do if o and o.Parent then pcall(function() o.Transparency=t end) end end
        table.clear(selfParts); table.clear(selfTextures)
        if selfHighlight then selfHighlight:Destroy(); selfHighlight=nil end
    end

    local bodyNames={head=true,torso=true,uppertorso=true,lowertorso=true,humanoidrootpart=true,["left arm"]=true,["right arm"]=true,["left leg"]=true,["right leg"]=true,lefthand=true,righthand=true,leftupperarm=true,rightupperarm=true,leftlowerarm=true,rightlowerarm=true,leftupperleg=true,rightupperleg=true,leftlowerleg=true,rightlowerleg=true}
    local gunParts=setmetatable({}, {__mode="k"})
    local gunTextures=setmetatable({}, {__mode="k"})
    local gunHighlights=setmetatable({}, {__mode="k"})
    local function equippedTool()
        local ch=LP.Character; if not ch then return nil end
        for _,x in ipairs(ch:GetChildren()) do if x:IsA("Tool") then return x end end
    end
    local function weaponRoots()
        local roots={}
        local tool=equippedTool(); if tool then table.insert(roots,tool) end
        if Camera then
            local toolName=tool and tool.Name:lower() or ""
            for _,m in ipairs(Camera:GetDescendants()) do
                if m:IsA("Model") then
                    local grip=m:FindFirstChild("Grip",true)
                    local muzzle=grip and grip:FindFirstChild("Muzzle",true)
                    local n=m.Name:lower()
                    if (toolName~="" and (n==toolName or n:find(toolName,1,true))) or (grip and muzzle) then table.insert(roots,m) end
                end
            end
        end
        return roots
    end
    local function applyGun()
        if not State.Local.GunChams then return end
        local roots=weaponRoots()
        local active={}
        for _,root in ipairs(roots) do
            if A.GunGlow then
                local h=gunHighlights[root]
                if not h or not h.Parent then
                    h=Instance.new("Highlight"); h.Name="LvkHubGunGlow"; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.FillTransparency=.80; h.OutlineTransparency=.05; h.Parent=root; gunHighlights[root]=h
                end
                h.Adornee=root; h.FillColor=A.GunColor; h.OutlineColor=A.GunColor; h.Enabled=true
            elseif gunHighlights[root] then gunHighlights[root]:Destroy(); gunHighlights[root]=nil end
            for _,o in ipairs(root:GetDescendants()) do
                if o:IsA("BasePart") and not bodyNames[o.Name:lower()] then
                    active[o]=true
                    if not gunParts[o] then gunParts[o]={Material=o.Material,Color=o.Color,Transparency=o.Transparency,CastShadow=o.CastShadow,TextureID=o:IsA("MeshPart") and o.TextureID or nil} end
                    o.Material=materialMap[A.GunMaterial] or Enum.Material.ForceField
                    o.Color=A.GunColor; o.Transparency=A.GunTransparency/100; o.CastShadow=false
                    if o:IsA("MeshPart") then o.TextureID="" end
                    for _,d in ipairs(o:GetDescendants()) do
                        if d:IsA("Decal") or d:IsA("Texture") then if gunTextures[d]==nil then gunTextures[d]=d.Transparency end; d.Transparency=1 end
                    end
                end
            end
        end
        for o,s in pairs(gunParts) do
            if not active[o] then
                if o and o.Parent then pcall(function() o.Material=s.Material; o.Color=s.Color; o.Transparency=s.Transparency; o.CastShadow=s.CastShadow; if o:IsA("MeshPart") and s.TextureID~=nil then o.TextureID=s.TextureID end end) end
                gunParts[o]=nil
            end
        end
        for root,h in pairs(gunHighlights) do if not table.find(roots,root) then if h then h:Destroy() end; gunHighlights[root]=nil end end
    end
    local function restoreGun()
        for o,s in pairs(gunParts) do if o and o.Parent then pcall(function() o.Material=s.Material; o.Color=s.Color; o.Transparency=s.Transparency; o.CastShadow=s.CastShadow; if o:IsA("MeshPart") and s.TextureID~=nil then o.TextureID=s.TextureID end end) end end
        for o,t in pairs(gunTextures) do if o and o.Parent then pcall(function() o.Transparency=t end) end end
        for _,h in pairs(gunHighlights) do if h then pcall(function() h:Destroy() end) end end
        table.clear(gunParts); table.clear(gunTextures); table.clear(gunHighlights)
    end

    local trail,a0,a1=nil,nil,nil
    local function clearTrail()
        if trail then trail:Destroy() end; if a0 then a0:Destroy() end; if a1 then a1:Destroy() end
        trail=nil; a0=nil; a1=nil
    end
    local function applyTrail()
        if not State.Local.Trail then clearTrail(); return end
        local ch=LP.Character
        local root=ch and ch:FindFirstChild("HumanoidRootPart")
        if not root or not Camera then return end
        if not trail then
            a0=Instance.new("Attachment"); a1=Instance.new("Attachment")
            trail=Instance.new("Trail"); trail.Name="LvkHubTrail"; trail.Attachment0=a0; trail.Attachment1=a1; trail.FaceCamera=true; trail.Enabled=true
        end
        local thick=A.TrailThickness/100
        a0.Position=Vector3.new(0,thick-2.7,0); a1.Position=Vector3.new(0,-thick-2.7,0)
        trail.Lifetime=A.TrailLifetime/10
        trail.Color=ColorSequence.new(A.TrailColor,A.TrailColor)
        a0.Parent=root; a1.Parent=root; trail.Parent=Camera
    end

    local selfWas,gunWas,trailWas=false,false,false
    local st,gt,tt=0,0,0
    RunService.RenderStepped:Connect(function(dt)
        if State.Local.SelfChams~=selfWas then if State.Local.SelfChams then applySelf() else restoreSelf() end; selfWas=State.Local.SelfChams end
        st+=dt; if State.Local.SelfChams and st>=.06 then st=0; applySelf() end

        if State.Local.GunChams~=gunWas then if State.Local.GunChams then applyGun() else restoreGun() end; gunWas=State.Local.GunChams end
        gt+=dt; if State.Local.GunChams and gt>=.06 then gt=0; applyGun() end

        if State.Local.Trail~=trailWas then if State.Local.Trail then applyTrail() else clearTrail() end; trailWas=State.Local.Trail end
        tt+=dt; if State.Local.Trail and tt>=.20 then tt=0; applyTrail() end
    end)

    LP.CharacterAdded:Connect(function()
        restoreSelf(); restoreGun(); clearTrail()
        task.wait(.35)
        if State.Local.SelfChams then applySelf() end
        if State.Local.GunChams then applyGun() end
        if State.Local.Trail then applyTrail() end
    end)
end
