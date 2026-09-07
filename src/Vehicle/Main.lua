-- Vehicle-only controls. Car ESP rendering is owned by UnifiedTestVisualsV5.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")
    local Workspace=game:GetService("Workspace")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Vehicle
    if not page then return end

    local cfg=State.Visuals._V5Config or {}
    State.Visuals._V5Config=cfg
    cfg.CarColor=cfg.CarColor or Color3.fromRGB(60,220,180)
    cfg.CarTransparency=tonumber(cfg.CarTransparency) or 84

    local function rounded(o,r)
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,r or 4)
        c.Parent=o
    end

    local rainbow=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(1/6,Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6,Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(3/6,Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6,Color3.fromRGB(0,0,255)),
        ColorSequenceKeypoint.new(5/6,Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0)),
    })

    local function openCarOptions()
        local p=Instance.new("Frame")
        p.Name="LvkVehicleCarESPOptions"
        p.Size=UDim2.fromOffset(236,132)
        p.BackgroundColor3=Color3.fromRGB(17,18,22)
        p.BorderSizePixel=0
        p.ZIndex=140
        rounded(p,7)
        local ps=Instance.new("UIStroke");ps.Color=Color3.fromRGB(65,67,80);ps.Transparency=.12;ps.Parent=p

        local title=Instance.new("TextLabel")
        title.BackgroundTransparency=1
        title.Position=UDim2.fromOffset(10,5)
        title.Size=UDim2.new(1,-42,0,28)
        title.Font=Enum.Font.SourceSansSemibold
        title.TextSize=14
        title.TextColor3=Color3.fromRGB(238,238,242)
        title.TextXAlignment=Enum.TextXAlignment.Left
        title.Text="Car ESP"
        title.ZIndex=141
        title.Parent=p

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
        close.ZIndex=142
        close.Parent=p
        rounded(close,4)
        close.MouseButton1Click:Connect(function()
            if UI.CloseDockedPanel then UI.CloseDockedPanel(p) elseif p.Parent then p:Destroy() end
        end)

        local cr=Instance.new("Frame")
        cr.Position=UDim2.fromOffset(7,39)
        cr.Size=UDim2.new(1,-14,0,38)
        cr.BackgroundColor3=Color3.fromRGB(27,28,34)
        cr.BorderSizePixel=0
        cr.ZIndex=141
        cr.Parent=p
        rounded(cr,4)
        local cl=Instance.new("TextLabel")
        cl.BackgroundTransparency=1;cl.Position=UDim2.fromOffset(8,0);cl.Size=UDim2.fromOffset(70,38)
        cl.Font=Enum.Font.SourceSans;cl.TextSize=12;cl.TextColor3=Color3.fromRGB(222,222,228);cl.TextXAlignment=Enum.TextXAlignment.Left;cl.Text="Color";cl.ZIndex=142;cl.Parent=cr
        local cb=Instance.new("Frame")
        cb.Position=UDim2.fromOffset(78,11);cb.Size=UDim2.new(1,-88,0,16);cb.BackgroundColor3=Color3.new(1,1,1);cb.BorderSizePixel=0;cb.Active=true;cb.ZIndex=143;cb.Parent=cr
        rounded(cb,4)
        local grad=Instance.new("UIGradient");grad.Color=rainbow;grad.Parent=cb
        local ck=Instance.new("Frame")
        ck.AnchorPoint=Vector2.new(.5,.5);ck.Size=UDim2.fromOffset(4,22);ck.BackgroundColor3=Color3.fromRGB(248,248,250);ck.BorderSizePixel=0;ck.ZIndex=144;ck.Parent=cb
        local cks=Instance.new("UIStroke");cks.Color=Color3.fromRGB(20,20,24);cks.Parent=ck
        ck.Position=UDim2.new(select(1,cfg.CarColor:ToHSV()),0,.5,0)
        local cd=false
        local function colorX(x)
            local h=math.clamp((x-cb.AbsolutePosition.X)/math.max(1,cb.AbsoluteSize.X),0,1)
            cfg.CarColor=Color3.fromHSV(h,1,1)
            ck.Position=UDim2.new(h,0,.5,0)
        end
        cb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then cd=true;colorX(i.Position.X) end end)
        UIS.InputChanged:Connect(function(i) if cd and i.UserInputType==Enum.UserInputType.MouseMovement then colorX(i.Position.X) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then cd=false end end)

        local sr=Instance.new("Frame")
        sr.Position=UDim2.fromOffset(7,82)
        sr.Size=UDim2.new(1,-14,0,38)
        sr.BackgroundColor3=Color3.fromRGB(27,28,34)
        sr.BorderSizePixel=0
        sr.ZIndex=141
        sr.Parent=p
        rounded(sr,4)
        local sl=Instance.new("TextLabel")
        sl.BackgroundTransparency=1;sl.Position=UDim2.fromOffset(8,0);sl.Size=UDim2.fromOffset(78,38)
        sl.Font=Enum.Font.SourceSans;sl.TextSize=12;sl.TextColor3=Color3.fromRGB(222,222,228);sl.TextXAlignment=Enum.TextXAlignment.Left;sl.Text="Transp.";sl.ZIndex=142;sl.Parent=sr
        local bar=Instance.new("Frame")
        bar.Position=UDim2.fromOffset(84,16);bar.Size=UDim2.new(1,-139,0,6);bar.BackgroundColor3=Color3.fromRGB(43,44,51);bar.BorderSizePixel=0;bar.Active=true;bar.ZIndex=143;bar.Parent=sr
        rounded(bar,3)
        local fill=Instance.new("Frame");fill.BackgroundColor3=UI.Accent;fill.BorderSizePixel=0;fill.ZIndex=144;fill.Parent=bar;rounded(fill,3)
        local knob=Instance.new("Frame");knob.AnchorPoint=Vector2.new(.5,.5);knob.Size=UDim2.fromOffset(10,16);knob.BackgroundColor3=Color3.fromRGB(242,242,245);knob.BorderSizePixel=0;knob.ZIndex=145;knob.Parent=bar;rounded(knob,5)
        local val=Instance.new("TextLabel");val.AnchorPoint=Vector2.new(1,.5);val.Position=UDim2.new(1,-7,.5,0);val.Size=UDim2.fromOffset(44,20);val.BackgroundColor3=Color3.fromRGB(35,36,43);val.BorderSizePixel=0;val.Font=Enum.Font.Code;val.TextSize=9;val.TextColor3=Color3.fromRGB(220,220,228);val.ZIndex=144;val.Parent=sr;rounded(val,3)
        local sd=false
        local function paintT()
            local n=math.clamp(tonumber(cfg.CarTransparency) or 84,0,100)
            local a=n/100
            fill.Size=UDim2.new(a,0,1,0);knob.Position=UDim2.new(a,0,.5,0);val.Text=tostring(math.floor(n+.5))
        end
        local function transX(x)
            local a=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1)
            cfg.CarTransparency=math.floor(a*100+.5)
            paintT()
        end
        bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sd=true;transX(i.Position.X) end end)
        knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sd=true;transX(i.Position.X) end end)
        UIS.InputChanged:Connect(function(i) if sd and i.UserInputType==Enum.UserInputType.MouseMovement then transX(i.Position.X) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sd=false end end)
        paintT()

        if UI.OpenDockedPanel then UI.OpenDockedPanel(p) else p.Parent=UI.Gui end
    end

    UI.Section(page,"Vehicle")
    UI.Toggle(page,"CarFly",function() return State.Movement.CarFly end,function(v) State.Movement.CarFly=v end)
    UI.Number(page,"CarFly Speed",function() return State.Movement.CarFlySpeed or 90 end,function(v) State.Movement.CarFlySpeed=v end,10,400)

    local carRow,carText=UI.Row(page,"Car ESP")
    carText.Size=UDim2.new(1,-78,1,0)
    carText.Active=true
    local dots=Instance.new("TextButton")
    dots.AnchorPoint=Vector2.new(1,.5);dots.Position=UDim2.new(1,-44,.5,0);dots.Size=UDim2.fromOffset(26,20)
    dots.BackgroundColor3=Color3.fromRGB(34,34,40);dots.BorderSizePixel=0;dots.Font=Enum.Font.SourceSansBold;dots.TextSize=15;dots.TextColor3=Color3.fromRGB(195,195,205);dots.Text="•••";dots.Parent=carRow;rounded(dots,4)
    local tog=Instance.new("TextButton")
    tog.AnchorPoint=Vector2.new(1,.5);tog.Position=UDim2.new(1,-7,.5,0);tog.Size=UDim2.fromOffset(28,18);tog.Text="";tog.BorderSizePixel=0;tog.Parent=carRow;rounded(tog,3)
    local mark=Instance.new("Frame");mark.AnchorPoint=Vector2.new(.5,.5);mark.Position=UDim2.fromScale(.5,.5);mark.Size=UDim2.fromOffset(18,10);mark.BorderSizePixel=0;mark.Parent=tog;rounded(mark,2)
    local function paintCar()
        local on=State.Visuals.CarESP==true
        tog.BackgroundColor3=on and UI.Accent or Color3.fromRGB(45,45,45)
        mark.BackgroundColor3=on and Color3.fromRGB(238,238,240) or Color3.fromRGB(86,86,86)
    end
    local function flipCar() State.Visuals.CarESP=not State.Visuals.CarESP;paintCar() end
    tog.MouseButton1Click:Connect(flipCar)
    carText.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then flipCar() end end)
    dots.MouseButton1Click:Connect(openCarOptions)
    paintCar()

    local function seatedVehicle()
        local ch=LP.Character
        local hum=ch and ch:FindFirstChildOfClass("Humanoid")
        local seat=hum and hum.SeatPart
        if not seat then return nil,nil end
        local model=seat:FindFirstAncestorOfClass("Model")
        if not model then return nil,nil end
        return model,seat
    end

    local function moveVector(cam)
        local f=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
        if f.Magnitude>0 then f=f.Unit end
        local r=Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z)
        if r.Magnitude>0 then r=r.Unit end
        local v=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then v+=f end
        if UIS:IsKeyDown(Enum.KeyCode.S) then v-=f end
        if UIS:IsKeyDown(Enum.KeyCode.D) then v+=r end
        if UIS:IsKeyDown(Enum.KeyCode.A) then v-=r end
        if UIS:IsKeyDown(Enum.KeyCode.E) then v+=Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.Q) then v-=Vector3.yAxis end
        return v.Magnitude>0 and v.Unit or Vector3.zero
    end

    RunService.Heartbeat:Connect(function()
        if not State.Movement.CarFly then return end
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local vehicle,seat=seatedVehicle()
        if not vehicle or not seat then return end
        local root=vehicle.PrimaryPart or seat or vehicle:FindFirstChildWhichIsA("BasePart",true)
        if not root then return end
        local dir=moveVector(cam)
        local speed=math.max(10,State.Movement.CarFlySpeed or 90)
        if dir.Magnitude>0 then root.AssemblyLinearVelocity=dir*speed else root.AssemblyLinearVelocity=Vector3.zero end
        local flat=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
        if flat.Magnitude>0 then pcall(function() root.CFrame=CFrame.lookAt(root.Position,root.Position+flat.Unit) end) end
    end)
end
