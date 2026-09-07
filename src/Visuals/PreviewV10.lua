-- Deterministic Visuals Preview V10.
-- Preview-only mannequin; never inserted into Registry and never used by Combat.
return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")
    local Workspace=game:GetService("Workspace")

    local cfg=State.Visuals._V5Config or {}
    State.Visuals.PreviewHealth=tonumber(State.Visuals.PreviewHealth) or 100

    local function rounded(o,r)
        local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 5);c.Parent=o
    end

    for _,name in ipairs({"LvkHubVisualsDummyPreview","LvkHubUnifiedPreviewV3","LvkHubUnifiedPreviewV4","LvkHubUnifiedPreviewV5","LvkHubVisualPreview"}) do
        local old=UI.Gui:FindFirstChild(name)
        if old then old:Destroy() end
    end

    local frame=Instance.new("Frame")
    frame.Name="LvkHubVisualsDummyPreview"
    frame.Size=UDim2.fromOffset(254,332)
    frame.Position=UDim2.fromOffset(1400,220)
    frame.BackgroundColor3=Color3.fromRGB(14,15,20)
    frame.BorderSizePixel=0
    frame.Visible=false
    frame.ZIndex=170
    frame.Parent=UI.Gui
    rounded(frame,8)
    local outline=Instance.new("UIStroke");outline.Color=Color3.fromRGB(58,61,76);outline.Transparency=.08;outline.Parent=frame

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
    accent.Position=UDim2.fromOffset(8,10);accent.Size=UDim2.fromOffset(3,22);accent.BackgroundColor3=UI.Accent;accent.BorderSizePixel=0;accent.ZIndex=172;accent.Parent=header;rounded(accent,2)
    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1;title.Position=UDim2.fromOffset(18,3);title.Size=UDim2.new(1,-26,0,20);title.Font=Enum.Font.SourceSansSemibold;title.TextSize=14;title.TextColor3=Color3.fromRGB(240,240,244);title.TextXAlignment=Enum.TextXAlignment.Left;title.Text="VISUALS PREVIEW";title.ZIndex=172;title.Parent=header
    local sub=Instance.new("TextLabel")
    sub.BackgroundTransparency=1;sub.Position=UDim2.fromOffset(18,21);sub.Size=UDim2.new(1,-26,0,16);sub.Font=Enum.Font.SourceSans;sub.TextSize=10;sub.TextColor3=Color3.fromRGB(137,142,160);sub.TextXAlignment=Enum.TextXAlignment.Left;sub.Text="PREVIEW DUMMY / DRAG";sub.ZIndex=172;sub.Parent=header

    local vp=Instance.new("ViewportFrame")
    vp.Position=UDim2.fromOffset(10,50);vp.Size=UDim2.new(1,-20,0,214);vp.BackgroundColor3=Color3.fromRGB(20,21,28);vp.BorderSizePixel=0;vp.Ambient=Color3.fromRGB(220,220,228);vp.LightColor=Color3.fromRGB(255,255,255);vp.LightDirection=Vector3.new(-1,-1,-1);vp.ZIndex=171;vp.Parent=frame;rounded(vp,6)
    local vg=Instance.new("UIGradient")
    vg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(34,36,48)),ColorSequenceKeypoint.new(.55,Color3.fromRGB(19,20,28)),ColorSequenceKeypoint.new(1,Color3.fromRGB(11,12,17))});vg.Rotation=90;vg.Parent=vp

    local world=Instance.new("WorldModel");world.Parent=vp
    local cam=Instance.new("Camera");cam.FieldOfView=32;cam.Parent=vp;vp.CurrentCamera=cam

    local mannequin=Instance.new("Model");mannequin.Name="LvkHubPreviewMannequin";mannequin.Parent=world
    local skin=Color3.fromRGB(224,188,154)
    local shirt=Color3.fromRGB(71,84,116)
    local pants=Color3.fromRGB(28,31,39)
    local parts={}
    local function part(name,size,pos,color)
        local p=Instance.new("Part")
        p.Name=name;p.Size=size;p.CFrame=CFrame.new(pos);p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CastShadow=false;p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Parent=mannequin
        parts[name]=p
        return p
    end
    part("Head",Vector3.new(1.55,1.35,1.35),Vector3.new(0,3.05,0),skin)
    part("Torso",Vector3.new(2.15,2.1,1.05),Vector3.new(0,1.35,0),shirt)
    part("Left Arm",Vector3.new(.82,2.05,.86),Vector3.new(-1.5,1.35,0),skin)
    part("Right Arm",Vector3.new(.82,2.05,.86),Vector3.new(1.5,1.35,0),skin)
    part("Left Leg",Vector3.new(.94,2.15,.98),Vector3.new(-.58,-.78,0),pants)
    part("Right Leg",Vector3.new(.94,2.15,.98),Vector3.new(.58,-.78,0),pants)
    cam.CFrame=CFrame.lookAt(Vector3.new(0,1.25,8.4),Vector3.new(0,1.25,0))

    local chams=Instance.new("Highlight")
    chams.Name="LvkHubPreviewChams";chams.Adornee=mannequin;chams.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;chams.FillTransparency=.62;chams.OutlineTransparency=.04;chams.Enabled=false;chams.Parent=world

    local overlay=Instance.new("Frame")
    overlay.Position=vp.Position;overlay.Size=vp.Size;overlay.BackgroundTransparency=1;overlay.ZIndex=180;overlay.Parent=frame

    local function line(name)
        local f=Instance.new("Frame");f.Name=name;f.AnchorPoint=Vector2.new(.5,.5);f.BorderSizePixel=0;f.Visible=false;f.ZIndex=182;f.Parent=overlay;return f
    end
    local function setLine(f,a,b,w,color,trans)
        local d=b-a;if d.Magnitude<.01 then f.Visible=false return end
        f.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2);f.Size=UDim2.fromOffset(d.Magnitude,w or 1);f.Rotation=math.deg(math.atan2(d.Y,d.X));f.BackgroundColor3=color;f.BackgroundTransparency=math.clamp((trans or 0)/100,0,1);f.Visible=true
    end

    local box={};for i=1,8 do box[i]=line("Corner"..i) end
    local bones={};for i=1,5 do bones[i]=line("Bone"..i) end
    local tracer=line("Tracer")

    local nameLabel=Instance.new("TextLabel")
    nameLabel.BackgroundTransparency=1;nameLabel.Position=UDim2.fromOffset(40,2);nameLabel.Size=UDim2.fromOffset(154,18);nameLabel.Font=Enum.Font.Code;nameLabel.TextSize=10;nameLabel.TextStrokeTransparency=.15;nameLabel.Text="PREVIEW DUMMY";nameLabel.Visible=false;nameLabel.ZIndex=183;nameLabel.Parent=overlay
    local distLabel=nameLabel:Clone();distLabel.Position=UDim2.fromOffset(74,194);distLabel.Size=UDim2.fromOffset(90,16);distLabel.Text="25 studs";distLabel.Parent=overlay

    local hpBack=Instance.new("Frame")
    hpBack.Position=UDim2.fromOffset(48,16);hpBack.Size=UDim2.fromOffset(4,181);hpBack.BackgroundColor3=Color3.fromRGB(22,22,27);hpBack.BorderSizePixel=0;hpBack.Visible=false;hpBack.ZIndex=183;hpBack.Parent=overlay
    local hpFill=Instance.new("Frame");hpFill.AnchorPoint=Vector2.new(0,1);hpFill.Position=UDim2.new(0,0,1,0);hpFill.Size=UDim2.fromScale(1,1);hpFill.BorderSizePixel=0;hpFill.ZIndex=184;hpFill.Parent=hpBack

    local info=Instance.new("TextLabel")
    info.Position=UDim2.fromOffset(12,272);info.Size=UDim2.new(1,-24,0,19);info.BackgroundTransparency=1;info.Font=Enum.Font.SourceSansSemibold;info.TextSize=12;info.TextColor3=Color3.fromRGB(232,232,238);info.TextXAlignment=Enum.TextXAlignment.Left;info.Text="PREVIEW DUMMY / HP 100%";info.ZIndex=172;info.Parent=frame
    local hpSlider=Instance.new("Frame")
    hpSlider.Position=UDim2.fromOffset(12,300);hpSlider.Size=UDim2.new(1,-24,0,8);hpSlider.BackgroundColor3=Color3.fromRGB(39,40,48);hpSlider.BorderSizePixel=0;hpSlider.Active=true;hpSlider.ZIndex=172;hpSlider.Parent=frame;rounded(hpSlider,4)
    local hpSliderFill=Instance.new("Frame");hpSliderFill.Size=UDim2.fromScale(1,1);hpSliderFill.BorderSizePixel=0;hpSliderFill.ZIndex=173;hpSliderFill.Parent=hpSlider;rounded(hpSliderFill,4)
    local hint=Instance.new("TextLabel")
    hint.Position=UDim2.fromOffset(12,311);hint.Size=UDim2.new(1,-24,0,15);hint.BackgroundTransparency=1;hint.Font=Enum.Font.SourceSans;hint.TextSize=9;hint.TextColor3=Color3.fromRGB(128,133,149);hint.TextXAlignment=Enum.TextXAlignment.Left;hint.Text="drag HP / preview gradient";hint.ZIndex=172;hint.Parent=frame

    local function healthColor(r)
        r=math.clamp(r,0,1)
        if r>=.5 then local t=(r-.5)/.5;return Color3.new(1-t,1,0) end
        return Color3.new(1,r/.5,0)
    end

    local draggingHP=false
    local function hpFromX(x)
        local a=math.clamp((x-hpSlider.AbsolutePosition.X)/math.max(1,hpSlider.AbsoluteSize.X),0,1)
        State.Visuals.PreviewHealth=math.floor(a*100+.5)
    end
    hpSlider.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then draggingHP=true;hpFromX(i.Position.X) end end)
    UIS.InputChanged:Connect(function(i) if draggingHP and i.UserInputType==Enum.UserInputType.MouseMovement then hpFromX(i.Position.X) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then draggingHP=false end end)

    local dragging=false
    local startMouse,startPos
    header.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;startMouse=i.Position;startPos=frame.Position end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-startMouse
            local v=Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
            local x=math.clamp(startPos.X.Offset+d.X,0,math.max(0,v.X-frame.AbsoluteSize.X))
            local y=math.clamp(startPos.Y.Offset+d.Y,0,math.max(0,v.Y-38))
            frame.Position=UDim2.fromOffset(x,y)
        end
    end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)

    local function cornerBox(color,trans)
        local l,r,t,b=58,176,16,197
        local cw,ch=27,38
        local pairs={
            {Vector2.new(l,t),Vector2.new(l+cw,t)},{Vector2.new(l,t),Vector2.new(l,t+ch)},
            {Vector2.new(r,t),Vector2.new(r-cw,t)},{Vector2.new(r,t),Vector2.new(r,t+ch)},
            {Vector2.new(l,b),Vector2.new(l+cw,b)},{Vector2.new(l,b),Vector2.new(l,b-ch)},
            {Vector2.new(r,b),Vector2.new(r-cw,b)},{Vector2.new(r,b),Vector2.new(r,b-ch)},
        }
        for i,p in ipairs(pairs) do setLine(box[i],p[1],p[2],1,color,trans) end
    end

    RunService.RenderStepped:Connect(function()
        frame.Visible=State.Visuals.Preview==true and UI.Main.Visible==true
        if not frame.Visible then return end
        local hp=math.clamp((tonumber(State.Visuals.PreviewHealth) or 100)/100,0,1)
        local hpc=healthColor(hp)
        info.Text=string.format("PREVIEW DUMMY / HP %d%%",math.floor(hp*100+.5))
        hpSliderFill.Size=UDim2.new(hp,0,1,0);hpSliderFill.BackgroundColor3=hpc

        local esp=State.Visuals.ESP==true
        local ch=State.Visuals.Chams==true or esp
        chams.Enabled=ch
        if ch then
            local col=esp and (cfg.ESPVisibleColor or Color3.fromRGB(55,235,95)) or (cfg.ChamsColor or UI.Accent)
            chams.FillColor=col;chams.OutlineColor=col;chams.FillTransparency=math.clamp((cfg.ChamsTransparency or 62)/100,0,1)
        end

        local cornersOn=State.Visuals.CornerBox==true or esp or State.Visuals.ThermalCorner==true
        if cornersOn then
            local col=esp and (cfg.ESPVisibleColor or Color3.fromRGB(55,235,95)) or (State.Visuals.ThermalCorner and (cfg.ThermalColor or Color3.fromRGB(255,145,60)) or (cfg.CornerColor or Color3.new(1,1,1)))
            local tr=esp and (cfg.ESPTransparency or 0) or (cfg.CornerTransparency or 0)
            cornerBox(col,tr)
        else for _,x in ipairs(box) do x.Visible=false end end

        nameLabel.Visible=State.Visuals.NameDistance==true or esp
        distLabel.Visible=nameLabel.Visible
        if nameLabel.Visible then
            local col=esp and (cfg.ESPVisibleColor or Color3.fromRGB(55,235,95)) or (cfg.NameColor or Color3.new(1,1,1))
            nameLabel.TextColor3=col;distLabel.TextColor3=col
        end

        hpBack.Visible=State.Visuals.HealthBar==true or esp
        if hpBack.Visible then hpFill.Size=UDim2.new(1,0,hp,0);hpFill.BackgroundColor3=hpc end

        if State.Visuals.Tracers then setLine(tracer,Vector2.new(117,214),Vector2.new(117,108),1,cfg.TracerColor or Color3.new(1,1,1),cfg.TracerTransparency or 0) else tracer.Visible=false end

        local sk=State.Visuals.Skeleton==true
        if sk then
            local c=cfg.SkeletonColor or Color3.new(1,1,1);local tr=cfg.SkeletonTransparency or 0
            local pts={Vector2.new(117,48),Vector2.new(117,95),Vector2.new(81,113),Vector2.new(153,113),Vector2.new(96,169),Vector2.new(138,169)}
            setLine(bones[1],pts[1],pts[2],1,c,tr);setLine(bones[2],pts[2],pts[3],1,c,tr);setLine(bones[3],pts[2],pts[4],1,c,tr);setLine(bones[4],pts[2],pts[5],1,c,tr);setLine(bones[5],pts[2],pts[6],1,c,tr)
        else for _,x in ipairs(bones) do x.Visible=false end end
    end)
end
