-- LvkHub.exe unified Visuals V4
-- LOCAL Workspace.TestPlayers dummies + Workspace.Vehicles only.
-- No real Player.Character is used as a target by this renderer.

return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local Players=game:GetService("Players")
    local UIS=game:GetService("UserInputService")

    local LP=Players.LocalPlayer
    local page=UI.Pages.Visuals
    local win=UI.Windows.Visuals
    local parent=UI.Gui.Parent

    local cfg=State.Visuals._V4Config or {
        Box3DColor=Color3.fromRGB(119,120,255),
        ChamsColor=Color3.fromRGB(119,120,255),
        CornerColor=Color3.fromRGB(255,255,255),
        ESPVisibleColor=Color3.fromRGB(55,235,95),
        ESPHiddenColor=Color3.fromRGB(245,65,65),
        ESPWallCheck=true,
        NameColor=Color3.fromRGB(255,255,255),
        ThermalColor=Color3.fromRGB(255,145,60),
        TracerColor=Color3.fromRGB(255,255,255),
        TracerOrigin="Bottom",
        SkeletonColor=Color3.fromRGB(255,255,255),
        CarColor=Color3.fromRGB(60,220,180),
        PreviewAccent=Color3.fromRGB(119,120,255),
    }
    State.Visuals._V4Config=cfg

    local function rounded(obj,r)
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,r or 5)
        c.Parent=obj
        return c
    end

    local function drag(frame,handle)
        handle.Active=true
        local dragging=false
        local startMouse,startPos
        handle.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then
                dragging=true
                startMouse=input.Position
                startPos=frame.Position
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                local d=input.Position-startMouse
                frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
        end)
    end

    for _,name in ipairs({"LvkHubUnifiedVisualsV3","LvkHubUnifiedVisualsV4","LvkHubVisualPreview","LvkHubUnifiedPreviewV3","LvkHubUnifiedPreviewV4"}) do
        local old=parent:FindFirstChild(name) or UI.Gui:FindFirstChild(name)
        if old then pcall(function() old:Destroy() end) end
    end
    local tf=Workspace:FindFirstChild("TestPlayers")
    if tf then
        for _,d in ipairs(tf:GetDescendants()) do
            if d:IsA("Highlight") and d.Name:find("LvkHubUnified",1,true) then
                pcall(function() d:Destroy() end)
            end
        end
    end

    ------------------------------------------------------------------------
    -- Yokai-style rows + ••• popup.
    ------------------------------------------------------------------------
    UI.Section(page,"Visuals")
    local popup=nil
    local popupBody=nil
    local painters={}

    local function clearPopup()
        if popup then popup:Destroy() end
        popup=nil
        popupBody=nil
    end

    local function makePopup(title)
        clearPopup()
        popup=Instance.new("Frame")
        popup.Name="VisualSettingsPopupV4"
        popup.Size=UDim2.fromOffset(214,44)
        popup.Position=UDim2.new(1,226,0,37)
        popup.BackgroundColor3=Color3.fromRGB(17,18,22)
        popup.BorderSizePixel=0
        popup.ZIndex=60
        popup.Parent=win
        rounded(popup,7)
        local st=Instance.new("UIStroke")
        st.Color=Color3.fromRGB(70,72,86)
        st.Transparency=.18
        st.Parent=popup

        local titleLabel=Instance.new("TextLabel")
        titleLabel.BackgroundTransparency=1
        titleLabel.Position=UDim2.fromOffset(10,5)
        titleLabel.Size=UDim2.new(1,-48,0,27)
        titleLabel.Font=Enum.Font.SourceSansSemibold
        titleLabel.TextSize=14
        titleLabel.TextColor3=Color3.fromRGB(235,235,240)
        titleLabel.TextXAlignment=Enum.TextXAlignment.Left
        titleLabel.Text=title
        titleLabel.ZIndex=61
        titleLabel.Parent=popup

        local close=Instance.new("TextButton")
        close.AnchorPoint=Vector2.new(1,0)
        close.Position=UDim2.new(1,-7,0,6)
        close.Size=UDim2.fromOffset(25,22)
        close.BackgroundColor3=Color3.fromRGB(35,36,43)
        close.BorderSizePixel=0
        close.Text="×"
        close.Font=Enum.Font.SourceSansBold
        close.TextSize=16
        close.TextColor3=Color3.fromRGB(210,210,218)
        close.ZIndex=62
        close.Parent=popup
        rounded(close,4)
        close.MouseButton1Click:Connect(clearPopup)

        popupBody=Instance.new("Frame")
        popupBody.BackgroundTransparency=1
        popupBody.Position=UDim2.fromOffset(7,36)
        popupBody.Size=UDim2.new(1,-14,0,0)
        popupBody.AutomaticSize=Enum.AutomaticSize.Y
        popupBody.ZIndex=61
        popupBody.Parent=popup
        local list=Instance.new("UIListLayout")
        list.Padding=UDim.new(0,4)
        list.SortOrder=Enum.SortOrder.LayoutOrder
        list.Parent=popupBody
        list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if popup then popup.Size=UDim2.fromOffset(214,44+list.AbsoluteContentSize.Y) end
        end)
    end

    local function popRow(label,height)
        local r=Instance.new("Frame")
        r.Size=UDim2.new(1,0,0,height or 30)
        r.BackgroundColor3=Color3.fromRGB(27,28,34)
        r.BorderSizePixel=0
        r.ZIndex=61
        r.Parent=popupBody
        rounded(r,4)
        local l=Instance.new("TextLabel")
        l.BackgroundTransparency=1
        l.Position=UDim2.fromOffset(8,0)
        l.Size=UDim2.new(1,-16,1,0)
        l.Font=Enum.Font.SourceSans
        l.TextSize=12
        l.TextColor3=Color3.fromRGB(222,222,228)
        l.TextXAlignment=Enum.TextXAlignment.Left
        l.Text=label
        l.ZIndex=62
        l.Parent=r
        return r,l
    end

    local function colorRow(label,getColor,setColor)
        local r,l=popRow(label,34)
        l.Size=UDim2.fromOffset(75,34)
        local sw=Instance.new("Frame")
        sw.Position=UDim2.fromOffset(78,7)
        sw.Size=UDim2.fromOffset(20,20)
        sw.BorderSizePixel=0
        sw.ZIndex=63
        sw.Parent=r
        rounded(sw,3)
        local boxes={}
        local function refresh()
            local c=getColor()
            sw.BackgroundColor3=c
            local v={math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5)}
            for i,b in ipairs(boxes) do b.Text=tostring(v[i]) end
        end
        local function commit()
            local c=getColor()
            local v={math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5)}
            for i,b in ipairs(boxes) do v[i]=math.clamp(tonumber(b.Text) or v[i],0,255) end
            setColor(Color3.fromRGB(v[1],v[2],v[3]))
            refresh()
        end
        for i=1,3 do
            local b=Instance.new("TextBox")
            b.Position=UDim2.fromOffset(103+(i-1)*31,7)
            b.Size=UDim2.fromOffset(28,20)
            b.BackgroundColor3=Color3.fromRGB(37,38,46)
            b.BorderSizePixel=0
            b.ClearTextOnFocus=false
            b.Font=Enum.Font.Code
            b.TextSize=10
            b.TextColor3=Color3.fromRGB(230,230,235)
            b.ZIndex=63
            b.Parent=r
            rounded(b,3)
            boxes[i]=b
            b.FocusLost:Connect(commit)
        end
        refresh()
    end

    local function popupToggle(label,get,set)
        local r,l=popRow(label)
        l.Size=UDim2.new(1,-50,1,0)
        local b=Instance.new("TextButton")
        b.AnchorPoint=Vector2.new(1,.5)
        b.Position=UDim2.new(1,-7,.5,0)
        b.Size=UDim2.fromOffset(34,18)
        b.Text=""
        b.BorderSizePixel=0
        b.AutoButtonColor=false
        b.ZIndex=63
        b.Parent=r
        rounded(b,3)
        local function paint() b.BackgroundColor3=get() and UI.Accent or Color3.fromRGB(48,49,57) end
        b.MouseButton1Click:Connect(function() set(not get()); paint() end)
        paint()
    end

    local function popupNumber(label,get,set,min,max)
        local r,l=popRow(label)
        l.Size=UDim2.new(1,-78,1,0)
        local b=Instance.new("TextBox")
        b.AnchorPoint=Vector2.new(1,.5)
        b.Position=UDim2.new(1,-7,.5,0)
        b.Size=UDim2.fromOffset(64,20)
        b.BackgroundColor3=Color3.fromRGB(37,38,46)
        b.BorderSizePixel=0
        b.ClearTextOnFocus=false
        b.Font=Enum.Font.Code
        b.TextSize=10
        b.TextColor3=Color3.fromRGB(230,230,235)
        b.Text=tostring(get())
        b.ZIndex=63
        b.Parent=r
        rounded(b,3)
        b.FocusLost:Connect(function()
            local n=tonumber(b.Text)
            if n then set(math.clamp(n,min,max)) end
            b.Text=tostring(get())
        end)
    end

    local function popupDropdown(label,values,get,set)
        local r,l=popRow(label)
        l.Size=UDim2.new(1,-88,1,0)
        local b=Instance.new("TextButton")
        b.AnchorPoint=Vector2.new(1,.5)
        b.Position=UDim2.new(1,-7,.5,0)
        b.Size=UDim2.fromOffset(74,20)
        b.BackgroundColor3=Color3.fromRGB(37,38,46)
        b.BorderSizePixel=0
        b.Font=Enum.Font.SourceSans
        b.TextSize=11
        b.TextColor3=Color3.fromRGB(225,225,232)
        b.ZIndex=63
        b.Parent=r
        rounded(b,3)
        local function paint() b.Text=tostring(get()) end
        b.MouseButton1Click:Connect(function()
            local i=table.find(values,get()) or 0
            set(values[i%#values+1])
            paint()
        end)
        paint()
    end

    local function visualToggle(label,get,set,builder)
        local f,t=UI.Row(page,label)
        t.Size=UDim2.new(1,-78,1,0)
        t.Active=true
        local dots=Instance.new("TextButton")
        dots.AnchorPoint=Vector2.new(1,.5)
        dots.Position=UDim2.new(1,-44,.5,0)
        dots.Size=UDim2.fromOffset(26,20)
        dots.BackgroundColor3=Color3.fromRGB(34,34,40)
        dots.BorderSizePixel=0
        dots.Font=Enum.Font.SourceSansBold
        dots.TextSize=15
        dots.TextColor3=Color3.fromRGB(195,195,205)
        dots.Text="•••"
        dots.Parent=f
        rounded(dots,4)
        local b=Instance.new("TextButton")
        b.AnchorPoint=Vector2.new(1,.5)
        b.Position=UDim2.new(1,-7,.5,0)
        b.Size=UDim2.fromOffset(28,18)
        b.Text=""
        b.BorderSizePixel=0
        b.AutoButtonColor=false
        b.Parent=f
        rounded(b,3)
        local mark=Instance.new("Frame")
        mark.AnchorPoint=Vector2.new(.5,.5)
        mark.Position=UDim2.fromScale(.5,.5)
        mark.Size=UDim2.fromOffset(18,10)
        mark.BorderSizePixel=0
        mark.Parent=b
        rounded(mark,2)
        local function paint()
            local on=get()==true
            b.BackgroundColor3=on and UI.Accent or Color3.fromRGB(45,45,45)
            mark.BackgroundColor3=on and Color3.fromRGB(238,238,240) or Color3.fromRGB(86,86,86)
        end
        local function flip() set(not get()); paint() end
        b.MouseButton1Click:Connect(flip)
        t.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then flip() end end)
        dots.MouseButton1Click:Connect(function() makePopup(label); if builder then builder() end end)
        table.insert(painters,paint)
        paint()
    end

    visualToggle("3D Box",function() return State.Visuals.Box3D end,function(v) State.Visuals.Box3D=v end,function()
        colorRow("Color",function() return cfg.Box3DColor end,function(c) cfg.Box3DColor=c end)
    end)
    visualToggle("Chams",function() return State.Visuals.Chams end,function(v) State.Visuals.Chams=v end,function()
        colorRow("Color",function() return cfg.ChamsColor end,function(c) cfg.ChamsColor=c end)
    end)
    visualToggle("Corner Box",function() return State.Visuals.CornerBox end,function(v) State.Visuals.CornerBox=v end,function()
        colorRow("Color",function() return cfg.CornerColor end,function(c) cfg.CornerColor=c end)
    end)
    visualToggle("ESP",function() return State.Visuals.ESP end,function(v) State.Visuals.ESP=v end,function()
        popupToggle("Wall Check",function() return cfg.ESPWallCheck end,function(v) cfg.ESPWallCheck=v end)
        colorRow("Visible",function() return cfg.ESPVisibleColor end,function(c) cfg.ESPVisibleColor=c end)
        colorRow("Hidden",function() return cfg.ESPHiddenColor end,function(c) cfg.ESPHiddenColor=c end)
    end)

    local fovEnabled=false
    local originalFov=setmetatable({}, {__mode="k"})
    visualToggle("FOVChanger",function() return fovEnabled end,function(v)
        fovEnabled=v
        local cam=Workspace.CurrentCamera
        if cam and not v and originalFov[cam] then cam.FieldOfView=originalFov[cam] end
    end,function()
        popupNumber("Field of View",function() return State.Visuals.FOV or 70 end,function(v) State.Visuals.FOV=v end,40,120)
    end)
    visualToggle("HealthBar",function() return State.Visuals.HealthBar end,function(v) State.Visuals.HealthBar=v end,function()
        local _,l=popRow("Gradient by HP")
        l.TextColor3=Color3.fromRGB(120,220,160)
    end)
    visualToggle("Name + Distance",function() return State.Visuals.NameDistance end,function(v) State.Visuals.NameDistance=v end,function()
        colorRow("Color",function() return cfg.NameColor end,function(c) cfg.NameColor=c end)
    end)
    visualToggle("Preview",function() return State.Visuals.Preview end,function(v) State.Visuals.Preview=v end,function()
        colorRow("Accent",function() return cfg.PreviewAccent end,function(c) cfg.PreviewAccent=c end)
    end)
    visualToggle("Thermal Corner",function() return State.Visuals.ThermalCorner end,function(v) State.Visuals.ThermalCorner=v end,function()
        colorRow("Color",function() return cfg.ThermalColor end,function(c) cfg.ThermalColor=c end)
    end)
    visualToggle("Tracers",function() return State.Visuals.Tracers end,function(v) State.Visuals.Tracers=v end,function()
        colorRow("Color",function() return cfg.TracerColor end,function(c) cfg.TracerColor=c end)
        popupDropdown("Origin",{"Bottom","Top","Mouse"},function() return cfg.TracerOrigin end,function(v) cfg.TracerOrigin=v end)
    end)
    visualToggle("Skeleton",function() return State.Visuals.Skeleton end,function(v) State.Visuals.Skeleton=v end,function()
        colorRow("Color",function() return cfg.SkeletonColor end,function(c) cfg.SkeletonColor=c end)
    end)
    visualToggle("Car ESP",function() return State.Visuals.CarESP end,function(v) State.Visuals.CarESP=v end,function()
        colorRow("Color",function() return cfg.CarColor end,function(c) cfg.CarColor=c end)
    end)

    ------------------------------------------------------------------------
    -- Main overlay.
    ------------------------------------------------------------------------
    local gui=Instance.new("ScreenGui")
    gui.Name="LvkHubUnifiedVisualsV4"
    gui.IgnoreGuiInset=true
    gui.ResetOnSpawn=false
    gui.DisplayOrder=998
    gui.Parent=parent

    local function line(name)
        local f=Instance.new("Frame")
        f.Name=name or "ESPLine"
        f.AnchorPoint=Vector2.new(.5,.5)
        f.BorderSizePixel=0
        f.BackgroundColor3=Color3.new(1,1,1)
        f.Visible=false
        f.Parent=gui
        return f
    end
    local function setLine(f,a,b,thickness,color)
        if not f or not a or not b then if f then f.Visible=false end return end
        local d=b-a
        if d.Magnitude<.01 then f.Visible=false return end
        f.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
        f.Size=UDim2.fromOffset(d.Magnitude,thickness or 1)
        f.Rotation=math.deg(math.atan2(d.Y,d.X))
        f.BackgroundColor3=color
        f.Visible=true
    end
    local function hideLines(t) for _,x in ipairs(t) do x.Visible=false end end
    local function label(name)
        local t=Instance.new("TextLabel")
        t.Name=name or "ESPLabel"
        t.AnchorPoint=Vector2.new(.5,.5)
        t.BackgroundTransparency=1
        t.Size=UDim2.fromOffset(220,18)
        t.Font=Enum.Font.Code
        t.TextSize=11
        t.TextStrokeTransparency=0
        t.TextStrokeColor3=Color3.new(0,0,0)
        t.Visible=false
        t.Parent=gui
        return t
    end

    local function healthColor(r)
        r=math.clamp(r,0,1)
        if r>=.5 then
            local t=(r-.5)/.5
            return Color3.new(1-t,1,0)
        end
        local t=r/.5
        return Color3.new(1,t,0)
    end

    local stores=setmetatable({}, {__mode="k"})
    local function newStore(model)
        local s={model=model}
        s.highlight=Instance.new("Highlight")
        s.highlight.Name="LvkHubUnifiedV4Chams"
        s.highlight.Adornee=model
        s.highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        s.highlight.FillTransparency=.62
        s.highlight.OutlineTransparency=0
        s.highlight.Enabled=false
        s.highlight.Parent=model
        s.corner={}; for i=1,8 do s.corner[i]=line("Corner"..i) end
        s.box3d={}; for i=1,12 do s.box3d[i]=line("Box3D"..i) end
        s.skeleton={}; for i=1,15 do s.skeleton[i]=line("Bone"..i) end
        s.tracer=line("Tracer")
        s.name=label("Name")
        s.dist=label("Distance")
        s.healthBack=Instance.new("Frame")
        s.healthBack.Name="HealthBack"
        s.healthBack.BorderSizePixel=0
        s.healthBack.BackgroundColor3=Color3.new(0,0,0)
        s.healthBack.Visible=false
        s.healthBack.Parent=gui
        s.health=Instance.new("Frame")
        s.health.Name="HealthFill"
        s.health.BorderSizePixel=0
        s.health.Visible=false
        s.health.Parent=gui
        stores[model]=s
        return s
    end
    local function hideStore(s)
        s.highlight.Enabled=false
        hideLines(s.corner); hideLines(s.box3d); hideLines(s.skeleton)
        s.tracer.Visible=false; s.name.Visible=false; s.dist.Visible=false
        s.healthBack.Visible=false; s.health.Visible=false
    end
    local function destroyStore(model)
        local s=stores[model]
        if not s then return end
        for _,v in pairs(s) do
            if typeof(v)=="Instance" then pcall(function() v:Destroy() end)
            elseif type(v)=="table" then for _,x in ipairs(v) do pcall(function() x:Destroy() end) end end
        end
        stores[model]=nil
    end

    local function validDummy(model)
        local folder=Workspace:FindFirstChild("TestPlayers")
        if not folder or not model or not model:IsA("Model") or not model:IsDescendantOf(folder) then return false end
        if model:GetAttribute("LvkHubManagedDummy")~=true then return false end
        if Registry.IsRealPlayerCharacter and Registry.IsRealPlayerCharacter(model) then return false end
        local hum=Registry.HumanoidOf(model)
        return hum~=nil and Registry.RootOf(model)~=nil and hum.Health>0
    end

    local function projectedBounds(model,cam)
        local root=Registry.RootOf(model)
        if not root then return nil end
        local rp,rootOn=cam:WorldToViewportPoint(root.Position)
        if not rootOn or rp.Z<=0 then return nil end

        local ok,cf,size=pcall(function() return model:GetBoundingBox() end)
        if not ok then return nil end
        local hs=size/2
        local minX,minY=math.huge,math.huge
        local maxX,maxY=-math.huge,-math.huge
        local points={}
        local allFront=true
        for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
            local wp=(cf*CFrame.new(hs.X*x,hs.Y*y,hs.Z*z)).Position
            local p=cam:WorldToViewportPoint(wp)
            local front=p.Z>0
            allFront=allFront and front
            table.insert(points,{screen=Vector2.new(p.X,p.Y),visible=front})
            if front then
                minX=math.min(minX,p.X); maxX=math.max(maxX,p.X)
                minY=math.min(minY,p.Y); maxY=math.max(maxY,p.Y)
            end
        end end end
        if not allFront or minX==math.huge then return nil end
        local w=math.clamp(maxX-minX,8,cam.ViewportSize.X*1.25)
        local h=math.clamp(maxY-minY,12,cam.ViewportSize.Y*1.25)
        return Vector2.new((minX+maxX)/2,(minY+maxY)/2),w,h,points
    end

    local function visibleToCamera(model,root,cam)
        local dir=root.Position-cam.CFrame.Position
        if dir.Magnitude<.05 then return true end
        local ray=RaycastParams.new()
        ray.FilterType=Enum.RaycastFilterType.Exclude
        local ex={model,cam}
        if LP.Character then table.insert(ex,LP.Character) end
        ray.FilterDescendantsInstances=ex
        ray.IgnoreWater=true
        return Workspace:Raycast(cam.CFrame.Position,dir,ray)==nil
    end

    local function updateCorners(lines,pos,w,h,color)
        local l,r,t,b=pos.X-w/2,pos.X+w/2,pos.Y-h/2,pos.Y+h/2
        local cw,ch=w*.22,h*.22
        local p={
            {Vector2.new(l,t),Vector2.new(l+cw,t)},{Vector2.new(l,t),Vector2.new(l,t+ch)},
            {Vector2.new(r,t),Vector2.new(r-cw,t)},{Vector2.new(r,t),Vector2.new(r,t+ch)},
            {Vector2.new(l,b),Vector2.new(l+cw,b)},{Vector2.new(l,b),Vector2.new(l,b-ch)},
            {Vector2.new(r,b),Vector2.new(r-cw,b)},{Vector2.new(r,b),Vector2.new(r,b-ch)},
        }
        for i,v in ipairs(p) do setLine(lines[i],v[1],v[2],1,color) end
    end

    local edges={{1,2},{2,4},{4,3},{3,1},{5,6},{6,8},{8,7},{7,5},{1,5},{2,6},{3,7},{4,8}}
    local function update3D(lines,points,color)
        for i,e in ipairs(edges) do
            local a,b=points[e[1]],points[e[2]]
            if a and b and a.visible and b.visible then setLine(lines[i],a.screen,b.screen,1,color) else lines[i].Visible=false end
        end
    end

    local bonesR15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
    local bonesR6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
    local function updateSkeleton(lines,model,cam,color)
        hideLines(lines)
        local bones=model:FindFirstChild("UpperTorso") and bonesR15 or bonesR6
        for i,b in ipairs(bones) do
            local a=model:FindFirstChild(b[1]); local c=model:FindFirstChild(b[2])
            if a and c and a:IsA("BasePart") and c:IsA("BasePart") and lines[i] then
                local pa,va=cam:WorldToViewportPoint(a.Position)
                local pc,vc=cam:WorldToViewportPoint(c.Position)
                if va and vc and pa.Z>0 and pc.Z>0 then setLine(lines[i],Vector2.new(pa.X,pa.Y),Vector2.new(pc.X,pc.Y),1,color) end
            end
        end
    end

    local function tracerStart(cam)
        if cfg.TracerOrigin=="Top" then return Vector2.new(cam.ViewportSize.X/2,0) end
        if cfg.TracerOrigin=="Mouse" then
            local p=UIS:GetMouseLocation()
            return Vector2.new(p.X,p.Y)
        end
        return Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y)
    end

    ------------------------------------------------------------------------
    -- Draggable selected-dummy preview.
    ------------------------------------------------------------------------
    local preview=Instance.new("Frame")
    preview.Name="LvkHubUnifiedPreviewV4"
    preview.Size=UDim2.fromOffset(252,326)
    preview.Position=UDim2.fromOffset(18,520)
    preview.BackgroundColor3=Color3.fromRGB(15,16,20)
    preview.BorderSizePixel=0
    preview.Visible=false
    preview.ZIndex=70
    preview.Parent=UI.Gui
    rounded(preview,8)
    local pst=Instance.new("UIStroke")
    pst.Color=Color3.fromRGB(70,72,88)
    pst.Transparency=.12
    pst.Parent=preview

    local pHeader=Instance.new("Frame")
    pHeader.Name="Header"
    pHeader.Size=UDim2.new(1,0,0,42)
    pHeader.BackgroundColor3=Color3.fromRGB(20,21,27)
    pHeader.BorderSizePixel=0
    pHeader.ZIndex=71
    pHeader.Parent=preview
    rounded(pHeader,8)
    local pAccent=Instance.new("Frame")
    pAccent.Size=UDim2.fromOffset(3,22)
    pAccent.Position=UDim2.fromOffset(8,10)
    pAccent.BorderSizePixel=0
    pAccent.BackgroundColor3=cfg.PreviewAccent
    pAccent.ZIndex=72
    pAccent.Parent=pHeader
    rounded(pAccent,2)
    local pTitle=Instance.new("TextLabel")
    pTitle.BackgroundTransparency=1
    pTitle.Position=UDim2.fromOffset(18,3)
    pTitle.Size=UDim2.new(1,-26,0,20)
    pTitle.Font=Enum.Font.SourceSansSemibold
    pTitle.TextSize=14
    pTitle.TextColor3=Color3.fromRGB(238,238,242)
    pTitle.TextXAlignment=Enum.TextXAlignment.Left
    pTitle.Text="VISUALS PREVIEW"
    pTitle.ZIndex=72
    pTitle.Parent=pHeader
    local pSub=Instance.new("TextLabel")
    pSub.BackgroundTransparency=1
    pSub.Position=UDim2.fromOffset(18,21)
    pSub.Size=UDim2.new(1,-26,0,16)
    pSub.Font=Enum.Font.SourceSans
    pSub.TextSize=10
    pSub.TextColor3=Color3.fromRGB(135,140,158)
    pSub.TextXAlignment=Enum.TextXAlignment.Left
    pSub.Text="DRAG • LOCAL TEST TARGET"
    pSub.ZIndex=72
    pSub.Parent=pHeader
    drag(preview,pHeader)

    local vp=Instance.new("ViewportFrame")
    vp.Position=UDim2.fromOffset(10,50)
    vp.Size=UDim2.new(1,-20,0,208)
    vp.BackgroundColor3=Color3.fromRGB(22,23,30)
    vp.BorderSizePixel=0
    vp.Ambient=Color3.fromRGB(200,200,210)
    vp.LightColor=Color3.fromRGB(255,255,255)
    vp.LightDirection=Vector3.new(-1,-1,-1)
    vp.ZIndex=71
    vp.Parent=preview
    rounded(vp,6)
    local wc=Instance.new("WorldModel")
    wc.Parent=vp
    local pc=Instance.new("Camera")
    pc.FieldOfView=34
    pc.Parent=vp
    vp.CurrentCamera=pc

    local pName=Instance.new("TextLabel")
    pName.Position=UDim2.fromOffset(12,265)
    pName.Size=UDim2.new(1,-24,0,20)
    pName.BackgroundTransparency=1
    pName.Font=Enum.Font.SourceSansSemibold
    pName.TextSize=13
    pName.TextColor3=Color3.fromRGB(235,235,240)
    pName.TextXAlignment=Enum.TextXAlignment.Left
    pName.Text="No test target"
    pName.ZIndex=72
    pName.Parent=preview
    local pMeta=Instance.new("TextLabel")
    pMeta.Position=UDim2.fromOffset(12,284)
    pMeta.Size=UDim2.new(1,-24,0,16)
    pMeta.BackgroundTransparency=1
    pMeta.Font=Enum.Font.Code
    pMeta.TextSize=10
    pMeta.TextColor3=Color3.fromRGB(150,155,170)
    pMeta.TextXAlignment=Enum.TextXAlignment.Left
    pMeta.Text="HP --  •  DIST --"
    pMeta.ZIndex=72
    pMeta.Parent=preview
    local pHealthBack=Instance.new("Frame")
    pHealthBack.Position=UDim2.fromOffset(12,305)
    pHealthBack.Size=UDim2.new(1,-24,0,7)
    pHealthBack.BackgroundColor3=Color3.fromRGB(35,36,44)
    pHealthBack.BorderSizePixel=0
    pHealthBack.ZIndex=72
    pHealthBack.Parent=preview
    rounded(pHealthBack,4)
    local pHealth=Instance.new("Frame")
    pHealth.Size=UDim2.fromScale(1,1)
    pHealth.BackgroundColor3=Color3.fromRGB(60,230,90)
    pHealth.BorderSizePixel=0
    pHealth.ZIndex=73
    pHealth.Parent=pHealthBack
    rounded(pHealth,4)

    local previewSource=nil
    local previewModel=nil
    local previewHighlight=nil
    local function clearPreviewWorld()
        for _,x in ipairs(wc:GetChildren()) do x:Destroy() end
        previewModel=nil
        previewHighlight=nil
    end
    local function desiredPreviewTarget()
        if State.Combat and State.Combat.SelectedBot and Registry.IsBot(State.Combat.SelectedBot) then return State.Combat.SelectedBot end
        local list={}
        for m in pairs(Registry.Bots) do if Registry.IsBot(m) then table.insert(list,m) end end
        table.sort(list,function(a,b) return a.Name<b.Name end)
        return list[1]
    end
    local function rebuildPreview(model)
        clearPreviewWorld()
        previewSource=model
        if not model then return end
        local old=model.Archivable
        model.Archivable=true
        local ok,clone=pcall(function() return model:Clone() end)
        model.Archivable=old
        if not ok or not clone then return end
        for _,d in ipairs(clone:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Tool") then d:Destroy()
            elseif d:IsA("BasePart") then d.Anchored=true; d.CanCollide=false end
        end
        clone.Parent=wc
        previewModel=clone
        local ok2,cf,size=pcall(function() return clone:GetBoundingBox() end)
        if ok2 then
            clone:PivotTo(CFrame.new(-cf.Position))
            local maxSize=math.max(size.X,size.Y,size.Z)
            pc.CFrame=CFrame.new(0,size.Y*.05,math.max(7,maxSize*2.2))*CFrame.Angles(0,math.rad(180),0)
        else
            pc.CFrame=CFrame.new(0,1.5,8)*CFrame.Angles(0,math.rad(180),0)
        end
        previewHighlight=Instance.new("Highlight")
        previewHighlight.Adornee=clone
        previewHighlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        previewHighlight.FillTransparency=.62
        previewHighlight.OutlineTransparency=0
        previewHighlight.Parent=wc
    end

    ------------------------------------------------------------------------
    -- Car ESP.
    ------------------------------------------------------------------------
    local cars=setmetatable({}, {__mode="k"})
    local function carAnchor(m)
        return m:FindFirstChildWhichIsA("VehicleSeat",true) or m:FindFirstChild("Seat1",true) or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart",true)
    end
    local function ensureCar(m)
        if cars[m] and cars[m].h and cars[m].h.Parent then return cars[m] end
        local a=carAnchor(m); if not a then return nil end
        for _,d in ipairs(m:GetDescendants()) do
            if d.Name=="YokaiPreservedCarESP" or d.Name=="YokaiPreservedCarLabel" or d.Name=="LvkHubCarESPV3" or d.Name=="LvkHubCarLabelV3" or d.Name=="LvkHubCarESPV4" or d.Name=="LvkHubCarLabelV4" then
                pcall(function() d:Destroy() end)
            end
        end
        local h=Instance.new("Highlight")
        h.Name="LvkHubCarESPV4"
        h.Adornee=m
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        h.FillTransparency=.84
        h.OutlineTransparency=.05
        h.Enabled=false
        h.Parent=m
        local bb=Instance.new("BillboardGui")
        bb.Name="LvkHubCarLabelV4"
        bb.Adornee=a
        bb.AlwaysOnTop=true
        bb.MaxDistance=0
        bb.Size=UDim2.fromOffset(190,26)
        bb.StudsOffsetWorldSpace=Vector3.new(0,3,0)
        bb.Enabled=false
        bb.Parent=a
        local txt=Instance.new("TextLabel")
        txt.BackgroundTransparency=1
        txt.Size=UDim2.fromScale(1,1)
        txt.Font=Enum.Font.GothamSemibold
        txt.TextSize=12
        txt.TextStrokeTransparency=.35
        txt.Parent=bb
        cars[m]={h=h,bb=bb,t=txt,a=a}
        return cars[m]
    end

    local paintTimer=0
    local carTimer=0
    local previewTimer=0
    local fovWas=false

    RunService.RenderStepped:Connect(function(dt)
        local cam=Workspace.CurrentCamera
        if not cam then return end

        paintTimer+=dt
        if paintTimer>=.15 then paintTimer=0; for _,p in ipairs(painters) do p() end end

        if originalFov[cam]==nil then originalFov[cam]=cam.FieldOfView end
        if fovEnabled then
            local wanted=math.clamp(State.Visuals.FOV or 70,40,120)
            if math.abs(cam.FieldOfView-wanted)>.01 then cam.FieldOfView=wanted end
        elseif fovWas and originalFov[cam] then
            cam.FieldOfView=originalFov[cam]
        end
        fovWas=fovEnabled

        preview.Visible=State.Visuals.Preview==true
        if preview.Visible then
            previewTimer+=dt
            local target=desiredPreviewTarget()
            if target~=previewSource or previewTimer>=1 then
                previewTimer=0
                if target~=previewSource then rebuildPreview(target) end
            end
            pAccent.BackgroundColor3=cfg.PreviewAccent
            if target and Registry.IsBot(target) then
                local hum=Registry.HumanoidOf(target)
                local root=Registry.RootOf(target)
                local ratio=hum and math.clamp(hum.Health/math.max(1,hum.MaxHealth),0,1) or 0
                local dist=root and (root.Position-cam.CFrame.Position).Magnitude or 0
                pName.Text=target.Name
                pName.TextColor3=cfg.NameColor
                pMeta.Text=string.format("HP %.0f/%.0f  •  %d studs",hum and hum.Health or 0,hum and hum.MaxHealth or 0,math.floor(dist+.5))
                pHealth.Size=UDim2.new(ratio,0,1,0)
                pHealth.BackgroundColor3=healthColor(ratio)
                if previewHighlight then
                    previewHighlight.Enabled=State.Visuals.Chams or State.Visuals.ESP
                    local c=State.Visuals.ESP and cfg.ESPVisibleColor or cfg.ChamsColor
                    previewHighlight.FillColor=c; previewHighlight.OutlineColor=c
                end
            else
                pName.Text="No test target"
                pMeta.Text="HP --  •  DIST --"
                pHealth.Size=UDim2.new(0,0,1,0)
                if previewHighlight then previewHighlight.Enabled=false end
            end
        end

        local current=setmetatable({}, {__mode="k"})
        local folder=Workspace:FindFirstChild("TestPlayers")
        if folder then
            for _,m in ipairs(folder:GetChildren()) do if validDummy(m) then current[m]=true end end
        end
        for m in pairs(stores) do if not current[m] then destroyStore(m) end end

        local any=State.Visuals.Box3D or State.Visuals.Chams or State.Visuals.CornerBox or State.Visuals.ESP or State.Visuals.HealthBar or State.Visuals.NameDistance or State.Visuals.ThermalCorner or State.Visuals.Tracers or State.Visuals.Skeleton
        for model in pairs(current) do
            local s=stores[model] or newStore(model)
            if not any then hideStore(s) continue end

            local hum=Registry.HumanoidOf(model)
            local root=Registry.RootOf(model)
            local pos,w,h,points=projectedBounds(model,cam)
            local vis=visibleToCamera(model,root,cam)
            local espColor=(not cfg.ESPWallCheck or vis) and cfg.ESPVisibleColor or cfg.ESPHiddenColor

            local chamsOn=State.Visuals.Chams or State.Visuals.ESP
            s.highlight.Enabled=chamsOn
            if chamsOn then
                local c=State.Visuals.ESP and espColor or cfg.ChamsColor
                s.highlight.FillColor=c; s.highlight.OutlineColor=c
            end

            if not pos then
                hideLines(s.corner); hideLines(s.box3d); hideLines(s.skeleton)
                s.tracer.Visible=false; s.name.Visible=false; s.dist.Visible=false; s.healthBack.Visible=false; s.health.Visible=false
                continue
            end

            if State.Visuals.CornerBox or State.Visuals.ESP or State.Visuals.ThermalCorner then
                local c=State.Visuals.ESP and espColor or (State.Visuals.ThermalCorner and cfg.ThermalColor or cfg.CornerColor)
                updateCorners(s.corner,pos,w,h,c)
            else hideLines(s.corner) end

            if State.Visuals.Box3D then update3D(s.box3d,points,cfg.Box3DColor) else hideLines(s.box3d) end
            if State.Visuals.Skeleton then updateSkeleton(s.skeleton,model,cam,cfg.SkeletonColor) else hideLines(s.skeleton) end
            if State.Visuals.Tracers then setLine(s.tracer,tracerStart(cam),pos,1,cfg.TracerColor) else s.tracer.Visible=false end

            if State.Visuals.NameDistance or State.Visuals.ESP then
                s.name.Position=UDim2.fromOffset(pos.X,pos.Y-h/2-13)
                s.name.Text=model.Name
                s.name.TextColor3=State.Visuals.ESP and espColor or cfg.NameColor
                s.name.Visible=true
                local dist=root and (root.Position-cam.CFrame.Position).Magnitude or 0
                s.dist.Position=UDim2.fromOffset(pos.X,pos.Y+h/2+9)
                s.dist.Text=string.format("%d studs",math.floor(dist+.5))
                s.dist.TextColor3=s.name.TextColor3
                s.dist.Visible=true
            else
                s.name.Visible=false; s.dist.Visible=false
            end

            if (State.Visuals.HealthBar or State.Visuals.ESP) and hum then
                local ratio=math.clamp(hum.Health/math.max(1,hum.MaxHealth),0,1)
                s.healthBack.Position=UDim2.fromOffset(pos.X-w/2-7,pos.Y-h/2)
                s.healthBack.Size=UDim2.fromOffset(4,h)
                s.healthBack.Visible=true
                s.health.Position=UDim2.fromOffset(pos.X-w/2-6,pos.Y-h/2+h*(1-ratio)+1)
                s.health.Size=UDim2.fromOffset(2,math.max(0,h*ratio-2))
                s.health.BackgroundColor3=healthColor(ratio)
                s.health.Visible=true
            else
                s.healthBack.Visible=false; s.health.Visible=false
            end
        end

        carTimer+=dt
        if carTimer>=.5 then
            carTimer=0
            local vf=Workspace:FindFirstChild("Vehicles")
            local live=setmetatable({}, {__mode="k"})
            if vf then
                for _,m in ipairs(vf:GetChildren()) do if m:IsA("Model") then live[m]=true; ensureCar(m) end end
            end
            for m,s in pairs(cars) do
                if not live[m] or not m.Parent then
                    if s.h then s.h:Destroy() end
                    if s.bb then s.bb:Destroy() end
                    cars[m]=nil
                end
            end
        end
        for m,s in pairs(cars) do
            local show=State.Visuals.CarESP==true and m.Parent~=nil
            s.h.Enabled=show; s.bb.Enabled=show
            if show and s.a and s.a.Parent then
                s.h.FillColor=cfg.CarColor; s.h.OutlineColor=cfg.CarColor; s.t.TextColor3=cfg.CarColor
                local dist=(s.a.Position-cam.CFrame.Position).Magnitude
                s.t.Text=string.format("%s  •  %d studs",m.Name:gsub("_"," "),math.floor(dist+.5))
            end
        end
    end)
end
