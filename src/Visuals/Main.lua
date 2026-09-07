-- LvkHub.exe Visuals
-- Faithful port of the old Yokai visual renderer used in AttachedVisualsPreview/VisualsV2.
-- Intentional changes only:
--   1) target source is Registry.Bots instead of Roblox Player objects;
--   2) every artificial min/max ESP distance gate was removed;
--   3) Skeleton keeps the old style with an R6 fallback;
--   4) Car ESP keeps the old Yokai style but has no distance filter.

return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local UserInputService=game:GetService("UserInputService")
    local page=UI.Pages.Visuals
    local parent=UI.Gui.Parent
    local BLUE=Color3.fromRGB(119,120,255)

    -- ---------------------------------------------------------------------
    -- Options: same requested Yokai set, with no distance controls.
    -- ---------------------------------------------------------------------
    UI.Section(page,"Visuals")
    UI.Toggle(page,"3D Box",function() return State.Visuals.Box3D end,function(v) State.Visuals.Box3D=v end)
    UI.Toggle(page,"Chams",function() return State.Visuals.Chams end,function(v) State.Visuals.Chams=v end)
    UI.Toggle(page,"Corner Box",function() return State.Visuals.CornerBox end,function(v) State.Visuals.CornerBox=v end)
    UI.Toggle(page,"ESP",function() return State.Visuals.ESP end,function(v) State.Visuals.ESP=v end)

    local fovEnabled=false
    local originalFov=setmetatable({}, {__mode="k"})
    local function applyFov()
        local cam=Workspace.CurrentCamera
        if not cam then return end
        if originalFov[cam]==nil then originalFov[cam]=cam.FieldOfView end
        cam.FieldOfView=fovEnabled and math.clamp(State.Visuals.FOV or 70,40,120) or (originalFov[cam] or 70)
    end
    UI.Toggle(page,"FOVChanger",function() return fovEnabled end,function(v) fovEnabled=v; applyFov() end)
    UI.Number(page,"FOV",function() return State.Visuals.FOV or 70 end,function(v) State.Visuals.FOV=v; if fovEnabled then applyFov() end end,40,120)
    Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() task.wait(); applyFov() end)

    UI.Toggle(page,"HealthBar",function() return State.Visuals.HealthBar end,function(v) State.Visuals.HealthBar=v end)
    UI.Toggle(page,"Name + Distance",function() return State.Visuals.NameDistance end,function(v) State.Visuals.NameDistance=v end)
    UI.Toggle(page,"Preview",function() return State.Visuals.Preview end,function(v) State.Visuals.Preview=v end)
    UI.Toggle(page,"Thermal Corner",function() return State.Visuals.ThermalCorner end,function(v) State.Visuals.ThermalCorner=v end)
    UI.Toggle(page,"Tracers",function() return State.Visuals.Tracers end,function(v) State.Visuals.Tracers=v end)
    UI.Toggle(page,"Skeleton",function() return State.Visuals.Skeleton end,function(v) State.Visuals.Skeleton=v end)
    UI.Toggle(page,"Car ESP",function() return State.Visuals.CarESP end,function(v) State.Visuals.CarESP=v end)

    -- ---------------------------------------------------------------------
    -- Old Yokai overlay primitives.
    -- ---------------------------------------------------------------------
    local oldOverlay=parent:FindFirstChild("LvkHubVisuals")
    if oldOverlay then oldOverlay:Destroy() end
    local overlay=Instance.new("ScreenGui")
    overlay.Name="LvkHubVisuals"
    overlay.ResetOnSpawn=false
    overlay.IgnoreGuiInset=true
    overlay.DisplayOrder=998
    overlay.Parent=parent

    local function createLine(color)
        local f=Instance.new("Frame")
        f.BorderSizePixel=0
        f.AnchorPoint=Vector2.new(.5,.5)
        f.BackgroundColor3=color or Color3.new(1,1,1)
        f.Visible=false
        f.Parent=overlay
        return f
    end
    local function setLine(f,a,b,thickness,color)
        if not f or not a or not b then if f then f.Visible=false end return end
        local d=b-a
        if d.Magnitude<.01 then f.Visible=false return end
        f.Size=UDim2.fromOffset(d.Magnitude,thickness or 1)
        f.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
        f.Rotation=math.deg(math.atan2(d.Y,d.X))
        if color then f.BackgroundColor3=color end
        f.Visible=true
    end
    local function hideList(list)
        if list then for _,x in ipairs(list) do if x then x.Visible=false end end end
    end
    local function newCornerSet()
        local t={}
        for i=1,8 do t[i]=createLine(Color3.new(1,1,1)) end
        return t
    end
    local function newSkeletonSet()
        local t={}
        for i=1,15 do t[i]=createLine(Color3.new(1,1,1)) end
        return t
    end
    local function newBox3DSet()
        local t={}
        for i=1,12 do t[i]=createLine(Color3.new(1,1,1)) end
        return t
    end
    local function newLabel()
        local l=Instance.new("TextLabel")
        l.BackgroundTransparency=1
        l.AnchorPoint=Vector2.new(.5,.5)
        l.Size=UDim2.fromOffset(190,20)
        l.Font=Enum.Font.Code
        l.TextSize=11
        l.TextStrokeTransparency=0
        l.TextStrokeColor3=Color3.fromRGB(0,0,0)
        l.TextColor3=Color3.new(1,1,1)
        l.RichText=true
        l.Visible=false
        l.Parent=overlay
        return l
    end

    -- Same sizing formula used by the old AttachedVisualsPreview renderer.
    local function screenData(root)
        local cam=Workspace.CurrentCamera
        if not cam or not root then return nil end
        local p,on=cam:WorldToViewportPoint(root.Position)
        if not on or p.Z<=0 then return nil end
        local scale=(root.Size.Y*cam.ViewportSize.Y)/(p.Z*2)
        return Vector2.new(p.X,p.Y),3*scale,4.5*scale,(cam.CFrame.Position-root.Position).Magnitude/3.5714285714
    end

    local stores=setmetatable({}, {__mode="k"})
    local function newStore(model)
        local s={Model=model}
        s.Chams=Instance.new("Highlight")
        s.Chams.Name="AttachedChams"
        s.Chams.FillTransparency=1
        s.Chams.OutlineTransparency=0
        s.Chams.OutlineColor=BLUE
        s.Chams.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        s.Chams.Adornee=model
        s.Chams.Enabled=false
        s.Chams.Parent=model

        s.CornerFill=Instance.new("Frame")
        s.CornerFill.BorderSizePixel=0
        s.CornerFill.BackgroundColor3=Color3.fromRGB(0,0,0)
        s.CornerFill.BackgroundTransparency=.75
        s.CornerFill.Visible=false
        s.CornerFill.Parent=overlay
        s.Corner=newCornerSet()

        s.ThermalFill=Instance.new("Frame")
        s.ThermalFill.BorderSizePixel=0
        s.ThermalFill.BackgroundColor3=BLUE
        s.ThermalFill.BackgroundTransparency=.75
        s.ThermalFill.Visible=false
        s.ThermalFill.Parent=overlay
        s.ThermalCorner=newCornerSet()

        s.HealthBack=Instance.new("Frame")
        s.HealthBack.BorderSizePixel=0
        s.HealthBack.BackgroundColor3=Color3.fromRGB(0,0,0)
        s.HealthBack.Visible=false
        s.HealthBack.Parent=overlay
        s.Health=Instance.new("Frame")
        s.Health.BorderSizePixel=0
        s.Health.BackgroundColor3=Color3.fromRGB(255,255,255)
        s.Health.Visible=false
        s.Health.Parent=overlay
        local grad=Instance.new("UIGradient")
        grad.Rotation=-90
        grad.Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(200,0,0)),
            ColorSequenceKeypoint.new(.5,Color3.fromRGB(60,60,125)),
            ColorSequenceKeypoint.new(1,BLUE),
        })
        grad.Parent=s.Health
        s.HealthText=newLabel()
        s.Name=newLabel()
        s.Distance=newLabel()
        s.Skeleton=newSkeletonSet()
        s.Tracer=createLine(Color3.fromRGB(255,255,255))
        s.Box3D=newBox3DSet()

        -- Old ESP Pack objects.
        s.PackChams=s.Chams:Clone()
        s.PackChams.Name="AttachedESPPackChams"
        s.PackChams.Adornee=model
        s.PackChams.Parent=model
        s.PackBox=Instance.new("Frame")
        s.PackBox.BorderSizePixel=1
        s.PackBox.BorderColor3=Color3.fromRGB(255,255,255)
        s.PackBox.BackgroundColor3=Color3.fromRGB(255,255,255)
        s.PackBox.BackgroundTransparency=.75
        s.PackBox.Visible=false
        s.PackBox.Parent=overlay
        local pg=Instance.new("UIGradient")
        pg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,BLUE),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,0))})
        pg.Parent=s.PackBox
        s.PackCorners=newCornerSet()
        s.PackHealthBack=s.HealthBack:Clone(); s.PackHealthBack.Parent=overlay
        s.PackHealth=s.Health:Clone(); s.PackHealth.Parent=overlay
        s.PackHealthText=s.HealthText:Clone(); s.PackHealthText.Parent=overlay
        s.PackName=s.Name:Clone(); s.PackName.Parent=overlay
        s.PackDistance=s.Distance:Clone(); s.PackDistance.Parent=overlay
        s.PackWeapon=s.HealthText:Clone(); s.PackWeapon.TextColor3=BLUE; s.PackWeapon.Parent=overlay

        stores[model]=s
        return s
    end
    local function hideStore(s)
        if not s then return end
        s.Chams.Enabled=false; s.PackChams.Enabled=false
        s.CornerFill.Visible=false; s.ThermalFill.Visible=false
        s.Health.Visible=false; s.HealthBack.Visible=false; s.HealthText.Visible=false
        s.Name.Visible=false; s.Distance.Visible=false; s.Tracer.Visible=false
        s.PackBox.Visible=false; s.PackHealth.Visible=false; s.PackHealthBack.Visible=false
        s.PackHealthText.Visible=false; s.PackName.Visible=false; s.PackDistance.Visible=false; s.PackWeapon.Visible=false
        hideList(s.Corner); hideList(s.ThermalCorner); hideList(s.Skeleton); hideList(s.Box3D); hideList(s.PackCorners)
    end
    local function destroyStore(model)
        local s=stores[model]
        if not s then return end
        for _,v in pairs(s) do
            if typeof(v)=="Instance" then pcall(function() v:Destroy() end)
            elseif type(v)=="table" then for _,x in pairs(v) do if typeof(x)=="Instance" then pcall(function() x:Destroy() end) end end end
        end
        stores[model]=nil
    end

    local function updateCorners(lines,pos,w,h,color)
        local l,r,t,b=pos.X-w/2,pos.X+w/2,pos.Y-h/2,pos.Y+h/2
        local cw,ch=w/5,h/5
        local p={
            {Vector2.new(l,t),Vector2.new(l+cw,t)},{Vector2.new(l,t),Vector2.new(l,t+ch)},
            {Vector2.new(r,t),Vector2.new(r-cw,t)},{Vector2.new(r,t),Vector2.new(r,t+ch)},
            {Vector2.new(l,b),Vector2.new(l+cw,b)},{Vector2.new(l,b),Vector2.new(l,b-ch)},
            {Vector2.new(r,b),Vector2.new(r-cw,b)},{Vector2.new(r,b),Vector2.new(r,b-ch)},
        }
        for i,v in ipairs(p) do setLine(lines[i],v[1],v[2],1,color) end
    end

    local bonesR15={
        {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
        {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
        {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
        {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
        {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    }
    local bonesR6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
    local function updateSkeleton(lines,model,color)
        local cam=Workspace.CurrentCamera
        if not cam then hideList(lines) return end
        hideList(lines)
        local bones=model:FindFirstChild("UpperTorso") and bonesR15 or bonesR6
        for i,b in ipairs(bones) do
            local p1,p2=model:FindFirstChild(b[1]),model:FindFirstChild(b[2])
            local line=lines[i]
            if p1 and p2 and line then
                local a,va=cam:WorldToViewportPoint(p1.Position)
                local c,vc=cam:WorldToViewportPoint(p2.Position)
                if va and vc and a.Z>0 and c.Z>0 then
                    setLine(line,Vector2.new(a.X,a.Y),Vector2.new(c.X,c.Y),1,color)
                end
            end
        end
    end

    local function update3D(lines,root,color)
        local cam=Workspace.CurrentCamera
        if not cam or not root then hideList(lines) return end
        local cf=root.CFrame*CFrame.new(0,-.5,0)
        local sz=Vector3.new(3,5,3)/2
        local corners={}
        for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do table.insert(corners,(cf*CFrame.new(sz*Vector3.new(x,y,z))).Position) end end end
        local screen={}; local all=true
        for i,p in ipairs(corners) do
            local s,v=cam:WorldToViewportPoint(p)
            screen[i]=Vector2.new(s.X,s.Y)
            if not v or s.Z<=0 then all=false end
        end
        local edges={{1,2},{2,4},{4,3},{3,1},{5,6},{6,8},{8,7},{7,5},{1,5},{2,6},{3,7},{4,8}}
        if not all then hideList(lines) return end
        for i,e in ipairs(edges) do setLine(lines[i],screen[e[1]],screen[e[2]],1,color) end
    end

    local function updateHealth(bar,back,text,hum,pos,w,h,width,textColor,showText)
        local ratio=math.clamp(hum.Health/math.max(1,hum.MaxHealth),0,1)
        back.Position=UDim2.fromOffset(pos.X-w/2-6,pos.Y-h/2)
        back.Size=UDim2.fromOffset(width,h); back.Visible=true
        bar.Position=UDim2.fromOffset(pos.X-w/2-6,pos.Y-h/2+h*(1-ratio))
        bar.Size=UDim2.fromOffset(width,h*ratio); bar.Visible=true
        text.Position=UDim2.fromOffset(pos.X-w/2-15,pos.Y-h/2+h*(1-ratio))
        text.Text=tostring(math.floor(ratio*100)); text.TextColor3=textColor
        text.Visible=showText and hum.Health<hum.MaxHealth
    end

    -- ---------------------------------------------------------------------
    -- Preview: port of the old VisualsPreviewControlsFix window.
    -- ---------------------------------------------------------------------
    local previewGui=Instance.new("ScreenGui")
    previewGui.Name="LvkHubVisualPreview"
    previewGui.ResetOnSpawn=false
    previewGui.IgnoreGuiInset=true
    previewGui.DisplayOrder=997
    previewGui.Enabled=false
    previewGui.Parent=parent

    local previewFrame=Instance.new("Frame")
    previewFrame.Name="Window"
    previewFrame.Size=UDim2.fromOffset(280,360)
    previewFrame.Position=UDim2.new(1,-300,0,72)
    previewFrame.BackgroundColor3=Color3.fromRGB(15,15,18)
    previewFrame.BorderSizePixel=0
    previewFrame.Parent=previewGui
    local pfc=Instance.new("UICorner"); pfc.CornerRadius=UDim.new(0,9); pfc.Parent=previewFrame
    local pfs=Instance.new("UIStroke"); pfs.Color=Color3.fromRGB(62,64,72); pfs.Transparency=.25; pfs.Parent=previewFrame
    local ptitle=Instance.new("TextLabel")
    ptitle.BackgroundTransparency=1; ptitle.Position=UDim2.fromOffset(14,8); ptitle.Size=UDim2.new(1,-28,0,25)
    ptitle.Font=Enum.Font.Code; ptitle.TextSize=13; ptitle.TextColor3=Color3.fromRGB(235,235,240); ptitle.TextXAlignment=Enum.TextXAlignment.Left; ptitle.Text="Visuals Preview"; ptitle.Parent=previewFrame
    local pcanvas=Instance.new("Frame")
    pcanvas.Position=UDim2.fromOffset(12,38); pcanvas.Size=UDim2.new(1,-24,1,-50); pcanvas.BackgroundColor3=Color3.fromRGB(20,20,24); pcanvas.BorderSizePixel=0; pcanvas.ClipsDescendants=true; pcanvas.Parent=previewFrame
    local pcc=Instance.new("UICorner"); pcc.CornerRadius=UDim.new(0,6); pcc.Parent=pcanvas
    local pdummy=Instance.new("Frame")
    pdummy.AnchorPoint=Vector2.new(.5,.5); pdummy.Position=UDim2.new(.5,0,.53,0); pdummy.Size=UDim2.fromOffset(66,174); pdummy.BackgroundColor3=BLUE; pdummy.BackgroundTransparency=.16; pdummy.BorderSizePixel=0; pdummy.Parent=pcanvas
    local pdc=Instance.new("UICorner"); pdc.CornerRadius=UDim.new(0,5); pdc.Parent=pdummy
    local pout=Instance.new("UIStroke"); pout.Thickness=2; pout.Color=BLUE; pout.Parent=pdummy
    local phead=Instance.new("Frame")
    phead.AnchorPoint=Vector2.new(.5,.5); phead.Position=UDim2.new(.5,0,0,-25); phead.Size=UDim2.fromOffset(36,36); phead.BackgroundColor3=BLUE; phead.BackgroundTransparency=.16; phead.BorderSizePixel=0; phead.Parent=pdummy
    local phc=Instance.new("UICorner"); phc.CornerRadius=UDim.new(0,5); phc.Parent=phead
    local pho=Instance.new("UIStroke"); pho.Thickness=2; pho.Color=BLUE; pho.Parent=phead
    local ptracer=Instance.new("Frame")
    ptracer.AnchorPoint=Vector2.new(.5,.5); ptracer.BorderSizePixel=0; ptracer.BackgroundColor3=Color3.new(1,1,1); ptracer.Visible=false; ptracer.Parent=pcanvas
    local pdrag=false; local dragStart; local frameStart
    ptitle.Active=true
    ptitle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then pdrag=true; dragStart=input.Position; frameStart=previewFrame.Position end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if pdrag and input.UserInputType==Enum.UserInputType.MouseMovement then
            local d=input.Position-dragStart
            previewFrame.Position=UDim2.new(frameStart.X.Scale,frameStart.X.Offset+d.X,frameStart.Y.Scale,frameStart.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then pdrag=false end end)

    -- ---------------------------------------------------------------------
    -- Old Yokai Car ESP style, event-driven and with NO distance gate.
    -- ---------------------------------------------------------------------
    local carColor=Color3.fromRGB(60,220,180)
    local cars=setmetatable({}, {__mode="k"})
    local function vehicleAnchor(m)
        return m:FindFirstChildWhichIsA("VehicleSeat",true)
            or m:FindFirstChild("Seat1",true)
            or m.PrimaryPart
            or m:FindFirstChildWhichIsA("BasePart",true)
    end
    local function addCar(m)
        if cars[m] or not m or not m:IsA("Model") then return end
        local a=vehicleAnchor(m); if not a then return end
        local h=Instance.new("Highlight")
        h.Name="YokaiPreservedCarESP"; h.Adornee=m; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.FillTransparency=.86; h.OutlineTransparency=.08; h.Enabled=false; h.Parent=m
        local bb=Instance.new("BillboardGui")
        bb.Name="YokaiPreservedCarLabel"; bb.Adornee=a; bb.AlwaysOnTop=true; bb.MaxDistance=0; bb.Size=UDim2.fromOffset(180,28); bb.StudsOffsetWorldSpace=Vector3.new(0,3,0); bb.Enabled=false; bb.Parent=a
        local t=Instance.new("TextLabel")
        t.BackgroundTransparency=1; t.Size=UDim2.fromScale(1,1); t.Font=Enum.Font.GothamSemibold; t.TextSize=12; t.TextStrokeTransparency=.45; t.Parent=bb
        cars[m]={h=h,bb=bb,t=t,a=a}
    end

    local activeLast=false
    RunService.RenderStepped:Connect(function()
        applyFov()
        previewGui.Enabled=State.Visuals.Preview==true
        if State.Visuals.Preview then
            local on=State.Visuals.ESP or State.Visuals.Chams or State.Visuals.CornerBox or State.Visuals.ThermalCorner
            pdummy.BackgroundTransparency=on and .18 or .58; phead.BackgroundTransparency=pdummy.BackgroundTransparency
            pout.Transparency=on and 0 or .45; pho.Transparency=pout.Transparency
            ptracer.Visible=State.Visuals.Tracers==true
            if ptracer.Visible then
                local sz=pcanvas.AbsoluteSize
                setLine(ptracer,Vector2.new(sz.X/2,sz.Y),Vector2.new(sz.X/2,sz.Y*.53),1,Color3.new(1,1,1))
            end
        end

        local cam=Workspace.CurrentCamera
        if not cam then return end
        local any=State.Visuals.Chams or State.Visuals.CornerBox or State.Visuals.ThermalCorner or State.Visuals.HealthBar or State.Visuals.NameDistance or State.Visuals.Skeleton or State.Visuals.Tracers or State.Visuals.Box3D or State.Visuals.ESP
        if not any then
            if activeLast then for _,s in pairs(stores) do hideStore(s) end end
            activeLast=false
        else
            activeLast=true
            for model in pairs(stores) do if not Registry.Bots[model] or not Registry.IsBot(model) then destroyStore(model) end end
            for model in pairs(Registry.Bots) do
                if Registry.IsBot(model) then
                    local s=stores[model] or newStore(model)
                    local hum=Registry.HumanoidOf(model)
                    local root=Registry.RootOf(model)
                    local pos,w,h,dist
                    if root then pos,w,h,dist=screenData(root) end

                    -- Chams has no range check and remains active even if the bot is off-screen.
                    if State.Visuals.Chams then
                        s.Chams.Adornee=model; s.Chams.Enabled=true; s.Chams.FillColor=BLUE; s.Chams.OutlineColor=BLUE
                        local pulse=math.clamp(math.atan(math.sin(os.clock()*2))*2/math.pi,0,1)
                        s.Chams.FillTransparency=pulse; s.Chams.OutlineTransparency=pulse
                    else s.Chams.Enabled=false end

                    if not pos then
                        s.CornerFill.Visible=false; s.ThermalFill.Visible=false; s.Health.Visible=false; s.HealthBack.Visible=false; s.HealthText.Visible=false
                        s.Name.Visible=false; s.Distance.Visible=false; s.Tracer.Visible=false; hideList(s.Corner); hideList(s.ThermalCorner); hideList(s.Skeleton); hideList(s.Box3D)
                        s.PackBox.Visible=false; s.PackHealth.Visible=false; s.PackHealthBack.Visible=false; s.PackHealthText.Visible=false; s.PackName.Visible=false; s.PackDistance.Visible=false; s.PackWeapon.Visible=false; hideList(s.PackCorners)
                        s.PackChams.Enabled=State.Visuals.ESP
                        if State.Visuals.ESP then s.PackChams.Adornee=model; s.PackChams.FillColor=BLUE; s.PackChams.OutlineColor=BLUE; s.PackChams.FillTransparency=.82; s.PackChams.OutlineTransparency=.08 end
                    else
                        if State.Visuals.CornerBox then
                            s.CornerFill.Position=UDim2.fromOffset(pos.X-w/2,pos.Y-h/2); s.CornerFill.Size=UDim2.fromOffset(w,h); s.CornerFill.Visible=true
                            updateCorners(s.Corner,pos,w,h,Color3.new(1,1,1))
                        else s.CornerFill.Visible=false; hideList(s.Corner) end

                        if State.Visuals.ThermalCorner then
                            s.ThermalFill.Position=UDim2.fromOffset(pos.X-w/2,pos.Y-h/2); s.ThermalFill.Size=UDim2.fromOffset(w,h); s.ThermalFill.BackgroundColor3=BLUE; s.ThermalFill.Visible=true
                            updateCorners(s.ThermalCorner,pos,w,h,Color3.new(1,1,1))
                        else s.ThermalFill.Visible=false; hideList(s.ThermalCorner) end

                        if State.Visuals.HealthBar and hum then updateHealth(s.Health,s.HealthBack,s.HealthText,hum,pos,w,h,2.5,BLUE,true)
                        else s.Health.Visible=false; s.HealthBack.Visible=false; s.HealthText.Visible=false end

                        if State.Visuals.NameDistance then
                            s.Name.Position=UDim2.fromOffset(pos.X,pos.Y-h/2-15); s.Name.Text=model.Name; s.Name.TextColor3=Color3.new(1,1,1); s.Name.Visible=true
                            s.Distance.Position=UDim2.fromOffset(pos.X,pos.Y+h/2+7); s.Distance.Text=string.format("%d meters",math.floor(dist)); s.Distance.TextColor3=Color3.new(1,1,1); s.Distance.Visible=true
                        else s.Name.Visible=false; s.Distance.Visible=false end

                        if State.Visuals.Skeleton then updateSkeleton(s.Skeleton,model,Color3.new(1,1,1)) else hideList(s.Skeleton) end
                        if State.Visuals.Tracers then setLine(s.Tracer,Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y),pos,1,Color3.new(1,1,1)) else s.Tracer.Visible=false end
                        if State.Visuals.Box3D then update3D(s.Box3D,root,Color3.new(1,1,1)) else hideList(s.Box3D) end

                        -- ESP = the old all-in-one pack. No distance check.
                        if State.Visuals.ESP then
                            s.PackChams.Adornee=model; s.PackChams.Enabled=true; s.PackChams.FillColor=BLUE; s.PackChams.OutlineColor=BLUE; s.PackChams.FillTransparency=.84; s.PackChams.OutlineTransparency=.08
                            s.PackBox.Position=UDim2.fromOffset(pos.X-w/2,pos.Y-h/2); s.PackBox.Size=UDim2.fromOffset(w,h); s.PackBox.Visible=true
                            updateCorners(s.PackCorners,pos,w,h,BLUE)
                            if hum then updateHealth(s.PackHealth,s.PackHealthBack,s.PackHealthText,hum,pos,w,h,2.5,BLUE,true) end
                            s.PackName.Position=UDim2.fromOffset(pos.X,pos.Y-h/2-15); s.PackName.Text=model.Name; s.PackName.TextColor3=Color3.new(1,1,1); s.PackName.Visible=true
                            s.PackDistance.Position=UDim2.fromOffset(pos.X,pos.Y+h/2+7); s.PackDistance.Text=string.format("%d meters",math.floor(dist)); s.PackDistance.TextColor3=Color3.new(1,1,1); s.PackDistance.Visible=true
                        else
                            s.PackChams.Enabled=false; s.PackBox.Visible=false; hideList(s.PackCorners); s.PackHealth.Visible=false; s.PackHealthBack.Visible=false; s.PackHealthText.Visible=false; s.PackName.Visible=false; s.PackDistance.Visible=false; s.PackWeapon.Visible=false
                        end
                    end
                end
            end
        end

        -- Car ESP: every registered/replicated vehicle is shown when enabled, regardless of range.
        for model in pairs(cars) do
            if not Registry.Vehicles[model] or not model.Parent then
                local s=cars[model]; if s.h then s.h:Destroy() end; if s.bb then s.bb:Destroy() end; cars[model]=nil
            end
        end
        for model in pairs(Registry.Vehicles) do
            if model and model.Parent then
                addCar(model)
                local s=cars[model]
                if s then
                    local show=State.Visuals.CarESP==true
                    s.h.Enabled=show; s.bb.Enabled=show
                    if show then
                        s.h.FillColor=carColor; s.h.OutlineColor=carColor; s.t.TextColor3=carColor
                        local dist=(s.a.Position-cam.CFrame.Position).Magnitude
                        s.t.Text=string.format("%s  •  %d studs",model.Name:gsub("_"," "),math.floor(dist+.5))
                    end
                end
            end
        end
    end)
end
