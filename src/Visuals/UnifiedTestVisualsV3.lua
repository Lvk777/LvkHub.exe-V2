-- LvkHub.exe unified Visuals V3
-- Single renderer for LOCAL Workspace.TestPlayers dummies only.
-- Removes the previous multi-renderer/Highlight conflicts and does not use real Player.Character targets.

return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local Players=game:GetService("Players")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Visuals
    local win=UI.Windows.Visuals
    local parent=UI.Gui.Parent

    local DEFAULT_BLUE=Color3.fromRGB(119,120,255)
    local cfg=State.Visuals._V3Config or {
        Box3DColor=Color3.fromRGB(119,120,255),
        ChamsColor=Color3.fromRGB(119,120,255),
        CornerColor=Color3.fromRGB(255,255,255),
        ESPVisibleColor=Color3.fromRGB(55,235,95),
        ESPHiddenColor=Color3.fromRGB(245,65,65),
        ESPWallCheck=true,
        HealthColor=Color3.fromRGB(80,235,120),
        NameColor=Color3.fromRGB(255,255,255),
        ThermalColor=Color3.fromRGB(255,145,60),
        TracerColor=Color3.fromRGB(255,255,255),
        SkeletonColor=Color3.fromRGB(255,255,255),
        CarColor=Color3.fromRGB(60,220,180),
        PreviewAccent=Color3.fromRGB(119,120,255),
    }
    State.Visuals._V3Config=cfg

    -- Clean leftovers from older visual stacks so only one renderer owns the dummies.
    for _,name in ipairs({
        "LvkHubVisuals","LvkHubVisualPreview","LvkHubTestPlayersVisualFallback",
        "LvkHubUnifiedVisualsV3","LvkHubUnifiedPreviewV3"
    }) do
        local old=parent:FindFirstChild(name)
        if old then pcall(function() old:Destroy() end) end
    end
    local tf=Workspace:FindFirstChild("TestPlayers")
    if tf then
        for _,d in ipairs(tf:GetDescendants()) do
            if d:IsA("Highlight") and (
                d.Name=="AttachedChams" or d.Name=="AttachedESPPackChams" or
                d.Name=="LvkHubTestPlayersFallbackChams" or d.Name=="LvkHubUnifiedTestChams"
            ) then pcall(function() d:Destroy() end) end
        end
    end

    ------------------------------------------------------------------------
    -- Compact Yokai-style rows with a ... settings button.
    ------------------------------------------------------------------------
    UI.Section(page,"Visuals")

    local painters={}
    local popup=nil
    local popupTitle=nil
    local popupBody=nil

    local function rounded(obj,r)
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,r or 4)
        c.Parent=obj
    end

    local function clearPopup()
        if popup then popup:Destroy() end
        popup=nil; popupTitle=nil; popupBody=nil
    end

    local function makePopup(title)
        clearPopup()
        popup=Instance.new("Frame")
        popup.Name="VisualSettingsPopup"
        popup.Size=UDim2.fromOffset(206,40)
        popup.Position=UDim2.new(1,226,0,37)
        popup.BackgroundColor3=Color3.fromRGB(18,18,21)
        popup.BorderSizePixel=0
        popup.ClipsDescendants=false
        popup.ZIndex=50
        popup.Parent=win
        rounded(popup,6)
        local stroke=Instance.new("UIStroke")
        stroke.Color=Color3.fromRGB(58,60,70); stroke.Transparency=.15; stroke.Parent=popup

        popupTitle=Instance.new("TextLabel")
        popupTitle.BackgroundTransparency=1
        popupTitle.Position=UDim2.fromOffset(10,4)
        popupTitle.Size=UDim2.new(1,-42,0,28)
        popupTitle.Font=Enum.Font.SourceSansSemibold
        popupTitle.TextSize=14
        popupTitle.TextColor3=Color3.fromRGB(230,230,235)
        popupTitle.TextXAlignment=Enum.TextXAlignment.Left
        popupTitle.Text=title
        popupTitle.ZIndex=51
        popupTitle.Parent=popup

        local close=Instance.new("TextButton")
        close.AnchorPoint=Vector2.new(1,0)
        close.Position=UDim2.new(1,-7,0,6)
        close.Size=UDim2.fromOffset(24,22)
        close.BackgroundColor3=Color3.fromRGB(35,35,40)
        close.BorderSizePixel=0
        close.Text="×"
        close.Font=Enum.Font.SourceSansBold
        close.TextSize=16
        close.TextColor3=Color3.fromRGB(205,205,210)
        close.ZIndex=52
        close.Parent=popup
        rounded(close,4)
        close.MouseButton1Click:Connect(clearPopup)

        popupBody=Instance.new("Frame")
        popupBody.BackgroundTransparency=1
        popupBody.Position=UDim2.fromOffset(7,36)
        popupBody.Size=UDim2.new(1,-14,0,0)
        popupBody.AutomaticSize=Enum.AutomaticSize.Y
        popupBody.ZIndex=51
        popupBody.Parent=popup
        local list=Instance.new("UIListLayout")
        list.Padding=UDim.new(0,4)
        list.SortOrder=Enum.SortOrder.LayoutOrder
        list.Parent=popupBody
        list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            popup.Size=UDim2.fromOffset(206,44+list.AbsoluteContentSize.Y)
        end)
        return popupBody
    end

    local function popRow(label,height)
        local r=Instance.new("Frame")
        r.Size=UDim2.new(1,0,0,height or 30)
        r.BackgroundColor3=Color3.fromRGB(27,27,31)
        r.BorderSizePixel=0
        r.ZIndex=51
        r.Parent=popupBody
        rounded(r,4)
        local l=Instance.new("TextLabel")
        l.BackgroundTransparency=1
        l.Position=UDim2.fromOffset(8,0)
        l.Size=UDim2.new(1,-16,1,0)
        l.Font=Enum.Font.SourceSans
        l.TextSize=12
        l.TextColor3=Color3.fromRGB(220,220,225)
        l.TextXAlignment=Enum.TextXAlignment.Left
        l.Text=label
        l.ZIndex=52
        l.Parent=r
        return r,l
    end

    local function colorRow(label,getColor,setColor)
        local r,l=popRow(label,34)
        l.Size=UDim2.fromOffset(72,34)
        local swatch=Instance.new("Frame")
        swatch.Position=UDim2.fromOffset(76,7)
        swatch.Size=UDim2.fromOffset(20,20)
        swatch.BorderSizePixel=0
        swatch.ZIndex=53
        swatch.Parent=r
        rounded(swatch,3)

        local boxes={}
        local function refresh()
            local c=getColor()
            swatch.BackgroundColor3=c
            local vals={math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5)}
            for i,b in ipairs(boxes) do b.Text=tostring(vals[i]) end
        end
        local function commit()
            local old=getColor()
            local vals={math.floor(old.R*255+.5),math.floor(old.G*255+.5),math.floor(old.B*255+.5)}
            for i,b in ipairs(boxes) do vals[i]=math.clamp(tonumber(b.Text) or vals[i],0,255) end
            setColor(Color3.fromRGB(vals[1],vals[2],vals[3]))
            refresh()
        end
        for i=1,3 do
            local b=Instance.new("TextBox")
            b.Position=UDim2.fromOffset(100+(i-1)*30,7)
            b.Size=UDim2.fromOffset(27,20)
            b.BackgroundColor3=Color3.fromRGB(36,36,42)
            b.BorderSizePixel=0
            b.ClearTextOnFocus=false
            b.Font=Enum.Font.Code
            b.TextSize=10
            b.TextColor3=Color3.fromRGB(225,225,230)
            b.ZIndex=53
            b.Parent=r
            rounded(b,3)
            boxes[i]=b
            b.FocusLost:Connect(commit)
        end
        refresh()
    end

    local function popupToggle(label,get,set)
        local r,l=popRow(label,30)
        l.Size=UDim2.new(1,-50,1,0)
        local b=Instance.new("TextButton")
        b.AnchorPoint=Vector2.new(1,.5)
        b.Position=UDim2.new(1,-7,.5,0)
        b.Size=UDim2.fromOffset(34,18)
        b.Text=""
        b.BorderSizePixel=0
        b.AutoButtonColor=false
        b.ZIndex=53
        b.Parent=r
        rounded(b,3)
        local function paint() b.BackgroundColor3=get() and UI.Accent or Color3.fromRGB(48,48,54) end
        b.MouseButton1Click:Connect(function() set(not get()); paint() end)
        paint()
    end

    local function popupNumber(label,get,set,min,max)
        local r,l=popRow(label,30)
        l.Size=UDim2.new(1,-72,1,0)
        local b=Instance.new("TextBox")
        b.AnchorPoint=Vector2.new(1,.5)
        b.Position=UDim2.new(1,-7,.5,0)
        b.Size=UDim2.fromOffset(58,20)
        b.BackgroundColor3=Color3.fromRGB(36,36,42)
        b.BorderSizePixel=0
        b.ClearTextOnFocus=false
        b.Font=Enum.Font.Code
        b.TextSize=10
        b.TextColor3=Color3.fromRGB(225,225,230)
        b.Text=tostring(get())
        b.ZIndex=53
        b.Parent=r
        rounded(b,3)
        b.FocusLost:Connect(function()
            local n=tonumber(b.Text)
            if n then set(math.clamp(n,min,max)) end
            b.Text=tostring(get())
        end)
    end

    local function visualToggle(label,get,set,settingsTitle,builder)
        local f,t=UI.Row(page,label)
        t.Size=UDim2.new(1,-78,1,0)
        t.Active=true

        local dots=Instance.new("TextButton")
        dots.AnchorPoint=Vector2.new(1,.5)
        dots.Position=UDim2.new(1,-44,.5,0)
        dots.Size=UDim2.fromOffset(26,20)
        dots.BackgroundColor3=Color3.fromRGB(34,34,38)
        dots.BorderSizePixel=0
        dots.AutoButtonColor=false
        dots.Font=Enum.Font.SourceSansBold
        dots.TextSize=15
        dots.TextColor3=Color3.fromRGB(190,190,200)
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
            mark.BackgroundColor3=on and Color3.fromRGB(235,235,235) or Color3.fromRGB(86,86,86)
        end
        local function flip() set(not get()); paint() end
        b.MouseButton1Click:Connect(flip)
        t.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then flip() end
        end)
        dots.MouseButton1Click:Connect(function()
            makePopup(settingsTitle or label)
            if builder then builder() end
        end)
        table.insert(painters,paint)
        paint()
        return f
    end

    visualToggle("3D Box",function() return State.Visuals.Box3D end,function(v) State.Visuals.Box3D=v end,"3D Box",function()
        colorRow("Color",function() return cfg.Box3DColor end,function(c) cfg.Box3DColor=c end)
    end)
    visualToggle("Chams",function() return State.Visuals.Chams end,function(v) State.Visuals.Chams=v end,"Chams",function()
        colorRow("Color",function() return cfg.ChamsColor end,function(c) cfg.ChamsColor=c end)
    end)
    visualToggle("Corner Box",function() return State.Visuals.CornerBox end,function(v) State.Visuals.CornerBox=v end,"Corner Box",function()
        colorRow("Color",function() return cfg.CornerColor end,function(c) cfg.CornerColor=c end)
    end)
    visualToggle("ESP",function() return State.Visuals.ESP end,function(v) State.Visuals.ESP=v end,"ESP",function()
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
    end,"FOVChanger",function()
        popupNumber("Field of View",function() return State.Visuals.FOV or 70 end,function(v) State.Visuals.FOV=v end,40,120)
    end)

    visualToggle("HealthBar",function() return State.Visuals.HealthBar end,function(v) State.Visuals.HealthBar=v end,"HealthBar",function()
        colorRow("Color",function() return cfg.HealthColor end,function(c) cfg.HealthColor=c end)
    end)
    visualToggle("Name + Distance",function() return State.Visuals.NameDistance end,function(v) State.Visuals.NameDistance=v end,"Name + Distance",function()
        colorRow("Color",function() return cfg.NameColor end,function(c) cfg.NameColor=c end)
    end)
    visualToggle("Preview",function() return State.Visuals.Preview end,function(v) State.Visuals.Preview=v end,"Preview",function()
        colorRow("Accent",function() return cfg.PreviewAccent end,function(c) cfg.PreviewAccent=c end)
    end)
    visualToggle("Thermal Corner",function() return State.Visuals.ThermalCorner end,function(v) State.Visuals.ThermalCorner=v end,"Thermal Corner",function()
        colorRow("Color",function() return cfg.ThermalColor end,function(c) cfg.ThermalColor=c end)
    end)
    visualToggle("Tracers",function() return State.Visuals.Tracers end,function(v) State.Visuals.Tracers=v end,"Tracers",function()
        colorRow("Color",function() return cfg.TracerColor end,function(c) cfg.TracerColor=c end)
    end)
    visualToggle("Skeleton",function() return State.Visuals.Skeleton end,function(v) State.Visuals.Skeleton=v end,"Skeleton",function()
        colorRow("Color",function() return cfg.SkeletonColor end,function(c) cfg.SkeletonColor=c end)
    end)
    visualToggle("Car ESP",function() return State.Visuals.CarESP end,function(v) State.Visuals.CarESP=v end,"Car ESP",function()
        colorRow("Color",function() return cfg.CarColor end,function(c) cfg.CarColor=c end)
    end)

    ------------------------------------------------------------------------
    -- Main screen overlay.
    ------------------------------------------------------------------------
    local gui=Instance.new("ScreenGui")
    gui.Name="LvkHubUnifiedVisualsV3"
    gui.IgnoreGuiInset=true
    gui.ResetOnSpawn=false
    gui.DisplayOrder=998
    gui.Parent=parent

    local function line()
        local f=Instance.new("Frame")
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
        f.BackgroundColor3=color or Color3.new(1,1,1)
        f.Visible=true
    end
    local function hideLines(t) for _,x in ipairs(t) do x.Visible=false end end
    local function label()
        local t=Instance.new("TextLabel")
        t.AnchorPoint=Vector2.new(.5,.5)
        t.BackgroundTransparency=1
        t.Size=UDim2.fromOffset(220,18)
        t.Font=Enum.Font.Code
        t.TextSize=11
        t.TextStrokeTransparency=0
        t.TextStrokeColor3=Color3.new(0,0,0)
        t.TextColor3=Color3.new(1,1,1)
        t.Visible=false
        t.Parent=gui
        return t
    end

    local stores=setmetatable({}, {__mode="k"})
    local function newStore(model)
        local s={model=model}
        s.highlight=Instance.new("Highlight")
        s.highlight.Name="LvkHubUnifiedV3Chams"
        s.highlight.Adornee=model
        s.highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        s.highlight.FillTransparency=.62
        s.highlight.OutlineTransparency=0
        s.highlight.Enabled=false
        s.highlight.Parent=model
        s.corner={}; for i=1,8 do s.corner[i]=line() end
        s.box3d={}; for i=1,12 do s.box3d[i]=line() end
        s.skeleton={}; for i=1,15 do s.skeleton[i]=line() end
        s.tracer=line()
        s.name=label(); s.dist=label()
        s.healthBack=Instance.new("Frame"); s.healthBack.BorderSizePixel=0; s.healthBack.BackgroundColor3=Color3.new(0,0,0); s.healthBack.Visible=false; s.healthBack.Parent=gui
        s.health=Instance.new("Frame"); s.health.BorderSizePixel=0; s.health.Visible=false; s.health.Parent=gui
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
        local s=stores[model]; if not s then return end
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
        local hum=Registry.HumanoidOf(model); local root=Registry.RootOf(model)
        return hum~=nil and root~=nil and hum.Health>0
    end

    local function projectedBounds(model,cam)
        local ok,cf,size=pcall(function() return model:GetBoundingBox() end)
        if not ok or not cf or not size then return nil end
        local hs=size/2
        local minX,minY=math.huge,math.huge
        local maxX,maxY=-math.huge,-math.huge
        local any=false
        local points={}
        for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
            local wp=(cf*CFrame.new(hs.X*x,hs.Y*y,hs.Z*z)).Position
            local p,on=cam:WorldToViewportPoint(wp)
            table.insert(points,{screen=Vector2.new(p.X,p.Y),visible=on and p.Z>0})
            if on and p.Z>0 then
                any=true; minX=math.min(minX,p.X); maxX=math.max(maxX,p.X); minY=math.min(minY,p.Y); maxY=math.max(maxY,p.Y)
            end
        end end end
        if not any then return nil end
        return Vector2.new((minX+maxX)/2,(minY+maxY)/2),math.max(8,maxX-minX),math.max(12,maxY-minY),points
    end

    local function visibleToCamera(model,root,cam)
        if not root or not cam then return false end
        local dir=root.Position-cam.CFrame.Position
        if dir.Magnitude<.05 then return true end
        local rp=RaycastParams.new()
        rp.FilterType=Enum.RaycastFilterType.Exclude
        local ex={model}
        if LP.Character then table.insert(ex,LP.Character) end
        rp.FilterDescendantsInstances=ex
        rp.IgnoreWater=true
        return Workspace:Raycast(cam.CFrame.Position,dir,rp)==nil
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
        if not points then hideLines(lines); return end
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
                local pa,va=cam:WorldToViewportPoint(a.Position); local pc,vc=cam:WorldToViewportPoint(c.Position)
                if va and vc and pa.Z>0 and pc.Z>0 then setLine(lines[i],Vector2.new(pa.X,pa.Y),Vector2.new(pc.X,pc.Y),1,color) end
            end
        end
    end

    ------------------------------------------------------------------------
    -- Better preview: actual 3D block avatar inside a ViewportFrame + overlays.
    ------------------------------------------------------------------------
    local preview=Instance.new("Frame")
    preview.Name="LvkHubUnifiedPreviewV3"
    preview.Size=UDim2.fromOffset(210,282)
    preview.Position=UDim2.new(1,8,0,37)
    preview.BackgroundColor3=Color3.fromRGB(16,16,20)
    preview.BorderSizePixel=0
    preview.Visible=false
    preview.ZIndex=40
    preview.Parent=win
    rounded(preview,7)
    local ps=Instance.new("UIStroke"); ps.Color=Color3.fromRGB(55,58,68); ps.Transparency=.15; ps.Parent=preview
    local pt=Instance.new("TextLabel")
    pt.BackgroundTransparency=1; pt.Position=UDim2.fromOffset(10,5); pt.Size=UDim2.new(1,-20,0,24); pt.Font=Enum.Font.SourceSansSemibold; pt.TextSize=13; pt.TextColor3=Color3.fromRGB(230,230,235); pt.TextXAlignment=Enum.TextXAlignment.Left; pt.Text="Visuals Preview"; pt.ZIndex=41; pt.Parent=preview
    local vp=Instance.new("ViewportFrame")
    vp.Position=UDim2.fromOffset(10,32); vp.Size=UDim2.new(1,-20,1,-42); vp.BackgroundColor3=Color3.fromRGB(23,23,29); vp.BorderSizePixel=0; vp.Ambient=Color3.fromRGB(190,190,190); vp.LightColor=Color3.fromRGB(255,255,255); vp.LightDirection=Vector3.new(-1,-1,-1); vp.ZIndex=41; vp.Parent=preview
    rounded(vp,5)
    local wc=Instance.new("WorldModel"); wc.Parent=vp
    local pc=Instance.new("Camera"); pc.FieldOfView=36; pc.CFrame=CFrame.new(0,1.7,9)*CFrame.Angles(0,math.rad(180),0); pc.Parent=vp; vp.CurrentCamera=pc
    local dummy=Instance.new("Model"); dummy.Name="PreviewDummy"; dummy.Parent=wc
    local function part(name,size,pos)
        local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Anchored=true; p.CanCollide=false; p.Material=Enum.Material.SmoothPlastic; p.Color=Color3.fromRGB(160,165,180); p.CFrame=CFrame.new(pos); p.Parent=dummy; return p
    end
    part("Torso",Vector3.new(2,2,1),Vector3.new(0,1.5,0)); part("Head",Vector3.new(1.4,1.4,1.4),Vector3.new(0,3.2,0)); part("LeftArm",Vector3.new(.7,2,1),Vector3.new(-1.4,1.5,0)); part("RightArm",Vector3.new(.7,2,1),Vector3.new(1.4,1.5,0)); part("LeftLeg",Vector3.new(.8,2,1),Vector3.new(-.55,-.5,0)); part("RightLeg",Vector3.new(.8,2,1),Vector3.new(.55,-.5,0))
    local ph=Instance.new("Highlight"); ph.Adornee=dummy; ph.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; ph.FillTransparency=.55; ph.OutlineTransparency=0; ph.Parent=wc
    local pName=Instance.new("TextLabel"); pName.BackgroundTransparency=1; pName.Size=UDim2.fromOffset(160,18); pName.Position=UDim2.new(.5,-80,0,44); pName.Font=Enum.Font.Code; pName.TextSize=11; pName.Text="TEST_DUMMY  •  42m"; pName.TextStrokeTransparency=0; pName.ZIndex=45; pName.Parent=preview
    local pHealthBack=Instance.new("Frame"); pHealthBack.Position=UDim2.fromOffset(25,70); pHealthBack.Size=UDim2.fromOffset(4,145); pHealthBack.BackgroundColor3=Color3.new(0,0,0); pHealthBack.BorderSizePixel=0; pHealthBack.ZIndex=45; pHealthBack.Parent=preview
    local pHealth=Instance.new("Frame"); pHealth.AnchorPoint=Vector2.new(0,1); pHealth.Position=UDim2.new(0,25,0,215); pHealth.Size=UDim2.fromOffset(4,112); pHealth.BorderSizePixel=0; pHealth.ZIndex=46; pHealth.Parent=preview
    local pTracer=Instance.new("Frame"); pTracer.AnchorPoint=Vector2.new(.5,.5); pTracer.BorderSizePixel=0; pTracer.ZIndex=45; pTracer.Parent=preview
    local function setPreviewTracer()
        local a=Vector2.new(105,270); local b=Vector2.new(105,160); local d=b-a
        pTracer.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2); pTracer.Size=UDim2.fromOffset(d.Magnitude,1); pTracer.Rotation=math.deg(math.atan2(d.Y,d.X))
    end
    setPreviewTracer()

    ------------------------------------------------------------------------
    -- Car ESP direct from Workspace.Vehicles; no distance gate.
    ------------------------------------------------------------------------
    local cars=setmetatable({}, {__mode="k"})
    local function carAnchor(m)
        return m:FindFirstChildWhichIsA("VehicleSeat",true) or m:FindFirstChild("Seat1",true) or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart",true)
    end
    local function ensureCar(m)
        if cars[m] and cars[m].h and cars[m].h.Parent then return cars[m] end
        local a=carAnchor(m); if not a then return nil end
        for _,d in ipairs(m:GetDescendants()) do
            if d.Name=="YokaiPreservedCarESP" or d.Name=="YokaiPreservedCarLabel" or d.Name=="LvkHubCarESPV3" or d.Name=="LvkHubCarLabelV3" then pcall(function() d:Destroy() end) end
        end
        local h=Instance.new("Highlight"); h.Name="LvkHubCarESPV3"; h.Adornee=m; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.FillTransparency=.84; h.OutlineTransparency=.05; h.Enabled=false; h.Parent=m
        local bb=Instance.new("BillboardGui"); bb.Name="LvkHubCarLabelV3"; bb.Adornee=a; bb.AlwaysOnTop=true; bb.MaxDistance=0; bb.Size=UDim2.fromOffset(190,26); bb.StudsOffsetWorldSpace=Vector3.new(0,3,0); bb.Enabled=false; bb.Parent=a
        local txt=Instance.new("TextLabel"); txt.BackgroundTransparency=1; txt.Size=UDim2.fromScale(1,1); txt.Font=Enum.Font.GothamSemibold; txt.TextSize=12; txt.TextStrokeTransparency=.35; txt.Parent=bb
        cars[m]={h=h,bb=bb,t=txt,a=a}; return cars[m]
    end

    local carScan=0
    local paintTimer=0
    local fovLast=false

    RunService.RenderStepped:Connect(function(dt)
        paintTimer+=dt
        if paintTimer>=.15 then paintTimer=0; for _,p in ipairs(painters) do p() end end

        local cam=Workspace.CurrentCamera
        if not cam then return end
        if originalFov[cam]==nil then originalFov[cam]=cam.FieldOfView end
        if fovEnabled then
            local wanted=math.clamp(State.Visuals.FOV or 70,40,120)
            if math.abs(cam.FieldOfView-wanted)>.01 then cam.FieldOfView=wanted end
        elseif fovLast and originalFov[cam] then
            cam.FieldOfView=originalFov[cam]
        end
        fovLast=fovEnabled

        preview.Visible=State.Visuals.Preview==true
        if preview.Visible then
            ph.Enabled=State.Visuals.Chams or State.Visuals.ESP
            ph.FillColor=State.Visuals.ESP and cfg.ESPVisibleColor or cfg.ChamsColor
            ph.OutlineColor=ph.FillColor
            for _,p in ipairs(dummy:GetChildren()) do if p:IsA("BasePart") then p.Color=cfg.PreviewAccent end end
            pName.Visible=State.Visuals.NameDistance or State.Visuals.ESP; pName.TextColor3=cfg.NameColor
            pHealthBack.Visible=State.Visuals.HealthBar or State.Visuals.ESP; pHealth.Visible=pHealthBack.Visible; pHealth.BackgroundColor3=cfg.HealthColor
            pTracer.Visible=State.Visuals.Tracers; pTracer.BackgroundColor3=cfg.TracerColor
        end

        local current=setmetatable({}, {__mode="k"})
        local folder=Workspace:FindFirstChild("TestPlayers")
        if folder then
            for _,model in ipairs(folder:GetChildren()) do if validDummy(model) then current[model]=true end end
        end
        for model in pairs(stores) do if not current[model] then destroyStore(model) end end

        local any=State.Visuals.Box3D or State.Visuals.Chams or State.Visuals.CornerBox or State.Visuals.ESP or State.Visuals.HealthBar or State.Visuals.NameDistance or State.Visuals.ThermalCorner or State.Visuals.Tracers or State.Visuals.Skeleton
        for model in pairs(current) do
            local s=stores[model] or newStore(model)
            if not any then hideStore(s) continue end
            local hum=Registry.HumanoidOf(model); local root=Registry.RootOf(model)
            local pos,w,h,points=projectedBounds(model,cam)
            local visible=visibleToCamera(model,root,cam)
            local espColor=(not cfg.ESPWallCheck or visible) and cfg.ESPVisibleColor or cfg.ESPHiddenColor

            local chamsOn=State.Visuals.Chams or State.Visuals.ESP
            s.highlight.Enabled=chamsOn
            if chamsOn then
                local c=State.Visuals.ESP and espColor or cfg.ChamsColor
                s.highlight.FillColor=c; s.highlight.OutlineColor=c; s.highlight.FillTransparency=.62; s.highlight.OutlineTransparency=0
            end

            if not pos then
                hideLines(s.corner); hideLines(s.box3d); hideLines(s.skeleton); s.tracer.Visible=false; s.name.Visible=false; s.dist.Visible=false; s.healthBack.Visible=false; s.health.Visible=false
                continue
            end

            if State.Visuals.CornerBox or State.Visuals.ESP or State.Visuals.ThermalCorner then
                local c=State.Visuals.ESP and espColor or (State.Visuals.ThermalCorner and cfg.ThermalColor or cfg.CornerColor)
                updateCorners(s.corner,pos,w,h,c)
            else hideLines(s.corner) end

            if State.Visuals.Box3D then update3D(s.box3d,points,cfg.Box3DColor) else hideLines(s.box3d) end
            if State.Visuals.Skeleton then updateSkeleton(s.skeleton,model,cam,cfg.SkeletonColor) else hideLines(s.skeleton) end
            if State.Visuals.Tracers then setLine(s.tracer,Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y),pos,1,cfg.TracerColor) else s.tracer.Visible=false end

            if State.Visuals.NameDistance or State.Visuals.ESP then
                s.name.Position=UDim2.fromOffset(pos.X,pos.Y-h/2-13); s.name.Text=model.Name; s.name.TextColor3=State.Visuals.ESP and espColor or cfg.NameColor; s.name.Visible=true
                local dist=root and (root.Position-cam.CFrame.Position).Magnitude or 0
                s.dist.Position=UDim2.fromOffset(pos.X,pos.Y+h/2+9); s.dist.Text=string.format("%d studs",math.floor(dist+.5)); s.dist.TextColor3=s.name.TextColor3; s.dist.Visible=true
            else s.name.Visible=false; s.dist.Visible=false end

            if (State.Visuals.HealthBar or State.Visuals.ESP) and hum then
                local ratio=math.clamp(hum.Health/math.max(1,hum.MaxHealth),0,1)
                s.healthBack.Position=UDim2.fromOffset(pos.X-w/2-6,pos.Y-h/2); s.healthBack.Size=UDim2.fromOffset(3,h); s.healthBack.Visible=true
                s.health.Position=UDim2.fromOffset(pos.X-w/2-6,pos.Y-h/2+h*(1-ratio)); s.health.Size=UDim2.fromOffset(3,h*ratio); s.health.BackgroundColor3=State.Visuals.ESP and espColor or cfg.HealthColor; s.health.Visible=true
            else s.healthBack.Visible=false; s.health.Visible=false end
        end

        carScan+=dt
        if carScan>=.5 then
            carScan=0
            local vf=Workspace:FindFirstChild("Vehicles")
            local live=setmetatable({}, {__mode="k"})
            if vf then
                for _,m in ipairs(vf:GetChildren()) do if m:IsA("Model") then live[m]=true; ensureCar(m) end end
            end
            for m,s in pairs(cars) do
                if not live[m] or not m.Parent then
                    if s.h then s.h:Destroy() end; if s.bb then s.bb:Destroy() end; cars[m]=nil
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
