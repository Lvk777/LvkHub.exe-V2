-- Persistent World controls.
-- Lighting is enforced late in the render step without PropertyChanged feedback loops.
-- Vegetation detaches Workspace.Map.Vegetation children locally while enabled.

return function(State, Registry, UI)
    local Lighting=game:GetService("Lighting")
    local Workspace=game:GetService("Workspace")
    local RunService=game:GetService("RunService")
    local page=UI.Pages.World

    UI.Section(page,"World")
    UI.Toggle(page,"FullBrightness",function() return State.World.FullBrightness end,function(v) State.World.FullBrightness=v end)
    UI.Toggle(page,"No Fog",function() return State.World.NoFog end,function(v) State.World.NoFog=v end)
    UI.Toggle(page,"Vegetation",function() return State.World.Vegetation end,function(v) State.World.Vegetation=v end)
    UI.Toggle(page,"No Shadows",function() return State.World.NoShadows end,function(v) State.World.NoShadows=v end)
    UI.Toggle(page,"FPS Boost",function() return State.World.FPSBoost end,function(v) State.World.FPSBoost=v end)

    local skyOrder={"Default","Bright Day","Night"}
    UI.Button(page,"ChangeSkyDome","CYCLE",function(button)
        local i=table.find(skyOrder,State.World.Sky) or 1
        State.World.Sky=skyOrder[i%#skyOrder+1]
        button.Text=string.upper(State.World.Sky)
    end)

    local original={
        Brightness=Lighting.Brightness,
        ClockTime=Lighting.ClockTime,
        Ambient=Lighting.Ambient,
        OutdoorAmbient=Lighting.OutdoorAmbient,
        GlobalShadows=Lighting.GlobalShadows,
        FogStart=Lighting.FogStart,
        FogEnd=Lighting.FogEnd,
        FogColor=Lighting.FogColor,
    }
    local atmosphereOriginal=setmetatable({}, {__mode="k"})
    local controlledLast=false

    local function setIfDifferent(obj,prop,value)
        local ok,current=pcall(function() return obj[prop] end)
        if ok and current~=value then pcall(function() obj[prop]=value end) end
    end

    local function rememberAtmosphere(a)
        if atmosphereOriginal[a] then return end
        atmosphereOriginal[a]={Density=a.Density,Haze=a.Haze,Glare=a.Glare}
    end

    local function restoreLightingOnce()
        setIfDifferent(Lighting,"Brightness",original.Brightness)
        setIfDifferent(Lighting,"ClockTime",original.ClockTime)
        setIfDifferent(Lighting,"Ambient",original.Ambient)
        setIfDifferent(Lighting,"OutdoorAmbient",original.OutdoorAmbient)
        setIfDifferent(Lighting,"GlobalShadows",original.GlobalShadows)
        setIfDifferent(Lighting,"FogStart",original.FogStart)
        setIfDifferent(Lighting,"FogEnd",original.FogEnd)
        setIfDifferent(Lighting,"FogColor",original.FogColor)
        for a,v in pairs(atmosphereOriginal) do
            if a and a.Parent then
                setIfDifferent(a,"Density",v.Density)
                setIfDifferent(a,"Haze",v.Haze)
                setIfDifferent(a,"Glare",v.Glare)
            end
        end
    end

    local function enforceLighting()
        local controlled=State.World.FullBrightness or State.World.NoFog or State.World.NoShadows or State.World.Sky~="Default"
        if not controlled then
            if controlledLast then restoreLightingOnce() end
            controlledLast=false
            return
        end
        controlledLast=true

        if State.World.FullBrightness then
            setIfDifferent(Lighting,"Brightness",3)
            setIfDifferent(Lighting,"Ambient",Color3.fromRGB(190,190,190))
            setIfDifferent(Lighting,"OutdoorAmbient",Color3.fromRGB(190,190,190))
        end

        if State.World.Sky=="Bright Day" then
            setIfDifferent(Lighting,"ClockTime",13)
        elseif State.World.Sky=="Night" then
            setIfDifferent(Lighting,"ClockTime",0)
        elseif State.World.FullBrightness then
            setIfDifferent(Lighting,"ClockTime",14)
        end

        if State.World.NoFog then
            setIfDifferent(Lighting,"FogStart",1e7)
            setIfDifferent(Lighting,"FogEnd",1e7+1000)
            for _,x in ipairs(Lighting:GetChildren()) do
                if x:IsA("Atmosphere") then
                    rememberAtmosphere(x)
                    setIfDifferent(x,"Density",0)
                    setIfDifferent(x,"Haze",0)
                    setIfDifferent(x,"Glare",0)
                end
            end
        end

        if State.World.NoShadows then setIfDifferent(Lighting,"GlobalShadows",false) end
    end

    -- Late render enforcement avoids the previous PropertyChanged -> write ->
    -- PropertyChanged feedback loop that could freeze/crash the client.
    pcall(function() RunService:UnbindFromRenderStep("LvkHubWorldLighting") end)
    RunService:BindToRenderStep("LvkHubWorldLighting",Enum.RenderPriority.Last.Value+900,function()
        enforceLighting()
    end)

    -- Workspace > Map > Vegetation > Bushes / Trees.
    local vegetationFolder=nil
    local vegetationStash=setmetatable({}, {__mode="k"})
    local vegetationConn=nil

    local function resolveVegetation()
        local map=Workspace:FindFirstChild("Map")
        return map and map:FindFirstChild("Vegetation") or nil
    end

    local function detachVegetationChild(child)
        if not State.World.Vegetation or not child or child.Parent~=vegetationFolder then return end
        if vegetationStash[child]==nil then vegetationStash[child]=vegetationFolder end
        child.Parent=nil
    end

    local function attachVegetationFolder(folder)
        if vegetationFolder==folder then return end
        if vegetationConn then vegetationConn:Disconnect(); vegetationConn=nil end
        vegetationFolder=folder
        if vegetationFolder then
            vegetationConn=vegetationFolder.ChildAdded:Connect(function(child)
                if State.World.Vegetation then task.defer(detachVegetationChild,child) end
            end)
        end
    end

    local function applyVegetation()
        local current=resolveVegetation()
        if current~=vegetationFolder then attachVegetationFolder(current) end
        if State.World.Vegetation then
            if vegetationFolder then
                local children=vegetationFolder:GetChildren()
                for i,child in ipairs(children) do
                    detachVegetationChild(child)
                    if i%40==0 then task.wait() end
                end
            end
        else
            local target=resolveVegetation()
            if target then
                for child in pairs(vegetationStash) do
                    if child and child.Parent==nil then pcall(function() child.Parent=target end) end
                    vegetationStash[child]=nil
                end
            end
        end
    end

    Workspace.DescendantAdded:Connect(function(obj)
        if obj.Name=="Vegetation" and obj.Parent and obj.Parent.Name=="Map" then
            task.defer(function()
                attachVegetationFolder(obj)
                if State.World.Vegetation then applyVegetation() end
            end)
        end
    end)

    local effectOriginal=setmetatable({}, {__mode="k"})
    local function isHubEffect(x)
        local n=string.lower(x.Name or "")
        return n:find("lvkhub",1,true)~=nil or n:find("yokaitrail",1,true)~=nil
    end
    local function applyFPS(enabled)
        for _,x in ipairs(Workspace:GetDescendants()) do
            if (x:IsA("ParticleEmitter") or x:IsA("Trail") or x:IsA("Beam") or x:IsA("Smoke") or x:IsA("Fire") or x:IsA("Sparkles")) and not isHubEffect(x) then
                if effectOriginal[x]==nil then effectOriginal[x]={Enabled=x.Enabled} end
                if enabled then x.Enabled=false else local o=effectOriginal[x]; if o then x.Enabled=o.Enabled end end
            end
        end
        for _,x in ipairs(Lighting:GetChildren()) do
            if (x:IsA("BloomEffect") or x:IsA("SunRaysEffect") or x:IsA("DepthOfFieldEffect")) and not isHubEffect(x) then
                if effectOriginal[x]==nil then effectOriginal[x]={Enabled=x.Enabled} end
                if enabled then x.Enabled=false else local o=effectOriginal[x]; if o then x.Enabled=o.Enabled end end
            end
        end
        if not enabled then table.clear(effectOriginal) end
    end

    attachVegetationFolder(resolveVegetation())
    task.spawn(function()
        local vegetationWas=false
        local fpsWas=false
        while UI.Gui.Parent do
            task.wait(.50)
            if State.World.Vegetation~=vegetationWas then
                applyVegetation()
                vegetationWas=State.World.Vegetation
            elseif State.World.Vegetation then
                local current=resolveVegetation()
                if current~=vegetationFolder then attachVegetationFolder(current) end
                if vegetationFolder and #vegetationFolder:GetChildren()>0 then applyVegetation() end
            end
            if State.World.FPSBoost~=fpsWas then
                applyFPS(State.World.FPSBoost)
                fpsWas=State.World.FPSBoost
            end
        end
    end)
end
