-- Local practice overlay V2: dummy snapline + custom crosshair with pulse.
-- Custom crosshair also hides only the LocalPlayer's normal weapon reticle GUI.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local UIS=game:GetService("UserInputService")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Visuals

    State.Visuals.Snapline=State.Visuals.Snapline==true
    State.Visuals.CustomCrosshair=State.Visuals.CustomCrosshair==true
    local C=State.Visuals._PracticeOverlay or {
        SnapColor=Color3.fromRGB(119,120,255), SnapTransparency=0,
        CrossColor=Color3.fromRGB(255,255,255), CrossTransparency=0,
        CrossSize=8, CrossGap=5, Pulse=false, PulseSpeed=1.8, PulseAmount=.35,
    }
    C.Pulse=C.Pulse==true
    C.PulseSpeed=tonumber(C.PulseSpeed) or 1.8
    C.PulseAmount=tonumber(C.PulseAmount) or .35
    State.Visuals._PracticeOverlay=C

    local function rounded(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 4); c.Parent=o end
    local function makeLine(name)
        local f=Instance.new("Frame"); f.Name=name; f.AnchorPoint=Vector2.new(.5,.5); f.BorderSizePixel=0; f.Visible=false; f.ZIndex=180; f.Parent=UI.Gui; return f
    end
    local function setLine(f,a,b,width,color,trans)
        local d=b-a
        if d.Magnitude<.01 then f.Visible=false return end
        f.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
        f.Size=UDim2.fromOffset(d.Magnitude,width)
        f.Rotation=math.deg(math.atan2(d.Y,d.X))
        f.BackgroundColor3=color
        f.BackgroundTransparency=math.clamp((trans or 0)/100,0,1)
        f.Visible=true
    end

    local rainbow=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(1/6,Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(3/6,Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(5/6,Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0)),
    })

    local function popup(title,builder)
        local p=Instance.new("Frame")
        p.Name="LvkPracticeOverlayOptionsV2"; p.Size=UDim2.fromOffset(236,44); p.BackgroundColor3=Color3.fromRGB(17,18,22); p.BorderSizePixel=0; p.ZIndex=120; rounded(p,7)
        local st=Instance.new("UIStroke"); st.Color=Color3.fromRGB(65,67,80); st.Transparency=.12; st.Parent=p
        local ttl=Instance.new("TextLabel"); ttl.BackgroundTransparency=1; ttl.Position=UDim2.fromOffset(10,5); ttl.Size=UDim2.new(1,-42,0,28); ttl.Font=Enum.Font.SourceSansSemibold; ttl.TextSize=14; ttl.TextColor3=Color3.fromRGB(238,238,242); ttl.TextXAlignment=Enum.TextXAlignment.Left; ttl.Text=title; ttl.ZIndex=121; ttl.Parent=p
        local close=Instance.new("TextButton"); close.AnchorPoint=Vector2.new(1,0); close.Position=UDim2.new(1,-7,0,6); close.Size=UDim2.fromOffset(25,22); close.BackgroundColor3=Color3.fromRGB(34,35,42); close.BorderSizePixel=0; close.Text="×"; close.TextColor3=Color3.fromRGB(215,215,222); close.ZIndex=122; close.Parent=p; rounded(close,4)
        close.MouseButton1Click:Connect(function() if UI.CloseDockedPanel then UI.CloseDockedPanel(p) elseif p.Parent then p:Destroy() end end)
        local y=39
        local function base(label,h)
            h=h or 38
            local r=Instance.new("Frame"); r.Position=UDim2.fromOffset(7,y); r.Size=UDim2.new(1,-14,0,h); r.BackgroundColor3=Color3.fromRGB(27,28,34); r.BorderSizePixel=0; r.ZIndex=121; r.Parent=p; rounded(r,4)
            local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Position=UDim2.fromOffset(8,0); l.Size=UDim2.fromOffset(78,h); l.Font=Enum.Font.SourceSans; l.TextSize=12; l.TextColor3=Color3.fromRGB(222,222,228); l.TextXAlignment=Enum.TextXAlignment.Left; l.Text=label; l.ZIndex=122; l.Parent=r
            y+=h+5
            return r,l
        end
        local function color(label,get,set)
            local r,l=base(label); l.Size=UDim2.fromOffset(74,38)
            local bar=Instance.new("Frame"); bar.Position=UDim2.fromOffset(80,11); bar.Size=UDim2.new(1,-90,0,16); bar.BackgroundColor3=Color3.new(1,1,1); bar.BorderSizePixel=0; bar.Active=true; bar.ZIndex=123; bar.Parent=r; rounded(bar,4)
            local g=Instance.new("UIGradient"); g.Color=rainbow; g.Parent=bar
            local k=Instance.new("Frame"); k.AnchorPoint=Vector2.new(.5,.5); k.Size=UDim2.fromOffset(4,22); k.BackgroundColor3=Color3.fromRGB(248,248,250); k.BorderSizePixel=0; k.ZIndex=124; k.Parent=bar
            local drag=false
            local function paint() local h=select(1,get():ToHSV()); k.Position=UDim2.new(h,0,.5,0) end
            local function setX(x) local h=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1); set(Color3.fromHSV(h,1,1)); paint() end
            bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; setX(i.Position.X) end end)
            UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then setX(i.Position.X) end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end); paint()
        end
        local function slider(label,get,set,min,max,step)
            local r,l=base(label); l.Size=UDim2.fromOffset(76,38)
            local bar=Instance.new("Frame"); bar.Position=UDim2.fromOffset(82,16); bar.Size=UDim2.new(1,-137,0,6); bar.BackgroundColor3=Color3.fromRGB(43,44,51); bar.BorderSizePixel=0; bar.Active=true; bar.ZIndex=123; bar.Parent=r; rounded(bar,3)
            local fill=Instance.new("Frame"); fill.BackgroundColor3=UI.Accent; fill.BorderSizePixel=0; fill.ZIndex=124; fill.Parent=bar; rounded(fill,3)
            local k=Instance.new("Frame"); k.AnchorPoint=Vector2.new(.5,.5); k.Size=UDim2.fromOffset(10,16); k.BackgroundColor3=Color3.fromRGB(242,242,245); k.BorderSizePixel=0; k.ZIndex=125; k.Parent=bar; rounded(k,5)
            local val=Instance.new("TextLabel"); val.AnchorPoint=Vector2.new(1,.5); val.Position=UDim2.new(1,-7,.5,0); val.Size=UDim2.fromOffset(44,20); val.BackgroundColor3=Color3.fromRGB(35,36,43); val.BorderSizePixel=0; val.Font=Enum.Font.Code; val.TextSize=9; val.TextColor3=Color3.fromRGB(220,220,228); val.ZIndex=124; val.Parent=r; rounded(val,3)
            local drag=false
            local function paint() local n=math.clamp(tonumber(get()) or min,min,max); local a=(n-min)/(max-min); fill.Size=UDim2.new(a,0,1,0); k.Position=UDim2.new(a,0,.5,0); val.Text=step<1 and string.format("%.2f",n) or tostring(math.floor(n+.5)) end
            local function setX(x) local a=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1); local n=min+(max-min)*a; n=math.floor(n/step+.5)*step; set(math.clamp(n,min,max)); paint() end
            bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; setX(i.Position.X) end end)
            k.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; setX(i.Position.X) end end)
            UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then setX(i.Position.X) end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end); paint()
        end
        local function toggle(label,get,set)
            local r,l=base(label,31); l.Size=UDim2.new(1,-50,1,0)
            local b=Instance.new("TextButton"); b.AnchorPoint=Vector2.new(1,.5); b.Position=UDim2.new(1,-7,.5,0); b.Size=UDim2.fromOffset(34,18); b.Text=""; b.BorderSizePixel=0; b.ZIndex=123; b.Parent=r; rounded(b,3)
            local function paint() b.BackgroundColor3=get() and UI.Accent or Color3.fromRGB(48,49,57) end
            b.MouseButton1Click:Connect(function() set(not get()); paint() end); paint()
        end
        builder({Color=color,Slider=slider,Toggle=toggle})
        p.Size=UDim2.fromOffset(236,y+3)
        if UI.OpenDockedPanel then UI.OpenDockedPanel(p) else p.Parent=UI.Gui end
    end

    local function rowWithDots(label,get,set,onDots)
        local r,t=UI.Row(page,label); t.Size=UDim2.new(1,-78,1,0); t.Active=true
        local dots=Instance.new("TextButton"); dots.AnchorPoint=Vector2.new(1,.5); dots.Position=UDim2.new(1,-44,.5,0); dots.Size=UDim2.fromOffset(26,20); dots.BackgroundColor3=Color3.fromRGB(34,34,40); dots.BorderSizePixel=0; dots.Font=Enum.Font.SourceSansBold; dots.TextSize=15; dots.TextColor3=Color3.fromRGB(195,195,205); dots.Text="•••"; dots.Parent=r; rounded(dots,4)
        local b=Instance.new("TextButton"); b.AnchorPoint=Vector2.new(1,.5); b.Position=UDim2.new(1,-7,.5,0); b.Size=UDim2.fromOffset(28,18); b.Text=""; b.BorderSizePixel=0; b.Parent=r; rounded(b,3)
        local mark=Instance.new("Frame"); mark.AnchorPoint=Vector2.new(.5,.5); mark.Position=UDim2.fromScale(.5,.5); mark.Size=UDim2.fromOffset(18,10); mark.BorderSizePixel=0; mark.Parent=b; rounded(mark,2)
        local function paint() local on=get(); b.BackgroundColor3=on and UI.Accent or Color3.fromRGB(45,45,45); mark.BackgroundColor3=on and Color3.fromRGB(238,238,240) or Color3.fromRGB(86,86,86) end
        local function flip() set(not get()); paint() end
        b.MouseButton1Click:Connect(flip); t.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then flip() end end); dots.MouseButton1Click:Connect(onDots); paint()
    end

    UI.Section(page,"Practice Overlay")
    rowWithDots("Snapline",function() return State.Visuals.Snapline end,function(v) State.Visuals.Snapline=v end,function()
        popup("Snapline",function(o)
            o.Color("Color",function() return C.SnapColor end,function(v) C.SnapColor=v end)
            o.Slider("Transp.",function() return C.SnapTransparency end,function(v) C.SnapTransparency=v end,0,100,1)
        end)
    end)
    rowWithDots("Custom Crosshair",function() return State.Visuals.CustomCrosshair end,function(v) State.Visuals.CustomCrosshair=v end,function()
        popup("Custom Crosshair",function(o)
            o.Color("Color",function() return C.CrossColor end,function(v) C.CrossColor=v end)
            o.Slider("Transp.",function() return C.CrossTransparency end,function(v) C.CrossTransparency=v end,0,100,1)
            o.Slider("Size",function() return C.CrossSize end,function(v) C.CrossSize=v end,3,30,1)
            o.Slider("Gap",function() return C.CrossGap end,function(v) C.CrossGap=v end,0,24,1)
            o.Toggle("Pulse",function() return C.Pulse end,function(v) C.Pulse=v end)
            o.Slider("Pulse Speed",function() return C.PulseSpeed end,function(v) C.PulseSpeed=v end,.4,5,.1)
            o.Slider("Pulse Amt.",function() return C.PulseAmount end,function(v) C.PulseAmount=v end,.05,.8,.05)
        end)
    end)

    local snap=makeLine("LvkHubPracticeSnaplineV2")
    local cross={makeLine("LvkCrossL2"),makeLine("LvkCrossR2"),makeLine("LvkCrossT2"),makeLine("LvkCrossB2")}

    local hidden=setmetatable({}, {__mode="k"})
    local function isReticle(obj)
        local n=string.lower(obj.Name or "")
        if n:find("crosshair",1,true) or n:find("cross_hair",1,true) or n:find("reticle",1,true) then return true end
        local ok,path=pcall(function() return string.lower(obj:GetFullName()) end)
        return ok and (path:find("crosshair",1,true)~=nil or path:find("reticle",1,true)~=nil)
    end
    local function hideDefault(obj)
        if not State.Visuals.CustomCrosshair or not obj or not isReticle(obj) then return end
        if obj:IsA("GuiObject") then
            if hidden[obj]==nil then hidden[obj]={kind="Visible",value=obj.Visible} end
            obj.Visible=false
        elseif obj:IsA("ScreenGui") then
            if hidden[obj]==nil then hidden[obj]={kind="Enabled",value=obj.Enabled} end
            obj.Enabled=false
        end
    end
    local function scanReticle()
        local pg=LP:FindFirstChild("PlayerGui")
        if not pg then return end
        for _,o in ipairs(pg:GetDescendants()) do hideDefault(o) end
    end
    local function restoreReticle()
        for o,s in pairs(hidden) do
            if o and o.Parent then pcall(function() o[s.kind]=s.value end) end
            hidden[o]=nil
        end
    end
    local pg=LP:FindFirstChild("PlayerGui")
    if pg then pg.DescendantAdded:Connect(function(o) if State.Visuals.CustomCrosshair then task.defer(hideDefault,o) end end) end

    local lastCustom=false
    local reticleTimer=0
    RunService.RenderStepped:Connect(function(dt)
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local m=State.Combat and State.Combat.SelectedBot
        local p=m and Registry.IsBot(m) and (m:FindFirstChild("Head") or Registry.RootOf(m)) or nil
        if State.Visuals.Snapline and p then
            local sp,on=cam:WorldToViewportPoint(p.Position)
            if on and sp.Z>0 then setLine(snap,cam.ViewportSize/2,Vector2.new(sp.X,sp.Y),1.25,C.SnapColor,C.SnapTransparency) else snap.Visible=false end
        else snap.Visible=false end

        if State.Visuals.CustomCrosshair then
            local center=cam.ViewportSize/2
            local factor=1
            if C.Pulse then factor=1+math.sin(os.clock()*math.pi*2*C.PulseSpeed)*C.PulseAmount end
            local s=math.max(1,C.CrossSize*factor)
            local g=math.max(0,C.CrossGap*factor)
            setLine(cross[1],Vector2.new(center.X-g-s,center.Y),Vector2.new(center.X-g,center.Y),1.5,C.CrossColor,C.CrossTransparency)
            setLine(cross[2],Vector2.new(center.X+g,center.Y),Vector2.new(center.X+g+s,center.Y),1.5,C.CrossColor,C.CrossTransparency)
            setLine(cross[3],Vector2.new(center.X,center.Y-g-s),Vector2.new(center.X,center.Y-g),1.5,C.CrossColor,C.CrossTransparency)
            setLine(cross[4],Vector2.new(center.X,center.Y+g),Vector2.new(center.X,center.Y+g+s),1.5,C.CrossColor,C.CrossTransparency)
        else
            for _,f in ipairs(cross) do f.Visible=false end
        end

        if State.Visuals.CustomCrosshair~=lastCustom then
            lastCustom=State.Visuals.CustomCrosshair
            if lastCustom then scanReticle() else restoreReticle() end
        end
        reticleTimer+=dt
        if lastCustom and reticleTimer>=.18 then reticleTimer=0; scanReticle() end
    end)
end
