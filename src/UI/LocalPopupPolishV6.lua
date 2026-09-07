-- Local popups V6: material/color/transparency/glow inside SelfChams and GunChams ••• menus.
return function(State, UI)
    local UIS=game:GetService("UserInputService")
    local page=UI.Pages.Local
    if not page then return end
    local A=State.Local._Appearance or {}
    A.SelfMaterial=A.SelfMaterial or "ForceField";A.GunMaterial=A.GunMaterial or "ForceField"
    State.Local._Appearance=A
    local materials={"ForceField","Neon","SmoothPlastic","Glass","Foil","Metal","Plastic"}
    local rainbow=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(.17,Color3.fromRGB(255,255,0)),ColorSequenceKeypoint.new(.34,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(.67,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(.84,Color3.fromRGB(255,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0))})
    local function round(o,r)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 4);c.Parent=o end
    local function rowByText(text)
        for _,r in ipairs(page:GetChildren()) do if r:IsA("Frame") then local t=r:FindFirstChildWhichIsA("TextLabel");if t and t.Text==text then return r,t end end end
    end
    local function popup(title,builder)
        local p=Instance.new("Frame");p.Name="LvkLocalOptionsV6";p.Size=UDim2.fromOffset(236,44);p.BackgroundColor3=Color3.fromRGB(17,18,22);p.BorderSizePixel=0;p.ZIndex=150;round(p,7)
        local st=Instance.new("UIStroke");st.Color=Color3.fromRGB(65,67,80);st.Transparency=.12;st.Parent=p
        local ttl=Instance.new("TextLabel");ttl.BackgroundTransparency=1;ttl.Position=UDim2.fromOffset(10,5);ttl.Size=UDim2.new(1,-42,0,28);ttl.Font=Enum.Font.SourceSansSemibold;ttl.TextSize=14;ttl.TextColor3=Color3.fromRGB(238,238,242);ttl.TextXAlignment=Enum.TextXAlignment.Left;ttl.Text=title;ttl.ZIndex=151;ttl.Parent=p
        local close=Instance.new("TextButton");close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-7,0,6);close.Size=UDim2.fromOffset(25,22);close.BackgroundColor3=Color3.fromRGB(34,35,42);close.BorderSizePixel=0;close.Text="×";close.TextColor3=Color3.fromRGB(215,215,222);close.ZIndex=152;close.Parent=p;round(close,4)
        close.MouseButton1Click:Connect(function()if UI.CloseDockedPanel then UI.CloseDockedPanel(p) elseif p.Parent then p:Destroy() end end)
        local y=39
        local function base(label,h)
            h=h or 38;local r=Instance.new("Frame");r.Position=UDim2.fromOffset(7,y);r.Size=UDim2.new(1,-14,0,h);r.BackgroundColor3=Color3.fromRGB(27,28,34);r.BorderSizePixel=0;r.ZIndex=151;r.Parent=p;round(r,4)
            local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Position=UDim2.fromOffset(8,0);l.Size=UDim2.fromOffset(74,h);l.Font=Enum.Font.SourceSans;l.TextSize=12;l.TextColor3=Color3.fromRGB(222,222,228);l.TextXAlignment=Enum.TextXAlignment.Left;l.Text=label;l.ZIndex=152;l.Parent=r;y+=h+5;return r,l
        end
        local function color(label,get,set)
            local r=base(label,38);local bar=Instance.new("Frame");bar.Position=UDim2.fromOffset(80,11);bar.Size=UDim2.new(1,-90,0,16);bar.BackgroundColor3=Color3.new(1,1,1);bar.BorderSizePixel=0;bar.Active=true;bar.ZIndex=153;bar.Parent=r;round(bar,4)
            local g=Instance.new("UIGradient");g.Color=rainbow;g.Parent=bar;local k=Instance.new("Frame");k.AnchorPoint=Vector2.new(.5,.5);k.Size=UDim2.fromOffset(4,22);k.BackgroundColor3=Color3.fromRGB(248,248,250);k.BorderSizePixel=0;k.ZIndex=154;k.Parent=bar
            local d=false;local function paint()local c=get();k.Position=UDim2.new(typeof(c)=="Color3" and select(1,c:ToHSV()) or 0,0,.5,0)end
            local function setX(x)local h=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1);set(Color3.fromHSV(h,1,1));paint()end
            bar.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then d=true;setX(i.Position.X)end end);UIS.InputChanged:Connect(function(i)if d and i.UserInputType==Enum.UserInputType.MouseMovement then setX(i.Position.X)end end);UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end);paint()
        end
        local function slider(label,get,set,min,max,step)
            local r=base(label,38);local bar=Instance.new("Frame");bar.Position=UDim2.fromOffset(78,16);bar.Size=UDim2.new(1,-133,0,6);bar.BackgroundColor3=Color3.fromRGB(43,44,51);bar.BorderSizePixel=0;bar.Active=true;bar.ZIndex=153;bar.Parent=r;round(bar,3)
            local fill=Instance.new("Frame");fill.BackgroundColor3=UI.Accent;fill.BorderSizePixel=0;fill.ZIndex=154;fill.Parent=bar;round(fill,3);local k=Instance.new("Frame");k.AnchorPoint=Vector2.new(.5,.5);k.Size=UDim2.fromOffset(10,16);k.BackgroundColor3=Color3.fromRGB(242,242,245);k.BorderSizePixel=0;k.ZIndex=155;k.Parent=bar;round(k,5)
            local val=Instance.new("TextLabel");val.AnchorPoint=Vector2.new(1,.5);val.Position=UDim2.new(1,-7,.5,0);val.Size=UDim2.fromOffset(44,20);val.BackgroundColor3=Color3.fromRGB(35,36,43);val.BorderSizePixel=0;val.Font=Enum.Font.Code;val.TextSize=9;val.TextColor3=Color3.fromRGB(220,220,228);val.ZIndex=154;val.Parent=r;round(val,3)
            local d=false;local function paint()local n=math.clamp(tonumber(get()) or min,min,max);local a=(n-min)/(max-min);fill.Size=UDim2.new(a,0,1,0);k.Position=UDim2.new(a,0,.5,0);val.Text=tostring(math.floor(n+.5))end
            local function setX(x)local a=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1);local n=math.floor((min+(max-min)*a)/step+.5)*step;set(math.clamp(n,min,max));paint()end
            bar.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then d=true;setX(i.Position.X)end end);k.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then d=true;setX(i.Position.X)end end);UIS.InputChanged:Connect(function(i)if d and i.UserInputType==Enum.UserInputType.MouseMovement then setX(i.Position.X)end end);UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end);paint()
        end
        local function dropdown(label,values,get,set)
            local r,l=base(label,31);l.Size=UDim2.new(1,-96,1,0);local b=Instance.new("TextButton");b.AnchorPoint=Vector2.new(1,.5);b.Position=UDim2.new(1,-7,.5,0);b.Size=UDim2.fromOffset(82,20);b.BackgroundColor3=Color3.fromRGB(37,38,46);b.BorderSizePixel=0;b.Font=Enum.Font.SourceSans;b.TextSize=11;b.TextColor3=Color3.fromRGB(225,225,232);b.ZIndex=153;b.Parent=r;round(b,3)
            local function paint()b.Text=tostring(get())end;b.MouseButton1Click:Connect(function()local i=table.find(values,get()) or 0;set(values[i%#values+1]);paint()end);paint()
        end
        local function toggle(label,get,set)
            local r,l=base(label,31);l.Size=UDim2.new(1,-50,1,0);local b=Instance.new("TextButton");b.AnchorPoint=Vector2.new(1,.5);b.Position=UDim2.new(1,-7,.5,0);b.Size=UDim2.fromOffset(34,18);b.Text="";b.BorderSizePixel=0;b.ZIndex=153;b.Parent=r;round(b,3);local function paint()b.BackgroundColor3=get() and UI.Accent or Color3.fromRGB(48,49,57)end;b.MouseButton1Click:Connect(function()set(not get());paint()end);paint()
        end
        builder({Color=color,Slider=slider,Dropdown=dropdown,Toggle=toggle});p.Size=UDim2.fromOffset(236,y+3);if UI.OpenDockedPanel then UI.OpenDockedPanel(p) else p.Parent=UI.Gui end
    end
    local function addDots(label,cb)
        local r,t=rowByText(label);if not r then return end;local old=r:FindFirstChild("LvkLocalDotsV5");if old then old:Destroy() end;local old2=r:FindFirstChild("LvkLocalDotsV6");if old2 then old2:Destroy() end;t.Size=UDim2.new(1,-78,1,0)
        local d=Instance.new("TextButton");d.Name="LvkLocalDotsV6";d.AnchorPoint=Vector2.new(1,.5);d.Position=UDim2.new(1,-44,.5,0);d.Size=UDim2.fromOffset(26,20);d.BackgroundColor3=Color3.fromRGB(34,34,40);d.BorderSizePixel=0;d.Font=Enum.Font.SourceSansBold;d.TextSize=15;d.TextColor3=Color3.fromRGB(195,195,205);d.Text="•••";d.Parent=r;round(d,4);d.MouseButton1Click:Connect(cb)
    end
    task.defer(function()
        addDots("SelfChams",function()popup("SelfChams",function(o)o.Dropdown("Material",materials,function()return A.SelfMaterial end,function(v)A.SelfMaterial=v end);o.Color("Color",function()return A.SelfColor end,function(v)A.SelfColor=v end);o.Slider("Transp.",function()return A.SelfTransparency end,function(v)A.SelfTransparency=v end,0,90,1);o.Toggle("Glow",function()return A.SelfGlow end,function(v)A.SelfGlow=v end)end)end)
        addDots("GunChams",function()popup("GunChams",function(o)o.Dropdown("Material",materials,function()return A.GunMaterial end,function(v)A.GunMaterial=v end);o.Color("Color",function()return A.GunColor end,function(v)A.GunColor=v end);o.Slider("Transp.",function()return A.GunTransparency end,function(v)A.GunTransparency=v end,0,90,1);o.Toggle("Glow",function()return A.GunGlow end,function(v)A.GunGlow=v end)end)end)
        addDots("Trail",function()popup("Trail",function(o)o.Color("Color",function()return A.TrailColor end,function(v)A.TrailColor=v end);o.Slider("Lifetime",function()return A.TrailLifetime end,function(v)A.TrailLifetime=v end,1,100,1);o.Slider("Thickness",function()return A.TrailThickness end,function(v)A.TrailThickness=v end,1,30,1);o.Toggle("Glow",function()return State.Local.TrailGlow==true end,function(v)State.Local.TrailGlow=v end)end)end)
    end)
end
