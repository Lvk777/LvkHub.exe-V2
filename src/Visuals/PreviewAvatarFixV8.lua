-- Reliable Visuals Preview dummy.
-- Preview-only: never inserted into Registry or used by Combat/ESP targeting.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")

    local busy=false
    local lastAttempt=0

    local function sanitize(model)
        for _,d in ipairs(model:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Tool") then
                d:Destroy()
            elseif d:IsA("BasePart") then
                d.Anchored=true
                d.CanCollide=false
                d.CanTouch=false
                d.CastShadow=false
                d.LocalTransparencyModifier=0
            end
        end
    end

    local function fallback()
        local m=Instance.new("Model")
        m.Name="LvkHubPreviewDummyV9"
        local skin=Color3.fromRGB(226,188,151)
        local shirt=Color3.fromRGB(72,88,132)
        local pants=Color3.fromRGB(31,35,43)
        local function part(name,size,pos,color)
            local p=Instance.new("Part")
            p.Name=name;p.Size=size;p.CFrame=CFrame.new(pos);p.Anchored=true;p.CanCollide=false
            p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Parent=m
            return p
        end
        part("Head",Vector3.new(1.6,1.3,1.3),Vector3.new(0,3.15,0),skin)
        part("Torso",Vector3.new(2.2,2.1,1.05),Vector3.new(0,1.45,0),shirt)
        part("Left Arm",Vector3.new(.82,2.05,.86),Vector3.new(-1.52,1.45,0),skin)
        part("Right Arm",Vector3.new(.82,2.05,.86),Vector3.new(1.52,1.45,0),skin)
        part("Left Leg",Vector3.new(.95,2.15,.98),Vector3.new(-.6,-.7,0),pants)
        part("Right Leg",Vector3.new(.95,2.15,.98),Vector3.new(.6,-.7,0),pants)
        return m
    end

    local function buildDummy()
        local ok,model=pcall(function()
            local desc=Instance.new("HumanoidDescription")
            local result=Players:CreateHumanoidModelFromDescription(desc,Enum.HumanoidRigType.R15)
            desc:Destroy()
            return result
        end)
        if not ok or not model then return fallback() end

        local skin=Color3.fromRGB(226,188,151)
        local shirt=Color3.fromRGB(72,88,132)
        local pants=Color3.fromRGB(31,35,43)
        for _,p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then
                local n=p.Name:lower()
                if n:find("head",1,true) or n:find("arm",1,true) or n:find("hand",1,true) then
                    p.Color=skin
                elseif n:find("torso",1,true) then
                    p.Color=shirt
                elseif n:find("leg",1,true) or n:find("foot",1,true) then
                    p.Color=pants
                end
                p.Material=Enum.Material.SmoothPlastic
            end
        end
        return model
    end

    local function renamePreviewText(frame)
        for _,d in ipairs(frame:GetDescendants()) do
            if d:IsA("TextLabel") then
                local txt=tostring(d.Text or "")
                if txt:lower():find("vitor250407",1,true) then
                    d.Text=txt:gsub("vitor250407","PREVIEW DUMMY")
                end
            end
        end
    end

    local function install()
        if busy then return end
        local frame=UI.Gui:FindFirstChild("LvkHubVisualsDummyPreview")
        if not frame then return end
        renamePreviewText(frame)

        local vp=frame:FindFirstChildWhichIsA("ViewportFrame",true)
        if not vp then return end
        local world=vp:FindFirstChildWhichIsA("WorldModel")
        local cam=vp.CurrentCamera or vp:FindFirstChildWhichIsA("Camera")
        if not world or not cam then return end

        local existing=world:FindFirstChild("LvkHubPreviewDummyV9")
        if existing and existing:FindFirstChildWhichIsA("BasePart",true) then
            -- DummyPreviewV6 may finish an async avatar request after this module.
            -- Remove any late model so the preview remains deterministic.
            for _,x in ipairs(world:GetChildren()) do
                if x:IsA("Model") and x~=existing then pcall(function() x:Destroy() end) end
            end
            lastAttempt=os.clock()
            return
        end

        busy=true
        task.spawn(function()
            for _,x in ipairs(world:GetChildren()) do
                if x:IsA("Model") then x:Destroy() end
            end

            local model=buildDummy()
            model.Name="LvkHubPreviewDummyV9"
            sanitize(model)
            model.Parent=world

            local ok,boxCF,size=pcall(function() return model:GetBoundingBox() end)
            if not ok then
                boxCF=CFrame.new(0,1.5,0)
                size=Vector3.new(4,6,2)
            end

            local pivot=model:GetPivot()
            model:PivotTo(CFrame.new(-boxCF.Position)*pivot)
            local ok2,centerCF,size2=pcall(function() return model:GetBoundingBox() end)
            if ok2 then boxCF,size=centerCF,size2 end

            local center=boxCF.Position
            local d=math.max(7.2,size.Y*1.25,size.X*2.15,size.Z*3)
            cam.FieldOfView=31
            cam.CFrame=CFrame.lookAt(center+Vector3.new(0,size.Y*.02,-d),center+Vector3.new(0,size.Y*.02,0))
            vp.CurrentCamera=cam
            vp.Ambient=Color3.fromRGB(225,225,232)
            vp.LightColor=Color3.fromRGB(255,255,255)
            vp.LightDirection=Vector3.new(-1,-1,-1)
            vp.Visible=true

            lastAttempt=os.clock()
            busy=false
        end)
    end

    task.delay(.25,install)
    RunService.Heartbeat:Connect(function()
        if os.clock()-lastAttempt>1.0 then
            lastAttempt=os.clock()
            install()
        end
    end)
end
