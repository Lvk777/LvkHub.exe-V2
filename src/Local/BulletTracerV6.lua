-- BulletTracer V6: local cosmetic tracer only.
-- Third person: actual equipped Tool muzzle. First person: matched camera viewmodel muzzle.
return function(State, Registry, UI)
    local Players=game:GetService("Players")
    local Workspace=game:GetService("Workspace")
    local UIS=game:GetService("UserInputService")
    local Debris=game:GetService("Debris")
    local LP=Players.LocalPlayer
    local page=UI.Pages.Local

    State.Local.BulletTracer=State.Local.BulletTracer==true
    local C=State.Local._BulletTracerV6 or State.Local._BulletTracerV5 or {
        Color=Color3.fromRGB(119,120,255),Transparency=5,Lifetime=.18,Thickness=.08,Glow=true,Distance=20000,
    }
    State.Local._BulletTracerV6=C

    local function round(o,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 4);c.Parent=o end
    local rainbow=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),ColorSequenceKeypoint.new(1/6,Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(2/6,Color3.fromRGB(0,255,0)),ColorSequenceKeypoint.new(3/6,Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(4/6,Color3.fromRGB(0,0,255)),ColorSequenceKeypoint.new(5/6,Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,0)),
    })

    local function openOptions()
        local p=Instance.new("Frame");p.Name="LvkBulletTracerOptionsV6";p.Size=UDim2.fromOffset(236,252);p.BackgroundColor3=Color3.fromRGB(17,18,22);p.BorderSizePixel=0;p.ZIndex=130;round(p,7)
        local ps=Instance.new("UIStroke");ps.Color=Color3.fromRGB(65,67,80);ps.Transparency=.12;ps.Parent=p
        local header=Instance.new("Frame");header.Name="Header";header.Size=UDim2.new(1,0,0,36);header.BackgroundTransparency=1;header.Active=true;header.ZIndex=131;header.Parent=p
        local title=Instance.new("TextLabel");title.BackgroundTransparency=1;title.Position=UDim2.fromOffset(10,4);title.Size=UDim2.new(1,-42,0,28);title.Font=Enum.Font.SourceSansSemibold;title.TextSize=14;title.TextColor3=Color3.fromRGB(238,238,242);title.TextXAlignment=Enum.TextXAlignment.Left;title.Text="BulletTracer";title.ZIndex=132;title.Parent=header
        local close=Instance.new("TextButton");close.AnchorPoint=Vector2.new(1,0);close.Position=UDim2.new(1,-7,0,6);close.Size=UDim2.fromOffset(25,22);close.BackgroundColor3=Color3.fromRGB(34,35,42);close.BorderSizePixel=0;close.Text="×";close.TextColor3=Color3.fromRGB(215,215,222);close.ZIndex=133;close.Parent=p;round(close,4)
        close.MouseButton1Click:Connect(function() if UI.CloseDockedPanel then UI.CloseDockedPanel(p) elseif p.Parent then p:Destroy() end end)
        local function row(label,y)
            local r=Instance.new("Frame");r.Position=UDim2.fromOffset(7,y);r.Size=UDim2.new(1,-14,0,38);r.BackgroundColor3=Color3.fromRGB(27,28,34);r.BorderSizePixel=0;r.ZIndex=131;r.Parent=p;round(r,4)
            local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Position=UDim2.fromOffset(8,0);l.Size=UDim2.fromOffset(72,38);l.Font=Enum.Font.SourceSans;l.TextSize=12;l.TextColor3=Color3.fromRGB(222,222,228);l.TextXAlignment=Enum.TextXAlignment.Left;l.Text=label;l.ZIndex=132;l.Parent=r
            return r,l
        end
        local cr=row("Color",39)
        local cb=Instance.new("Frame");cb.Position=UDim2.fromOffset(80,11);cb.Size=UDim2.new(1,-90,0,16);cb.BackgroundColor3=Color3.new(1,1,1);cb.BorderSizePixel=0;cb.Active=true;cb.ZIndex=133;cb.Parent=cr;round(cb,4)
        local cg=Instance.new("UIGradient");cg.Color=rainbow;cg.Parent=cb
        local ck=Instance.new("Frame");ck.AnchorPoint=Vector2.new(.5,.5);ck.Size=UDim2.fromOffset(4,22);ck.BackgroundColor3=Color3.fromRGB(248,248,250);ck.BorderSizePixel=0;ck.ZIndex=134;ck.Parent=cb
        local colorDrag=false
        local function colorX(x) local h=math.clamp((x-cb.AbsolutePosition.X)/math.max(1,cb.AbsoluteSize.X),0,1);C.Color=Color3.fromHSV(h,1,1);ck.Position=UDim2.new(h,0,.5,0) end
        cb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then colorDrag=true;colorX(i.Position.X) end end)
        UIS.InputChanged:Connect(function(i) if colorDrag and i.UserInputType==Enum.UserInputType.MouseMovement then colorX(i.Position.X) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then colorDrag=false end end)
        ck.Position=UDim2.new(select(1,C.Color:ToHSV()),0,.5,0)
        local function slider(label,get,set,min,max,step,y)
            local r=row(label,y)
            local bar=Instance.new("Frame");bar.Position=UDim2.fromOffset(82,16);bar.Size=UDim2.new(1,-137,0,6);bar.BackgroundColor3=Color3.fromRGB(43,44,51);bar.BorderSizePixel=0;bar.Active=true;bar.ZIndex=133;bar.Parent=r;round(bar,3)
            local fill=Instance.new("Frame");fill.BackgroundColor3=UI.Accent;fill.BorderSizePixel=0;fill.ZIndex=134;fill.Parent=bar;round(fill,3)
            local k=Instance.new("Frame");k.AnchorPoint=Vector2.new(.5,.5);k.Size=UDim2.fromOffset(10,16);k.BackgroundColor3=Color3.fromRGB(242,242,245);k.BorderSizePixel=0;k.ZIndex=135;k.Parent=bar;round(k,5)
            local val=Instance.new("TextLabel");val.AnchorPoint=Vector2.new(1,.5);val.Position=UDim2.new(1,-7,.5,0);val.Size=UDim2.fromOffset(44,20);val.BackgroundColor3=Color3.fromRGB(35,36,43);val.BorderSizePixel=0;val.Font=Enum.Font.Code;val.TextSize=9;val.TextColor3=Color3.fromRGB(220,220,228);val.ZIndex=134;val.Parent=r;round(val,3)
            local dragging=false
            local function paint() local n=math.clamp(tonumber(get()) or min,min,max);local a=(n-min)/(max-min);fill.Size=UDim2.new(a,0,1,0);k.Position=UDim2.new(a,0,.5,0);val.Text=step<1 and string.format("%.2f",n) or tostring(math.floor(n+.5)) end
            local function fromX(x) local a=math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1);local n=min+(max-min)*a;n=math.floor(n/step+.5)*step;set(math.clamp(n,min,max));paint() end
            bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;fromX(i.Position.X) end end)
            k.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true;fromX(i.Position.X) end end)
            UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then fromX(i.Position.X) end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end);paint()
        end
        slider("Transp.",function() return C.Transparency end,function(v) C.Transparency=v end,0,100,1,82)
        slider("Lifetime",function() return C.Lifetime end,function(v) C.Lifetime=v end,.05,1.5,.05,125)
        slider("Thickness",function() return C.Thickness end,function(v) C.Thickness=v end,.02,.35,.01,168)
        local gr=row("Glow",211);local gb=Instance.new("TextButton");gb.AnchorPoint=Vector2.new(1,.5);gb.Position=UDim2.new(1,-7,.5,0);gb.Size=UDim2.fromOffset(34,18);gb.Text="";gb.BorderSizePixel=0;gb.ZIndex=133;gb.Parent=gr;round(gb,3)
        local function gp() gb.BackgroundColor3=C.Glow and UI.Accent or Color3.fromRGB(48,49,57) end;gb.MouseButton1Click:Connect(function() C.Glow=not C.Glow;gp() end);gp()
        if UI.OpenDockedPanel then UI.OpenDockedPanel(p) else p.Parent=UI.Gui end
    end

    local row,text=UI.Row(page,"BulletTracer");text.Size=UDim2.new(1,-78,1,0);text.Active=true
    local dots=Instance.new("TextButton");dots.AnchorPoint=Vector2.new(1,.5);dots.Position=UDim2.new(1,-44,.5,0);dots.Size=UDim2.fromOffset(26,20);dots.BackgroundColor3=Color3.fromRGB(34,34,40);dots.BorderSizePixel=0;dots.Font=Enum.Font.SourceSansBold;dots.TextSize=15;dots.TextColor3=Color3.fromRGB(195,195,205);dots.Text="•••";dots.Parent=row;round(dots,4)
    local tog=Instance.new("TextButton");tog.AnchorPoint=Vector2.new(1,.5);tog.Position=UDim2.new(1,-7,.5,0);tog.Size=UDim2.fromOffset(28,18);tog.Text="";tog.BorderSizePixel=0;tog.Parent=row;round(tog,3)
    local mark=Instance.new("Frame");mark.AnchorPoint=Vector2.new(.5,.5);mark.Position=UDim2.fromScale(.5,.5);mark.Size=UDim2.fromOffset(18,10);mark.BorderSizePixel=0;mark.Parent=tog;round(mark,2)
    local function paint() local on=State.Local.BulletTracer;tog.BackgroundColor3=on and UI.Accent or Color3.fromRGB(45,45,45);mark.BackgroundColor3=on and Color3.fromRGB(238,238,240) or Color3.fromRGB(86,86,86) end
    local function flip() State.Local.BulletTracer=not State.Local.BulletTracer;paint() end
    tog.MouseButton1Click:Connect(flip);text.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then flip() end end);dots.MouseButton1Click:Connect(openOptions);paint()

    for _,n in ipairs({"LvkHubBulletTracersV2","LvkHubBulletTracersV3","LvkHubBulletTracersV4","LvkHubBulletTracersV5","LvkHubBulletTracersV6"}) do local old=Workspace:FindFirstChild(n);if old then old:Destroy() end end
    local folder=Instance.new("Folder");folder.Name="LvkHubBulletTracersV6";folder.Parent=Workspace

    local function currentWeapon()
        local ch=LP.Character;if not ch then return nil end
        for _,o in ipairs(ch:GetChildren()) do if o:IsA("Tool") and (o:FindFirstChild("WeaponConfig") or o:FindFirstChild("Ammo")) then return o end end
    end
    local function worldPos(o) if o:IsA("Attachment") then return o.WorldPosition elseif o:IsA("BasePart") then return o.Position end end
    local function exactMuzzle(root)
        if not root then return nil end
        local grip=root:FindFirstChild("Grip",true)
        local gm=grip and grip:FindFirstChild("Muzzle",true)
        if gm and (gm:IsA("Attachment") or gm:IsA("BasePart")) then return gm end
        local weapon=root:FindFirstChild("Weapon",true)
        if weapon then local wg=weapon:FindFirstChild("Grip",true);local wm=wg and wg:FindFirstChild("Muzzle",true);if wm and (wm:IsA("Attachment") or wm:IsA("BasePart")) then return wm end end
        local best=nil
        for _,d in ipairs(root:GetDescendants()) do
            if (d:IsA("Attachment") or d:IsA("BasePart")) and d.Name:lower():find("muzzle",1,true) then best=d;break end
        end
        return best
    end
    local function firstPerson()
        local cam=Workspace.CurrentCamera;local ch=LP.Character;local head=ch and ch:FindFirstChild("Head")
        return cam and head and (cam.CFrame.Position-head.Position).Magnitude<1.35
    end
    local function cameraMuzzle(tool)
        local cam=Workspace.CurrentCamera;if not cam then return nil end
        local expected=cam.CFrame.Position+cam.CFrame.LookVector*2
        local toolName=tool and tool.Name:lower() or ""
        local best,bestScore=nil,math.huge
        for _,m in ipairs(cam:GetDescendants()) do
            if m:IsA("Model") then
                local obj=exactMuzzle(m)
                if obj then
                    local p=worldPos(obj)
                    if p then
                        local n=m.Name:lower();local score=(p-expected).Magnitude
                        if toolName~="" and (n==toolName or n:find(toolName,1,true)) then score-=8 end
                        if score<bestScore then best,bestScore=obj,score end
                    end
                end
            end
        end
        return best
    end
    local function muzzlePosition(tool)
        if firstPerson() then local vm=cameraMuzzle(tool);if vm then return worldPos(vm) end end
        local tm=exactMuzzle(tool);if tm then return worldPos(tm) end
        local handle=tool and (tool:FindFirstChild("Handle",true) or tool:FindFirstChild("Grip",true))
        if handle and handle:IsA("BasePart") then return handle.Position+handle.CFrame.LookVector*math.max(.45,handle.Size.Z*.5) end
    end
    local function aimPoint()
        local cam=Workspace.CurrentCamera;if not cam then return nil end
        local c=cam.ViewportSize/2;local ray=cam:ViewportPointToRay(c.X,c.Y)
        local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Exclude;rp.FilterDescendantsInstances={folder,LP.Character,cam};rp.IgnoreWater=true
        local dist=tonumber(C.Distance) or 20000;local hit=Workspace:Raycast(ray.Origin,ray.Direction*dist,rp)
        return hit and hit.Position or ray.Origin+ray.Direction*dist
    end
    local function anchor(pos)
        local p=Instance.new("Part");p.Size=Vector3.new(.02,.02,.02);p.Transparency=1;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CFrame=CFrame.new(pos);p.Parent=folder
        local a=Instance.new("Attachment");a.Parent=p;return p,a
    end
    local lastTrace=0
    local function emit(tool)
        if not State.Local.BulletTracer then return end
        local now=os.clock();if now-lastTrace<.04 then return end;lastTrace=now
        tool=tool or currentWeapon();if not tool then return end
        local from=muzzlePosition(tool);local to=aimPoint();if not from or not to or (to-from).Magnitude<.1 then return end
        local p0,a0=anchor(from);local p1,a1=anchor(to)
        local beam=Instance.new("Beam");beam.Attachment0=a0;beam.Attachment1=a1;beam.FaceCamera=true;beam.Color=ColorSequence.new(C.Color);beam.Transparency=NumberSequence.new(math.clamp((C.Transparency or 0)/100,0,1));beam.Width0=C.Thickness or .08;beam.Width1=C.Thickness or .08;beam.LightEmission=C.Glow and 1 or 0;beam.LightInfluence=C.Glow and 0 or 1;beam.Parent=p0
        local life=math.clamp(C.Lifetime or .18,.05,1.5);Debris:AddItem(p0,life);Debris:AddItem(p1,life)
    end

    local watchedTool=nil;local conns={};local lastMag=nil
    local function clearWatch() for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end;table.clear(conns);watchedTool=nil;lastMag=nil end
    local function watchTool(tool)
        if tool==watchedTool then return end;clearWatch();watchedTool=tool;if not tool then return end
        table.insert(conns,tool.Activated:Connect(function() task.defer(emit,tool) end))
        local ammo=tool:FindFirstChild("Ammo");local mag=ammo and ammo:FindFirstChild("MagAmmo")
        if mag and mag:IsA("ValueBase") then
            lastMag=tonumber(mag.Value)
            table.insert(conns,mag:GetPropertyChangedSignal("Value"):Connect(function()
                local n=tonumber(mag.Value);if n and lastMag and n<lastMag then task.defer(emit,tool) end;lastMag=n
            end))
        end
    end
    task.spawn(function() while task.wait(.12) do watchTool(currentWeapon()) end end)
end
