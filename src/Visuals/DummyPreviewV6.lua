-- Single polished Visuals preview using the public avatar appearance of vitor250407.
-- Preview-only: this avatar is never inserted into Registry.Bots or used as a target.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")
    local Workspace=game:GetService("Workspace")

    local cfg=State.Visuals._V5Config or {}
    State.Visuals.PreviewHealth=tonumber(State.Visuals.PreviewHealth) or 100

    local function rounded(o,r)
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,r or 5)
        c.Parent=o
    end

    ------------------------------------------------------------------------
    -- Guarantee one preview only. UnifiedTestVisualsV5 historically created a
    -- legacy preview; remove every known legacy frame before creating this one.
    ------------------------------------------------------------------------
    local function purgeLegacy(except)
        for _,name in ipairs({
            "LvkHubVisualsDummyPreview",
            "LvkHubUnifiedPreviewV3",
            "LvkHubUnifiedPreviewV4",
            "LvkHubUnifiedPreviewV5",
            "LvkHubVisualPreview",
        }) do
            local x=UI.Gui:FindFirstChild(name)
            if x and x~=except then pcall(function() x:Destroy() end) end
        end

        -- Fallback cleanup for an old preview whose internal name changed.
        for _,x in ipairs(UI.Gui:GetChildren()) do
            if x~=except and x:IsA("Frame") then
                local looksLikePreview=false
                for _,d in ipairs(x:GetDescendants()) do
                    if d:IsA("TextLabel") then
                        local txt=string.upper(tostring(d.Text or ""))
                        if txt=="VISUALS PREVIEW" then
                            looksLikePreview=true
                            break
                        end
                    end
                end
                if looksLikePreview then pcall(function() x:Destroy() end) end
            end
        end
    end
    purgeLegacy(nil)

    ------------------------------------------------------------------------
    -- Window.
    ------------------------------------------------------------------------
    local frame=Instance.new("Frame")
    frame.Name="LvkHubVisualsDummyPreview"
    frame.Size=UDim2.fromOffset(254,332)
    frame.Position=UDim2.fromOffset(1398,220)
    frame.BackgroundColor3=Color3.fromRGB(14,15,20)
    frame.BorderSizePixel=0
    frame.Visible=false
    frame.ZIndex=170
    frame.Parent=UI.Gui
    rounded(frame,8)

    local outline=Instance.new("UIStroke")
    outline.Color=Color3.fromRGB(58,61,76)
    outline.Transparency=.08
    outline.Thickness=1
    outline.Parent=frame

    local header=Instance.new("Frame")
    header.Name="Header"
    header.Size=UDim2.new(1,0,0,42)
    header.BackgroundColor3=Color3.fromRGB(19,20,27)
    header.BorderSizePixel=0
    header.Active=true
    header.ZIndex=171
    header.Parent=frame
    rounded(header,8)

    local accent=Instance.new("Frame")
    accent.Position=UDim2.fromOffset(8,10)
    accent.Size=UDim2.fromOffset(3,22)
    accent.BackgroundColor3=UI.Accent
    accent.BorderSizePixel=0
    accent.ZIndex=172
    accent.Parent=header
    rounded(accent,2)

    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Position=UDim2.fromOffset(18,3)
    title.Size=UDim2.new(1,-26,0,20)
    title.Font=Enum.Font.SourceSansSemibold
    title.TextSize=14
    title.TextColor3=Color3.fromRGB(240,240,244)
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Text="VISUALS PREVIEW"
    title.ZIndex=172
    title.Parent=header

    local sub=Instance.new("TextLabel")
    sub.BackgroundTransparency=1
    sub.Position=UDim2.fromOffset(18,21)
    sub.Size=UDim2.new(1,-26,0,16)
    sub.Font=Enum.Font.SourceSans
    sub.TextSize=10
    sub.TextColor3=Color3.fromRGB(137,142,160)
    sub.TextXAlignment=Enum.TextXAlignment.Left
    sub.Text="vitor250407 • DRAG"
    sub.ZIndex=172
    sub.Parent=header

    ------------------------------------------------------------------------
    -- Viewport + avatar.
    ------------------------------------------------------------------------
    local vp=Instance.new("ViewportFrame")
    vp.Position=UDim2.fromOffset(10,50)
    vp.Size=UDim2.new(1,-20,0,214)
    vp.BackgroundColor3=Color3.fromRGB(21,22,29)
    vp.BackgroundTransparency=.02
    vp.BorderSizePixel=0
    vp.Ambient=Color3.fromRGB(185,188,202)
    vp.LightColor=Color3.fromRGB(255,255,255)
    vp.LightDirection=Vector3.new(-1,-1,-1)
    vp.ZIndex=171
    vp.Parent=frame
    rounded(vp,6)

    local vignette=Instance.new("UIGradient")
    vignette.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(30,32,44)),
        ColorSequenceKeypoint.new(.5,Color3.fromRGB(19,20,28)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(12,13,18)),
    })
    vignette.Rotation=90
    vignette.Parent=vp

    local world=Instance.new("WorldModel")
    world.Parent=vp
    local cam=Instance.new("Camera")
    cam.FieldOfView=32
    cam.Parent=vp
    vp.CurrentCamera=cam

    local avatar=nil
    local avatarHighlight=nil
    local avatarOriginal=setmetatable({}, {__mode="k"})

    local function sanitizeModel(model)
        for _,d in ipairs(model:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") or d:IsA("Tool") then
                d:Destroy()
            elseif d:IsA("BasePart") then
                d.Anchored=true
                d.CanCollide=false
                d.CanTouch=false
                d.CastShadow=false
            end
        end
    end

    local function fitAvatar(model)
        local ok,cf,size=pcall(function() return model:GetBoundingBox() end)
        if not ok then
            cam.CFrame=CFrame.lookAt(Vector3.new(0,1.4,8),Vector3.new(0,1.4,0))
            return
        end
        model:PivotTo(CFrame.new(0,-cf.Position.Y+size.Y*.46,0)*CFrame.Angles(0,math.rad(180),0))
        local d=math.max(6.8,math.max(size.X,size.Y,size.Z)*1.82)
        cam.CFrame=CFrame.lookAt(Vector3.new(0,size.Y*.05,d),Vector3.new(0,size.Y*.04,0))
    end

    local function fallbackAvatar()
        local m=Instance.new("Model")
        m.Name="vitor250407_preview"
        local function p(name,size,pos,color)
            local x=Instance.new("Part")
            x.Name=name
            x.Size=size
            x.CFrame=CFrame.new(pos)
            x.Anchored=true
            x.CanCollide=false
            x.Color=color
            x.Material=Enum.Material.SmoothPlastic
            x.Parent=m
        end
        local skin=Color3.fromRGB(226,188,151)
        p("Head",Vector3.new(1.5,1.25,1.2),Vector3.new(0,3.1,0),skin)
        p("Torso",Vector3.new(2.15,2.1,1.05),Vector3.new(0,1.4,0),Color3.fromRGB(60,76,105))
        p("Left Arm",Vector3.new(.82,2.05,.86),Vector3.new(-1.5,1.4,0),skin)
        p("Right Arm",Vector3.new(.82,2.05,.86),Vector3.new(1.5,1.4,0),skin)
        p("Left Leg",Vector3.new(.92,2.15,.96),Vector3.new(-.58,-.75,0),Color3.fromRGB(31,35,43))
        p("Right Leg",Vector3.new(.92,2.15,.96),Vector3.new(.58,-.75,0),Color3.fromRGB(31,35,43))
        return m
    end

    local function loadAvatar()
        local model=nil
        local ok,userId=pcall(function()
            return Players:GetUserIdFromNameAsync("vitor250407")
        end)
        if ok and userId then
            local okDesc,desc=pcall(function()
                return Players:GetHumanoidDescriptionFromUserId(userId)
            end)
            if okDesc and desc then
                local okModel,result=pcall(function()
                    return Players:CreateHumanoidModelFromDescription(desc,Enum.HumanoidRigType.R15)
                end)
                if okModel then model=result end
            end
        end
        model=model or fallbackAvatar()
        model.Name="vitor250407_preview"
        sanitizeModel(model)
        model.Parent=world
        avatar=model
        fitAvatar(model)

        for _,d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") then
                avatarOriginal[d]={Color=d.Color,Material=d.Material,Transparency=d.Transparency}
            end
        end

        avatarHighlight=Instance.new("Highlight")
        avatarHighlight.Name="LvkHubPreviewChams"
        avatarHighlight.Adornee=model
        avatarHighlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
        avatarHighlight.FillTransparency=.62
        avatarHighlight.OutlineTransparency=.04
        avatarHighlight.Enabled=false
        avatarHighlight.Parent=world
    end
    task.spawn(loadAvatar)

    ------------------------------------------------------------------------
    -- Fixed preview overlay that mirrors enabled Visuals.
    ------------------------------------------------------------------------
    local overlay=Instance.new("Frame")
    overlay.Position=vp.Position
    overlay.Size=vp.Size
    overlay.BackgroundTransparency=1
    overlay.ZIndex=180
    overlay.Parent=frame

    local box=Instance.new("Frame")
    box.Position=UDim2.fromOffset(61,13)
    box.Size=UDim2.fromOffset(112,184)
    box.BackgroundTransparency=1
    box.BorderSizePixel=1
    box.Visible=false
    box.ZIndex=181
    box.Parent=overlay

    local function makeLine(name)
        local f=Instance.new("Frame")
        f.Name=name
        f.AnchorPoint=Vector2.new(.5,.5)
        f.BorderSizePixel=0
        f.Visible=false
        f.ZIndex=182
        f.Parent=overlay
        return f
    end
    local function setLine(f,a,b,w,color,trans)
        local d=b-a
        if d.Magnitude<.01 then f.Visible=false return end
        f.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
        f.Size=UDim2.fromOffset(d.Magnitude,w or 1)
        f.Rotation=math.deg(math.atan2(d.Y,d.X))
        f.BackgroundColor3=color
        f.BackgroundTransparency=math.clamp((trans or 0)/100,0,1)
        f.Visible=true
    end

    local corners={}
    for i=1,8 do corners[i]=makeLine("Corner"..i) end
    local skeleton={}
    for i=1,6 do skeleton[i]=makeLine("Bone"..i) end
    local tracer=makeLine("Tracer")

    local nameLabel=Instance.new("TextLabel")
    nameLabel.BackgroundTransparency=1
    nameLabel.Position=UDim2.fromOffset(30,2)
    nameLabel.Size=UDim2.fromOffset(174,18)
    nameLabel.Font=Enum.Font.Code
    nameLabel.TextSize=10
    nameLabel.TextStrokeTransparency=.15
    nameLabel.Text="vitor250407"
    nameLabel.Visible=false
    nameLabel.ZIndex=183
    nameLabel.Parent=overlay

    local distLabel=nameLabel:Clone()
    distLabel.Position=UDim2.fromOffset(73,194)
    distLabel.Size=UDim2.fromOffset(90,16)
    distLabel.TextSize=9
    distLabel.Text="25 studs"
    distLabel.Parent=overlay

    local hpBack=Instance.new("Frame")
    hpBack.Position=UDim2.fromOffset(54,13)
    hpBack.Size=UDim2.fromOffset(4,184)
    hpBack.BackgroundColor3=Color3.fromRGB(24,24,29)
    hpBack.BorderSizePixel=0
    hpBack.Visible=false
    hpBack.ZIndex=183
    hpBack.Parent=overlay
    local hpFill=Instance.new("Frame")
    hpFill.AnchorPoint=Vector2.new(0,1)
    hpFill.Position=UDim2.new(0,0,1,0)
    hpFill.Size=UDim2.fromScale(1,1)
    hpFill.BorderSizePixel=0
    hpFill.ZIndex=184
    hpFill.Parent=hpBack

    local info=Instance.new("TextLabel")
    info.Position=UDim2.fromOffset(12,272)
    info.Size=UDim2.new(1,-24,0,19)
    info.BackgroundTransparency=1
    info.Font=Enum.Font.SourceSansSemibold
    info.TextSize=12
    info.TextColor3=Color3.fromRGB(232,232,238)
    info.TextXAlignment=Enum.TextXAlignment.Left
    info.Text="vitor250407 • HP 100%"
    info.ZIndex=172
    info.Parent=frame

    local hpSlider=Instance.new("Frame")
    hpSlider.Position=UDim2.fromOffset(12,300)
    hpSlider.Size=UDim2.new(1,-24,0,8)
    hpSlider.BackgroundColor3=Color3.fromRGB(39,40,48)
    hpSlider.BorderSizePixel=0
    hpSlider.Active=true
    hpSlider.ZIndex=172
    hpSlider.Parent=frame
    rounded(hpSlider,4)
    local hpSliderFill=Instance.new("Frame")
    hpSliderFill.Size=UDim2.fromScale(1,1)
    hpSliderFill.BorderSizePixel=0
    hpSliderFill.ZIndex=173
    hpSliderFill.Parent=hpSlider
    rounded(hpSliderFill,4)

    local hint=Instance.new("TextLabel")
    hint.Position=UDim2.fromOffset(12,311)
    hint.Size=UDim2.new(1,-24,0,15)
    hint.BackgroundTransparency=1
    hint.Font=Enum.Font.SourceSans
    hint.TextSize=9
    hint.TextColor3=Color3.fromRGB(128,133,149)
    hint.TextXAlignment=Enum.TextXAlignment.Left
    hint.Text="drag HP • preview gradient"
    hint.ZIndex=172
    hint.Parent=frame

    local function healthColor(r)
        r=math.clamp(r,0,1)
        if r>=.5 then
            local t=(r-.5)/.5
            return Color3.new(1-t,1,0)
        end
        return Color3.new(1,r/.5,0)
    end

    local hpDragging=false
    local function hpFromX(x)
        local a=math.clamp((x-hpSlider.AbsolutePosition.X)/math.max(1,hpSlider.AbsoluteSize.X),0,1)
        State.Visuals.PreviewHealth=math.floor(a*100+.5)
    end
    hpSlider.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then hpDragging=true; hpFromX(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if hpDragging and i.UserInputType==Enum.UserInputType.MouseMovement then hpFromX(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then hpDragging=false end
    end)

    ------------------------------------------------------------------------
    -- Draggable header with viewport clamp on release.
    ------------------------------------------------------------------------
    local dragging=false
    local startMouse,startPos
    local function clampFrame()
        local v=Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
        local p=frame.AbsolutePosition
        local s=frame.AbsoluteSize
        local dx=math.clamp(p.X,4,math.max(4,v.X-s.X-4))-p.X
        local dy=math.clamp(p.Y,4,math.max(4,v.Y-38))-p.Y
        frame.Position=UDim2.new(frame.Position.X.Scale,frame.Position.X.Offset+dx,frame.Position.Y.Scale,frame.Position.Y.Offset+dy)
    end
    header.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
            startMouse=i.Position
            startPos=frame.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-startMouse
            frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 and dragging then
            dragging=false
            clampFrame()
        end
    end)

    local function updateCornerLines(color,trans)
        local l,r,t,b=61,173,13,197
        local cw,ch=28,34
        local pairs={
            {Vector2.new(l,t),Vector2.new(l+cw,t)},{Vector2.new(l,t),Vector2.new(l,t+ch)},
            {Vector2.new(r,t),Vector2.new(r-cw,t)},{Vector2.new(r,t),Vector2.new(r,t+ch)},
            {Vector2.new(l,b),Vector2.new(l+cw,b)},{Vector2.new(l,b),Vector2.new(l,b-ch)},
            {Vector2.new(r,b),Vector2.new(r-cw,b)},{Vector2.new(r,b),Vector2.new(r,b-ch)},
        }
        for i,p in ipairs(pairs) do setLine(corners[i],p[1],p[2],1.4,color,trans) end
    end

    local function updateSkeleton(color,trans)
        local pairs={
            {Vector2.new(117,45),Vector2.new(117,89)},
            {Vector2.new(117,89),Vector2.new(117,128)},
            {Vector2.new(117,78),Vector2.new(81,108)},
            {Vector2.new(117,78),Vector2.new(153,108)},
            {Vector2.new(117,128),Vector2.new(92,178)},
            {Vector2.new(117,128),Vector2.new(142,178)},
        }
        for i,p in ipairs(pairs) do setLine(skeleton[i],p[1],p[2],1.25,color,trans) end
    end

    local cleanupTimer=0
    RunService.RenderStepped:Connect(function(dt)
        frame.Visible=State.Visuals.Preview==true and UI.Main.Visible==true

        cleanupTimer+=dt
        if cleanupTimer>=1 then
            cleanupTimer=0
            purgeLegacy(frame)
        end
        if not frame.Visible then return end

        cfg=State.Visuals._V5Config or cfg
        accent.BackgroundColor3=cfg.PreviewAccent or UI.Accent

        local hp=math.clamp((tonumber(State.Visuals.PreviewHealth) or 100)/100,0,1)
        local hc=healthColor(hp)
        hpSliderFill.Size=UDim2.new(hp,0,1,0)
        hpSliderFill.BackgroundColor3=hc
        hpFill.Size=UDim2.new(1,0,hp,0)
        hpFill.BackgroundColor3=hc
        info.Text=string.format("vitor250407 • HP %d%%",math.floor(hp*100+.5))

        local esp=State.Visuals.ESP==true
        local espColor=cfg.ESPVisibleColor or Color3.fromRGB(55,235,95)
        local chamsColor=esp and espColor or (cfg.ChamsColor or UI.Accent)

        if avatarHighlight then
            avatarHighlight.Enabled=State.Visuals.Chams==true or esp
            avatarHighlight.FillColor=chamsColor
            avatarHighlight.OutlineColor=chamsColor
            avatarHighlight.FillTransparency=math.clamp((cfg.ChamsTransparency or 62)/100,0,1)
        end

        box.Visible=State.Visuals.Box3D==true
        box.BorderColor3=cfg.Box3DColor or UI.Accent
        box.BorderSizePixel=box.Visible and 1 or 0

        local cornerOn=State.Visuals.CornerBox==true or esp or State.Visuals.ThermalCorner==true
        if cornerOn then
            local c=esp and espColor or (State.Visuals.ThermalCorner and (cfg.ThermalColor or Color3.fromRGB(255,145,60)) or (cfg.CornerColor or Color3.new(1,1,1)))
            updateCornerLines(c,esp and cfg.ESPTransparency or cfg.CornerTransparency)
        else
            for _,x in ipairs(corners) do x.Visible=false end
        end

        if State.Visuals.Skeleton then
            updateSkeleton(cfg.SkeletonColor or Color3.new(1,1,1),cfg.SkeletonTransparency)
        else
            for _,x in ipairs(skeleton) do x.Visible=false end
        end

        if State.Visuals.Tracers then
            setLine(tracer,Vector2.new(117,214),Vector2.new(117,108),1.25,cfg.TracerColor or Color3.new(1,1,1),cfg.TracerTransparency)
        else tracer.Visible=false end

        local showName=State.Visuals.NameDistance==true or esp
        nameLabel.Visible=showName
        distLabel.Visible=showName
        nameLabel.TextColor3=esp and espColor or (cfg.NameColor or Color3.new(1,1,1))
        distLabel.TextColor3=nameLabel.TextColor3
        nameLabel.TextTransparency=math.clamp((cfg.NameTransparency or 0)/100,0,1)
        distLabel.TextTransparency=nameLabel.TextTransparency

        local showHP=State.Visuals.HealthBar==true or esp
        hpBack.Visible=showHP
        hpFill.Visible=showHP
    end)

    task.delay(.15,function() purgeLegacy(frame) end)
end
