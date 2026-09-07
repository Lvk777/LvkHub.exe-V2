-- Local practice overlay for Workspace.TestPlayers only: snapline, target focus and custom crosshair.
return function(State, Registry, UI)
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local UIS=game:GetService("UserInputService")

    State.Visuals.Snapline=State.Visuals.Snapline==true
    State.Visuals.CustomCrosshair=State.Visuals.CustomCrosshair==true
    local C=State.Visuals._PracticeOverlay or {
        SnapColor=Color3.fromRGB(119,120,255), SnapTransparency=0, SnapThickness=1.25,
        CrossColor=Color3.fromRGB(150,255,65), CrossTransparency=0,
        CrossSize=9, CrossGap=5, CrossRotating=false, CrossRotationSpeed=90,
        CrossText=false,
    }
    C.SnapThickness=tonumber(C.SnapThickness) or 1.25
    C.CrossRotating=C.CrossRotating==true
    C.CrossRotationSpeed=tonumber(C.CrossRotationSpeed) or 90
    C.CrossText=C.CrossText==true
    State.Visuals._PracticeOverlay=C

    local function rounded(o,r)
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,r or 4)
        c.Parent=o
    end

    local function makeLine(name,parent)
        local f=Instance.new("Frame")
        f.Name=name
        f.AnchorPoint=Vector2.new(.5,.5)
        f.BorderSizePixel=0
        f.Visible=false
        f.ZIndex=150
        f.Parent=parent or UI.Gui
        return f
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

    ------------------------------------------------------------------------
    -- Docked option popup helpers.
    ------------------------------------------------------------------------
    local activePopup=nil
    local rainbow=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(1/6,Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6,Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(3/6,Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6,Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(5/6,Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0)),
    })

    local function closePopup()
        if not activePopup then return end
        if UI.CloseDockedPanel and UI.ActiveDockedPanel==activePopup then
            UI.CloseDockedPanel(activePopup)
        elseif activePopup.Parent then
            activePopup:Destroy()
        end
        activePopup=nil
    end

    local function openPopup(title,builder)
        closePopup()
        local p=Instance.new("Frame")
        p.Name="LvkPracticeOverlayOptions"
        p.Size=UDim2.fromOffset(236,44)
        p.BackgroundColor3=Color3.fromRGB(17,18,22)
        p.BorderSizePixel=0
        p.ZIndex=120
        rounded(p,7)
        local stroke=Instance.new("UIStroke")
        stroke.Color=Color3.fromRGB(65,67,80)
        stroke.Transparency=.12
        stroke.Parent=p

        local titleLabel=Instance.new("TextLabel")
        titleLabel.BackgroundTransparency=1
        titleLabel.Position=UDim2.fromOffset(10,5)
        titleLabel.Size=UDim2.new(1,-42,0,28)
        titleLabel.Font=Enum.Font.SourceSansSemibold
        titleLabel.TextSize=14
        titleLabel.TextColor3=Color3.fromRGB(238,238,242)
        titleLabel.TextXAlignment=Enum.TextXAlignment.Left
        titleLabel.Text=title
        titleLabel.ZIndex=121
        titleLabel.Parent=p

        local close=Instance.new("TextButton")
        close.AnchorPoint=Vector2.new(1,0)
        close.Position=UDim2.new(1,-7,0,6)
        close.Size=UDim2.fromOffset(25,22)
        close.BackgroundColor3=Color3.fromRGB(34,35,42)
        close.BorderSizePixel=0
        close.Text="×"
        close.Font=Enum.Font.SourceSansBold
        close.TextSize=16
        close.TextColor3=Color3.fromRGB(215,215,222)
        close.ZIndex=122
        close.Parent=p
        rounded(close,4)
        close.MouseButton1Click:Connect(closePopup)

        local y=39
        local function baseRow(label,h)
            h=h or 31
            local r=Instance.new("Frame")
            r.Position=UDim2.fromOffset(7,y)
            r.Size=UDim2.new(1,-14,0,h)
            r.BackgroundColor3=Color3.fromRGB(27,28,34)
            r.BorderSizePixel=0
            r.ZIndex=121
            r.Parent=p
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
            l.ZIndex=122
            l.Parent=r
            y+=h+5
            return r,l
        end

        local function color(label,get,set)
            local r,l=baseRow(label,38)
            l.Size=UDim2.fromOffset(74,38)
            local bar=Instance.new("Frame")
            bar.Position=UDim2.fromOffset(80,11)
            bar.Size=UDim2.new(1,-90,0,16)
            bar.BackgroundColor3=Color3.new(1,1,1)
            bar.BorderSizePixel=0
            bar.Active=true
            bar.ZIndex=123
            bar.Parent=r
            rounded(bar,4)
            local grad=Instance.new("UIGradient")
            grad.Color=rainbow
            grad.Parent=bar
            local knob=Instance.new("Frame")
            knob.AnchorPoint=Vector2.new(.5,.5)
            knob.Size=UDim2.fromOffset(4,22)
            knob.BackgroundColor3=Color3.fromRGB(248,248,250)
            knob.BorderSizePixel=0
            knob.ZIndex=124
            knob.Parent=bar
            local ks=Instance.new("UIStroke")
            ks.Color=Color3.fromRGB(20,20,24)
            ks.Parent=knob
            local dragging=false
            local function paint()
                local c=get()
                local h=typeof(c)=="Color3" and select(1,c:ToHSV()) or 0
                knob.Position=UDim2.new(h,0,.5,0)
            end
            local function fromX(x)
                local h=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1)
                set(Color3.fromHSV(h,1,1))
                knob.Position=UDim2.new(h,0,.5,0)
            end
            bar.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; fromX(i.Position.X) end
            end)
            UIS.InputChanged:Connect(function(i)
                if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then fromX(i.Position.X) end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
            end)
            paint()
        end

        local function slider(label,get,set,min,max,step)
            local r,l=baseRow(label,38)
            l.Size=UDim2.fromOffset(82,38)
            local bar=Instance.new("Frame")
            bar.Position=UDim2.fromOffset(88,16)
            bar.Size=UDim2.new(1,-143,0,6)
            bar.BackgroundColor3=Color3.fromRGB(43,44,51)
            bar.BorderSizePixel=0
            bar.Active=true
            bar.ZIndex=123
            bar.Parent=r
            rounded(bar,3)
            local fill=Instance.new("Frame")
            fill.BackgroundColor3=UI.Accent
            fill.BorderSizePixel=0
            fill.ZIndex=124
            fill.Parent=bar
            rounded(fill,3)
            local knob=Instance.new("Frame")
            knob.AnchorPoint=Vector2.new(.5,.5)
            knob.Size=UDim2.fromOffset(10,16)
            knob.BackgroundColor3=Color3.fromRGB(242,242,245)
            knob.BorderSizePixel=0
            knob.ZIndex=125
            knob.Parent=bar
            rounded(knob,5)
            local val=Instance.new("TextLabel")
            val.AnchorPoint=Vector2.new(1,.5)
            val.Position=UDim2.new(1,-7,.5,0)
            val.Size=UDim2.fromOffset(44,20)
            val.BackgroundColor3=Color3.fromRGB(35,36,43)
            val.BorderSizePixel=0
            val.Font=Enum.Font.Code
            val.TextSize=9
            val.TextColor3=Color3.fromRGB(220,220,228)
            val.ZIndex=124
            val.Parent=r
            rounded(val,3)
            local dragging=false
            step=step or 1
            local function paint()
                local n=math.clamp(tonumber(get()) or min,min,max)
                local a=(n-min)/math.max(max-min,1e-6)
                fill.Size=UDim2.new(a,0,1,0)
                knob.Position=UDim2.new(a,0,.5,0)
                val.Text=step<1 and string.format("%.2f",n) or tostring(math.floor(n+.5))
            end
            local function fromX(x)
                local a=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1)
                local n=min+(max-min)*a
                n=math.floor(n/step+.5)*step
                set(math.clamp(n,min,max))
                paint()
            end
            bar.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; fromX(i.Position.X) end
            end)
            knob.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; fromX(i.Position.X) end
            end)
            UIS.InputChanged:Connect(function(i)
                if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then fromX(i.Position.X) end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
            end)
            paint()
        end

        local function toggle(label,get,set)
            local r,l=baseRow(label)
            l.Size=UDim2.new(1,-50,1,0)
            local b=Instance.new("TextButton")
            b.AnchorPoint=Vector2.new(1,.5)
            b.Position=UDim2.new(1,-7,.5,0)
            b.Size=UDim2.fromOffset(34,18)
            b.Text=""
            b.BorderSizePixel=0
            b.AutoButtonColor=false
            b.ZIndex=123
            b.Parent=r
            rounded(b,3)
            local function paint() b.BackgroundColor3=get() and UI.Accent or Color3.fromRGB(48,49,57) end
            b.MouseButton1Click:Connect(function() set(not get()); paint() end)
            paint()
        end

        builder({Color=color,Slider=slider,Toggle=toggle})
        p.Size=UDim2.fromOffset(236,y+3)
        activePopup=p
        if UI.OpenDockedPanel then UI.OpenDockedPanel(p) else p.Parent=UI.Gui end
    end

    local function optionToggle(label,get,set,onDots)
        local row,text=UI.Row(UI.Pages.Visuals,label)
        text.Size=UDim2.new(1,-78,1,0)
        text.Active=true
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
        dots.Parent=row
        rounded(dots,4)
        local b=Instance.new("TextButton")
        b.AnchorPoint=Vector2.new(1,.5)
        b.Position=UDim2.new(1,-7,.5,0)
        b.Size=UDim2.fromOffset(28,18)
        b.Text=""
        b.BorderSizePixel=0
        b.AutoButtonColor=false
        b.Parent=row
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
        text.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then flip() end end)
        dots.MouseButton1Click:Connect(onDots)
        paint()
    end

    UI.Section(UI.Pages.Visuals,"Practice Overlay")
    optionToggle("Snapline",function() return State.Visuals.Snapline end,function(v) State.Visuals.Snapline=v end,function()
        openPopup("Snapline",function(o)
            o.Color("Color",function() return C.SnapColor end,function(v) C.SnapColor=v end)
            o.Slider("Transp.",function() return C.SnapTransparency end,function(v) C.SnapTransparency=v end,0,100,1)
            o.Slider("Thickness",function() return C.SnapThickness end,function(v) C.SnapThickness=v end,.5,5,.1)
        end)
    end)
    optionToggle("Custom Crosshair",function() return State.Visuals.CustomCrosshair end,function(v) State.Visuals.CustomCrosshair=v end,function()
        openPopup("Custom Crosshair",function(o)
            o.Color("Color",function() return C.CrossColor end,function(v) C.CrossColor=v end)
            o.Slider("Transp.",function() return C.CrossTransparency end,function(v) C.CrossTransparency=v end,0,100,1)
            o.Slider("Size",function() return C.CrossSize end,function(v) C.CrossSize=v end,3,30,1)
            o.Slider("Gap",function() return C.CrossGap end,function(v) C.CrossGap=v end,0,20,1)
            o.Toggle("Rotate",function() return C.CrossRotating end,function(v) C.CrossRotating=v end)
            o.Slider("Rotate Speed",function() return C.CrossRotationSpeed end,function(v) C.CrossRotationSpeed=v end,10,360,5)
            o.Toggle("Show Lvk.exe",function() return C.CrossText end,function(v) C.CrossText=v end)
        end)
    end)

    ------------------------------------------------------------------------
    -- Runtime visuals.
    ------------------------------------------------------------------------
    local snap=makeLine("LvkHubPracticeSnapline")

    local crossRoot=Instance.new("Frame")
    crossRoot.Name="LvkHubCrosshairRoot"
    crossRoot.AnchorPoint=Vector2.new(.5,.5)
    crossRoot.Size=UDim2.fromOffset(100,100)
    crossRoot.BackgroundTransparency=1
    crossRoot.Visible=false
    crossRoot.ZIndex=150
    crossRoot.Parent=UI.Gui
    local cross={}
    for i=1,4 do
        local arm=Instance.new("Frame")
        arm.Name="Arm"..i
        arm.BorderSizePixel=0
        arm.ZIndex=151
        arm.Parent=crossRoot
        cross[i]=arm
    end
    local crossText=Instance.new("TextLabel")
    crossText.Name="LvkHubCrosshairText"
    crossText.AnchorPoint=Vector2.new(.5,0)
    crossText.Size=UDim2.fromOffset(110,18)
    crossText.BackgroundTransparency=1
    crossText.Font=Enum.Font.Code
    crossText.TextSize=13
    crossText.TextStrokeTransparency=.25
    crossText.Text="Lvk.exe"
    crossText.Visible=false
    crossText.ZIndex=151
    crossText.Parent=UI.Gui

    local focus=nil
    local focusModel=nil
    local rotation=0

    local function currentTarget()
        local m=State.Combat and State.Combat.SelectedBot or nil
        if m and Registry.IsBot(m) then
            local p=m:FindFirstChild("Head") or Registry.RootOf(m)
            return m,p
        end
        return nil,nil
    end

    local function combatTargetActive()
        return State.Combat and (State.Combat.Aimbot or State.Combat.SilentAim or State.Combat.MagicBullets or State.Combat.HitBoxes)
    end

    RunService.RenderStepped:Connect(function(dt)
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local m,p=currentTarget()
        local blue=combatTargetActive() and m~=nil

        if focusModel~=m then if focus then focus:Destroy(); focus=nil end; focusModel=m end
        if blue and m and Registry.IsBot(m) then
            if not focus then
                focus=Instance.new("Highlight")
                focus.Name="LvkHubPracticeTargetBlue"
                focus.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                focus.FillTransparency=.84
                focus.OutlineTransparency=0
                focus.Parent=m
            end
            focus.Adornee=m
            focus.FillColor=UI.Accent
            focus.OutlineColor=UI.Accent
            focus.Enabled=true
        elseif focus then
            focus.Enabled=false
        end

        if State.Visuals.Snapline and m and p then
            local sp,on=cam:WorldToViewportPoint(p.Position)
            if on and sp.Z>0 then
                setLine(snap,cam.ViewportSize/2,Vector2.new(sp.X,sp.Y),C.SnapThickness,C.SnapColor,C.SnapTransparency)
            else
                snap.Visible=false
            end
        else
            snap.Visible=false
        end

        local center=cam.ViewportSize/2
        crossRoot.Position=UDim2.fromOffset(center.X,center.Y)
        if State.Visuals.CustomCrosshair then
            crossRoot.Visible=true
            local size=math.max(3,C.CrossSize)
            local gap=math.max(0,C.CrossGap)
            local col=C.CrossColor
            local tr=math.clamp(C.CrossTransparency/100,0,1)
            local thick=2

            cross[1].AnchorPoint=Vector2.new(1,.5)
            cross[1].Position=UDim2.fromOffset(50-gap,50)
            cross[1].Size=UDim2.fromOffset(size,thick)
            cross[2].AnchorPoint=Vector2.new(0,.5)
            cross[2].Position=UDim2.fromOffset(50+gap,50)
            cross[2].Size=UDim2.fromOffset(size,thick)
            cross[3].AnchorPoint=Vector2.new(.5,1)
            cross[3].Position=UDim2.fromOffset(50,50-gap)
            cross[3].Size=UDim2.fromOffset(thick,size)
            cross[4].AnchorPoint=Vector2.new(.5,0)
            cross[4].Position=UDim2.fromOffset(50,50+gap)
            cross[4].Size=UDim2.fromOffset(thick,size)
            for _,arm in ipairs(cross) do
                arm.BackgroundColor3=col
                arm.BackgroundTransparency=tr
            end

            if C.CrossRotating then
                rotation=(rotation+dt*C.CrossRotationSpeed)%360
                crossRoot.Rotation=rotation
            else
                crossRoot.Rotation=0
                rotation=0
            end

            crossText.Position=UDim2.fromOffset(center.X,center.Y+gap+size+8)
            crossText.TextColor3=col
            crossText.TextTransparency=tr
            crossText.Visible=C.CrossText==true
        else
            crossRoot.Visible=false
            crossText.Visible=false
        end
    end)
end
