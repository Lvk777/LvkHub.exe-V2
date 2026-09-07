-- Local cosmetic BulletTracer for the LocalPlayer's equipped weapon.
-- Draws only a client-side beam and does not alter bullet direction or damage.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local Workspace=game:GetService("Workspace")
    local UIS=game:GetService("UserInputService")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Local

    State.Local.BulletTracer=State.Local.BulletTracer==true
    local C=State.Local._BulletTracer or {
        Color=Color3.fromRGB(119,120,255),
        Transparency=5,
        Lifetime=.16,
        Thickness=.08,
        Glow=true,
        Distance=20000,
    }
    State.Local._BulletTracer=C

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

    local activePopup=nil
    local function closePopup()
        if not activePopup then return end
        if UI.CloseDockedPanel and UI.ActiveDockedPanel==activePopup then UI.CloseDockedPanel(activePopup)
        elseif activePopup.Parent then activePopup:Destroy() end
        activePopup=nil
    end

    local function openOptions()
        closePopup()
        local p=Instance.new("Frame")
        p.Name="LvkBulletTracerOptions"
        p.Size=UDim2.fromOffset(236,44)
        p.BackgroundColor3=Color3.fromRGB(17,18,22)
        p.BorderSizePixel=0
        p.ZIndex=120
        rounded(p,7)
        local stroke=Instance.new("UIStroke"); stroke.Color=Color3.fromRGB(65,67,80); stroke.Transparency=.12; stroke.Parent=p
        local title=Instance.new("TextLabel")
        title.BackgroundTransparency=1; title.Position=UDim2.fromOffset(10,5); title.Size=UDim2.new(1,-42,0,28)
        title.Font=Enum.Font.SourceSansSemibold; title.TextSize=14; title.TextColor3=Color3.fromRGB(238,238,242); title.TextXAlignment=Enum.TextXAlignment.Left; title.Text="BulletTracer"; title.ZIndex=121; title.Parent=p
        local close=Instance.new("TextButton")
        close.AnchorPoint=Vector2.new(1,0); close.Position=UDim2.new(1,-7,0,6); close.Size=UDim2.fromOffset(25,22)
        close.BackgroundColor3=Color3.fromRGB(34,35,42); close.BorderSizePixel=0; close.Text="×"; close.Font=Enum.Font.SourceSansBold; close.TextSize=16; close.TextColor3=Color3.fromRGB(215,215,222); close.ZIndex=122; close.Parent=p; rounded(close,4)
        close.MouseButton1Click:Connect(closePopup)

        local y=39
        local function baseRow(label,h)
            h=h or 31
            local r=Instance.new("Frame"); r.Position=UDim2.fromOffset(7,y); r.Size=UDim2.new(1,-14,0,h); r.BackgroundColor3=Color3.fromRGB(27,28,34); r.BorderSizePixel=0; r.ZIndex=121; r.Parent=p; rounded(r,4)
            local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Position=UDim2.fromOffset(8,0); l.Size=UDim2.new(1,-16,1,0); l.Font=Enum.Font.SourceSans; l.TextSize=12; l.TextColor3=Color3.fromRGB(222,222,228); l.TextXAlignment=Enum.TextXAlignment.Left; l.Text=label; l.ZIndex=122; l.Parent=r
            y+=h+5
            return r,l
        end

        local function colorRow()
            local r,l=baseRow("Color",38); l.Size=UDim2.fromOffset(74,38)
            local bar=Instance.new("Frame"); bar.Position=UDim2.fromOffset(80,11); bar.Size=UDim2.new(1,-90,0,16); bar.BackgroundColor3=Color3.new(1,1,1); bar.BorderSizePixel=0; bar.Active=true; bar.ZIndex=123; bar.Parent=r; rounded(bar,4)
            local g=Instance.new("UIGradient"); g.Color=rainbow; g.Parent=bar
            local knob=Instance.new("Frame"); knob.AnchorPoint=Vector2.new(.5,.5); knob.Size=UDim2.fromOffset(4,22); knob.BackgroundColor3=Color3.fromRGB(248,248,250); knob.BorderSizePixel=0; knob.ZIndex=124; knob.Parent=bar
            local ks=Instance.new("UIStroke"); ks.Color=Color3.fromRGB(20,20,24); ks.Parent=knob
            local dragging=false
            local function paint() knob.Position=UDim2.new(select(1,C.Color:ToHSV()),0,.5,0) end
            local function fromX(x)
                local h=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1)
                C.Color=Color3.fromHSV(h,1,1); knob.Position=UDim2.new(h,0,.5,0)
            end
            bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; fromX(i.Position.X) end end)
            UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then fromX(i.Position.X) end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
            paint()
        end

        local function slider(label,get,set,min,max,step)
            local r,l=baseRow(label,38); l.Size=UDim2.fromOffset(82,38)
            local bar=Instance.new("Frame"); bar.Position=UDim2.fromOffset(88,16); bar.Size=UDim2.new(1,-143,0,6); bar.BackgroundColor3=Color3.fromRGB(43,44,51); bar.BorderSizePixel=0; bar.Active=true; bar.ZIndex=123; bar.Parent=r; rounded(bar,3)
            local fill=Instance.new("Frame"); fill.BackgroundColor3=UI.Accent; fill.BorderSizePixel=0; fill.ZIndex=124; fill.Parent=bar; rounded(fill,3)
            local knob=Instance.new("Frame"); knob.AnchorPoint=Vector2.new(.5,.5); knob.Size=UDim2.fromOffset(10,16); knob.BackgroundColor3=Color3.fromRGB(242,242,245); knob.BorderSizePixel=0; knob.ZIndex=125; knob.Parent=bar; rounded(knob,5)
            local val=Instance.new("TextLabel"); val.AnchorPoint=Vector2.new(1,.5); val.Position=UDim2.new(1,-7,.5,0); val.Size=UDim2.fromOffset(44,20); val.BackgroundColor3=Color3.fromRGB(35,36,43); val.BorderSizePixel=0; val.Font=Enum.Font.Code; val.TextSize=9; val.TextColor3=Color3.fromRGB(220,220,228); val.ZIndex=124; val.Parent=r; rounded(val,3)
            local dragging=false
            local function paint()
                local n=math.clamp(tonumber(get()) or min,min,max); local a=(n-min)/math.max(max-min,1e-6)
                fill.Size=UDim2.new(a,0,1,0); knob.Position=UDim2.new(a,0,.5,0)
                val.Text=step<1 and string.format("%.2f",n) or tostring(math.floor(n+.5))
            end
            local function fromX(x)
                local a=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1); local n=min+(max-min)*a
                n=math.floor(n/step+.5)*step; set(math.clamp(n,min,max)); paint()
            end
            bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; fromX(i.Position.X) end end)
            knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; fromX(i.Position.X) end end)
            UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then fromX(i.Position.X) end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
            paint()
        end

        local function toggle(label,get,set)
            local r,l=baseRow(label); l.Size=UDim2.new(1,-50,1,0)
            local b=Instance.new("TextButton"); b.AnchorPoint=Vector2.new(1,.5); b.Position=UDim2.new(1,-7,.5,0); b.Size=UDim2.fromOffset(34,18); b.Text=""; b.BorderSizePixel=0; b.ZIndex=123; b.Parent=r; rounded(b,3)
            local function paint() b.BackgroundColor3=get() and UI.Accent or Color3.fromRGB(48,49,57) end
            b.MouseButton1Click:Connect(function() set(not get()); paint() end); paint()
        end

        colorRow()
        slider("Transp.",function() return C.Transparency end,function(v) C.Transparency=v end,0,100,1)
        slider("Lifetime",function() return C.Lifetime end,function(v) C.Lifetime=v end,.05,1.5,.05)
        slider("Thickness",function() return C.Thickness end,function(v) C.Thickness=v end,.02,.35,.01)
        toggle("Glow",function() return C.Glow end,function(v) C.Glow=v end)
        p.Size=UDim2.fromOffset(236,y+3)
        activePopup=p
        if UI.OpenDockedPanel then UI.OpenDockedPanel(p) else p.Parent=UI.Gui end
    end

    local row,text=UI.Row(page,"BulletTracer")
    text.Size=UDim2.new(1,-78,1,0); text.Active=true
    local dots=Instance.new("TextButton"); dots.AnchorPoint=Vector2.new(1,.5); dots.Position=UDim2.new(1,-44,.5,0); dots.Size=UDim2.fromOffset(26,20); dots.BackgroundColor3=Color3.fromRGB(34,34,40); dots.BorderSizePixel=0; dots.Font=Enum.Font.SourceSansBold; dots.TextSize=15; dots.TextColor3=Color3.fromRGB(195,195,205); dots.Text="•••"; dots.Parent=row; rounded(dots,4)
    local toggle=Instance.new("TextButton"); toggle.AnchorPoint=Vector2.new(1,.5); toggle.Position=UDim2.new(1,-7,.5,0); toggle.Size=UDim2.fromOffset(28,18); toggle.Text=""; toggle.BorderSizePixel=0; toggle.Parent=row; rounded(toggle,3)
    local mark=Instance.new("Frame"); mark.AnchorPoint=Vector2.new(.5,.5); mark.Position=UDim2.fromScale(.5,.5); mark.Size=UDim2.fromOffset(18,10); mark.BorderSizePixel=0; mark.Parent=toggle; rounded(mark,2)
    local function paintToggle()
        local on=State.Local.BulletTracer==true
        toggle.BackgroundColor3=on and UI.Accent or Color3.fromRGB(45,45,45)
        mark.BackgroundColor3=on and Color3.fromRGB(238,238,240) or Color3.fromRGB(86,86,86)
    end
    local function flip() State.Local.BulletTracer=not State.Local.BulletTracer; paintToggle() end
    toggle.MouseButton1Click:Connect(flip)
    text.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then flip() end end)
    dots.MouseButton1Click:Connect(openOptions)
    paintToggle()

    local folder=Workspace:FindFirstChild("LvkHubBulletTracers")
    if folder then folder:Destroy() end
    folder=Instance.new("Folder"); folder.Name="LvkHubBulletTracers"; folder.Parent=Workspace

    local function worldPos(obj)
        if not obj then return nil end
        if obj:IsA("Attachment") then return obj.WorldPosition end
        if obj:IsA("BasePart") then return obj.Position end
        return nil
    end

    local function muzzleOf(tool)
        if not tool then return nil end
        local muzzle=tool:FindFirstChild("Muzzle",true)
        local p=worldPos(muzzle)
        if p then return p end
        local cam=Workspace.CurrentCamera
        if cam then
            local toolName=string.lower(tool.Name)
            for _,m in ipairs(cam:GetDescendants()) do
                if m:IsA("Model") then
                    local n=string.lower(m.Name)
                    if n==toolName or string.find(n,toolName,1,true) then
                        local mm=m:FindFirstChild("Muzzle",true)
                        p=worldPos(mm)
                        if p then return p end
                    end
                end
            end
        end
        return nil
    end

    local function endPoint(origin)
        local cam=Workspace.CurrentCamera
        if not cam then return origin+Vector3.new(0,0,-500) end
        local center=cam.ViewportSize/2
        local ray=cam:ViewportPointToRay(center.X,center.Y)
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        local ex={folder,cam}
        if LP.Character then table.insert(ex,LP.Character) end
        params.FilterDescendantsInstances=ex
        params.IgnoreWater=true
        local result=Workspace:Raycast(ray.Origin,ray.Direction*C.Distance,params)
        return result and result.Position or (ray.Origin+ray.Direction*C.Distance)
    end

    local function pointPart(pos)
        local p=Instance.new("Part")
        p.Size=Vector3.new(.05,.05,.05); p.Transparency=1; p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.CFrame=CFrame.new(pos); p.Parent=folder
        local a=Instance.new("Attachment"); a.Parent=p
        return p,a
    end

    local function spawnTracer(tool)
        if not State.Local.BulletTracer then return end
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local origin=muzzleOf(tool) or cam.CFrame.Position
        local target=endPoint(origin)
        local p0,a0=pointPart(origin)
        local p1,a1=pointPart(target)
        local beam=Instance.new("Beam")
        beam.Name="LvkHubBulletTracerBeam"
        beam.Attachment0=a0; beam.Attachment1=a1; beam.FaceCamera=true
        beam.Color=ColorSequence.new(C.Color)
        beam.Transparency=NumberSequence.new(math.clamp(C.Transparency/100,0,1))
        beam.Width0=C.Thickness; beam.Width1=C.Thickness
        beam.LightEmission=C.Glow and 1 or .2
        beam.LightInfluence=0
        beam.Parent=p0
        local glow=nil
        if C.Glow then
            glow=Instance.new("Beam")
            glow.Name="LvkHubBulletTracerGlow"
            glow.Attachment0=a0; glow.Attachment1=a1; glow.FaceCamera=true
            glow.Color=ColorSequence.new(C.Color)
            glow.Transparency=NumberSequence.new(math.clamp(C.Transparency/100+.45,0,1))
            glow.Width0=C.Thickness*2.6; glow.Width1=C.Thickness*2.6
            glow.LightEmission=1; glow.LightInfluence=0; glow.Parent=p0
        end
        task.delay(math.max(.05,C.Lifetime),function()
            if p0 then p0:Destroy() end
            if p1 then p1:Destroy() end
        end)
    end

    local toolConns=setmetatable({}, {__mode="k"})
    local function watchTool(tool)
        if not tool or not tool:IsA("Tool") or toolConns[tool] then return end
        toolConns[tool]=tool.Activated:Connect(function() spawnTracer(tool) end)
    end

    local function watchCharacter(char)
        for _,obj in ipairs(char:GetChildren()) do if obj:IsA("Tool") then watchTool(obj) end end
        char.ChildAdded:Connect(function(obj) if obj:IsA("Tool") then watchTool(obj) end end)
    end
    if LP.Character then watchCharacter(LP.Character) end
    LP.CharacterAdded:Connect(watchCharacter)
end
