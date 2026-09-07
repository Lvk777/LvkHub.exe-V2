-- Moves SelfChams/GunChams/Trail sub-settings into ••• popup panels.
-- Existing Local feature logic remains unchanged; this module only changes presentation.
return function(State, UI)
    local UIS=game:GetService("UserInputService")
    local page=UI.Pages.Local
    if not page then return end
    local A=State.Local._Appearance
    if type(A)~="table" then return end

    local materials={"ForceField","Neon","SmoothPlastic","Glass","Foil","Metal","Plastic"}
    local rainbow=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(1/6,Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(3/6,Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(5/6,Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0)),
    })
    local function rounded(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 4); c.Parent=o end

    local function rowByText(names)
        for _,r in ipairs(page:GetChildren()) do
            if r:IsA("Frame") then
                local t=r:FindFirstChildWhichIsA("TextLabel")
                if t and table.find(names,t.Text) then return r,t end
            end
        end
    end

    local function hideRows(names)
        for _,r in ipairs(page:GetChildren()) do
            if r:IsA("Frame") then
                local t=r:FindFirstChildWhichIsA("TextLabel")
                if t and table.find(names,t.Text) then r.Visible=false end
            end
        end
    end

    local function buildPopup(title,builder)
        local p=Instance.new("Frame")
        p.Name="LvkLocalOptionsV4"; p.Size=UDim2.fromOffset(236,44); p.BackgroundColor3=Color3.fromRGB(17,18,22); p.BorderSizePixel=0; p.ZIndex=130; rounded(p,7)
        local st=Instance.new("UIStroke"); st.Color=Color3.fromRGB(65,67,80); st.Transparency=.12; st.Parent=p
        local ttl=Instance.new("TextLabel"); ttl.BackgroundTransparency=1; ttl.Position=UDim2.fromOffset(10,5); ttl.Size=UDim2.new(1,-42,0,28); ttl.Font=Enum.Font.SourceSansSemibold; ttl.TextSize=14; ttl.TextColor3=Color3.fromRGB(238,238,242); ttl.TextXAlignment=Enum.TextXAlignment.Left; ttl.Text=title; ttl.ZIndex=131; ttl.Parent=p
        local close=Instance.new("TextButton"); close.AnchorPoint=Vector2.new(1,0); close.Position=UDim2.new(1,-7,0,6); close.Size=UDim2.fromOffset(25,22); close.BackgroundColor3=Color3.fromRGB(34,35,42); close.BorderSizePixel=0; close.Text="×"; close.TextColor3=Color3.fromRGB(215,215,222); close.ZIndex=132; close.Parent=p; rounded(close,4)
        close.MouseButton1Click:Connect(function() if UI.CloseDockedPanel then UI.CloseDockedPanel(p) elseif p.Parent then p:Destroy() end end)
        local y=39
        local function base(label,h)
            h=h or 38
            local r=Instance.new("Frame"); r.Position=UDim2.fromOffset(7,y); r.Size=UDim2.new(1,-14,0,h); r.BackgroundColor3=Color3.fromRGB(27,28,34); r.BorderSizePixel=0; r.ZIndex=131; r.Parent=p; rounded(r,4)
            local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Position=UDim2.fromOffset(8,0); l.Size=UDim2.fromOffset(78,h); l.Font=Enum.Font.SourceSans; l.TextSize=12; l.TextColor3=Color3.fromRGB(222,222,228); l.TextXAlignment=Enum.TextXAlignment.Left; l.Text=label; l.ZIndex=132; l.Parent=r
            y+=h+5
            return r,l
        end
        local function color(label,get,set)
            local r,l=base(label); l.Size=UDim2.fromOffset(74,38)
            local bar=Instance.new("Frame"); bar.Position=UDim2.fromOffset(80,11); bar.Size=UDim2.new(1,-90,0,16); bar.BackgroundColor3=Color3.new(1,1,1); bar.BorderSizePixel=0; bar.Active=true; bar.ZIndex=133; bar.Parent=r; rounded(bar,4)
            local g=Instance.new("UIGradient"); g.Color=rainbow; g.Parent=bar
            local k=Instance.new("Frame"); k.AnchorPoint=Vector2.new(.5,.5); k.Size=UDim2.fromOffset(4,22); k.BackgroundColor3=Color3.fromRGB(248,248,250); k.BorderSizePixel=0; k.ZIndex=134; k.Parent=bar
            local drag=false
            local function paint() local h=select(1,get():ToHSV()); k.Position=UDim2.new(h,0,.5,0) end
            local function setX(x) local h=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1); set(Color3.fromHSV(h,1,1)); paint() end
            bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; setX(i.Position.X) end end)
            UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then setX(i.Position.X) end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end); paint()
        end
        local function slider(label,get,set,min,max,step)
            local r,l=base(label); l.Size=UDim2.fromOffset(76,38)
            local bar=Instance.new("Frame"); bar.Position=UDim2.fromOffset(82,16); bar.Size=UDim2.new(1,-137,0,6); bar.BackgroundColor3=Color3.fromRGB(43,44,51); bar.BorderSizePixel=0; bar.Active=true; bar.ZIndex=133; bar.Parent=r; rounded(bar,3)
            local fill=Instance.new("Frame"); fill.BackgroundColor3=UI.Accent; fill.BorderSizePixel=0; fill.ZIndex=134; fill.Parent=bar; rounded(fill,3)
            local k=Instance.new("Frame"); k.AnchorPoint=Vector2.new(.5,.5); k.Size=UDim2.fromOffset(10,16); k.BackgroundColor3=Color3.fromRGB(242,242,245); k.BorderSizePixel=0; k.ZIndex=135; k.Parent=bar; rounded(k,5)
            local val=Instance.new("TextLabel"); val.AnchorPoint=Vector2.new(1,.5); val.Position=UDim2.new(1,-7,.5,0); val.Size=UDim2.fromOffset(44,20); val.BackgroundColor3=Color3.fromRGB(35,36,43); val.BorderSizePixel=0; val.Font=Enum.Font.Code; val.TextSize=9; val.TextColor3=Color3.fromRGB(220,220,228); val.ZIndex=134; val.Parent=r; rounded(val,3)
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
            local b=Instance.new("TextButton"); b.AnchorPoint=Vector2.new(1,.5); b.Position=UDim2.new(1,-7,.5,0); b.Size=UDim2.fromOffset(34,18); b.Text=""; b.BorderSizePixel=0; b.ZIndex=133; b.Parent=r; rounded(b,3)
            local function paint() b.BackgroundColor3=get() and UI.Accent or Color3.fromRGB(48,49,57) end
            b.MouseButton1Click:Connect(function() set(not get()); paint() end); paint()
        end
        local function dropdown(label,values,get,set)
            local r,l=base(label,31); l.Size=UDim2.new(1,-98,1,0)
            local b=Instance.new("TextButton"); b.AnchorPoint=Vector2.new(1,.5); b.Position=UDim2.new(1,-7,.5,0); b.Size=UDim2.fromOffset(84,20); b.BackgroundColor3=Color3.fromRGB(37,38,46); b.BorderSizePixel=0; b.Font=Enum.Font.SourceSans; b.TextSize=10; b.TextColor3=Color3.fromRGB(225,225,232); b.ZIndex=133; b.Parent=r; rounded(b,3)
            local function paint() b.Text=tostring(get()) end
            b.MouseButton1Click:Connect(function() local i=table.find(values,get()) or 0; set(values[i%#values+1]); paint() end); paint()
        end
        builder({Color=color,Slider=slider,Toggle=toggle,Dropdown=dropdown})
        p.Size=UDim2.fromOffset(236,y+3)
        if UI.OpenDockedPanel then UI.OpenDockedPanel(p) else p.Parent=UI.Gui end
    end

    local function addDots(parentLabels,open)
        local r,t=rowByText(parentLabels)
        if not r or r:FindFirstChild("LvkLocalDotsV4") then return end
        t.Size=UDim2.new(1,-78,1,0)
        local d=Instance.new("TextButton"); d.Name="LvkLocalDotsV4"; d.AnchorPoint=Vector2.new(1,.5); d.Position=UDim2.new(1,-44,.5,0); d.Size=UDim2.fromOffset(26,20); d.BackgroundColor3=Color3.fromRGB(34,34,40); d.BorderSizePixel=0; d.Font=Enum.Font.SourceSansBold; d.TextSize=15; d.TextColor3=Color3.fromRGB(195,195,205); d.Text="•••"; d.Parent=r; rounded(d,4); d.MouseButton1Click:Connect(open)
    end

    task.defer(function()
        hideRows({"Self Material","Self Color","Self Transparency","Self Transp.","Self Glow"})
        hideRows({"Gun Material","Gun Color","Gun Transparency","Gun Transp.","Gun Glow"})
        hideRows({"Trail Color","Trail Lifetime","Trail Life","Trail Thickness","Trail Thick."})

        addDots({"SelfChams"},function()
            buildPopup("SelfChams",function(o)
                o.Dropdown("Material",materials,function() return A.SelfMaterial end,function(v) A.SelfMaterial=v end)
                o.Color("Color",function() return A.SelfColor end,function(v) A.SelfColor=v end)
                o.Slider("Transp.",function() return A.SelfTransparency end,function(v) A.SelfTransparency=v end,0,90,1)
                o.Toggle("Glow",function() return A.SelfGlow end,function(v) A.SelfGlow=v end)
            end)
        end)
        addDots({"GunChams"},function()
            buildPopup("GunChams",function(o)
                o.Dropdown("Material",materials,function() return A.GunMaterial end,function(v) A.GunMaterial=v end)
                o.Color("Color",function() return A.GunColor end,function(v) A.GunColor=v end)
                o.Slider("Transp.",function() return A.GunTransparency end,function(v) A.GunTransparency=v end,0,90,1)
                o.Toggle("Glow",function() return A.GunGlow end,function(v) A.GunGlow=v end)
            end)
        end)
        addDots({"Trail"},function()
            buildPopup("Trail",function(o)
                o.Color("Color",function() return A.TrailColor end,function(v) A.TrailColor=v end)
                o.Slider("Lifetime",function() return A.TrailLifetime end,function(v) A.TrailLifetime=v end,1,100,1)
                o.Slider("Thickness",function() return A.TrailThickness end,function(v) A.TrailThickness=v end,1,30,1)
                o.Toggle("Glow",function() return State.Local.TrailGlow==true end,function(v) State.Local.TrailGlow=v end)
            end)
        end)
    end)
end
