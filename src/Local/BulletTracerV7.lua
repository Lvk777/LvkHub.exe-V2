-- BulletTracer V7: local cosmetic tracer emitted from each actual WeaponShotBuilder shot.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local Workspace=game:GetService("Workspace")
    local UIS=game:GetService("UserInputService")
    local Debris=game:GetService("Debris")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Local

    State.Local.BulletTracer=State.Local.BulletTracer==true
    local C=State.Local._BulletTracerV7 or {Color=Color3.fromRGB(119,120,255),Transparency=5,Lifetime=.20,Thickness=.08,Glow=true,Distance=20000}
    State.Local._BulletTracerV7=C

    local function round(o,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 4);c.Parent=o end
    local function currentWeapon()
        local ch=LP.Character;if not ch then return nil end
        for _,o in ipairs(ch:GetChildren()) do if o:IsA("Tool") and (o:FindFirstChild("WeaponConfig") or o:FindFirstChild("Ammo")) then return o end end
    end
    local function worldPos(o)
        if o and o:IsA("Attachment") then return o.WorldPosition end
        if o and o:IsA("BasePart") then return o.Position end
    end
    local function muzzlePosition()
        local tool=currentWeapon()
        if tool then
            local muzzle=tool:FindFirstChild("Muzzle",true)
            local p=worldPos(muzzle);if p then return p end
            local grip=tool:FindFirstChild("Grip",true)
            if grip and grip:IsA("BasePart") then return grip.Position+grip.CFrame.LookVector*math.max(.5,grip.Size.Z*.5) end
            local handle=tool:FindFirstChild("Handle",true)
            if handle and handle:IsA("BasePart") then return handle.Position+handle.CFrame.LookVector*math.max(.5,handle.Size.Z*.5) end
        end
        local cam=Workspace.CurrentCamera
        return cam and cam.CFrame.Position or nil
    end

    for _,name in ipairs({"LvkHubBulletTracersV6","LvkHubBulletTracersV7"}) do local o=Workspace:FindFirstChild(name);if o then o:Destroy() end end
    local folder=Instance.new("Folder");folder.Name="LvkHubBulletTracersV7";folder.Parent=Workspace

    local function anchor(pos)
        local p=Instance.new("Part")
        p.Size=Vector3.new(.02,.02,.02);p.Transparency=1;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CFrame=CFrame.new(pos);p.Parent=folder
        local a=Instance.new("Attachment");a.Parent=p
        return p,a
    end
    local function selectedEndpoint()
        if not (State.Combat and (State.Combat.SilentAim or State.Combat.MagicBullets)) then return nil end
        local m=State.Combat.SelectedBot
        if m and Registry.IsBot(m) then
            local p=(State.Combat.AimPart=="Torso" and (m:FindFirstChild("UpperTorso") or m:FindFirstChild("Torso"))) or m:FindFirstChild("Head") or Registry.RootOf(m)
            return p and p.Position or nil
        end
    end
    local lastEmit=0
    local function emit(direction)
        if not State.Local.BulletTracer then return end
        local now=os.clock();if now-lastEmit<.025 then return end;lastEmit=now
        local from=muzzlePosition();if not from then return end
        local to=selectedEndpoint()
        if not to then
            local dir=direction
            local cam=Workspace.CurrentCamera
            if typeof(dir)~="Vector3" or dir.Magnitude<=0 then dir=cam and cam.CFrame.LookVector or nil end
            if not dir then return end
            local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={folder,LP.Character,cam};rp.IgnoreWater=true
            local dist=tonumber(C.Distance) or 20000
            local hit=Workspace:Raycast(from,dir.Unit*dist,rp)
            to=hit and hit.Position or from+dir.Unit*dist
        end
        if (to-from).Magnitude<.1 then return end
        local p0,a0=anchor(from);local p1,a1=anchor(to)
        local beam=Instance.new("Beam")
        beam.Attachment0=a0;beam.Attachment1=a1;beam.FaceCamera=true;beam.Color=ColorSequence.new(C.Color)
        beam.Transparency=NumberSequence.new(math.clamp((C.Transparency or 0)/100,0,1));beam.Width0=C.Thickness or .08;beam.Width1=C.Thickness or .08
        beam.LightEmission=C.Glow and 1 or 0;beam.LightInfluence=C.Glow and 0 or 1;beam.Parent=p0
        if C.Glow then
            local glow=beam:Clone();glow.Width0=(C.Thickness or .08)*3;glow.Width1=glow.Width0;glow.Transparency=NumberSequence.new(.72);glow.Parent=p0
        end
        local life=math.clamp(tonumber(C.Lifetime) or .20,.05,1.5)
        Debris:AddItem(p0,life);Debris:AddItem(p1,life)
    end

    local function openOptions()
        local p=Instance.new("Frame");p.Name="LvkBulletTracerOptionsV7";p.Size=UDim2.fromOffset(236,252);p.BackgroundColor3=Color3.fromRGB(17,18,22);p.BorderSizePixel=0;p.ZIndex=130;round(p,7)
        local st=Instance.new("UIStroke");st.Color=Color3.fromRGB(65,67,80);st.Transparency=.12;st.Parent=p
        local ttl=Instance.new("TextLabel");ttl.BackgroundTransparency=1;ttl.Position=UDim2.fromOffset(10,5);ttl.Size=UDim2.new(1,-42,0,28);ttl.Font=Enum.Font.SourceSansSemibold;ttl.TextSize=14;ttl.TextColor3=Color3.fromRGB(238,238,242);ttl.TextXAlignment=Enum.TextXAlignment.Left;ttl.Text="BulletTracer";ttl.ZIndex=131;ttl.Parent=p
        local close=Instance.new("TextButton");close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-7,0,6);close.Size=UDim2.fromOffset(25,22);close.BackgroundColor3=Color3.fromRGB(34,35,42);close.BorderSizePixel=0;close.Text="×";close.TextColor3=Color3.fromRGB(215,215,222);close.ZIndex=132;close.Parent=p;round(close,4)
        close.MouseButton1Click:Connect(function() if UI.CloseDockedPanel then UI.CloseDockedPanel(p) elseif p.Parent then p:Destroy() end end)
        local rainbow=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(.17,Color3.fromRGB(255,255,0)),ColorSequenceKeypoint.new(.34,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(0,255,255)),ColorSequenceKeypoint.new(.67,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(.84,Color3.fromRGB(255,0,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0))})
        local y=39
        local function base(label)
            local r=Instance.new("Frame");r.Position=UDim2.fromOffset(7,y);r.Size=UDim2.new(1,-14,0,38);r.BackgroundColor3=Color3.fromRGB(27,28,34);r.BorderSizePixel=0;r.ZIndex=131;r.Parent=p;round(r,4)
            local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Position=UDim2.fromOffset(8,0);l.Size=UDim2.fromOffset(72,38);l.Font=Enum.Font.SourceSans;l.TextSize=12;l.TextColor3=Color3.fromRGB(222,222,228);l.TextXAlignment=Enum.TextXAlignment.Left;l.Text=label;l.ZIndex=132;l.Parent=r
y+=43;return r,l
        end
        local r=base("Color")
        local bar=Instance.new("Frame");bar.Position=UDim2.fromOffset(80,11);bar.Size=UDim2.new(1,-90,0,16);bar.BackgroundColor3=Color3.new(1,1,1);bar.BorderSizePixel=0;bar.Active=true;bar.ZIndex=133;bar.Parent=r;round(bar,4)
        local g=Instance.new("UIGradient");g.Color=rainbow;g.Parent=bar
        local k=Instance.new("Frame");k.AnchorPoint=Vector2.new(.5,.5);k.Size=UDim2.fromOffset(4,22);k.BackgroundColor3=Color3.fromRGB(248,248,250);k.BorderSizePixel=0;k.ZIndex=134;k.Parent=bar
        local drag=false
        local function colorX(x) local h=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1);C.Color=Color3.fromHSV(h,1,1);k.Position=UDim2.new(h,0,.5,0) end
        bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;colorX(i.Position.X) end end);UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then colorX(i.Position.X) end end);UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end);k.Position=UDim2.new(select(1,C.Color:ToHSV()),0,.5,0)
        local function slider(label,get,set,min,max,step)
            local rr,ll=base(label);ll.Size=UDim2.fromOffset(70,38)
            local b=Instance.new("Frame");b.Position=UDim2.fromOffset(78,16);b.Size=UDim2.new(1,-133,0,6);b.BackgroundColor3=Color3.fromRGB(43,44,51);b.BorderSizePixel=0;b.Active=true;b.ZIndex=133;b.Parent=rr;round(b,3)
            local fill=Instance.new("Frame");fill.BackgroundColor3=UI.Accent;fill.BorderSizePixel=0;fill.ZIndex=134;fill.Parent=b;round(fill,3)
            local kk=Instance.new("Frame");kk.AnchorPoint=Vector2.new(.5,.5);kk.Size=UDim2.fromOffset(10,16);kk.BackgroundColor3=Color3.fromRGB(242,242,245);kk.BorderSizePixel=0;kk.ZIndex=135;kk.Parent=b;round(kk,5)
            local val=Instance.new("TextLabel");val.AnchorPoint=Vector2.new(1,.5);val.Position=UDim2.new(1,-7,.5,0);val.Size=UDim2.fromOffset(44,20);val.BackgroundColor3=Color3.fromRGB(35,36,43);val.BorderSizePixel=0;val.Font=Enum.Font.Code;val.TextSize=9;val.TextColor3=Color3.fromRGB(220,220,228);val.ZIndex=134;val.Parent=rr;round(val,3)
            local d=false
            local function paint() local n=math.clamp(tonumber(get()) or min,min,max);local a=(n-min)/(max-min);fill.Size=UDim2.new(a,0,1,0);kk.Position=UDim2.new(a,0,.5,0);val.Text=step<1 and string.format("%.2f",n) or tostring(math.floor(n+.5)) end
            local function fromX(x) local a=math.clamp((x-b.AbsolutePosition.X)/math.max(1,b.AbsoluteSize.X),0,1);local n=min+(max-min)*a;n=math.floor(n/step+.5)*step;set(math.clamp(n,min,max));paint() end
            b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=true;fromX(i.Position.X) end end);kk.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=true;fromX(i.Position.X) end end);UIS.InputChanged:Connect(function(i) if d and i.UserInputType==Enum.UserInputType.MouseMovement then fromX(i.Position.X) end end);UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end);paint()
        end
        slider("Transp.",function() return C.Transparency end,function(v) C.Transparency=v end,0,100,1)
        slider("Lifetime",function() return C.Lifetime end,function(v) C.Lifetime=v end,.05,1.5,.05)
        slider("Thickness",function() return C.Thickness end,function(v) C.Thickness=v end,.02,.35,.01)
        local gr=base("Glow");local gb=Instance.new("TextButton");gb.AnchorPoint=Vector2.new(1,.5);gb.Position=UDim2.new(1,-7,.5,0);gb.Size=UDim2.fromOffset(34,18);gb.Text="";gb.BorderSizePixel=0;gb.ZIndex=133;gb.Parent=gr;round(gb,3)
        local function gp() gb.BackgroundColor3=C.Glow and UI.Accent or Color3.fromRGB(48,49,57) end;gb.MouseButton1Click:Connect(function() C.Glow=not C.Glow;gp() end);gp()
        p.Size=UDim2.fromOffset(236,y+3);if UI.OpenDockedPanel then UI.OpenDockedPanel(p) else p.Parent=UI.Gui end
    end

    local row,text=UI.Row(page,"BulletTracer");text.Size=UDim2.new(1,-78,1,0);text.Active=true
    local dots=Instance.new("TextButton");dots.AnchorPoint=Vector2.new(1,.5);dots.Position=UDim2.new(1,-44,.5,0);dots.Size=UDim2.fromOffset(26,20);dots.BackgroundColor3=Color3.fromRGB(34,34,40);dots.BorderSizePixel=0;dots.Font=Enum.Font.SourceSansBold;dots.TextSize=15;dots.TextColor3=Color3.fromRGB(195,195,205);dots.Text="•••";dots.Parent=row;round(dots,4)
    local tog=Instance.new("TextButton");tog.AnchorPoint=Vector2.new(1,.5);tog.Position=UDim2.new(1,-7,.5,0);tog.Size=UDim2.fromOffset(28,18);tog.Text="";tog.BorderSizePixel=0;tog.Parent=row;round(tog,3)
    local mark=Instance.new("Frame");mark.AnchorPoint=Vector2.new(.5,.5);mark.Position=UDim2.fromScale(.5,.5);mark.Size=UDim2.fromOffset(18,10);mark.BorderSizePixel=0;mark.Parent=tog;round(mark,2)
    local function paint() local on=State.Local.BulletTracer;tog.BackgroundColor3=on and UI.Accent or Color3.fromRGB(45,45,45);mark.BackgroundColor3=on and Color3.fromRGB(238,238,240) or Color3.fromRGB(86,86,86) end
    local function flip() State.Local.BulletTracer=not State.Local.BulletTracer;paint() end
    tog.MouseButton1Click:Connect(flip);text.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then flip() end end);dots.MouseButton1Click:Connect(openOptions);paint()

    local installed=false
    local lastActual=0
    local function findBuilder()
        local ps=LP:FindFirstChild("PlayerScripts");if not ps then return nil end
        for _,d in ipairs(ps:GetDescendants()) do if d:IsA("ModuleScript") and d.Name=="WeaponShotBuilder" then return d end end
    end
    local function install()
        if installed then return true end
        local mod=findBuilder();if not mod then return false end
        local ok,b=pcall(require,mod);if not ok or type(b)~="table" or type(b.GetSpreadDirection)~="function" then return false end
        local prev=b.GetSpreadDirection
        b.GetSpreadDirection=function(baseDirection,spreadState)
            local result=prev(baseDirection,spreadState)
            lastActual=os.clock();task.defer(emit,result or baseDirection)
            return result
        end
        installed=true;return true
    end
    task.spawn(function() while not installed do install();task.wait(.75) end end)

    -- Fallback only if this build caches the builder before our wrapper is installed.
    UIS.InputBegan:Connect(function(i)
        if i.UserInputType~=Enum.UserInputType.MouseButton1 or UIS:GetFocusedTextBox() then return end
        local started=os.clock();task.delay(.06,function() if lastActual<started then local cam=Workspace.CurrentCamera;emit(cam and cam.CFrame.LookVector or nil) end end)
    end)
end
